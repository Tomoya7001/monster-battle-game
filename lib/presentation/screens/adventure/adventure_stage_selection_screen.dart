import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/adventure/adventure_bloc.dart';
import '../../bloc/adventure/adventure_event.dart';
import '../../bloc/adventure/adventure_state.dart';
import '../../../domain/models/stage/stage_data.dart';

class AdventureStageSelectionScreen extends StatelessWidget {
  const AdventureStageSelectionScreen({Key? key}) : super(key: key);

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
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: InkWell(
        onTap: () {
          // TODO: バトル開始処理
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${stage.name}に挑戦します')),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 難易度アイコン
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
                  
                  // タイトル
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
                        Text(
                          '進行状況: $encounterCount/$encountersToBoss',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // ボス解放バッジ
                  if (bossUnlocked)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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
                            'ボス解放',
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

              // 説明
              if (stage.description != null)
                Text(
                  stage.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),

              const SizedBox(height: 12),

              // 報酬情報
              Row(
                children: [
                  _buildInfoChip(
                    Icons.trending_up,
                    'Lv.${stage.recommendedLevel}',
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.star,
                    'EXP +${stage.rewards.exp}',
                    Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.monetization_on,
                    '${stage.rewards.gold}G',
                    Colors.amber,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 挑戦ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${stage.name}に挑戦します')),
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('挑戦する'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getDifficultyColor(stage.difficulty),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
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
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      case 5:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}