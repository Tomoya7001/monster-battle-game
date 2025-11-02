import 'package:flutter/material.dart';

/// ガチャの種類
enum GachaType {
  normal,   // 通常
  premium,  // プレミアム
  pickup,   // ピックアップ
}

/// ガチャタブ切り替えウィジェット
/// 
/// Day 1: 基本的なタブ切り替え
/// Day 3-4: BLoCと連携して状態管理
class GachaTabs extends StatefulWidget {
  final GachaType initialType;
  final Function(GachaType)? onTypeChanged;

  const GachaTabs({
    super.key,
    this.initialType = GachaType.normal,
    this.onTypeChanged,
  });

  @override
  State<GachaTabs> createState() => _GachaTabsState();
}

class _GachaTabsState extends State<GachaTabs> {
  late GachaType _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          _buildTab(
            type: GachaType.normal,
            label: '通常',
          ),
          _buildTab(
            type: GachaType.premium,
            label: 'プレミアム',
          ),
          _buildTab(
            type: GachaType.pickup,
            label: 'ピックアップ',
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required GachaType type,
    required String label,
  }) {
    final isSelected = _selectedType == type;
    
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedType = type;
          });
          // コールバック実行(Day 3-4でBLoCに通知)
          widget.onTypeChanged?.call(type);
          
          // 開発用: 選択されたタブを表示
          debugPrint('[GachaTabs] Selected: $type');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected 
                  ? Theme.of(context).primaryColor 
                  : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected 
                ? Theme.of(context).primaryColor 
                : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}

/// ガチャタイプの表示名を取得
extension GachaTypeExtension on GachaType {
  String get displayName {
    switch (this) {
      case GachaType.normal:
        return '通常';
      case GachaType.premium:
        return 'プレミアム';
      case GachaType.pickup:
        return 'ピックアップ';
    }
  }
}