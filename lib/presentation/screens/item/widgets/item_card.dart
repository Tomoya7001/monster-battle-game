// lib/presentation/screens/item/widgets/item_card.dart
import 'package:flutter/material.dart';
import '../../../../domain/entities/item.dart';

class ItemCard extends StatelessWidget {
  final Item item;
  final int quantity;
  final VoidCallback? onTap;

  const ItemCard({
    super.key,
    required this.item,
    required this.quantity,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Color(item.rarityColor).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Color(item.rarityColor),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // アイコン
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(item.rarityColor).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  item.name.substring(0, 1),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(item.rarityColor),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // 名前
            Text(
              item.name,
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            // 所持数
            Text(
              '×$quantity',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(item.rarityColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}