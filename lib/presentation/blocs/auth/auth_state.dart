part of 'auth_bloc.dart';

/// 認証状態
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// 初期状態
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// 読み込み中
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// 認証済み
class Authenticated extends AuthState {
  final String userId;

  const Authenticated(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// 未認証
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// エラー
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
