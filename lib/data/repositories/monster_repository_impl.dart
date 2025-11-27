import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/monster.dart';
import '../../domain/repositories/monster_repository.dart';
import '../../core/models/monster_model.dart';

class MonsterRepositoryImpl implements MonsterRepository {
  final FirebaseFirestore _firestore;
  static const String _collection = 'user_monsters';
  static const String _masterCollection = 'monster_masters';

  MonsterRepositoryImpl(this._firestore);

  @override
  Future<List<Monster>> getMonsters(String userId) async {
    try {
      final snapshot = await _firestore
        .collection(_collection)
        .where('user_id', isEqualTo: userId)
        .get();

      // モンスターIDを収集
      final monsterIds = snapshot.docs
          .map((doc) => doc.data()['monster_id'] as String?)
          .where((id) => id != null)
          .toSet()
          .toList();

      // マスターデータを一括取得
      final masterDataMap = await _getMonsterMasterData(monsterIds.cast<String>());

      // Monsterエンティティに変換
      return snapshot.docs.map((doc) {
        final monsterId = doc.data()['monster_id'] as String?;
        final masterData = masterDataMap[monsterId];
        return MonsterModel.fromFirestore(doc, masterData);
      }).toList();
    } catch (e) {
      print('Error getting monsters: $e');
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

      // マスターデータを取得
      final data = doc.data()!;
      final masterMonsterId = data['monster_id'] as String?;
      
      Map<String, dynamic>? masterData;
      if (masterMonsterId != null) {
        final masterDoc = await _firestore
            .collection(_masterCollection)
            .doc(masterMonsterId)
            .get();
        
        if (masterDoc.exists) {
          masterData = masterDoc.data();
        }
      }

      return MonsterModel.fromFirestore(doc, masterData);
    } catch (e) {
      print('Error getting monster: $e');
      throw Exception('Failed to get monster: $e');
    }
  }

