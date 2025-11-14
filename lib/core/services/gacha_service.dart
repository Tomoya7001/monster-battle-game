import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gacha_ticket.dart';
import '../models/gacha_history.dart';

class GachaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  // ========================================
  // チケット関連
  // ========================================

  // チケット残高取得
  Future<GachaTicket> getTicketBalance(String userId) async {
    try {
      final doc = await _firestore
          .collection('user_gacha_tickets')
          .doc(userId)
          .get();

      if (!doc.exists) {
        return GachaTicket(userId: userId);
      }

      final data = doc.data()!;
      return GachaTicket(
        userId: userId,
        ticketCount: data['ticketCount'] as int? ?? 0,
        totalPulls: data['totalPulls'] as int? ?? 0,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      );
    } catch (e) {
      throw Exception('チケット残高の取得に失敗しました: $e');
    }
  }

  // ガチャ実行時にチケット追加
  Future<void> addTickets(String userId, int count) async {
    try {
      final docRef = _firestore.collection('user_gacha_tickets').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        if (!doc.exists) {
          transaction.set(docRef, {
            'userId': userId,
            'ticketCount': count,
            'totalPulls': count,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          final currentCount = doc.data()!['ticketCount'] as int;
          final totalPulls = doc.data()!['totalPulls'] as int;

          transaction.update(docRef, {
            'ticketCount': currentCount + count,
            'totalPulls': totalPulls + count,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      throw Exception('チケットの追加に失敗しました: $e');
    }
  }

  // チケット交換オプション取得
  Future<List<TicketExchangeOption>> getExchangeOptions() async {
    try {
      final snapshot = await _firestore
          .collection('gacha_ticket_exchange')
          .orderBy('requiredTickets')
          .get();

      return snapshot.docs
          .map((doc) => TicketExchangeOption.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      throw Exception('交換オプションの取得に失敗しました: $e');
    }
  }

  // チケット交換実行
  Future<Map<String, dynamic>> exchangeTickets({
    required String userId,
    required String optionId,
  }) async {
    try {
      // 交換オプション取得
      final optionDoc = await _firestore
          .collection('gacha_ticket_exchange')
          .doc(optionId)
          .get();

      if (!optionDoc.exists) {
        throw Exception('無効な交換オプションです');
      }

      final option = TicketExchangeOption.fromJson({
        'id': optionDoc.id,
        ...optionDoc.data()!,
      });

      // ユーザーのチケット残高確認
      final ticketData = await getTicketBalance(userId);

      if (ticketData.ticketCount < option.requiredTickets) {
        throw Exception(
            'チケットが不足しています。必要: ${option.requiredTickets}, 所持: ${ticketData.ticketCount}');
      }

      // ガチャ実行（報酬決定）
      final reward = await _executeGachaWithOption(option);

      // チケット消費
      await _consumeTickets(userId, option.requiredTickets);

      // ユーザーにモンスター付与
      await _grantMonster(userId, reward['monsterId'] as String);

      // 履歴記録
      await _recordExchange(userId, option, reward);

      return reward;
    } catch (e) {
      throw Exception('チケット交換に失敗しました: $e');
    }
  }

  // ガチャ実行（交換オプションに基づく）
  Future<Map<String, dynamic>> _executeGachaWithOption(
      TicketExchangeOption option) async {
    final random = _random.nextInt(100);

    String monsterId;
    int rarity;

    if (option.specificMonsterId != null) {
      monsterId = option.specificMonsterId!;
      rarity = 5;
    } else if (option.rewardType == 'star5') {
      if (random < option.guaranteeRate) {
        monsterId = await _getRandomMonster(5);
        rarity = 5;
      } else {
        monsterId = await _getRandomMonster(4);
        rarity = 4;
      }
    } else if (option.rewardType == 'star4') {
      if (random < option.guaranteeRate) {
        monsterId = await _getRandomMonster(4);
        rarity = 4;
      } else {
        monsterId = await _getRandomMonster(5);
        rarity = 5;
      }
    } else {
      throw Exception('不明な報酬タイプ');
    }

    return {
      'monsterId': monsterId,
      'rarity': rarity,
    };
  }

  // ランダムモンスター取得
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

  // チケット消費
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

  // モンスター付与
  Future<void> _grantMonster(String userId, String monsterId) async {
    final monsterDoc =
        await _firestore.collection('monster_masters').doc(monsterId).get();

    if (!monsterDoc.exists) {
      throw Exception('モンスターが見つかりません');
    }

    await _firestore.collection('user_monsters').add({
      'userId': userId,
      'monsterId': monsterId,
      'level': 1,
      'exp': 0,
      'intimacyLevel': 1,
      'intimacyExp': 0,
      'ivHp': _generateIV(),
      'ivAttack': _generateIV(),
      'ivDefense': _generateIV(),
      'ivMagic': _generateIV(),
      'ivSpeed': _generateIV(),
      'pointHp': 0,
      'pointAttack': 0,
      'pointDefense': 0,
      'pointMagic': 0,
      'pointSpeed': 0,
      'remainingPoints': 0,
      'skinId': 1,
      'isFavorite': false,
      'isLocked': false,
      'acquiredAt': FieldValue.serverTimestamp(),
    });
  }

  // 個体値生成（±0〜10）
  int _generateIV() {
    return _random.nextInt(21) - 10;
  }

  // 交換履歴記録
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
        'results': results.map((r) => {
          'monsterId': r['id'] ?? 'temp_${_random.nextInt(10000)}',
          'monsterName': r['name'] ?? '不明',
          'rarity': r['rarity'] ?? 2,
          'race': r['race'] ?? '不明',
          'element': r['element'] ?? '不明',
        }).toList(),
        'gemsUsed': gemsUsed,
        'ticketsUsed': ticketsUsed,
        'pulledAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('gacha_histories').add(historyData);
    } catch (e) {
      throw Exception('ガチャ履歴の保存に失敗しました: $e');
    }
  }

  /// ガチャ履歴を取得（最新100件）
  Future<List<GachaHistory>> getGachaHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('gacha_histories')
          .where('userId', isEqualTo: userId)
          .orderBy('pulledAt', descending: true)
          .limit(100)
          .get();

      return snapshot.docs
          .map((doc) => GachaHistory.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('ガチャ履歴の取得に失敗しました: $e');
    }
  }
}