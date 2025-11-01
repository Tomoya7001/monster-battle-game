import 'package:freezed_annotation/freezed_annotation.dart';

part 'equipment.freezed.dart';
part 'equipment.g.dart';

@freezed
class Equipment with _$Equipment {
  const factory Equipment({
    required String id,
    required String masterId,
    required String userId,
    required String name,
    required int rarity, // 2-5
    required String category, // weapon, armor, accessory, special
    required Map<String, dynamic> effects, // JSON形式で柔軟に
    @Default(false) bool isLocked,
    required DateTime acquiredAt,
  }) = _Equipment;

  factory Equipment.fromJson(Map<String, dynamic> json) =>
      _$EquipmentFromJson(json);
}