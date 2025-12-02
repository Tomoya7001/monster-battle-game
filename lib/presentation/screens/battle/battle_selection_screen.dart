import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../../data/repositories/party_preset_repository.dart';
import '../../../domain/models/party/party_preset_v2.dart';
import '../../../core/services/monster_service.dart';
import '../../../domain/entities/monster.dart';
import 'battle_screen.dart';
import 'casual_battle_screen.dart'; // ★修正: CasualBattleScreenをインポート
import '../draft/draft_selection_screen.dart';

/// バトル選択画面
class BattleSelectionScreen extends StatefulWidget {
  const BattleSelectionScreen({Key? key}) : super(key: key);

  @override
  State<BattleSelectionScreen> createState() => _BattleSelectionScreenState();
}

class _BattleSelectionScreenState extends State<BattleSelectionScreen> {
  final PartyPresetRepository _presetRepo = PartyPresetRepository();
  final MonsterService _monsterService = MonsterService();
  
  String? _selectedPresetId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    
    if (authState is! Authenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('バトル')),
        body: const Center(child: Text('ログインしてください')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('バトル選択'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // パーティ選択セクション
            _buildPartySelection(authState.userId),
            
            const SizedBox(height: 24),
            
            // ★カジュアルマッチボタン
            ElevatedButton.icon(
              onPressed: _selectedPresetId != null && !_isLoading
                  ? () => _startCasualMatch(authState.userId)
                  : null,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.sports_esports, size: 32),
              label: Text(
                _isLoading ? 'ロード中...' : 'カジュアルマッチ',
                style: const TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
              ),
            ),
            
            const SizedBox(height: 8),
            
            const Text(
              'ランク変動なし・気軽に対戦！\nLv.50固定制・最大3体使用',
              style: TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),
            
            // ★ドラフトバトルボタン
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DraftSelectionScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.shuffle, size: 28),
              label: const Text(
                'ドラフトバトル',
                style: TextStyle(fontSize: 16),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: Colors.purple,
                side: const BorderSide(color: Colors.purple, width: 2),
              ),
            ),
            
            const SizedBox(height: 8),
            
            const Text(
              '25体のモンスターから5体を選んで対戦！',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // ★PvEバトルボタン（従来のバトル開始）
            OutlinedButton.icon(
              onPressed: _selectedPresetId != null && !_isLoading
                  ? () => _startBattle(authState.userId)
                  : null,
              icon: const Icon(Icons.play_arrow, size: 28),
              label: const Text(
                'PvEバトル（ステージ）',
                style: TextStyle(fontSize: 16),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red, width: 2),
              ),
            ),
            
            const SizedBox(height: 8),
            
            const Text(
              'ステージを選んでCPUと対戦',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartySelection(String userId) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'パーティを選択',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'PvP用パーティから選択してください',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            FutureBuilder<List<PartyPresetV2>>(
              future: _presetRepo.getUserPresets(userId, 'pvp'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text('エラー: ${snapshot.error}');
                }

                final presets = snapshot.data ?? [];

                if (presets.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange, size: 32),
                        SizedBox(height: 8),
                        Text(
                          'PvP用パーティが設定されていません',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '「預かり所」タブでPvP用パーティを編成してください',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: presets.map((preset) {
                    final isSelected = _selectedPresetId == preset.id;
                    
                    return RadioListTile<String>(
                      value: preset.id,
                      groupValue: _selectedPresetId,
                      onChanged: (value) {
                        setState(() {
                          _selectedPresetId = value;
                        });
                      },
                      title: Text(
                        preset.name,
                        style: TextStyle(
                          fontWeight: isSelected 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        '${preset.monsterIds.length}体 / プリセット${preset.presetNumber}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      secondary: preset.isActive
                          ? const Icon(Icons.star, color: Colors.amber)
                          : null,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// カジュアルマッチ開始（★修正: CasualBattleScreenに直接遷移）
  Future<void> _startCasualMatch(String userId) async {
    if (_selectedPresetId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // プリセット取得
      final presets = await _presetRepo.getUserPresets(userId, 'pvp');
      final selectedPreset = presets.firstWhere(
        (p) => p.id == _selectedPresetId,
      );

      // モンスター取得
      final allMonsters = await _monsterService.getUserMonsters(userId);
      final partyMonsters = <Monster>[];

      for (final monsterId in selectedPreset.monsterIds) {
        final monster = allMonsters.firstWhere(
          (m) => m.id == monsterId,
          orElse: () => throw Exception('モンスターが見つかりません: $monsterId'),
        );
        partyMonsters.add(monster);
      }

      if (partyMonsters.length < 3) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('最低3体のモンスターが必要です')),
          );
        }
        return;
      }

      // ★修正: CasualBattleScreenへ直接遷移（ドラフトと同じ構造）
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CasualBattleScreen(playerParty: partyMonsters),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// PvEバトル開始（従来のステージバトル）
  Future<void> _startBattle(String userId) async {
    if (_selectedPresetId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // プリセット取得
      final presets = await _presetRepo.getUserPresets(userId, 'pvp');
      final selectedPreset = presets.firstWhere(
        (p) => p.id == _selectedPresetId,
      );

      // モンスター取得
      final allMonsters = await _monsterService.getUserMonsters(userId);
      final partyMonsters = <Monster>[];

      for (final monsterId in selectedPreset.monsterIds) {
        final monster = allMonsters.firstWhere(
          (m) => m.id == monsterId,
          orElse: () => throw Exception('モンスターが見つかりません: $monsterId'),
        );
        partyMonsters.add(monster);
      }

      if (partyMonsters.length < 3) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('最低3体のモンスターが必要です')),
          );
        }
        return;
      }

      // バトル画面へ遷移
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BattleScreen(playerParty: partyMonsters),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
