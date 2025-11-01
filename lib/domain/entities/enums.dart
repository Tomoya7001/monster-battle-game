// 種族（Species）- 7種族
enum MonsterSpecies {
  angel,      // エンジェル（天使）
  demon,      // デーモン（悪魔）
  human,      // ヒューマン（人間）
  spirit,     // スピリット（妖怪・精霊）
  mechanoid,  // メカノイド（機械）
  dragon,     // ドラゴン（竜）
  mutant,     // ミュータント（UMA）
}

// 属性（Element）- 7属性
enum MonsterElement {
  fire,     // 炎
  water,    // 水
  thunder,  // 雷
  wind,     // 風
  earth,    // 大地
  light,    // 光
  dark,     // 闇
}

// 技タイプ
enum SkillType {
  physical, // 物理
  magical,  // 魔法
  buff,     // バフ
  debuff,   // デバフ
  heal,     // 回復
  special,  // 特殊
}

// 技ターゲット
enum SkillTarget {
  enemy,       // 敵単体
  self,        // 自分
  allEnemies,  // 敵全体
  allAllies,   // 味方全体
}

// 装備カテゴリ
enum EquipmentCategory {
  weapon,    // 武器
  armor,     // 防具
  accessory, // アクセサリ
  special,   // 特殊
}

// Enum拡張メソッド（文字列変換用）
extension MonsterSpeciesExtension on MonsterSpecies {
  String get value {
    switch (this) {
      case MonsterSpecies.angel:
        return 'angel';
      case MonsterSpecies.demon:
        return 'demon';
      case MonsterSpecies.human:
        return 'human';
      case MonsterSpecies.spirit:
        return 'spirit';
      case MonsterSpecies.mechanoid:
        return 'mechanoid';
      case MonsterSpecies.dragon:
        return 'dragon';
      case MonsterSpecies.mutant:
        return 'mutant';
    }
  }

  static MonsterSpecies fromString(String value) {
    switch (value.toLowerCase()) {
      case 'angel':
        return MonsterSpecies.angel;
      case 'demon':
        return MonsterSpecies.demon;
      case 'human':
        return MonsterSpecies.human;
      case 'spirit':
        return MonsterSpecies.spirit;
      case 'mechanoid':
        return MonsterSpecies.mechanoid;
      case 'dragon':
        return MonsterSpecies.dragon;
      case 'mutant':
        return MonsterSpecies.mutant;
      default:
        throw ArgumentError('Invalid species: $value');
    }
  }
}

extension MonsterElementExtension on MonsterElement {
  String get value {
    switch (this) {
      case MonsterElement.fire:
        return 'fire';
      case MonsterElement.water:
        return 'water';
      case MonsterElement.thunder:
        return 'thunder';
      case MonsterElement.wind:
        return 'wind';
      case MonsterElement.earth:
        return 'earth';
      case MonsterElement.light:
        return 'light';
      case MonsterElement.dark:
        return 'dark';
    }
  }

  static MonsterElement fromString(String value) {
    switch (value.toLowerCase()) {
      case 'fire':
        return MonsterElement.fire;
      case 'water':
        return MonsterElement.water;
      case 'thunder':
        return MonsterElement.thunder;
      case 'wind':
        return MonsterElement.wind;
      case 'earth':
        return MonsterElement.earth;
      case 'light':
        return MonsterElement.light;
      case 'dark':
        return MonsterElement.dark;
      default:
        throw ArgumentError('Invalid element: $value');
    }
  }
}