import 'package:freezed_annotation/freezed_annotation.dart';

part 'skill.freezed.dart';
part 'skill.g.dart';

@freezed
class Skill with _$Skill {
  const factory Skill({
    required String id,
    required String masterId,
    required String monsterId,
    required String name,
    required String description,
    required String type, // physical, magical, buff, debuff, heal, special
    String? element, // fire, water, thunder, wind, earth, light, dark, none
    required int cost, // 1-6
    @Default(0) int power,
    @Default(100) int accuracy,
    @Default('enemy') String target, // enemy, self, all_enemies, all_allies
    required Map<String, dynamic> effects,
    required int slot, // 技スロット番号（0-3、UMAは0-4）
  }) = _Skill;

  factory Skill.fromJson(Map<String, dynamic> json) =>
      _$SkillFromJson(json);
}