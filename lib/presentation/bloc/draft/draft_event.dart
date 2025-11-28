import 'package:equatable/equatable.dart';

abstract class DraftEvent extends Equatable {
  const DraftEvent();

  @override
  List<Object?> get props => [];
}

class StartDraftMatching extends DraftEvent {
  const StartDraftMatching();
}

class UpdateMatchingTimer extends DraftEvent {
  final int waitSeconds;

  const UpdateMatchingTimer({required this.waitSeconds});

  @override
  List<Object?> get props => [waitSeconds];
}

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

class ToggleMonsterSelection extends DraftEvent {
  final String monsterId;

  const ToggleMonsterSelection({required this.monsterId});

  @override
  List<Object?> get props => [monsterId];
}

class ConfirmSelection extends DraftEvent {
  const ConfirmSelection();
}

class UpdateTimer extends DraftEvent {
  final int remainingSeconds;

  const UpdateTimer({required this.remainingSeconds});

  @override
  List<Object?> get props => [remainingSeconds];
}

class TimeExpired extends DraftEvent {
  const TimeExpired();
}

class OpponentConfirmed extends DraftEvent {
  const OpponentConfirmed();
}

class DraftBattleStart extends DraftEvent {
  const DraftBattleStart();
}

class CancelDraftMatching extends DraftEvent {
  const CancelDraftMatching();
}

class DraftError extends DraftEvent {
  final String message;

  const DraftError({required this.message});

  @override
  List<Object?> get props => [message];
}