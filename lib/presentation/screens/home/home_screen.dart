import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';

/// ホーム画面
/// 
/// ゲームのメイン画面（Week 5以降で本格実装予定）
/// 現在は仮実装で基本的なナビゲーションのみ
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // ナビゲーションアイテム
  final List<_NavigationItem> _navigationItems = [
    _NavigationItem(
      icon: Icons.home,
      label: 'ホーム',
      color: Colors.purple,
    ),
    _NavigationItem(
      icon: Icons.sports_kabaddi,
      label: 'バトル',
      color: Colors.red,
    ),
    _NavigationItem(
      icon: Icons.pets,
      label: 'モンスター',
      color: Colors.green,
    ),
    _NavigationItem(
      icon: Icons.casino,
      label: 'ガチャ',
      color: Colors.orange,
    ),
    _NavigationItem(
      icon: Icons.shopping_bag,
      label: 'ショップ',
      color: Colors.blue,
    ),
    _NavigationItem(
      icon: Icons.person,
      label: 'マイページ',
      color: Colors.teal,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_navigationItems[_selectedIndex].label),
        actions: [
          // 通知アイコン
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('通知機能は後で実装します')),
              );
            },
          ),
          // 設定アイコン
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('設定画面は後で実装します')),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: _navigationItems
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }

  /// メインコンテンツ
  Widget _buildBody() {
    final item = _navigationItems[_selectedIndex];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            item.color.withOpacity(0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // アイコン
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                item.icon,
                size: 64,
                color: item.color,
              ),
            ),
            const SizedBox(height: 24),

            // タイトル
            Text(
              item.label,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: item.color,
                  ),
            ),
            const SizedBox(height: 16),

            // 説明
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                _getDescription(_selectedIndex),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),

            // 実装予定バッジ
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.orange,
                  width: 1,
                ),
              ),
              child: const Text(
                '🚧 実装予定',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 48),

            // ログアウトボタン（開発用）
            OutlinedButton.icon(
              onPressed: () {
                // TODO: 実際のログアウト処理を実装
                context.go(AppRouter.login);
              },
              icon: const Icon(Icons.logout),
              label: const Text('ログアウト（開発用）'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// タブごとの説明文
  String _getDescription(int index) {
    switch (index) {
      case 0:
        return 'ホーム画面では、お知らせやミッション、\nログインボーナスなどを確認できます';
      case 1:
        return 'バトル画面では、他のプレイヤーや\nCPUと対戦できます';
      case 2:
        return 'モンスター画面では、所持モンスターの\n育成やパーティ編成ができます';
      case 3:
        return 'ガチャ画面では、新しいモンスターを\n入手できます';
      case 4:
        return 'ショップ画面では、アイテムや石を\n購入できます';
      case 5:
        return 'マイページでは、プロフィールや\n戦績を確認できます';
      default:
        return '';
    }
  }
}

/// ナビゲーションアイテムのデータクラス
class _NavigationItem {
  final IconData icon;
  final String label;
  final Color color;

  _NavigationItem({
    required this.icon,
    required this.label,
    required this.color,
  });
}