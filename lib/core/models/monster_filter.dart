// lib/core/models/monster_filter.dart

/// モンスターフィルター
class MonsterFilter {
  final String? species;
  final String? element;
  final int? rarity;
  final bool favoriteOnly;
  final bool lockedOnly;
  final String? searchKeyword;

  const MonsterFilter({
    this.species,
    this.element,
    this.rarity,
    this.favoriteOnly = false,
    this.lockedOnly = false,
    this.searchKeyword,
  });

  /// フィルターが適用されているかどうか
  bool get hasActiveFilters {
    return species != null ||
        element != null ||
        rarity != null ||
        favoriteOnly ||
        lockedOnly ||
        (searchKeyword?.isNotEmpty == true);
  }

  /// フィルターをコピーして新しいインスタンスを作成
  MonsterFilter copyWith({
    String? species,
    String? element,
    int? rarity,
    bool? favoriteOnly,
    bool? lockedOnly,
    String? searchKeyword,
  }) {
    return MonsterFilter(
      species: species ?? this.species,
      element: element ?? this.element,
      rarity: rarity ?? this.rarity,
      favoriteOnly: favoriteOnly ?? this.favoriteOnly,
      lockedOnly: lockedOnly ?? this.lockedOnly,
      searchKeyword: searchKeyword ?? this.searchKeyword,
    );
  }

  /// フィルターをクリア
  MonsterFilter clear() {
    return const MonsterFilter();
  }

  @override
  String toString() {
    return 'MonsterFilter(species: $species, element: $element, rarity: $rarity, favoriteOnly: $favoriteOnly, lockedOnly: $lockedOnly, searchKeyword: $searchKeyword)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MonsterFilter &&
        other.species == species &&
        other.element == element &&
        other.rarity == rarity &&
        other.favoriteOnly == favoriteOnly &&
        other.lockedOnly == lockedOnly &&
        other.searchKeyword == searchKeyword;
  }

  @override
  int get hashCode {
    return Object.hash(
      species,
      element,
      rarity,
      favoriteOnly,
      lockedOnly,
      searchKeyword,
    );
  }
}

/// ソートタイプ
enum MonsterSortType {
  levelDesc, // レベル降順
  levelAsc, // レベル昇順
  rarityDesc, // レアリティ降順
  rarityAsc, // レアリティ昇順
  nameAsc, // 名前昇順
  nameDesc, // 名前降順
  acquiredDesc, // 取得日降順（新しい順）
  acquiredAsc, // 取得日昇順（古い順）
  hpDesc, // HP降順
  hpAsc, // HP昇順
}

/// ソートタイプの表示名
extension MonsterSortTypeExtension on MonsterSortType {
  String get displayName {
    switch (this) {
      case MonsterSortType.levelDesc:
        return 'レベル（高い順）';
      case MonsterSortType.levelAsc:
        return 'レベル（低い順）';
      case MonsterSortType.rarityDesc:
        return 'レアリティ（高い順）';
      case MonsterSortType.rarityAsc:
        return 'レアリティ（低い順）';
      case MonsterSortType.nameAsc:
        return '名前（A-Z）';
      case MonsterSortType.nameDesc:
        return '名前（Z-A）';
      case MonsterSortType.acquiredDesc:
        return '取得日（新しい順）';
      case MonsterSortType.acquiredAsc:
        return '取得日（古い順）';
      case MonsterSortType.hpDesc:
        return 'HP（高い順）';
      case MonsterSortType.hpAsc:
        return 'HP（低い順）';
    }
  }
}