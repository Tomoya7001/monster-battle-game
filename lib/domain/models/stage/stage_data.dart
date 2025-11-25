import 'package:freezed_annotation/freezed_annotation.dart';
import '../../entities/monster.dart';

part 'stage_data.freezed.dart';
part 'stage_data.g.dart';

/// ステージデータ
@freezed
class StageData with _$StageData {
  const factory StageData({
    required String id,
    required String name,
    required String description,
    required int difficulty, // 1-5
    required List<String> enemyMonsterIds,
    required int recommendedLevel,
    required StageRewards rewards,
    @Default(false) bool isBossStage,
  }) = _StageData;

  factory StageData.fromJson(Map<String, dynamic> json) =>
      _$StageDataFromJson(json);
}

/// ステージ報酬
@freezed
class StageRewards with _$StageRewards {
  const factory StageRewards({
    @Default(0) int exp,
    @Default(0) int gold,
    @Default([]) List<String> itemIds,
    @Default(0) int gems,
  }) = _StageRewards;

  factory StageRewards.fromJson(Map<String, dynamic> json) =>
      _$StageRewardsFromJson(json);
}

/// ユーザーのステージ進行状況
@freezed
class UserStageProgress with _$UserStageProgress {
  const factory UserStageProgress({
    required String userId,
    required String stageId,
    @Default(false) bool isCleared,
    @Default(0) int clearCount,
    DateTime? firstClearedAt,
    DateTime? lastClearedAt,
  }) = _UserStageProgress;

  factory UserStageProgress.fromJson(Map<String, dynamic> json) =>
      _$UserStageProgressFromJson(json);
}