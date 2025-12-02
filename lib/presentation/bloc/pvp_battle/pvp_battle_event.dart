// lib/presentation/bloc/pvp_battle/pvp_battle_event.dart
// PvPバトル専用Event

import '../../../domain/entities/monster.dart';
import 'pvp_battle_state.dart';

/// PvPバトルイベント基底クラス
abstract class PvpBattleEvent {
  const PvpBattleEvent();
}

// ============================================================
// バトル開始系
// ============================================================

/// カジュアルマッチ開始
class StartCasualMatch extends PvpBattleEvent {
  final List<Monster> playerParty;
  final String playerId;
  final String playerName;
  final String opponentName;
  final bool isCpuOpponent;

  const StartCasualMatch({
    required this.playerParty,
    required this.playerId,
    required this.playerName,
    required this.opponentName,
    this.isCpuOpponent = true,
  });
}

/// ランクマッチ開始（将来用）
class StartRankedMatch extends PvpBattleEvent {
  final List<Monster> playerParty;
  final String playerId;
  final String playerName;
  final String opponentId;
  final String opponentName;
  final List<Monster> opponentParty;

  const StartRankedMatch({
    required this.playerParty,
    required this.playerId,
    required this.playerName,
    required this.opponentId,
    required this.opponentName,
    required this.opponentParty,
  });
}

/// フレンドバトル開始（将来用）
class StartFriendBattle extends PvpBattleEvent {
  final List<Monster> playerParty;
  final String playerId;
  final String playerName;
  final String friendId;
  final String friendName;
  final List<Monster> friendParty;

  const StartFriendBattle({
    required this.playerParty,
    required this.playerId,
    required this.playerName,
    required this.friendId,
    required this.friendName,
    required this.friendParty,
  });
}

// ============================================================
// モンスター選択系
// ============================================================

/// 最初のモンスター選択
class SelectFirstMonster extends PvpBattleEvent {
  final PvpMonster monster;

  const SelectFirstMonster(this.monster);
}

/// 交代モンスター選択
class SelectSwitchMonster extends PvpBattleEvent {
  final PvpMonster monster;

  const SelectSwitchMonster(this.monster);
}

/// 交代リクエスト（交代UI表示）
class RequestSwitch extends PvpBattleEvent {
  const RequestSwitch();
}

// ============================================================
// 行動選択系
// ============================================================

/// 技選択
class SelectSkill extends PvpBattleEvent {
  final PvpSkill skill;

  const SelectSkill(this.skill);
}

/// 待機選択
class SelectWait extends PvpBattleEvent {
  const SelectWait();
}

// ============================================================
// CPU / ターン処理系
// ============================================================

/// CPU行動実行
class ExecuteCpuAction extends PvpBattleEvent {
  const ExecuteCpuAction();
}

/// ターン終了処理
class ProcessTurnEnd extends PvpBattleEvent {
  const ProcessTurnEnd();
}

// ============================================================
// バトル終了系
// ============================================================

/// 降参
class Surrender extends PvpBattleEvent {
  const Surrender();
}

/// タイムアウト（時間切れ）
class TimeoutAction extends PvpBattleEvent {
  final int consecutiveTimeouts;

  const TimeoutAction({required this.consecutiveTimeouts});
}

/// バトル終了
class EndBattle extends PvpBattleEvent {
  final bool isPlayerWin;

  const EndBattle({required this.isPlayerWin});
}
