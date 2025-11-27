import '../../../domain/entities/monster.dart';
import '../../../domain/entities/equipment_master.dart';
import 'battle_skill.dart';

/// バトル中のモンスター状態
class BattleMonster {
  final Monster baseMonster;
  final List<BattleSkill> skills;
  final List<EquipmentMaster> equipments; // ★追加: 装備リスト
  
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
  
  // バフ・デバフの持続ターン数（0 = 無制限）
  int attackStageTurns;
  int defenseStageTurns;
  int magicStageTurns;
  int speedStageTurns;
  int accuracyStageTurns;
  int evasionStageTurns;
  
  // 状態異常
  String? statusAilment;
  int statusTurns;
  
  // バトル参加フラグ
  bool hasParticipated;

  // まもる状態フラグ
  bool isProtecting = false;

  // ★追加: 装備効果による消耗フラグ
  bool hasUsedEndure = false; // 「HP1で耐える」発動済み
  
  BattleMonster({
    required this.baseMonster,
    required this.skills,
    this.equipments = const [], // ★追加
    int? initialHp,
  })  : currentHp = initialHp ?? baseMonster.lv50MaxHp,
        currentCost = 3,
        maxCost = 6,
        attackStage = 0,
        defenseStage = 0,
        magicStage = 0,
        speedStage = 0,
        accuracyStage = 0,
        evasionStage = 0,
        attackStageTurns = 0,
        defenseStageTurns = 0,
        magicStageTurns = 0,
        speedStageTurns = 0,
        accuracyStageTurns = 0,
        evasionStageTurns = 0,
        statusAilment = null,
        statusTurns = 0,
        hasParticipated = false {
    // ★追加: 初期コストブースト（装備効果）
    final costBoost = _getEquipmentEffectValue('initial_cost_boost', 'amount');
    if (costBoost > 0) {
      currentCost = (currentCost + costBoost).clamp(0, maxCost);
    }
  }

  // ★追加: 装備効果からステータスブーストを計算
  double _getStatBoostFromEquipment(String statName) {
    double totalBoost = 0.0;
    for (final eq in equipments) {
      for (final effect in eq.effects) {
        if (effect['type'] == 'stat_boost' && effect['stat'] == statName) {
          totalBoost += (effect['boost_percentage'] as num?)?.toDouble() ?? 0.0;
        }
        if (effect['type'] == 'all_stats_boost') {
          totalBoost += (effect['boost_percentage'] as num?)?.toDouble() ?? 0.0;
        }
      }
    }
    return totalBoost;
  }

  // ★追加: 装備効果値を取得
  int _getEquipmentEffectValue(String effectType, String field) {
    for (final eq in equipments) {
      for (final effect in eq.effects) {
        if (effect['type'] == effectType) {
          return (effect[field] as num?)?.toInt() ?? 0;
        }
      }
    }
    return 0;
  }

  // ★追加: 装備効果を持っているか
  bool hasEquipmentEffect(String effectType) {
    for (final eq in equipments) {
      for (final effect in eq.effects) {
        if (effect['type'] == effectType) {
          return true;
        }
      }
    }
    return false;
  }

  // ★追加: クリティカル率ブースト
  double get criticalRateBoost {
    double boost = 0.0;
    for (final eq in equipments) {
      for (final effect in eq.effects) {
        if (effect['type'] == 'critical_rate_boost') {
          boost += (effect['boost'] as num?)?.toDouble() ?? 0.0;
        }
      }
    }
    return boost;
  }

  // ★追加: 命中率ブースト
  double get accuracyBoost {
    double boost = 0.0;
    for (final eq in equipments) {
      for (final effect in eq.effects) {
        if (effect['type'] == 'accuracy_boost') {
          boost += (effect['boost'] as num?)?.toDouble() ?? 0.0;
        }
      }
    }
    return boost;
  }

  // ★追加: 毎ターンHP回復量（最大HPの割合）
  double get turnHealPercentage {
    double total = 0.0;
    for (final eq in equipments) {
      for (final effect in eq.effects) {
        if (effect['type'] == 'turn_healing') {
          total += (effect['heal_percentage'] as num?)?.toDouble() ?? 0.0;
        }
      }
    }
    return total;
  }

  // ★追加: ダメージ反射率
  double get reflectDamagePercentage {
    double total = 0.0;
    for (final eq in equipments) {
      for (final effect in eq.effects) {
        if (effect['type'] == 'reflect_damage') {
          total += (effect['percentage'] as num?)?.toDouble() ?? 0.0;
        }
      }
    }
    return total;
  }

