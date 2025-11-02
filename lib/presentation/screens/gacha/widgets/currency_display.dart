import 'package:flutter/material.dart';

/// 通貨表示ウィジェット
/// 
/// 所持している石とチケットの数を表示
/// Day 1: 仮データで表示
/// Day 3-4: BLoCから実データを取得
class CurrencyDisplay extends StatelessWidget {
  final int freeGems;
  final int tickets;

  const CurrencyDisplay({
    super.key,
    this.freeGems = 1500, // デフォルト値(仮データ)
    this.tickets = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 石の表示
          _CurrencyItem(
            icon: Icons.diamond,
            label: '石',
            value: freeGems,
            color: Colors.blue,
          ),
          const SizedBox(width: 32),
          // チケットの表示
          _CurrencyItem(
            icon: Icons.receipt,
            label: 'チケット',
            value: tickets,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }
}

/// 通貨アイテム(石またはチケット)
class _CurrencyItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _CurrencyItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}