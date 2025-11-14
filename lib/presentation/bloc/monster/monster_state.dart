import 'package:equatable/equatable.dart';
import '../../../domain/entities/monster.dart';
import '../../../core/models/monster_filter.dart';

/// モンスター管理のステート
abstract class MonsterState extends Equatable {
  const MonsterState();

  @override
  List<Object?> get props => [];
}

/// 初期状態
class MonsterInitial extends MonsterState {
  const MonsterInitial();
}

/// 読み込み中
class MonsterLoading extends MonsterState {
  const MonsterLoading();
}

/// モンスター一覧読み込み成功
class MonsterListLoaded extends MonsterState {
  final List<Monster> monsters;
  final MonsterFilter? filter;
  final MonsterSortType sortType;
  final int totalCount;

  const MonsterListLoaded({
    required this.monsters,
    this.filter,
    required this.sortType,
    required this.totalCount,
  });

  @override
  List<Object?> get props => [monsters, filter, sortType, totalCount];

  /// フィルターがアクティブか
  bool get hasActiveFilter => filter?.isActive ?? false;

  /// copyWith
  MonsterListLoaded copyWith({
    List<Monster>? monsters,
    MonsterFilter? filter,
    MonsterSortType? sortType,
    int? totalCount,
    bool clearFilter = false,
  }) {
    return MonsterListLoaded(
      monsters: monsters ?? this.monsters,
      filter: clearFilter ? null : (filter ?? this.filter),
      sortType: sortType ?? this.sortType,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

/// モンスター詳細読み込み成功
class MonsterDetailLoaded extends MonsterState {
  final Monster monster;

  const MonsterDetailLoaded(this.monster);

  @override
  List<Object?> get props => [monster];
}

/// モンスター更新成功
class MonsterUpdated extends MonsterState {
  final Monster monster;
  final String message;

  const MonsterUpdated({
    required this.monster,
    this.message = '更新しました',
  });

  @override
  List<Object?> get props => [monster, message];
}

/// ダミーモンスター作成成功
class DummyMonstersCreated extends MonsterState {
  final int count;

  const DummyMonstersCreated(this.count);

  @override
  List<Object?> get props => [count];
}

/// エラー状態
class MonsterError extends MonsterState {
  final String message;
  final Object? error;

  const MonsterError({
    required this.message,
    this.error,
  });

  @override
  List<Object?> get props => [message, error];
}

/// HP更新中
class MonsterHpUpdating extends MonsterState {
  final String monsterId;

  const MonsterHpUpdating(this.monsterId);

  @override
  List<Object?> get props => [monsterId];
}

/// HP更新成功
class MonsterHpUpdated extends MonsterState {
  final Monster monster;

  const MonsterHpUpdated(this.monster);

  @override
  List<Object?> get props => [monster];
}