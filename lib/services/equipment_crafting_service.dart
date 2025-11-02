// lib/services/equipment_crafting_service.dart

import '../models/equipment.dart';
import '../repositories/equipment_repository.dart';

class EquipmentCraftingService {
  final EquipmentRepository _repository = EquipmentRepository();
  
  /// 装備を錬成
  Future<Equipment> craftEquipment({
    required String userId,
    required int equipmentMasterId,
    required Map<String, int> materials, // material_id -> quantity
    required int gold,
  }) async {
    // 1. 装備マスターデータ取得
    final master = await _getEquipmentMaster(equipmentMasterId);
    
    // 2. 素材・ゴールドチェック（省略）
    
    // 3. 装備作成
    final equipment = Equipment(
      id: '', // Firestore自動生成
      userId: userId,
      equipmentMasterId: equipmentMasterId,
      obtainedAt: DateTime.now(),
    );
    
    // 4. Firestoreに保存
    final docRef = await _firestore
        .collection('user_equipment')
        .add(equipment.toJson());
    
    // 5. 素材・ゴールド消費（省略）
    
    return equipment.copyWith(id: docRef.id);
  }
  
  Future<Map<String, dynamic>> _getEquipmentMaster(int id) async {
    final doc = await FirebaseFirestore.instance
        .collection('equipment_masters')
        .doc(id.toString())
        .get();
    return doc.data()!;
  }
}