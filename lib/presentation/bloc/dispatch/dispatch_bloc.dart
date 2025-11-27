// lib/presentation/bloc/dispatch/dispatch_bloc.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/repositories/dispatch_repository.dart';
import '../../../data/repositories/material_repository.dart';
import '../../../domain/entities/dispatch.dart';
import '../../../domain/entities/material.dart';
import '../../../domain/entities/monster.dart';
import 'dispatch_event.dart';
import 'dispatch_state.dart';

class DispatchBloc extends Bloc<DispatchEvent, DispatchState> {
  final DispatchRepository _dispatchRepository;
  final MaterialRepository _materialRepository;
  final FirebaseFirestore _firestore;

  Timer? _refreshTimer;
  String? _currentUserId;

  DispatchBloc({
    DispatchRepository? dispatchRepository,
    MaterialRepository? materialRepository,
    FirebaseFirestore? firestore,
  })  : _dispatchRepository = dispatchRepository ?? DispatchRepository(),
        _materialRepository = materialRepository ?? MaterialRepository(),
        _firestore = firestore ?? FirebaseFirestore.instance,
        super(const DispatchInitial()) {
    on<LoadDispatchData>(_onLoadDispatchData);
    on<RefreshDispatches>(_onRefreshDispatches);
    on<StartDispatch>(_onStartDispatch);
    on<ClaimDispatchReward>(_onClaimDispatchReward);
    on<UnlockDispatchSlot>(_onUnlockDispatchSlot);
    on<CancelDispatch>(_onCancelDispatch);
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    return super.close();
  }

  /// 探索データ読み込み
  Future<void> _onLoadDispatchData(
    LoadDispatchData event,
    Emitter<DispatchState> emit,
  ) async {
    emit(const DispatchLoading());

    try {
      _currentUserId = event.userId;

      // 各種データ取得
      final settings = await _dispatchRepository.getUserSettings(event.userId);
      final activeDispatches = await _dispatchRepository.getActiveDispatches(event.userId);
      final unlockedLocations = await _dispatchRepository.getUnlockedLocations(event.userId);
      final allLocations = await _dispatchRepository.getLocationMasters();
      final dispatchedMonsterIds = await _dispatchRepository.getDispatchedMonsterIds(event.userId);
      final materialMasters = await _materialRepository.getMaterialMasters();
      final availableMonsters = await _loadUserMonsters(event.userId);

      emit(DispatchLoaded(
        userId: event.userId,
        settings: settings,
        activeDispatches: activeDispatches,
        unlockedLocations: unlockedLocations,
        allLocations: allLocations.values.where((l) => l.isActive).toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder)),
        availableMonsters: availableMonsters,
        dispatchedMonsterIds: dispatchedMonsterIds,
        materialMasters: materialMasters,
      ));

