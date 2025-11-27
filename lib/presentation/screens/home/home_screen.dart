import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import '../../../data/repositories/party_preset_repository.dart';
import '../../../domain/entities/monster.dart';
import '../item/item_screen.dart';
import '../../bloc/item/item_bloc.dart';
import '../../bloc/item/item_event.dart';
import '../../../data/repositories/monster_repository_impl.dart';


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
              
              // 冒険ボタン
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final partyRepo = PartyPresetRepository();
                    
                    // アクティブなプリセット取得
                    final preset = await partyRepo.getActivePreset(
                      'dev_user_12345',
                      'adventure',
                    );

                    if (preset == null || preset.monsterIds.isEmpty) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('冒険用パーティを編成してください'),
                            action: SnackBarAction(
                              label: '編成',
                              onPressed: () {
                                context.push('/party-formation?battleType=adventure');
                              },
                            ),
                          ),
                        );
                      }
                      return;
                    }

                    // ★修正: MonsterRepositoryImplを使用してモンスター取得
                    // （MonsterModel.fromFirestoreで時間ベース回復が適用される）
                    final firestore = FirebaseFirestore.instance;
                    final monsterRepo = MonsterRepositoryImpl(firestore);
                    final adventureParty = await monsterRepo.getMonstersByIds(preset.monsterIds);

                    if (adventureParty.isEmpty) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('パーティのモンスターが見つかりません')),
                        );
                      }
                      return;
                    }

                    // ★追加: HP0のモンスターがいないかチェック
                    final availableMonsters = adventureParty.where((m) => m.currentHp > 0).toList();
                    if (availableMonsters.isEmpty) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('戦えるモンスターがいません。回復してください。'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      return;
                    }

                    if (context.mounted) {
                      context.push('/adventure', extra: adventureParty);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('エラー: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.explore),
                label: const Text('冒険'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor: Colors.purple,
                ),
              ),
              
              const SizedBox(height: 16),

              // 探索ボタン追加
              ElevatedButton.icon(
                onPressed: () => context.push('/dispatch'),
                icon: const Icon(Icons.explore),
                label: const Text('探索'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.all(16),
                ),
              ),

              const SizedBox(height: 16),
              
              // アイテムボタン
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider(
                        create: (context) => ItemBloc()
                          ..add(LoadItems(userId: userId ?? 'dev_user_12345')),
                        child: ItemScreen(userId: userId ?? 'dev_user_12345'),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.inventory_2),
                label: const Text('アイテム'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor: Colors.teal,
                ),
              ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: () {
                context.push('/crafting');
              },
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('錬成'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                backgroundColor: Colors.orange,
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