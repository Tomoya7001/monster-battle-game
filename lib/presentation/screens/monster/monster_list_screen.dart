import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/monster/monster_bloc.dart';
import '../../bloc/monster/monster_event.dart';
import '../../bloc/monster/monster_state.dart';
import '../../../domain/entities/monster.dart';
import '../../../core/models/monster_filter.dart';
import 'widgets/monster_card.dart';
import 'widgets/monster_filter_dialog.dart';
import 'widgets/monster_sort_dialog.dart';
import 'monster_detail_screen.dart';

/// モンスター一覧画面
/// 
/// 所持モンスターをグリッド形式で表示し、
/// フィルター・ソート・検索機能を提供します。
class MonsterListScreen extends StatefulWidget {
  const MonsterListScreen({super.key});

  @override
  State<MonsterListScreen> createState() => _MonsterListScreenState();
}

class _MonsterListScreenState extends State<MonsterListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final String _userId = 'demo_user'; // TODO: 実際のユーザーIDに置き換え

  @override
  void initState() {
    super.initState();
    context.read<MonsterBloc>().add(LoadUserMonsters(userId: _userId));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('預かり所'),
        actions: [
          // デバッグ用: ダミーデータ作成ボタン
          if (_isDevelopmentMode())
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'ダミーデータ作成',
              onPressed: () => _showCreateDummyDialog(context),
            ),
          // リフレッシュボタン
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '更新',
            onPressed: () {
              context.read<MonsterBloc>().add(RefreshMonsterList(_userId));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 検索・フィルター・ソートバー
          _buildSearchBar(),
          // モンスター一覧
          Expanded(
            child: BlocConsumer<MonsterBloc, MonsterState>(
                buildWhen: (previous, current) => current is! MonsterUpdated,
              listener: (context, state) {
                if (state is MonsterError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else if (state is MonsterUpdated) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.message)),
                    );
                } else if (state is DummyMonstersCreated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${state.count}体のダミーモンスターを作成しました'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is MonsterLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state is MonsterListLoaded) {
                  return _buildMonsterList(state);
                }

                // 初期状態またはエラー後
                return const Center(
                  child: Text('モンスターデータを読み込んでいます...'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 検索バーを構築
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: BlocBuilder<MonsterBloc, MonsterState>(
        builder: (context, state) {
          if (state is! MonsterListLoaded) {
            return const SizedBox.shrink();
          }

          return Column(
            children: [
              // 所持数表示
              Row(
                children: [
                  Text(
                    '所持: ${state.totalCount}/300',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 検索・フィルター・ソート
              Row(
                children: [
                  // フィルターボタン
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showFilterDialog(context, state.filter ?? const MonsterFilter()),
                      icon: Icon(
                        Icons.filter_list,
                        color: state.filter?.isActive ?? false ? Colors.blue : Colors.grey,
                      ),
                      label: Text(
                        'フィルター${state.filter?.isActive ?? false ? " ●" : ""}',
                        style: TextStyle(
                          color: state.filter?.isActive ?? false ? Colors.blue : Colors.grey[700],
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: state.filter?.isActive ?? false ? Colors.blue : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ソートボタン
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showSortDialog(context, state.sortType),
                      icon: const Icon(Icons.sort, color: Colors.grey),
                      label: Text(
                        'ソート',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 検索ボタン
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showSearchDialog(context, state.filter ?? const MonsterFilter()),
                      icon: const Icon(Icons.search, color: Colors.grey),
                      label: Text(
                        '検索',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
              // アクティブなフィルター表示
              if (state.filter?.isActive ?? false) ...[
                const SizedBox(height: 8),
                _buildActiveFilters(state.filter ?? const MonsterFilter()),
              ],
            ],
          );
        },
      ),
    );
  }

  /// アクティブなフィルターを表示
  Widget _buildActiveFilters(MonsterFilter filter) {
    final List<Widget> chips = [];

    if (filter.species != null) {
      chips.add(_buildFilterChip(
        label: speciesNameMap[filter.species] ?? filter.species!,
        onDeleted: () {
          context.read<MonsterBloc>().add(
                ApplyFilter(filter.copyWith(clearSpecies: true)),
              );
        },
      ));
    }

    if (filter.element != null) {
      chips.add(_buildFilterChip(
        label: elementNameMap[filter.element] ?? filter.element!,
        onDeleted: () {
          context.read<MonsterBloc>().add(
                ApplyFilter(filter.copyWith(clearElement: true)),
              );
        },
      ));
    }

    if (filter.rarity != null) {
      chips.add(_buildFilterChip(
        label: '★${filter.rarity}',
        onDeleted: () {
          context.read<MonsterBloc>().add(
                ApplyFilter(filter.copyWith(clearRarity: true)),
              );
        },
      ));
    }

    if (filter.favoriteOnly == true) {
      chips.add(_buildFilterChip(
        label: 'お気に入り',
        onDeleted: () {
          context.read<MonsterBloc>().add(
                ApplyFilter(filter.copyWith(clearFavorite: true)),
              );
        },
      ));
    }

    if (filter.searchKeyword != null && filter.searchKeyword!.isNotEmpty) {
      chips.add(_buildFilterChip(
        label: '検索: ${filter.searchKeyword}',
        onDeleted: () {
          context.read<MonsterBloc>().add(
                ApplyFilter(filter.copyWith(clearKeyword: true)),
              );
        },
      ));
    }

    chips.add(
      TextButton.icon(
        onPressed: () {
          context.read<MonsterBloc>().add(
                ApplyFilter(const MonsterFilter()),
              );
        },
        icon: const Icon(Icons.clear_all, size: 16),
        label: const Text('すべてクリア'),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: chips,
    );
  }

  /// フィルターチップを構築
  Widget _buildFilterChip({
    required String label,
    required VoidCallback onDeleted,
  }) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: onDeleted,
      backgroundColor: Colors.blue.withOpacity(0.1),
      deleteIconColor: Colors.blue,
      labelStyle: const TextStyle(
        fontSize: 12,
        color: Colors.blue,
      ),
    );
  }

  /// モンスター一覧を構築
  Widget _buildMonsterList(MonsterListLoaded state) {
    if (state.monsters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.pets,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'モンスターがいません',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            if (_isDevelopmentMode()) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showCreateDummyDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('ダミーデータを作成'),
              ),
            ],
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: state.monsters.length,
      itemBuilder: (context, index) {
        final monster = state.monsters[index];
        return MonsterCard(
          monster: monster,
          onTap: () => _navigateToDetail(context, monster),
          onFavoriteToggle: (isFavorite) {
            context.read<MonsterBloc>().add(
                  ToggleFavorite(
                    monsterId: monster.id,
                    isFavorite: isFavorite,
                  ),
                );
          },
          // ✅ 追加: ロック機能の連携
          onLockToggle: (isLocked) {
            context.read<MonsterBloc>().add(
                  ToggleLock(
                    monsterId: monster.id,
                    isLocked: isLocked,
                  ),
                );
          },
        );
      },
    );
  }

  /// フィルターダイアログを表示
  void _showFilterDialog(BuildContext context, MonsterFilter currentFilter) {
    showDialog(
      context: context,
      builder: (dialogContext) => MonsterFilterDialog(
        currentFilter: currentFilter,
        onApply: (filter) {
          context.read<MonsterBloc>().add(ApplyFilter(filter));
        },
      ),
    );
  }

  /// ソートダイアログを表示
  void _showSortDialog(BuildContext context, MonsterSortType currentSort) {
    showDialog(
      context: context,
      builder: (dialogContext) => MonsterSortDialog(
        currentSort: currentSort,
        onSelect: (sortType) {
          context.read<MonsterBloc>().add(ApplySort(sortType));
        },
      ),
    );
  }

  /// 検索ダイアログを表示
  void _showSearchDialog(BuildContext context, MonsterFilter currentFilter) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController(
          text: currentFilter.searchKeyword ?? '',
        );

        return AlertDialog(
          title: const Text('モンスター検索'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'モンスター名を入力',
              prefixIcon: Icon(Icons.search),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                final keyword = controller.text.trim();
                context.read<MonsterBloc>().add(
                      ApplyFilter(
                        currentFilter.copyWith(searchKeyword: keyword),
                      ),
                    );
                Navigator.pop(dialogContext);
              },
              child: const Text('検索'),
            ),
          ],
        );
      },
    );
  }

  /// ダミーデータ作成ダイアログを表示
  void _showCreateDummyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ダミーデータ作成'),
        content: const Text('20体のダミーモンスターを作成しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<MonsterBloc>().add(
                    CreateDummyMonsters(userId: _userId, count: 20),
                  );
              Navigator.pop(dialogContext);
            },
            child: const Text('作成'),
          ),
        ],
      ),
    );
  }

  /// モンスター詳細画面へ遷移
    void _navigateToDetail(BuildContext context, Monster monster) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<MonsterBloc>(), // 同じインスタンスを引き継ぐ
          child: MonsterDetailScreen(monster: monster),
        ),
      ),
    );
  }

  /// 開発モードかどうか
  bool _isDevelopmentMode() {
    // TODO: 本番環境では false を返す
    return true;
  }
}