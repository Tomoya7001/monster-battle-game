import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';

/// サインアップ（新規登録）画面
/// 
/// Google/Apple Sign Inでの新規アカウント作成を提供
/// 現在は仮実装（Week 2で本実装予定）
class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRouter.login),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ロゴ
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.pets,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),

              // タイトル
              Text(
                '新規登録',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // サブタイトル
              Text(
                '新しいアカウントを作成してゲームを始めよう',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Google Sign Up ボタン
              _SignUpButton(
                icon: Icons.g_mobiledata_rounded,
                label: 'Googleで登録',
                backgroundColor: Colors.white,
                textColor: Colors.black87,
                onPressed: () {
                  // TODO: Week 2で実装
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Google Sign Upは Week 2 で実装予定です'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  
                  // 仮の遷移（開発確認用）
                  Future.delayed(const Duration(seconds: 1), () {
                    if (context.mounted) {
                      context.go(AppRouter.home);
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Apple Sign Up ボタン
              _SignUpButton(
                icon: Icons.apple,
                label: 'Appleで登録',
                backgroundColor: Colors.black,
                textColor: Colors.white,
                onPressed: () {
                  // TODO: Week 2で実装
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Apple Sign Upは Week 2 で実装予定です'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // 利用規約・プライバシーポリシー
              Text(
                '登録することで、利用規約とプライバシーポリシーに同意したものとみなされます',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // 区切り線
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'または',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 32),

              // ログインへのリンク
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'すでにアカウントをお持ちですか？',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () {
                      context.go(AppRouter.login);
                    },
                    child: const Text('ログイン'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// サインアップボタンウィジェット
class _SignUpButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onPressed;

  const _SignUpButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: backgroundColor == Colors.white
              ? const BorderSide(color: Colors.grey, width: 0.5)
              : BorderSide.none,
        ),
        elevation: 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}