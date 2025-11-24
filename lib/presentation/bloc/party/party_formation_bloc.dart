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
      // TODO: 実際のuserIdに置き換え（Firebase Authenticationから取得）
      final userId = 'dev_user_12345';

      // プリセット取得
      final presetsSnapshot = await _firestore
          .collection('party_presets')
          .where('user_id', isEqualTo: userId)
          .where('battle_type', isEqualTo: event.battleType)
          .get();

      final presets = <PartyPreset>[];
      for (var doc in presetsSnapshot.docs) {
        try {
          final data = doc.data();
          final preset = PartyPreset.fromJson({
            ...data,
            'id': doc.id,
          });
          presets.add(preset);
        } catch (e) {
          print('プリセット読み込みエラー (${doc.id}): $e');
          // 不正なプリセットは無視して続行
          continue;
        }
      }

      // 手持ちモンスター取得（MonsterRepositoryを使用）
      // 常に最新のモンスター情報を取得（レベルアップ・装備変更を反映）
      final monsters = await _monsterRepository.getMonsters(userId);

      // アクティブなプリセット取得
      PartyPreset? activePreset;
      if (presets.isNotEmpty) {
        try {
          activePreset = presets.firstWhere((p) => p.isActive);
        } catch (e) {
          // isActiveなプリセットがない場合は最初のプリセットを使用
          activePreset = presets[0];
        }
      }

      // アクティブプリセットのモンスターを選択状態にする
      List<Monster> selectedMonsters = [];
      if (activePreset != null) {
        for (var monsterId in activePreset.monsterIds) {
          try {
            final monster = monsters.firstWhere((m) => m.id == monsterId);
            selectedMonsters.add(monster);
          } catch (e) {
            print('モンスターが見つかりません: $monsterId');
            // モンスターが見つからない場合は無視（削除された可能性）
          }
        }
      }

      emit(PartyFormationLoaded(
        presets: presets,
        allMonsters: monsters,
        currentPreset: activePreset,
        selectedMonsters: selectedMonsters,
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

    // PvPの場合、同一モンスターID（マスターID）チェック
    if (currentState.battleType == 'pvp') {
      if (selectedMonsters.any((m) => m.monsterId == event.monster.monsterId)) {
        emit(currentState.copyWith(
          errorMessage: 'PvPでは同じモンスターを複数選択できません',
        ));
        return;
      }
    }

    // 既に選択済みかチェック
    if (selectedMonsters.any((m) => m.id == event.monster.id)) {
      emit(currentState.copyWith(
        errorMessage: 'このモンスターは既に選択されています',
      ));
      return;
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

      if (event.presetId != null) {
        // 既存プリセット更新
        await _updatePreset(
          userId: userId,
          presetId: event.presetId!,
          name: event.name,
          battleType: currentState.battleType,
          monsterIds: currentState.selectedMonsters.map((m) => m.id).toList(),
          isActive: event.isActive,
        );
      } else {
        // 新規プリセット作成
        await _createPreset(
          userId: userId,
          name: event.name,
          battleType: currentState.battleType,
          monsterIds: currentState.selectedMonsters.map((m) => m.id).toList(),
          isActive: event.isActive,
        );
      }

      // 再読み込み
      add(LoadPartyPresets(battleType: currentState.battleType));
    } catch (e) {
      emit(PartyFormationError(message: 'プリセット保存エラー: $e'));
    }
  }

  /// プリセット作成
  Future<void> _createPreset({
    required String userId,
    required String name,
    required String battleType,
    required List<String> monsterIds,
    required bool isActive,
  }) async {
    // 新規作成時にisActiveがtrueの場合、他のプリセットを非アクティブに
    if (isActive) {
      await _deactivateAllPresets(userId: userId, battleType: battleType);
    }

    await _firestore.collection('party_presets').add({
      'user_id': userId,
      'name': name,
      'battle_type': battleType,
      'monster_ids': monsterIds,
      'is_active': isActive,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// プリセット更新
  Future<void> _updatePreset({
    required String userId,
    required String presetId,
    required String name,
    required String battleType,
    required List<String> monsterIds,
    required bool isActive,
  }) async {
    // 更新時にisActiveがtrueの場合、他のプリセットを非アクティブに
    if (isActive) {
      await _deactivateAllPresets(
        userId: userId,
        battleType: battleType,
        excludePresetId: presetId,
      );
    }

    await _firestore
        .collection('party_presets')
        .doc(presetId)
        .update({
      'name': name,
      'monster_ids': monsterIds,
      'is_active': isActive,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// 全プリセット非アクティブ化
  Future<void> _deactivateAllPresets({
    required String userId,
    required String battleType,
    String? excludePresetId,
  }) async {
    final presetsSnapshot = await _firestore
        .collection('party_presets')
        .where('user_id', isEqualTo: userId)
        .where('battle_type', isEqualTo: battleType)
        .get();

    final batch = _firestore.batch();
    for (var doc in presetsSnapshot.docs) {
      if (doc.id != excludePresetId) {
        batch.update(doc.reference, {'is_active': false});
      }
    }
    await batch.commit();
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

      // すべてのプリセットを非アクティブに
      await _deactivateAllPresets(
        userId: userId,
        battleType: currentState.battleType,
      );

      // 指定されたプリセットをアクティブに
      await _firestore
          .collection('party_presets')
          .doc(event.presetId)
          .update({
        'is_active': true,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // 再読み込み
      add(LoadPartyPresets(battleType: currentState.battleType));
    } catch (e) {
      emit(PartyFormationError(message: 'プリセット有効化エラー: $e'));
    }
  }
}