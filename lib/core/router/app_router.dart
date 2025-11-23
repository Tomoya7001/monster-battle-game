import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../presentation/screens/admin/data_import_screen.dart';

import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/signup_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/test/firestore_test_screen.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';

/// アプリケーション全体のルーティング設定
class AppRouter {
  /// ルートパス定義
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String test = '/test';  // 🔥 追加
  static const String dataImport = '/admin/data-import';

  /// GoRouterインスタンス
  static final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: AppRouter.splash,  // 🔥 テスト用に一時変更（後で splash に戻す）
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

      // ★追加: マスターデータ投入画面
      GoRoute(
        path: dataImport,
        name: 'data-import',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const DataImportScreen(),
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
      // デバッグ用：認証状態を出力
      final authState = context.read<AuthBloc>().state;
      print('🔍 現在の認証状態: $authState');
      print('🔍 現在のパス: ${state.matchedLocation}');
      
      // redirectは使わない（splash_screen.dartのBlocListenerで処理）
      return null;
    },
  );
}