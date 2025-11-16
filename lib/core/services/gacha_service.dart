// lib/core/services/gacha_service.dart

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gacha_ticket.dart';

// ガチャ確率定数
const double RATE_5_STAR = 0.02; // 2%
const double RATE_4_STAR = 0.15; // 15%
const double RATE_3_STAR = 0.30; // 30%
const double RATE_2_STAR = 0.53; // 53%

/// ガチャ結果モデル
class GachaResult {
  final String userMonsterId;
  final Map<String, dynamic> monsterMaster;
  final int rarity;
  final Map<String, int> individualValues;
  final Map<String, dynamic>? mainTrait;

  GachaResult({
    required this.userMonsterId,
    required this.monsterMaster,
    required this.rarity,
    required this.individualValues,
    this.mainTrait,
  });
}

/// ガチャサービス
class GachaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  // ========================================
  // ガチャ実行
  // ========================================

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

  // 6. マスターデータから基礎HP取得
  final baseStats =
      selectedMonster['base_stats'] as Map<String, dynamic>? ?? {};
  final baseHp = baseStats['hp'] as int? ?? 100;
  final initialHp = baseHp + ivs['hp']!;

  // ✅ 修正: ドキュメントIDを使用
  final monsterDocId = selectedMonster['_document_id'] as String? ?? 
                       selectedMonster['monster_id'].toString();

  // 7. UserMonsterドキュメントを作成
  final userMonsterRef = _firestore.collection('user_monsters').doc();

  await userMonsterRef.set({
    'user_id': userId,
    'monster_id': monsterDocId, // ✅ 修正: 文字列のドキュメントIDを使用
    'level': 1,
    'exp': 0,
    'current_hp': initialHp > 0 ? initialHp : 1,
    'last_hp_update': FieldValue.serverTimestamp(),
    'intimacy_level': 1,
    'intimacy_exp': 0,
    'iv_hp': ivs['hp'],
    'iv_attack': ivs['attack'],
    'iv_defense': ivs['defense'],
    'iv_magic': ivs['magic'],
    'iv_speed': ivs['speed'],
    'point_hp': 0,
    'point_attack': 0,
    'point_defense': 0,
    'point_magic': 0,
    'point_speed': 0,
    'remaining_points': 0,
    'main_trait_id': mainTrait?['trait_id']?.toString(),
    'equipped_skills': _getInitialSkills(selectedMonster),
    'equipped_equipment': <String>[],
    'skin_id': 1,
    'is_favorite': false,
    'is_locked': false,
    'acquired_at': FieldValue.serverTimestamp(),
    'last_used_at': null,
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

    // 通常抽選
    final rand = _random.nextDouble();

    if (rand < RATE_5_STAR) {
      return 5;
    } else if (rand < RATE_5_STAR + RATE_4_STAR) {
      return 4;
    } else if (rand < RATE_5_STAR + RATE_4_STAR + RATE_3_STAR) {
      return 3;
    } else {
      return 2;
    }
  }

  /// 指定レアリティのモンスターマスターを取得
  Future<List<Map<String, dynamic>>> _getMonstersByRarity(int rarity) async {
    final snapshot = await _firestore
        .collection('monster_masters')
        .where('rarity', isEqualTo: rarity)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      // ✅ 修正: ドキュメントIDを文字列として保存（monster_idとは別）
      data['_document_id'] = doc.id;
      // monster_idが存在しない場合のみ設定
      if (!data.containsKey('monster_id')) {
        data['monster_id'] = doc.id;
      }
      return data;
    }).toList();
  }

  /// 個体値生成（0〜10）
  Map<String, int> _generateIndividualValues() {
    return {
      'hp': _random.nextInt(11),
      'attack': _random.nextInt(11),
      'defense': _random.nextInt(11),
      'magic': _random.nextInt(11),
      'speed': _random.nextInt(11),
    };
  }

  /// メイン特性抽選
  Future<Map<String, dynamic>?> _selectMainTrait(
      Map<String, dynamic> monster) async {
    final traitsData = monster['traits'];

    if (traitsData == null) {
      return null;
    }

    List<dynamic>? traitPool;

    if (traitsData is Map<String, dynamic>) {
      traitPool = traitsData['main_trait_pool'] as List<dynamic>?;
    } else if (traitsData is List) {
      traitPool = traitsData;
    }

    if (traitPool == null || traitPool.isEmpty) {
      return null;
    }

    final rand = _random.nextDouble();
    double cumulative = 0.0;

    for (var trait in traitPool) {
      if (trait is Map<String, dynamic>) {
        final probability = (trait['probability'] as num?)?.toDouble() ?? 0.0;
        cumulative += probability;
        if (rand < cumulative) {
          return trait;
        }
      }
    }

    // フォールバック: 最初の特性を返す
    if (traitPool.first is Map<String, dynamic>) {
      return traitPool.first as Map<String, dynamic>;
    }

    return null;
  }

  /// 初期技を取得
  List<String> _getInitialSkills(Map<String, dynamic> monster) {
    final initialSkills = monster['initial_skills'];

    if (initialSkills == null) {
      return <String>[];
    }

    if (initialSkills is List) {
      return initialSkills.map((e) => e.toString()).toList();
    }

    return <String>[];
  }

  // ========================================
  // チケット管理
  // ========================================

  /// チケット残高を取得
  Future<int> getTicketBalance(String userId) async {
    final doc =
        await _firestore.collection('user_gacha_tickets').doc(userId).get();

    if (!doc.exists) {
      // 初期化
      await _firestore.collection('user_gacha_tickets').doc(userId).set({
        'ticketCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return 0;
    }

    return doc.data()!['ticketCount'] as int? ?? 0;
  }

  /// チケットを追加
  Future<void> addTickets(String userId, int count) async {
    final docRef = _firestore.collection('user_gacha_tickets').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);

      if (!doc.exists) {
        transaction.set(docRef, {
          'ticketCount': count,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final currentCount = doc.data()!['ticketCount'] as int? ?? 0;
        transaction.update(docRef, {
          'ticketCount': currentCount + count,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// チケット交換オプションを取得
  Future<List<TicketExchangeOption>> getExchangeOptions() async {
    return [
      const TicketExchangeOption(
        id: 'star4_guaranteed',
        name: '★4確定ガチャ',
        requiredTickets: 50,
        rewardType: 'star4',
        guaranteeRate: 100,
        // description削除
      ),
      const TicketExchangeOption(
        id: 'star5_guaranteed',
        name: '★5確定ガチャ',
        requiredTickets: 100,
        rewardType: 'star5',
        guaranteeRate: 100,
        // description削除
      ),
    ];
  }

  /// チケット交換を実行（修正版）
  Future<Map<String, dynamic>> exchangeTickets({
    required String userId,
    required String optionId,
  }) async {
    // オプションを取得
    final options = await getExchangeOptions();
    final option = options.firstWhere(
      (opt) => opt.id == optionId,
      orElse: () => throw Exception('無効な交換オプションID: $optionId'),
    );

    // チケット残高確認
    final balance = await getTicketBalance(userId);

    if (balance < option.requiredTickets) {
      throw Exception('チケットが不足しています');
    }

    // 報酬を決定
    final reward = await _determineExchangeReward(option);

    // チケット消費
    await _consumeTickets(userId, option.requiredTickets);

    // モンスター付与
    await _grantMonster(userId, reward['monsterId'] as String);

    // 履歴記録
    await _recordExchange(userId, option, reward);

    return reward;
  }

  /// 交換報酬を決定
  Future<Map<String, dynamic>> _determineExchangeReward(
      TicketExchangeOption option) async {
    final random = _random.nextDouble();
    String monsterId;
    int rarity;

    if (option.rewardType == 'star5') {
      monsterId = await _getRandomMonster(5);
      rarity = 5;
    } else if (option.rewardType == 'star4') {
      monsterId = await _getRandomMonster(4);
      rarity = 4;
    } else {
      throw Exception('不明な報酬タイプ');
    }

    return {
      'monsterId': monsterId,
      'rarity': rarity,
    };
  }

  /// ランダムモンスター取得
  Future<String> _getRandomMonster(int rarity) async {
    final snapshot = await _firestore
        .collection('monster_masters')
        .where('rarity', isEqualTo: rarity)
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception('レアリティ$rarity のモンスターが見つかりません');
    }

    final randomIndex = _random.nextInt(snapshot.docs.length);
    return snapshot.docs[randomIndex].id;
  }

  /// チケット消費
  Future<void> _consumeTickets(String userId, int count) async {
    final docRef = _firestore.collection('user_gacha_tickets').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);

      if (!doc.exists) {
        throw Exception('チケットデータが見つかりません');
      }

      final currentCount = doc.data()!['ticketCount'] as int;

      if (currentCount < count) {
        throw Exception('チケットが不足しています');
      }

      transaction.update(docRef, {
        'ticketCount': currentCount - count,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// モンスター付与
  Future<void> _grantMonster(String userId, String monsterId) async {
    final monsterDoc =
        await _firestore.collection('monster_masters').doc(monsterId).get();

    if (!monsterDoc.exists) {
      throw Exception('モンスターが見つかりません');
    }

    // マスターデータから基礎HP取得
    final masterData = monsterDoc.data()!;
    final baseStats = masterData['base_stats'] as Map<String, dynamic>? ?? {};
    final baseHp = baseStats['hp'] as int? ?? 100;
    
    // 個体値生成
    final ivHp = _generateIV();
    final ivAttack = _generateIV();
    final ivDefense = _generateIV();
    final ivMagic = _generateIV();
    final ivSpeed = _generateIV();
    
    // 初期HPを計算（Lv1なのでbaseHp + ivHp）
    final initialHp = baseHp + ivHp;

    await _firestore.collection('user_monsters').add({
      'user_id': userId,                   // ✅ snake_case
      'monster_id': monsterId,             // ✅ snake_case
      'level': 1,
      'exp': 0,
      'current_hp': initialHp,             // ✅ 追加
      'last_hp_update': FieldValue.serverTimestamp(),  // ✅ 追加
      'intimacy_level': 1,                 // ✅ snake_case
      'intimacy_exp': 0,                   // ✅ snake_case
      'iv_hp': ivHp,                       // ✅ snake_case
      'iv_attack': ivAttack,               // ✅ snake_case
      'iv_defense': ivDefense,             // ✅ snake_case
      'iv_magic': ivMagic,                 // ✅ snake_case
      'iv_speed': ivSpeed,                 // ✅ snake_case
      'point_hp': 0,                       // ✅ snake_case
      'point_attack': 0,                   // ✅ snake_case
      'point_defense': 0,                  // ✅ snake_case
      'point_magic': 0,                    // ✅ snake_case
      'point_speed': 0,                    // ✅ snake_case
      'remaining_points': 0,               // ✅ snake_case
      'main_trait_id': null,               // ✅ 追加
      'equipped_skills': <String>[],       // ✅ 追加
      'equipped_equipment': <String>[],    // ✅ 追加
      'skin_id': 1,                        // ✅ snake_case
      'is_favorite': false,                // ✅ snake_case
      'is_locked': false,                  // ✅ snake_case
      'acquired_at': FieldValue.serverTimestamp(),  // ✅ snake_case
      'last_used_at': null,                // ✅ 追加
    });
  }

  /// 個体値生成（0〜10）
  int _generateIV() {
    return _random.nextInt(11);
  }

  /// 交換履歴記録
  Future<void> _recordExchange(
    String userId,
    TicketExchangeOption option,
    Map<String, dynamic> reward,
  ) async {
    await _firestore.collection('gacha_ticket_exchange_history').add({
      'userId': userId,
      'optionId': option.id,
      'optionName': option.name,
      'ticketsUsed': option.requiredTickets,
      'monsterId': reward['monsterId'],
      'rarity': reward['rarity'],
      'exchangedAt': FieldValue.serverTimestamp(),
    });
  }

  // ========================================
  // ガチャ履歴関連
  // ========================================

  /// ガチャ履歴を保存
  Future<void> saveGachaHistory({
    required String userId,
    required String gachaType,
    required int pullCount,
    required List<Map<String, dynamic>> results,
    required int gemsUsed,
    required int ticketsUsed,
  }) async {
    try {
      final historyData = {
        'userId': userId,
        'gachaType': gachaType,
        'pullCount': pullCount,
        'results': results
            .map((r) => {
                  'monsterId': r['id'] ?? 'temp_${_random.nextInt(10000)}',
                  'monsterName': r['name'] ?? '不明',
                  'rarity': r['rarity'] ?? 2,
                  'race': r['race'] ?? '不明',
                  'element': r['element'] ?? 'none',
                })
            .toList(),
        'gemsUsed': gemsUsed,
        'ticketsUsed': ticketsUsed,
        'pulledAt': FieldValue.serverTimestamp(), // ✅ 修正: createdAt → pulledAt
      };

      await _firestore.collection('gacha_history').add(historyData);
    } catch (e) {
      print('ガチャ履歴保存エラー: $e');
    }
  }

  /// ガチャ履歴を取得
  Future<List<Map<String, dynamic>>> getGachaHistory(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('gacha_history')
          .where('userId', isEqualTo: userId)
          .orderBy('pulledAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('ガチャ履歴取得エラー: $e');
      return [];
    }
  }
}