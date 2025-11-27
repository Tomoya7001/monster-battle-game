import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/monster_filter.dart';
import '../../../domain/entities/monster.dart';
import '../../bloc/monster/monster_bloc.dart';
import '../../bloc/monster/monster_event.dart';
import '../../bloc/monster/monster_state.dart';
import 'widgets/monster_card.dart';
import 'widgets/monster_filter_dialog.dart';
import 'widgets/monster_sort_dialog.dart';
import 'monster_detail_screen.dart';
import '../../blocs/auth/auth_bloc.dart';

/// グリッド表示タイプ
enum GridViewType {
  large,  // 2列表示
  medium, // 4列表示（デフォルト）
  small,  // 6列表示
}

class MonsterListScreen extends StatefulWidget {
  const MonsterListScreen({super.key});

  @override
  State<MonsterListScreen> createState() => _MonsterListScreenState();
}

class _MonsterListScreenState extends State<MonsterListScreen> {
  // SharedPreferencesのキー
  static const String _gridViewTypeKey = 'monster_list_grid_view_type';
  
  // デフォルトは4列
  GridViewType _gridViewType = GridViewType.medium;
  bool _isInitialized = false;
  
  List<Monster> _cachedMonsters = [];
  MonsterFilter? _cachedFilter;
  MonsterSortType _cachedSortType = MonsterSortType.levelDesc;
  int _cachedTotalCount = 100;

  String get _userId {
    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
    if (firebaseUid != null && firebaseUid.isNotEmpty) {
      return firebaseUid;
    }
    
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        return authState.userId;
      }
    } catch (e) {
      debugPrint('AuthBloc取得エラー: $e');
    }
    
    return 'dev_user_12345';
  }

  @override
  void initState() {
    super.initState();
    _loadGridViewType();
    context.read<MonsterBloc>().add(LoadUserMonsters(userId: _userId));
  }

  /// 保存された列数設定を読み込み
  Future<void> _loadGridViewType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedType = prefs.getString(_gridViewTypeKey);
      
      if (savedType != null && mounted) {
        setState(() {
          _gridViewType = _stringToGridViewType(savedType);
          _isInitialized = true;
        });
      } else {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('列数設定読み込みエラー: $e');
      setState(() {
        _isInitialized = true;
      });
    }
  }

  /// 列数設定を保存
  Future<void> _saveGridViewType(GridViewType type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_gridViewTypeKey, _gridViewTypeToString(type));
    } catch (e) {
      debugPrint('列数設定保存エラー: $e');
    }
  }

  /// GridViewType → String
  String _gridViewTypeToString(GridViewType type) {
    switch (type) {
      case GridViewType.large:
        return 'large';
      case GridViewType.medium:
        return 'medium';
      case GridViewType.small:
        return 'small';
    }
  }

  /// String → GridViewType
  GridViewType _stringToGridViewType(String value) {
    switch (value) {
      case 'large':
        return GridViewType.large;
      case 'medium':
        return GridViewType.medium;
      case 'small':
        return GridViewType.small;
      default:
        return GridViewType.medium;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('預かり所'),
        actions: [
          _buildGridToggleButton(),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context, _cachedFilter ?? const MonsterFilter()),
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
            onPressed: () => _showFilterDialog(context, _cachedFilter ?? const MonsterFilter()),
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
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
          if (state is MonsterUpdated) {
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
            _cachedMonsters = state.monsters;
            _cachedFilter = state.filter;
            _cachedSortType = state.sortType;
            _cachedTotalCount = state.totalCount;
          }
        },
        builder: (context, state) {
          // 初期化完了待ち
          if (!_isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MonsterLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MonsterListLoaded) {
            if (state.monsters.isEmpty) {
              return _buildEmptyState();
            }
            return _buildMonsterGrid(context, state.monsters);
          }

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
        setState(() => _gridViewType = type);
        _saveGridViewType(type); // 設定を保存
      },
      itemBuilder: (context) => [
        _buildGridMenuItem(GridViewType.large, Icons.grid_view, '大（2列）'),
        _buildGridMenuItem(GridViewType.medium, Icons.grid_on, '中（4列）'),
        _buildGridMenuItem(GridViewType.small, Icons.apps, '小（6列）'),
        const PopupMenuDivider(),
        PopupMenuItem(
          enabled: false,
          child: Text(
            '※ 設定は自動保存されます',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  PopupMenuItem<GridViewType> _buildGridMenuItem(GridViewType type, IconData icon, String label) {
    return PopupMenuItem(
      value: type,
      child: Row(
        children: [
          Icon(icon, color: _gridViewType == type ? Theme.of(context).primaryColor : null),
          const SizedBox(width: 8),
          Text(label),
          if (_gridViewType == type)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.check, size: 16),
            ),
        ],
      ),
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
        return 0.72;
      case GridViewType.medium:
        return 0.62;
      case GridViewType.small:
        return 0.58;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.catching_pokemon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('モンスターがいません', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('ガチャでモンスターを手に入れましょう！', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('エラーが発生しました', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(fontSize: 14, color: Colors.grey[500]), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<MonsterBloc>().add(LoadUserMonsters(userId: _userId)),
            child: const Text('再読み込み'),
          ),
        ],
      ),
    );
  }

  Widget _buildMonsterGrid(BuildContext context, List<Monster> monsters) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${monsters.length} / $_cachedTotalCount 体',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              Text(
                _getGridTypeLabel(),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: monsters.length,
            itemBuilder: (context, index) {
              final monster = monsters[index];
              return MonsterCard(
                monster: monster,
                isCompact: _gridViewType != GridViewType.large,
                onTap: () => _navigateToDetail(context, monster),
                // お気に入りの表示のみ（タップ不可）
                showFavoriteIcon: true,
                onFavoriteToggle: null,
                // 鍵マークは一覧で非表示
                showLockIcon: false,
                onLockToggle: null,
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
        onApply: (filter) => context.read<MonsterBloc>().add(ApplyFilter(filter)),
      ),
    );
  }

  void _showSortDialog(BuildContext context, MonsterSortType currentSort) {
    showDialog(
      context: context,
      builder: (dialogContext) => MonsterSortDialog(
        currentSort: currentSort,
        onSelect: (sortType) => context.read<MonsterBloc>().add(ApplySort(sortType)),
      ),
    );
  }

  void _showSearchDialog(BuildContext context, MonsterFilter currentFilter) {
    final controller = TextEditingController(text: currentFilter.searchKeyword ?? '');
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            context.read<MonsterBloc>().add(ApplyFilter(currentFilter.copyWith(searchKeyword: value)));
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('キャンセル')),
          if (currentFilter.searchKeyword?.isNotEmpty == true)
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<MonsterBloc>().add(ApplyFilter(currentFilter.copyWith(searchKeyword: '', clearKeyword: true)));
              },
              child: const Text('クリア'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<MonsterBloc>().add(ApplyFilter(currentFilter.copyWith(searchKeyword: controller.text)));
            },
            child: const Text('検索'),
          ),
        ],
      ),
    );
  }
}