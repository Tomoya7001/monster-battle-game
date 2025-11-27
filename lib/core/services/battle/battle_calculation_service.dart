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
  /// 状態異常補正 = 火傷時は物理攻撃×0.5
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

    // ★火傷状態で物理技の威力半減
    if (attacker.statusAilment == 'burn' && skill.type == 'physical') {
      baseDamage *= 0.5;
    }

    // ★追加: 装備効果 - 属性技威力ブースト
    final attributeBoost = attacker.getAttributeBoost(skill.element);
    if (attributeBoost > 0) {
      baseDamage *= (1.0 + attributeBoost);
    }

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

    // 5. クリティカル判定（6% + 装備ブースト）
    double criticalChance = 0.06 + attacker.criticalRateBoost;
    bool isCritical = _random.nextDouble() < criticalChance;
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
    double hitChance = skill.accuracy.toDouble();

    // 命中率ステージ補正
    hitChance *= _getAccuracyMultiplier(attacker.accuracyStage);

    // ★追加: 装備効果 - 命中率ブースト
    hitChance *= (1.0 + attacker.accuracyBoost);

    // 回避率ステージ補正
    hitChance /= _getEvasionMultiplier(defender.evasionStage);

    // 最終判定
    return _random.nextInt(100) < hitChance.round().clamp(1, 100);
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

  // ========== Week 2: バフ・デバフシステム ==========

  /// バフ・デバフ効果を適用
  /// 
  /// ★既存Firestoreデータ構造に対応（2パターンサポート）:
  /// 
  /// パターン1（既存形式）:
  /// {
  ///   "buff": {"stat": "attack", "stage": 2},
  ///   "buff2": {"stat": "defense", "stage": 1},
  ///   "debuff": {"stat": "speed", "stage": -1, "chance": 30}
  /// }
  /// 
  /// パターン2（新形式）:
  /// {
  ///   "stat_changes": [
  ///     {"target": "self", "stat": "attack", "stages": 2, "probability": 100}
  ///   ]
  /// }
  static List<String> applyStatChanges({
    required BattleSkill skill,
    required BattleMonster user,
    BattleMonster? target,
  }) {
    final List<String> messages = [];
    
    // パターン2（新形式）の処理
    final statChanges = skill.effects['stat_changes'] as List<dynamic>?;
    if (statChanges != null && statChanges.isNotEmpty) {
      for (var change in statChanges) {
        final changeData = change as Map<String, dynamic>;
        
        final probability = changeData['probability'] as int? ?? 100;
        if (_random.nextInt(100) >= probability) continue;

        final targetType = changeData['target'] as String;
        BattleMonster? affectedMonster;
        if (targetType == 'self') {
          affectedMonster = user;
        } else if (targetType == 'opponent' && target != null) {
          affectedMonster = target;
        }

        if (affectedMonster == null) continue;

        final stat = changeData['stat'] as String;
        final stages = changeData['stages'] as int;

        final String result = _applyStageChange(affectedMonster, stat, stages);
        messages.add(result);
      }
      return messages;
    }

    // パターン1（既存形式）の処理
    // buff, buff2, debuff, debuff2 などのキーを処理
    for (var key in skill.effects.keys) {
      if (!key.startsWith('buff') && !key.startsWith('debuff')) continue;
      
      final changeData = skill.effects[key] as Map<String, dynamic>?;
      if (changeData == null) continue;

      // 確率判定
      final probability = changeData['chance'] as int? ?? 100;
      if (_random.nextInt(100) >= probability) continue;

      // buff系は自分、debuff系は相手
      BattleMonster? affectedMonster;
      if (key.startsWith('buff')) {
        affectedMonster = user;
      } else if (key.startsWith('debuff') && target != null) {
        affectedMonster = target;
      }

      if (affectedMonster == null) continue;

      final stat = changeData['stat'] as String;
      final stage = changeData['stage'] as int;

      final String result = _applyStageChange(affectedMonster, stat, stage);
      messages.add(result);
    }

    return messages;
  }

  /// ステージ変更を実際に適用
  /// カスタマイズ: 新しいステータスを追加する場合は、ここにcase文を追加
  static String _applyStageChange(BattleMonster monster, String stat, int stages) {
    int currentStage = 0;
    String statName = '';

    // 現在のステージを取得
    switch (stat) {
      case 'attack':
        currentStage = monster.attackStage;
        statName = '攻撃';
        break;
      case 'defense':
        currentStage = monster.defenseStage;
        statName = '防御';
        break;
      case 'magic':
        currentStage = monster.magicStage;
        statName = '魔力';
        break;
      case 'speed':
        currentStage = monster.speedStage;
        statName = '素早さ';
        break;
      case 'accuracy':
        currentStage = monster.accuracyStage;
        statName = '命中率';
        break;
      case 'evasion':
        currentStage = monster.evasionStage;
        statName = '回避率';
        break;
      default:
        return '';
    }

    // 新しいステージを計算（-3 ~ +3の範囲内）
    final newStage = (currentStage + stages).clamp(-3, 3);
    final actualChange = newStage - currentStage;

    // 変更がない場合
    if (actualChange == 0) {
      if (stages > 0) {
        return '${monster.baseMonster.monsterName}の${statName}はこれ以上上がらない！';
      } else {
        return '${monster.baseMonster.monsterName}の${statName}はこれ以上下がらない！';
      }
    }

    // ステージを適用（★ここに持続ターンも追加）
    switch (stat) {
      case 'attack':
        monster.attackStage = newStage;
        monster.attackStageTurns = 3; // ★NEW: 3ターン持続
        break;
      case 'defense':
        monster.defenseStage = newStage;
        monster.defenseStageTurns = 3; // ★NEW
        break;
      case 'magic':
        monster.magicStage = newStage;
        monster.magicStageTurns = 3; // ★NEW
        break;
      case 'speed':
        monster.speedStage = newStage;
        monster.speedStageTurns = 3; // ★NEW
        break;
      case 'accuracy':
        monster.accuracyStage = newStage;
        monster.accuracyStageTurns = 3; // ★NEW
        break;
      case 'evasion':
        monster.evasionStage = newStage;
        monster.evasionStageTurns = 3; // ★NEW
        break;
    }

    // メッセージ生成
    final changeText = _getStageChangeText(actualChange);
    return '${monster.baseMonster.monsterName}の${statName}が${changeText}！';
  }

  /// ステージ変化のテキスト取得
  static String _getStageChangeText(int stages) {
    if (stages == 1) return '上がった';
    if (stages == 2) return 'ぐーんと上がった';
    if (stages == 3) return 'ぐぐーんと上がった';
    if (stages == -1) return '下がった';
    if (stages == -2) return 'がくっと下がった';
    if (stages == -3) return 'がくがくっと下がった';
    return '';
  }

  // ========== Week 3: 状態異常システム ==========

  /// 状態異常を付与
  /// 
  /// ★既存Firestoreデータ構造に対応（2パターンサポート）:
  /// 
  /// パターン1（既存形式）:
  /// {
  ///   "status_ailment": "burn",
  ///   "status_chance": 30
  /// }
  /// 
  /// パターン2（新形式）:
  /// {
  ///   "status_ailments": [
  ///     {"ailment": "burn", "probability": 30}
  ///   ]
  /// }
  static List<String> applyStatusAilments({
  required BattleSkill skill,
  required BattleMonster target,
    }) {
    final List<String> messages = [];

    // ★修正: 既に状態異常がある場合はログを追加
    if (target.statusAilment != null) {
        messages.add('${target.baseMonster.monsterName}は既に${_getStatusName(target.statusAilment!)}状態です');
        return messages;
    }

  // 以下、既存のコード...

    // パターン2（新形式）の処理
    final ailments = skill.effects['status_ailments'] as List<dynamic>?;
    if (ailments != null && ailments.isNotEmpty) {
      for (var ailmentData in ailments) {
        final data = ailmentData as Map<String, dynamic>;
        final probability = data['probability'] as int? ?? 100;
        
        if (_random.nextInt(100) >= probability) continue;

        final ailment = data['ailment'] as String;
        target.statusAilment = ailment;
        target.statusTurns = _getStatusDuration(ailment);
        
        messages.add('${target.baseMonster.monsterName}は${_getStatusName(ailment)}状態になった！');
        break;
      }
      return messages;
    }

    // パターン1（既存形式）の処理
    final ailment = skill.effects['status_ailment'] as String?;
    if (ailment == null) return messages;

    final probability = skill.effects['status_chance'] as int? ?? 100;
    
    // 確率判定
    if (_random.nextInt(100) >= probability) {
      return messages;
    }

    target.statusAilment = ailment;
    target.statusTurns = _getStatusDuration(ailment);
    
    messages.add('${target.baseMonster.monsterName}は${_getStatusName(ailment)}状態になった！');

    return messages;
  }

  /// 状態異常の持続ターン数を取得
  /// カスタマイズ: 状態異常の持続ターンを変更する場合はここを編集
  static int _getStatusDuration(String ailment) {
    switch (ailment) {
      case 'burn':
      case 'poison':
      case 'paralysis':
        return 3 + _random.nextInt(3); // 3-5ターン
      case 'sleep':
      case 'freeze':
        return 1 + _random.nextInt(3); // 1-3ターン
      case 'confusion':
        return 2 + _random.nextInt(3); // 2-4ターン
      default:
        return 3;
    }
  }

  /// 状態異常の日本語名
  static String _getStatusName(String ailment) {
    switch (ailment) {
      case 'burn':
        return 'やけど';
      case 'poison':
        return 'どく';
      case 'paralysis':
        return 'まひ';
      case 'sleep':
        return 'ねむり';
      case 'freeze':
        return 'こおり';
      case 'confusion':
        return 'こんらん';
      default:
        return ailment;
    }
  }

  /// ターン開始時の状態異常処理
  /// カスタマイズ: 新しい状態異常を追加する場合はここにcase文を追加
  static List<String> processStatusAilmentStart(BattleMonster monster) {
    final List<String> messages = [];
    
    if (monster.statusAilment == null) return messages;

    switch (monster.statusAilment) {
      case 'burn':
      case 'poison':
        // 火傷・毒: ターン開始時に最大HPの12.5%ダメージ
        final damage = (monster.maxHp * 0.125).round().clamp(1, monster.maxHp);
        monster.takeDamage(damage);
        messages.add('${monster.baseMonster.monsterName}は${_getStatusName(monster.statusAilment!)}のダメージを受けた！（${damage}ダメージ）');
        break;
      
      case 'sleep':
        messages.add('${monster.baseMonster.monsterName}はぐうぐう眠っている');
        break;
      
      case 'freeze':
        messages.add('${monster.baseMonster.monsterName}は凍っている');
        break;
      
      case 'confusion':
        messages.add('${monster.baseMonster.monsterName}は混乱している');
        break;
    }

    return messages;
  }

  /// 状態異常による行動可否判定
  /// カスタマイズ: 行動不能の条件を変更する場合はここを編集
  static StatusActionResult checkStatusAction(BattleMonster monster) {
    if (monster.statusAilment == null) {
      return StatusActionResult(canAct: true, message: '');
    }

    switch (monster.statusAilment) {
      case 'sleep':
      case 'freeze':
        // 眠り・凍結: 完全行動不能
        return StatusActionResult(
          canAct: false,
          message: '${monster.baseMonster.monsterName}は動けない！',
        );
      
      case 'paralysis':
        // 麻痺: 25%の確率で行動不能
        if (_random.nextInt(100) < 25) {
          return StatusActionResult(
            canAct: false,
            message: '${monster.baseMonster.monsterName}は痺れて動けない！',
          );
        }
        break;
      
      case 'confusion':
        // 混乱: 50%の確率で自分を攻撃
        if (_random.nextInt(100) < 50) {
          final damage = (monster.attack * 0.4).round().clamp(1, monster.maxHp);
          monster.takeDamage(damage);
          return StatusActionResult(
            canAct: false,
            message: '${monster.baseMonster.monsterName}は混乱して自分を攻撃した！（${damage}ダメージ）',
          );
        }
        break;
    }

    return StatusActionResult(canAct: true, message: '');
  }

  /// ターン終了時の状態異常処理
  /// カスタマイズ: 状態異常の回復条件を変更する場合はここを編集
  static List<String> processStatusAilmentEnd(BattleMonster monster) {
    final List<String> messages = [];
    
    if (monster.statusAilment == null) return messages;

    // ターン数を減らす
    monster.statusTurns--;

    // 状態異常が治る判定
    if (monster.statusTurns <= 0) {
      final ailmentName = _getStatusName(monster.statusAilment!);
      monster.statusAilment = null;
      monster.statusTurns = 0;
      messages.add('${monster.baseMonster.monsterName}の${ailmentName}が治った！');
    }

    return messages;
  }

  /// コスト回復時の状態異常補正
  /// 麻痺状態の場合、コスト回復量が-1される
  /// カスタマイズ: コスト回復の補正を変更する場合はここを編集
  static int getCostRecoveryAmount(BattleMonster monster) {
    int baseRecovery = 2; // 基本回復量

    // 麻痺状態: コスト回復-1
    if (monster.statusAilment == 'paralysis') {
      baseRecovery -= 1;
    }

    return baseRecovery.clamp(0, 6);
  }

  /// バフ/デバフの持続ターンを減算
  static List<String> decreaseStatStageTurns(BattleMonster monster) {
    final List<String> messages = [];
    
    // ターン減算前の値を保存
    final previousAttackStage = monster.attackStage;
    final previousDefenseStage = monster.defenseStage;
    final previousMagicStage = monster.magicStage;
    final previousSpeedStage = monster.speedStage;
    final previousAccuracyStage = monster.accuracyStage;
    final previousEvasionStage = monster.evasionStage;
    
    // 持続ターンを減算
    monster.decreaseStatStageTurns();
    
    // リセットされたステータスを検出してメッセージを追加
    if (previousAttackStage != 0 && monster.attackStage == 0) {
      messages.add('${monster.baseMonster.monsterName}の攻撃が元に戻った');
    }
    if (previousDefenseStage != 0 && monster.defenseStage == 0) {
      messages.add('${monster.baseMonster.monsterName}の防御が元に戻った');
    }
    if (previousMagicStage != 0 && monster.magicStage == 0) {
      messages.add('${monster.baseMonster.monsterName}の魔力が元に戻った');
    }
    if (previousSpeedStage != 0 && monster.speedStage == 0) {
      messages.add('${monster.baseMonster.monsterName}の素早さが元に戻った');
    }
    if (previousAccuracyStage != 0 && monster.accuracyStage == 0) {
      messages.add('${monster.baseMonster.monsterName}の命中率が元に戻った');
    }
    if (previousEvasionStage != 0 && monster.evasionStage == 0) {
      messages.add('${monster.baseMonster.monsterName}の回避率が元に戻った');
    }
    
    return messages;
  }

  // ========== 特殊効果システム ==========

  /// 反動技の処理（与ダメージの一定%を自分も受ける）
  /// 
  /// JSONデータ例:
  /// {
  ///   "recoil": 33  // 与ダメの33%を反動ダメージ
  /// }
  static List<String> applyRecoil({
    required BattleSkill skill,
    required BattleMonster user,
    required int damageDealt,
  }) {
    final List<String> messages = [];
    
    final recoilPercentage = skill.effects['recoil'];
    if (recoilPercentage == null || damageDealt <= 0) return messages;
    
    final percentage = recoilPercentage is int ? recoilPercentage : (recoilPercentage as num).toInt();
    final recoilDamage = (damageDealt * percentage / 100).round().clamp(1, user.currentHp);
    
    user.takeDamage(recoilDamage);
    messages.add('${user.baseMonster.monsterName}は反動で${recoilDamage}ダメージを受けた！');
    
    return messages;
  }

  /// ドレイン技の処理（与ダメージの一定%を回復）
  /// 
  /// JSONデータ例:
  /// {
  ///   "drain": 50  // 与ダメの50%を回復
  /// }
  static List<String> applyDrain({
    required BattleSkill skill,
    required BattleMonster user,
    required int damageDealt,
  }) {
    final List<String> messages = [];
    
    final drainPercentage = skill.effects['drain'];
    if (drainPercentage == null || damageDealt <= 0) return messages;
    
    final percentage = drainPercentage is int ? drainPercentage : (drainPercentage as num).toInt();
    final healAmount = (damageDealt * percentage / 100).round();
    
    if (healAmount <= 0) return messages;
    
    final beforeHp = user.currentHp;
    user.heal(healAmount);
    final actualHeal = user.currentHp - beforeHp;
    
    if (actualHeal > 0) {
      messages.add('${user.baseMonster.monsterName}はHPを${actualHeal}吸収した！');
    }
    
    return messages;
  }

  /// まもる状態を設定
  /// 
  /// JSONデータ例:
  /// {
  ///   "protect": true
  /// }
  static List<String> applyProtect({
    required BattleSkill skill,
    required BattleMonster user,
  }) {
    final List<String> messages = [];
    
    final isProtect = skill.effects['protect'];
    if (isProtect != true) return messages;
    
    // ★修正: まもる状態を設定
    user.isProtecting = true;
    messages.add('${user.baseMonster.monsterName}は身を守っている！');
    
    return messages;
  }

  /// 優先度を取得（先制技判定用）
  /// 
  /// JSONデータ例:
  /// {
  ///   "priority": 1  // +1で先制、-1で後攻
  /// }
  static int getPriority(BattleSkill skill) {
    final priority = skill.effects['priority'];
    if (priority == null) return 0;
    return priority is int ? priority : (priority as num).toInt();
  }

  // ========== 回復技システム ==========

  /// 回復技を実行
  /// 
  /// ★Firestoreデータ構造に対応（3パターンサポート）:
  /// 
  /// パターン1（Firestore実際の形式）:
  /// {
  ///   "heal_percentage": 50
  /// }
  /// 
  /// パターン2（既存形式）:
  /// {
  ///   "heal": {"percentage": 50}
  /// }
  /// 
  /// パターン3（新形式）:
  /// {
  ///   "heal_effects": [
  ///     {"type": "percentage", "value": 50, "target": "self"}
  ///   ]
  /// }
  static List<String> applyHeal({
    required BattleSkill skill,
    required BattleMonster user,
    BattleMonster? target,
  }) {
    final List<String> messages = [];

    // ★パターン1（Firestore実際の形式）: heal_percentageが直接ある場合
    final healPercentage = skill.effects['heal_percentage'];
    if (healPercentage != null) {
      final percentage = healPercentage is int ? healPercentage : (healPercentage as num).toInt();
      final healAmount = (user.maxHp * percentage / 100).round();

      final beforeHp = user.currentHp;
      user.heal(healAmount);
      final actualHeal = user.currentHp - beforeHp;

      if (actualHeal > 0) {
        messages.add('${user.baseMonster.monsterName}のHPが${actualHeal}回復した！');
      } else {
        messages.add('${user.baseMonster.monsterName}のHPは満タンだ！');
      }

      // ★状態異常回復
      if (skill.effects['cure_status'] == true && user.statusAilment != null) {
        final ailmentName = _getStatusName(user.statusAilment!);
        user.statusAilment = null;
        user.statusTurns = 0;
        messages.add('${user.baseMonster.monsterName}の${ailmentName}が治った！');
      }

      return messages;
    }

    // パターン3（新形式）の処理
    final healEffects = skill.effects['heal_effects'] as List<dynamic>?;
    if (healEffects != null && healEffects.isNotEmpty) {
      for (var healData in healEffects) {
        final data = healData as Map<String, dynamic>;
        
        final targetType = data['target'] as String? ?? 'self';
        BattleMonster? healTarget;
        if (targetType == 'self') {
          healTarget = user;
        } else if (targetType == 'ally' && target != null) {
          healTarget = target;
        }

        if (healTarget == null) continue;

        final healType = data['type'] as String? ?? 'percentage';
        final value = data['value'] as int? ?? 50;

        int healAmount;
        if (healType == 'percentage') {
          // パーセンテージ回復
          healAmount = (healTarget.maxHp * value / 100).round();
        } else {
          // 固定値回復
          healAmount = value;
        }

        final beforeHp = healTarget.currentHp;
        healTarget.heal(healAmount);
        final actualHeal = healTarget.currentHp - beforeHp;

        if (actualHeal > 0) {
          messages.add('${healTarget.baseMonster.monsterName}のHPが${actualHeal}回復した！');
        } else {
          messages.add('${healTarget.baseMonster.monsterName}のHPは満タンだ！');
        }
      }
      return messages;
    }

    // パターン2（既存形式）の処理
    final healData = skill.effects['heal'] as Map<String, dynamic>?;
    if (healData == null) return messages;

    final percentage = healData['percentage'] as int? ?? 50;
    final healAmount = (user.maxHp * percentage / 100).round();

    final beforeHp = user.currentHp;
    user.heal(healAmount);
    final actualHeal = user.currentHp - beforeHp;

    if (actualHeal > 0) {
      messages.add('${user.baseMonster.monsterName}のHPが${actualHeal}回復した！');
    } else {
      messages.add('${user.baseMonster.monsterName}のHPは満タンだ！');
    }

    return messages;
  }

  // ========== 既存メソッド（互換性維持） ==========

  /// 素早さ判定（プレイヤーが先制かどうか）
  static bool isPlayerFirst(BattleMonster player, BattleMonster enemy) {
    // 素早さが同じ場合はランダム
    if (player.speed == enemy.speed) {
      return _random.nextBool();
    }
    return player.speed > enemy.speed;
  }
}

/// ダメージ計算結果
class BattleCalculationResult {
  final int damage;
  final bool isCritical;
  final double effectivenessMultiplier;
  final String effectivenessText;

  BattleCalculationResult({
    required this.damage,
    required this.isCritical,
    required this.effectivenessMultiplier,
    required this.effectivenessText,
  });
}

/// 状態異常による行動判定結果
class StatusActionResult {
  final bool canAct; // 行動可能か
  final String message; // 行動不能時のメッセージ

  StatusActionResult({
    required this.canAct,
    required this.message,
  });
}