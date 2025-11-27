// lib/data/repositories/equipment_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/equipment_master.dart';

class EquipmentRepository {
  final FirebaseFirestore _firestore;
  Map<String, EquipmentMaster>? _masterCache;

  EquipmentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 装備マスター全取得
  Future<Map<String, EquipmentMaster>> getEquipmentMasters() async {
    if (_masterCache != null) return _masterCache!;

    final snapshot = await _firestore.collection('equipment_masters').get();
    
    _masterCache = {};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      data['equipment_id'] = doc.id;
      _masterCache![doc.id] = EquipmentMaster.fromJson(data);
    }
    
    return _masterCache!;
  }

  /// 装備マスター単体取得
  Future<EquipmentMaster?> getEquipmentMaster(String equipmentId) async {
    final masters = await getEquipmentMasters();
    return masters[equipmentId];
  }

  /// カテゴリ別装備取得
  Future<List<EquipmentMaster>> getEquipmentsByCategory(String category) async {
    final masters = await getEquipmentMasters();
    return masters.values
        .where((e) => e.category == category)
        .toList()
      ..sort((a, b) => a.rarity.compareTo(b.rarity));
  }

  /// ユーザー所持装備取得
  Future<Map<String, int>> getUserEquipments(String userId) async {
    final snapshot = await _firestore
        .collection('user_equipment')
        .where('user_id', isEqualTo: userId)
        .get();

    final equipments = <String, int>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final equipmentId = data['equipment_id'] as String?;
      final quantity = data['quantity'] as int? ?? 0;
      if (equipmentId != null && quantity > 0) {
        equipments[equipmentId] = quantity;
      }
    }
    return equipments;
  }

  /// 装備をモンスターに装着
  Future<bool> equipToMonster({
    required String monsterId,
    required String equipmentId,
    required int slot,
  }) async {
    try {
      final monsterDoc = await _firestore
          .collection('user_monsters')
          .doc(monsterId)
          .get();
      
      if (!monsterDoc.exists) return false;
      
      final data = monsterDoc.data()!;
      final currentEquipment = List<String>.from(data['equipped_equipment'] ?? []);
      final species = data['species'] as String? ?? '';
      final maxSlots = species.toLowerCase() == 'human' ? 2 : 1;
      
      if (slot >= maxSlots) return false;
      
      while (currentEquipment.length <= slot) {
        currentEquipment.add('');
      }
      currentEquipment[slot] = equipmentId;
      
      final cleanedEquipment = currentEquipment.where((e) => e.isNotEmpty).toList();
      
      await _firestore
          .collection('user_monsters')
          .doc(monsterId)
          .update({
        'equipped_equipment': cleanedEquipment,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      print('❌ 装備エラー: $e');
      return false;
    }
  }

  /// 装備を外す
  Future<bool> unequipFromMonster({
    required String monsterId,
    required String equipmentId,
  }) async {
    try {
      final monsterDoc = await _firestore
          .collection('user_monsters')
          .doc(monsterId)
          .get();
      
      if (!monsterDoc.exists) return false;
      
      final data = monsterDoc.data()!;
      final currentEquipment = List<String>.from(data['equipped_equipment'] ?? []);
      
      currentEquipment.remove(equipmentId);
      
      await _firestore
          .collection('user_monsters')
          .doc(monsterId)
          .update({
        'equipped_equipment': currentEquipment,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      print('❌ 装備解除エラー: $e');
      return false;
    }
  }

  void clearCache() {
    _masterCache = null;
  }
}