      // タイマー開始（30秒ごとにリフレッシュ）
      _startRefreshTimer();
    } catch (e) {
      print('❌ 探索データ読み込みエラー: $e');
      emit(DispatchError('データの読み込みに失敗しました: $e'));
    }
  }

  /// ユーザーモンスター読み込み
  Future<List<Monster>> _loadUserMonsters(String userId) async {
    final snapshot = await _firestore
        .collection('user_monsters')
        .where('user_id', isEqualTo: userId)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Monster(
        id: doc.id,
        userId: data['user_id'] as String? ?? '',
        monsterId: data['monster_id'] as String? ?? '',
        monsterName: data['monster_name'] as String? ?? 'Unknown',
        species: data['species'] as String? ?? '',
        element: data['element'] as String? ?? '',
        rarity: data['rarity'] as int? ?? 1,
        level: data['level'] as int? ?? 1,
        exp: data['exp'] as int? ?? 0,
        currentHp: data['current_hp'] as int? ?? 100,
        lastHpUpdate: (data['last_hp_update'] as Timestamp?)?.toDate() ?? DateTime.now(),
        acquiredAt: (data['acquired_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
        baseHp: data['base_hp'] as int? ?? 100,
        baseAttack: data['base_attack'] as int? ?? 50,
        baseDefense: data['base_defense'] as int? ?? 50,
        baseMagic: data['base_magic'] as int? ?? 50,
        baseSpeed: data['base_speed'] as int? ?? 50,
      );
    }).toList().cast<Monster>()
      ..sort((a, b) => b.level.compareTo(a.level));
  }

  /// タイマー開始
  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => add(const RefreshDispatches()),
    );
  }

  /// リフレッシュ
  Future<void> _onRefreshDispatches(
    RefreshDispatches event,
    Emitter<DispatchState> emit,
  ) async {
    if (state is! DispatchLoaded || _currentUserId == null) return;

    final currentState = state as DispatchLoaded;

    try {
      final activeDispatches = await _dispatchRepository.getActiveDispatches(_currentUserId!);
      final dispatchedMonsterIds = await _dispatchRepository.getDispatchedMonsterIds(_currentUserId!);

      emit(currentState.copyWith(
        activeDispatches: activeDispatches,
        dispatchedMonsterIds: dispatchedMonsterIds,
      ));
    } catch (e) {
      print('❌ リフレッシュエラー: $e');
    }
  }

  /// 探索開始
  Future<void> _onStartDispatch(
    StartDispatch event,
    Emitter<DispatchState> emit,
  ) async {
    if (state is! DispatchLoaded) return;

    final currentState = state as DispatchLoaded;

    try {
      final dispatch = await _dispatchRepository.startDispatch(
        userId: currentState.userId,
        slotIndex: event.slotIndex,
        locationId: event.locationId,
        durationHours: event.durationHours,
        monsterIds: event.monsterIds,
      );

      if (dispatch == null) {
        emit(const DispatchError('探索の開始に失敗しました'));
        emit(currentState);
        return;
      }

      // データ再読み込み
      add(LoadDispatchData(currentState.userId));

      emit(DispatchStarted(dispatch));
    } catch (e) {
      print('❌ 探索開始エラー: $e');
      emit(DispatchError('探索の開始に失敗しました: $e'));
      emit(currentState);
    }
  }

  /// 報酬受取
  Future<void> _onClaimDispatchReward(
    ClaimDispatchReward event,
    Emitter<DispatchState> emit,
  ) async {
    if (state is! DispatchLoaded) return;

    final currentState = state as DispatchLoaded;

    try {
      // 対象の探索を取得して経験値情報を保持
      final dispatch = currentState.activeDispatches
          .where((d) => d.id == event.dispatchId)
          .firstOrNull;

      if (dispatch == null) {
        emit(const DispatchError('探索が見つかりません'));
        emit(currentState);
        return;
      }

      final location = await _dispatchRepository.getLocationMaster(dispatch.locationId);
      final option = location?.dispatchOptions
          .where((o) => o.durationHours == dispatch.durationHours)
          .firstOrNull;

      final rewards = await _dispatchRepository.claimReward(event.dispatchId);

      if (rewards == null) {
        emit(const DispatchError('報酬の受取に失敗しました'));
        emit(currentState);
        return;
      }

      final materialMasters = await _materialRepository.getMaterialMasters();

      // 報酬受取結果を表示
      emit(DispatchRewardClaimed(
        rewards: rewards,
        expGained: option?.baseExp ?? 0,
        materialMasters: materialMasters,
      ));

      // データ再読み込み
      add(LoadDispatchData(currentState.userId));
    } catch (e) {
      print('❌ 報酬受取エラー: $e');
      emit(DispatchError('報酬の受取に失敗しました: $e'));
      emit(currentState);
    }
  }

  /// 枠解放
  Future<void> _onUnlockDispatchSlot(
    UnlockDispatchSlot event,
    Emitter<DispatchState> emit,
  ) async {
    if (state is! DispatchLoaded) return;

    final currentState = state as DispatchLoaded;

    try {
      // 石の残高確認
      final userDoc = await _firestore
          .collection('users')
          .doc(currentState.userId)
          .get();

      final currentStone = userDoc.data()?['stone'] as int? ?? 0;

      if (currentStone < DispatchRepository.slotUnlockCost) {
        emit(const DispatchError('石が不足しています'));
        emit(currentState);
        return;
      }

      // 石消費
      await _firestore
          .collection('users')
          .doc(currentState.userId)
          .update({
            'stone': currentStone - DispatchRepository.slotUnlockCost,
          });

      // 枠解放
      final success = await _dispatchRepository.unlockSlot(
        currentState.userId,
        event.slotIndex,
      );

      if (!success) {
        // 石を返却
        await _firestore
            .collection('users')
            .doc(currentState.userId)
            .update({'stone': currentStone});

        emit(const DispatchError('枠の解放に失敗しました'));
        emit(currentState);
        return;
      }

      emit(DispatchSlotUnlocked(event.slotIndex));

      // データ再読み込み
      add(LoadDispatchData(currentState.userId));
    } catch (e) {
      print('❌ 枠解放エラー: $e');
      emit(DispatchError('枠の解放に失敗しました: $e'));
      emit(currentState);
    }
  }

  /// 探索キャンセル
  Future<void> _onCancelDispatch(
    CancelDispatch event,
    Emitter<DispatchState> emit,
  ) async {
    if (state is! DispatchLoaded) return;

    final currentState = state as DispatchLoaded;

    try {
      final success = await _dispatchRepository.cancelDispatch(event.dispatchId);

      if (!success) {
        emit(const DispatchError('キャンセルできません（開始から5分以上経過）'));
        emit(currentState);
        return;
      }

      // データ再読み込み
      add(LoadDispatchData(currentState.userId));
    } catch (e) {
      print('❌ キャンセルエラー: $e');
      emit(DispatchError('キャンセルに失敗しました: $e'));
      emit(currentState);
    }
  }
}