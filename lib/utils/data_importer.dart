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