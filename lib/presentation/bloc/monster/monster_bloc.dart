import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/monster_service.dart';
import '../../../core/models/monster_filter.dart';
import 'monster_event.dart';
import 'monster_state.dart';

/// モンスター管理BLoC
class MonsterBloc extends Bloc<MonsterEvent, MonsterState> {
  final MonsterService _monsterService;

  // 現在のフィルターとソート設定を保持
  MonsterFilter? _currentFilter;
  MonsterSortType _currentSortType = MonsterSortType.levelDesc;
  String? _currentUserId;

  MonsterBloc({
    MonsterService? monsterService,
  })  : _monsterService = monsterService ?? MonsterService(),
        super(const MonsterInitial()) {
    // イベントハンドラーの登録
    on<LoadUserMonsters>(_onLoadUserMonsters);
    on<LoadMonsterDetail>(_onLoadMonsterDetail);
    on<ToggleFavorite>(_onToggleFavorite);
    on<ToggleLock>(_onToggleLock);
    on<UpdateMonsterHp>(_onUpdateMonsterHp);
    on<HealMonster>(_onHealMonster);
    on<ApplyFilter>(_onApplyFilter);
    on<ApplySort>(_onApplySort);
    on<ClearFilter>(_onClearFilter);
    on<RefreshMonsterList>(_onRefreshMonsterList);
    on<CreateDummyMonsters>(_onCreateDummyMonsters);
    on<AllocatePoints>(_onAllocatePoints);
    on<ResetPoints>(_onResetPoints);
    on<UpdateEquippedSkills>(_onUpdateEquippedSkills);
    on<UpdateEquippedEquipment>(_onUpdateEquippedEquipment);
  }

  /// ユーザーのモンスター一覧を読み込む
  Future<void> _onLoadUserMonsters(
    LoadUserMonsters event,
    Emitter<MonsterState> emit,
  ) async {
    try {
      emit(const MonsterLoading());

      // 現在の設定を保存
      _currentUserId = event.userId;
      _currentFilter = event.filter;
      _currentSortType = event.sortType;

      // モンスター一覧を取得
      final monsters = await _monsterService.getUserMonsters(
        event.userId,
        filter: event.filter,
        sortType: event.sortType,
      );

      // 総数を取得（フィルターなし）
      final totalCount = await _monsterService.getMonsterCount(event.userId);

      emit(MonsterListLoaded(
        monsters: monsters,
        filter: event.filter,
        sortType: event.sortType,
        totalCount: totalCount,
      ));
    } catch (e) {
      emit(MonsterError(
        message: 'モンスターの読み込みに失敗しました',
        error: e,
      ));
    }
  }

  /// モンスター詳細を読み込む
  Future<void> _onLoadMonsterDetail(
    LoadMonsterDetail event,
    Emitter<MonsterState> emit,
  ) async {
    try {
      emit(const MonsterLoading());

      final monster = await _monsterService.getMonsterById(event.monsterId);

      if (monster == null) {
        emit(const MonsterError(
          message: 'モンスターが見つかりませんでした',
        ));
        return;
      }

      emit(MonsterDetailLoaded(monster));
    } catch (e) {
      emit(MonsterError(
        message: 'モンスター詳細の読み込みに失敗しました',
        error: e,
      ));
    }
  }

