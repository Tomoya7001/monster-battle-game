import 'package:equatable/equatable.dart';

/// モンスターのソートタイプ
enum MonsterSortType {
  levelDesc,      // レベル降順
  levelAsc,       // レベル昇順
  rarityDesc,     // レアリティ降順
  rarityAsc,      // レアリティ昇順
  acquiredDesc,   // 取得日時（新しい順）
  acquiredAsc,    // 取得日時（古い順）
  favoriteFirst,  // お気に入り優先
  nameAsc,        // 名前昇順
  nameDesc,       // 名前降順
}

/// MonsterSortTypeの拡張
extension MonsterSortTypeExtension on MonsterSortType {
  /// 表示名を取得
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
    }
  }
}

/// モンスターフィルター
class MonsterFilter extends Equatable {
  final String? species;        // 種族フィルター
  final String? element;        // 属性フィルター
  final int? rarity;            // レアリティフィルター
  final bool? favoriteOnly;     // お気に入りのみ
  final bool? lockedOnly;       // ロック中のみ
  final String? searchKeyword;  // 検索キーワード

  const MonsterFilter({
    this.species,
    this.element,
    this.rarity,
    this.favoriteOnly,
    this.lockedOnly,
    this.searchKeyword,
  });

  @override
  List<Object?> get props => [
        species,
        element,
        rarity,
        favoriteOnly,
        lockedOnly,
        searchKeyword,
      ];

  /// フィルターがアクティブか
  bool get isActive {
    return species != null ||
        element != null ||
        rarity != null ||
        (favoriteOnly == true) ||
        (lockedOnly == true) ||
        (searchKeyword != null && searchKeyword!.isNotEmpty);
  }

  /// コピーwithクリア機能付き
  MonsterFilter copyWith({
    String? species,
    String? element,
    int? rarity,
    bool? favoriteOnly,
    bool? lockedOnly,
    String? searchKeyword,
    bool clearSpecies = false,
    bool clearElement = false,
    bool clearRarity = false,
    bool clearFavorite = false,
    bool clearLocked = false,
    bool clearKeyword = false,
  }) {
    return MonsterFilter(
      species: clearSpecies ? null : (species ?? this.species),
      element: clearElement ? null : (element ?? this.element),
      rarity: clearRarity ? null : (rarity ?? this.rarity),
      favoriteOnly: clearFavorite ? null : (favoriteOnly ?? this.favoriteOnly),
      lockedOnly: clearLocked ? null : (lockedOnly ?? this.lockedOnly),
      searchKeyword: clearKeyword ? null : (searchKeyword ?? this.searchKeyword),
    );
  }
}

/// 種族リスト
const List<String> speciesList = [
  'angel',
  'demon',
  'human',
  'spirit',
  'mechanoid',
  'dragon',
  'mutant',
];

/// 種族名マップ
const Map<String, String> speciesNameMap = {
  'angel': '天使',
  'demon': '悪魔',
  'human': '人間',
  'spirit': '精霊',
  'mechanoid': '機械',
  'dragon': 'ドラゴン',
  'mutant': '変異体',
};

/// 属性リスト
const List<String> elementList = [
  'fire',
  'water',
  'thunder',
  'wind',
  'earth',
  'light',
  'dark',
  'none',
];

/// 属性名マップ
const Map<String, String> elementNameMap = {
  'fire': '火',
  'water': '水',
  'thunder': '雷',
  'wind': '風',
  'earth': '土',
  'light': '光',
  'dark': '闇',
  'none': '無',
};

/// レアリティリスト
const List<int> rarityList = [2, 3, 4, 5];