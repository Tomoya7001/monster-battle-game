/// 属性相性計算サービス
class TypeEffectivenessService {
  // 相性定数
  static const double superEffective = 1.3;
  static const double normal = 1.0;
  static const double notVeryEffective = 0.77;

  /// 属性相性表
  /// 循環系: 炎 → 風 → 大地 → 雷 → 水 → 炎
  /// 対立系: 光 ⇔ 闇
  static final Map<String, Map<String, double>> _typeChart = {
    'fire': {
      'fire': normal,
      'water': notVeryEffective,
      'thunder': normal,
      'wind': superEffective,
      'earth': normal,
      'light': normal,
      'dark': normal,
      'none': normal,
    },
    'water': {
      'fire': superEffective,
      'water': normal,
      'thunder': notVeryEffective,
      'wind': normal,
      'earth': normal,
      'light': normal,
      'dark': normal,
      'none': normal,
    },
    'thunder': {
      'fire': normal,
      'water': superEffective,
      'thunder': normal,
      'wind': normal,
      'earth': notVeryEffective,
      'light': normal,
      'dark': normal,
      'none': normal,
    },
    'wind': {
      'fire': notVeryEffective,
      'water': normal,
      'thunder': normal,
      'wind': normal,
      'earth': superEffective,
      'light': normal,
      'dark': normal,
      'none': normal,
    },
    'earth': {
      'fire': normal,
      'water': normal,
      'thunder': superEffective,
      'wind': notVeryEffective,
      'earth': normal,
      'light': normal,
      'dark': normal,
      'none': normal,
    },
    'light': {
      'fire': normal,
      'water': normal,
      'thunder': normal,
      'wind': normal,
      'earth': normal,
      'light': normal,
      'dark': superEffective,
      'none': normal,
    },
    'dark': {
      'fire': normal,
      'water': normal,
      'thunder': normal,
      'wind': normal,
      'earth': normal,
      'light': superEffective,
      'dark': normal,
      'none': normal,
    },
    'none': {
      'fire': normal,
      'water': normal,
      'thunder': normal,
      'wind': normal,
      'earth': normal,
      'light': normal,
      'dark': normal,
      'none': normal,
    },
  };

  /// 単一属性への相性倍率を取得
  static double getMultiplier(String attackElement, String defenseElement) {
    final attackLower = attackElement.toLowerCase();
    final defenseLower = defenseElement.toLowerCase();
    
    return _typeChart[attackLower]?[defenseLower] ?? normal;
  }

  /// 複数属性への相性倍率を計算（掛け算方式）
  static double calculateMultiplier(String attackElement, List<String> defenseElements) {
    if (defenseElements.isEmpty) {
      return normal;
    }

    double multiplier = 1.0;
    for (final defElement in defenseElements) {
      multiplier *= getMultiplier(attackElement, defElement);
    }
    return multiplier;
  }

  /// 相性テキストを取得
  static String getEffectivenessText(double multiplier) {
    if (multiplier >= superEffective) {
      return '効果抜群！';
    } else if (multiplier <= notVeryEffective) {
      return '今ひとつ...';
    } else {
      return '';
    }
  }
}