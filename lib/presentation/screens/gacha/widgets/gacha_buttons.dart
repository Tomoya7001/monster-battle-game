import 'package:flutter/material.dart';

/// ガチャボタンウィジェット
/// 
/// 単発・10連ガチャのボタンを表示
/// Day 2: 基本UI
/// Day 3-4: 実際のガチャ実行処理
class GachaButtons extends StatelessWidget {
  final VoidCallback? onSinglePressed;
  final VoidCallback? onMultiPressed;
  final int singleCost;
  final int multiCost;
  final bool isLoading;

  const GachaButtons({
    super.key,
    this.onSinglePressed,
    this.onMultiPressed,
    this.singleCost = 150,
    this.multiCost = 1500,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: Row(
        children: [
          // 単発ボタン
          Expanded(
            child: _GachaButton(
              label: '単発',
              cost: singleCost,
              costType: '石',
              onPressed: onSinglePressed,
              isLoading: isLoading,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          // 10連ボタン(強調)
          Expanded(
            child: _GachaButton(
              label: '10連',
              cost: multiCost,
              costType: '石',
              onPressed: onMultiPressed,
              isLoading: isLoading,
              color: Colors.orange,
              isHighlight: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// 個別のガチャボタン
class _GachaButton extends StatelessWidget {
  final String label;
  final int cost;
  final String costType;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color color;
  final bool isHighlight;

  const _GachaButton({
    required this.label,
    required this.cost,
    required this.costType,
    this.onPressed,
    this.isLoading = false,
    required this.color,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey[400],
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: isHighlight ? 4 : 2,
        shadowColor: color.withOpacity(0.5),
      ),
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ラベル
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // コスト表示
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.diamond, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$cost$costType',
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                // 10連の特典表示
                if (isHighlight)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '★3以上確定',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}