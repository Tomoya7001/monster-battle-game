import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/party/party_formation_bloc.dart';
import '../../../domain/entities/monster.dart';

class PartyFormationScreen extends StatelessWidget {
  final String battleType; // 'pvp' or 'adventure'

  const PartyFormationScreen({
    Key? key,
    required this.battleType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PartyFormationBloc()
        ..add(LoadPartyPresets(battleType: battleType)),
      child: Scaffold(
        appBar: AppBar(
          title: Text(battleType == 'pvp' ? 'PvPパーティ編成' : '冒険パーティ編成'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<PartyFormationBloc>().add(
                  LoadPartyPresets(battleType: battleType),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () => _showSaveDialog(context),
            ),
            IconButton(
              icon: const Icon(Icons.list),
              onPressed: () => _showPresetsDialog(context),
            ),
          ],
        ),
        body: BlocConsumer<PartyFormationBloc, PartyFormationState>(
          listener: (context, state) {
            if (state is PartyFormationError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
            if (state is PartyFormationLoaded && state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!)),
              );
            }
          },
          builder: (context, state) {
            if (state is PartyFormationLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is PartyFormationLoaded) {
              return _buildLoadedContent(context, state);
            }

            return const Center(child: Text('エラーが発生しました'));
          },
        ),
      ),
    );
  }

  Widget _buildLoadedContent(BuildContext context, PartyFormationLoaded state) {
    return Column(
      children: [
        // 選択中のモンスター表示エリア
        _buildSelectedMonsters(context, state),
        
        const Divider(height: 1),
        
        // 手持ちモンスター一覧
        Expanded(
          child: _buildMonsterList(context, state),
        ),
        
        // バトル開始ボタン
        _buildBottomBar(context, state),
      ],
    );
  }

  /// 選択中のモンスター表示
  Widget _buildSelectedMonsters(BuildContext context, PartyFormationLoaded state) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '選択中 (${state.selectedMonsters.length}/5)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (state.currentPreset != null)
                Text(
                  '${state.currentPreset!.name}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[700],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                if (index < state.selectedMonsters.length) {
                  final monster = state.selectedMonsters[index];
                  return _buildSelectedMonsterCard(context, monster, state.battleType);
                } else {
                  return _buildEmptySlot(context);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 選択中のモンスターカード
  Widget _buildSelectedMonsterCard(
    BuildContext context,
    Monster monster,
    String battleType,
  ) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Card(
        child: InkWell(
          onTap: () {
            context.read<PartyFormationBloc>().add(RemoveMonster(monsterId: monster.id));
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // モンスター名（完全表示）
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  monster.monsterName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              // レベル
              Text(
                'Lv${monster.level}',
                style: const TextStyle(fontSize: 10),
              ),
              // HP表示
              Text(
                'HP: ${monster.currentHp}/${_calculateMaxHp(monster)}',
                style: const TextStyle(fontSize: 9),
              ),
              // 種族・属性
              Text(
                '種族: ${monster.species}',
                style: const TextStyle(fontSize: 9),
              ),
              Text(
                '属性: ${monster.element}',
                style: const TextStyle(fontSize: 9),
              ),
              // 装備数表示
              if (monster.equippedEquipment.isNotEmpty)
                Text(
                  '⚔️ ${monster.equippedEquipment.length}個',
                  style: const TextStyle(fontSize: 9),
                ),
              const SizedBox(height: 4),
              // 削除ボタン
              const Icon(Icons.remove_circle, color: Colors.red, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// 空きスロット
  Widget _buildEmptySlot(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Card(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.add, size: 40, color: Colors.grey),
        ),
      ),
    );
  }

  /// 手持ちモンスター一覧
  Widget _buildMonsterList(BuildContext context, PartyFormationLoaded state) {
    if (state.allMonsters.isEmpty) {
      return const Center(child: Text('モンスターがいません'));
    }

    return ListView.builder(
      itemCount: state.allMonsters.length,
      itemBuilder: (context, index) {
        final monster = state.allMonsters[index];
        final isSelected = state.selectedMonsters.any((m) => m.id == monster.id);
        final canSelect = !isSelected && state.selectedMonsters.length < 5;

        // PvPの場合、同じmonsterIdが選択されていないかチェック
        final isDuplicate = state.battleType == 'pvp' &&
            state.selectedMonsters.any((m) => m.monsterId == monster.monsterId);

        return _buildMonsterListTile(
          context,
          monster,
          isSelected: isSelected,
          canSelect: canSelect && !isDuplicate,
          onTap: () {
            if (isSelected) {
              context.read<PartyFormationBloc>().add(RemoveMonster(monsterId: monster.id));
            } else if (canSelect && !isDuplicate) {
              context.read<PartyFormationBloc>().add(SelectMonster(monster: monster));
            }
          },
        );
      },
    );
  }

  /// モンスターリストタイル
  Widget _buildMonsterListTile(
    BuildContext context,
    Monster monster, {
    required bool isSelected,
    required bool canSelect,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isSelected ? Colors.blue[50] : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getElementColor(monster.element),
          child: Text(
            monster.monsterName.substring(0, 1),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          monster.monsterName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lv.${monster.level}'),
            Text('HP: ${monster.currentHp}/${_calculateMaxHp(monster)}'),
            Text('種族: ${monster.species} / 属性: ${monster.element}'),
            if (monster.equippedEquipment.isNotEmpty)
              Text('装備: ${monster.equippedEquipment.length}個'),
          ],
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Colors.green)
            : canSelect
                ? const Icon(Icons.add_circle, color: Colors.blue)
                : const Icon(Icons.block, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  /// 属性カラー
  Color _getElementColor(String element) {
    switch (element.toLowerCase()) {
      case 'fire':
        return Colors.red;
      case 'water':
        return Colors.blue;
      case 'thunder':
        return Colors.yellow[700]!;
      case 'wind':
        return Colors.green;
      case 'earth':
        return Colors.brown;
      case 'light':
        return Colors.amber;
      case 'dark':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// 最大HP計算
  int _calculateMaxHp(Monster monster) {
    return monster.maxHp;
  }

  /// 底部バー（バトル開始ボタン）
  Widget _buildBottomBar(BuildContext context, PartyFormationLoaded state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: state.selectedMonsters.isEmpty
                  ? null
                  : () => _navigateToBattle(context, state),
              icon: const Icon(Icons.play_arrow),
              label: Text(
                state.battleType == 'pvp' ? 'マッチング開始' : '冒険に出発',
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// バトル画面への遷移
  void _navigateToBattle(BuildContext context, PartyFormationLoaded state) {
    // TODO: バトル画面への遷移処理を実装
    // context.go('/battle', extra: {'monsters': state.selectedMonsters, 'battleType': state.battleType});
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('バトル画面への遷移は未実装です')),
    );
  }

  /// 保存ダイアログ
  void _showSaveDialog(BuildContext context) {
    final nameController = TextEditingController();
    final bloc = context.read<PartyFormationBloc>();
    final state = bloc.state;

    if (state is! PartyFormationLoaded) return;

    // 現在のプリセットを編集する場合、名前を初期値に
    if (state.currentPreset != null) {
      nameController.text = state.currentPreset!.name;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('パーティを保存'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'プリセット名',
                hintText: '例: バランス型',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Text('選択中: ${state.selectedMonsters.length}体'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('プリセット名を入力してください')),
                );
                return;
              }

              if (state.selectedMonsters.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('モンスターを選択してください')),
                );
                return;
              }

              bloc.add(SavePartyPreset(
                presetId: state.currentPreset?.id,
                name: nameController.text,
                isActive: true,
              ));

              Navigator.of(dialogContext).pop();
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// プリセット一覧ダイアログ
  void _showPresetsDialog(BuildContext context) {
    final bloc = context.read<PartyFormationBloc>();
    final state = bloc.state;

    if (state is! PartyFormationLoaded) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('保存済みプリセット'),
        content: SizedBox(
          width: double.maxFinite,
          child: state.presets.isEmpty
              ? const Center(child: Text('保存されたプリセットがありません'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.presets.length,
                  itemBuilder: (context, index) {
                    final preset = state.presets[index];
                    final isActive = preset.isActive;

                    return ListTile(
                      leading: Icon(
                        isActive ? Icons.star : Icons.star_border,
                        color: isActive ? Colors.amber : Colors.grey,
                      ),
                      title: Text(preset.name),
                      subtitle: Text('${preset.monsterIds.length}体'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isActive)
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () {
                                bloc.add(ActivatePreset(presetId: preset.id));
                                Navigator.of(dialogContext).pop();
                              },
                              tooltip: '使用する',
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _confirmDeletePreset(context, bloc, preset.id);
                              Navigator.of(dialogContext).pop();
                            },
                            tooltip: '削除',
                          ),
                        ],
                      ),
                      onTap: () {
                        bloc.add(ActivatePreset(presetId: preset.id));
                        Navigator.of(dialogContext).pop();
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  /// プリセット削除確認
  void _confirmDeletePreset(BuildContext context, PartyFormationBloc bloc, String presetId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('プリセット削除'),
        content: const Text('このプリセットを削除してもよろしいですか?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              bloc.add(DeletePartyPreset(presetId: presetId));
              Navigator.of(dialogContext).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}