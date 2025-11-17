/// バトル用技データ
/// 
/// Firestoreのskill_mastersから読み込み、バトル計算に使用
class BattleSkill {
  final String id;
  final String name;
  final String type; // physical, magical, buff, debuff, heal, special
  final String element; // fire, water, thunder, wind, earth, light, dark, none
  final int cost; // 1-6
  final double powerMultiplier; // 威力倍率（例: 1.5 = 攻撃力の1.5倍）
  final int accuracy; // 命中率（0-100）
  final String target; // enemy, self, all_enemies, all_allies
  final Map<String, dynamic> effects; // 特殊効果
  final String description;

  const BattleSkill({
    required this.id,
    required this.name,
    required this.type,
    required this.element,
    required this.cost,
    required this.powerMultiplier,
    required this.accuracy,
    required this.target,
    required this.effects,
    required this.description,
  });

  /// Firestoreから変換
  factory BattleSkill.fromFirestore(Map<String, dynamic> data) {
    // effects の型チェック
    Map<String, dynamic> effectsMap = {};
    final effectsData = data['effects'];
    if (effectsData is Map<String, dynamic>) {
        effectsMap = effectsData;
    } else if (effectsData is List && effectsData.isNotEmpty) {
        // 配列の場合は最初の要素を使用（または空Mapにする）
        if (effectsData.first is Map<String, dynamic>) {
        effectsMap = effectsData.first as Map<String, dynamic>;
        }
    }
    return BattleSkill(
      id: data['skill_id']?.toString() ?? data['id']?.toString() ?? '',
      name: data['name'] as String? ?? '不明',
      type: data['type'] as String? ?? data['category'] as String? ?? 'physical',
      element: (data['element'] as String? ?? data['attribute'] as String? ?? 'none').toLowerCase(),
      cost: data['cost'] as int? ?? 1,
      powerMultiplier: (data['power_multiplier'] as num?)?.toDouble() 
          ?? (data['power'] as num? ?? 0) / 100.0, // powerが100なら1.0倍
      accuracy: data['accuracy'] as int? ?? 100,
      target: data['target'] as String? ?? 'enemy',
      effects: effectsMap,
      description: data['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'skill_id': id,
      'name': name,
      'type': type,
      'element': element,
      'cost': cost,
      'power_multiplier': powerMultiplier,
      'accuracy': accuracy,
      'target': target,
      'effects': effects,
      'description': description,
    };
  }

  /// 攻撃技かどうか
  bool get isAttack => type == 'physical' || type == 'magical';

  /// バフ技かどうか
  bool get isBuff => type == 'buff';

  /// デバフ技かどうか
  bool get isDebuff => type == 'debuff';

  /// 回復技かどうか
  bool get isHeal => type == 'heal';
}