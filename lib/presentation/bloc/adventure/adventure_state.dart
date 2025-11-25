import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../domain/models/stage/stage_data.dart';

part 'adventure_state.freezed.dart';

@freezed
class AdventureState with _$AdventureState {
  const factory AdventureState.initial() = AdventureInitial;
  const factory AdventureState.loading() = AdventureLoading;
  const factory AdventureState.stageList({
    required List<StageData> stages,
    required Map<String, UserAdventureProgress> progressMap,
  }) = AdventureStageList;
  const factory AdventureState.stageSelected({
    required StageData stage,
    UserAdventureProgress? progress,
  }) = AdventureStageSelected;
  const factory AdventureState.error({required String message}) = AdventureError;
}