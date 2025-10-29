import 'package:equatable/equatable.dart';

/// 認証関連のイベント
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// 認証状態チェック要求
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// ログアウト要求
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// ログイン成功
class AuthLoginSuccess extends AuthEvent {
  final String userId;

  const AuthLoginSuccess(this.userId);

  @override
  List<Object?> get props => [userId];
}
