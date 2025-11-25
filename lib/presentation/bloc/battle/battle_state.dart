import 'package:equatable/equatable.dart';
import '../../../domain/models/battle/battle_state_model.dart';
import '../../../domain/models/battle/battle_result.dart'; // ★追加

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
  final BattleResult? result; // ★追加

  const BattlePlayerWin({
    required this.battleState,
    this.result,
  });

  @override
  List<Object?> get props => [battleState, result];
}

/// プレイヤー敗北
class BattlePlayerLose extends BattleState {
  final BattleStateModel battleState;
  final BattleResult? result; // ★追加

  const BattlePlayerLose({
    required this.battleState,
    this.result,
  });

  @override
  List<Object?> get props => [battleState, result];
}

/// ★NEW: ネットワークエラー
class BattleNetworkError extends BattleState {
  final BattleStateModel? battleState;
  final String message;
  final bool canRetry;

  const BattleNetworkError({
    this.battleState,
    required this.message,
    this.canRetry = true,
  });

  @override
  List<Object?> get props => [battleState, message, canRetry];
}

/// ★NEW: データ不整合エラー
class BattleDataError extends BattleState {
  final String message;
  final String details;

  const BattleDataError({
    required this.message,
    required this.details,
  });

  @override
  List<Object?> get props => [message, details];
}

/// エラー
class BattleError extends BattleState {
  final String message;

  const BattleError({required this.message});

  @override
  List<Object?> get props => [message];
}