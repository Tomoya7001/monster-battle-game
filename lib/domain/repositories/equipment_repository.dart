import '../entities/equipment.dart';
import '../entities/equipment_master.dart';

abstract class EquipmentRepository {
  // 装備マスター取得
  Future<List<EquipmentMaster>> getEquipmentMasters();
  Future<EquipmentMaster?> getEquipmentMaster(String equipmentId);
  
  // ユーザー装備取得
  Future<List<Equipment>> getUserEquipment(String userId);
  Future<Equipment?> getEquipment(String equipmentId);
  
  // 装備作成・削除
  Future<void> createEquipment(Equipment equipment);
  Future<void> deleteEquipment(String equipmentId);
  
  // モンスター装備管理
  Future<List<Equipment>> getMonsterEquipment(String monsterId);
  Future<void> equipToMonster(String monsterId, String equipmentId, int slot);
  Future<void> unequipFromMonster(String monsterId, int slot);
  
  // リアルタイム監視
  Stream<List<Equipment>> watchUserEquipment(String userId);
}