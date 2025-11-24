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
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                if (index < state.selectedMonsters.length) {
                  return _buildSelectedMonsterCard(
                    context,
                    state.selectedMonsters[index],
                  );
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

  /// 選択済みモンスターカード
  Widget _buildSelectedMonsterCard(BuildContext context, Monster monster) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // モンスターアイコン（仮）
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    monster.monsterName.substring(0, 1),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Lv${monster.level}',
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
          // 削除ボタン
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                context.read<PartyFormationBloc>().add(
                      RemoveMonster(monsterId: monster.id),
                    );
              },
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 空きスロット
  Widget _buildEmptySlot(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 2),
      ),
      child: Center(
        child: Icon(
          Icons.add,
          size: 30,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  /// 手持ちモンスター一覧
  Widget _buildMonsterList(BuildContext context, PartyFormationLoaded state) {
    // 選択済みモンスターを除外
    final selectedIds = state.selectedMonsters.map((m) => m.id).toSet();
    final availableMonsters = state.allMonsters
        .where((m) => !selectedIds.contains(m.id))
        .toList();

    if (availableMonsters.isEmpty) {
      return const Center(
        child: Text('選択可能なモンスターがいません'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: availableMonsters.length,
      itemBuilder: (context, index) {
        final monster = availableMonsters[index];
        
        // PvPで同じモンスターIDが既に選択されているかチェック
        final isDuplicate = state.battleType == 'pvp' &&
            state.selectedMonsters.any((m) => m.monsterId == monster.monsterId);

        return _buildMonsterListTile(
          context,
          monster,
          isDuplicate: isDuplicate,
          onTap: isDuplicate
              ? null
              : () {
                  context.read<PartyFormationBloc>().add(
                        SelectMonster(monster: monster),
                      );
                },
        );
      },
    );
  }

  /// モンスターリストタイル
  Widget _buildMonsterListTile(
    BuildContext context,
    Monster monster, {
    bool isDuplicate = false,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        enabled: !isDuplicate,
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isDuplicate ? Colors.grey[300] : Colors.blue[100],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              monster.monsterName.substring(0, 1),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDuplicate ? Colors.grey : Colors.blue[900],
              ),
            ),
          ),
        ),
        title: Text(
          monster.monsterName,
          style: TextStyle(
            color: isDuplicate ? Colors.grey : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lv.${monster.level}'),
            Text('HP: ${monster.currentHp}/${_calculateMaxHp(monster)}'),
            Text('種族: ${monster.species} / 属性: ${monster.element}'),
          ],
        ),
        trailing: isDuplicate
            ? const Icon(Icons.block, color: Colors.red)
            : const Icon(Icons.add_circle, color: Colors.blue),
        onTap: onTap,
      ),
    );
  }

  /// 最大HP計算（仮実装）
  int _calculateMaxHp(Monster monster) {
    return monster.baseHp + (monster.level * 2);
  }

  /// 保存ダイアログ
  void _showSaveDialog(BuildContext context) {
    final nameController = TextEditingController();
    final bloc = context.read<PartyFormationBloc>();
    final state = bloc.state;

    if (state is! PartyFormationLoaded) return;

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
                        isActive ? Icons.check_circle : Icons.circle_outlined,
                        color: isActive ? Colors.blue : Colors.grey,
                      ),
                      title: Text(
                        preset.name,
                        style: TextStyle(
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text('${preset.monsterIds.length}体'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isActive)
                            IconButton(
                              icon: const Icon(Icons.play_arrow, color: Colors.blue),
                              onPressed: () {
                                bloc.add(ActivatePreset(presetId: preset.id));
                                Navigator.of(dialogContext).pop();
                              },
                              tooltip: '使用する',
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              bloc.add(DeletePartyPreset(presetId: preset.id));
                              Navigator.of(dialogContext).pop();
                            },
                            tooltip: '削除',
                          ),
                        ],
                      ),
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
}