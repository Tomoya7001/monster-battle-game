import 'package:freezed_annotation/freezed_annotation.dart';

part 'stage_data.freezed.dart';
part 'stage_data.g.dart';

@freezed
class StageData with _$StageData {
  const factory StageData({
    @JsonKey(name: 'stage_id') required String stageId,
    required String name,
    @JsonKey(name: 'stage_type') required String stageType,
    required int difficulty,
    @JsonKey(name: 'recommendedLevel') required int recommendedLevel,
    String? description,
    
    @JsonKey(name: 'encounter_monster_ids') List<String>? encounterMonsterIds,
    @JsonKey(name: 'encounters_to_boss') int? encountersToBoss,
    @JsonKey(name: 'boss_stage_id') String? bossStageId,
    
    @JsonKey(name: 'parent_stage_id') String? parentStageId,
    @JsonKey(name: 'boss_monster_ids') List<String>? bossMonsterIds,
    
    required StageRewards rewards,
  }) = _StageData;

  factory StageData.fromJson(Map<String, dynamic> json) =>
      _$StageDataFromJson(json);
}

@freezed
class StageRewards with _$StageRewards {
  const factory StageRewards({
    required int exp,
    required int gold,
    @Default(0) int gems,
    @JsonKey(name: 'drop_items') @Default([]) List<ItemDrop> dropItems,
  }) = _StageRewards;

  factory StageRewards.fromJson(Map<String, dynamic> json) =>
      _$StageRewardsFromJson(json);
}

@freezed
class ItemDrop with _$ItemDrop {
  const factory ItemDrop({
    @JsonKey(name: 'item_id') required String itemId,
    @JsonKey(name: 'drop_rate') required int dropRate,
  }) = _ItemDrop;

  factory ItemDrop.fromJson(Map<String, dynamic> json) =>
      _$ItemDropFromJson(json);
}

@freezed
class UserAdventureProgress with _$UserAdventureProgress {
  const factory UserAdventureProgress({
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'stage_id') required String stageId,
    @JsonKey(name: 'encounter_count') required int encounterCount,
    @JsonKey(name: 'boss_unlocked') required bool bossUnlocked,
    @JsonKey(name: 'last_updated') required DateTime lastUpdated,
  }) = _UserAdventureProgress;

  factory UserAdventureProgress.fromJson(Map<String, dynamic> json) =>
      _$UserAdventureProgressFromJson(json);
}