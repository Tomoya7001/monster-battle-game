// lib/repositories/gacha_repository.dart

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/monster.dart';
import '../models/user_monster.dart';

class GachaRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();
  
  /// ガチャを1回引く
  Future<UserMonster> drawGacha({
    required String userId,
    bool isGuaranteed4Star = false,
  }) async {
    // 1. レアリティ抽選
    final rarity = _determineRarity(isGuaranteed4Star);
    
    // 2. そのレアリティのモンスターを取得
    final monsters = await _getMonstersByRarity(rarity);
    
    // 3. ランダムで1体選択
    final selectedMonster = monsters[_random.nextInt(monsters.length)];
    
    // 4. 個体値生成
    final ivs = _generateIndividualValues();
    
    // 5. メイン特性抽選
    final mainTrait = _selectMainTrait(selectedMonster);
    
    // 6. UserMonster作成
    final userMonster = UserMonster(
      id: '', // Firestoreが自動生成
      userId: userId,
      monsterId: selectedMonster['monster_id'],
      level: 1,
      exp: 0,
      individualValues: ivs,
      statPoints: StatPoints(
        hp: 0,
        attack: 0,
        defense: 0,
        magic: 0,
        speed: 0,
      ),
      mainTraitId: mainTrait['trait_id'],
      subTraits: [],
      equippedSkills: [], // 初期技のみ
      affectionLevel: 0,
      obtainedAt: DateTime.now(),
    );
    
    // 7. Firestoreに保存
    final docRef = await _firestore
        .collection('user_monsters')
        .add(userMonster.toJson());
    
    return userMonster.copyWith(id: docRef.id);
  }
  
  /// レアリティ抽選
  int _determineRarity(bool isGuaranteed) {
    if (isGuaranteed) return 4; // ★4以上確定
    
    final rand = _random.nextDouble();
    
    // ★5: 2%
    if (rand < 0.02) return 5;
    
    // ★4: 15% (累計17%)
    if (rand < 0.17) return 4;
    
    // ★3: 30% (累計47%)
    if (rand < 0.47) return 3;
    
    // ★2: 53% (累計100%)
    return 2;
  }
  
  /// 指定レアリティのモンスターを取得
  Future<List<Map<String, dynamic>>> _getMonstersByRarity(int rarity) async {
    final snapshot = await _firestore
        .collection('monster_masters')
        .where('rarity', isEqualTo: rarity)
        .get();
    
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
  
  /// 個体値生成（±0~10）
  Map<String, int> _generateIndividualValues() {
    return {
      'hp': _random.nextInt(11),      // 0-10
      'attack': _random.nextInt(11),
      'defense': _random.nextInt(11),
      'magic': _random.nextInt(11),
      'speed': _random.nextInt(11),
    };
  }
  
  /// メイン特性抽選
  Map<String, dynamic> _selectMainTrait(Map<String, dynamic> monster) {
    final traitPool = monster['traits']['main_trait_pool'] as List;
    final rand = _random.nextDouble();
    
    // 確率に基づいて選択
    double cumulative = 0.0;
    for (var trait in traitPool) {
      cumulative += trait['probability'];
      if (rand < cumulative) {
        return trait;
      }
    }
    
    // フォールバック（通常特性）
    return traitPool.firstWhere((t) => t['rarity'] == 'normal');
  }
  
  /// 10連ガチャ
  Future<List<UserMonster>> draw10Gacha({
    required String userId,
  }) async {
    final results = <UserMonster>[];
    
    for (int i = 0; i < 10; i++) {
      // 10連目は★4以上確定
      final isGuaranteed = (i == 9);
      final monster = await drawGacha(
        userId: userId,
        isGuaranteed4Star: isGuaranteed,
      );
      results.add(monster);
    }
    
    return results;
  }
}