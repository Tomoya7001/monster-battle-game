import 'package:equatable/equatable.dart';
import '../../../domain/entities/monster.dart';
import '../../../domain/models/battle/battle_skill.dart';

abstract class BattleEvent extends Equatable {
  const BattleEvent();

  @override
  List<Object?> get props => [];
}

/// バトル開始（CPUバトル）
class StartCpuBattle extends BattleEvent {
  final List<Monster> playerParty;

  const StartCpuBattle({required this.playerParty});

  @override
  List<Object?> get props => [playerParty];
}

/// 初期モンスター選択
class SelectFirstMonster extends BattleEvent {
  final String monsterId;

  const SelectFirstMonster({required this.monsterId});

  @override
  List<Object?> get props => [monsterId];
}

/// 技を使用
class UseSkill extends BattleEvent {
  final BattleSkill skill;

  const UseSkill({required this.skill});

  @override
  List<Object?> get props => [skill];
}

/// モンスター交代
class SwitchMonster extends BattleEvent {
  final String monsterId;
  final bool isForcedSwitch; // 瀕死による強制交代かどうか

  const SwitchMonster({
    required this.monsterId,
    this.isForcedSwitch = false, // デフォルトは自主的な交代
  });

  @override
  List<Object?> get props => [monsterId, isForcedSwitch];
}

/// 待機（ターンスキップ）
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