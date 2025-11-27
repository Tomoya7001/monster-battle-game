// lib/presentation/screens/dispatch/widgets/dispatch_monster_select_dialog.dart

import 'package:flutter/material.dart';
import '../../../../domain/entities/monster.dart';

class DispatchMonsterSelectDialog extends StatefulWidget {
  final List<Monster> availableMonsters;
  final int requiredCount;
  final int maxCount;
  final void Function(List<String> monsterIds) onConfirm;

  const DispatchMonsterSelectDialog({
    Key? key,
    required this.availableMonsters,
    required this.requiredCount,
    required this.maxCount,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<DispatchMonsterSelectDialog> createState() =>
      _DispatchMonsterSelectDialogState();
}

class _DispatchMonsterSelectDialogState
    extends State<DispatchMonsterSelectDialog> {
  final Set<String> _selectedMonsterIds = {};

  @override
  Widget build(BuildContext context) {
    final canConfirm = _selectedMonsterIds.length >= widget.requiredCount &&
        _selectedMonsterIds.length <= widget.maxCount;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ヘッダー
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pets, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'モンスターを選択',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_selectedMonsterIds.length}/${widget.maxCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 説明
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '派遣するモンスターを${widget.requiredCount}体選択してください',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // モンスターリスト
            Flexible(
              child: widget.availableMonsters.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: widget.availableMonsters.length,
                      itemBuilder: (context, index) {
                        final monster = widget.availableMonsters[index];
                        return _buildMonsterTile(monster);
                      },
                    ),
            ),

            // フッター
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('戻る'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: canConfirm
                          ? () {
                              Navigator.pop(context);
                              widget.onConfirm(_selectedMonsterIds.toList());
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('探索開始'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber, size: 48, color: Colors.orange.shade300),
          const SizedBox(height: 12),
          const Text(
            '派遣可能なモンスターがいません',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            '他のモンスターが探索中です',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildMonsterTile(Monster monster) {
    final isSelected = _selectedMonsterIds.contains(monster.id);
    final canSelect = _selectedMonsterIds.length < widget.maxCount || isSelected;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: isSelected ? Colors.green.shade50 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? Colors.green : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: canSelect
            ? () {
                setState(() {
                  if (isSelected) {
                    _selectedMonsterIds.remove(monster.id);
                  } else {
                    _selectedMonsterIds.add(monster.id);
                  }
                });
              }
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // チェックボックス
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.green : Colors.grey.shade200,
                  border: Border.all(
                    color: isSelected ? Colors.green : Colors.grey.shade400,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),

              // モンスター属性アイコン
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getElementColor(monster.element).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _getElementEmoji(monster.element),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // モンスター情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          monster.monsterName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getRarityStars(monster.rarity),
                          style: TextStyle(
                            color: Colors.amber.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Lv.${monster.level}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // 属性タグ
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getElementColor(monster.element).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  monster.element,
                  style: TextStyle(
                    fontSize: 11,
                    color: _getElementColor(monster.element),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getElementColor(String element) {
    switch (element.toLowerCase()) {
      case 'fire': return Colors.red;
      case 'water': return Colors.blue;
      case 'thunder': return Colors.amber;
      case 'earth': return Colors.brown;
      case 'wind': return Colors.teal;
      case 'light': return Colors.orange;
      case 'dark': return Colors.purple;
      default: return Colors.grey;
    }
  }

  String _getElementEmoji(String element) {
    switch (element.toLowerCase()) {
      case 'fire': return '🔥';
      case 'water': return '💧';
      case 'thunder': return '⚡';
      case 'earth': return '🌍';
      case 'wind': return '🌪️';
      case 'light': return '✨';
      case 'dark': return '🌙';
      default: return '❓';
    }
  }

  String _getRarityStars(int rarity) {
    return '★' * rarity;
  }
}