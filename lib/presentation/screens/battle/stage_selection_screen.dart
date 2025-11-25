import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/models/stage/stage_data.dart';
import '../../../domain/entities/monster.dart';
import 'battle_screen.dart';

class StageSelectionScreen extends StatefulWidget {
  final List<Monster> playerParty;

  const StageSelectionScreen({
    Key? key,
    required this.playerParty,
  }) : super(key: key);

  @override
  State<StageSelectionScreen> createState() => _StageSelectionScreenState();
}

class _StageSelectionScreenState extends State<StageSelectionScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<StageData> _stages = [];
  Map<String, UserAdventureProgress> _progressMap = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStages();
  }

  Future<void> _loadStages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // ★修正: stage_typeフィルタリング追加
      final stagesSnapshot = await _firestore
          .collection('stage_masters')
          .where('stage_type', isEqualTo: 'normal') // 通常ステージのみ
          .orderBy('difficulty')
          .get()
          .timeout(const Duration(seconds: 10));

      final stages = stagesSnapshot.docs
          .map((doc) {
            final data = doc.data();
            return StageData.fromJson({
              ...data,
              'stageId': data['stage_id'] ?? doc.id, // ★修正
            });
          })
          .toList();

      // ★修正: 進行状況コレクション名変更
      const userId = 'dev_user_12345';
      final progressSnapshot = await _firestore
          .collection('user_adventure_progress') // ★変更
          .where('userId', isEqualTo: userId) // ★フィールド名変更
          .get()
          .timeout(const Duration(seconds: 10));

      final progressMap = <String, UserAdventureProgress>{};
      for (final doc in progressSnapshot.docs) {
        final data = doc.data();
        final progress = UserAdventureProgress(
        userId: data['userId'] as String,
        stageId: data['stageId'] as String,
        encounterCount: data['encounterCount'] as int? ?? 0,
        bossUnlocked: data['bossUnlocked'] as bool? ?? false,
        lastUpdated: data['lastUpdated'] != null
            ? (data['lastUpdated'] as Timestamp).toDate()
            : DateTime.now(),
        );
        progressMap[progress.stageId] = progress;
      }

      setState(() {
        _stages = stages;
        _progressMap = progressMap;
        _isLoading = false;
      });
    } on TimeoutException {
      setState(() {
        _errorMessage = '読み込みがタイムアウトしました';
        _isLoading = false;
      });
    } on FirebaseException catch (e) {
      setState(() {
        _errorMessage = 'データの読み込みに失敗しました: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'エラーが発生しました: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ステージ選択'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStages,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('ステージ情報を読み込んでいます...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
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
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadStages,
              icon: const Icon(Icons.refresh),
              label: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    if (_stages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.info_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text('ステージがありません'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadStages,
              icon: const Icon(Icons.refresh),
              label: const Text('再読み込み'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _stages.length,
      itemBuilder: (context, index) {
        final stage = _stages[index];
        final progress = _progressMap[stage.stageId];
        return _buildStageCard(stage, progress);
      },
    );
  }

  Widget _buildStageCard(StageData stage, UserAdventureProgress? progress) {
    final bossUnlocked = progress?.bossUnlocked ?? false;
    final encounterCount = progress?.encounterCount ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: InkWell(
        onTap: () => _startBattle(stage),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              Row(
                children: [
                  // ステージアイコン
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(stage.difficulty),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: stage.stageType == 'boss'
                          ? const Icon(Icons.shield, color: Colors.white, size: 28)
                          : Text(
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
                  
                  // タイトルとクリア状態
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
                            if (bossUnlocked) ...[
                              const Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'ボス解放済み ($encounterCount/5)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ] else ...[
                              const Icon(
                                Icons.lock,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '未クリア',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // 難易度星
                  _buildDifficultyStars(stage.difficulty),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              // 説明
              Text(
                stage.description ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 12),

              // 推奨レベルと報酬
              Row(
                children: [
                  // 推奨レベル
                  _buildInfoChip(
                    Icons.trending_up,
                    '推奨Lv.${stage.recommendedLevel}',
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  
                  // 経験値報酬
                  _buildInfoChip(
                    Icons.star,
                    'EXP +${stage.rewards.exp}',
                    Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  
                  // ゴールド報酬
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
                  onPressed: () => _startBattle(stage),
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

  Widget _buildDifficultyStars(int difficulty) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < difficulty ? Icons.star : Icons.star_border,
          size: 16,
          color: Colors.amber,
        );
      }),
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

  void _startBattle(StageData stage) {
    // パーティチェック
    if (widget.playerParty.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('パーティが編成されていません')),
      );
      return;
    }

    // 推奨レベルチェック（警告のみ）
    final avgLevel = widget.playerParty
        .map((m) => m.level)
        .reduce((a, b) => a + b) / widget.playerParty.length;
    
    if (avgLevel < stage.recommendedLevel) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('警告'),
          content: Text(
            'パーティの平均レベルが推奨レベル(Lv.${stage.recommendedLevel})より低いです。\n'
            '現在の平均レベル: Lv.${avgLevel.round()}\n\n'
            'それでも挑戦しますか？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _navigateToBattle(stage);
              },
              child: const Text('挑戦する'),
            ),
          ],
        ),
      );
    } else {
      _navigateToBattle(stage);
    }
  }

  void _navigateToBattle(StageData stage) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BattleScreen(
          playerParty: widget.playerParty,
          stageData: stage,
        ),
      ),
    );
  }
}