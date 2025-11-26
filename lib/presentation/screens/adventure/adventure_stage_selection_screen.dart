import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/adventure/adventure_bloc.dart';
import '../../bloc/adventure/adventure_event.dart';
import '../../bloc/adventure/adventure_state.dart';
import '../../../domain/models/stage/stage_data.dart';
import '../../../domain/entities/monster.dart';
import '../../../data/repositories/adventure_repository.dart';
import '../battle/battle_screen.dart';

class AdventureStageSelectionScreen extends StatelessWidget {
  final List<Monster> party;

  const AdventureStageSelectionScreen({
    Key? key,
    required this.party,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('冒険'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AdventureBloc>().add(const AdventureEvent.loadStages());
            },
          ),
        ],
      ),
      body: BlocBuilder<AdventureBloc, AdventureState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: Text('初期化中...')),
            loading: () => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('ステージを読み込んでいます...'),
                ],
              ),
            ),
            stageList: (stages, progressMap) {
              if (stages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.info_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('ステージがありません'),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<AdventureBloc>().add(
                            const AdventureEvent.loadStages(),
                          );
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('再読み込み'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: stages.length,
                itemBuilder: (context, index) {
                  final stage = stages[index];
                  final progress = progressMap[stage.stageId];
                  return _buildStageCard(context, stage, progress);
                },
              );
            },
            stageSelected: (stage, progress) => const Center(
              child: Text('ステージ選択済み'),
            ),
            error: (message) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<AdventureBloc>().add(
                        const AdventureEvent.loadStages(),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('再試行'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStageCard(
    BuildContext context,
    StageData stage,
    UserAdventureProgress? progress,
  ) {
    final encounterCount = progress?.encounterCount ?? 0;
    final bossUnlocked = progress?.bossUnlocked ?? false;
    final encountersToBoss = stage.encountersToBoss ?? 5;
    
    // ★修正: 表示用のカウント（maxを超えない）
    final displayCount = encounterCount.clamp(0, encountersToBoss);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(stage.difficulty),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${stage.difficulty}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // ★修正: 進行状況バー
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: displayCount / encountersToBoss,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  bossUnlocked ? Colors.purple : Colors.blue,
                                ),
                                minHeight: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$displayCount/$encountersToBoss',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: bossUnlocked ? Colors.purple : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                if (bossUnlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'BOSS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            if (stage.description != null)
              Text(
                stage.description!,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),

            const SizedBox(height: 12),

            Row(
              children: [
                _buildInfoChip(Icons.trending_up, 'Lv.${stage.recommendedLevel}', Colors.blue),
                const SizedBox(width: 8),
                _buildInfoChip(Icons.star, 'EXP +${stage.rewards.exp}', Colors.orange),
                const SizedBox(width: 8),
                _buildInfoChip(Icons.monetization_on, '${stage.rewards.gold}G', Colors.amber),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _startNormalBattle(context, stage),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('挑戦'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                
                if (bossUnlocked) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _startBossBattle(context, stage),
                      icon: const Icon(Icons.shield),
                      label: const Text('ボス戦'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _startNormalBattle(BuildContext context, StageData stage) {
    // ★HPチェック: 戦えるモンスターがいるか確認
    final availableMonsters = party.where((m) => m.currentHp > 0).toList();
    
    if (availableMonsters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('戦えるモンスターがいません。回復アイテムを使用してください。'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => BattleScreen(
          playerParty: party,
          stageData: stage,
        ),
      ),
    ).then((_) {
      // バトル終了後にステージリストをリロード
      if (context.mounted) {
        context.read<AdventureBloc>().add(const AdventureEvent.loadStages());
      }
    });
  }

  /// ★実装: ボスバトル開始
  void _startBossBattle(BuildContext context, StageData stage) async {
    // ★HPチェック: 戦えるモンスターがいるか確認
    final availableMonsters = party.where((m) => m.currentHp > 0).toList();
    
    if (availableMonsters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('戦えるモンスターがいません。回復アイテムを使用してください。'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final bossStageId = stage.bossStageId;
    if (bossStageId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ボスステージが設定されていません')),
      );
      return;
    }

    // ローディング表示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // ボスステージデータを取得
      final adventureRepo = AdventureRepository();
      final bossStage = await adventureRepo.getStage(bossStageId);
      
      if (context.mounted) {
        Navigator.pop(context); // ローディング閉じる
      }

      if (bossStage == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ボスステージの取得に失敗しました')),
          );
        }
        return;
      }

      // ボスバトル画面へ遷移
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => BattleScreen(
              playerParty: party,
              stageData: bossStage,
            ),
          ),
        ).then((_) {
          // バトル終了後にステージリストをリロード
          if (context.mounted) {
            context.read<AdventureBloc>().add(const AdventureEvent.loadStages());
          }
        });
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // ローディング閉じる
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1: return Colors.green;
      case 2: return Colors.orange;
      case 3: return Colors.red;
      case 4: return Colors.purple;
      case 5: return Colors.black;
      default: return Colors.grey;
    }
  }
}