import 'package:cloud_firestore/cloud_firestore.dart';

/// モンスター育成サービス
class MonsterGrowthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// 経験値テーブル（レベルごとの必要累計経験値）
  static List<int> _expTable = _generateExpTable();
  
  /// 経験値テーブルを生成（Lv1-100）
  static List<int> _generateExpTable() {
    final table = <int>[0];
    int cumulative = 0;
    
    for (int lv = 2; lv <= 100; lv++) {
      final expForLevel = (lv * lv * 10).toInt();
      cumulative += expForLevel;
      table.add(cumulative);
    }
    
    return table;
  }
  
  /// 経験値を追加
  Future<Map<String, dynamic>> addExp({
    required String userMonsterId,
    required int expGain,
  }) async {
    final monsterRef = _firestore.collection('user_monsters').doc(userMonsterId);
    
    return await _firestore.runTransaction((transaction) async {
      final monsterDoc = await transaction.get(monsterRef);
      
      if (!monsterDoc.exists) {
        throw Exception('モンスターが存在しません');
      }
      
      final data = monsterDoc.data()!;
      final currentLevel = data['level'] as int;
      final currentExp = data['exp'] as int;
      
      final newExp = currentExp + expGain;
      
      int newLevel = currentLevel;
      while (newLevel < 100 && newExp >= _expTable[newLevel]) {
        newLevel++;
      }
      
      final leveledUp = newLevel > currentLevel;
      final levelsGained = newLevel - currentLevel;
      
      final updateData = {
        'exp': newExp,
        'level': newLevel,
        'updated_at': FieldValue.serverTimestamp(),
      };
      
      transaction.update(monsterRef, updateData);
      
      return {
        'leveled_up': leveledUp,
        'levels_gained': levelsGained,
        'old_level': currentLevel,
        'new_level': newLevel,
        'new_exp': newExp,
        'points_gained': levelsGained * 4,
      };
    });
  }
  
  /// ステータスポイントを振り分け
  Future<void> allocateStatPoints({
    required String userMonsterId,
    required String stat,
    required int points,
  }) async {
    final monsterRef = _firestore.collection('user_monsters').doc(userMonsterId);
    
    await _firestore.runTransaction((transaction) async {
      final monsterDoc = await transaction.get(monsterRef);
      
      if (!monsterDoc.exists) {
        throw Exception('モンスターが存在しません');
      }
      
      final data = monsterDoc.data()!;
      final statPoints = data['stat_points'] as Map<String, dynamic>;
      
      final currentValue = statPoints[stat] as int;
      final actualGain = _calculateDiminishingReturns(currentValue, points);
      
      statPoints[stat] = currentValue + actualGain.round();
      
      transaction.update(monsterRef, {
        'stat_points': statPoints,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }
  
  /// 収穫逓減の法則を適用
  double _calculateDiminishingReturns(int currentValue, int pointsToAdd) {
    double efficiency;
    
    if (currentValue < 40) {
      efficiency = 1.00;
    } else if (currentValue < 80) {
      efficiency = 0.85;
    } else if (currentValue < 120) {
      efficiency = 0.70;
    } else if (currentValue < 160) {
      efficiency = 0.55;
    } else {
      efficiency = 0.40;
    }
    
    return pointsToAdd * efficiency;
  }
  
  /// ステータスポイントをリセット
  Future<void> resetStatPoints({
    required String userMonsterId,
  }) async {
    final monsterRef = _firestore.collection('user_monsters').doc(userMonsterId);
    
    await monsterRef.update({
      'stat_points': {
        'hp': 0,
        'attack': 0,
        'defense': 0,
        'magic': 0,
        'speed': 0,
      },
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
  
  /// 技を変更
  Future<void> changeSkills({
    required String userMonsterId,
    required List<int> skillIds,
  }) async {
    if (skillIds.length > 4) {
      throw Exception('技は最大4個（ミュータントは5個）まで');
    }
    
    final monsterRef = _firestore.collection('user_monsters').doc(userMonsterId);
    
    await monsterRef.update({
      'equipped_skills': skillIds,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
  
  /// サブ特性を変更
  Future<void> changeSubTraits({
    required String userMonsterId,
    required List<int> traitIds,
  }) async {
    if (traitIds.length > 2) {
      throw Exception('サブ特性は最大2個（親密度Lv5+で3個）まで');
    }
    
    final monsterRef = _firestore.collection('user_monsters').doc(userMonsterId);
    
    await monsterRef.update({
      'sub_traits': traitIds,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
  
  /// 親密度を上げる
  Future<void> addAffection({
    required String userMonsterId,
    required int amount,
  }) async {
    final monsterRef = _firestore.collection('user_monsters').doc(userMonsterId);
    
    await _firestore.runTransaction((transaction) async {
      final monsterDoc = await transaction.get(monsterRef);
      
      if (!monsterDoc.exists) {
        throw Exception('モンスターが存在しません');
      }
      
      final data = monsterDoc.data()!;
      final currentAffection = data['affection_level'] as int;
      final newAffection = (currentAffection + amount).clamp(0, 10);
      
      transaction.update(monsterRef, {
        'affection_level': newAffection,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }
  
  /// モンスターの最終ステータスを計算
  Future<Map<String, int>> calculateFinalStats({
    required String userMonsterId,
    bool forPvP = false,
  }) async {
    final monsterDoc = await _firestore
        .collection('user_monsters')
        .doc(userMonsterId)
        .get();
    
    if (!monsterDoc.exists) {
      throw Exception('モンスターが存在しません');
    }
    
    final monsterData = monsterDoc.data()!;
    final level = forPvP ? 50 : (monsterData['level'] as int);
    
    final masterDoc = await _firestore
        .collection('monster_masters')
        .doc(monsterData['monster_id'].toString())
        .get();
    
    if (!masterDoc.exists) {
      throw Exception('モンスターマスターが存在しません');
    }
    
    final masterData = masterDoc.data()!;
    final baseStats = masterData['base_stats'] as Map<String, dynamic>;
    
    final stats = <String, int>{};
    
    for (var statName in ['hp', 'attack', 'defense', 'magic', 'speed']) {
      int value = (baseStats[statName] as num).toInt();
      
      if (forPvP || level >= 50) {
        final lv50Bonus = masterData['level_50_stats'];
        value += (lv50Bonus['${statName}_bonus'] as num).toInt();
      } else {
        final lv50Bonus = masterData['level_50_stats'];
        final bonusPerLevel = (lv50Bonus['${statName}_bonus'] as num) / 50;
        value += (bonusPerLevel * level).toInt();
      }
      
      final ivs = monsterData['individual_values'] as Map<String, dynamic>;
      value += (ivs[statName] as num).toInt();
      
      final statPoints = monsterData['stat_points'] as Map<String, dynamic>;
      int pointValue = (statPoints[statName] as num).toInt();
      if (statName == 'hp') {
        pointValue *= 2;
      }
      value += pointValue;
      
      stats[statName] = value;
    }
    
    return stats;
  }
  
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}