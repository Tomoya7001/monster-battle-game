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
        final docRef = _firestore
            .collection('monster_masters')
            .doc(monster['monster_id'].toString());
        
        batch.set(docRef, {
          ...monster,
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
        final docRef = _firestore
            .collection('skill_masters')
            .doc(skill['skill_id'].toString());
        
        batch.set(docRef, {
          ...skill,
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
        final docRef = _firestore
            .collection('equipment_masters')
            .doc(equipment['equipment_id'].toString());
        
        batch.set(docRef, {
          ...equipment,
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
        final docRef = _firestore
            .collection('trait_masters')
            .doc(trait['trait_id'].toString());
        
        batch.set(docRef, {
          ...trait,
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