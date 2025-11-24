import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../../data/repositories/party_preset_repository.dart';
import '../../../domain/models/party/party_preset_v2.dart';
import '../../../core/services/monster_service.dart';
import '../../../domain/entities/monster.dart';
import 'battle_screen.dart';

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
            
            // バトル開始ボタン
            ElevatedButton.icon(
              onPressed: _selectedPresetId != null && !_isLoading
                  ? () => _startBattle(authState.userId)
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
                  : const Icon(Icons.play_arrow, size: 32),
              label: Text(
                _isLoading ? 'ロード中...' : 'バトル開始',
                style: const TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.red,
              ),
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
                  return Column(
                    children: [
                      const Text('パーティが登録されていません'),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/party-formation');
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('パーティを作成'),
                      ),
                    ],
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