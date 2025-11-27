// lib/presentation/screens/dispatch/widgets/dispatch_slot_card.dart

import 'package:flutter/material.dart';
import '../../../../domain/entities/dispatch.dart';
import '../../../../domain/entities/material.dart' as mat;
import '../../../../domain/entities/monster.dart';
import 'dispatch_location_select_dialog.dart';

class DispatchSlotCard extends StatelessWidget {
  final int slotIndex;
  final UserDispatch? dispatch;
  final bool isUnlocked;
  final List<DispatchLocation> unlockedLocations;
  final List<Monster> availableMonsters;
  final Map<String, mat.MaterialMaster> materialMasters;
  final void Function(String locationId, int durationHours, List<String> monsterIds) onStart;
  final void Function(String dispatchId) onClaim;
  final void Function(String dispatchId) onCancel;
  final VoidCallback? onUnlock;

  const DispatchSlotCard({
    Key? key,
    required this.slotIndex,
    this.dispatch,
    required this.isUnlocked,
    required this.unlockedLocations,
    required this.availableMonsters,
    required this.materialMasters,
    required this.onStart,
    required this.onClaim,
    required this.onCancel,
    this.onUnlock,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isUnlocked) {
      return _buildLockedCard(context);
    }

    if (dispatch == null) {
      return _buildEmptyCard(context);
    }

    return _buildActiveCard(context, dispatch!);
  }

  /// 未解放の枠
  Widget _buildLockedCard(BuildContext context) {
    return Card(
      color: Colors.grey.shade200,
      child: InkWell(
        onTap: onUnlock,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lock, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '枠$slotIndex（未解放）',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.diamond, size: 16, color: Colors.blue.shade400),
                        const SizedBox(width: 4),
                        Text(
                          '500石で解放',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.add_circle, color: Colors.blue.shade400, size: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// 空の枠（探索可能）
  Widget _buildEmptyCard(BuildContext context) {
    final canStart = unlockedLocations.isNotEmpty && availableMonsters.isNotEmpty;

    return Card(
      child: InkWell(
        onTap: canStart
            ? () => _showLocationSelectDialog(context)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: canStart ? Colors.green.shade100 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.add,
                  color: canStart ? Colors.green : Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '枠$slotIndex',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      canStart
                          ? 'タップして探索を開始'
                          : unlockedLocations.isEmpty
                              ? '探索先がありません'
                              : 'モンスターがいません',
                      style: TextStyle(
                        color: canStart ? Colors.green : Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (canStart)
                const Icon(Icons.chevron_right, color: Colors.green),
            ],
          ),
        ),
      ),
    );
  }

  /// 探索中/完了の枠
  Widget _buildActiveCard(BuildContext context, UserDispatch dispatch) {
    final isCompleted = dispatch.isTimeCompleted;
    final location = unlockedLocations
        .where((l) => l.locationId == dispatch.locationId)
        .firstOrNull;

    return Card(
      color: isCompleted ? Colors.green.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green.shade200
                        : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check : Icons.explore,
                    color: isCompleted ? Colors.green : Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '枠$slotIndex',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        location?.name ?? '不明な探索先',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                // ステータスバッジ
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green : Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isCompleted ? '完了' : '探索中',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 進行状況
            if (!isCompleted) ...[
              // プログレスバー
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: dispatch.progressRate,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(Colors.blue.shade400),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              // 残り時間
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${dispatch.durationHours}時間探索',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        dispatch.remainingTimeText,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // キャンセルボタン（開始直後のみ）
              if (DateTime.now().difference(dispatch.startedAt).inMinutes < 5)
                TextButton(
                  onPressed: () => onCancel(dispatch.id),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('キャンセル（5分以内）'),
                ),
            ],

            // 完了時の報酬受取ボタン
            if (isCompleted) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => onClaim(dispatch.id),
                  icon: const Icon(Icons.card_giftcard),
                  label: const Text('報酬を受け取る'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showLocationSelectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => DispatchLocationSelectDialog(
        unlockedLocations: unlockedLocations,
        availableMonsters: availableMonsters,
        materialMasters: materialMasters,
        onConfirm: (locationId, durationHours, monsterIds) {
          onStart(locationId, durationHours, monsterIds);
        },
      ),
    );
  }
}