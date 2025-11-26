// lib/data/repositories/item_repository.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/item.dart';
import '../../domain/entities/user_item.dart';

class ItemRepository {
  final FirebaseFirestore _firestore;
  Map<String, Item>? _itemMasterCache;

  ItemRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ========== マスターデータ ==========

  /// アイテムマスター全取得（キャッシュ付き）
  Future<Map<String, Item>> getItemMasters() async {
    if (_itemMasterCache != null) return _itemMasterCache!;

    final snapshot = await _firestore.collection('item_masters').get();
    
    _itemMasterCache = {};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      data['itemId'] = doc.id;
      // snake_case -> camelCase 変換
      final converted = _convertToCamelCase(data);
      _itemMasterCache![doc.id] = Item.fromJson(converted);
    }
    
    return _itemMasterCache!;
  }

  /// アイテムマスター単体取得
  Future<Item?> getItemMaster(String itemId) async {
    final masters = await getItemMasters();
    return masters[itemId];
  }

  /// カテゴリ別アイテムマスター取得
  Future<List<Item>> getItemMastersByCategory(String category) async {
    final masters = await getItemMasters();
    return masters.values
        .where((item) => item.category == category && item.isActive)
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }

  // ========== ユーザーアイテム ==========

  /// ユーザー所持アイテム全取得
  Future<List<UserItem>> getUserItems(String userId) async {
    final snapshot = await _firestore
        .collection('user_items')
        .where('user_id', isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((doc) => UserItem.fromJson(doc.data(), doc.id))
        .where((item) => item.quantity > 0)
        .toList();
  }

  /// ユーザー所持アイテム取得（単体）
  Future<UserItem?> getUserItem(String userId, String itemId) async {
    final docId = '${userId}_$itemId';
    final doc = await _firestore.collection('user_items').doc(docId).get();
    
    if (!doc.exists) return null;
    return UserItem.fromJson(doc.data()!, doc.id);
  }

  /// アイテム追加（ドロップ等）
  Future<void> addItem(String userId, String itemId, int quantity) async {
    final docId = '${userId}_$itemId';
    final docRef = _firestore.collection('user_items').doc(docId);
    
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
        'item_id': itemId,
        'quantity': quantity,
        'acquired_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    }
  }

  /// アイテム消費
  Future<bool> consumeItem(String userId, String itemId, int quantity) async {
    final docId = '${userId}_$itemId';
    final docRef = _firestore.collection('user_items').doc(docId);
    
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

  /// 複数アイテム一括追加（バトル報酬等）
  Future<void> addItems(String userId, Map<String, int> items) async {
    final batch = _firestore.batch();
    
    for (final entry in items.entries) {
      final docId = '${userId}_${entry.key}';
      final docRef = _firestore.collection('user_items').doc(docId);
      
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
          'item_id': entry.key,
          'quantity': entry.value,
          'acquired_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    }
    
    await batch.commit();
  }

  // ========== ドロップ計算 ==========

  /// ステージクリア時のドロップ計算
  Future<Map<String, int>> calculateDrop(String stageId, {bool isBoss = false}) async {
    final masters = await getItemMasters();
    final drops = <String, int>{};
    
    for (final item in masters.values) {
      if (!item.dropStages.contains(stageId)) continue;
      
      // ドロップ判定
      final roll = DateTime.now().microsecondsSinceEpoch % 100;
      var dropRate = item.dropRate;
      
      // ボス戦はドロップ率1.5倍
      if (isBoss) dropRate = (dropRate * 1.5).round();
      
      if (roll < dropRate) {
        final qty = item.rarity >= 3 ? 1 : (1 + (roll % 2)); // 低レアは1-2個
        drops[item.itemId] = qty;
      }
    }
    
    // ボス戦はボスの証を確定ドロップ
    if (isBoss) {
      drops['boss_proof'] = 1;
    }
    
    return drops;
  }

  // ========== ユーティリティ ==========

  Map<String, dynamic> _convertToCamelCase(Map<String, dynamic> data) {
    return {
      'itemId': data['item_id'],
      'name': data['name'],
      'nameEn': data['name_en'],
      'category': data['category'],
      'subCategory': data['sub_category'],
      'rarity': data['rarity'],
      'description': data['description'],
      'effect': data['effect'],
      'icon': data['icon'],
      'sellPrice': data['sell_price'],
      'buyPrice': data['buy_price'],
      'maxStack': data['max_stack'],
      'isUsableInBattle': data['is_usable_in_battle'],
      'dropStages': data['drop_stages'],
      'dropRate': data['drop_rate'],
      'displayOrder': data['display_order'],
      'isActive': data['is_active'],
    };
  }

  void clearCache() {
    _itemMasterCache = null;
  }
}