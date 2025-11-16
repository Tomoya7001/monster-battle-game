import 'package:equatable/equatable.dart';
import '../../../core/models/monster_filter.dart';

/// モンスター管理のイベント
abstract class MonsterEvent extends Equatable {
  const MonsterEvent();

  @override
  List<Object?> get props => [];
}

/// ユーザーのモンスター一覧を読み込む
class LoadUserMonsters extends MonsterEvent {
  final String userId;
  final MonsterFilter? filter;
  final MonsterSortType sortType;

  const LoadUserMonsters({
    required this.userId,
    this.filter,
    this.sortType = MonsterSortType.levelDesc,
  });

  @override
  List<Object?> get props => [userId, filter, sortType];
}

/// モンスター詳細を読み込む
class LoadMonsterDetail extends MonsterEvent {
  final String monsterId;

  const LoadMonsterDetail(this.monsterId);

  @override
  List<Object?> get props => [monsterId];
}

/// お気に入り状態を切り替え
class ToggleFavorite extends MonsterEvent {
  final String monsterId;
  final bool isFavorite;

  const ToggleFavorite({
    required this.monsterId,
    required this.isFavorite,
  });

  @override
  List<Object?> get props => [monsterId, isFavorite];
}

/// ロック状態を切り替え
class ToggleLock extends MonsterEvent {
  final String monsterId;
  final bool isLocked;

  const ToggleLock({
    required this.monsterId,
    required this.isLocked,
  });

  @override
  List<Object?> get props => [monsterId, isLocked];
}

/// モンスターのHPを更新
class UpdateMonsterHp extends MonsterEvent {
  final String monsterId;
  final int newHp;

  const UpdateMonsterHp({
    required this.monsterId,
    required this.newHp,
  });

  @override
  List<Object?> get props => [monsterId, newHp];
}

/// モンスターのHPを全回復
class HealMonster extends MonsterEvent {
  final String monsterId;
  final int maxHp;

  const HealMonster({
    required this.monsterId,
    required this.maxHp,
  });

  @override
  List<Object?> get props => [monsterId, maxHp];
}

/// フィルターを適用
class ApplyFilter extends MonsterEvent {
  final MonsterFilter filter;

  const ApplyFilter(this.filter);

  @override
  List<Object?> get props => [filter];
}

/// ソートを適用
class ApplySort extends MonsterEvent {
  final MonsterSortType sortType;

  const ApplySort(this.sortType);

  @override
  List<Object?> get props => [sortType];
}

/// フィルターをクリア
class ClearFilter extends MonsterEvent {
  const ClearFilter();
}

/// モンスター一覧をリフレッシュ
class RefreshMonsterList extends MonsterEvent {
  final String userId;

  const RefreshMonsterList(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// ダミーモンスターを作成（テスト用）
class CreateDummyMonsters extends MonsterEvent {
  final String userId;
  final int count;

  const CreateDummyMonsters({
    required this.userId,
    this.count = 20,
  });

  @override
  List<Object?> get props => [userId, count];
}

class AllocatePoints extends MonsterEvent {
  final String monsterId;
  final String statType; // 'hp', 'attack', 'defense', 'magic', 'speed'
  final int amount;

  const AllocatePoints({
    required this.monsterId,
    required this.statType,
    required this.amount,
  });

  @override
  List<Object?> get props => [monsterId, statType, amount];
}

class ResetPoints extends MonsterEvent {
  final String monsterId;

  const ResetPoints({required this.monsterId});

  @override
  List<Object?> get props => [monsterId];
}

class UpdateEquippedSkills extends MonsterEvent {
  final String monsterId;
  final List<String> skillIds;

  const UpdateEquippedSkills({
    required this.monsterId,
    required this.skillIds,
  });

  @override
  List<Object?> get props => [monsterId, skillIds];
}