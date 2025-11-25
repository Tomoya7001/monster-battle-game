import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/monster_service.dart';
import '../gacha/gacha_screen.dart';
import '../../bloc/gacha/gacha_bloc.dart';
import '../../bloc/gacha/gacha_event.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../../core/router/app_router.dart';
import '../monster/monster_list_screen.dart';
import '../../bloc/monster/monster_bloc.dart';
import '../battle/battle_screen.dart';
import '../battle/battle_selection_screen.dart';
import '../battle/stage_selection_screen.dart'; // ★追加

/// ホーム画面
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 現在のユーザーID取得
    final authState = context.watch<AuthBloc>().state;
    String? userId;
    if (authState is Authenticated) {
      userId = authState.userId;
    }

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // ログアウト完了時にログイン画面へ遷移
        if (state is Unauthenticated) {
          context.go(AppRouter.login);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ホーム'),
          actions: [
            // ログアウトボタン
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'ログアウト',
              onPressed: () {
                // ログアウト確認ダイアログ
                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('ログアウト'),
                    content: const Text('ログアウトしますか？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('キャンセル'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          context.read<AuthBloc>().add(const AuthLogoutRequested());
                        },
                        child: const Text('ログアウト'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'モンスター対戦ゲーム',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // ユーザーID表示
              if (userId != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'ログイン中',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'UserID: ${userId.substring(0, 8)}...',
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),
              
              // ガチャ画面へのナビゲーション
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider(
                        create: (context) => GachaBloc()..add(const InitializeGacha()),
                        child: const GachaScreen(),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.catching_pokemon),
                label: const Text('ガチャ'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider(
                        create: (context) => MonsterBloc(),
                        child: const MonsterListScreen(),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.pets),
                label: const Text('モンスター一覧'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),

              // ★追加: パーティ編成ボタン
              const SizedBox(height: 16),
              
              ElevatedButton.icon(
                onPressed: () {
                  context.push('/party-formation?battleType=pvp');
                },
                icon: const Icon(Icons.groups),
                label: const Text('パーティ編成'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor: Colors.green,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // バトルボタン
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BattleSelectionScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.sports_kabaddi),
                label: const Text('バトル'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor: Colors.red,
                ),
              ),

              const SizedBox(height: 16),
              
              // ステージ挑戦ボタン
              ElevatedButton.icon(
                onPressed: () async {
                  // パーティを取得（簡易実装）
                  final monsterService = MonsterService();
                  final monsters = await monsterService.getUserMonsters(userId ?? 'dev_user_12345');
                  
                  if (monsters.isEmpty) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('モンスターがいません。ガチャを引いてください')),
                      );
                    }
                    return;
                  }

                  // 先頭3体をパーティとして使用
                  final party = monsters.take(3).toList();

                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StageSelectionScreen(
                          playerParty: party,
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.flag),
                label: const Text('ステージ挑戦'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor: Colors.purple,
                ),
              ),

            const SizedBox(height: 16),
              
              // ★追加: マスターデータ投入ボタン
              ElevatedButton.icon(
                onPressed: () {
                  context.go('/admin/data-import');
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('マスターデータ投入'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor: Colors.orange,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}