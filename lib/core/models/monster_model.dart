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
    final pointHp = (data['point_hp'] as int?) ?? 0;

    // マスターに growth 情報があれば取得（なければ 0）
    final growthData = masterData?['growth'] as Map<String, dynamic>? ?? {};
    final growthHpInt = (growthData['hp'] as num?)?.toInt()
        ?? (masterData?['growthHp'] as num?)?.toInt()
        ?? 0;
    // growth fields を double で Monster に渡す（既存コードに合わせる）
    final growthHpDouble = growthHpInt.toDouble() == 0.0 ? 1.0 : growthHpInt.toDouble();
    final growthAttackDouble = (growthData['attack'] as num?)?.toDouble() ?? 1.0;
    final growthDefenseDouble = (growthData['defense'] as num?)?.toDouble() ?? 1.0;
    final growthMagicDouble = (growthData['magic'] as num?)?.toDouble() ?? 1.0;
    final growthSpeedDouble = (growthData['speed'] as num?)?.toDouble() ?? 1.0;

    // レベルボーナス（簡易）
    final lvBonus = (level > 1) ? growthHpInt * (level - 1) : 0;

    // current_hp が無い場合は、baseHp + ivHp + pointHp + lvBonus で補完
    final storedHp = (data['current_hp'] as int?) ??
        (baseHp + ivHp + pointHp + lvBonus);
    
    // 最大HP計算（簡易版）
    final calculatedMaxHp = baseHp + ivHp + pointHp + lvBonus;
    
    // HP自動回復計算（5分ごとに+5）
    final lastHpUpdateTime = (data['last_hp_update'] as Timestamp?)?.toDate() ?? DateTime.now();
    final currentHp = _calculateRecoveredHp(
      storedHp: storedHp,
      maxHp: calculatedMaxHp,
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
      lastHpUpdate: (data['last_hp_update'] as Timestamp?)?.toDate() ?? DateTime.now(),
      intimacyLevel: data['intimacy_level'] as int? ?? 1,
      intimacyExp: data['intimacy_exp'] as int? ?? 0,
      ivHp: ivHp,
      ivAttack: data['iv_attack'] as int? ?? 0,
      ivDefense: data['iv_defense'] as int? ?? 0,
      ivMagic: data['iv_magic'] as int? ?? 0,
      ivSpeed: data['iv_speed'] as int? ?? 0,
      pointHp: pointHp,
      pointAttack: data['point_attack'] as int? ?? 0,
      pointDefense: data['point_defense'] as int? ?? 0,
      pointMagic: data['point_magic'] as int? ?? 0,
      pointSpeed: data['point_speed'] as int? ?? 0,
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

  /// HP自動回復計算（5分ごとに+5、瀕死からも回復）
  static int _calculateRecoveredHp({
    required int storedHp,
    required int maxHp,
    required DateTime lastUpdate,
  }) {
    final now = DateTime.now();
    final elapsedMinutes = now.difference(lastUpdate).inMinutes;
    
    // 5分ごとに+5回復
    final recoveryIntervals = elapsedMinutes ~/ 5;
    final recoveredAmount = recoveryIntervals * 5;
    
    // 最大HPを超えない、最低0
    return (storedHp + recoveredAmount).clamp(0, maxHp);
  }
}
