import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../data/repositories/user_repository_impl.dart';
import '../../../domain/entities/app_user.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// 認証BLoC
/// 
/// アプリケーション全体の認証状態を管理
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  StreamSubscription<User?>? _authStateSubscription;

  AuthBloc({
    AuthRepository? authRepository,
    UserRepository? userRepository,
  })  : _authRepository = authRepository ?? AuthRepositoryImpl(),
        _userRepository = userRepository ?? UserRepositoryImpl(),
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthLoginSuccess>(_onAuthLoginSuccess);

    // 認証状態の監視
    _authStateSubscription = _authRepository.authStateChanges.listen(
      (user) {
        if (user != null) {
          add(const AuthCheckRequested());
        }
        // else は不要（AuthCheckRequestedが適切に処理する）
      },
    );
  }

  /// 認証状態チェック
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = _authRepository.currentUser;
      if (user != null) {
        emit(Authenticated(user.uid));
      } else {
        emit(const Unauthenticated());
      }
    } catch (e) {
      emit(const AuthError('認証状態の確認に失敗しました'));
    }
  }

  /// Googleログイン処理（新規追加）
  Future<void> _onGoogleSignInRequested(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      // Google認証
      final firebaseUser = await _authRepository.signInWithGoogle();

      // ユーザーがキャンセルした場合
      if (firebaseUser == null) {
        emit(const Unauthenticated());
        return;
      }

      // ユーザーデータ確認
      AppUser? user = await _userRepository.getUser(firebaseUser.uid);

      // 初回ログイン時、ユーザー作成
      if (user == null) {
        user = AppUser(
          id: firebaseUser.uid,
          displayName: firebaseUser.displayName ?? 'プレイヤー',
          photoUrl: firebaseUser.photoURL,
          stone: 1000, // 初回ボーナス
          coin: 10000, // 初回ボーナス
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        await _userRepository.createUser(user);
        print('新規ユーザー作成: ${user.id}');
      } else {
        // 最終ログイン日時更新
        user = user.copyWith(lastLoginAt: DateTime.now());
        await _userRepository.updateUser(user);
        print('既存ユーザーログイン: ${user.id}');
      }

      emit(Authenticated(firebaseUser.uid));
    } catch (e) {
      print('Login Error: $e');
      emit(AuthError('ログインに失敗しました: $e'));
    }
  }

  /// ログアウト処理
  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await _authRepository.signOut();
      emit(const Unauthenticated());
    } catch (e) {
      emit(const AuthError('ログアウトに失敗しました'));
    }
  }

  /// ログイン成功
  Future<void> _onAuthLoginSuccess(
    AuthLoginSuccess event,
    Emitter<AuthState> emit,
  ) async {
    emit(Authenticated(event.userId));
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}