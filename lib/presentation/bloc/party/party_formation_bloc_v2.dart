import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/monster_filter.dart';
import '../../../data/repositories/monster_repository_impl.dart';
import '../../../domain/entities/monster.dart';
import '../../../domain/models/party/party_preset_v2.dart';

// ========================================
// Events
// ========================================

abstract class PartyFormationEventV2 extends Equatable {
  const PartyFormationEventV2();

  @override
  List<Object?> get props => [];
}

class LoadPartyPresetsV2 extends PartyFormationEventV2 {
  final String battleType;

  const LoadPartyPresetsV2({required this.battleType});

  @override
  List<Object?> get props => [battleType];
}

class SelectPresetV2 extends PartyFormationEventV2 {
  final int presetNumber;

  const SelectPresetV2({required this.presetNumber});

  @override
  List<Object?> get props => [presetNumber];
}

class SelectMonsterV2 extends PartyFormationEventV2 {
  final Monster monster;

  const SelectMonsterV2({required this.monster});

  @override
  List<Object?> get props => [monster];
}

class RemoveMonsterV2 extends PartyFormationEventV2 {
  final String monsterId;

  const RemoveMonsterV2({required this.monsterId});

  @override
  List<Object?> get props => [monsterId];
}

class ClearSelectionV2 extends PartyFormationEventV2 {
  const ClearSelectionV2();
}

class ChangeSortTypeV2 extends PartyFormationEventV2 {
  final MonsterSortType sortType;

  const ChangeSortTypeV2({required this.sortType});

  @override
  List<Object?> get props => [sortType];
}

class ChangeFilterV2 extends PartyFormationEventV2 {
  final MonsterFilter filter;

  const ChangeFilterV2({required this.filter});

  @override
  List<Object?> get props => [filter];
}

class ChangeGridSizeV2 extends PartyFormationEventV2 {
  final int gridSize;

  const ChangeGridSizeV2({required this.gridSize});

  @override
  List<Object?> get props => [gridSize];
}

class ReorderMonstersV2 extends PartyFormationEventV2 {
  final int oldIndex;
  final int newIndex;

  const ReorderMonstersV2({
    required this.oldIndex,
    required this.newIndex,
  });

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

class SaveToFirestoreV2 extends PartyFormationEventV2 {
  const SaveToFirestoreV2();
}

// ========================================
// States
// ========================================

abstract class PartyFormationStateV2 extends Equatable {
  const PartyFormationStateV2();

  @override
  List<Object?> get props => [];
}

class PartyFormationInitialV2 extends PartyFormationStateV2 {
  const PartyFormationInitialV2();
}

class PartyFormationLoadingV2 extends PartyFormationStateV2 {
  const PartyFormationLoadingV2();
}

class PartyFormationLoadedV2 extends PartyFormationStateV2 {
  final List<Monster> allMonsters;
  final String battleType;
  
  // ローカルキャッシュ（プリセット1~5）
  final Map<int, List<Monster>> presetCache;
  final int? currentPresetNumber;
  
  // 現在選択中のモンスター
  final List<Monster> selectedMonsters;
  
  // UI設定
  final MonsterSortType sortType;
  final MonsterFilter filter;
  final int gridSize;
  
  final String? errorMessage;

