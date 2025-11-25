import 'package:freezed_annotation/freezed_annotation.dart';

part 'battle_result.freezed.dart';
part 'battle_result.g.dart';

/// バトル結果
@freezed
class BattleResult with _$BattleResult {
  const factory BattleResult({
    required bool isWin,
    required int turnCount,
    required List<String> usedMonsterIds,
    required BattleRewards rewards,
    required List<MonsterExpGain> expGains,
    DateTime? completedAt,
  }) = _BattleResult;

  factory BattleResult.fromJson(Map<String, dynamic> json) =>
      _$BattleResultFromJson(json);
}

/// バトル報酬
@freezed
class BattleRewards with _$BattleRewards {
  const factory BattleRewards({
    @Default(0) int exp,
    @Default(0) int gold,
    @Default([]) List<DropItem> items,
    @Default(0) int gems,
  }) = _BattleRewards;

  factory BattleRewards.fromJson(Map<String, dynamic> json) =>
      _$BattleRewardsFromJson(json);
}

/// ドロップアイテム
@freezed
class DropItem with _$DropItem {
  const factory DropItem({
    required String itemId,
    required String itemName,
    @Default(1) int quantity,
  }) = _DropItem;

  factory DropItem.fromJson(Map<String, dynamic> json) =>
      _$DropItemFromJson(json);
}

/// モンスター経験値獲得
@freezed
class MonsterExpGain with _$MonsterExpGain {
  const factory MonsterExpGain({
    required String monsterId,
    required String monsterName,
    required int gainedExp,
    required int levelBefore,
    required int levelAfter,
    @Default(false) bool didLevelUp,
  }) = _MonsterExpGain;

  factory MonsterExpGain.fromJson(Map<String, dynamic> json) =>
      _$MonsterExpGainFromJson(json);
}