import 'package:freezed_annotation/freezed_annotation.dart';

part 'equipment_master.freezed.dart';
part 'equipment_master.g.dart';

@freezed
class EquipmentMaster with _$EquipmentMaster {
  const factory EquipmentMaster({
    required String id,
    required String name,
    required String category, // weapon, armor, accessory, special
    required int rarity, // 2-5
    required Map<String, dynamic> effects, // JSON形式
    required String description,
    String? spriteId,
    String? dropLocation,
    Map<String, dynamic>? craftingRecipe,
    @Default(false) bool isUnique,
    String? requiredSpecies, // 装備可能種族（nullなら全種族）
    @Default(1) int requiredLevel,
    @Default(0) int displayOrder,
    @Default(true) bool isActive,
  }) = _EquipmentMaster;

  factory EquipmentMaster.fromJson(Map<String, dynamic> json) =>
      _$EquipmentMasterFromJson(json);
}