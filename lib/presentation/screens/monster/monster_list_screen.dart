// lib/presentation/screens/monster/monster_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/monster_filter.dart';
import '../../../domain/entities/monster.dart';
import '../../bloc/monster/monster_bloc.dart';
import '../../bloc/monster/monster_event.dart';
import '../../bloc/monster/monster_state.dart';
import 'widgets/monster_card.dart';
import 'widgets/monster_filter_dialog.dart';
import 'widgets/monster_sort_dialog.dart';
import 'monster_detail_screen.dart';

/// グリッド表示タイプ
enum GridViewType {
  large, // 2列表示
  medium, // 4列表示
  small, // 6列表示
}

class MonsterListScreen extends StatefulWidget {
  const MonsterListScreen({super.key});

  @override
  State<MonsterListScreen> createState() => _MonsterListScreenState();
}

class _MonsterListScreenState extends State<MonsterListScreen> {
  GridViewType _gridViewType = GridViewType.large;
  
  // ✅ 追加: 最後に読み込んだモンスターリストを保持
  List<Monster> _cachedMonsters = [];
  MonsterFilter? _cachedFilter;
  MonsterSortType _cachedSortType = MonsterSortType.levelDesc;
  int _cachedTotalCount = 100;

  String get _userId {
    return FirebaseAuth.instance.currentUser?.uid ?? 'demo_user';
  }

