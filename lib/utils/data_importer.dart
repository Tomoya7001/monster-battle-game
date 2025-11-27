// lib/utils/data_importer.dart
// マスターデータをFirestoreに投入するユーティリティ

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// マスターデータをFirestoreに投入するクラス
class DataImporter {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// モンスターマスターデータを投入
  Future<void> importMonsterMasters() async {
    try {
      print('📦 モンスターマスターデータ読み込み中...');
      
      final String jsonString = await rootBundle
          .loadString('assets/data/monster_masters_data.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      
      print('✅ JSONファイル読み込み完了');
      
      final batch = _firestore.batch();
      int count = 0;
      
      for (var monster in data['monsters']) {
        final monsterMap = Map<String, dynamic>.from(monster as Map);
        final docRef = _firestore
            .collection('monster_masters')
            .doc(monsterMap['monster_id'].toString());
        
        batch.set(docRef, {
          ...monsterMap,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
        count++;
        
        if (count % 500 == 0) {
          await batch.commit();
          print('✅ $count 件のモンスターマスターを投入');
        }
      }
      
      if (count % 500 != 0) {
        await batch.commit();
      }
      
      print('✅ モンスターマスターデータ投入完了: $count 件');
    } catch (e, stackTrace) {
      print('❌ エラー: $e');
      print('スタックトレース: $stackTrace');
      rethrow;
    }
  }
  
  /// 技マスターデータを投入
  Future<void> importSkillMasters() async {
    try {
      print('📦 技マスターデータ読み込み中...');
      
      final String jsonString = await rootBundle
          .loadString('assets/data/skill_masters_data.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      
      print('✅ JSONファイル読み込み完了');
      
      final batch = _firestore.batch();
      int count = 0;
      
      for (var skill in data['skills']) {
        final skillMap = Map<String, dynamic>.from(skill as Map);
        final docRef = _firestore
            .collection('skill_masters')
            .doc(skillMap['skill_id'].toString());
        
        batch.set(docRef, {
          ...skillMap,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
        count++;
        
        if (count % 500 == 0) {
          await batch.commit();
          print('✅ $count 件の技マスターを投入');
        }
      }
      
      if (count % 500 != 0) {
        await batch.commit();
      }
      
      print('✅ 技マスターデータ投入完了: $count 件');
    } catch (e, stackTrace) {
      print('❌ エラー: $e');
      print('スタックトレース: $stackTrace');
      rethrow;
    }
  }
  
  /// 装備マスターデータを投入
  Future<void> importEquipmentMasters() async {
    try {
      print('📦 装備マスターデータ読み込み中...');
      
      final String jsonString = await rootBundle
          .loadString('assets/data/equipment_masters_data.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      
      print('✅ JSONファイル読み込み完了');
      
      final batch = _firestore.batch();
      int count = 0;
      
      for (var equipment in data['equipment']) {
        final equipmentMap = Map<String, dynamic>.from(equipment as Map);
        final docRef = _firestore
            .collection('equipment_masters')
            .doc(equipmentMap['equipment_id'].toString());
        
        batch.set(docRef, {
          ...equipmentMap,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
        count++;
        
        if (count % 500 == 0) {
          await batch.commit();
          print('✅ $count 件の装備マスターを投入');
        }
      }
      
      if (count % 500 != 0) {
        await batch.commit();
      }
      
      print('✅ 装備マスターデータ投入完了: $count 件');
    } catch (e, stackTrace) {
      print('❌ エラー: $e');
      print('スタックトレース: $stackTrace');
      rethrow;
    }
  }
  
  /// 特性マスターデータを投入
  Future<void> importTraitMasters() async {
    try {
      print('📦 特性マスターデータ読み込み中...');
      
      final String jsonString = await rootBundle
          .loadString('assets/data/trait_masters_data.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      
      print('✅ JSONファイル読み込み完了');
      
      final batch = _firestore.batch();
      int count = 0;
      
      for (var trait in data['traits']) {
        final traitMap = Map<String, dynamic>.from(trait as Map);
        final docRef = _firestore
            .collection('trait_masters')
            .doc(traitMap['trait_id'].toString());
        
        batch.set(docRef, {
          ...traitMap,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
        count++;
        
        if (count % 500 == 0) {
          await batch.commit();
          print('✅ $count 件の特性マスターを投入');
        }
      }
      
      if (count % 500 != 0) {
        await batch.commit();
      }
      
      print('✅ 特性マスターデータ投入完了: $count 件');
    } catch (e, stackTrace) {
      print('❌ エラー: $e');
      print('スタックトレース: $stackTrace');
      rethrow;
    }
  }

  /// アイテムマスターデータを投入
  Future<void> importItemMasters() async {
    try {
      print('📦 アイテムマスターデータ読み込み中...');
      
      final String jsonString = await rootBundle
          .loadString('assets/data/item_masters_data.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      
      print('✅ JSONファイル読み込み完了');
      
      final batch = _firestore.batch();
      int count = 0;
      
      for (var item in data['items']) {
        final itemMap = Map<String, dynamic>.from(item as Map);
        final docRef = _firestore
            .collection('item_masters')
            .doc(itemMap['item_id'].toString());
        
        batch.set(docRef, {
          ...itemMap,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
        count++;
        
        if (count % 500 == 0) {
          await batch.commit();
          print('✅ $count 件のアイテムマスターを投入');
        }
      }
      
      if (count % 500 != 0) {
        await batch.commit();
      }
      
      print('✅ アイテムマスターデータ投入完了: $count 件');
    } catch (e, stackTrace) {
      print('❌ エラー: $e');
      print('スタックトレース: $stackTrace');
      rethrow;
    }
  }

  /// ★追加: 素材マスターデータを投入
  Future<void> importMaterialMasters() async {
    try {
      print('📦 素材マスターデータ読み込み中...');
      
      final String jsonString = await rootBundle
          .loadString('assets/data/material_masters_data.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      
      print('✅ JSONファイル読み込み完了');
      
      final batch = _firestore.batch();
      int count = 0;
      
      for (var material in data['materials']) {
        final materialMap = Map<String, dynamic>.from(material as Map);
        final docRef = _firestore
            .collection('material_masters')
            .doc(materialMap['material_id'].toString());
        
        batch.set(docRef, {
          ...materialMap,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
        count++;
      }
      
      await batch.commit();
      
      print('✅ 素材マスターデータ投入完了: $count 件');
    } catch (e, stackTrace) {
      print('❌ エラー: $e');
      print('スタックトレース: $stackTrace');
      rethrow;
    }
  }

  /// ★追加: 探索先マスターデータを投入
  Future<void> importDispatchLocations() async {
    try {
      print('📦 探索先マスターデータ読み込み中...');
      
      final String jsonString = await rootBundle
          .loadString('assets/data/dispatch_locations.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      
      print('✅ JSONファイル読み込み完了');
      
      final batch = _firestore.batch();
      int count = 0;
      
      for (var location in data['dispatch_locations']) {
        final locationMap = Map<String, dynamic>.from(location as Map);
        final docRef = _firestore
            .collection('dispatch_locations')
            .doc(locationMap['location_id'].toString());
        
        batch.set(docRef, {
          ...locationMap,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
        count++;
      }
      
      await batch.commit();
      
      print('✅ 探索先マスターデータ投入完了: $count 件');
    } catch (e, stackTrace) {
      print('❌ エラー: $e');
      print('スタックトレース: $stackTrace');
      rethrow;
    }
  }
  
  /// すべてのマスターデータを一括投入
  Future<Map<String, int>> importAllMasterData() async {
    print('');
    print('====================================');
    print('📦 マスターデータ投入開始...');
    print('====================================');
    print('');
    
    final Map<String, int> results = {};
    
    try {
      await importMonsterMasters();
      results['monsters'] = await _getCollectionCount('monster_masters');
      print('');
      
      await importSkillMasters();
      print('');
      
      await importAdditionalSkills();
      results['skills'] = await _getCollectionCount('skill_masters');
      print('');
      
      await importEquipmentMasters();
      results['equipment'] = await _getCollectionCount('equipment_masters');
      print('');
      
      await importTraitMasters();
      results['traits'] = await _getCollectionCount('trait_masters');
      print('');

      await importStageMasters();
      results['stages'] = await _getCollectionCount('stage_masters');
      print('');

      await importItemMasters();
      results['items'] = await _getCollectionCount('item_masters');
      print('');

      await importMaterialMasters();
      results['materials'] = await _getCollectionCount('material_masters');
      print('');

      await importDispatchLocations();
      results['dispatch_locations'] = await _getCollectionCount('dispatch_locations');
      print('');
      
      print('====================================');
      print('🎉 すべてのマスターデータ投入完了！');
      print('====================================');
      
      return results;
    } catch (e, stackTrace) {
      print('');
      print('====================================');
      print('❌ マスターデータ投入失敗');
      print('====================================');
      print('エラー: $e');
      print('スタックトレース: $stackTrace');
      rethrow;
    }
  }
  
  /// データ検証
  Future<Map<String, int>> validateData() async {
    print('');
    print('====================================');
    print('🔍 データ検証開始...');
    print('====================================');
    print('');
    
    final results = <String, int>{};
    
    try {
      results['monsters'] = await _getCollectionCount('monster_masters');
      print('✅ モンスター数: ${results['monsters']} / 30 (目標)');
      
      results['skills'] = await _getCollectionCount('skill_masters');
      print('✅ 技数: ${results['skills']} / 26+ (目標)');
      
      results['equipment'] = await _getCollectionCount('equipment_masters');
      print('✅ 装備数: ${results['equipment']} / 22+ (目標)');
      
      results['traits'] = await _getCollectionCount('trait_masters');
      print('✅ 特性数: ${results['traits']} / 56 (目標)');

      results['items'] = await _getCollectionCount('item_masters');
      print('✅ アイテム数: ${results['items']} / 12 (目標)');

      results['materials'] = await _getCollectionCount('material_masters');
      print('✅ 素材数: ${results['materials']} / 21 (目標)');

      results['dispatch_locations'] = await _getCollectionCount('dispatch_locations');
      print('✅ 探索先数: ${results['dispatch_locations']} / 3 (目標)');
      
      print('');
      print('====================================');
      print('🎉 データ検証完了！');
      print('====================================');
      
      return results;
    } catch (e) {
      print('');
      print('====================================');
      print('❌ データ検証失敗: $e');
      print('====================================');
      rethrow;
    }
  }
  
  /// コレクションの件数を取得
  Future<int> _getCollectionCount(String collectionName) async {
    final snapshot = await _firestore.collection(collectionName).get();
    return snapshot.docs.length;
  }
  
  /// 特定のコレクションを削除（開発用）
  Future<void> deleteCollection(String collectionName) async {
    print('⚠️  $collectionName コレクションを削除中...');
    
    final snapshot = await _firestore.collection(collectionName).get();
    final batch = _firestore.batch();
    int count = 0;
    
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
      count++;
      
      if (count % 500 == 0) {
        await batch.commit();
        print('削除済み: $count 件');
      }
    }
    
    if (count % 500 != 0) {
      await batch.commit();
    }
    
    print('✅ $collectionName コレクション削除完了: $count 件');
  }
  
  /// 追加技データを投入
  Future<void> importAdditionalSkills() async {
    try {
      print('📦 追加技データ読み込み中...');
      
      final String jsonString = await rootBundle
          .loadString('assets/data/additional_skills.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      
      print('✅ JSONファイル読み込み完了');
      
      final batch = _firestore.batch();
      int count = 0;
      
      for (var skill in data['additional_skills']) {
        final skillMap = Map<String, dynamic>.from(skill as Map);
        final docRef = _firestore
            .collection('skill_masters')
            .doc(skillMap['skill_id'].toString());
        
        batch.set(docRef, {
          ...skillMap,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
        count++;
      }
      
      await batch.commit();
      
      print('✅ 追加技データ投入完了: $count 件');
    } catch (e, stackTrace) {
      print('❌ エラー: $e');
      print('スタックトレース: $stackTrace');
      rethrow;
    }
  }

  /// 統一技マスタデータを投入
  Future<void> importUnifiedSkillMasters() async {
    try {
      print('🔥 統一技マスタデータ読み込み中...');
      
      final jsonString = await rootBundle.loadString('assets/data/skill_masters_unified.json');
      final data = json.decode(jsonString) as Map<String, dynamic>;
      final skills = data['skills'] as List<dynamic>;

      print('📊 ${skills.length}件の技データを投入します...');

      final batch = _firestore.batch();
      int count = 0;

      for (var skillData in skills) {
        final docRef = _firestore
            .collection('skill_masters')
            .doc(skillData['skill_id']);
        
        batch.set(docRef, skillData, SetOptions(merge: true));
        count++;
      }

      await batch.commit();
      print('✅ 技マスタデータ投入完了: $count件');
    } catch (e) {
      print('❌ 技マスタデータ投入エラー: $e');
      rethrow;
    }
  }

  /// 冒険システム用マスタデータ一括投入
  Future<void> importAdventureSystemData() async {
    try {
      print('🚀 冒険システム用マスタデータ投入開始...');
      print('');
      
      await importUnifiedSkillMasters();
      print('');
      
      await importStageMasters();
      print('');
      
      print('✅ 冒険システム用マスタデータ投入完了！');
    } catch (e) {
      print('❌ マスタデータ投入失敗: $e');
      rethrow;
    }
  }

  /// ステージマスタデータを投入
  Future<void> importStageMasters() async {
    try {
      print('🗺️ ステージマスタデータ読み込み中...');
      
      final jsonString = await rootBundle.loadString('assets/data/stage_masters.json');
      final data = json.decode(jsonString) as Map<String, dynamic>;
      final stages = data['stages'] as List<dynamic>;

      print('📊 ${stages.length}件のステージデータを投入します...');

      final batch = _firestore.batch();
      int count = 0;

      for (var stageData in stages) {
        final docRef = _firestore
            .collection('stage_masters')
            .doc(stageData['stage_id']);
        
        batch.set(docRef, stageData);
        count++;
      }

      await batch.commit();
      print('✅ ステージマスタデータ投入完了: $count件');
    } catch (e) {
      print('❌ ステージマスタデータ投入エラー: $e');
      rethrow;
    }
  }

  /// 全マスタデータ投入（拡張版）
  Future<void> importAllMasterDataExtended() async {
    try {
      print('🚀 全マスタデータ投入開始...');
      
      await importUnifiedSkillMasters();
      await importStageMasters();
      await importMaterialMasters();
      await importDispatchLocations();
      
      print('✅ 全マスタデータ投入完了！');
    } catch (e) {
      print('❌ マスタデータ投入失敗: $e');
      rethrow;
    }
  }

  /// ★追加: 探索システム用データのみ投入
  Future<void> importDispatchSystemData() async {
    try {
      print('🚀 探索システム用マスタデータ投入開始...');
      print('');
      
      await importMaterialMasters();
      print('');
      
      await importDispatchLocations();
      print('');
      
      print('✅ 探索システム用マスタデータ投入完了！');
    } catch (e) {
      print('❌ マスタデータ投入失敗: $e');
      rethrow;
    }
  }
  
  /// すべてのマスターデータを削除（開発用）
  Future<void> deleteAllMasterData() async {
    print('');
    print('====================================');
    print('⚠️  すべてのマスターデータを削除中...');
    print('====================================');
    print('');
    
    await deleteCollection('monster_masters');
    await deleteCollection('skill_masters');
    await deleteCollection('equipment_masters');
    await deleteCollection('trait_masters');
    await deleteCollection('material_masters');
    await deleteCollection('dispatch_locations');
    
    print('');
    print('====================================');
    print('✅ すべてのマスターデータ削除完了');
    print('====================================');
  }

  // ============================================================
  // 開発用ユーザーデータ付与機能
  // ============================================================

  /// 開発ユーザーにアイテムを付与
  Future<void> grantItemsToUser({
    required String userId,
    required Map<String, int> items,
  }) async {
    if (items.isEmpty) return;

    try {
      print('🎁 アイテム付与開始: $userId');
      
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
          print('  📦 ${entry.key}: +${entry.value} (合計: ${currentQty + entry.value})');
        } else {
          batch.set(docRef, {
            'user_id': userId,
            'item_id': entry.key,
            'quantity': entry.value,
            'acquired_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          });
          print('  📦 ${entry.key}: +${entry.value} (新規)');
        }
      }
      
      await batch.commit();
      print('✅ アイテム付与完了: ${items.length}種類');
    } catch (e) {
      print('❌ アイテム付与エラー: $e');
      rethrow;
    }
  }

  /// ★追加: 開発ユーザーに素材を付与
  Future<void> grantMaterialsToUser({
    required String userId,
    required Map<String, int> materials,
  }) async {
    if (materials.isEmpty) return;

    try {
      print('🎁 素材付与開始: $userId');
      
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
          print('  🧱 ${entry.key}: +${entry.value} (合計: ${currentQty + entry.value})');
        } else {
          batch.set(docRef, {
            'user_id': userId,
            'material_id': entry.key,
            'quantity': entry.value,
            'acquired_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          });
          print('  🧱 ${entry.key}: +${entry.value} (新規)');
        }
      }
      
      await batch.commit();
      print('✅ 素材付与完了: ${materials.length}種類');
    } catch (e) {
      print('❌ 素材付与エラー: $e');
      rethrow;
    }
  }

  /// 開発ユーザーに通貨を付与
  Future<void> grantCurrencyToUser({
    required String userId,
    int coin = 0,
    int stone = 0,
    int gem = 0,
  }) async {
    try {
      print('💰 通貨付与開始: $userId');
      
      final userDoc = _firestore.collection('users').doc(userId);
      final doc = await userDoc.get();
      
      if (doc.exists) {
        final data = doc.data()!;
        final updates = <String, dynamic>{
          'updated_at': FieldValue.serverTimestamp(),
        };
        
        if (coin > 0) {
          final currentCoin = data['coin'] as int? ?? 0;
          updates['coin'] = currentCoin + coin;
          print('  🪙 コイン: +$coin (合計: ${currentCoin + coin})');
        }
        if (stone > 0) {
          final currentStone = data['stone'] as int? ?? 0;
          updates['stone'] = currentStone + stone;
          print('  💎 石: +$stone (合計: ${currentStone + stone})');
        }
        if (gem > 0) {
          final currentGem = data['gem'] as int? ?? 0;
          updates['gem'] = currentGem + gem;
          print('  💠 ジェム: +$gem (合計: ${currentGem + gem})');
        }
        
        await userDoc.update(updates);
      } else {
        await userDoc.set({
          'user_id': userId,
          'coin': coin,
          'stone': stone,
          'gem': gem,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
        print('  🪙 コイン: $coin');
        print('  💎 石: $stone');
        print('  💠 ジェム: $gem');
      }
      
      print('✅ 通貨付与完了');
    } catch (e) {
      print('❌ 通貨付与エラー: $e');
      rethrow;
    }
  }

  /// 開発ユーザーのモンスターHP全回復
  Future<void> healAllMonsters(String userId) async {
    try {
      print('💚 モンスターHP全回復開始: $userId');
      
      final snapshot = await _firestore
          .collection('user_monsters')
          .where('user_id', isEqualTo: userId)
          .get();
      
      if (snapshot.docs.isEmpty) {
        print('⚠️ モンスターが見つかりません');
        return;
      }
      
      final batch = _firestore.batch();
      int count = 0;
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final baseHp = data['base_hp'] as int? ?? 100;
        final ivHp = data['iv_hp'] as int? ?? 0;
        final pointHp = data['point_hp'] as int? ?? 0;
        final level = data['level'] as int? ?? 1;
        final maxHp = baseHp + ivHp + pointHp + (level * 2);
        
        batch.update(doc.reference, {
          'current_hp': maxHp,
          'last_hp_update': FieldValue.serverTimestamp(),
        });
        count++;
      }
      
      await batch.commit();
      print('✅ HP全回復完了: $count体');
    } catch (e) {
      print('❌ HP全回復エラー: $e');
      rethrow;
    }
  }

  /// ★追加: ボス撃破済みフラグを設定（探索先解放用）
  Future<void> setBossDefeated(String userId, String stageId) async {
    try {
      print('🏆 ボス撃破済み設定: $userId - $stageId');
      
      final docRef = _firestore
          .collection('user_adventure_progress')
          .doc('${userId}_$stageId');
      
      final doc = await docRef.get();
      
      if (doc.exists) {
        await docRef.update({
          'boss_defeated': true,
          'last_updated': FieldValue.serverTimestamp(),
        });
      } else {
        await docRef.set({
          'user_id': userId,
          'stage_id': stageId,
          'encounter_count': 0,
          'boss_unlocked': false,
          'boss_defeated': true,
          'last_updated': FieldValue.serverTimestamp(),
        });
      }
      
      print('✅ ボス撃破済み設定完了');
    } catch (e) {
      print('❌ ボス撃破済み設定エラー: $e');
      rethrow;
    }
  }

  /// 開発用：初期アイテムセット付与
  Future<void> grantDevStarterPack(String userId) async {
    print('');
    print('====================================');
    print('🎁 開発用スターターパック付与開始');
    print('====================================');
    print('');
    
    await grantItemsToUser(
      userId: userId,
      items: {
        'potion_small': 99,
        'potion_medium': 50,
        'potion_large': 20,
        'revive_half': 30,
        'revive_full': 10,
        'status_heal': 30,
        'exp_small': 50,
        'exp_medium': 30,
        'exp_large': 10,
        'intimacy_treat': 30,
        'reset_points': 5,
        'trait_stone': 3,
      },
    );
    
    print('');
    
    await grantMaterialsToUser(
      userId: userId,
      materials: {
        'iron_ore': 100,
        'magic_ore': 50,
        'mithril_ore': 20,
        'fire_fragment': 50,
        'water_fragment': 50,
        'thunder_fragment': 50,
        'forest_moss': 50,
        'forest_wood': 50,
        'fire_crystal': 30,
        'lava_stone': 30,
        'dragon_scale': 10,
        'boss_proof': 5,
      },
    );
    
    print('');
    
    await grantCurrencyToUser(
      userId: userId,
      coin: 100000,
      stone: 1000,
      gem: 500,
    );
    
    print('');
    
    await healAllMonsters(userId);
    
    print('');
    
    // 探索先解放のためにボス撃破済みを設定
    await setBossDefeated(userId, 'stage_001');
    await setBossDefeated(userId, 'stage_002');
    
    print('');
    print('====================================');
    print('🎉 スターターパック付与完了！');
    print('====================================');
  }
}