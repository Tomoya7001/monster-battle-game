import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/signup_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/test/firestore_test_screen.dart';  // 🔥 追加

/// アプリケーション全体のルーティング設定
class AppRouter {
  /// ルートパス定義
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String test = '/test';  // 🔥 追加

  /// GoRouterインスタンス
  static final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: test,  // 🔥 テスト用に一時変更（後で splash に戻す）
    routes: [
      // スプラッシュ画面
      GoRoute(
        path: splash,
        name: 'splash',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SplashScreen(),
        ),
      ),

      // ログイン画面
      GoRoute(
        path: login,
        name: 'login',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),

      // サインアップ画面
      GoRoute(
        path: signup,
        name: 'signup',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SignupScreen(),
        ),
      ),

      // ホーム画面
      GoRoute(
        path: home,
        name: 'home',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const HomeScreen(),
        ),
      ),

      // 🔥 Firestoreテスト画面（追加）
      GoRoute(
        path: test,
        name: 'test',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const FirestoreTestScreen(),
        ),
      ),
    ],

    // エラーページ
    errorPageBuilder: (context, state) => MaterialPage(
      key: state.pageKey,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'ページが見つかりません',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                state.error?.toString() ?? '',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go(splash),
                child: const Text('トップに戻る'),
              ),
            ],
          ),
        ),
      ),
    ),

    // 画面遷移時のリダイレクト処理
    redirect: (context, state) {
      // TODO: 認証状態に応じたリダイレクト処理を実装
      // 例: 未認証の場合はログイン画面へ、認証済みの場合はホーム画面へ
      return null; // nullを返すと、リダイレクトなしで元のパスへ遷移
    },
  );
}