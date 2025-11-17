import 'dart:math';
import '../../../domain/models/battle/battle_monster.dart';
import '../../../domain/models/battle/battle_skill.dart';
import 'type_effectiveness_service.dart';

/// バトル計算サービス
class BattleCalculationService {
  static final _random = Random();

  /// ダメージ計算
  /// 
  /// 計算式:
  /// 基本ダメージ = (攻撃力 or 魔力) × 威力倍率
  /// 属性補正 = 基本ダメージ × 属性相性倍率
  /// 防御補正 = 属性補正 × (1 - 防御力 / (防御力 + 100))
  /// 乱数補正 = 防御補正 × (0.85 ~ 1.0)
  /// クリティカル = 乱数補正 × 1.5（6%の確率）
  static BattleCalculationResult calculateDamage({
    required BattleMonster attacker,
    required BattleMonster defender,
    required BattleSkill skill,
  }) {
    // 攻撃技でない場合はダメージ0
    if (!skill.isAttack) {
      return BattleCalculationResult(
        damage: 0,
        isCritical: false,
        effectivenessMultiplier: 1.0,
        effectivenessText: '',
      );
    }

    // 1. 基本ダメージ（物理技は攻撃力、魔法技は魔力）
    final attackStat = skill.type == 'physical' ? attacker.attack : attacker.magic;
    double baseDamage = attackStat * skill.powerMultiplier;

    // 2. 属性相性補正
    final defenderElements = [defender.baseMonster.element];
    final typeMultiplier = TypeEffectivenessService.calculateMultiplier(
      skill.element,
      defenderElements,
    );
    double damage = baseDamage * typeMultiplier;

    // 3. 防御補正（防御力による軽減）
    final defenseStat = defender.defense;
    final defenseReduction = 1 - (defenseStat / (defenseStat + 100));
    damage *= defenseReduction;

    // 4. 乱数補正（85% ~ 100%）
    final randomMultiplier = 0.85 + _random.nextDouble() * 0.15;
    damage *= randomMultiplier;

    // 5. クリティカル判定（6%）
    bool isCritical = _random.nextDouble() < 0.06;
    if (isCritical) {
      damage *= 1.5;
    }

    // 6. 最終ダメージ（最低1）
    final finalDamage = damage.round().clamp(1, 9999);

    return BattleCalculationResult(
      damage: finalDamage,
      isCritical: isCritical,
      effectivenessMultiplier: typeMultiplier,
      effectivenessText: TypeEffectivenessService.getEffectivenessText(typeMultiplier),
    );
  }

  /// 命中判定
  static bool checkHit(BattleSkill skill, BattleMonster attacker, BattleMonster defender) {
    // 基本命中率
    int hitChance = skill.accuracy;

    // 命中率ステージ補正
    hitChance = (hitChance * _getAccuracyMultiplier(attacker.accuracyStage)).round();

    // 回避率ステージ補正
    hitChance = (hitChance / _getEvasionMultiplier(defender.evasionStage)).round();

    // 最終判定
    return _random.nextInt(100) < hitChance.clamp(1, 100);
  }

  static double _getAccuracyMultiplier(int stage) {
    final multipliers = {
      -3: 0.56,
      -2: 0.67,
      -1: 0.83,
      0: 1.0,
      1: 1.2,
      2: 1.5,
      3: 1.8,
    };
    return multipliers[stage] ?? 1.0;
  }

  static double _getEvasionMultiplier(int stage) {
    return _getAccuracyMultiplier(stage);
  }

  /// すばやさ判定（先制決定）
  static bool isPlayerFirst(BattleMonster player, BattleMonster enemy) {
    if (player.speed > enemy.speed) {
      return true;
    } else if (player.speed < enemy.speed) {
      return false;
    } else {
      // 同速はランダム
      return _random.nextBool();
    }
  }
}

/// ダメージ計算結果
class BattleCalculationResult {
  final int damage;
  final bool isCritical;
  final double effectivenessMultiplier;
  final String effectivenessText;

  const BattleCalculationResult({
    required this.damage,
    required this.isCritical,
    required this.effectivenessMultiplier,
    required this.effectivenessText,
  });
}