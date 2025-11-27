import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/monster.dart';

class MonsterModel {
  static Monster fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    Map<String, dynamic>? masterData,
  ) {
    final data = snapshot.data()!;
    
    final baseStats = masterData?['base_stats'] as Map<String, dynamic>? ?? {};
    final baseHp = baseStats['hp'] as int? ?? 100;
    final baseAttack = baseStats['attack'] as int? ?? 50;
    final baseDefense = baseStats['defense'] as int? ?? 50;
    final baseMagic = baseStats['magic'] as int? ?? 50;
    final baseSpeed = baseStats['speed'] as int? ?? 50;

    final monsterName = masterData?['name'] as String? ?? '不明';
    final species = (masterData?['species'] as String? ?? 'human').toLowerCase();
    
    // attributesが配列の場合と文字列の場合に対応
    final attributesData = masterData?['attributes'];
    String attributesStr;
    if (attributesData is List && attributesData.isNotEmpty) {
      attributesStr = attributesData.first.toString();
    } else if (attributesData is String) {
      attributesStr = attributesData;
    } else {
      attributesStr = 'none';
    }
    
    final element = attributesStr.split(',').first.toLowerCase();
    final rarity = masterData?['rarity'] as int? ?? 2;

    // レベル / 個体値 / 努力値 の取得
    final level = (data['level'] as int?) ?? (data['lv'] as int?) ?? 1;
    final ivHp = (data['iv_hp'] as int?) ?? 0;
    final ivAttack = (data['iv_attack'] as int?) ?? 0;
    final ivDefense = (data['iv_defense'] as int?) ?? 0;
    final ivMagic = (data['iv_magic'] as int?) ?? 0;
    final ivSpeed = (data['iv_speed'] as int?) ?? 0;
    final pointHp = (data['point_hp'] as int?) ?? 0;
    final pointAttack = (data['point_attack'] as int?) ?? 0;
    final pointDefense = (data['point_defense'] as int?) ?? 0;
    final pointMagic = (data['point_magic'] as int?) ?? 0;
    final pointSpeed = (data['point_speed'] as int?) ?? 0;

    // growth fields（互換性のため残すが、計算では使用しない）
    final growthData = masterData?['growth'] as Map<String, dynamic>? ?? {};
    final growthHpDouble = (growthData['hp'] as num?)?.toDouble() ?? 1.0;
    final growthAttackDouble = (growthData['attack'] as num?)?.toDouble() ?? 1.0;
    final growthDefenseDouble = (growthData['defense'] as num?)?.toDouble() ?? 1.0;
    final growthMagicDouble = (growthData['magic'] as num?)?.toDouble() ?? 1.0;
    final growthSpeedDouble = (growthData['speed'] as num?)?.toDouble() ?? 1.0;

    // ★ Monster.maxHp と同じ計算式を使用して最大HPを計算
    final maxHp = _calculateStat(baseHp, ivHp, pointHp, level);
    
    // current_hp が無い場合は maxHp で補完
    final storedHp = (data['current_hp'] as int?) ?? maxHp;
    
    // ★ HP自動回復計算（5分ごとに最大HPの5%回復、小数点切り上げ）
    final lastHpUpdateTime = (data['last_hp_update'] as Timestamp?)?.toDate() ?? DateTime.now();
    final currentHp = _calculateRecoveredHp(
      storedHp: storedHp,
      maxHp: maxHp,
      lastUpdate: lastHpUpdateTime,
    );

    return Monster(
      id: snapshot.id,
      userId: data['user_id'] as String? ?? '',
      monsterId: data['monster_id'] as String? ?? '',
      monsterName: monsterName,
      species: species,
      element: element,
      rarity: rarity,
      level: level,
      exp: data['exp'] as int? ?? 0,
      currentHp: currentHp,
      lastHpUpdate: lastHpUpdateTime,
      intimacyLevel: data['intimacy_level'] as int? ?? 1,
      intimacyExp: data['intimacy_exp'] as int? ?? 0,
      ivHp: ivHp,
      ivAttack: ivAttack,
      ivDefense: ivDefense,
      ivMagic: ivMagic,
      ivSpeed: ivSpeed,
      pointHp: pointHp,
      pointAttack: pointAttack,
      pointDefense: pointDefense,
      pointMagic: pointMagic,
      pointSpeed: pointSpeed,
      remainingPoints: data['remaining_points'] as int? ?? 0,
      mainTraitId: data['main_trait_id'] as String?,
      equippedSkills: _parseStringList(data['equipped_skills']),
      equippedEquipment: _parseStringList(data['equipped_equipment']),
      skinId: data['skin_id'] as int? ?? 1,
      isFavorite: data['is_favorite'] as bool? ?? false,
      isLocked: data['is_locked'] as bool? ?? false,
      acquiredAt: (data['acquired_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUsedAt: (data['last_used_at'] as Timestamp?)?.toDate(),
      baseHp: baseHp,
      baseAttack: baseAttack,
      baseDefense: baseDefense,
      baseMagic: baseMagic,
      baseSpeed: baseSpeed,
      growthHp: growthHpDouble,
      growthAttack: growthAttackDouble,
      growthDefense: growthDefenseDouble,
      growthMagic: growthMagicDouble,
      growthSpeed: growthSpeedDouble,
    );
  }

  static Map<String, dynamic> toFirestore(Monster monster) {
    return {
      'user_id': monster.userId,
      'monster_id': monster.monsterId,
      'level': monster.level,
      'exp': monster.exp,
      'current_hp': monster.currentHp,
      'last_hp_update': Timestamp.fromDate(monster.lastHpUpdate),
      'intimacy_level': monster.intimacyLevel,
      'intimacy_exp': monster.intimacyExp,
      'iv_hp': monster.ivHp,
      'iv_attack': monster.ivAttack,
      'iv_defense': monster.ivDefense,
      'iv_magic': monster.ivMagic,
      'iv_speed': monster.ivSpeed,
      'point_hp': monster.pointHp,
      'point_attack': monster.pointAttack,
      'point_defense': monster.pointDefense,
      'point_magic': monster.pointMagic,
      'point_speed': monster.pointSpeed,
      'remaining_points': monster.remainingPoints,
      'main_trait_id': monster.mainTraitId,
      'equipped_skills': monster.equippedSkills,
      'equipped_equipment': monster.equippedEquipment,
      'skin_id': monster.skinId,
      'is_favorite': monster.isFavorite,
      'is_locked': monster.isLocked,
      'acquired_at': Timestamp.fromDate(monster.acquiredAt),
      'last_used_at': monster.lastUsedAt != null ? Timestamp.fromDate(monster.lastUsedAt!) : null,
    };
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// ★ Monster.maxHp と同じ計算式
  /// 計算式: base * (1 + (level - 1) * 0.05) + iv + diminishingReturn(point)
  static int _calculateStat(int base, int iv, int allocatedPoints, int level) {
    // 基礎値 * レベル倍率（1レベルごとに+5%）
    final double baseStat = base * (1.0 + (level - 1) * 0.05);
    
    // 個体値を加算
    final double withIv = baseStat + iv;
    
    // ポイント振り分けによる追加（収穫逓減の法則）
    final double pointBonus = _calculateDiminishingReturn(allocatedPoints);
    
    return (withIv + pointBonus).round();
  }

  /// 収穫逓減の法則によるポイント計算
  static double _calculateDiminishingReturn(int points) {
    if (points <= 0) return 0.0;

    double total = 0.0;

    // 0-50: +1.0
    if (points > 0) {
      final int range1 = points.clamp(0, 50);
      total += range1 * 1.0;
    }

    // 51-100: +0.8
    if (points > 50) {
      final int range2 = (points - 50).clamp(0, 50);
      total += range2 * 0.8;
    }

    // 101-150: +0.6
    if (points > 100) {
      final int range3 = (points - 100).clamp(0, 50);
      total += range3 * 0.6;
    }

    // 151-200: +0.4
    if (points > 150) {
      final int range4 = (points - 150).clamp(0, 50);
      total += range4 * 0.4;
    }

    // 201以上: +0.2
    if (points > 200) {
      final int range5 = points - 200;
      total += range5 * 0.2;
    }

    return total;
  }

  /// ★ HP自動回復計算（5分ごとに最大HPの5%回復、小数点切り上げ）
  /// 仕様: 5分ごとに最大HPの5%回復
  static int _calculateRecoveredHp({
    required int storedHp,
    required int maxHp,
    required DateTime lastUpdate,
  }) {
    if (maxHp <= 0) return 0;
    
    final now = DateTime.now();
    final elapsedMinutes = now.difference(lastUpdate).inMinutes;
    
    // 5分ごとの回復回数
    final recoveryIntervals = elapsedMinutes ~/ 5;
    
    if (recoveryIntervals <= 0) {
      return storedHp.clamp(0, maxHp);
    }
    
    // 1回あたりの回復量 = 最大HPの5%（小数点切り上げ）
    final recoveryPerInterval = (maxHp * 0.05).ceil();
    
    // 総回復量
    final totalRecovery = recoveryIntervals * recoveryPerInterval;
    
    // 最大HPを超えない
    return (storedHp + totalRecovery).clamp(0, maxHp);
  }
}