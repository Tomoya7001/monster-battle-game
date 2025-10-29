import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// 認証BLoC
/// 
/// アプリケーション全体の認証状態を管理
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthLoginSuccess>(_onAuthLoginSuccess);
  }

  /// 認証状態チェック
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      // TODO: Week 2で実装
      // Firebase Auth の状態をチェック
      // final user = FirebaseAuth.instance.currentUser;
      
      // 仮の実装：常に未認証とする
      await Future.delayed(const Duration(milliseconds: 500));
      emit(const Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// ログアウト処理
  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      // TODO: Week 2で実装
      // await FirebaseAuth.instance.signOut();
      
      // 仮の実装
      await Future.delayed(const Duration(milliseconds: 300));
      emit(const Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// ログイン成功
  Future<void> _onAuthLoginSuccess(
    AuthLoginSuccess event,
    Emitter<AuthState> emit,
  ) async {
    emit(Authenticated(event.userId));
  }
}