// lib/presentation/bloc/pvp_battle/pvp_battle_state.dart
// PvPバトル専用State

import '../../../domain/models/battle/battle_result.dart';

/// PvP用技（簡易版）
class PvpSkill {
  final String id;
  final String name;
  final String element;
  final String type; // physical, magical
  final int cost;
  final double powerMultiplier;
  final int accuracy;
  final String description;

  const PvpSkill({
    required this.id,
    required this.name,
    required this.element,
    required this.type,
    required this.cost,
    required this.powerMultiplier,
    required this.accuracy,
    this.description = '',
  });

  /// 威力（表示用）
  int get power => (powerMultiplier * 100).round();
}

/// PvP用モンスター（簡易版）
class PvpMonster {
  final String id;
  final String name;
  final String element;
  final String species;
  final int level;
  final int maxHp;
  final int currentHp;
  final int attack;
  final int defense;
  final int magic;
  final int speed;
  final List<PvpSkill> skills;

  const PvpMonster({
    required this.id,
    required this.name,
    required this.element,
    required this.species,
    required this.level,
    required this.maxHp,
    required this.currentHp,
    required this.attack,
    required this.defense,
    required this.magic,
    required this.speed,
    required this.skills,
  });

  PvpMonster copyWith({
    String? id,
    String? name,
    String? element,
    String? species,
    int? level,
    int? maxHp,
    int? currentHp,
    int? attack,
    int? defense,
    int? magic,
    int? speed,
    List<PvpSkill>? skills,
  }) {
    return PvpMonster(
      id: id ?? this.id,
      name: name ?? this.name,
      element: element ?? this.element,
      species: species ?? this.species,
      level: level ?? this.level,
      maxHp: maxHp ?? this.maxHp,
      currentHp: currentHp ?? this.currentHp,
      attack: attack ?? this.attack,
      defense: defense ?? this.defense,
      magic: magic ?? this.magic,
      speed: speed ?? this.speed,
      skills: skills ?? this.skills,
    );
  }
}

/// PvPバトルの状態
enum PvpBattleStatus {
  initial,
  loading,
  selectingFirstMonster,
  inProgress,
  waitingForOpponent,
  finished,
  error,
}

/// PvPバトルState
class PvpBattleState {
  final PvpBattleStatus status;
  
  // バトル情報
  final String? battleId;
  final String playerName;
  final String opponentName;
  final bool isCpuOpponent;
  
  // プレイヤー側
  final List<PvpMonster> playerParty;
  final PvpMonster? playerActiveMonster;
  final List<PvpMonster> playerBench;
  final int playerCost;
  final int playerUsedMonsterCount;
  
  // 相手側
  final List<PvpMonster> enemyParty;
  final PvpMonster? enemyActiveMonster;
  final List<PvpMonster> enemyBench;
  final int enemyCost;
  final int enemyUsedMonsterCount;
  
  // ターン情報
  final int turnCount;
  final bool isPlayerTurn;
  final bool needsMonsterSwitch;
  final bool isForcedSwitch;
  
  // バトルログ
  final List<String> battleLog;
  
  // 結果
  final BattleResult? result;
  final String? errorMessage;

  const PvpBattleState({
    this.status = PvpBattleStatus.initial,
    this.battleId,
    this.playerName = '',
    this.opponentName = '',
    this.isCpuOpponent = false,
    this.playerParty = const [],
    this.playerActiveMonster,
    this.playerBench = const [],
    this.playerCost = 3,
    this.playerUsedMonsterCount = 0,
    this.enemyParty = const [],
    this.enemyActiveMonster,
    this.enemyBench = const [],
    this.enemyCost = 3,
    this.enemyUsedMonsterCount = 0,
    this.turnCount = 0,
    this.isPlayerTurn = true,
    this.needsMonsterSwitch = false,
    this.isForcedSwitch = false,
    this.battleLog = const [],
    this.result,
    this.errorMessage,
  });

  /// 交代可能かどうか
  bool get canSwitch => 
      playerBench.any((m) => m.currentHp > 0) && 
      playerUsedMonsterCount < 3;

  /// バトル継続可能かどうか
  bool get canContinueBattle =>
      playerActiveMonster != null &&
      playerActiveMonster!.currentHp > 0 &&
      enemyActiveMonster != null &&
      enemyActiveMonster!.currentHp > 0;

  PvpBattleState copyWith({
    PvpBattleStatus? status,
    String? battleId,
    String? playerName,
    String? opponentName,
    bool? isCpuOpponent,
    List<PvpMonster>? playerParty,
    PvpMonster? playerActiveMonster,
    List<PvpMonster>? playerBench,
    int? playerCost,
    int? playerUsedMonsterCount,
    List<PvpMonster>? enemyParty,
    PvpMonster? enemyActiveMonster,
    List<PvpMonster>? enemyBench,
    int? enemyCost,
    int? enemyUsedMonsterCount,
    int? turnCount,
    bool? isPlayerTurn,
    bool? needsMonsterSwitch,
    bool? isForcedSwitch,
    List<String>? battleLog,
    BattleResult? result,
    String? errorMessage,
    bool clearActiveMonster = false,
    bool clearResult = false,
  }) {
    return PvpBattleState(
      status: status ?? this.status,
      battleId: battleId ?? this.battleId,
      playerName: playerName ?? this.playerName,
      opponentName: opponentName ?? this.opponentName,
      isCpuOpponent: isCpuOpponent ?? this.isCpuOpponent,
      playerParty: playerParty ?? this.playerParty,
      playerActiveMonster: clearActiveMonster ? null : (playerActiveMonster ?? this.playerActiveMonster),
      playerBench: playerBench ?? this.playerBench,
      playerCost: playerCost ?? this.playerCost,
      playerUsedMonsterCount: playerUsedMonsterCount ?? this.playerUsedMonsterCount,
      enemyParty: enemyParty ?? this.enemyParty,
      enemyActiveMonster: clearActiveMonster ? null : (enemyActiveMonster ?? this.enemyActiveMonster),
      enemyBench: enemyBench ?? this.enemyBench,
      enemyCost: enemyCost ?? this.enemyCost,
      enemyUsedMonsterCount: enemyUsedMonsterCount ?? this.enemyUsedMonsterCount,
      turnCount: turnCount ?? this.turnCount,
      isPlayerTurn: isPlayerTurn ?? this.isPlayerTurn,
      needsMonsterSwitch: needsMonsterSwitch ?? this.needsMonsterSwitch,
      isForcedSwitch: isForcedSwitch ?? this.isForcedSwitch,
      battleLog: battleLog ?? this.battleLog,
      result: clearResult ? null : (result ?? this.result),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
