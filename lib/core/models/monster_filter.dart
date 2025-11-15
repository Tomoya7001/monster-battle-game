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
  bool get isActive {
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
    bool clearKeyword = false,
  }) {
    return MonsterFilter(
      species: species ?? this.species,
      element: element ?? this.element,
      rarity: rarity ?? this.rarity,
      favoriteOnly: favoriteOnly ?? this.favoriteOnly,
      lockedOnly: lockedOnly ?? this.lockedOnly,
      searchKeyword: clearKeyword ? null : (searchKeyword ?? this.searchKeyword),
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
  levelDesc,
  levelAsc,
  rarityDesc,
  rarityAsc,
  acquiredDesc,
  acquiredAsc,
  favoriteFirst,
  nameAsc,
  nameDesc,
  hpDesc,
  hpAsc,
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
      case MonsterSortType.acquiredDesc:
        return '取得日時（新しい順）';
      case MonsterSortType.acquiredAsc:
        return '取得日時（古い順）';
      case MonsterSortType.favoriteFirst:
        return 'お気に入り優先';
      case MonsterSortType.nameAsc:
        return '名前（昇順）';
      case MonsterSortType.nameDesc:
        return '名前（降順）';
      case MonsterSortType.hpDesc:
        return 'HP（高い順）';
      case MonsterSortType.hpAsc:
        return 'HP（低い順）';
    }
  }
}