  // ▼ ToggleFavorite: 楽観的更新に変更（全体ロードなし）
  Future<void> _onToggleFavorite(
    ToggleFavorite event,
    Emitter<MonsterState> emit,
  ) async {
    // 1) 一覧表示中なら該当1件だけ即時更新（UIはサクッと反映）
    if (state is MonsterListLoaded) {
      final s = state as MonsterListLoaded;
      final updated = s.monsters.map((m) {
        if (m.id == event.monsterId) {
          return m.copyWith(isFavorite: event.isFavorite);
        }
        return m;
      }).toList();

      emit(MonsterListLoaded(
        monsters: updated,
        filter: s.filter,
        sortType: s.sortType,
        totalCount: s.totalCount,
      ));
    }

    // 2) 裏で保存。失敗したら当該1件のみロールバック＋エラー通知
    try {
      await _monsterService.toggleFavorite(event.monsterId, event.isFavorite);

      // 詳細などに差し替え用の最新データがあればemit（一覧はビルド抑制推奨）
      final monster = await _monsterService.getMonsterById(event.monsterId);
      if (monster != null) {
        emit(MonsterUpdated(
          monster: monster,
          message: event.isFavorite ? 'お気に入りに追加しました' : 'お気に入りを解除しました',
        ));
      }
    } catch (e) {
      if (state is MonsterListLoaded) {
        final s = state as MonsterListLoaded;
        final rolledBack = s.monsters.map((m) {
          if (m.id == event.monsterId) {
            return m.copyWith(isFavorite: !event.isFavorite);
          }
          return m;
        }).toList();

        emit(MonsterListLoaded(
          monsters: rolledBack,
          filter: s.filter,
          sortType: s.sortType,
          totalCount: s.totalCount,
        ));
      }
      emit(MonsterError(
        message: 'お気に入り状態の更新に失敗しました',
        error: e,
      ));
    }
  }

  // ▼ ToggleLock: 楽観的更新に変更（全体ロードなし）
  Future<void> _onToggleLock(
    ToggleLock event,
    Emitter<MonsterState> emit,
  ) async {
    // 1) 一覧表示中なら該当1件だけ即時更新（UIはサクッと反映）
    if (state is MonsterListLoaded) {
      final s = state as MonsterListLoaded;
      final updated = s.monsters.map((m) {
        if (m.id == event.monsterId) {
          return m.copyWith(isLocked: event.isLocked);
        }
        return m;
      }).toList();

      emit(MonsterListLoaded(
        monsters: updated,
        filter: s.filter,
        sortType: s.sortType,
        totalCount: s.totalCount,
      ));
    }

    // 2) 裏で保存。失敗したら当該1件のみロールバック＋エラー通知
    try {
      await _monsterService.toggleLock(event.monsterId, event.isLocked);

      final monster = await _monsterService.getMonsterById(event.monsterId);
      if (monster != null) {
        emit(MonsterUpdated(
          monster: monster,
          message: event.isLocked ? 'ロックしました' : 'ロックを解除しました',
        ));
      }
    } catch (e) {
      if (state is MonsterListLoaded) {
        final s = state as MonsterListLoaded;
        final rolledBack = s.monsters.map((m) {
          if (m.id == event.monsterId) {
            return m.copyWith(isLocked: !event.isLocked);
          }
          return m;
        }).toList();

        emit(MonsterListLoaded(
          monsters: rolledBack,
          filter: s.filter,
          sortType: s.sortType,
          totalCount: s.totalCount,
        ));
      }
      emit(MonsterError(
        message: 'ロック状態の更新に失敗しました',
        error: e,
      ));
    }
  }

  /// モンスターのHPを更新
  Future<void> _onUpdateMonsterHp(
    UpdateMonsterHp event,
    Emitter<MonsterState> emit,
  ) async {
    try {
      emit(MonsterHpUpdating(event.monsterId));

      await _monsterService.updateMonsterHp(event.monsterId, event.newHp);

      // モンスター詳細を再読み込み
      final monster = await _monsterService.getMonsterById(event.monsterId);

      if (monster != null) {
        emit(MonsterHpUpdated(monster));
      }
    } catch (e) {
      emit(MonsterError(
        message: 'HPの更新に失敗しました',
        error: e,
      ));
    }
  }

  /// モンスターのHPを全回復
  Future<void> _onHealMonster(
    HealMonster event,
    Emitter<MonsterState> emit,
  ) async {
    try {
      emit(MonsterHpUpdating(event.monsterId));

      await _monsterService.healMonster(event.monsterId, event.maxHp);

      // モンスター詳細を再読み込み
      final monster = await _monsterService.getMonsterById(event.monsterId);

      if (monster != null) {
        emit(MonsterUpdated(
          monster: monster,
          message: 'HPを全回復しました',
        ));

        // 一覧表示中の場合は一覧を更新（必要なら差分更新に変更可）
        if (_currentUserId != null) {
          add(RefreshMonsterList(_currentUserId!));
        }
      }
    } catch (e) {
      emit(MonsterError(
        message: 'HPの回復に失敗しました',
        error: e,
      ));
    }
  }

