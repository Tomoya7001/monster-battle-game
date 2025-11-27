import 'package:equatable/equatable.dart';

abstract class DraftEvent extends Equatable {
  const DraftEvent();

  @override
  List<Object?> get props => [];
}

/// ドラフトバトル開始（マッチング）
class StartDraftMatching extends DraftEvent {
  const StartDraftMatching();
}

/// マッチングタイマー更新
class UpdateMatchingTimer extends DraftEvent {
  final int waitSeconds;

  const UpdateMatchingTimer({required this.waitSeconds});

  @override
  List<Object?> get props => [waitSeconds];
}

/// マッチング成立、プール生成
class DraftMatchFound extends DraftEvent {
  final String battleId;
  final List<String> poolMonsterIds;

  const DraftMatchFound({
    required this.battleId,
    required this.poolMonsterIds,
  });

  @override
  List<Object?> get props => [battleId, poolMonsterIds];
}

/// モンスター選択/選択解除
class ToggleMonsterSelection extends DraftEvent {
  final String monsterId;

  const ToggleMonsterSelection({required this.monsterId});

  @override
  List<Object?> get props => [monsterId];
}

/// 選択確定
class ConfirmSelection extends DraftEvent {
  const ConfirmSelection();
}

/// タイマー更新
class UpdateTimer extends DraftEvent {
  final int remainingSeconds;

  const UpdateTimer({required this.remainingSeconds});

  @override
  List<Object?> get props => [remainingSeconds];
}

/// 時間切れ（ランダム補完）
class TimeExpired extends DraftEvent {
  const TimeExpired();
}

/// 相手が確定済み
class OpponentConfirmed extends DraftEvent {
  const OpponentConfirmed();
}

/// 両者確定、バトル開始（Draft用）
class DraftBattleStart extends DraftEvent {
  const DraftBattleStart();
}

/// キャンセル
class CancelDraftMatching extends DraftEvent {
  const CancelDraftMatching();
}

/// エラー発生
class DraftError extends DraftEvent {
  final String message;

  const DraftError({required this.message});

  @override
  List<Object?> get props => [message];
}