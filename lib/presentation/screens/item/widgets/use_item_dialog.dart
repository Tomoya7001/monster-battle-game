// lib/presentation/screens/item/widgets/use_item_dialog.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../domain/entities/item.dart';

class UseItemDialog extends StatefulWidget {
  final Item item;
  final String userId;
  final Function(String monsterId) onUse;

  const UseItemDialog({
    super.key,
    required this.item,
    required this.userId,
    required this.onUse,
  });

  @override
  State<UseItemDialog> createState() => _UseItemDialogState();
}

class _UseItemDialogState extends State<UseItemDialog> {
  String? _selectedMonsterId;
  List<Map<String, dynamic>> _monsters = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMonsters();
  }

  Future<void> _loadMonsters() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('user_monsters')
          .where('user_id', isEqualTo: widget.userId)
          .get();

      final monsters = <Map<String, dynamic>>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final masterId = data['monster_id'] as String?;
        
        if (masterId != null) {
          final masterDoc = await FirebaseFirestore.instance
              .collection('monster_masters')
              .doc(masterId)
              .get();
          
          if (masterDoc.exists) {
            monsters.add({
              'id': doc.id,
              'name': masterDoc.data()?['name'] ?? '不明',
              'level': data['level'] ?? 1,
              'current_hp': data['current_hp'] ?? 0,
              'base_hp': masterDoc.data()?['base_stats']?['hp'] ?? 100,
            });
          }
        }
      }

      setState(() {
        _monsters = monsters;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  bool _canUseOnMonster(Map<String, dynamic> monster) {
    final effectType = widget.item.effect?['type'] as String?;
    final currentHp = monster['current_hp'] as int? ?? 0;
    
    switch (effectType) {
      case 'revive':
        return currentHp <= 0; // 瀕死のみ
      case 'heal_hp':
      case 'heal_hp_full':
        return currentHp > 0; // 生存中のみ
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.item.name}を使用'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _monsters.isEmpty
                ? const Center(child: Text('モンスターがいません'))
                : ListView.builder(
                    itemCount: _monsters.length,
                    itemBuilder: (context, index) {
                      final monster = _monsters[index];
                      final canUse = _canUseOnMonster(monster);
                      final isSelected = _selectedMonsterId == monster['id'];
                      
                      return ListTile(
                        enabled: canUse,
                        selected: isSelected,
                        leading: CircleAvatar(
                          backgroundColor: canUse ? Colors.blue : Colors.grey,
                          child: Text('${monster['level']}'),
                        ),
                        title: Text(
                          monster['name'],
                          style: TextStyle(
                            color: canUse ? null : Colors.grey,
                          ),
                        ),
                        subtitle: Text(
                          monster['current_hp'] <= 0
                              ? '瀕死'
                              : 'HP: ${monster['current_hp']}',
                          style: TextStyle(
                            color: monster['current_hp'] <= 0
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                        onTap: canUse
                            ? () => setState(() => _selectedMonsterId = monster['id'])
                            : null,
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _selectedMonsterId != null
              ? () => widget.onUse(_selectedMonsterId!)
              : null,
          child: const Text('使用'),
        ),
      ],
    );
  }
}