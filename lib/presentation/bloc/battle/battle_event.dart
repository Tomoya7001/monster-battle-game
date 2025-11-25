// 行数不明のため、完全なソース提供

import 'package:equatable/equatable.dart';
import '../../../domain/entities/monster.dart';
import '../../../domain/models/battle/battle_skill.dart';
import '../../../domain/models/stage/stage_data.dart'; // ★追加

abstract class BattleEvent extends Equatable {
  const BattleEvent();

  @override
  List<Object?> get props => [];
}

/// CPUバトル開始
class StartCpuBattle extends BattleEvent {
  final List<Monster> playerParty;

  const StartCpuBattle({required this.playerParty});

  @override
  List<Object?> get props => [playerParty];
}

/// ★NEW: ステージバトル開始
class StartStageBattle extends BattleEvent {
  final List<Monster> playerParty;
  final StageData stageData;

  const StartStageBattle({
    required this.playerParty,
    required this.stageData,
  });

  @override
  List<Object?> get props => [playerParty, stageData];
}

/// 初期モンスター選択
class SelectFirstMonster extends BattleEvent {
  final String monsterId;

  const SelectFirstMonster({required this.monsterId});

  @override
  List<Object?> get props => [monsterId];
}

/// 技使用
class UseSkill extends BattleEvent {
  final BattleSkill skill;

  const UseSkill({required this.skill});

  @override
  List<Object?> get props => [skill];
}

/// モンスター交代
class SwitchMonster extends BattleEvent {
  final String monsterId;
  final bool isForcedSwitch;

  const SwitchMonster({
    required this.monsterId,
    this.isForcedSwitch = false,
  });

  @override
  List<Object?> get props => [monsterId, isForcedSwitch];
}

/// 待機
class WaitTurn extends BattleEvent {
  const WaitTurn();
}

/// ターン終了処理
class ProcessTurnEnd extends BattleEvent {
  const ProcessTurnEnd();
}

/// バトル終了
class EndBattle extends BattleEvent {
  const EndBattle();
}

/// ★NEW: エラーリトライ
class RetryAfterError extends BattleEvent {
  const RetryAfterError();
}

/// ★NEW: バトル強制終了
class ForceBattleEnd extends BattleEvent {
  const ForceBattleEnd();
}