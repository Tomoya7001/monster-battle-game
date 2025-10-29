import 'package:equatable/equatable.dart';

/// アプリ全体のイベント
abstract class AppEvent extends Equatable {
  const AppEvent();

  @override
  List<Object?> get props => [];
}

/// ローディング開始
class AppLoadingStarted extends AppEvent {
  const AppLoadingStarted();
}

/// ローディング終了
class AppLoadingEnded extends AppEvent {
  const AppLoadingEnded();
}

/// エラー表示
class AppErrorOccurred extends AppEvent {
  final String message;

  const AppErrorOccurred(this.message);

  @override
  List<Object?> get props => [message];
}

/// エラークリア
class AppErrorCleared extends AppEvent {
  const AppErrorCleared();
}