  // ★追加: 属性技威力ブースト
  double getAttributeBoost(String attribute) {
    double boost = 0.0;
    for (final eq in equipments) {
      for (final effect in eq.effects) {
        if (effect['type'] == 'attribute_boost' &&
            (effect['attribute'] as String?)?.toLowerCase() == attribute.toLowerCase()) {
          boost += (effect['boost_percentage'] as num?)?.toDouble() ?? 0.0;
        }
      }
    }
    return boost;
  }

  /// PvP用：Lv50ステータス（装備効果込み）
  int get attack {
    final base = _applyStageMultiplier(baseMonster.lv50Attack, attackStage);
    final boost = _getStatBoostFromEquipment('attack');
    return (base * (1.0 + boost)).round();
  }

  int get defense {
    final base = _applyStageMultiplier(baseMonster.lv50Defense, defenseStage);
    final boost = _getStatBoostFromEquipment('defense');
    return (base * (1.0 + boost)).round();
  }

  int get magic {
    final base = _applyStageMultiplier(baseMonster.lv50Magic, magicStage);
    final boost = _getStatBoostFromEquipment('magic');
    return (base * (1.0 + boost)).round();
  }

  int get speed {
    int base = _applyStageMultiplier(baseMonster.lv50Speed, speedStage);
    final boost = _getStatBoostFromEquipment('speed');
    base = (base * (1.0 + boost)).round();
    
    // 麻痺状態で素早さ×0.5
    if (statusAilment == 'paralysis') {
      base = (base * 0.5).round();
    }
    
    return base;
  }

  int get maxHp {
    final base = baseMonster.lv50MaxHp;
    final boost = _getStatBoostFromEquipment('hp');
    return (base * (1.0 + boost)).round();
  }

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
    // ★追加: 初期コストブースト（交代時も適用）
    final costBoost = _getEquipmentEffectValue('initial_cost_boost', 'amount');
    if (costBoost > 0) {
      currentCost = (currentCost + costBoost).clamp(0, maxCost);
    }
  }

  /// ダメージを受ける（装備効果「HP1で耐える」対応）
  void takeDamage(int damage) {
    final newHp = currentHp - damage;
    
    // ★追加: HP1で耐える（endure）効果
    if (newHp <= 0 && !hasUsedEndure && hasEquipmentEffect('endure')) {
      currentHp = 1;
      hasUsedEndure = true;
    } else {
      currentHp = newHp.clamp(0, maxHp);
    }
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

    attackStageTurns = 0;
    defenseStageTurns = 0;
    magicStageTurns = 0;
    speedStageTurns = 0;
    accuracyStageTurns = 0;
    evasionStageTurns = 0;
  }
  
  // バフ/デバフの持続ターン減算処理
  void decreaseStatStageTurns() {
    if (attackStageTurns > 0) attackStageTurns--;
    if (defenseStageTurns > 0) defenseStageTurns--;
    if (magicStageTurns > 0) magicStageTurns--;
    if (speedStageTurns > 0) speedStageTurns--;
    if (accuracyStageTurns > 0) accuracyStageTurns--;
    if (evasionStageTurns > 0) evasionStageTurns--;
    
    if (attackStageTurns == 0 && attackStage != 0) attackStage = 0;
    if (defenseStageTurns == 0 && defenseStage != 0) defenseStage = 0;
    if (magicStageTurns == 0 && magicStage != 0) magicStage = 0;
    if (speedStageTurns == 0 && speedStage != 0) speedStage = 0;
    if (accuracyStageTurns == 0 && accuracyStage != 0) accuracyStage = 0;
    if (evasionStageTurns == 0 && evasionStage != 0) evasionStage = 0;
  }

  /// ターン終了時の処理（まもる状態をリセット）
  void resetProtecting() {
    isProtecting = false;
  }

  /// ★追加: ターン終了時の装備効果処理（HP回復など）
  List<String> processEquipmentTurnEnd() {
    final messages = <String>[];
    
    // 毎ターンHP回復
    final healPercent = turnHealPercentage;
    if (healPercent > 0 && currentHp > 0 && currentHp < maxHp) {
      final healAmount = (maxHp * healPercent).round();
      heal(healAmount);
      messages.add('${baseMonster.monsterName}はHPが${healAmount}回復した！');
    }
    
    return messages;
  }
}