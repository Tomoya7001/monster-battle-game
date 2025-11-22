import '../entities/monster.dart';

abstract class MonsterRepository {
  // モンスター取得
  Future<List<Monster>> getMonsters(String userId);
  Future<Monster?> getMonster(String monsterId);
  
  // モンスター作成・更新・削除
  Future<void> createMonster(Monster monster);
  Future<void> updateMonster(Monster monster);
  Future<void> deleteMonster(String monsterId);
  
  // リアルタイム監視
  Stream<List<Monster>> watchMonsters(String userId);
  
  // パーティー管理
  Future<List<Monster>> getPartyMonsters(String userId);
  Future<void> updateParty(String userId, List<String> monsterIds);
  
  // 経験値追加
  Future<void> addExp(String monsterId, int exp);
  
  // ★ 追加：技装備更新
  Future<void> updateEquippedSkills(String monsterId, List<String> skillIds);
  
  // ★ 追加：装備更新
  Future<void> updateEquippedEquipment(String monsterId, List<String> equipmentIds);
}