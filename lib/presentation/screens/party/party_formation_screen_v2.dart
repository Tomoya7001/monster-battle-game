import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/monster.dart';
import '../../../core/models/monster_filter.dart';
import '../../bloc/party/party_formation_bloc_v2.dart';

/// クラロワ風パーティ編成画面V3（完全版）
class PartyFormationScreenV2 extends StatelessWidget {
  const PartyFormationScreenV2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('デッキ編成'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(40),
            child: Container(
                color: Colors.white,
                child: TabBar(
                labelColor: Colors.black87,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                ),
                tabs: const [
                    Tab(icon: Icon(Icons.people, size: 18), text: 'PvP'),
                    Tab(icon: Icon(Icons.explore, size: 18), text: '冒険'),
                ],
                ),
            ),
            ),
        ),
        body: TabBarView(
          children: [
            _buildTabContent(context, 'pvp'),
            _buildTabContent(context, 'adventure'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, String battleType) {
    return BlocProvider(
      create: (context) => PartyFormationBlocV2()
        ..add(LoadPartyPresetsV2(battleType: battleType)),
      child: _PartyFormationContent(battleType: battleType),
    );
  }
}

class _PartyFormationContent extends StatelessWidget {
  final String battleType;

  const _PartyFormationContent({required this.battleType});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: battleType == 'pvp'
              ? [Colors.red[50]!, Colors.red[100]!]
              : [Colors.green[50]!, Colors.green[100]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: BlocConsumer<PartyFormationBlocV2, PartyFormationStateV2>(
        listener: (context, state) {
          if (state is PartyFormationErrorV2) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is PartyFormationLoadingV2) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PartyFormationLoadedV2) {
            return _buildContent(context, state);
          }

          return const Center(child: Text('初期化中...'));
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, PartyFormationLoadedV2 state) {
    return Column(
      children: [
        // アクティブプリセット表示
        _buildActivePresetBanner(context, state),

        // プリセット番号選択（1-5）
        _buildPresetSelector(context, state),

        // 選択中モンスター表示（5体固定・ドラッグ&ドロップ対応）
        _buildSelectedMonsters(context, state),

        // ツールバー（ソート・フィルター・グリッドサイズ）
        _buildToolbar(context, state),

        const Divider(height: 1),

        // モンスター一覧
        Expanded(
          child: _buildMonsterGrid(context, state),
        ),
      ],
    );
  }

  /// アクティブプリセットバナー
  Widget _buildActivePresetBanner(BuildContext context, PartyFormationLoadedV2 state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: battleType == 'pvp' ? Colors.red[700] : Colors.green[700],
      child: Row(
        children: [
          Icon(
            battleType == 'pvp' ? Icons.sports_kabaddi : Icons.explore,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  battleType == 'pvp' ? 'PvPバトル用デッキ' : '冒険用パーティ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (state.currentPresetNumber != null)
                  Text(
                    '使用中: デッキ${state.currentPresetNumber}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${state.selectedMonsters.length}/5',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// プリセット番号選択
  Widget _buildPresetSelector(BuildContext context, PartyFormationLoadedV2 state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(5, (index) {
          final presetNumber = index + 1;
          final isSelected = state.currentPresetNumber == presetNumber;
          final monsterCount = state.getMonsterCountForPreset(presetNumber);

          return _buildPresetButton(
            context,
            presetNumber,
            isSelected: isSelected,
            monsterCount: monsterCount,
            onTap: () {
              context.read<PartyFormationBlocV2>().add(
                    SelectPresetV2(presetNumber: presetNumber),
                  );
            },
          );
        }),
      ),
    );
  }

  Widget _buildPresetButton(
    BuildContext context,
    int number, {
    required bool isSelected,
    required int monsterCount,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected
              ? (battleType == 'pvp' ? Colors.red[600] : Colors.green[600])
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? (battleType == 'pvp' ? Colors.red[800]! : Colors.green[800]!)
                : Colors.grey[300]!,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (battleType == 'pvp'
                            ? Colors.red[600]!
                            : Colors.green[600]!)
                        .withOpacity(0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$number',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              '$monsterCount体',
              style: TextStyle(
                fontSize: 9,
                color: isSelected ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 選択中モンスター表示（5体固定・ドラッグ&ドロップ対応）
  Widget _buildSelectedMonsters(BuildContext context, PartyFormationLoadedV2 state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '選択中',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (state.selectedMonsters.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    context.read<PartyFormationBlocV2>().add(ClearSelectionV2());
                  },
                  icon: const Icon(Icons.clear_all, size: 14),
                  label: const Text('クリア', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 70,
            child: ReorderableListView(
              scrollDirection: Axis.horizontal,
              onReorder: (oldIndex, newIndex) {
                context.read<PartyFormationBlocV2>().add(
                      ReorderMonstersV2(
                        oldIndex: oldIndex,
                        newIndex: newIndex,
                      ),
                    );
              },
              children: [
                ...List.generate(state.selectedMonsters.length, (index) {
                  final monster = state.selectedMonsters[index];
                  return _buildDraggableMonsterCard(
                    context,
                    monster,
                    index,
                    key: ValueKey(monster.id),
                  );
                }),
                ...List.generate(
                  5 - state.selectedMonsters.length,
                  (index) => _buildEmptySlot(
                    key: ValueKey('empty_${state.selectedMonsters.length + index}'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableMonsterCard(
    BuildContext context,
    Monster monster,
    int index, {
    required Key key,
  }) {
    return Container(
      key: key,
      width: 60,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: _getRarityColor(monster.rarity),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          context.read<PartyFormationBlocV2>().add(
                RemoveMonsterV2(monsterId: monster.id),
              );
        },
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  monster.monsterName.length > 3
                      ? monster.monsterName.substring(0, 3)
                      : monster.monsterName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Lv${monster.level}',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
            if (battleType == 'adventure' && index == 0)
              Positioned(
                bottom: 2,
                left: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '先頭',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySlot({required Key key}) {
    return Container(
      key: key,
      width: 60,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 2),
      ),
      child: Center(
        child: Icon(
          Icons.add_circle_outline,
          size: 20,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  /// ツールバー（修正版）
  Widget _buildToolbar(BuildContext context, PartyFormationLoadedV2 state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          const Text(
            'モンスター一覧',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          _buildToolbarButton(
            context,
            icon: Icons.sort,
            label: 'ソート',
            onPressed: () => _showSortDialog(context, state),
          ),
          const SizedBox(width: 6),
          _buildToolbarButton(
            context,
            icon: Icons.filter_list,
            label: 'フィルター',
            onPressed: () => _showFilterDialog(context, state),
          ),
          const SizedBox(width: 6),
          _buildToolbarButton(
            context,
            icon: Icons.grid_view,
            label: '${state.gridSize}列',
            onPressed: () => _showGridSizeDialog(context, state),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  /// モンスターグリッド
  Widget _buildMonsterGrid(BuildContext context, PartyFormationLoadedV2 state) {
    final monsters = _applyFilterAndSort(state);

    if (monsters.isEmpty) {
      return const Center(
        child: Text('モンスターがいません'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: state.gridSize,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 0.7,
      ),
      itemCount: monsters.length,
      itemBuilder: (context, index) {
        return _buildMonsterCard(context, state, monsters[index]);
      },
    );
  }

  Widget _buildMonsterCard(BuildContext context, PartyFormationLoadedV2 state, Monster monster) {
    final isSelected = state.selectedMonsters.any((m) => m.id == monster.id);
    final canSelect = state.selectedMonsters.length < 5;
    final isDuplicate = battleType == 'pvp' &&
        state.selectedMonsters.any((m) => m.monsterId == monster.monsterId);

    return Card(
      elevation: isSelected ? 3 : 1,
      color: isSelected
          ? Colors.blue[50]
          : (isDuplicate ? Colors.grey[300] : Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: (!canSelect || isDuplicate)
            ? null
            : () {
                context.read<PartyFormationBlocV2>().add(
                      SelectMonsterV2(monster: monster),
                    );
              },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // レアリティ
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: _getRarityColor(monster.rarity),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '★${monster.rarity}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // モンスター名
              Expanded(
                child: Center(
                  child: Text(
                    monster.monsterName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDuplicate ? Colors.grey : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // ステータス
              Text(
                'Lv${monster.level}',
                style: TextStyle(
                  fontSize: 10,
                  color: isDuplicate ? Colors.grey : Colors.black54,
                ),
              ),
              Text(
                'HP ${monster.currentHp}/${monster.maxHp}',
                style: TextStyle(
                  fontSize: 9,
                  color: isDuplicate ? Colors.grey : Colors.black54,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (isDuplicate)
                const Text(
                  '選択済み',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// ソートダイアログ
  void _showSortDialog(BuildContext context, PartyFormationLoadedV2 state) {
    final bloc = context.read<PartyFormationBlocV2>();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('並び替え'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: MonsterSortType.values.map((sortType) {
              return RadioListTile<MonsterSortType>(
                title: Text(sortType.displayName),
                value: sortType,
                groupValue: state.sortType,
                onChanged: (value) {
                  if (value != null) {
                    bloc.add(ChangeSortTypeV2(sortType: value));
                    Navigator.pop(dialogContext);
                  }
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// フィルターダイアログ（修正版）
  void _showFilterDialog(BuildContext context, PartyFormationLoadedV2 state) {
    final bloc = context.read<PartyFormationBlocV2>();
    
    String? selectedSpecies = state.filter.species;
    String? selectedElement = state.filter.element;
    int? selectedRarity = state.filter.rarity;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setState) {
          return AlertDialog(
            title: const Text('フィルター'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('種族', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      FilterChip(
                        label: const Text('全て', style: TextStyle(fontSize: 11)),
                        selected: selectedSpecies == null,
                        onSelected: (_) => setState(() => selectedSpecies = null),
                      ),
                      ...['angel', 'demon', 'human', 'spirit', 'mechanoid', 'dragon', 'mutant']
                          .map((species) {
                        return FilterChip(
                          label: Text(species, style: const TextStyle(fontSize: 11)),
                          selected: selectedSpecies == species,
                          onSelected: (_) => setState(() => selectedSpecies = species),
                        );
                      }).toList(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('属性', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      FilterChip(
                        label: const Text('全て', style: TextStyle(fontSize: 11)),
                        selected: selectedElement == null,
                        onSelected: (_) => setState(() => selectedElement = null),
                      ),
                      ...['fire', 'water', 'thunder', 'wind', 'earth', 'light', 'dark']
                          .map((element) {
                        return FilterChip(
                          label: Text(element, style: const TextStyle(fontSize: 11)),
                          selected: selectedElement == element,
                          onSelected: (_) => setState(() => selectedElement = element),
                        );
                      }).toList(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('レアリティ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      FilterChip(
                        label: const Text('全て', style: TextStyle(fontSize: 11)),
                        selected: selectedRarity == null,
                        onSelected: (_) => setState(() => selectedRarity = null),
                      ),
                      ...[2, 3, 4, 5].map((rarity) {
                        return FilterChip(
                          label: Text('★$rarity', style: const TextStyle(fontSize: 11)),
                          selected: selectedRarity == rarity,
                          onSelected: (_) => setState(() => selectedRarity = rarity),
                        );
                      }).toList(),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  bloc.add(const ChangeFilterV2(filter: MonsterFilter()));
                  Navigator.pop(dialogContext);
                },
                child: const Text('クリア'),
              ),
              ElevatedButton(
                onPressed: () {
                  bloc.add(
                    ChangeFilterV2(
                      filter: MonsterFilter(
                        species: selectedSpecies,
                        element: selectedElement,
                        rarity: selectedRarity,
                      ),
                    ),
                  );
                  Navigator.pop(dialogContext);
                },
                child: const Text('適用'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// グリッドサイズダイアログ
  void _showGridSizeDialog(BuildContext context, PartyFormationLoadedV2 state) {
    final bloc = context.read<PartyFormationBlocV2>();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('表示サイズ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.grid_view),
              title: const Text('大 (2列)'),
              trailing: state.gridSize == 2 ? const Icon(Icons.check) : null,
              onTap: () {
                bloc.add(const ChangeGridSizeV2(gridSize: 2));
                Navigator.pop(dialogContext);
              },
            ),
            ListTile(
              leading: const Icon(Icons.grid_view),
              title: const Text('中 (4列)'),
              trailing: state.gridSize == 4 ? const Icon(Icons.check) : null,
              onTap: () {
                bloc.add(const ChangeGridSizeV2(gridSize: 4));
                Navigator.pop(dialogContext);
              },
            ),
            ListTile(
              leading: const Icon(Icons.grid_view),
              title: const Text('小 (6列)'),
              trailing: state.gridSize == 6 ? const Icon(Icons.check) : null,
              onTap: () {
                bloc.add(const ChangeGridSizeV2(gridSize: 6));
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// フィルター・ソート適用
  List<Monster> _applyFilterAndSort(PartyFormationLoadedV2 state) {
    var monsters = List<Monster>.from(state.allMonsters);

    // フィルター適用
    if (state.filter.species != null) {
      monsters = monsters
          .where((m) => m.species.toLowerCase() == state.filter.species!.toLowerCase())
          .toList();
    }
    if (state.filter.element != null) {
      monsters = monsters
          .where((m) => m.element.toLowerCase() == state.filter.element!.toLowerCase())
          .toList();
    }
    if (state.filter.rarity != null) {
      monsters = monsters.where((m) => m.rarity == state.filter.rarity).toList();
    }

    // ソート適用
    switch (state.sortType) {
      case MonsterSortType.levelDesc:
        monsters.sort((a, b) => b.level.compareTo(a.level));
        break;
      case MonsterSortType.levelAsc:
        monsters.sort((a, b) => a.level.compareTo(b.level));
        break;
      case MonsterSortType.rarityDesc:
        monsters.sort((a, b) => b.rarity.compareTo(a.rarity));
        break;
      case MonsterSortType.rarityAsc:
        monsters.sort((a, b) => a.rarity.compareTo(b.rarity));
        break;
      case MonsterSortType.hpDesc:
        monsters.sort((a, b) => b.currentHp.compareTo(a.currentHp));
        break;
      case MonsterSortType.hpAsc:
        monsters.sort((a, b) => a.currentHp.compareTo(b.currentHp));
        break;
      case MonsterSortType.acquiredDesc:
        monsters.sort((a, b) => b.acquiredAt.compareTo(a.acquiredAt));
        break;
      case MonsterSortType.acquiredAsc:
        monsters.sort((a, b) => a.acquiredAt.compareTo(b.acquiredAt));
        break;
      case MonsterSortType.favoriteFirst:
        monsters.sort((a, b) {
          if (a.isFavorite && !b.isFavorite) return -1;
          if (!a.isFavorite && b.isFavorite) return 1;
          return b.level.compareTo(a.level);
        });
        break;
      case MonsterSortType.nameAsc:
        monsters.sort((a, b) => a.monsterName.compareTo(b.monsterName));
        break;
      case MonsterSortType.nameDesc:
        monsters.sort((a, b) => b.monsterName.compareTo(a.monsterName));
        break;
    }

    return monsters;
  }

  Color _getRarityColor(int rarity) {
    switch (rarity) {
      case 2:
        return Colors.grey;
      case 3:
        return Colors.blue;
      case 4:
        return Colors.purple;
      case 5:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}