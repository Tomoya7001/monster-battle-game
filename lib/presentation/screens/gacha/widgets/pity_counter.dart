import 'package:flutter/material.dart';

/// 天井カウンターウィジェット
/// 100連までの進捗を表示
class PityCounter extends StatelessWidget {
  final int current;
  final int max;

  const PityCounter({
    Key? key,
    required this.current,
    required this.max,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final remaining = max - current;
    final progress = current / max;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '天井まで',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'あと $remaining 回',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(progress),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$current / $max',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.9) {
      return Colors.red;
    } else if (progress >= 0.7) {
      return Colors.orange;
    } else if (progress >= 0.5) {
      return Colors.amber;
    } else {
      return Colors.blue;
    }
  }
}