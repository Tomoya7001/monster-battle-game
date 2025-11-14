import 'package:equatable/equatable.dart';

/// モンスターエンティティ
/// 
/// ユーザーが所持するモンスターの情報を保持します。
/// Firestoreの user_monsters コレクションに対応します。
class Monster extends Equatable {
  /// ユーザーモンスターID（Firestore document ID）
  final String id;

  /// ユーザーID
  final String userId;

  /// モンスターマスタID
  final String monsterId;

  /// モンスター名（monster_masters から参照）
  final String monsterName;

  /// 種族（angel, demon, human, spirit, mechanoid, dragon, mutant）
  final String species;

  /// 属性（fire, water, thunder, wind, earth, light, dark, none）
  final String element;

  /// レアリティ（2-5）
  final int rarity;

  /// レベル（1-100）
  final int level;

  /// 経験値
  final int exp;

  /// 現在HP（モンスター体力制）
  final int currentHp;

  /// 最終HP更新時刻
  final DateTime lastHpUpdate;

  /// 親密度レベル（1-10）
  final int intimacyLevel;

  /// 親密度経験値
  final int intimacyExp;

  /// 個体値HP（-10～+10）
  final int ivHp;

  /// 個体値攻撃（-10～+10）
  final int ivAttack;

  /// 個体値防御（-10～+10）
  final int ivDefense;

  /// 個体値魔力（-10～+10）
  final int ivMagic;

  /// 個体値素早さ（-10～+10）
  final int ivSpeed;

  /// 振り分けHP
  final int pointHp;

  /// 振り分け攻撃
  final int pointAttack;

  /// 振り分け防御
  final int pointDefense;

  /// 振り分け魔力
  final int pointMagic;

  /// 振り分け素早さ
  final int pointSpeed;

  /// 残りポイント
  final int remainingPoints;

  /// メイン特性ID
  final String? mainTraitId;

  /// 装備中の技（skill_id のリスト）
  final List<String> equippedSkills;

  /// 装備中の装備（equipment_id のリスト）
  final List<String> equippedEquipment;

  /// スキンID
  final int skinId;

  /// お気に入りフラグ
  final bool isFavorite;

  /// ロックフラグ（売却防止）
  final bool isLocked;

  /// 取得日時
  final DateTime acquiredAt;

  /// 最終使用日時
  final DateTime? lastUsedAt;

  /// 基礎ステータス（Lv1）
  final int baseHp;
  final int baseAttack;
  final int baseDefense;
  final int baseMagic;
  final int baseSpeed;

  /// 成長率
  final double growthHp;
  final double growthAttack;
  final double growthDefense;
  final double growthMagic;
  final double growthSpeed;

  const Monster({
    required this.id,
    required this.userId,
    required this.monsterId,
    required this.monsterName,
    required this.species,
    required this.element,
    required this.rarity,
    required this.level,
    required this.exp,
    required this.currentHp,
    required this.lastHpUpdate,
    this.intimacyLevel = 1,
    this.intimacyExp = 0,
    this.ivHp = 0,
    this.ivAttack = 0,
    this.ivDefense = 0,
    this.ivMagic = 0,
    this.ivSpeed = 0,
    this.pointHp = 0,
    this.pointAttack = 0,
    this.pointDefense = 0,
    this.pointMagic = 0,
    this.pointSpeed = 0,
    this.remainingPoints = 0,
    this.mainTraitId,
    this.equippedSkills = const [],
    this.equippedEquipment = const [],
    this.skinId = 1,
    this.isFavorite = false,
    this.isLocked = false,
    required this.acquiredAt,
    this.lastUsedAt,
    required this.baseHp,
    required this.baseAttack,
    required this.baseDefense,
    required this.baseMagic,
    required this.baseSpeed,
    this.growthHp = 1.0,
    this.growthAttack = 1.0,
    this.growthDefense = 1.0,
    this.growthMagic = 1.0,
    this.growthSpeed = 1.0,
  });

  /// 現在のレベルでの最大HP計算
  int get maxHp {
    return _calculateStat(baseHp, growthHp, ivHp, pointHp, level);
  }

  /// 現在のレベルでの攻撃力計算
  int get attack {
    return _calculateStat(baseAttack, growthAttack, ivAttack, pointAttack, level);
  }

  /// 現在のレベルでの防御力計算
  int get defense {
    return _calculateStat(baseDefense, growthDefense, ivDefense, pointDefense, level);
  }

  /// 現在のレベルでの魔力計算
  int get magic {
    return _calculateStat(baseMagic, growthMagic, ivMagic, pointMagic, level);
  }

  /// 現在のレベルでの素早さ計算
  int get speed {
    return _calculateStat(baseSpeed, growthSpeed, ivSpeed, pointSpeed, level);
  }

