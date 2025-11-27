// lib/presentation/screens/dispatch/widgets/dispatch_location_select_dialog.dart

import 'package:flutter/material.dart';
import '../../../../domain/entities/dispatch.dart';
import '../../../../domain/entities/material.dart' as mat;
import '../../../../domain/entities/monster.dart';
import 'dispatch_monster_select_dialog.dart';

class DispatchLocationSelectDialog extends StatefulWidget {
  final List<DispatchLocation> unlockedLocations;
  final List<Monster> availableMonsters;
  final Map<String, mat.MaterialMaster> materialMasters;
  final void Function(String locationId, int durationHours, List<String> monsterIds) onConfirm;

  const DispatchLocationSelectDialog({
    Key? key,
    required this.unlockedLocations,
    required this.availableMonsters,
    required this.materialMasters,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<DispatchLocationSelectDialog> createState() =>
      _DispatchLocationSelectDialogState();
}

class _DispatchLocationSelectDialogState
    extends State<DispatchLocationSelectDialog> {
  DispatchLocation? _selectedLocation;
  int _selectedDuration = 6;

  @override
  void initState() {
    super.initState();
    if (widget.unlockedLocations.isNotEmpty) {
      _selectedLocation = widget.unlockedLocations.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
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
                  const Icon(Icons.explore, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    '探索先を選択',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // コンテンツ
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 探索先選択
                    const Text(
                      '探索先',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...widget.unlockedLocations.map((location) =>
                        _buildLocationOption(location)),

                    const SizedBox(height: 24),

                    // 時間選択
                    const Text(
                      '探索時間',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDurationOption(6),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDurationOption(12),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 報酬プレビュー
                    if (_selectedLocation != null) ...[
                      const Text(
                        '獲得可能な報酬',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildRewardPreview(),
                    ],
                  ],
                ),
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
                      child: const Text('キャンセル'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedLocation != null
                          ? () => _showMonsterSelectDialog()
                          : null,
                      child: const Text('モンスター選択'),
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

  Widget _buildLocationOption(DispatchLocation location) {
    final isSelected = _selectedLocation?.locationId == location.locationId;

    return Card(
      color: isSelected ? Colors.blue.shade50 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedLocation = location;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // ラジオボタン的なアイコン
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? Colors.blue : Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.blue.shade700 : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      location.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '推奨Lv.${location.recommendedLevel}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationOption(int hours) {
    final isSelected = _selectedDuration == hours;
    final option = _selectedLocation?.dispatchOptions
        .where((o) => o.durationHours == hours)
        .firstOrNull;

    return Card(
      color: isSelected ? Colors.green.shade50 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? Colors.green : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedDuration = hours;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(
                Icons.timer,
                color: isSelected ? Colors.green : Colors.grey,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                '$hours時間',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isSelected ? Colors.green.shade700 : null,
                ),
              ),
              if (option != null) ...[
                const SizedBox(height: 4),
                Text(
                  '経験値 ${option.baseExp}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardPreview() {
    final option = _selectedLocation?.dispatchOptions
        .where((o) => o.durationHours == _selectedDuration)
        .firstOrNull;

    if (option == null) {
      return const Text('報酬情報がありません');
    }

    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 経験値
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  '経験値 ${option.baseExp}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            // 素材リスト
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: option.rewards.map((reward) {
                final material = widget.materialMasters[reward.materialId];
                final name = material?.name ?? reward.materialId;
                final rarity = material?.rarity ?? 1;

                return Chip(
                  label: Text(
                    '$name (${reward.rate}%)',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: _getRarityColor(rarity).withOpacity(0.2),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRarityColor(int rarity) {
    switch (rarity) {
      case 1: return Colors.grey;
      case 2: return Colors.green;
      case 3: return Colors.blue;
      case 4: return Colors.purple;
      case 5: return Colors.orange;
      default: return Colors.grey;
    }
  }

  void _showMonsterSelectDialog() {
    if (_selectedLocation == null) return;

    showDialog(
      context: context,
      builder: (_) => DispatchMonsterSelectDialog(
        availableMonsters: widget.availableMonsters,
        requiredCount: _selectedLocation!.requiredMonsterCount,
        maxCount: _selectedLocation!.requiredMonsterCount, // 現在は1体固定
        onConfirm: (monsterIds) {
          Navigator.pop(context); // このダイアログを閉じる
          widget.onConfirm(
            _selectedLocation!.locationId,
            _selectedDuration,
            monsterIds,
          );
        },
      ),
    );
  }
}