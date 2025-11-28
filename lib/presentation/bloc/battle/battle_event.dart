import '../../../domain/models/battle/battle_skill.dart';
import '../../../domain/entities/monster.dart';
import '../../../domain/models/stage/stage_data.dart';

/// バトルイベント
abstract class BattleEvent {
  const BattleEvent();
}

/// CPUバトル開始
class StartCpuBattle extends BattleEvent {
  final List<Monster> playerParty;

  const StartCpuBattle({required this.playerParty});
}

/// ステージバトル開始
class StartStageBattle extends BattleEvent {
  final List<Monster> playerParty;
  final StageData stageData;

  const StartStageBattle({
    required this.playerParty,
    required this.stageData,
  });
}

/*
/// ドラフトバトル開始
class StartDraftBattle extends BattleEvent {
  final List<Monster> playerParty;
  final List<Monster> enemyParty;
  final String battleId;
  final bool isCpuOpponent;

  const StartDraftBattle({
    required this.playerParty,
    required this.enemyParty,
    required this.battleId,
    this.isCpuOpponent = false,
  });
}
*/

/// 最初のモンスター選択
class SelectFirstMonster extends BattleEvent {
  final String monsterId;

  const SelectFirstMonster({required this.monsterId});
}

/// 技使用
class UseSkill extends BattleEvent {
  final BattleSkill skill;

  const UseSkill({required this.skill});
}

/// モンスター交代
class SwitchMonster extends BattleEvent {
  final String monsterId;
  final bool isForcedSwitch; // 瀕死による強制交代かどうか

  const SwitchMonster({
    required this.monsterId,
    this.isForcedSwitch = false,
  });
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

/// エラー後リトライ
class RetryAfterError extends BattleEvent {
  const RetryAfterError();
}

/// バトル強制終了
class ForceBattleEnd extends BattleEvent {
  const ForceBattleEnd();
}

/// 冒険エンカウントバトル開始
class StartAdventureEncounter extends BattleEvent {
  final String stageId;
  final List<Monster> playerParty;

  const StartAdventureEncounter({
    required this.stageId,
    required this.playerParty,
  });
}

/// ボスバトル開始
class StartBossBattle extends BattleEvent {
  final String stageId;
  final List<Monster> playerParty;

  const StartBossBattle({
    required this.stageId,
    required this.playerParty,
  });
}

  /// ドラフトバトル開始
class StartDraftBattle extends BattleEvent {
  final List<Monster> playerParty;
  final List<Monster> enemyParty;
  final String battleId;
  final bool isCpuOpponent;

  const StartDraftBattle({
    required this.playerParty,
    required this.enemyParty,
    required this.battleId,
    required this.isCpuOpponent,
  });

  @override
  List<Object?> get props => [playerParty, enemyParty, battleId, isCpuOpponent];
}

