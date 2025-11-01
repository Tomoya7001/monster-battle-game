import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/skill.dart';
import '../../domain/entities/skill_master.dart';
import '../../domain/repositories/skill_repository.dart';

class SkillRepositoryImpl implements SkillRepository {
  final FirebaseFirestore _firestore;
  static const String _masterCollection = 'skill_masters';
  static const String _userSkillsCollection = 'user_skills';

  SkillRepositoryImpl(this._firestore);

  @override
  Future<List<SkillMaster>> getSkillMasters() async {
    try {
      final snapshot = await _firestore
          .collection(_masterCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('displayOrder')
          .get();

      return snapshot.docs
          .map((doc) => SkillMaster.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get skill masters: $e');
    }
  }

  @override
  Future<SkillMaster?> getSkillMaster(String skillId) async {
    try {
      final doc = await _firestore
          .collection(_masterCollection)
          .doc(skillId)
          .get();

      if (!doc.exists) return null;

      return SkillMaster.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get skill master: $e');
    }
  }

  @override
  Future<List<Skill>> getMonsterSkills(String monsterId) async {
    try {
      final snapshot = await _firestore
          .collection(_userSkillsCollection)
          .where('monsterId', isEqualTo: monsterId)
          .orderBy('slot')
          .get();

      return snapshot.docs
          .map((doc) => Skill.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get monster skills: $e');
    }
  }

  @override
  Future<void> setMonsterSkills(
    String monsterId,
    List<String> skillIds,
  ) async {
    try {
      final batch = _firestore.batch();

      // 既存のスキルをすべて削除
      final existingSkills = await _firestore
          .collection(_userSkillsCollection)
          .where('monsterId', isEqualTo: monsterId)
          .get();

      for (var doc in existingSkills.docs) {
        batch.delete(doc.reference);
      }

      // 新しいスキルを設定
      for (var i = 0; i < skillIds.length; i++) {
        final skillMaster = await getSkillMaster(skillIds[i]);
        if (skillMaster == null) continue;

        final docRef = _firestore
            .collection(_userSkillsCollection)
            .doc();

        final skill = Skill(
          id: docRef.id,
          masterId: skillMaster.id,
          monsterId: monsterId,
          name: skillMaster.name,
          description: skillMaster.description,
          type: skillMaster.type,
          element: skillMaster.element,
          cost: skillMaster.cost,
          power: skillMaster.power,
          accuracy: skillMaster.accuracy,
          target: skillMaster.target,
          effects: skillMaster.effects,
          slot: i,
        );

        batch.set(docRef, skill.toJson());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to set monster skills: $e');
    }
  }

  @override
  Future<List<SkillMaster>> getLearnableSkills(
    String monsterMasterId,
    int level,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_masterCollection)
          .where('learnableBy', arrayContains: monsterMasterId)
          .where('requiredLevel', isLessThanOrEqualTo: level)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => SkillMaster.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get learnable skills: $e');
    }
  }

  @override
  Stream<List<Skill>> watchMonsterSkills(String monsterId) {
    return _firestore
        .collection(_userSkillsCollection)
        .where('monsterId', isEqualTo: monsterId)
        .orderBy('slot')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Skill.fromJson(doc.data()))
            .toList());
  }
}