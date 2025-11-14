import 'package:flutter/material.dart';

/// カラーユーティリティ
class ColorUtils {
  /// 16進数カラーコードをColorに変換
  /// 
  /// 例: "#FF5722" → Color(0xFFFF5722)
  static Color parseColor(String hexColor) {
    try {
      // "#" を削除
      String hex = hexColor.replaceAll('#', '');
      
      // 6桁の場合は不透明度100%を追加
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      // パースエラーの場合はグレーを返す
      return Colors.grey;
    }
  }

  /// レアリティに応じた色を取得
  static Color getRarityColor(int rarity) {
    switch (rarity) {
      case 5:
        return const Color(0xFFFFD700); // 金
      case 4:
        return const Color(0xFF9B59B6); // 紫
      case 3:
        return const Color(0xFF3498DB); // 青
      case 2:
      default:
        return const Color(0xFF95A5A6); // 灰色
    }
  }

  /// 属性に応じた色を取得
  static Color getElementColor(String element) {
    final lowerElement = element.toLowerCase();
    switch (lowerElement) {
      case 'fire':
        return const Color(0xFFFF5722);
      case 'water':
        return const Color(0xFF2196F3);
      case 'thunder':
        return const Color(0xFFFFC107);
      case 'wind':
        return const Color(0xFF4CAF50);
      case 'earth':
        return const Color(0xFF795548);
      case 'light':
        return const Color(0xFFFFEB3B);
      case 'dark':
        return const Color(0xFF9C27B0);
      case 'none':
      default:
        return const Color(0xFF95A5A6);
    }
  }
}