// lib/presentation/screens/item/item_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../bloc/item/item_bloc.dart';
import '../../bloc/item/item_event.dart';
import '../../bloc/item/item_state.dart';
import '../../../domain/entities/equipment_master.dart';
import '../../../domain/entities/monster.dart';
import '../../../data/repositories/monster_repository_impl.dart';
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
              _buildEquipmentTab(context, state),
              _buildMaterialTab(state),
              _buildConsumableTab(context, state),
              _buildValuableTab(state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEquipmentTab(BuildContext context, ItemState state) {
    final equipments = state.equipmentMasters;
    
    if (equipments.isEmpty) {
      return const Center(child: Text('装備データがありません'));
    }

    // カテゴリでグループ化
    final grouped = <String, List<EquipmentMaster>>{};
    for (final eq in equipments) {
      grouped.putIfAbsent(eq.category, () => []).add(eq);
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        for (final category in ['weapon', 'armor', 'accessory', 'special'])
          if (grouped[category] != null && grouped[category]!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _getCategoryTitle(category),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...grouped[category]!.map((eq) => _buildEquipmentCard(context, eq)),
          ],
      ],
    );
  }

  String _getCategoryTitle(String category) {
    switch (category) {
      case 'weapon': return '🗡️ 武器';
      case 'armor': return '🛡️ 防具';
      case 'accessory': return '💍 アクセサリー';
      case 'special': return '✨ 特殊';
      default: return category;
    }
  }

  Widget _buildEquipmentCard(BuildContext context, EquipmentMaster equipment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: equipment.rarityColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: equipment.rarityColor, width: 2),
          ),
          child: Icon(equipment.categoryIcon, color: equipment.rarityColor),
        ),
        title: Row(
          children: [
            Expanded(child: Text(equipment.name)),
            Text(
              equipment.rarityStars,
              style: TextStyle(color: equipment.rarityColor, fontSize: 12),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              equipment.effectsText,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (equipment.restrictionText != null)
              Text(
                equipment.restrictionText!,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {
            final itemBloc = context.read<ItemBloc>();
            _showEquipDialog(context, equipment, itemBloc);
          },
          child: const Text('装着'),
        ),
        onTap: () {
          final itemBloc = context.read<ItemBloc>();
          _showEquipmentDetail(context, equipment, itemBloc);
        },
      ),
    );
  }

  void _showEquipmentDetail(BuildContext context, EquipmentMaster equipment, ItemBloc itemBloc) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(equipment.categoryIcon, color: equipment.rarityColor),
            const SizedBox(width: 8),
            Expanded(child: Text(equipment.name)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                equipment.rarityStars,
                style: TextStyle(color: equipment.rarityColor, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(equipment.description),
              const SizedBox(height: 16),
              const Text('効果:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(equipment.effectsText),
              if (equipment.restrictionText != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        equipment.restrictionText!,
                        style: TextStyle(color: Colors.orange.shade700),
                      ),
                    ],
                  ),
                ),
              ],
              if (equipment.crafting != null) ...[
                const SizedBox(height: 16),
                const Text('作成素材:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('• 共通素材: ${equipment.crafting!['common_materials']}'),
                Text('• モンスター素材: ${equipment.crafting!['monster_materials']}'),
                Text('• ゴールド: ${equipment.crafting!['gold']}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('閉じる'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showEquipDialog(context, equipment, itemBloc);
            },
            child: const Text('装着する'),
          ),
        ],
      ),
    );
  }

  void _showEquipDialog(BuildContext context, EquipmentMaster equipment, ItemBloc itemBloc) async {
    
    // モンスター一覧を取得
    final monsterRepo = MonsterRepositoryImpl(FirebaseFirestore.instance);
    final monsters = await monsterRepo.getMonsters(widget.userId);
    
    if (!mounted) return;
    
    // 装備可能なモンスターをフィルタ
    final equippableMonsters = monsters.where((m) {
      return equipment.canEquip(
        species: m.species,
        element: m.element,
        monsterRarity: m.rarity,
      );
    }).toList();
    
    if (equippableMonsters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('この装備を装着できるモンスターがいません'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${equipment.name}を装着'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: equippableMonsters.length,
            itemBuilder: (context, index) {
              final monster = equippableMonsters[index];
              final maxSlots = monster.species.toLowerCase() == 'human' ? 2 : 1;
              final currentEquipCount = monster.equippedEquipment.length;
              
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(int.parse(monster.elementColor.replaceFirst('#', '0xFF'))),
                    child: Text(
                      monster.monsterName.substring(0, 1),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(monster.monsterName),
                  subtitle: Text(
                    'Lv.${monster.level} | 装備: $currentEquipCount/$maxSlots',
                  ),
                  trailing: currentEquipCount < maxSlots
                      ? ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            itemBloc.add(EquipToMonster(
                              monsterId: monster.id,
                              equipmentId: equipment.equipmentId,
                              slot: currentEquipCount,
                            ));
                          },
                          child: const Text('装着'),
                        )
                      : TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            _showReplaceEquipDialog(context, monster, equipment, itemBloc);
                          },
                          child: const Text('交換'),
                        ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  void _showReplaceEquipDialog(
    BuildContext context,
    Monster monster,
    EquipmentMaster newEquipment,
    ItemBloc itemBloc,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${monster.monsterName}の装備を交換'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('どの装備と交換しますか？'),
            const SizedBox(height: 16),
            ...monster.equippedEquipment.asMap().entries.map((entry) {
                return ListTile(
                  title: Text('スロット${entry.key + 1}: ${entry.value}'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      // まず外して、新しい装備を装着
                      itemBloc.add(UnequipFromMonster(
                        monsterId: monster.id,
                        equipmentId: entry.value,
                      ));
                      Future.delayed(const Duration(milliseconds: 500), () {
                        itemBloc.add(EquipToMonster(
                          monsterId: monster.id,
                          equipmentId: newEquipment.equipmentId,
                          slot: entry.key,
                        ));
                      });
                    },
                    child: const Text('交換'),
                  ),
                );
              }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('キャンセル'),
          ),
        ],
      ),
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
                Text('×${entry.value}', style: const TextStyle(fontSize: 16)),
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
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _buildValuableCard(
          icon: Icons.emoji_events,
          title: 'トロフィーケース',
          subtitle: '獲得数: --/--',
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _buildValuableCard(
          icon: Icons.card_membership,
          title: '所持パス一覧',
          subtitle: 'バトルパス・ブーストパス',
          onTap: () {},
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