// ============================================
// カジュアルバトル画面
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/battle/battle_bloc.dart';
import '../../bloc/battle/battle_event.dart';
import '../../bloc/battle/battle_state.dart';
import '../../widgets/battle/battle_content_widget.dart';
import '../../../domain/entities/monster.dart';
import '../../../domain/models/battle/battle_state_model.dart';
import 'battle_result_screen.dart';

/// カジュアルバトル画面（ドラフトバトルと同じ構造）
class CasualBattleScreen extends StatelessWidget {
  final List<Monster> playerParty;

  const CasualBattleScreen({
    Key? key,
    required this.playerParty,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BattleBloc()
        ..add(StartCasualBattle(playerParty: playerParty)),
      child: const _CasualBattleContent(),
    );
  }
}

class _CasualBattleContent extends StatelessWidget {
  const _CasualBattleContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カジュアルマッチ'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _showBattleMenu(context),
        ),
        actions: [
          BlocBuilder<BattleBloc, BattleState>(
            builder: (context, state) {
              if (state is BattleInProgress) {
                return IconButton(
                  icon: const Icon(Icons.list_alt),
                  onPressed: () => _showBattleLog(context, state.battleState),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<BattleBloc, BattleState>(
        listener: (context, state) {
          if (state is BattlePlayerWin && state.result != null) {
            // ★修正: pushで結果画面に遷移（pushReplacementは使えない）
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => BattleResultScreen(
                  result: state.result!,
                  stageData: null,
                ),
              ),
            );
          } else if (state is BattlePlayerLose && state.result != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => BattleResultScreen(
                  result: state.result!,
                  stageData: null,
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is BattleLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BattleError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('エラー: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('戻る'),
                  ),
                ],
              ),
            );
          }

          if (state is BattleInProgress) {
            // 共通バトルウィジェットを使用（ドラフトと同じ）
            return BattleContentWidget(
              battleState: state.battleState,
              message: state.message,
              battleType: 'casual',
            );
          }

          return const Center(child: Text('バトル準備中...'));
        },
      ),
    );
  }

  void _showBattleMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('メニュー'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.red),
              title: const Text('降参'),
              onTap: () {
                Navigator.pop(ctx);
                _confirmSurrender(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _confirmSurrender(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('降参'),
        content: const Text('本当に降参しますか？\n敗北として記録されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<BattleBloc>().add(const ForceBattleEnd());
              // ★修正: バトル画面を閉じて前の画面に戻る
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('降参する'),
          ),
        ],
      ),
    );
  }

  void _showBattleLog(BuildContext context, BattleStateModel battleState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'バトルログ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: battleState.battleLog.length,
                    itemBuilder: (context, index) {
                      final log = battleState.battleLog[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          log,
                          style: TextStyle(
                            fontSize: 14,
                            color: log.contains('クリティカル')
                                ? Colors.orange
                                : log.contains('効果抜群')
                                    ? Colors.green
                                    : log.contains('今ひとつ')
                                        ? Colors.red
                                        : Colors.black87,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
