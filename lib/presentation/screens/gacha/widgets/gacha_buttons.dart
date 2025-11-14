import 'package:flutter/material.dart';

/// ガチャ実行ボタンウィジェット
class GachaButtons extends StatelessWidget {
  final VoidCallback onSinglePull;
  final VoidCallback onMultiPull;
  final int singleCost;
  final int multiCost;

  const GachaButtons({
    Key? key,
    required this.onSinglePull,
    required this.onMultiPull,
    required this.singleCost,
    required this.multiCost,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildButton(
              context: context,
              label: '単発',
              cost: singleCost,
              onPressed: onSinglePull,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildButton(
              context: context,
              label: '10連',
              cost: multiCost,
              onPressed: onMultiPull,
              color: Colors.purple,
              isSpecial: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required String label,
    required int cost,
    required VoidCallback onPressed,
    required Color color,
    bool isSpecial = false,
  }) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSpecial
              ? [color, color.withOpacity(0.7)]
              : [color.withOpacity(0.8), color.withOpacity(0.6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.diamond,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      cost.toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                if (isSpecial)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'おすすめ',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}