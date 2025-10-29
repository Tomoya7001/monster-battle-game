import 'package:equatable/equatable.dart';

/// アプリ全体の状態
class AppState extends Equatable {
  final bool isLoading;
  final String? errorMessage;

  const AppState({
    this.isLoading = false,
    this.errorMessage,
  });

  /// 状態をコピーして一部を変更
  AppState copyWith({
    bool? isLoading,
    String? errorMessage,
  }) {
    return AppState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// エラーをクリア
  AppState clearError() {
    return AppState(
      isLoading: isLoading,
      errorMessage: null,
    );
  }

  @override
  List<Object?> get props => [isLoading, errorMessage];
}