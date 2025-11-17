import 'package:equatable/equatable.dart';
import '../../../domain/models/battle/battle_state_model.dart';

abstract class BattleState extends Equatable {
  const BattleState();

  @override
  List<Object?> get props => [];
}

/// 初期状態
class BattleInitial extends BattleState {
  const BattleInitial();
}

/// バトル準備中
class BattleLoading extends BattleState {
  const BattleLoading();
}

/// バトル進行中
class BattleInProgress extends BattleState {
  final BattleStateModel battleState;
  final String? message;

  const BattleInProgress({
    required this.battleState,
    this.message,
  });

  @override
  List<Object?> get props => [battleState, message];
}

/// プレイヤー勝利
class BattlePlayerWin extends BattleState {
  final BattleStateModel battleState;

  const BattlePlayerWin({required this.battleState});

  @override
  List<Object?> get props => [battleState];
}

/// プレイヤー敗北
class BattlePlayerLose extends BattleState {
  final BattleStateModel battleState;

  const BattlePlayerLose({required this.battleState});

  @override
  List<Object?> get props => [battleState];
}

/// エラー
class BattleError extends BattleState {
  final String message;

  const BattleError({required this.message});

  @override
  List<Object?> get props => [message];
}