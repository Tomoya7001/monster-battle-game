import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/adventure/adventure_bloc.dart';
import '../../bloc/adventure/adventure_event.dart';
import '../../bloc/adventure/adventure_state.dart';
import '../../../domain/models/stage/stage_data.dart';
import '../../../domain/entities/monster.dart';
import '../../../data/repositories/adventure_repository.dart';
import '../battle/battle_screen.dart';
import 'adventure_battle_screen.dart';

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
    
    final displayCount = encounterCount.clamp(0, encountersToBoss);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ステージ情報行
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
              ],
            ),

            const SizedBox(height: 12),

            // 説明文
            if (stage.description != null) ...[
              Text(
                stage.description!,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
            ],

            // 情報チップ
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

            // ボタン行（Columnの直接の子として配置）
            if (bossUnlocked)
              // ボス解放時: 挑戦 | AUTO | ボス戦
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _startNormalBattle(context, stage),
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('挑戦'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _startAutoAdventure(context, stage),
                      icon: const Icon(Icons.repeat, size: 18),
                      label: const Text('AUTO'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _startBossBattle(context, stage),
                      icon: const Icon(Icons.shield, size: 18),
                      label: const Text('ボス戦'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              )
            else
              // ボス未解放時: 挑戦 | AUTO
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      onPressed: () => _startNormalBattle(context, stage),
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('挑戦'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _startAutoAdventure(context, stage),
                      icon: const Icon(Icons.repeat, size: 18),
                      label: const Text('AUTO'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _startNormalBattle(BuildContext context, StageData stage) {
    final availableMonsters = party.where((m) => m.currentHp > 0).toList();
    
    if (availableMonsters.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('戦闘可能なモンスターが3体以上必要です。回復してください。'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => AdventureBattleScreen(
          party: party,
          stage: stage,
        ),
      ),
    ).then((_) {
      if (context.mounted) {
        context.read<AdventureBloc>().add(const AdventureEvent.loadStages());
      }
    });
  }

  /// ★修正: ボスバトル開始（AdventureBattleScreen経由）
  void _startBossBattle(BuildContext context, StageData stage) {
    final availableMonsters = party.where((m) => m.currentHp > 0).toList();
    
    if (availableMonsters.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('戦闘可能なモンスターが3体以上必要です。回復してください。'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => AdventureBattleScreen(
          party: party,
          stage: stage,
        ),
      ),
    ).then((_) {
      if (context.mounted) {
        context.read<AdventureBloc>().add(const AdventureEvent.loadStages());
      }
    });
  }

  /// AUTO周回開始
  void _startAutoAdventure(BuildContext context, StageData stage) {
    final availableMonsters = party.where((m) => m.currentHp > 0).toList();
    
    if (availableMonsters.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('戦闘可能なモンスターが3体以上必要です。回復してください。'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // AUTO周回回数選択ダイアログ
    _showAutoLoopSelectDialog(context, stage);
  }

  void _showAutoLoopSelectDialog(BuildContext context, StageData stage) {
    int selectedCount = 5;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.repeat, color: Colors.orange),
              SizedBox(width: 8),
              Text('AUTO周回'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('周回回数を選択してください'),
              const SizedBox(height: 16),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [5, 10, 20, 50].map((count) {
                  final isSelected = selectedCount == count;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedCount = count),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.orange : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected 
                            ? Border.all(color: Colors.orange.shade700, width: 2)
                            : null,
                      ),
                      child: Text(
                        '$count回',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '・敗北時は自動で停止します\n・ボス解放時も停止します',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('キャンセル'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => AdventureBattleScreen(
                      party: party,
                      stage: stage,
                      autoLoopCount: selectedCount,
                    ),
                  ),
                ).then((_) {
                  if (context.mounted) {
                    context.read<AdventureBloc>().add(const AdventureEvent.loadStages());
                  }
                });
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('開始'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
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