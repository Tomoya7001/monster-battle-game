import 'package:flutter/material.dart';

/// ガチャ種別タブウィジェット
/// 通常・プレミアム・ピックアップの切り替え
class GachaTabs extends StatelessWidget {
  final String selectedTab;
  final ValueChanged<String> onTabChanged;

  const GachaTabs({
    Key? key,
    required this.selectedTab,
    required this.onTabChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildTab(
              context: context,
              label: '通常',
              isSelected: selectedTab == '通常',
              onTap: () => onTabChanged('通常'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTab(
              context: context,
              label: 'プレミアム',
              isSelected: selectedTab == 'プレミアム',
              onTap: () => onTabChanged('プレミアム'),
              color: Colors.purple,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTab(
              context: context,
              label: 'ピックアップ',
              isSelected: selectedTab == 'ピックアップ',
              onTap: () => onTabChanged('ピックアップ'),
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final tabColor = color ?? Colors.blue;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? tabColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? tabColor : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}