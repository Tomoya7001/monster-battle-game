import 'package:flutter/material.dart';

/// 通貨表示ウィジェット
/// ガチャ画面上部に石とチケットの所持数を表示
class CurrencyDisplay extends StatelessWidget {
  final int gems;
  final int tickets;

  const CurrencyDisplay({
    Key? key,
    required this.gems,
    required this.tickets,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCurrencyItem(
            icon: Icons.diamond,
            label: '石',
            amount: gems,
            color: Colors.blue,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade300,
          ),
          _buildCurrencyItem(
            icon: Icons.confirmation_number,
            label: 'チケット',
            amount: tickets,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyItem({
    required IconData icon,
    required String label,
    required int amount,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              amount.toString(),
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