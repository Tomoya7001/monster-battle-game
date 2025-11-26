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
        
        // Firestoreのバッチ制限は500件
        if (count % 500 == 0) {
          await batch.commit();
          print('✅ $count 件のモンスターマスターを投入');
        }
      }
      
      // 残りをコミット
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
  
  /// すべてのマスターデータを一括投入
  Future<Map<String, int>> importAllMasterData() async {
    print('');
    print('====================================');
    print('📦 マスターデータ投入開始...');
    print('====================================');
    print('');
    
    final Map<String, int> results = {};
    
    try {
      // モンスター
      await importMonsterMasters();
      results['monsters'] = await _getCollectionCount('monster_masters');
      print('');
      
      // 技
      await importSkillMasters();
      print('');
      
      // 追加技
      await importAdditionalSkills();
      results['skills'] = await _getCollectionCount('skill_masters');
      print('');
      
      // 装備
      await importEquipmentMasters();
      results['equipment'] = await _getCollectionCount('equipment_masters');
      print('');
      
      // 特性
      await importTraitMasters();
      results['traits'] = await _getCollectionCount('trait_masters');
      print('');

      // ★追加: ステージ
      await importStageMasters();
      results['stages'] = await _getCollectionCount('stage_masters');
      print('');

      // アイテム
      await importItemMasters();
      results['items'] = await _getCollectionCount('item_masters');
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
      print('✅ アイテム数: ${results['items']} / 20 (目標)');
      
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
      
      print('✅ 全マスタデータ投入完了！');
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
    
    print('');
    print('====================================');
    print('✅ すべてのマスターデータ削除完了');
    print('====================================');
  }
}


/*
// lib/utils/data_importer.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class DataImporter {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// モンスターマスターデータを投入
  Future<void> importMonsters({
    Function(int current, int total)? onProgress,
  }) async {
    final jsonString = await rootBundle.loadString('assets/data/monster_masters_data.json');
    final jsonData = Map<String, dynamic>.from(json.decode(jsonString) as Map);
    final List<dynamic> data = List<dynamic>.from(jsonData['monsters'] as List);
    
    final batch = _firestore.batch();
    int count = 0;
    
    for (var item in data) {
      final itemMap = Map<String, dynamic>.from(item as Map);
      final docRef = _firestore.collection('monster_masters').doc(itemMap['monster_id'].toString());
      batch.set(docRef, {
        ...itemMap,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      count++;
      if (count % 500 == 0) {
        await batch.commit();
        onProgress?.call(count, data.length);
      }
    }
    
    if (count % 500 != 0) {
      await batch.commit();
    }
    
    onProgress?.call(data.length, data.length);
  }

  /// 技マスターデータを投入
  Future<void> importSkills({
    Function(int current, int total)? onProgress,
  }) async {
    final jsonString = await rootBundle.loadString('assets/data/skill_masters_data.json');
    final jsonData = Map<String, dynamic>.from(json.decode(jsonString) as Map);
    final List<dynamic> data = List<dynamic>.from(jsonData['skills'] as List);
    
    final batch = _firestore.batch();
    int count = 0;
    
    for (var item in data) {
      final itemMap = Map<String, dynamic>.from(item as Map);
      final docRef = _firestore.collection('skill_masters').doc(itemMap['skill_id'].toString());
      batch.set(docRef, {
        ...itemMap,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      count++;
      if (count % 500 == 0) {
        await batch.commit();
        onProgress?.call(count, data.length);
      }
    }
    
    if (count % 500 != 0) {
      await batch.commit();
    }
    
    onProgress?.call(data.length, data.length);
  }

  /// 装備マスターデータを投入
  Future<void> importEquipment({
    Function(int current, int total)? onProgress,
  }) async {
    final jsonString = await rootBundle.loadString('assets/data/equipment_masters_data.json');
    final jsonData = Map<String, dynamic>.from(json.decode(jsonString) as Map);
    final List<dynamic> data = List<dynamic>.from(jsonData['equipment'] as List);
    
    final batch = _firestore.batch();
    int count = 0;
    
    for (var item in data) {
      final itemMap = Map<String, dynamic>.from(item as Map);
      final docRef = _firestore.collection('equipment_masters').doc(itemMap['equipment_id'].toString());
      batch.set(docRef, {
        ...itemMap,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      count++;
      if (count % 500 == 0) {
        await batch.commit();
        onProgress?.call(count, data.length);
      }
    }
    
    if (count % 500 != 0) {
      await batch.commit();
    }
    
    onProgress?.call(data.length, data.length);
  }

  /// 特性マスターデータを投入
  Future<void> importTraits({
    Function(int current, int total)? onProgress,
  }) async {
    final jsonString = await rootBundle.loadString('assets/data/trait_masters_data.json');
    final jsonData = Map<String, dynamic>.from(json.decode(jsonString) as Map);
    final List<dynamic> data = List<dynamic>.from(jsonData['traits'] as List);
    
    final batch = _firestore.batch();
    int count = 0;
    
    for (var item in data) {
      final itemMap = Map<String, dynamic>.from(item as Map);
      final docRef = _firestore.collection('trait_masters').doc(itemMap['trait_id'].toString());
      batch.set(docRef, {
        ...itemMap,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      count++;
      if (count % 500 == 0) {
        await batch.commit();
        onProgress?.call(count, data.length);
      }
    }
    
    if (count % 500 != 0) {
      await batch.commit();
    }
    
    onProgress?.call(data.length, data.length);
  }

  /// 全データを一括投入
  Future<void> importAll({
    Function(String task, int current, int total)? onProgress,
  }) async {
    await importMonsters(
      onProgress: (c, t) => onProgress?.call('モンスター', c, t),
    );
    await importSkills(
      onProgress: (c, t) => onProgress?.call('技', c, t),
    );
    await importEquipment(
      onProgress: (c, t) => onProgress?.call('装備', c, t),
    );
    await importTraits(
      onProgress: (c, t) => onProgress?.call('特性', c, t),
    );
  }

  /// データ削除（開発用）
  Future<void> deleteAll() async {
    final collections = [
      'monster_masters',
      'skill_masters',
      'equipment_masters',
      'trait_masters',
    ];

    for (var collection in collections) {
      final snapshot = await _firestore.collection(collection).get();
      final batch = _firestore.batch();
      
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    }
  }
}
*/