  /// フィルターを適用
  Future<void> _onApplyFilter(
    ApplyFilter event,
    Emitter<MonsterState> emit,
  ) async {
    if (_currentUserId == null) return;

    _currentFilter = event.filter;

    add(LoadUserMonsters(
      userId: _currentUserId!,
      filter: _currentFilter,
      sortType: _currentSortType,
    ));
  }

  /// ソートを適用
  Future<void> _onApplySort(
    ApplySort event,
    Emitter<MonsterState> emit,
  ) async {
    if (_currentUserId == null) return;

    _currentSortType = event.sortType;

    add(LoadUserMonsters(
      userId: _currentUserId!,
      filter: _currentFilter,
      sortType: _currentSortType,
    ));
  }

  /// フィルターをクリア
  Future<void> _onClearFilter(
    ClearFilter event,
    Emitter<MonsterState> emit,
  ) async {
    if (_currentUserId == null) return;

    _currentFilter = null;

    add(LoadUserMonsters(
      userId: _currentUserId!,
      filter: null,
      sortType: _currentSortType,
    ));
  }

  /// モンスター一覧をリフレッシュ
  Future<void> _onRefreshMonsterList(
    RefreshMonsterList event,
    Emitter<MonsterState> emit,
  ) async {
    add(LoadUserMonsters(
      userId: event.userId,
      filter: _currentFilter,
      sortType: _currentSortType,
    ));
  }

  /// ダミーモンスターを作成（テスト用）
  Future<void> _onCreateDummyMonsters(
    CreateDummyMonsters event,
    Emitter<MonsterState> emit,
  ) async {
    try {
      // 全体のロード画面に切り替えると UX が悪くなるため削除しました。
      // emit(const MonsterLoading());

      await _monsterService.createDummyMonsters(userId: event.userId, count: event.count);

      emit(DummyMonstersCreated(event.count));

      // 一覧を再読み込み
      add(RefreshMonsterList(event.userId));
    } catch (e) {
      emit(MonsterError(
        message: 'ダミーモンスターの作成に失敗しました',
        error: e,
      ));
    }
  }

  Future<void> _onAllocatePoints(
    AllocatePoints event,
    Emitter<MonsterState> emit,
  ) async {
    try {
      await _monsterService.allocatePoints(
        event.monsterId,
        event.statType,
        event.amount,
      );
      final monster = await _monsterService.getMonsterById(event.monsterId);
      if (monster != null) {
        emit(MonsterUpdated(monster: monster, message: 'ポイントを振り分けました'));
      }
    } catch (e) {
      emit(MonsterError(message: 'ポイント振り分けに失敗しました: $e'));
    }
  }

  Future<void> _onResetPoints(
    ResetPoints event,
    Emitter<MonsterState> emit,
  ) async {
    try {
      await _monsterService.resetPoints(event.monsterId);
      final monster = await _monsterService.getMonsterById(event.monsterId);
      if (monster != null) {
        emit(MonsterUpdated(monster: monster, message: 'ポイントをリセットしました'));
      }
    } catch (e) {
      emit(MonsterError(message: 'リセットに失敗しました: $e'));
    }
  }

  Future<void> _onUpdateEquippedSkills(
    UpdateEquippedSkills event,
    Emitter<MonsterState> emit,
  ) async {
    try {
      await _monsterService.updateEquippedSkills(event.monsterId, event.skillIds);
      final monster = await _monsterService.getMonsterById(event.monsterId);
      if (monster != null) {
        emit(MonsterUpdated(monster: monster, message: '技を更新しました'));
      }
    } catch (e) {
      emit(MonsterError(message: '技の更新に失敗しました: $e'));
    }
  }

  Future<void> _onUpdateEquippedEquipment(
    UpdateEquippedEquipment event,
    Emitter<MonsterState> emit,
  ) async {
    try {
      await _monsterService.updateEquippedEquipment(event.monsterId, event.equipmentIds);
      final monster = await _monsterService.getMonsterById(event.monsterId);
      if (monster != null) {
        emit(MonsterUpdated(monster: monster, message: '装備を更新しました'));
      }
    } catch (e) {
      emit(MonsterError(message: '装備の更新に失敗しました: $e'));
    }
  }
}
