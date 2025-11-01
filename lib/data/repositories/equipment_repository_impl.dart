import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/equipment.dart';
import '../../domain/entities/equipment_master.dart';
import '../../domain/repositories/equipment_repository.dart';

class EquipmentRepositoryImpl implements EquipmentRepository {
  final FirebaseFirestore _firestore;
  static const String _masterCollection = 'equipment_masters';
  static const String _userEquipmentCollection = 'user_equipment';
  static const String _monsterEquipmentCollection = 'monster_equipment';

  EquipmentRepositoryImpl(this._firestore);

  @override
  Future<List<EquipmentMaster>> getEquipmentMasters() async {
    try {
      final snapshot = await _firestore
          .collection(_masterCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('displayOrder')
          .get();

      return snapshot.docs
          .map((doc) => EquipmentMaster.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get equipment masters: $e');
    }
  }

  @override
  Future<EquipmentMaster?> getEquipmentMaster(String equipmentId) async {
    try {
      final doc = await _firestore
          .collection(_masterCollection)
          .doc(equipmentId)
          .get();

      if (!doc.exists) return null;

      return EquipmentMaster.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get equipment master: $e');
    }
  }

  @override
  Future<List<Equipment>> getUserEquipment(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_userEquipmentCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('acquiredAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Equipment.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user equipment: $e');
    }
  }

  @override
  Future<Equipment?> getEquipment(String equipmentId) async {
    try {
      final doc = await _firestore
          .collection(_userEquipmentCollection)
          .doc(equipmentId)
          .get();

      if (!doc.exists) return null;

      return Equipment.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get equipment: $e');
    }
  }

  @override
  Future<void> createEquipment(Equipment equipment) async {
    try {
      await _firestore
          .collection(_userEquipmentCollection)
          .doc(equipment.id)
          .set(equipment.toJson());
    } catch (e) {
      throw Exception('Failed to create equipment: $e');
    }
  }

  @override
  Future<void> deleteEquipment(String equipmentId) async {
    try {
      await _firestore
          .collection(_userEquipmentCollection)
          .doc(equipmentId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete equipment: $e');
    }
  }

  @override
  Future<List<Equipment>> getMonsterEquipment(String monsterId) async {
    try {
      final snapshot = await _firestore
          .collection(_monsterEquipmentCollection)
          .where('monsterId', isEqualTo: monsterId)
          .orderBy('slot')
          .get();

      final equipmentIds = snapshot.docs
          .map((doc) => doc.data()['equipmentId'] as String)
          .toList();

      if (equipmentIds.isEmpty) return [];

      final equipmentList = <Equipment>[];
      for (var id in equipmentIds) {
        final equipment = await getEquipment(id);
        if (equipment != null) {
          equipmentList.add(equipment);
        }
      }

      return equipmentList;
    } catch (e) {
      throw Exception('Failed to get monster equipment: $e');
    }
  }

  @override
  Future<void> equipToMonster(
    String monsterId,
    String equipmentId,
    int slot,
  ) async {
    try {
      // 既存の装備を確認
      final existingQuery = await _firestore
          .collection(_monsterEquipmentCollection)
          .where('equipmentId', isEqualTo: equipmentId)
          .get();

      // 他のモンスターに装備されている場合は削除
      for (var doc in existingQuery.docs) {
        await doc.reference.delete();
      }

      // 同じスロットの装備を削除
      final slotQuery = await _firestore
          .collection(_monsterEquipmentCollection)
          .where('monsterId', isEqualTo: monsterId)
          .where('slot', isEqualTo: slot)
          .get();

      for (var doc in slotQuery.docs) {
        await doc.reference.delete();
      }

      // 新しい装備を設定
      await _firestore
          .collection(_monsterEquipmentCollection)
          .add({
        'monsterId': monsterId,
        'equipmentId': equipmentId,
        'slot': slot,
        'equippedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to equip to monster: $e');
    }
  }

  @override
  Future<void> unequipFromMonster(
    String monsterId,
    int slot,
  ) async {
    try {
      final query = await _firestore
          .collection(_monsterEquipmentCollection)
          .where('monsterId', isEqualTo: monsterId)
          .where('slot', isEqualTo: slot)
          .get();

      for (var doc in query.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to unequip from monster: $e');
    }
  }

  @override
  Stream<List<Equipment>> watchUserEquipment(String userId) {
    return _firestore
        .collection(_userEquipmentCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('acquiredAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Equipment.fromJson(doc.data()))
            .toList());
  }
}