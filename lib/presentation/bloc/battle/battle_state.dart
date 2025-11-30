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
  final bool isAutoMode;
  final int currentLoop;
  final int totalLoop;
  final int autoSpeed;  // ★追加

  const BattleInProgress({
    required this.battleState,
    this.message,
    this.isAutoMode = false,
    this.currentLoop = 0,
    this.totalLoop = 0,
    this.autoSpeed = 1,  // ★追加
  });

  @override
  List<Object?> get props => [battleState, message, isAutoMode, currentLoop, totalLoop, autoSpeed];
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

/// AUTOモード勝利（VICTORY画面スキップ用）
class BattleAutoWin extends BattleState {
  final BattleStateModel battleState;
  final BattleResult? result;

  const BattleAutoWin({
    required this.battleState,
    this.result,
  });

  @override
  List<Object?> get props => [battleState, result];
}

/// AUTOモード停止（バトル中にOFFにした場合）
class BattleAutoStopped extends BattleState {
  final BattleStateModel battleState;
  final BattleResult? result;

  const BattleAutoStopped({
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

class DamageInfo {
  final int damage;
  final String skillType;  // 'physical', 'magical', 'heal'
  final String element;
  final bool isCritical;
  final bool isEffective;
  final bool isResisted;
  final bool isHeal;
  final bool targetIsPlayer;  // true = プレイヤーがダメージを受けた

  DamageInfo({
    required this.damage,
    required this.skillType,
    required this.element,
    this.isCritical = false,
    this.isEffective = false,
    this.isResisted = false,
    this.isHeal = false,
    required this.targetIsPlayer,
  });
}