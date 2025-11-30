import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../../core/router/app_router.dart';
import '../gacha/gacha_screen.dart';
import '../../bloc/gacha/gacha_bloc.dart';
import '../../bloc/gacha/gacha_event.dart';
import '../monster/monster_list_screen.dart';
import '../../bloc/monster/monster_bloc.dart';
import '../battle/battle_selection_screen.dart';
import '../item/item_screen.dart';
import '../../bloc/item/item_bloc.dart';
import '../../bloc/item/item_event.dart';
import '../recovery/recovery_screen.dart';
import '../../../data/repositories/party_preset_repository.dart';
import '../../../data/repositories/monster_repository_impl.dart';

/// ホーム画面（8タブ構成）
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String? userId;
    if (authState is Authenticated) {
      userId = authState.userId;
    }
    userId ??= 'dev_user_12345';

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          context.go(AppRouter.login);
        }
      },
      child: Scaffold(
        body: _buildBody(context, userId),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBody(BuildContext context, String userId) {
    switch (_currentIndex) {
      case 0: // バトル
        return _BattleTab(userId: userId);
      case 1: // 冒険
        return _AdventureTab(userId: userId);
      case 2: // 預かり所
        return BlocProvider(
          create: (context) => MonsterBloc(),
          child: const MonsterListScreen(),
        );
      case 3: // アイテム
        return BlocProvider(
          create: (context) => ItemBloc()..add(LoadItems(userId: userId)),
          child: ItemScreen(userId: userId),
        );
      case 4: // 召喚
        return BlocProvider(
          create: (context) => GachaBloc()..add(const InitializeGacha()),
          child: const GachaScreen(),
        );
      case 5: // 錬成
        return _CraftingTab();
      case 6: // 回復
        return const RecoveryScreen();
      case 7: // その他
        return _OtherTab(userId: userId);
      default:
        return const Center(child: Text('Unknown Tab'));
    }
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      selectedFontSize: 10,
      unselectedFontSize: 10,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.sports_kabaddi),
          label: 'バトル',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.explore),
          label: '冒険',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.pets),
          label: '預かり所',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2),
          label: 'アイテム',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.auto_awesome),
          label: '召喚',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.auto_fix_high),
          label: '錬成',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_hospital),
          label: '回復',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz),
          label: 'その他',
        ),
      ],
    );
  }
}

/// バトルタブ
class _BattleTab extends StatelessWidget {
  final String userId;
  
  const _BattleTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('バトル')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBattleButton(
                context,
                icon: Icons.people,
                title: 'カジュアルマッチ',
                subtitle: 'オンライン対戦',
                color: Colors.blue,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BattleSelectionScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _buildBattleButton(
                context,
                icon: Icons.person_add,
                title: 'フレンドバトル',
                subtitle: 'フレンドと対戦',
                color: Colors.green,
                onTap: () => _showComingSoon(context),
              ),
              const SizedBox(height: 16),
              _buildBattleButton(
                context,
                icon: Icons.casino,
                title: 'ドラフトバトル',
                subtitle: 'ランダム選出で対戦',
                color: Colors.purple,
                onTap: () => context.push('/draft'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBattleButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('準備中です')),
    );
  }
}

/// 冒険タブ
class _AdventureTab extends StatelessWidget {
  final String userId;
  
  const _AdventureTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('冒険')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAdventureButton(
                context,
                icon: Icons.map,
                title: '冒険に出発',
                subtitle: 'エリアを選んでバトル',
                color: Colors.green,
                onTap: () => _startAdventure(context),
              ),
              const SizedBox(height: 16),
              _buildAdventureButton(
                context,
                icon: Icons.send,
                title: '探索',
                subtitle: 'モンスターを派遣して素材収集',
                color: Colors.teal,
                onTap: () => context.push('/dispatch'),
              ),
              const SizedBox(height: 16),
              _buildAdventureButton(
                context,
                icon: Icons.groups,
                title: 'パーティ編成',
                subtitle: '冒険用パーティを編成',
                color: Colors.orange,
                onTap: () => context.push('/party-formation?battleType=adventure'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdventureButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startAdventure(BuildContext context) async {
    try {
      final partyRepo = PartyPresetRepository();
      final preset = await partyRepo.getActivePreset(userId, 'adventure');

      if (preset == null || preset.monsterIds.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('冒険用パーティを編成してください'),
              action: SnackBarAction(
                label: '編成',
                onPressed: () => context.push('/party-formation?battleType=adventure'),
              ),
            ),
          );
        }
        return;
      }

      final firestore = FirebaseFirestore.instance;
      final monsterRepo = MonsterRepositoryImpl(firestore);
      final adventureParty = await monsterRepo.getMonstersByIds(preset.monsterIds);

      if (adventureParty.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('パーティのモンスターが見つかりません')),
          );
        }
        return;
      }

      final availableMonsters = adventureParty.where((m) => m.currentHp > 0).toList();
      if (availableMonsters.length < 3) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('戦闘可能なモンスターが3体以上必要です。回復してください。'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (context.mounted) {
        context.push('/adventure', extra: adventureParty);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }
}

/// 錬成タブ
class _CraftingTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('錬成')),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () => context.push('/crafting'),
          icon: const Icon(Icons.auto_fix_high),
          label: const Text('錬成画面へ'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            backgroundColor: Colors.orange,
          ),
        ),
      ),
    );
  }
}

/// その他タブ
class _OtherTab extends StatelessWidget {
  final String userId;
  
  const _OtherTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('その他'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ログアウト',
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMenuItem(
            icon: Icons.store,
            title: 'ショップ',
            onTap: () => _showComingSoon(context),
          ),
          _buildMenuItem(
            icon: Icons.person,
            title: 'アカウント情報',
            onTap: () => _showComingSoon(context),
          ),
          _buildMenuItem(
            icon: Icons.settings,
            title: 'ゲーム設定',
            onTap: () => _showComingSoon(context),
          ),
          _buildMenuItem(
            icon: Icons.people,
            title: 'フレンド',
            onTap: () => _showComingSoon(context),
          ),
          _buildMenuItem(
            icon: Icons.help,
            title: 'ヘルプ',
            onTap: () => _showComingSoon(context),
          ),
          const Divider(),
          _buildMenuItem(
            icon: Icons.upload_file,
            title: 'マスターデータ投入',
            subtitle: '管理者用',
            onTap: () => context.go('/admin/data-import'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('ログアウトしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('準備中です')),
    );
  }
}
