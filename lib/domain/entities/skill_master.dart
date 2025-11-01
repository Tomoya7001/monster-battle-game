import 'package:freezed_annotation/freezed_annotation.dart';

part 'skill_master.freezed.dart';
part 'skill_master.g.dart';

@freezed
class SkillMaster with _$SkillMaster {
  const factory SkillMaster({
    required String id,
    required String name,
    required String description,
    required String type, // physical, magical, buff, debuff, heal, special
    String? element, // fire, water, thunder, wind, earth, light, dark, none
    required int cost, // 1-6
    @Default(0) int power,
    @Default(100) int accuracy,
    @Default('enemy') String target,
    required Map<String, dynamic> effects,
    required List<String> learnableBy, // モンスターIDのリスト
    @Default(1) int requiredLevel,
    String? animationId,
    @Default(true) bool isActive,
    @Default(0) int displayOrder,
  }) = _SkillMaster;

  factory SkillMaster.fromJson(Map<String, dynamic> json) =>
      _$SkillMasterFromJson(json);
}