import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/monster.dart';
import '../../../bloc/monster/monster_bloc.dart';
import '../../../bloc/monster/monster_event.dart';

class HealItemDialog extends StatelessWidget {
  final Monster monster;
  final List<HealItem> availableItems;

  const HealItemDialog({
    super.key,
    required this.monster,
    required this.availableItems,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('回復アイテムを選択'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: availableItems.isEmpty
            ? const Center(child: Text('使用できる回復アイテムがありません'))
            : ListView.builder(
                itemCount: availableItems.length,
                itemBuilder: (context, index) {
                  final item = availableItems[index];
                  return Card(
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.healing, color: Colors.green),
                      ),
                      title: Text(item.name),
                      subtitle: Text(item.description),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('×${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('+${item.healAmount}HP', style: const TextStyle(fontSize: 11, color: Colors.green)),
                        ],
                      ),
                      onTap: item.quantity > 0
                          ? () {
                              Navigator.pop(context);
                              _useHealItem(context, item);
                            }
                          : null,
                      enabled: item.quantity > 0,
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
      ],
    );
  }

  void _useHealItem(BuildContext context, HealItem item) {
    final newHp = (monster.currentHp + item.healAmount).clamp(0, monster.maxHp);
    context.read<MonsterBloc>().add(UpdateMonsterHp(
      monsterId: monster.id,
      newHp: newHp,
    ));
  }
}

/// 回復アイテムデータクラス
class HealItem {
  final String id;
  final String name;
  final String description;
  final int healAmount;
  final int quantity;

  const HealItem({
    required this.id,
    required this.name,
    required this.description,
    required this.healAmount,
    required this.quantity,
  });
}