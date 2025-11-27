// lib/data/repositories/material_repository.dart
//
// 既存の lib/domain/entities/material.dart の MaterialMaster を使用

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/material.dart';

class MaterialRepository {
  final FirebaseFirestore _firestore;
  Map<String, MaterialMaster>? _masterCache;

  MaterialRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 素材マスター全取得（item_mastersからmaterialカテゴリを取得）
  Future<Map<String, MaterialMaster>> getMaterialMasters() async {
    if (_masterCache != null) return _masterCache!;

    try {
      final snapshot = await _firestore
          .collection('item_masters')
          .where('category', isEqualTo: 'material')
          .get();
      
      _masterCache = {};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final materialId = data['item_id']?.toString() ?? doc.id;
        _masterCache![materialId] = MaterialMaster.fromJson(data);
      }
      
      return _masterCache!;
    } catch (e) {
      print('Error getting material masters: $e');
      return {};
    }
  }

  /// 素材マスター単体取得
  Future<MaterialMaster?> getMaterialMaster(String materialId) async {
    final masters = await getMaterialMasters();
    return masters[materialId];
  }

  /// カテゴリ別素材取得
  Future<List<MaterialMaster>> getMaterialsByCategory(String category) async {
    final masters = await getMaterialMasters();
    return masters.values
        .where((m) => m.subCategory == category || m.category == category)
        .toList()
      ..sort((a, b) => a.rarity.compareTo(b.rarity));
  }

  /// ユーザー所持素材取得
  Future<Map<String, int>> getUserMaterials(String userId) async {
    try {
      // user_itemsからmaterialカテゴリのアイテムを取得
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('user_items')
          .get();

      final masters = await getMaterialMasters();
      final materials = <String, int>{};
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final itemId = data['item_id'] as String? ?? doc.id;
        final quantity = data['quantity'] as int? ?? 0;
        
        // 素材マスターに存在するものだけ取得
        if (masters.containsKey(itemId) && quantity > 0) {
          materials[itemId] = quantity;
        }
      }
      
      return materials;
    } catch (e) {
      print('Error getting user materials: $e');
      return {};
    }
  }

  /// ユーザー所持素材詳細取得（マスター情報込み）
  Future<List<UserMaterialWithMaster>> getUserMaterialsWithMaster(String userId) async {
    final masters = await getMaterialMasters();
    final userMaterials = await getUserMaterials(userId);
    
    final result = <UserMaterialWithMaster>[];
    
    for (final entry in userMaterials.entries) {
      final master = masters[entry.key];
      if (master != null) {
        result.add(UserMaterialWithMaster(
          materialId: entry.key,
          quantity: entry.value,
          master: master,
        ));
      }
    }
    
    // レアリティ順でソート
    result.sort((a, b) => b.master.rarity.compareTo(a.master.rarity));
    
    return result;
  }

  /// 素材消費
  Future<bool> consumeMaterials(
    String userId,
    Map<String, int> materials,
  ) async {
    try {
      final batch = _firestore.batch();
      
      for (final entry in materials.entries) {
        final materialId = entry.key;
        final consumeQuantity = entry.value;
        
        // 現在の所持数を取得
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('user_items')
            .doc(materialId);
        
        final doc = await docRef.get();
        if (!doc.exists) {
          throw Exception('素材が見つかりません: $materialId');
        }
        
        final currentQuantity = doc.data()?['quantity'] as int? ?? 0;
        if (currentQuantity < consumeQuantity) {
          throw Exception('素材が不足しています: $materialId');
        }
        
        final newQuantity = currentQuantity - consumeQuantity;
        batch.update(docRef, {
          'quantity': newQuantity,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      return true;
    } catch (e) {
      print('Error consuming materials: $e');
      return false;
    }
  }

  /// 素材追加（ドロップ時など）
  Future<bool> addMaterials(
    String userId,
    Map<String, int> materials,
  ) async {
    try {
      final batch = _firestore.batch();
      
      for (final entry in materials.entries) {
        final materialId = entry.key;
        final addQuantity = entry.value;
        
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('user_items')
            .doc(materialId);
        
        final doc = await docRef.get();
        if (doc.exists) {
          final currentQuantity = doc.data()?['quantity'] as int? ?? 0;
          batch.update(docRef, {
            'quantity': currentQuantity + addQuantity,
            'updated_at': FieldValue.serverTimestamp(),
          });
        } else {
          batch.set(docRef, {
            'item_id': materialId,
            'quantity': addQuantity,
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
      }
      
      await batch.commit();
      return true;
    } catch (e) {
      print('Error adding materials: $e');
      return false;
    }
  }

  /// キャッシュクリア
  void clearCache() {
    _masterCache = null;
  }
}

/// ユーザー所持素材（マスター情報付き）
class UserMaterialWithMaster {
  final String materialId;
  final int quantity;
  final MaterialMaster master;

  const UserMaterialWithMaster({
    required this.materialId,
    required this.quantity,
    required this.master,
  });
}