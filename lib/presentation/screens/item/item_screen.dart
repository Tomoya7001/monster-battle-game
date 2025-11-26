// lib/presentation/screens/item/item_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/item/item_bloc.dart';
import '../../bloc/item/item_event.dart';
import '../../bloc/item/item_state.dart';
import 'widgets/item_card.dart';
import 'widgets/use_item_dialog.dart';

class ItemScreen extends StatefulWidget {
  final String userId;
  
  const ItemScreen({super.key, required this.userId});

  @override
  State<ItemScreen> createState() => _ItemScreenState();
}

class _ItemScreenState extends State<ItemScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        context.read<ItemBloc>().add(ChangeCategory(_tabController.index));
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('アイテム'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '装備'),
            Tab(text: '素材'),
            Tab(text: '消耗品'),
            Tab(text: '貴重品'),
          ],
        ),
      ),
      body: BlocConsumer<ItemBloc, ItemState>(
        listener: (context, state) {
          // 使用結果表示
          if (state.useResultMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.useResultMessage!),
                backgroundColor: state.useResultSuccess == true
                    ? Colors.green
                    : Colors.red,
              ),
            );
            context.read<ItemBloc>().add(const ClearUseResult());
          }
        },
        builder: (context, state) {
          if (state.status == ItemStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state.status == ItemStatus.error) {
            return Center(child: Text('エラー: ${state.errorMessage}'));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildEquipmentTab(state),
              _buildMaterialTab(state),
              _buildConsumableTab(context, state),
              _buildValuableTab(state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEquipmentTab(ItemState state) {
    // 装備は別画面で管理
    return const Center(
      child: Text('装備はモンスター詳細画面から管理できます'),
    );
  }

  Widget _buildMaterialTab(ItemState state) {
    final items = state.currentCategoryItems;
    
    if (items.isEmpty) {
      return const Center(child: Text('素材がありません'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final entry = items[index];
        return ItemCard(
          item: entry.key,
          quantity: entry.value,
          onTap: () => _showItemDetail(entry.key, entry.value),
        );
      },
    );
  }

  Widget _buildConsumableTab(BuildContext context, ItemState state) {
    final items = state.currentCategoryItems;
    
    if (items.isEmpty) {
      return const Center(child: Text('消耗品がありません'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final entry = items[index];
        return Card(
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Color(entry.key.rarityColor).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  entry.key.name.substring(0, 1),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(entry.key.rarityColor),
                  ),
                ),
              ),
            ),
            title: Text(entry.key.name),
            subtitle: Text(entry.key.description),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '×${entry.value}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _showUseDialog(context, entry.key),
                  child: const Text('使用'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildValuableTab(ItemState state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildValuableCard(
          icon: Icons.menu_book,
          title: '図鑑',
          subtitle: '登録済み: --/--',
          onTap: () {/* TODO: 図鑑画面へ */},
        ),
        const SizedBox(height: 12),
        _buildValuableCard(
          icon: Icons.emoji_events,
          title: 'トロフィーケース',
          subtitle: '獲得数: --/--',
          onTap: () {/* TODO: トロフィー画面へ */},
        ),
        const SizedBox(height: 12),
        _buildValuableCard(
          icon: Icons.card_membership,
          title: '所持パス一覧',
          subtitle: 'バトルパス・ブーストパス',
          onTap: () {/* TODO: パス画面へ */},
        ),
      ],
    );
  }

  Widget _buildValuableCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 40, color: Colors.amber),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showItemDetail(dynamic item, int quantity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.rarityStars),
            const SizedBox(height: 8),
            Text(item.description),
            const SizedBox(height: 16),
            Text('所持数: $quantity'),
            if (item.dropStages.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('ドロップ場所:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...item.dropStages.map<Widget>((s) => Text('• $s')).toList(),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showUseDialog(BuildContext context, dynamic item) {
    showDialog(
      context: context,
      builder: (dialogContext) => UseItemDialog(
        item: item,
        userId: widget.userId,
        onUse: (monsterId) {
          Navigator.pop(dialogContext);
          context.read<ItemBloc>().add(UseItem(
            userId: widget.userId,
            itemId: item.itemId,
            targetMonsterId: monsterId,
          ));
        },
      ),
    );
  }
}