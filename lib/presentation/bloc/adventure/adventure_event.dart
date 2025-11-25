import 'package:freezed_annotation/freezed_annotation.dart';

part 'adventure_event.freezed.dart';

@freezed
class AdventureEvent with _$AdventureEvent {
  const factory AdventureEvent.loadStages() = LoadStages;
  const factory AdventureEvent.selectStage(String stageId) = SelectStage;
  const factory AdventureEvent.startAdventureBattle({
    required String stageId,
    required List<String> partyMonsterIds,
  }) = StartAdventureBattle;
}