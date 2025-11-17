import '../../../domain/entities/monster.dart';
import 'battle_skill.dart';

/// バトル中のモンスター状態
class BattleMonster {
  final Monster baseMonster;
  final List<BattleSkill> skills;
  
  int currentHp;
  int currentCost;
  int maxCost;
  
  // バフ・デバフ段階（-3 ~ +3）
  int attackStage;
  int defenseStage;
  int magicStage;
  int speedStage;
  int accuracyStage;
  int evasionStage;
  
  // 状態異常
  String? statusAilment; // burn, poison, paralysis, sleep, freeze, confusion
  int statusTurns;
  
  // バトル参加フラグ
  bool hasParticipated;
  
  BattleMonster({
    required this.baseMonster,
    required this.skills,
    int? initialHp,
  })  : currentHp = initialHp ?? baseMonster.lv50MaxHp,
        currentCost = 3, // 初期コスト
        maxCost = 6,
        attackStage = 0,
        defenseStage = 0,
        magicStage = 0,
        speedStage = 0,
        accuracyStage = 0,
        evasionStage = 0,
        statusAilment = null,
        statusTurns = 0,
        hasParticipated = false;

  /// PvP用：Lv50ステータス
  int get attack => _applyStageMultiplier(baseMonster.lv50Attack, attackStage);
  int get defense => _applyStageMultiplier(baseMonster.lv50Defense, defenseStage);
  int get magic => _applyStageMultiplier(baseMonster.lv50Magic, magicStage);
  int get speed => _applyStageMultiplier(baseMonster.lv50Speed, speedStage);
  int get maxHp => baseMonster.lv50MaxHp;

  /// 段階倍率適用
  int _applyStageMultiplier(int baseStat, int stage) {
    final multipliers = {
      -3: 0.56,
      -2: 0.67,
      -1: 0.83,
      0: 1.0,
      1: 1.2,
      2: 1.5,
      3: 1.8,
    };
    return (baseStat * (multipliers[stage] ?? 1.0)).round();
  }

  /// HP割合
  double get hpPercentage => currentHp / maxHp;

  /// 瀕死かどうか
  bool get isFainted => currentHp <= 0;

  /// 行動可能かどうか
  bool get canAct {
    if (isFainted) return false;
    if (statusAilment == 'sleep' || statusAilment == 'freeze') return false;
    return true;
  }

  /// コスト回復（毎ターン+2）
  void recoverCost() {
    currentCost = (currentCost + 2).clamp(0, maxCost);
  }

  /// コストリセット（交代時）
  void resetCost() {
    currentCost = 3;
  }

  /// ダメージを受ける
  void takeDamage(int damage) {
    currentHp = (currentHp - damage).clamp(0, maxHp);
  }

  /// 回復する
  void heal(int amount) {
    currentHp = (currentHp + amount).clamp(0, maxHp);
  }

  /// 技が使用可能かどうか
  bool canUseSkill(BattleSkill skill) {
    return currentCost >= skill.cost;
  }

  /// 技を使用（コスト消費）
  void useSkill(BattleSkill skill) {
    currentCost -= skill.cost;
  }

  /// 状態をリセット（交代時にバフ・デバフをリセット）
  void resetStages() {
    attackStage = 0;
    defenseStage = 0;
    magicStage = 0;
    speedStage = 0;
    accuracyStage = 0;
    evasionStage = 0;
  }
}