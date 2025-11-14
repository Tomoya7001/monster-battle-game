import 'package:shared_preferences/shared_preferences.dart';

/// ガチャ設定の保存・読み込みを管理するクラス
class GachaPreferences {
  static const String _keySkipAnimation = 'gacha_skip_animation';
  static const String _keyAnimationSpeed = 'gacha_animation_speed';

  /// ガチャ演出スキップ設定を取得
  /// 
  /// Returns:
  ///   true: 常にスキップ
  ///   false: 演出を再生（デフォルト）
  static Future<bool> getSkipAnimation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySkipAnimation) ?? false;
  }

  /// ガチャ演出スキップ設定を保存
  /// 
  /// [value] true: 常にスキップ, false: 演出を再生
  static Future<void> setSkipAnimation(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySkipAnimation, value);
  }

  /// アニメーション速度設定を取得
  /// 
  /// Returns:
  ///   1.0: 通常速度（デフォルト）
  ///   0.5: スロー
  ///   2.0: 高速
  static Future<double> getAnimationSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyAnimationSpeed) ?? 1.0;
  }

  /// アニメーション速度設定を保存
  /// 
  /// [speed] アニメーション速度倍率（0.5 ~ 2.0）
  static Future<void> setAnimationSpeed(double speed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyAnimationSpeed, speed);
  }

  /// すべての設定をリセット
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySkipAnimation);
    await prefs.remove(_keyAnimationSpeed);
  }
}

/// ゲーム全体の設定を管理するクラス
class GamePreferences {
  static const String _keyBgmVolume = 'bgm_volume';
  static const String _keySfxVolume = 'sfx_volume';
  static const String _keyVoiceVolume = 'voice_volume';
  static const String _keyBattleSpeed = 'battle_speed';

  /// BGM音量を取得（0.0 ~ 1.0）
  static Future<double> getBgmVolume() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyBgmVolume) ?? 0.8;
  }

  /// BGM音量を保存
  static Future<void> setBgmVolume(double volume) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyBgmVolume, volume.clamp(0.0, 1.0));
  }

  /// 効果音音量を取得（0.0 ~ 1.0）
  static Future<double> getSfxVolume() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keySfxVolume) ?? 0.8;
  }

  /// 効果音音量を保存
  static Future<void> setSfxVolume(double volume) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keySfxVolume, volume.clamp(0.0, 1.0));
  }

  /// ボイス音量を取得（0.0 ~ 1.0）
  static Future<double> getVoiceVolume() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyVoiceVolume) ?? 0.8;
  }

  /// ボイス音量を保存
  static Future<void> setVoiceVolume(double volume) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyVoiceVolume, volume.clamp(0.0, 1.0));
  }

  /// バトル速度を取得（1: 通常, 2: 2倍速, 4: 4倍速）
  static Future<int> getBattleSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyBattleSpeed) ?? 1;
  }

  /// バトル速度を保存
  static Future<void> setBattleSpeed(int speed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyBattleSpeed, speed);
  }
}