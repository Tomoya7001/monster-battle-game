// lib/presentation/bloc/dispatch/dispatch_event.dart

import 'package:equatable/equatable.dart';

abstract class DispatchEvent extends Equatable {
  const DispatchEvent();

  @override
  List<Object?> get props => [];
}

/// 探索データ読み込み
class LoadDispatchData extends DispatchEvent {
  final String userId;

  const LoadDispatchData(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// 探索データリフレッシュ（タイマー用）
class RefreshDispatches extends DispatchEvent {
  const RefreshDispatches();
}

/// 探索開始
class StartDispatch extends DispatchEvent {
  final int slotIndex;
  final String locationId;
  final int durationHours;
  final List<String> monsterIds;

  const StartDispatch({
    required this.slotIndex,
    required this.locationId,
    required this.durationHours,
    required this.monsterIds,
  });

  @override
  List<Object?> get props => [slotIndex, locationId, durationHours, monsterIds];
}

/// 報酬受取
class ClaimDispatchReward extends DispatchEvent {
  final String dispatchId;

  const ClaimDispatchReward(this.dispatchId);

  @override
  List<Object?> get props => [dispatchId];
}

/// 探索枠解放
class UnlockDispatchSlot extends DispatchEvent {
  final int slotIndex;

  const UnlockDispatchSlot(this.slotIndex);

  @override
  List<Object?> get props => [slotIndex];
}

/// 探索キャンセル
class CancelDispatch extends DispatchEvent {
  final String dispatchId;

  const CancelDispatch(this.dispatchId);

  @override
  List<Object?> get props => [dispatchId];
}