  @override
  Future<void> createMonster(Monster monster) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(monster.id)
          .set(MonsterModel.toFirestore(monster));
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
          .update(MonsterModel.toFirestore(monster));
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
        .where('user_id', isEqualTo: userId)
        .orderBy('acquired_at', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      // モンスターIDを収集
      final monsterIds = snapshot.docs
          .map((doc) => doc.data()['monster_id'] as String?)
          .where((id) => id != null)
          .toSet()
          .toList();

      // マスターデータを一括取得
      final masterDataMap = await _getMonsterMasterData(monsterIds.cast<String>());

      // Monsterエンティティに変換
      return snapshot.docs.map((doc) {
        final monsterId = doc.data()['monster_id'] as String?;
        final masterData = masterDataMap[monsterId];
        return MonsterModel.fromFirestore(doc, masterData);
      }).toList();
    });
  }

  @override
  Future<List<Monster>> getPartyMonsters(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('user_id', isEqualTo: userId)
          .where('in_party', isEqualTo: true)
          .orderBy('party_slot')
          .limit(5)
          .get();

      // モンスターIDを収集
      final monsterIds = snapshot.docs
          .map((doc) => doc.data()['monster_id'] as String?)
          .where((id) => id != null)
          .toSet()
          .toList();

      // マスターデータを一括取得
      final masterDataMap = await _getMonsterMasterData(monsterIds.cast<String>());

      // Monsterエンティティに変換
      return snapshot.docs.map((doc) {
        final monsterId = doc.data()['monster_id'] as String?;
        final masterData = masterDataMap[monsterId];
        return MonsterModel.fromFirestore(doc, masterData);
      }).toList();
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
          .where('user_id', isEqualTo: userId)
          .get();

      for (var doc in allMonstersSnapshot.docs) {
        batch.update(doc.reference, {
          'in_party': false,
          'party_slot': null,
        });
      }

      // 指定されたモンスターをパーティに追加
      for (var i = 0; i < monsterIds.length; i++) {
        final monsterRef = _firestore
            .collection(_collection)
            .doc(monsterIds[i]);
        batch.update(monsterRef, {
          'in_party': true,
          'party_slot': i,
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

      final data = doc.data()!;
      final currentExp = data['exp'] as int? ?? 0;
      final newExp = currentExp + exp;

      await _firestore
          .collection(_collection)
          .doc(monsterId)
          .update({'exp': newExp});
    } catch (e) {
      throw Exception('Failed to add exp: $e');
    }
  }

  /// モンスターマスタデータを取得
  Future<Map<String, Map<String, dynamic>>> _getMonsterMasterData(
    List<String> monsterIds,
  ) async {
    if (monsterIds.isEmpty) return {};

    try {
      final Map<String, Map<String, dynamic>> masterDataMap = {};

      // 一括取得（Firestoreの制限により10件ずつ）
      for (int i = 0; i < monsterIds.length; i += 10) {
        final batch = monsterIds.skip(i).take(10).toList();
        final snapshot = await _firestore
            .collection(_masterCollection)
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (var doc in snapshot.docs) {
          masterDataMap[doc.id] = doc.data();
        }
      }

      return masterDataMap;
    } catch (e) {
      print('Error getting monster master data: $e');
      return {};
    }
  }

  /// 技装備を更新
  @override
  Future<void> updateEquippedSkills(
    String monsterId,
    List<String> skillIds,
  ) async {
    try {
      // バリデーション：4つまで
      if (skillIds.length > 4) {
        throw Exception('Cannot equip more than 4 skills');
      }

      await _firestore
          .collection(_collection)
          .doc(monsterId)
          .update({
        'equipped_skills': skillIds,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update equipped skills: $e');
    }
  }

  /// 装備を更新
  @override
  Future<void> updateEquippedEquipment(
    String monsterId,
    List<String> equipmentIds,
  ) async {
    try {
      // バリデーション：基本1つ、ヒューマンは2つ
      if (equipmentIds.length > 2) {
        throw Exception('Cannot equip more than 2 equipment');
      }

      await _firestore
          .collection(_collection)
          .doc(monsterId)
          .update({
        'equipped_equipment': equipmentIds,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update equipped equipment: $e');
    }
  }

  /// 複数のモンスターをIDで取得（MonsterModel.fromFirestoreを使用）
    Future<List<Monster>> getMonstersByIds(List<String> monsterIds) async {
      if (monsterIds.isEmpty) return [];
      
      try {
        final List<Monster> monsters = [];
        final Map<String, Map<String, dynamic>> masterDataMap = {};
        
        // ユーザーモンスターのドキュメントを取得
        final List<DocumentSnapshot<Map<String, dynamic>>> userMonsterDocs = [];
        final Set<String> masterMonsterIds = {};
        
        for (final monsterId in monsterIds) {
          final doc = await _firestore.collection(_collection).doc(monsterId).get();
          if (doc.exists && doc.data() != null) {
            userMonsterDocs.add(doc);
            final masterMonsterId = doc.data()!['monster_id'] as String?;
            if (masterMonsterId != null) {
              masterMonsterIds.add(masterMonsterId);
            }
          }
        }
        
        // マスターデータを一括取得
        if (masterMonsterIds.isNotEmpty) {
          final masterMap = await _getMonsterMasterData(masterMonsterIds.toList());
          masterDataMap.addAll(masterMap);
        }
        
        // MonsterModel.fromFirestoreを使用して変換（時間ベース回復が適用される）
        for (final doc in userMonsterDocs) {
          final masterMonsterId = doc.data()!['monster_id'] as String?;
          final masterData = masterDataMap[masterMonsterId];
          monsters.add(MonsterModel.fromFirestore(doc, masterData));
        }
        
        return monsters;
      } catch (e) {
        print('Error getting monsters by ids: $e');
        throw Exception('Failed to get monsters by ids: $e');
      }
    }

  /// モンスターのHPを更新
  @override
  Future<void> updateMonsterHp(String monsterId, int currentHp) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(monsterId)
          .update({
        'current_hp': currentHp,
        'last_hp_update': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update monster HP: $e');
    }
  }

  /// 複数モンスターのHPを一括更新
  @override
  Future<void> updateMonstersHp(Map<String, int> monsterHpMap) async {
    if (monsterHpMap.isEmpty) return;
    
    try {
      final batch = _firestore.batch();
      
      for (final entry in monsterHpMap.entries) {
        final docRef = _firestore.collection(_collection).doc(entry.key);
        batch.update(docRef, {
          'current_hp': entry.value,
          'last_hp_update': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      print('✅ ${monsterHpMap.length}体のモンスターHP更新完了');
    } catch (e) {
      print('❌ HP一括更新エラー: $e');
      throw Exception('Failed to update monsters HP: $e');
    }
  }
}