// lib/services/gacha_service.dart
// ガチャシステムのビジネスロジック

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ガチャ結果
class GachaResult {
  final String userMonsterId;
  final Map<String, dynamic> monsterMaster;
  final int rarity;
  final Map<String, int> individualValues;
  final Map<String, dynamic> mainTrait;
  
  GachaResult({
    required this.userMonsterId,
    required this.monsterMaster,
    required this.rarity,
    required this.individualValues,
    required this.mainTrait,
  });
}

/// ガチャサービス
class GachaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();
  
  // ガチャ排出率（week4_balance_config.yamlより）
  static const double RATE_5_STAR = 0.02;  // 2%
  static const double RATE_4_STAR = 0.08;  // 8%
  static const double RATE_3_STAR = 0.30;  // 30%
  static const double RATE_2_STAR = 0.60;  // 60%
  
  /// 単発ガチャを引く
  Future<GachaResult> drawSingle({
    required String userId,
    bool isGuaranteed4Star = false,
  }) async {
    // 1. レアリティ抽選
    final rarity = _determineRarity(isGuaranteed4Star);
    
    // 2. そのレアリティのモンスターマスターを取得
    final monsters = await _getMonstersByRarity(rarity);
    
    if (monsters.isEmpty) {
      throw Exception('レアリティ$rarityのモンスターが存在しません');
    }
    
    // 3. ランダムで1体選択
    final selectedMonster = monsters[_random.nextInt(monsters.length)];
    
    // 4. 個体値生成
    final ivs = _generateIndividualValues();
    
    // 5. メイン特性抽選
    final mainTrait = await _selectMainTrait(selectedMonster);
    
    // 6. UserMonsterドキュメントを作成
    final userMonsterRef = _firestore.collection('user_monsters').doc();
    
    await userMonsterRef.set({
      'user_id': userId,
      'monster_id': selectedMonster['monster_id'],
      'level': 1,
      'exp': 0,
      'individual_values': ivs,
      'stat_points': {
        'hp': 0,
        'attack': 0,
        'defense': 0,
        'magic': 0,
        'speed': 0,
      },
      'main_trait_id': mainTrait['trait_id'],
      'sub_traits': [],
      'equipped_skills': _getInitialSkills(selectedMonster),
      'affection_level': 0,
      'obtained_at': FieldValue.serverTimestamp(),
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
    
    return GachaResult(
      userMonsterId: userMonsterRef.id,
      monsterMaster: selectedMonster,
      rarity: rarity,
      individualValues: ivs,
      mainTrait: mainTrait,
    );
  }
  
  /// 10連ガチャを引く
  Future<List<GachaResult>> draw10Pull({
    required String userId,
  }) async {
    final results = <GachaResult>[];
    
    for (int i = 0; i < 10; i++) {
      // 10連目は★4以上確定
      final isGuaranteed = (i == 9);
      
      final result = await drawSingle(
        userId: userId,
        isGuaranteed4Star: isGuaranteed,
      );
      
      results.add(result);
    }
    
    return results;
  }
  
  /// レアリティを抽選
  int _determineRarity(bool isGuaranteed4Star) {
    if (isGuaranteed4Star) {
      // ★4以上確定の場合
      final rand = _random.nextDouble();
      // ★5: 2% ÷ 17% = 11.76%
      // ★4: 15% ÷ 17% = 88.24%
      return rand < (RATE_5_STAR / (RATE_5_STAR + RATE_4_STAR)) ? 5 : 4;
    }
    
    final rand = _random.nextDouble();
    
    // ★5: 2%
    if (rand < RATE_5_STAR) return 5;
    
    // ★4: 15% (累計17%)
    if (rand < RATE_5_STAR + RATE_4_STAR) return 4;
    
    // ★3: 30% (累計47%)
    if (rand < RATE_5_STAR + RATE_4_STAR + RATE_3_STAR) return 3;
    
    // ★2: 53% (累計100%)
    return 2;
  }
  
  /// 指定レアリティのモンスターマスターを取得
  Future<List<Map<String, dynamic>>> _getMonstersByRarity(int rarity) async {
    final snapshot = await _firestore
        .collection('monster_masters')
        .where('rarity', isEqualTo: rarity)
        .get();
    
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['_doc_id'] = doc.id; // ドキュメントIDも保存
      return data;
    }).toList();
  }
  
  /// 個体値を生成（各ステータス±0~10）
  Map<String, int> _generateIndividualValues() {
    return {
      'hp': _random.nextInt(11),      // 0-10
      'attack': _random.nextInt(11),
      'defense': _random.nextInt(11),
      'magic': _random.nextInt(11),
      'speed': _random.nextInt(11),
    };
  }
  
  /// メイン特性を抽選
  Future<Map<String, dynamic>> _selectMainTrait(
    Map<String, dynamic> monster,
  ) async {
    final traits = monster['traits'] as Map<String, dynamic>;
    final traitPool = traits['main_trait_pool'] as List<dynamic>;
    
    // 確率の正規化
    double totalProbability = 0.0;
    for (var trait in traitPool) {
      totalProbability += (trait['probability'] as num).toDouble();
    }
    
    // 抽選
    final rand = _random.nextDouble() * totalProbability;
    double cumulative = 0.0;
    
    for (var trait in traitPool) {
      cumulative += (trait['probability'] as num).toDouble();
      if (rand < cumulative) {
        // 特性マスターから詳細情報を取得
        return await _getTraitMaster(trait['trait_id']);
      }
    }
    
    // フォールバック（通常特性を返す）
    final normalTrait = traitPool.firstWhere(
      (t) => t['rarity'] == 'normal',
      orElse: () => traitPool.first,
    );
    return await _getTraitMaster(normalTrait['trait_id']);
  }
  
  /// 特性マスターを取得
  Future<Map<String, dynamic>> _getTraitMaster(int traitId) async {
    final doc = await _firestore
        .collection('trait_masters')
        .doc(traitId.toString())
        .get();
    
    if (!doc.exists) {
      throw Exception('特性ID $traitId が見つかりません');
    }
    
    return doc.data()!;
  }
  
  /// 初期技を取得
  List<int> _getInitialSkills(Map<String, dynamic> monster) {
    final skillPool = monster['skill_pool'] as List<dynamic>;
    
    // 最初の4つ（または5つ）の技を返す
    // TODO: レベル1で習得できる技のみをフィルタリング
    return skillPool.take(4).map((e) => e as int).toList();
  }
  
  /// ユーザーの石を消費
  Future<void> consumeStones({
    required String userId,
    required int amount,
  }) async {
    final userRef = _firestore.collection('users').doc(userId);
    
    await _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      
      if (!userDoc.exists) {
        throw Exception('ユーザーが存在しません');
      }
      
      final currentStones = userDoc.data()!['stones'] as int;
      
      if (currentStones < amount) {
        throw Exception('石が不足しています');
      }
      
      transaction.update(userRef, {
        'stones': currentStones - amount,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }
  
  /// ユーザーのガチャチケットを消費
  Future<void> consumeTickets({
    required String userId,
    required int amount,
  }) async {
    final userRef = _firestore.collection('users').doc(userId);
    
    await _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      
      if (!userDoc.exists) {
        throw Exception('ユーザーが存在しません');
      }
      
      final currentTickets = userDoc.data()!['gacha_tickets'] as int;
      
      if (currentTickets < amount) {
        throw Exception('ガチャチケットが不足しています');
      }
      
      transaction.update(userRef, {
        'gacha_tickets': currentTickets - amount,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }
  
  /// 単発ガチャの実行（石消費込み）
  Future<GachaResult> executeSingleGacha({
    required String userId,
    required bool useTicket,
  }) async {
    // 1. 石またはチケットを消費
    if (useTicket) {
      await consumeTickets(userId: userId, amount: 1);
    } else {
      await consumeStones(userId: userId, amount: 100); // 単発100石
    }
    
    // 2. ガチャを引く
    return await drawSingle(userId: userId);
  }
  
  /// 10連ガチャの実行（石消費込み）
  Future<List<GachaResult>> execute10PullGacha({
    required String userId,
    required bool useTicket,
  }) async {
    // 1. 石またはチケットを消費
    if (useTicket) {
      await consumeTickets(userId: userId, amount: 10);
    } else {
      await consumeStones(userId: userId, amount: 900); // 10連900石（10%オフ）
    }
    
    // 2. ガチャを引く
    return await draw10Pull(userId: userId);
  }
}