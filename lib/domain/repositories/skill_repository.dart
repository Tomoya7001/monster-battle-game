import '../entities/skill.dart';
import '../entities/skill_master.dart';

abstract class SkillRepository {
  // スキルマスター取得
  Future<List<SkillMaster>> getSkillMasters();
  Future<SkillMaster?> getSkillMaster(String skillId);
  
  // モンスターのスキル取得・設定
  Future<List<Skill>> getMonsterSkills(String monsterId);
  Future<void> setMonsterSkills(String monsterId, List<String> skillIds);
  
  // 習得可能スキル取得
  Future<List<SkillMaster>> getLearnableSkills(
    String monsterMasterId,
    int level,
  );
  
  // リアルタイム監視
  Stream<List<Skill>> watchMonsterSkills(String monsterId);
}