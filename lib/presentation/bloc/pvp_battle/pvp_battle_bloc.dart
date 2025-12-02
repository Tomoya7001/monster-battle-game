// lib/presentation/bloc/pvp_battle/pvp_battle_bloc.dart
// PvPバトル専用BLoC（カジュアル/ランク/フレンド対応）

import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/monster.dart';
import '../../../domain/models/battle/battle_result.dart';
import 'pvp_battle_event.dart';
import 'pvp_battle_state.dart';

/// PvPバトル専用BLoC
class PvpBattleBloc extends Bloc<PvpBattleEvent, PvpBattleState> {
  final FirebaseFirestore _firestore;
  final Random _random = Random();
  
  // Lv50固定制
  static const int _pvpFixedLevel = 50;
  
  // コスト設定
  static const int _initialCost = 3;
  static const int _costPerTurn = 2;
  static const int _maxCost = 6;

  PvpBattleBloc({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        super(const PvpBattleState()) {
    // バトル開始系
    on<StartCasualMatch>(_onStartCasualMatch);
    on<StartRankedMatch>(_onStartRankedMatch);
    on<StartFriendBattle>(_onStartFriendBattle);
    
    // モンスター選択系
    on<SelectFirstMonster>(_onSelectFirstMonster);
    on<SelectSwitchMonster>(_onSelectSwitchMonster);
    on<RequestSwitch>(_onRequestSwitch);
    
    // 行動選択系
    on<SelectSkill>(_onSelectSkill);
    on<SelectWait>(_onSelectWait);
    
    // CPU / ターン処理系
    on<ExecuteCpuAction>(_onExecuteCpuAction);
    on<ProcessTurnEnd>(_onProcessTurnEnd);
    
    // バトル終了系
    on<Surrender>(_onSurrender);
    on<TimeoutAction>(_onTimeoutAction);
    on<EndBattle>(_onEndBattle);
  }

  // ============================================================
  // バトル開始系
  // ============================================================

  Future<void> _onStartCasualMatch(
    StartCasualMatch event,
    Emitter<PvpBattleState> emit,
  ) async {
    emit(state.copyWith(status: PvpBattleStatus.loading));

    try {
      // プレイヤーパーティをLv50固定でPvpMonsterに変換
      final playerParty = event.playerParty
          .map((m) => _convertToLv50PvpMonster(m))
          .toList();

      // CPUパーティ生成
      final enemyParty = await _generateCpuParty();

      emit(state.copyWith(
        status: PvpBattleStatus.selectingFirstMonster,
        battleId: 'casual_${DateTime.now().millisecondsSinceEpoch}',
        playerName: event.playerName,
        opponentName: event.opponentName,
        isCpuOpponent: event.isCpuOpponent,
        playerParty: playerParty,
        playerBench: playerParty,
        playerCost: _initialCost,
        playerUsedMonsterCount: 0,
        enemyParty: enemyParty,
        enemyBench: enemyParty,
        enemyCost: _initialCost,
        enemyUsedMonsterCount: 0,
        turnCount: 0,
        battleLog: ['カジュアルマッチ開始！'],
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PvpBattleStatus.error,
        errorMessage: 'バトル開始エラー: $e',
      ));
    }
  }

  Future<void> _onStartRankedMatch(
    StartRankedMatch event,
    Emitter<PvpBattleState> emit,
  ) async {
    emit(state.copyWith(
      status: PvpBattleStatus.error,
      errorMessage: 'ランクマッチは現在準備中です',
    ));
  }

  Future<void> _onStartFriendBattle(
    StartFriendBattle event,
    Emitter<PvpBattleState> emit,
  ) async {
    emit(state.copyWith(
      status: PvpBattleStatus.error,
      errorMessage: 'フレンドバトルは現在準備中です',
    ));
  }

  // ============================================================
  // モンスター選択系
  // ============================================================

  Future<void> _onSelectFirstMonster(
    SelectFirstMonster event,
    Emitter<PvpBattleState> emit,
  ) async {
    final monster = event.monster;
    final newBench = state.playerBench.where((m) => m.id != monster.id).toList();

    // CPUも最初のモンスターを選択
    final cpuMonster = _selectCpuFirstMonster();
    final cpuBench = state.enemyBench.where((m) => m.id != cpuMonster.id).toList();

    final log = List<String>.from(state.battleLog);
    log.add('${state.playerName}は${monster.name}を繰り出した！');
    log.add('${state.opponentName}は${cpuMonster.name}を繰り出した！');

    emit(state.copyWith(
      status: PvpBattleStatus.inProgress,
      playerActiveMonster: monster,
      playerBench: newBench,
      playerUsedMonsterCount: 1,
      enemyActiveMonster: cpuMonster,
      enemyBench: cpuBench,
      enemyUsedMonsterCount: 1,
      turnCount: 1,
      isPlayerTurn: true,
      battleLog: log,
    ));
  }

  Future<void> _onSelectSwitchMonster(
    SelectSwitchMonster event,
    Emitter<PvpBattleState> emit,
  ) async {
    final monster = event.monster;
    
    // 使用上限チェック
    if (state.playerUsedMonsterCount >= 3 && !state.isForcedSwitch) {
      emit(state.copyWith(
        battleLog: [...state.battleLog, 'これ以上モンスターを出せません！'],
        needsMonsterSwitch: false,
      ));
      return;
    }

    // 現在のモンスターをベンチに戻す（瀕死でなければ）
    final newBench = List<PvpMonster>.from(state.playerBench);
    if (state.playerActiveMonster != null && 
        state.playerActiveMonster!.currentHp > 0 &&
        !state.isForcedSwitch) {
      newBench.add(state.playerActiveMonster!);
    }
    newBench.removeWhere((m) => m.id == monster.id);

    final log = List<String>.from(state.battleLog);
    if (!state.isForcedSwitch && state.playerActiveMonster != null) {
      log.add('${state.playerName}は${state.playerActiveMonster!.name}を引っ込めた！');
    }
    log.add('${state.playerName}は${monster.name}を繰り出した！');

    final newUsedCount = state.isForcedSwitch 
        ? state.playerUsedMonsterCount + 1 
        : state.playerUsedMonsterCount;

    emit(state.copyWith(
      playerActiveMonster: monster,
      playerBench: newBench,
      playerUsedMonsterCount: newUsedCount,
      playerCost: state.isForcedSwitch ? state.playerCost : _initialCost,
      needsMonsterSwitch: false,
      isForcedSwitch: false,
      isPlayerTurn: state.isForcedSwitch ? true : false,
      battleLog: log,
    ));

    // 強制交代でなければCPUのターンへ
    if (!state.isForcedSwitch && state.isCpuOpponent) {
      add(const ExecuteCpuAction());
    }
  }

  Future<void> _onRequestSwitch(
    RequestSwitch event,
    Emitter<PvpBattleState> emit,
  ) async {
    // トグル動作
    emit(state.copyWith(
      needsMonsterSwitch: !state.needsMonsterSwitch,
      isForcedSwitch: false,
    ));
  }

  // ============================================================
  // 行動選択系
  // ============================================================

  Future<void> _onSelectSkill(
    SelectSkill event,
    Emitter<PvpBattleState> emit,
  ) async {
    final skill = event.skill;
    final attacker = state.playerActiveMonster;
    final defender = state.enemyActiveMonster;

    if (attacker == null || defender == null) return;

    // コストチェック
    if (skill.cost > state.playerCost) {
      emit(state.copyWith(
        battleLog: [...state.battleLog, 'コストが足りません！'],
      ));
      return;
    }

    // ダメージ計算
    final damage = _calculateDamage(attacker, defender, skill);
    final newDefenderHp = (defender.currentHp - damage).clamp(0, defender.maxHp);
    
    // 相手モンスターのHP更新
    final updatedDefender = defender.copyWith(currentHp: newDefenderHp);

    final log = List<String>.from(state.battleLog);
    log.add('${attacker.name}の${skill.name}！');
    log.add('${defender.name}に$damageのダメージ！');

    final newPlayerCost = (state.playerCost - skill.cost).clamp(0, _maxCost);

    // 相手モンスター撃破チェック
    if (newDefenderHp <= 0) {
      log.add('${defender.name}は倒れた！');
      
      // 相手に交代可能なモンスターがいるか
      final remainingEnemy = state.enemyBench.where((m) => m.currentHp > 0).toList();
      if (remainingEnemy.isEmpty || state.enemyUsedMonsterCount >= 3) {
        emit(state.copyWith(
          enemyActiveMonster: updatedDefender,
          playerCost: newPlayerCost,
          battleLog: log,
        ));
        add(const EndBattle(isPlayerWin: true));
        return;
      }

      // CPUが次のモンスターを選択
      final nextMonster = _selectCpuNextMonster(remainingEnemy);
      final newEnemyBench = remainingEnemy.where((m) => m.id != nextMonster.id).toList();
      
      log.add('${state.opponentName}は${nextMonster.name}を繰り出した！');

      emit(state.copyWith(
        enemyActiveMonster: nextMonster,
        enemyBench: newEnemyBench,
        enemyUsedMonsterCount: state.enemyUsedMonsterCount + 1,
        enemyCost: _initialCost,
        playerCost: newPlayerCost,
        battleLog: log,
      ));
      
      add(const ProcessTurnEnd());
    } else {
      emit(state.copyWith(
        enemyActiveMonster: updatedDefender,
        playerCost: newPlayerCost,
        isPlayerTurn: false,
        battleLog: log,
      ));

      if (state.isCpuOpponent) {
        add(const ExecuteCpuAction());
      }
    }
  }

  Future<void> _onSelectWait(
    SelectWait event,
    Emitter<PvpBattleState> emit,
  ) async {
    final log = List<String>.from(state.battleLog);
    log.add('${state.playerActiveMonster?.name}は様子を見ている...');

    emit(state.copyWith(
      isPlayerTurn: false,
      battleLog: log,
    ));

    if (state.isCpuOpponent) {
      add(const ExecuteCpuAction());
    }
  }

  // ============================================================
  // CPU / ターン処理系
  // ============================================================

  Future<void> _onExecuteCpuAction(
    ExecuteCpuAction event,
    Emitter<PvpBattleState> emit,
  ) async {
    final cpuMonster = state.enemyActiveMonster;
    final playerMonster = state.playerActiveMonster;

    if (cpuMonster == null || playerMonster == null) return;

    // 使用可能な技を取得
    final usableSkills = cpuMonster.skills
        .where((s) => s.cost <= state.enemyCost)
        .toList();

    if (usableSkills.isEmpty) {
      final log = List<String>.from(state.battleLog);
      log.add('${cpuMonster.name}は様子を見ている...');
      
      emit(state.copyWith(battleLog: log));
      add(const ProcessTurnEnd());
      return;
    }

    // AI: 70%で最適技、30%でランダム
    PvpSkill selectedSkill;
    if (_random.nextDouble() < 0.7) {
      selectedSkill = usableSkills.reduce((a, b) {
        final damageA = _calculateDamage(cpuMonster, playerMonster, a);
        final damageB = _calculateDamage(cpuMonster, playerMonster, b);
        return damageA > damageB ? a : b;
      });
    } else {
      selectedSkill = usableSkills[_random.nextInt(usableSkills.length)];
    }

    // ダメージ計算
    final damage = _calculateDamage(cpuMonster, playerMonster, selectedSkill);
    final newPlayerHp = (playerMonster.currentHp - damage).clamp(0, playerMonster.maxHp);
    final updatedPlayer = playerMonster.copyWith(currentHp: newPlayerHp);

    final log = List<String>.from(state.battleLog);
    log.add('${cpuMonster.name}の${selectedSkill.name}！');
    log.add('${playerMonster.name}に$damageのダメージ！');

    final newEnemyCost = (state.enemyCost - selectedSkill.cost).clamp(0, _maxCost);

    // プレイヤーモンスター撃破チェック
    if (newPlayerHp <= 0) {
      log.add('${playerMonster.name}は倒れた！');

      final remainingPlayer = state.playerBench.where((m) => m.currentHp > 0).toList();
      if (remainingPlayer.isEmpty || state.playerUsedMonsterCount >= 3) {
        emit(state.copyWith(
          playerActiveMonster: updatedPlayer,
          enemyCost: newEnemyCost,
          battleLog: log,
        ));
        add(const EndBattle(isPlayerWin: false));
        return;
      }

      // プレイヤーに強制交代を要求
      emit(state.copyWith(
        playerActiveMonster: updatedPlayer,
        enemyCost: newEnemyCost,
        needsMonsterSwitch: true,
        isForcedSwitch: true,
        isPlayerTurn: true,
        battleLog: log,
      ));
    } else {
      emit(state.copyWith(
        playerActiveMonster: updatedPlayer,
        enemyCost: newEnemyCost,
        battleLog: log,
      ));
      
      add(const ProcessTurnEnd());
    }
  }

  Future<void> _onProcessTurnEnd(
    ProcessTurnEnd event,
    Emitter<PvpBattleState> emit,
  ) async {
    final newPlayerCost = (state.playerCost + _costPerTurn).clamp(0, _maxCost);
    final newEnemyCost = (state.enemyCost + _costPerTurn).clamp(0, _maxCost);

    emit(state.copyWith(
      turnCount: state.turnCount + 1,
      playerCost: newPlayerCost,
      enemyCost: newEnemyCost,
      isPlayerTurn: true,
    ));
  }

  // ============================================================
  // バトル終了系
  // ============================================================

  Future<void> _onSurrender(
    Surrender event,
    Emitter<PvpBattleState> emit,
  ) async {
    final log = List<String>.from(state.battleLog);
    log.add('${state.playerName}は降参した！');
    
    emit(state.copyWith(battleLog: log));
    add(const EndBattle(isPlayerWin: false));
  }

  Future<void> _onTimeoutAction(
    TimeoutAction event,
    Emitter<PvpBattleState> emit,
  ) async {
    if (event.consecutiveTimeouts >= 2) {
      final log = List<String>.from(state.battleLog);
      log.add('時間切れ！${state.playerName}の敗北！');
      
      emit(state.copyWith(battleLog: log));
      add(const EndBattle(isPlayerWin: false));
    } else {
      add(const SelectWait());
    }
  }

  Future<void> _onEndBattle(
    EndBattle event,
    Emitter<PvpBattleState> emit,
  ) async {
    final log = List<String>.from(state.battleLog);
    log.add(event.isPlayerWin 
        ? '${state.playerName}の勝利！' 
        : '${state.opponentName}の勝利！');

    final rewards = BattleRewards(
      exp: event.isPlayerWin ? 100 : 30,
      gold: event.isPlayerWin ? 500 : 100,
      gems: event.isPlayerWin ? 10 : 0,
      items: [],
    );

    final result = BattleResult(
      isWin: event.isPlayerWin,
      turnCount: state.turnCount,
      rewards: rewards,
      usedMonsterIds: state.playerParty.map((m) => m.id).toList(),
      expGains: [],
    );

    emit(state.copyWith(
      status: PvpBattleStatus.finished,
      result: result,
      battleLog: log,
    ));
  }

  // ============================================================
  // ユーティリティ
  // ============================================================

  /// MonsterをLv50固定のPvpMonsterに変換
  PvpMonster _convertToLv50PvpMonster(Monster monster) {
    // Lv50時のステータスを使用（Monsterクラスに既にlv50Xxxがある）
    final hp = monster.lv50MaxHp;
    final attack = monster.lv50Attack;
    final defense = monster.lv50Defense;
    final magic = monster.lv50Magic;
    final speed = monster.lv50Speed;

    // デフォルト技（equippedSkillsから後で読み込む場合は別途実装）
    final skills = _generateDefaultSkills(monster.element);

    return PvpMonster(
      id: monster.id,
      name: monster.monsterName,
      element: monster.element,
      species: monster.species,
      level: _pvpFixedLevel,
      maxHp: hp,
      currentHp: hp,
      attack: attack,
      defense: defense,
      magic: magic,
      speed: speed,
      skills: skills,
    );
  }

  /// CPUパーティ生成
  Future<List<PvpMonster>> _generateCpuParty() async {
    try {
      final snapshot = await _firestore
          .collection('monster_masters')
          .limit(30)
          .get();

      if (snapshot.docs.isEmpty) {
        return _generateFallbackCpuParty();
      }

      final allMonsters = snapshot.docs.map((doc) {
        final data = doc.data();
        return _createCpuMonsterFromMaster(data);
      }).toList();

      allMonsters.shuffle(_random);
      return allMonsters.take(5).toList();
    } catch (e) {
      return _generateFallbackCpuParty();
    }
  }

  /// マスターデータからCPUモンスター生成
  PvpMonster _createCpuMonsterFromMaster(Map<String, dynamic> data) {
    final level = _pvpFixedLevel;
    
    final baseHp = data['base_hp'] as int? ?? 100;
    final baseAttack = data['base_attack'] as int? ?? 50;
    final baseDefense = data['base_defense'] as int? ?? 50;
    final baseMagic = data['base_magic'] as int? ?? 50;
    final baseSpeed = data['base_speed'] as int? ?? 50;

    final ivBonus = _random.nextInt(11);
    final hp = baseHp + (level * 2) + ivBonus;
    final attack = baseAttack + level + ivBonus;
    final defense = baseDefense + level + ivBonus;
    final magic = baseMagic + level + ivBonus;
    final speed = baseSpeed + level + ivBonus;

    final element = data['element'] as String? ?? 'Non';
    final skills = _generateDefaultSkills(element);

    return PvpMonster(
      id: 'cpu_${data['monster_id'] ?? _random.nextInt(10000)}',
      name: data['name'] as String? ?? 'CPUモンスター',
      element: element,
      species: data['species'] as String? ?? 'Unknown',
      level: level,
      maxHp: hp,
      currentHp: hp,
      attack: attack,
      defense: defense,
      magic: magic,
      speed: speed,
      skills: skills,
    );
  }

  /// デフォルト技生成
  List<PvpSkill> _generateDefaultSkills(String element) {
    final elementName = _getElementName(element);
    return [
      PvpSkill(
        id: 'skill_tackle',
        name: 'たいあたり',
        element: 'Non',
        type: 'physical',
        cost: 1,
        powerMultiplier: 0.4,
        accuracy: 100,
        description: '通常攻撃',
      ),
      PvpSkill(
        id: 'skill_element_1',
        name: '${elementName}アタック',
        element: element,
        type: 'physical',
        cost: 2,
        powerMultiplier: 0.6,
        accuracy: 100,
        description: '属性攻撃',
      ),
      PvpSkill(
        id: 'skill_element_2',
        name: '${elementName}ブラスト',
        element: element,
        type: 'magical',
        cost: 3,
        powerMultiplier: 0.9,
        accuracy: 90,
        description: '強力な属性攻撃',
      ),
      PvpSkill(
        id: 'skill_element_3',
        name: '${elementName}バースト',
        element: element,
        type: 'magical',
        cost: 4,
        powerMultiplier: 1.2,
        accuracy: 80,
        description: '最強の属性攻撃',
      ),
    ];
  }

  String _getElementName(String element) {
    const names = {
      'Fire': '炎', 'Water': '水', 'Thunder': '雷', 'Wind': '風',
      'Earth': '大地', 'Light': '光', 'Dark': '闘', 'Non': '無',
    };
    return names[element] ?? '無';
  }

  /// フォールバックCPUパーティ
  List<PvpMonster> _generateFallbackCpuParty() {
    final elements = ['Fire', 'Water', 'Thunder', 'Wind', 'Earth'];
    return List.generate(5, (i) {
      final element = elements[i % elements.length];
      final level = _pvpFixedLevel;
      final baseStats = 50 + _random.nextInt(30);
      
      return PvpMonster(
        id: 'cpu_fallback_$i',
        name: 'CPUモンスター${i + 1}',
        element: element,
        species: 'Unknown',
        level: level,
        maxHp: 100 + (level * 2) + _random.nextInt(20),
        currentHp: 100 + (level * 2) + _random.nextInt(20),
        attack: baseStats + level,
        defense: baseStats + level,
        magic: baseStats + level,
        speed: baseStats + level,
        skills: _generateDefaultSkills(element),
      );
    });
  }

  /// CPU最初のモンスター選択
  PvpMonster _selectCpuFirstMonster() {
    if (_random.nextDouble() < 0.6) {
      return state.enemyBench.reduce((a, b) => a.speed > b.speed ? a : b);
    }
    return state.enemyBench[_random.nextInt(state.enemyBench.length)];
  }

  /// CPU次のモンスター選択
  PvpMonster _selectCpuNextMonster(List<PvpMonster> remaining) {
    if (_random.nextDouble() < 0.6) {
      return remaining.reduce((a, b) => a.currentHp > b.currentHp ? a : b);
    }
    return remaining[_random.nextInt(remaining.length)];
  }

  /// ダメージ計算
  int _calculateDamage(PvpMonster attacker, PvpMonster defender, PvpSkill skill) {
    final isPhysical = skill.type == 'physical';
    final attackStat = isPhysical ? attacker.attack : attacker.magic;
    final defenseStat = isPhysical ? defender.defense : defender.magic;

    // 基本ダメージ = 攻撃 * 威力倍率 / 防御 * 定数
    double damage = (attackStat * skill.powerMultiplier / defenseStat * 50).toDouble();

    // 属性相性
    final typeMultiplier = _getTypeMultiplier(skill.element, defender.element);
    damage *= typeMultiplier;

    // 乱数（85%〜100%）
    final random = 0.85 + _random.nextDouble() * 0.15;
    damage *= random;

    // クリティカル（6%）
    if (_random.nextDouble() < 0.06) {
      damage *= 1.5;
    }

    return damage.round().clamp(1, 9999);
  }

  /// 属性相性倍率取得
  double _getTypeMultiplier(String attackElement, String defenderElement) {
    const effectiveness = {
      'Fire': {'Wind': 1.3, 'Water': 0.77, 'Earth': 0.77},
      'Water': {'Fire': 1.3, 'Thunder': 0.77, 'Earth': 1.3},
      'Thunder': {'Water': 1.3, 'Earth': 0.77, 'Wind': 1.3},
      'Wind': {'Earth': 1.3, 'Fire': 0.77, 'Thunder': 0.77},
      'Earth': {'Fire': 1.3, 'Wind': 0.77, 'Water': 0.77},
      'Light': {'Dark': 1.3},
      'Dark': {'Light': 1.3},
    };
    return effectiveness[attackElement]?[defenderElement] ?? 1.0;
  }
}
