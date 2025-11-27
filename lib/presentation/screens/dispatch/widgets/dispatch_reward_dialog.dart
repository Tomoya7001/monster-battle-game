// lib/presentation/screens/dispatch/widgets/dispatch_reward_dialog.dart

import 'package:flutter/material.dart';
import '../../../../domain/entities/dispatch.dart';
import '../../../../domain/entities/material.dart' as mat;

class DispatchRewardDialog extends StatelessWidget {
  final List<DispatchRewardResult> rewards;
  final int expGained;
  final Map<String, mat.MaterialMaster> materialMasters;

  const DispatchRewardDialog({
    Key? key,
    required this.rewards,
    required this.expGained,
    required this.materialMasters,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 350),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ヘッダー
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade400, Colors.orange.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.card_giftcard,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '探索完了！',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '報酬を獲得しました',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // 報酬リスト
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 経験値
                    if (expGained > 0) ...[
                      _buildRewardItem(
                        icon: Icons.star,
                        iconColor: Colors.amber,
                        name: '経験値',
                        quantity: expGained,
                        isExp: true,
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                    ],

                    // 素材
                    if (rewards.isEmpty)
                      const Center(
                        child: Text(
                          '素材は獲得できませんでした',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      ...rewards.map((reward) {
                        final material = materialMasters[reward.materialId];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildRewardItem(
                            icon: Icons.inventory_2,
                            iconColor: _getRarityColor(material?.rarity ?? 1),
                            name: material?.name ?? reward.materialId,
                            quantity: reward.quantity,
                            rarity: material?.rarity ?? 1,
                          ),
                        );
                      }),
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
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardItem({
    required IconData icon,
    required Color iconColor,
    required String name,
    required int quantity,
    int rarity = 1,
    bool isExp = false,
  }) {
    return Row(
      children: [
        // アイコン
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor),
        ),
        const SizedBox(width: 12),

        // 名前
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!isExp && rarity > 1) ...[
                    const SizedBox(width: 4),
                    Text(
                      '★' * rarity,
                      style: TextStyle(
                        color: iconColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // 数量
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isExp ? Colors.amber.shade100 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            isExp ? '+$quantity' : 'x$quantity',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isExp ? Colors.amber.shade700 : Colors.grey.shade700,
            ),
          ),
        ),
      ],
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
}