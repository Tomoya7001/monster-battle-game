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

    // ★追加: 火傷状態で物理技の威力半減
    if (attacker.statusAilment == 'burn' && skill.type == 'physical') {
      baseDamage *= 0.5;
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

    // ステージを適用
    switch (stat) {
      case 'attack':
        monster.attackStage = newStage;
        break;
      case 'defense':
        monster.defenseStage = newStage;
        break;
      case 'magic':
        monster.magicStage = newStage;
        break;
      case 'speed':
        monster.speedStage = newStage;
        break;
      case 'accuracy':
        monster.accuracyStage = newStage;
        break;
      case 'evasion':
        monster.evasionStage = newStage;
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