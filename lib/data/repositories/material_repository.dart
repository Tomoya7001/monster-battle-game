// lib/data/repositories/material_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/material.dart';

/// 素材リポジトリ
class MaterialRepository {
  final FirebaseFirestore _firestore;
  Map<String, Material>? _materialMasterCache;

  MaterialRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ========== マスターデータ ==========

  /// 素材マスター全取得（キャッシュ付き）
  Future<Map<String, Material>> getMaterialMasters() async {
    if (_materialMasterCache != null) return _materialMasterCache!;

    final snapshot = await _firestore.collection('material_masters').get();

    _materialMasterCache = {};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      data['material_id'] = doc.id;
      _materialMasterCache![doc.id] = Material.fromJson(data);
    }

    return _materialMasterCache!;
  }

  /// 素材マスター単体取得
  Future<Material?> getMaterialMaster(String materialId) async {
    final masters = await getMaterialMasters();
    return masters[materialId];
  }

  /// カテゴリ別素材マスター取得
  Future<List<Material>> getMaterialMastersByCategory(String category) async {
    final masters = await getMaterialMasters();
    return masters.values
        .where((material) => material.category == category && material.isActive)
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }

  // ========== ユーザー所持素材 ==========

  /// ユーザー所持素材全取得
  Future<List<UserMaterial>> getUserMaterials(String userId) async {
    final snapshot = await _firestore
        .collection('user_materials')
        .where('user_id', isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((doc) => UserMaterial.fromJson(doc.data(), doc.id))
        .where((material) => material.quantity > 0)
        .toList();
  }

  /// ユーザー所持素材取得（単体）
  Future<UserMaterial?> getUserMaterial(String userId, String materialId) async {
    final docId = '${userId}_$materialId';
    final doc = await _firestore.collection('user_materials').doc(docId).get();

    if (!doc.exists) return null;
    return UserMaterial.fromJson(doc.data()!, doc.id);
  }

  /// 素材追加
  Future<void> addMaterial(String userId, String materialId, int quantity) async {
    final docId = '${userId}_$materialId';
    final docRef = _firestore.collection('user_materials').doc(docId);

    final doc = await docRef.get();

    if (doc.exists) {
      final currentQty = doc.data()!['quantity'] as int? ?? 0;
      await docRef.update({
        'quantity': currentQty + quantity,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } else {
      await docRef.set({
        'user_id': userId,
        'material_id': materialId,
        'quantity': quantity,
        'acquired_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    }
  }

  /// 素材消費
  Future<bool> consumeMaterial(String userId, String materialId, int quantity) async {
    final docId = '${userId}_$materialId';
    final docRef = _firestore.collection('user_materials').doc(docId);

    final doc = await docRef.get();
    if (!doc.exists) return false;

    final currentQty = doc.data()!['quantity'] as int? ?? 0;
    if (currentQty < quantity) return false;

    final newQty = currentQty - quantity;
    if (newQty <= 0) {
      await docRef.delete();
    } else {
      await docRef.update({
        'quantity': newQty,
        'updated_at': FieldValue.serverTimestamp(),
      });
    }

    return true;
  }

  /// 複数素材一括追加
  Future<void> addMaterials(String userId, Map<String, int> materials) async {
    if (materials.isEmpty) return;

    final batch = _firestore.batch();

    for (final entry in materials.entries) {
      final docId = '${userId}_${entry.key}';
      final docRef = _firestore.collection('user_materials').doc(docId);

      final doc = await docRef.get();

      if (doc.exists) {
        final currentQty = doc.data()!['quantity'] as int? ?? 0;
        batch.update(docRef, {
          'quantity': currentQty + entry.value,
          'updated_at': FieldValue.serverTimestamp(),
        });
      } else {
        batch.set(docRef, {
          'user_id': userId,
          'material_id': entry.key,
          'quantity': entry.value,
          'acquired_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
  }

  /// 素材が十分にあるか確認
  Future<bool> hasSufficientMaterials(
    String userId,
    Map<String, int> required,
  ) async {
    for (final entry in required.entries) {
      final userMaterial = await getUserMaterial(userId, entry.key);
      if (userMaterial == null || userMaterial.quantity < entry.value) {
        return false;
      }
    }
    return true;
  }

  /// 複数素材一括消費
  Future<bool> consumeMaterials(String userId, Map<String, int> materials) async {
    // 先に全ての素材が足りるか確認
    if (!await hasSufficientMaterials(userId, materials)) {
      return false;
    }

    final batch = _firestore.batch();

    for (final entry in materials.entries) {
      final docId = '${userId}_${entry.key}';
      final docRef = _firestore.collection('user_materials').doc(docId);

      final doc = await docRef.get();
      final currentQty = doc.data()!['quantity'] as int? ?? 0;
      final newQty = currentQty - entry.value;

      if (newQty <= 0) {
        batch.delete(docRef);
      } else {
        batch.update(docRef, {
          'quantity': newQty,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
    return true;
  }

  /// キャッシュクリア
  void clearCache() {
    _materialMasterCache = null;
  }
}