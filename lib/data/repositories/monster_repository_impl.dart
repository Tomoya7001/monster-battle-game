import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/monster.dart';
import '../../domain/repositories/monster_repository.dart';

class MonsterRepositoryImpl implements MonsterRepository {
  final FirebaseFirestore _firestore;
  static const String _collection = 'monsters';

  MonsterRepositoryImpl(this._firestore);

  @override
  Future<List<Monster>> getMonsters(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('acquiredAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Monster.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get monsters: $e');
    }
  }

  @override
  Future<Monster?> getMonster(String monsterId) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(monsterId)
          .get();

      if (!doc.exists) return null;

      return Monster.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get monster: $e');
    }
  }

  @override
  Future<void> createMonster(Monster monster) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(monster.id)
          .set(monster.toJson());
    } catch (e) {
      throw Exception('Failed to create monster: $e');
    }
  }

  @override
  Future<void> updateMonster(Monster monster) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(monster.id)
          .update(monster.toJson());
    } catch (e) {
      throw Exception('Failed to update monster: $e');
    }
  }

  @override
  Future<void> deleteMonster(String monsterId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(monsterId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete monster: $e');
    }
  }

  @override
  Stream<List<Monster>> watchMonsters(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('acquiredAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Monster.fromJson(doc.data()))
            .toList());
  }

  @override
  Future<List<Monster>> getPartyMonsters(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('inParty', isEqualTo: true)
          .orderBy('partySlot')
          .limit(5)
          .get();

      return snapshot.docs
          .map((doc) => Monster.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get party monsters: $e');
    }
  }

  @override
  Future<void> updateParty(String userId, List<String> monsterIds) async {
    try {
      final batch = _firestore.batch();

      // すべてのモンスターをパーティから外す
      final allMonstersSnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in allMonstersSnapshot.docs) {
        batch.update(doc.reference, {
          'inParty': false,
          'partySlot': null,
        });
      }

      // 指定されたモンスターをパーティに追加
      for (var i = 0; i < monsterIds.length; i++) {
        final monsterRef = _firestore
            .collection(_collection)
            .doc(monsterIds[i]);
        batch.update(monsterRef, {
          'inParty': true,
          'partySlot': i,
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to update party: $e');
    }
  }

  @override
  Future<void> addExp(String monsterId, int exp) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(monsterId)
          .get();

      if (!doc.exists) {
        throw Exception('Monster not found');
      }

      final monster = Monster.fromJson(doc.data()!);
      var currentExp = monster.exp + exp;
      var currentLevel = monster.level;

      // レベルアップ処理（簡易版）
      while (currentExp >= _getExpForNextLevel(currentLevel)) {
        currentExp -= _getExpForNextLevel(currentLevel);
        currentLevel++;
        if (currentLevel >= 100) {
          currentLevel = 100;
          currentExp = 0;
          break;
        }
      }

      await _firestore
          .collection(_collection)
          .doc(monsterId)
          .update({
        'exp': currentExp,
        'level': currentLevel,
      });
    } catch (e) {
      throw Exception('Failed to add exp: $e');
    }
  }

  // レベルアップに必要な経験値を計算
  int _getExpForNextLevel(int level) {
    return (level * level * 10).toInt();
  }
}