  /// レベル50時の最大HP（PvP用）
  int get lv50MaxHp {
    if (level < 50) return maxHp; // レベル50未満は現在の値
    return _calculateStat(baseHp, growthHp, ivHp, pointHp, 50);
  }

  /// レベル50時の攻撃力（PvP用）
  int get lv50Attack {
    if (level < 50) return attack;
    return _calculateStat(baseAttack, growthAttack, ivAttack, pointAttack, 50);
  }

  /// レベル50時の防御力（PvP用）
  int get lv50Defense {
    if (level < 50) return defense;
    return _calculateStat(baseDefense, growthDefense, ivDefense, pointDefense, 50);
  }

  /// レベル50時の魔力（PvP用）
  int get lv50Magic {
    if (level < 50) return magic;
    return _calculateStat(baseMagic, growthMagic, ivMagic, pointMagic, 50);
  }

  /// レベル50時の素早さ（PvP用）
  int get lv50Speed {
    if (level < 50) return speed;
    return _calculateStat(baseSpeed, growthSpeed, ivSpeed, pointSpeed, 50);
  }

  /// HP残量パーセンテージ
  double get hpPercentage {
    if (maxHp == 0) return 0.0;
    return (currentHp / maxHp).clamp(0.0, 1.0);
  }

  /// HP回復可能かどうか
  bool get canRecover {
    return currentHp < maxHp;
  }

  /// ステータス計算（共通処理）
  /// 
  /// 既存のFirestoreデータには成長率がないため、シンプルな計算式を使用
  /// 計算式: base * (1 + (level - 1) * 0.05) + iv + allocatedPoints * diminishingReturn
  int _calculateStat(
    int base,
    double growth, // 現在は使用しない（互換性のため残す）
    int iv,
    int allocatedPoints,
    int atLevel,
  ) {
    // 基礎値 * レベル倍率（1レベルごとに+5%）
    double baseStat = base * (1.0 + (atLevel - 1) * 0.05);

    // 個体値を加算
    double withIv = baseStat + iv;

    // ポイント振り分けによる追加（収穫逓減の法則）
    double pointBonus = _calculateDiminishingReturn(allocatedPoints);

    return (withIv + pointBonus).round();
  }

  /// 成長率計算（互換性のため残すが、現在は使用しない）
  double growthRate(double growth, int levelMinus1) {
    return 1.0; // 成長率は使用しない
  }

  /// 収穫逓減の法則によるポイント計算
  /// 
  /// 例:
  /// - 0-50ポイント: 1ポイント = +1
  /// - 51-100ポイント: 1ポイント = +0.8
  /// - 101-150ポイント: 1ポイント = +0.6
  /// - 151-200ポイント: 1ポイント = +0.4
  /// - 201ポイント以上: 1ポイント = +0.2
  double _calculateDiminishingReturn(int points) {
    if (points <= 0) return 0.0;

    double total = 0.0;

    // 0-50: +1.0
    if (points > 0) {
      int range1 = points.clamp(0, 50);
      total += range1 * 1.0;
    }

    // 51-100: +0.8
    if (points > 50) {
      int range2 = (points - 50).clamp(0, 50);
      total += range2 * 0.8;
    }

    // 101-150: +0.6
    if (points > 100) {
      int range3 = (points - 100).clamp(0, 50);
      total += range3 * 0.6;
    }

    // 151-200: +0.4
    if (points > 150) {
      int range4 = (points - 150).clamp(0, 50);
      total += range4 * 0.4;
    }

    // 201以上: +0.2
    if (points > 200) {
      int range5 = points - 200;
      total += range5 * 0.2;
    }

    return total;
  }

  /// レアリティカラー取得
  String get rarityColor {
    switch (rarity) {
      case 5:
        return '#FFD700'; // 金
      case 4:
        return '#9B59B6'; // 紫
      case 3:
        return '#3498DB'; // 青
      case 2:
      default:
        return '#95A5A6'; // 灰色
    }
  }

  /// 種族名（日本語）
  String get speciesName {
    final lowerSpecies = species.toLowerCase();
    switch (lowerSpecies) {
      case 'angel':
        return 'エンジェル';
      case 'demon':
        return 'デーモン';
      case 'human':
        return 'ヒューマン';
      case 'spirit':
        return 'スピリット';
      case 'mechanoid':
        return 'メカノイド';
      case 'dragon':
        return 'ドラゴン';
      case 'mutant':
        return 'ミュータント';
      default:
        return '不明';
    }
  }

  /// 属性名（日本語）
  String get elementName {
    final lowerElement = element.toLowerCase();
    switch (lowerElement) {
      case 'fire':
        return '炎';
      case 'water':
        return '水';
      case 'thunder':
        return '雷';
      case 'wind':
        return '風';
      case 'earth':
        return '大地';
      case 'light':
        return '光';
      case 'dark':
        return '闇';
      case 'none':
        return '無';
      default:
        return '不明';
    }
  }

