import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums.dart';

part 'monster.freezed.dart';
part 'monster.g.dart';

@freezed
class Monster with _$Monster {
  const factory Monster({
    required String id,
    required String masterId,
    required String userId,
    required String name,
    required int level,
    required int exp,
    
    // 種族と属性（文字列で保存、enumで扱う）
    required String species, // angel, demon, human, spirit, mechanoid, dragon, mutant
    required String element, // fire, water, thunder, wind, earth, light, dark
    
    required int rarity, // 2-5
    
    // 現在のステータス
    required int hp,
    required int maxHp,
    required int attack,
    required int defense,
    required int magic,
    required int speed,
    
    // 個体値（±0~10）
    @Default(0) int ivHp,
    @Default(0) int ivAttack,
    @Default(0) int ivDefense,
    @Default(0) int ivMagic,
    @Default(0) int ivSpeed,
    
    // ポイント振り分け
    @Default(0) int pointHp,
    @Default(0) int pointAttack,
    @Default(0) int pointDefense,
    @Default(0) int pointMagic,
    @Default(0) int pointSpeed,
    @Default(0) int remainingPoints,
    
    // 技・特性・装備
    required List<String> skillIds,
    required String mainAbilityId,
    String? subAbilityId,
    required List<String> equipmentIds,
    
    // メタ情報
    required DateTime acquiredAt,
    DateTime? lastBattleAt,
    @Default(false) bool inParty,
    int? partySlot,
    @Default(false) bool isFavorite,
    @Default(false) bool isLocked,
  }) = _Monster;

  factory Monster.fromJson(Map<String, dynamic> json) =>
      _$MonsterFromJson(json);
}

// 便利なgetterを追加
extension MonsterExtension on Monster {
  // 種族をenumで取得
  MonsterSpecies get speciesEnum =>
      MonsterSpeciesExtension.fromString(species);
  
  // 属性をenumで取得
  MonsterElement get elementEnum =>
      MonsterElementExtension.fromString(element);
}