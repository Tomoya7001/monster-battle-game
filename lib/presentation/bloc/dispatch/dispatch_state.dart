// lib/presentation/bloc/dispatch/dispatch_state.dart

import 'package:equatable/equatable.dart';
import '../../../domain/entities/dispatch.dart';
import '../../../domain/entities/material.dart';
import '../../../domain/entities/monster.dart';

abstract class DispatchState extends Equatable {
  const DispatchState();

  @override
  List<Object?> get props => [];
}

/// 初期状態
class DispatchInitial extends DispatchState {
  const DispatchInitial();
}

/// 読み込み中
class DispatchLoading extends DispatchState {
  const DispatchLoading();
}

/// 読み込み完了
class DispatchLoaded extends DispatchState {
  final String userId;
  final UserDispatchSettings settings;
  final List<UserDispatch> activeDispatches;
  final List<DispatchLocation> unlockedLocations;
  final List<DispatchLocation> allLocations;
  final List<Monster> availableMonsters;
  final Set<String> dispatchedMonsterIds;
  final Map<String, MaterialMaster> materialMasters;

  const DispatchLoaded({
    required this.userId,
    required this.settings,
    required this.activeDispatches,
    required this.unlockedLocations,
    required this.allLocations,
    required this.availableMonsters,
    required this.dispatchedMonsterIds,
    required this.materialMasters,
  });

  @override
  List<Object?> get props => [
        userId,
        settings,
        activeDispatches,
        unlockedLocations,
        allLocations,
        availableMonsters,
        dispatchedMonsterIds,
        materialMasters,
      ];

  /// 特定の枠の探索を取得
  UserDispatch? getDispatchBySlot(int slotIndex) {
    return activeDispatches
        .where((d) => d.slotIndex == slotIndex)
        .firstOrNull;
  }

  /// 枠が使用中かどうか
  bool isSlotInUse(int slotIndex) {
    return activeDispatches.any((d) => d.slotIndex == slotIndex);
  }

  /// 枠が解放されているか
  bool isSlotUnlocked(int slotIndex) {
    return settings.isSlotUnlocked(slotIndex);
  }

  /// 探索可能なモンスター一覧（派遣中でないもの）
  List<Monster> get selectableMonsters {
    return availableMonsters
        .where((m) => !dispatchedMonsterIds.contains(m.id))
        .toList();
  }

  /// 素材マスター名取得
  String getMaterialName(String materialId) {
    return materialMasters[materialId]?.name ?? materialId;
  }

  DispatchLoaded copyWith({
    String? userId,
    UserDispatchSettings? settings,
    List<UserDispatch>? activeDispatches,
    List<DispatchLocation>? unlockedLocations,
    List<DispatchLocation>? allLocations,
    List<Monster>? availableMonsters,
    Set<String>? dispatchedMonsterIds,
    Map<String, MaterialMaster>? materialMasters,
  }) {
    return DispatchLoaded(
      userId: userId ?? this.userId,
      settings: settings ?? this.settings,
      activeDispatches: activeDispatches ?? this.activeDispatches,
      unlockedLocations: unlockedLocations ?? this.unlockedLocations,
      allLocations: allLocations ?? this.allLocations,
      availableMonsters: availableMonsters ?? this.availableMonsters,
      dispatchedMonsterIds: dispatchedMonsterIds ?? this.dispatchedMonsterIds,
      materialMasters: materialMasters ?? this.materialMasters,
    );
  }
}

/// 報酬受取結果
class DispatchRewardClaimed extends DispatchState {
  final List<DispatchRewardResult> rewards;
  final int expGained;
  final Map<String, MaterialMaster> materialMasters;

  const DispatchRewardClaimed({
    required this.rewards,
    required this.expGained,
    required this.materialMasters,
  });

  @override
  List<Object?> get props => [rewards, expGained, materialMasters];

  String getMaterialName(String materialId) {
    return materialMasters[materialId]?.name ?? materialId;
  }
}

/// エラー
class DispatchError extends DispatchState {
  final String message;

  const DispatchError(this.message);

  @override
  List<Object?> get props => [message];
}

/// 枠解放成功
class DispatchSlotUnlocked extends DispatchState {
  final int slotIndex;

  const DispatchSlotUnlocked(this.slotIndex);

  @override
  List<Object?> get props => [slotIndex];
}

/// 探索開始成功
class DispatchStarted extends DispatchState {
  final UserDispatch dispatch;

  const DispatchStarted(this.dispatch);

  @override
  List<Object?> get props => [dispatch];
}