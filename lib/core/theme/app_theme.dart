import 'package:flutter/material.dart';

class AppTheme {
  // プライマリカラー (ダーク基調)
  static const Color primaryColor = Color(0xFF7C4DFF);
  static const Color secondaryColor = Color(0xFFFF4081);
  static const Color backgroundColor = Color(0xFF121212);
  static const Color surfaceColor = Color(0xFF1E1E1E);
  
  // テキストカラー
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  
  // 属性カラー
  static const Color fireColor = Color(0xFFFF5722);
  static const Color waterColor = Color(0xFF2196F3);
  static const Color grassColor = Color(0xFF4CAF50);
  static const Color electricColor = Color(0xFFFFC107);
  static const Color darkColor = Color(0xFF9C27B0);
  static const Color lightColor = Color(0xFFFFEB3B);
  
  // レアリティカラー
  static const Color rarity1 = Color(0xFF9E9E9E); // ★1
  static const Color rarity2 = Color(0xFF4CAF50); // ★2
  static const Color rarity3 = Color(0xFF2196F3); // ★3
  static const Color rarity4 = Color(0xFF9C27B0); // ★4
  static const Color rarity5 = Color(0xFFFFD700); // ★5
  
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      background: backgroundColor,
    ),
    useMaterial3: true,
  );
}
