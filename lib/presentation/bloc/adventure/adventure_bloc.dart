import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/adventure_repository.dart';
import 'adventure_event.dart';
import 'adventure_state.dart';
import '../../../domain/models/stage/stage_data.dart';

class AdventureBloc extends Bloc<AdventureEvent, AdventureState> {
  final AdventureRepository repository;

  AdventureBloc({required this.repository}) : super(const AdventureState.initial()) {
    on<LoadStages>(_onLoadStages);
    on<SelectStage>(_onSelectStage);
    on<StartAdventureBattle>(_onStartAdventureBattle);
  }

  Future<void> _onLoadStages(
    LoadStages event,
    Emitter<AdventureState> emit,
  ) async {
    emit(const AdventureState.loading());

    try {
      // 通常ステージ一覧取得
      final stages = await repository.getNormalStages();

      // 進行状況取得
      const userId = 'dev_user_12345';
      final progressMap = <String, UserAdventureProgress>{};
      
      for (final stage in stages) {
        final progress = await repository.getProgress(userId, stage.stageId);
        if (progress != null) {
          progressMap[stage.stageId] = progress;
        }
      }

      emit(AdventureState.stageList(
        stages: stages,
        progressMap: progressMap,
      ));
    } catch (e) {
      emit(AdventureState.error(message: 'ステージの読み込みに失敗しました: $e'));
    }
  }

  Future<void> _onSelectStage(
    SelectStage event,
    Emitter<AdventureState> emit,
  ) async {
    try {
      final stage = await repository.getStage(event.stageId);
      if (stage == null) {
        emit(const AdventureState.error(message: 'ステージが見つかりません'));
        return;
      }

      const userId = 'dev_user_12345';
      final progress = await repository.getProgress(userId, event.stageId);

      emit(AdventureState.stageSelected(
        stage: stage,
        progress: progress,
      ));
    } catch (e) {
      emit(AdventureState.error(message: 'ステージの選択に失敗しました: $e'));
    }
  }

  Future<void> _onStartAdventureBattle(
    StartAdventureBattle event,
    Emitter<AdventureState> emit,
  ) async {
    // バトル開始処理はBattleBlocに委譲
    // ここでは進行状況の更新のみ
    try {
      const userId = 'dev_user_12345';
      await repository.incrementEncounterCount(userId, event.stageId);
    } catch (e) {
      emit(AdventureState.error(message: 'バトル開始に失敗しました: $e'));
    }
  }
}