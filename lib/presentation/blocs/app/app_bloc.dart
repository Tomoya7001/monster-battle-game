import 'package:flutter_bloc/flutter_bloc.dart';
import 'app_event.dart';
import 'app_state.dart';

/// アプリ全体のBLoC
/// 
/// ローディング状態やエラー表示など、アプリ全体に関わる状態を管理
class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc() : super(const AppState()) {
    on<AppLoadingStarted>(_onLoadingStarted);
    on<AppLoadingEnded>(_onLoadingEnded);
    on<AppErrorOccurred>(_onErrorOccurred);
    on<AppErrorCleared>(_onErrorCleared);
  }

  /// ローディング開始
  void _onLoadingStarted(
    AppLoadingStarted event,
    Emitter<AppState> emit,
  ) {
    emit(state.copyWith(isLoading: true));
  }

  /// ローディング終了
  void _onLoadingEnded(
    AppLoadingEnded event,
    Emitter<AppState> emit,
  ) {
    emit(state.copyWith(isLoading: false));
  }

  /// エラー発生
  void _onErrorOccurred(
    AppErrorOccurred event,
    Emitter<AppState> emit,
  ) {
    emit(state.copyWith(
      isLoading: false,
      errorMessage: event.message,
    ));
  }

  /// エラークリア
  void _onErrorCleared(
    AppErrorCleared event,
    Emitter<AppState> emit,
  ) {
    emit(state.clearError());
  }
}