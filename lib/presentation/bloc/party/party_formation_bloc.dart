import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/monster.dart';
import '../../../domain/repositories/monster_repository.dart';
import '../../../domain/models/party/party_preset.dart';
import '../../../data/repositories/monster_repository_impl.dart';

part 'party_formation_event.dart';
part 'party_formation_state.dart';

class PartyFormationBloc extends Bloc<PartyFormationEvent, PartyFormationState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MonsterRepository _monsterRepository;

  PartyFormationBloc()
      : _monsterRepository = MonsterRepositoryImpl(FirebaseFirestore.instance),
        super(const PartyFormationInitial()) {
    on<LoadPartyPresets>(_onLoadPartyPresets);
    on<SelectMonster>(_onSelectMonster);
    on<RemoveMonster>(_onRemoveMonster);
    on<SavePartyPreset>(_onSavePartyPreset);
    on<DeletePartyPreset>(_onDeletePartyPreset);
    on<ActivatePreset>(_onActivatePreset);
  }

  /// プリセット読み込み
  Future<void> _onLoadPartyPresets(
    LoadPartyPresets event,
    Emitter<PartyFormationState> emit,
  ) async {
    emit(const PartyFormationLoading());

    try {
      // TODO: 実際のuserIdに置き換え
      final userId = 'dev_user_12345';

      // 修正後（orderByを削除）
    final presetsSnapshot = await _firestore
        .collection('party_presets')
        .where('user_id', isEqualTo: userId)
        .where('battle_type', isEqualTo: event.battleType)
        .get();

      final presets = presetsSnapshot.docs
          .map((doc) => PartyPreset.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      // 手持ちモンスター取得（MonsterRepositoryを使用）
      final monsters = await _monsterRepository.getMonsters(userId);

      // アクティブなプリセット取得
      PartyPreset? activePreset;
      if (presets.isNotEmpty) {
        activePreset = presets.firstWhere(
          (p) => p.isActive,
          orElse: () => presets[0],
        );
      }

      emit(PartyFormationLoaded(
        presets: presets,
        allMonsters: monsters,
        currentPreset: activePreset,
        selectedMonsters: activePreset != null
            ? monsters.where((m) => activePreset!.monsterIds.contains(m.id)).toList()
            : [],
        battleType: event.battleType,
      ));
    } catch (e) {
      emit(PartyFormationError(message: 'プリセット読み込みエラー: $e'));
    }
  }

  /// モンスター選択
  Future<void> _onSelectMonster(
    SelectMonster event,
    Emitter<PartyFormationState> emit,
  ) async {
    if (state is! PartyFormationLoaded) return;

    final currentState = state as PartyFormationLoaded;
    final selectedMonsters = List<Monster>.from(currentState.selectedMonsters);

    // 最大5体チェック
    if (selectedMonsters.length >= 5) {
      emit(currentState.copyWith(
        errorMessage: '最大5体まで選択できます',
      ));
      return;
    }

    // PvPの場合、同一モンスターチェック
    if (currentState.battleType == 'pvp') {
      if (selectedMonsters.any((m) => m.monsterId == event.monster.monsterId)) {
        emit(currentState.copyWith(
          errorMessage: 'PvPでは同じモンスターを複数選択できません',
        ));
        return;
      }
    }

    // モンスター追加
    selectedMonsters.add(event.monster);

    emit(currentState.copyWith(
      selectedMonsters: selectedMonsters,
      errorMessage: null,
    ));
  }

  /// モンスター削除
  Future<void> _onRemoveMonster(
    RemoveMonster event,
    Emitter<PartyFormationState> emit,
  ) async {
    if (state is! PartyFormationLoaded) return;

    final currentState = state as PartyFormationLoaded;
    final selectedMonsters = List<Monster>.from(currentState.selectedMonsters);

    selectedMonsters.removeWhere((m) => m.id == event.monsterId);

    emit(currentState.copyWith(
      selectedMonsters: selectedMonsters,
    ));
  }

  /// プリセット保存
  Future<void> _onSavePartyPreset(
    SavePartyPreset event,
    Emitter<PartyFormationState> emit,
  ) async {
    if (state is! PartyFormationLoaded) return;

    final currentState = state as PartyFormationLoaded;

    try {
      // TODO: 実際のuserIdに置き換え
      final userId = 'dev_user_12345';

      final presetData = {
        'user_id': userId,
        'name': event.name,
        'battle_type': currentState.battleType,
        'monster_ids': currentState.selectedMonsters.map((m) => m.id).toList(),
        'is_active': event.isActive,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (event.presetId != null) {
        // 更新
        await _firestore
            .collection('party_presets')
            .doc(event.presetId)
            .update({
          ...presetData,
          'created_at': FieldValue.serverTimestamp(), // 保持
        });
      } else {
        // 新規作成
        await _firestore.collection('party_presets').add(presetData);
      }

      // 再読み込み
      add(LoadPartyPresets(battleType: currentState.battleType));
    } catch (e) {
      emit(PartyFormationError(message: 'プリセット保存エラー: $e'));
    }
  }

  /// プリセット削除
  Future<void> _onDeletePartyPreset(
    DeletePartyPreset event,
    Emitter<PartyFormationState> emit,
  ) async {
    if (state is! PartyFormationLoaded) return;

    final currentState = state as PartyFormationLoaded;

    try {
      await _firestore.collection('party_presets').doc(event.presetId).delete();

      // 再読み込み
      add(LoadPartyPresets(battleType: currentState.battleType));
    } catch (e) {
      emit(PartyFormationError(message: 'プリセット削除エラー: $e'));
    }
  }

  /// プリセット有効化
  Future<void> _onActivatePreset(
    ActivatePreset event,
    Emitter<PartyFormationState> emit,
  ) async {
    if (state is! PartyFormationLoaded) return;

    final currentState = state as PartyFormationLoaded;

    try {
      // TODO: 実際のuserIdに置き換え
      final userId = 'dev_user_12345';

      final batch = _firestore.batch();

      // すべてのプリセットを非アクティブに
      final presetsSnapshot = await _firestore
          .collection('party_presets')
          .where('user_id', isEqualTo: userId)
          .where('battle_type', isEqualTo: currentState.battleType)
          .get();

      for (var doc in presetsSnapshot.docs) {
        batch.update(doc.reference, {'is_active': false});
      }

      // 指定されたプリセットをアクティブに
      batch.update(
        _firestore.collection('party_presets').doc(event.presetId),
        {'is_active': true},
      );

      await batch.commit();

      // 再読み込み
      add(LoadPartyPresets(battleType: currentState.battleType));
    } catch (e) {
      emit(PartyFormationError(message: 'プリセット有効化エラー: $e'));
    }
  }
}