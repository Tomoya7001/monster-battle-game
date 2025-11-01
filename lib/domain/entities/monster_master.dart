import 'package:freezed_annotation/freezed_annotation.dart';

part 'monster_master.freezed.dart';
part 'monster_master.g.dart';

@freezed
class MonsterMaster with _$MonsterMaster {
  const factory MonsterMaster({
    required String id,
    required String name,
    required String species, // angel, demon, human, spirit, mechanoid, dragon, mutant
    required String element, // fire, water, thunder, wind, earth, light, dark
    required int rarity,
    
    // 基礎ステータス
    required int baseHp,
    required int baseAttack,
    required int baseDefense,
    required int baseMagic,
    required int baseSpeed,
    
    // 成長率
    @Default(1.0) double growthHp,
    @Default(1.0) double growthAttack,
    @Default(1.0) double growthDefense,
    @Default(1.0) double growthMagic,
    @Default(1.0) double growthSpeed,
    
    // レベル50時の補正値（PvP用）
    required int lv50HpBonus,
    required int lv50AttackBonus,
    required int lv50DefenseBonus,
    required int lv50MagicBonus,
    required int lv50SpeedBonus,
    
    @Default(100) int maxLevel,
    String? defaultTraitId,
    @Default(4) int skillSlotCount, // UMAは5
    
    String? spriteId,
    String? description,
    String? obtainMethod,
    
    @Default(0) int displayOrder,
    @Default(true) bool isActive,
  }) = _MonsterMaster;

  factory MonsterMaster.fromJson(Map<String, dynamic> json) =>
      _$MonsterMasterFromJson(json);
}