  /// 属性カラー取得
  String get elementColor {
    final lowerElement = element.toLowerCase();
    switch (lowerElement) {
      case 'fire':
        return '#FF5722';
      case 'water':
        return '#2196F3';
      case 'thunder':
        return '#FFC107';
      case 'wind':
        return '#4CAF50';
      case 'earth':
        return '#795548';
      case 'light':
        return '#FFEB3B';
      case 'dark':
        return '#9C27B0';
      case 'none':
      default:
        return '#95A5A6';
    }
  }

  /// レアリティ表示（★）
  String get rarityStars {
    return '★' * rarity;
  }

  /// copyWith メソッド
  Monster copyWith({
    String? id,
    String? userId,
    String? monsterId,
    String? monsterName,
    String? species,
    String? element,
    int? rarity,
    int? level,
    int? exp,
    int? currentHp,
    DateTime? lastHpUpdate,
    int? intimacyLevel,
    int? intimacyExp,
    int? ivHp,
    int? ivAttack,
    int? ivDefense,
    int? ivMagic,
    int? ivSpeed,
    int? pointHp,
    int? pointAttack,
    int? pointDefense,
    int? pointMagic,
    int? pointSpeed,
    int? remainingPoints,
    String? mainTraitId,
    List<String>? equippedSkills,
    List<String>? equippedEquipment,
    int? skinId,
    bool? isFavorite,
    bool? isLocked,
    DateTime? acquiredAt,
    DateTime? lastUsedAt,
    int? baseHp,
    int? baseAttack,
    int? baseDefense,
    int? baseMagic,
    int? baseSpeed,
    double? growthHp,
    double? growthAttack,
    double? growthDefense,
    double? growthMagic,
    double? growthSpeed,
  }) {
    return Monster(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      monsterId: monsterId ?? this.monsterId,
      monsterName: monsterName ?? this.monsterName,
      species: species ?? this.species,
      element: element ?? this.element,
      rarity: rarity ?? this.rarity,
      level: level ?? this.level,
      exp: exp ?? this.exp,
      currentHp: currentHp ?? this.currentHp,
      lastHpUpdate: lastHpUpdate ?? this.lastHpUpdate,
      intimacyLevel: intimacyLevel ?? this.intimacyLevel,
      intimacyExp: intimacyExp ?? this.intimacyExp,
      ivHp: ivHp ?? this.ivHp,
      ivAttack: ivAttack ?? this.ivAttack,
      ivDefense: ivDefense ?? this.ivDefense,
      ivMagic: ivMagic ?? this.ivMagic,
      ivSpeed: ivSpeed ?? this.ivSpeed,
      pointHp: pointHp ?? this.pointHp,
      pointAttack: pointAttack ?? this.pointAttack,
      pointDefense: pointDefense ?? this.pointDefense,
      pointMagic: pointMagic ?? this.pointMagic,
      pointSpeed: pointSpeed ?? this.pointSpeed,
      remainingPoints: remainingPoints ?? this.remainingPoints,
      mainTraitId: mainTraitId ?? this.mainTraitId,
      equippedSkills: equippedSkills ?? this.equippedSkills,
      equippedEquipment: equippedEquipment ?? this.equippedEquipment,
      skinId: skinId ?? this.skinId,
      isFavorite: isFavorite ?? this.isFavorite,
      isLocked: isLocked ?? this.isLocked,
      acquiredAt: acquiredAt ?? this.acquiredAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      baseHp: baseHp ?? this.baseHp,
      baseAttack: baseAttack ?? this.baseAttack,
      baseDefense: baseDefense ?? this.baseDefense,
      baseMagic: baseMagic ?? this.baseMagic,
      baseSpeed: baseSpeed ?? this.baseSpeed,
      growthHp: growthHp ?? this.growthHp,
      growthAttack: growthAttack ?? this.growthAttack,
      growthDefense: growthDefense ?? this.growthDefense,
      growthMagic: growthMagic ?? this.growthMagic,
      growthSpeed: growthSpeed ?? this.growthSpeed,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        monsterId,
        monsterName,
        species,
        element,
        rarity,
        level,
        exp,
        currentHp,
        lastHpUpdate,
        intimacyLevel,
        intimacyExp,
        ivHp,
        ivAttack,
        ivDefense,
        ivMagic,
        ivSpeed,
        pointHp,
        pointAttack,
        pointDefense,
        pointMagic,
        pointSpeed,
        remainingPoints,
        mainTraitId,
        equippedSkills,
        equippedEquipment,
        skinId,
        isFavorite,
        isLocked,
        acquiredAt,
        lastUsedAt,
      ];
}