  const PartyFormationLoadedV2({
    required this.allMonsters,
    required this.battleType,
    this.presetCache = const {},
    this.currentPresetNumber,
    this.selectedMonsters = const [],
    this.sortType = MonsterSortType.levelDesc,
    this.filter = const MonsterFilter(),
    this.gridSize = 4,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
        allMonsters,
        battleType,
        presetCache,
        currentPresetNumber,
        selectedMonsters,
        sortType,
        filter,
        gridSize,
        errorMessage,
      ];

  /// プリセットのモンスター数取得
  int getMonsterCountForPreset(int presetNumber) {
    return presetCache[presetNumber]?.length ?? 0;
  }

  PartyFormationLoadedV2 copyWith({
    List<Monster>? allMonsters,
    String? battleType,
    Map<int, List<Monster>>? presetCache,
    int? currentPresetNumber,
    bool clearPresetNumber = false,
    List<Monster>? selectedMonsters,
    MonsterSortType? sortType,
    MonsterFilter? filter,
    int? gridSize,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PartyFormationLoadedV2(
      allMonsters: allMonsters ?? this.allMonsters,
      battleType: battleType ?? this.battleType,
      presetCache: presetCache ?? this.presetCache,
      currentPresetNumber: clearPresetNumber
          ? null
          : (currentPresetNumber ?? this.currentPresetNumber),
      selectedMonsters: selectedMonsters ?? this.selectedMonsters,
      sortType: sortType ?? this.sortType,
      filter: filter ?? this.filter,
      gridSize: gridSize ?? this.gridSize,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class PartyFormationErrorV2 extends PartyFormationStateV2 {
  final String message;

  const PartyFormationErrorV2({required this.message});

  @override
  List<Object?> get props => [message];
}

// ========================================
// BLoC
// ========================================

class PartyFormationBlocV2 extends Bloc<PartyFormationEventV2, PartyFormationStateV2> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final MonsterRepositoryImpl _monsterRepository;

  PartyFormationBlocV2() : super(const PartyFormationInitialV2()) {
    _monsterRepository = MonsterRepositoryImpl(_firestore);
    
    on<LoadPartyPresetsV2>(_onLoadPartyPresets);
    on<SelectPresetV2>(_onSelectPreset);
    on<SelectMonsterV2>(_onSelectMonster);
    on<RemoveMonsterV2>(_onRemoveMonster);
    on<ClearSelectionV2>(_onClearSelection);
    on<ChangeSortTypeV2>(_onChangeSortType);
    on<ChangeFilterV2>(_onChangeFilter);
    on<ChangeGridSizeV2>(_onChangeGridSize);
    on<ReorderMonstersV2>(_onReorderMonsters);
    on<SaveToFirestoreV2>(_onSaveToFirestore);
  }

  Future<void> _onLoadPartyPresets(
    LoadPartyPresetsV2 event,
    Emitter<PartyFormationStateV2> emit,
  ) async {
    emit(const PartyFormationLoadingV2());

    try {
      final userId = 'dev_user_12345'; // TODO: 実際のuserIdに置き換え

      // 全モンスター取得
      final monsters = await _monsterRepository.getMonsters(userId);

      // Firestoreからプリセットデータ取得
      final presetsSnapshot = await _firestore
          .collection('party_presets')
          .where('user_id', isEqualTo: userId)
          .where('battle_type', isEqualTo: event.battleType)
          .get();

      // ローカルキャッシュ構築
      final Map<int, List<Monster>> presetCache = {};
      int? activePresetNumber;

      for (var doc in presetsSnapshot.docs) {
        final data = doc.data();
        final presetNumber = data['preset_number'] as int;
        final monsterIds = List<String>.from(data['monster_ids'] ?? []);
        final isActive = data['is_active'] as bool? ?? false;

        if (isActive) {
          activePresetNumber = presetNumber;
        }

        // モンスターID配列からMonsterオブジェクトリスト作成
        final presetMonsters = monsters
            .where((m) => monsterIds.contains(m.id))
            .toList();

        presetCache[presetNumber] = presetMonsters;
      }

      // アクティブプリセットがない場合、プリセット1を自動選択
      if (activePresetNumber == null && presetCache.isNotEmpty) {
        activePresetNumber = 1;
      }

      final List<Monster> selectedMonsters =
          activePresetNumber != null ? (presetCache[activePresetNumber] ?? []) : [];

      emit(PartyFormationLoadedV2(
        allMonsters: monsters,
        battleType: event.battleType,
        presetCache: presetCache,
        currentPresetNumber: activePresetNumber,
        selectedMonsters: selectedMonsters,
      ));
    } catch (e) {
      emit(PartyFormationErrorV2(message: 'データ読み込みエラー: $e'));
    }
  }

  Future<void> _onSelectPreset(
    SelectPresetV2 event,
    Emitter<PartyFormationStateV2> emit,
  ) async {
    if (state is! PartyFormationLoadedV2) return;

    final currentState = state as PartyFormationLoadedV2;

    // 現在の選択をキャッシュに保存
    if (currentState.currentPresetNumber != null) {
      final updatedCache = Map<int, List<Monster>>.from(currentState.presetCache);
      updatedCache[currentState.currentPresetNumber!] = currentState.selectedMonsters;

      // 選択プリセット切り替え
      final newSelectedMonsters = updatedCache[event.presetNumber] ?? [];

      emit(currentState.copyWith(
        presetCache: updatedCache,
        currentPresetNumber: event.presetNumber,
        selectedMonsters: newSelectedMonsters,
      ));
    } else {
      // 初回プリセット選択
      final newSelectedMonsters = currentState.presetCache[event.presetNumber] ?? [];

      emit(currentState.copyWith(
        currentPresetNumber: event.presetNumber,
        selectedMonsters: newSelectedMonsters,
      ));
    }

    // Firestoreに非同期保存
    add(const SaveToFirestoreV2());
  }

  Future<void> _onSelectMonster(
    SelectMonsterV2 event,
    Emitter<PartyFormationStateV2> emit,
  ) async {
    if (state is! PartyFormationLoadedV2) return;

    final currentState = state as PartyFormationLoadedV2;
    final selectedMonsters = List<Monster>.from(currentState.selectedMonsters);

    // 選択数チェック
    if (selectedMonsters.length >= 5) {
      emit(currentState.copyWith(errorMessage: '最大5体まで選択できます'));
      return;
    }

    // PvP用重複チェック
    if (currentState.battleType == 'pvp') {
      if (selectedMonsters.any((m) => m.monsterId == event.monster.monsterId)) {
        emit(currentState.copyWith(
            errorMessage: 'PvPでは同じモンスターを複数選択できません'));
        return;
      }
    }

    // 既選択チェック
    if (selectedMonsters.any((m) => m.id == event.monster.id)) {
      emit(currentState.copyWith(
          errorMessage: 'このモンスターは既に選択されています'));
      return;
    }

    selectedMonsters.add(event.monster);

    // キャッシュ更新
    final updatedCache = Map<int, List<Monster>>.from(currentState.presetCache);
    if (currentState.currentPresetNumber != null) {
      updatedCache[currentState.currentPresetNumber!] = selectedMonsters;
    }

    emit(currentState.copyWith(
      selectedMonsters: selectedMonsters,
      presetCache: updatedCache,
      clearError: true,
    ));

    // Firestoreに非同期保存
    add(const SaveToFirestoreV2());
  }

  Future<void> _onRemoveMonster(
    RemoveMonsterV2 event,
    Emitter<PartyFormationStateV2> emit,
  ) async {
    if (state is! PartyFormationLoadedV2) return;

    final currentState = state as PartyFormationLoadedV2;
    final selectedMonsters = List<Monster>.from(currentState.selectedMonsters);

    selectedMonsters.removeWhere((m) => m.id == event.monsterId);

    // キャッシュ更新
    final updatedCache = Map<int, List<Monster>>.from(currentState.presetCache);
    if (currentState.currentPresetNumber != null) {
      updatedCache[currentState.currentPresetNumber!] = selectedMonsters;
    }

    emit(currentState.copyWith(
      selectedMonsters: selectedMonsters,
      presetCache: updatedCache,
    ));

    // Firestoreに非同期保存
    add(const SaveToFirestoreV2());
  }

  Future<void> _onClearSelection(
    ClearSelectionV2 event,
    Emitter<PartyFormationStateV2> emit,
  ) async {
    if (state is! PartyFormationLoadedV2) return;

    final currentState = state as PartyFormationLoadedV2;

    // キャッシュ更新
    final updatedCache = Map<int, List<Monster>>.from(currentState.presetCache);
    if (currentState.currentPresetNumber != null) {
      updatedCache[currentState.currentPresetNumber!] = [];
    }

    emit(currentState.copyWith(
      selectedMonsters: [],
      presetCache: updatedCache,
    ));

    // Firestoreに非同期保存
    add(const SaveToFirestoreV2());
  }

  Future<void> _onChangeSortType(
    ChangeSortTypeV2 event,
    Emitter<PartyFormationStateV2> emit,
  ) async {
    if (state is! PartyFormationLoadedV2) return;

    final currentState = state as PartyFormationLoadedV2;
    emit(currentState.copyWith(sortType: event.sortType));
  }

  Future<void> _onChangeFilter(
    ChangeFilterV2 event,
    Emitter<PartyFormationStateV2> emit,
  ) async {
    if (state is! PartyFormationLoadedV2) return;

    final currentState = state as PartyFormationLoadedV2;
    emit(currentState.copyWith(filter: event.filter));
  }

  Future<void> _onChangeGridSize(
    ChangeGridSizeV2 event,
    Emitter<PartyFormationStateV2> emit,
  ) async {
    if (state is! PartyFormationLoadedV2) return;

    final currentState = state as PartyFormationLoadedV2;
    emit(currentState.copyWith(gridSize: event.gridSize));
  }

  Future<void> _onReorderMonsters(
    ReorderMonstersV2 event,
    Emitter<PartyFormationStateV2> emit,
  ) async {
    if (state is! PartyFormationLoadedV2) return;

    final currentState = state as PartyFormationLoadedV2;
    final selectedMonsters = List<Monster>.from(currentState.selectedMonsters);

    // ReorderableListViewは実際の要素数で処理するため、
    // 空スロット含めた5個ではなく、実際の選択数でインデックス調整
    if (event.oldIndex >= selectedMonsters.length ||
        event.newIndex > selectedMonsters.length) {
      return;
    }

    // 並び替え処理
    int newIndex = event.newIndex;
    if (event.oldIndex < newIndex) {
      newIndex -= 1;
    }

    final monster = selectedMonsters.removeAt(event.oldIndex);
    selectedMonsters.insert(newIndex, monster);

    // キャッシュ更新
    final updatedCache = Map<int, List<Monster>>.from(currentState.presetCache);
    if (currentState.currentPresetNumber != null) {
      updatedCache[currentState.currentPresetNumber!] = selectedMonsters;
    }

    emit(currentState.copyWith(
      selectedMonsters: selectedMonsters,
      presetCache: updatedCache,
    ));

    // Firestoreに非同期保存
    add(const SaveToFirestoreV2());
  }

  Future<void> _onSaveToFirestore(
    SaveToFirestoreV2 event,
    Emitter<PartyFormationStateV2> emit,
  ) async {
    if (state is! PartyFormationLoadedV2) return;

    final currentState = state as PartyFormationLoadedV2;

    if (currentState.currentPresetNumber == null) return;

    try {
      final userId = 'dev_user_12345'; // TODO: 実際のuserIdに置き換え
      final presetNumber = currentState.currentPresetNumber!;
      final monsterIds =
          currentState.selectedMonsters.map((m) => m.id).toList();

      // 既存プリセット検索
      final existingSnapshot = await _firestore
          .collection('party_presets')
          .where('user_id', isEqualTo: userId)
          .where('battle_type', isEqualTo: currentState.battleType)
          .where('preset_number', isEqualTo: presetNumber)
          .get();

      final presetData = {
        'user_id': userId,
        'name': 'デッキ$presetNumber',
        'battle_type': currentState.battleType,
        'preset_number': presetNumber,
        'monster_ids': monsterIds,
        'is_active': true,
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (existingSnapshot.docs.isNotEmpty) {
        // 更新
        await _firestore
            .collection('party_presets')
            .doc(existingSnapshot.docs.first.id)
            .update(presetData);
      } else {
        // 新規作成
        await _firestore.collection('party_presets').add({
          ...presetData,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      // 他のプリセットを非アクティブに
      await _deactivateOtherPresets(
        userId: userId,
        battleType: currentState.battleType,
        presetNumber: presetNumber,
      );
    } catch (e) {
      // エラーは無視（バックグラウンド保存のため）
      print('Firestore保存エラー: $e');
    }
  }

  Future<void> _deactivateOtherPresets({
    required String userId,
    required String battleType,
    required int presetNumber,
  }) async {
    final snapshot = await _firestore
        .collection('party_presets')
        .where('user_id', isEqualTo: userId)
        .where('battle_type', isEqualTo: battleType)
        .get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['preset_number'] != presetNumber) {
        batch.update(doc.reference, {'is_active': false});
      }
    }
    await batch.commit();
  }
}