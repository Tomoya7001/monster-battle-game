import 'package:flutter_bloc/flutter_bloc.dart';

class GachaBloc extends Bloc<GachaEvent, GachaState> {
  final GachaService _gachaService;

  GachaBloc({
    required GachaService gachaService,
  })  : _gachaService = gachaService,
        super(const GachaState()) {
    on<GachaInitialize>(_onInitialize);
    on<GachaTypeChanged>(_onTypeChanged);
    on<GachaDrawSingle>(_onDrawSingle);
    on<GachaDrawMulti>(_onDrawMulti);
  }

  Future<void> _onInitialize(
    GachaInitialize event,
    Emitter<GachaState> emit,
  ) async {
    try {
      // TODO: Firestoreからユーザーの通貨情報を取得
      // TODO: 天井カウンターを取得
      
      emit(state.copyWith(
        status: GachaStatus.initial,
        freeGems: 1500, // 仮データ
        paidGems: 0,
        tickets: 5,
        pityCount: 25,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: GachaStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onTypeChanged(
    GachaTypeChanged event,
    Emitter<GachaState> emit,
  ) {
    emit(state.copyWith(
      selectedType: event.type,
    ));
  }

  Future<void> _onDrawSingle(
    GachaDrawSingle event,
    Emitter<GachaState> emit,
  ) async {
    emit(state.copyWith(status: GachaStatus.loading));

    try {
      // ガチャ実行
      final result = await _gachaService.drawSingle(userId: event.userId);
      
      // TODO: Firestoreに保存
      // TODO: 通貨を消費
      // TODO: 天井カウンターを更新

      emit(state.copyWith(
        status: GachaStatus.success,
        results: [result],
        freeGems: state.freeGems - 150, // 仮実装
        pityCount: state.pityCount + 1,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: GachaStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDrawMulti(
    GachaDrawMulti event,
    Emitter<GachaState> emit,
  ) async {
    emit(state.copyWith(status: GachaStatus.loading));

    try {
      // 10連ガチャ実行
      final results = await _gachaService.drawMulti(userId: event.userId);
      
      // TODO: Firestoreに保存
      // TODO: 通貨を消費
      // TODO: 天井カウンターを更新

      emit(state.copyWith(
        status: GachaStatus.success,
        results: results,
        freeGems: state.freeGems - 1500, // 仮実装
        pityCount: state.pityCount + 10,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: GachaStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}