  @override
  void initState() {
    super.initState();
    context.read<MonsterBloc>().add(LoadUserMonsters(userId: _userId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('モンスター一覧'),
        actions: [
          _buildGridToggleButton(),
          // ✅ 修正: キャッシュを使用して常にアイコンを表示
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              final filter = _cachedFilter ?? const MonsterFilter();
              _showSearchDialog(context, filter);
            },
            tooltip: '検索',
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (_cachedFilter?.isActive ?? false)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => _showFilterDialog(
              context,
              _cachedFilter ?? const MonsterFilter(),
            ),
            tooltip: 'フィルター',
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortDialog(context, _cachedSortType),
            tooltip: 'ソート',
          ),
        ],
      ),
      body: BlocConsumer<MonsterBloc, MonsterState>(
        listener: (context, state) {
          if (state is MonsterError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
          if (state is MonsterUpdated) {
            // ✅ 修正: キャッシュを更新
            _updateCachedMonster(state.monster);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 1),
              ),
            );
          }
          if (state is MonsterListLoaded) {
            // ✅ 修正: キャッシュを更新
            _cachedMonsters = state.monsters;
            _cachedFilter = state.filter;
            _cachedSortType = state.sortType;
            _cachedTotalCount = state.totalCount;
          }
        },
        builder: (context, state) {
          if (state is MonsterLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MonsterListLoaded) {
            if (state.monsters.isEmpty) {
              return _buildEmptyState();
            }
            return _buildMonsterGrid(context, state.monsters);
          }

          // ✅ 修正: MonsterUpdated時もキャッシュを使用して表示を維持
          if (state is MonsterUpdated || state is MonsterError) {
            if (_cachedMonsters.isNotEmpty) {
              return _buildMonsterGrid(context, _cachedMonsters);
            }
          }

          if (state is MonsterError) {
            return _buildErrorState(state.message);
          }

          return const Center(child: Text('モンスターを読み込んでください'));
        },
      ),
    );
  }

  // ✅ 追加: キャッシュ内のモンスターを更新
  void _updateCachedMonster(Monster updatedMonster) {
    final index = _cachedMonsters.indexWhere((m) => m.id == updatedMonster.id);
    if (index != -1) {
      setState(() {
        _cachedMonsters = List.from(_cachedMonsters);
        _cachedMonsters[index] = updatedMonster;
      });
    }
  }

  Widget _buildGridToggleButton() {
    return PopupMenuButton<GridViewType>(
      icon: Icon(_getGridIcon()),
      tooltip: '表示切替',
      onSelected: (type) {
        setState(() {
          _gridViewType = type;
        });
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: GridViewType.large,
          child: Row(
            children: [
              Icon(
                Icons.grid_view,
                color: _gridViewType == GridViewType.large
                    ? Theme.of(context).primaryColor
                    : null,
              ),
              const SizedBox(width: 8),
              const Text('大（2列）'),
              if (_gridViewType == GridViewType.large)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.check, size: 16),
                ),
            ],
          ),
        ),
        PopupMenuItem(
          value: GridViewType.medium,
          child: Row(
            children: [
              Icon(
                Icons.grid_on,
                color: _gridViewType == GridViewType.medium
                    ? Theme.of(context).primaryColor
                    : null,
              ),
              const SizedBox(width: 8),
              const Text('中（4列）'),
              if (_gridViewType == GridViewType.medium)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.check, size: 16),
                ),
            ],
          ),
        ),
        PopupMenuItem(
          value: GridViewType.small,
          child: Row(
            children: [
              Icon(
                Icons.apps,
                color: _gridViewType == GridViewType.small
                    ? Theme.of(context).primaryColor
                    : null,
              ),
              const SizedBox(width: 8),
              const Text('小（6列）'),
              if (_gridViewType == GridViewType.small)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.check, size: 16),
                ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getGridIcon() {
    switch (_gridViewType) {
      case GridViewType.large:
        return Icons.grid_view;
      case GridViewType.medium:
        return Icons.grid_on;
      case GridViewType.small:
        return Icons.apps;
    }
  }

  int _getGridCrossAxisCount() {
    switch (_gridViewType) {
      case GridViewType.large:
        return 2;
      case GridViewType.medium:
        return 4;
      case GridViewType.small:
        return 6;
    }
  }

  double _getGridChildAspectRatio() {
    switch (_gridViewType) {
      case GridViewType.large:
        return 0.75;
      case GridViewType.medium:
        return 0.65; // ✅ 修正: オーバーフロー対策で調整
      case GridViewType.small:
        return 0.6; // ✅ 修正: オーバーフロー対策で調整
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.catching_pokemon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'モンスターがいません',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ガチャでモンスターを手に入れましょう！',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
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
            'エラーが発生しました',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<MonsterBloc>().add(LoadUserMonsters(userId: _userId));
            },
            child: const Text('再読み込み'),
          ),
        ],
      ),
    );
  }

  // ✅ 修正: MonsterListLoadedではなくList<Monster>を受け取る
  Widget _buildMonsterGrid(BuildContext context, List<Monster> monsters) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${monsters.length} / 100 体',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              Text(
                _getGridTypeLabel(),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _getGridCrossAxisCount(),
              childAspectRatio: _getGridChildAspectRatio(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: monsters.length,
            itemBuilder: (context, index) {
              final monster = monsters[index];
              return MonsterCard(
                monster: monster,
                isCompact: _gridViewType != GridViewType.large, // ✅ 修正: 中・小表示時はコンパクト
                onTap: () => _navigateToDetail(context, monster),
                onFavoriteToggle: (isFavorite) {
                  context.read<MonsterBloc>().add(
                        ToggleFavorite(
                          monsterId: monster.id,
                          isFavorite: isFavorite,
                        ),
                      );
                },
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
          ),
        ),
      ],
    );
  }

  String _getGridTypeLabel() {
    switch (_gridViewType) {
      case GridViewType.large:
        return '大表示（2列）';
      case GridViewType.medium:
        return '中表示（4列）';
      case GridViewType.small:
        return '小表示（6列）';
    }
  }

  void _navigateToDetail(BuildContext context, Monster monster) {
    // ✅ 修正: BlocProviderを引き継ぐ
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<MonsterBloc>(),
          child: MonsterDetailScreen(monster: monster),
        ),
      ),
    );
  }

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
            onSubmitted: (value) {
              Navigator.pop(dialogContext);
              context.read<MonsterBloc>().add(
                    ApplyFilter(
                      currentFilter.copyWith(searchKeyword: value),
                    ),
                  );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('キャンセル'),
            ),
            if (currentFilter.searchKeyword?.isNotEmpty == true)
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.read<MonsterBloc>().add(
                        ApplyFilter(
                          currentFilter.copyWith(
                            searchKeyword: '',
                            clearKeyword: true,
                          ),
                        ),
                      );
                },
                child: const Text('クリア'),
              ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<MonsterBloc>().add(
                      ApplyFilter(
                        currentFilter.copyWith(
                          searchKeyword: controller.text,
                        ),
                      ),
                    );
              },
              child: const Text('検索'),
            ),
          ],
        );
      },
    );
  }
}