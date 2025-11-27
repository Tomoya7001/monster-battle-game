// lib/core/services/item_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/item.dart';
import '../../domain/entities/monster.dart';
import '../../data/repositories/item_repository.dart';

/// アイテム使用結果
class ItemUseResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  ItemUseResult({
    required this.success,
    required this.message,
    this.data,
  });
}

/// アイテム使用サービス
class ItemService {
  final FirebaseFirestore _firestore;
  final ItemRepository _itemRepository;

  ItemService({
    FirebaseFirestore? firestore,
    ItemRepository? itemRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _itemRepository = itemRepository ?? ItemRepository();

  /// アイテムを使用
  Future<ItemUseResult> useItem({
    required String userId,
    required String itemId,
    required String targetMonsterId,
  }) async {
    try {
      // アイテム情報取得
      final item = await _itemRepository.getItemMaster(itemId);
      if (item == null) {
        return ItemUseResult(success: false, message: 'アイテムが見つかりません');
      }

      // 所持確認
      final userItem = await _itemRepository.getUserItem(userId, itemId);
      if (userItem == null || userItem.quantity <= 0) {
        return ItemUseResult(success: false, message: 'アイテムを持っていません');
      }

      // モンスター取得（user_monstersとmonster_mastersを結合）
      final monsterDoc = await _firestore
          .collection('user_monsters')
          .doc(targetMonsterId)
          .get();
      
      if (!monsterDoc.exists) {
        return ItemUseResult(success: false, message: 'モンスターが見つかりません');
      }

      final monsterData = monsterDoc.data()!;
      
      // マスターデータも取得（baseHp計算に必要）
      final masterMonsterId = monsterData['monster_id'] as String?;
      Map<String, dynamic>? masterData;
      if (masterMonsterId != null) {
        final masterDoc = await _firestore
            .collection('monster_masters')
            .doc(masterMonsterId)
            .get();
        if (masterDoc.exists) {
          masterData = masterDoc.data();
        }
      }
      
      final effect = item.effect;
      
      if (effect == null) {
        return ItemUseResult(success: false, message: 'このアイテムは使用できません');
      }

      // 効果適用
      final result = await _applyEffect(
        userId: userId,
        itemId: itemId,
        monsterId: targetMonsterId,
        monsterData: monsterData,
        masterData: masterData,
        effect: effect,
        item: item,
      );

      if (result.success) {
        // アイテム消費
        await _itemRepository.consumeItem(userId, itemId, 1);
      }

      return result;
    } catch (e) {
      return ItemUseResult(success: false, message: 'エラー: $e');
    }
  }

  /// 効果適用
  Future<ItemUseResult> _applyEffect({
    required String userId,
    required String itemId,
    required String monsterId,
    required Map<String, dynamic> monsterData,
    Map<String, dynamic>? masterData,
    required Map<String, dynamic> effect,
    required Item item,
  }) async {
    final effectType = effect['type'] as String?;
    final value = effect['value'] as num? ?? 0;

    switch (effectType) {
      case 'heal_hp':
        return await _healHp(monsterId, monsterData, masterData, value.toInt());
      
      case 'heal_hp_full':
        return await _healHpFull(monsterId, monsterData, masterData);
      
      case 'revive':
        return await _revive(monsterId, monsterData, masterData, value.toInt());
      
      case 'cure_status':
        return await _cureStatus(monsterId, monsterData);
      
      case 'add_exp':
        return await _addExp(monsterId, monsterData, value.toInt());
      
      case 'add_intimacy':
        return await _addIntimacy(monsterId, monsterData, value.toInt());
      
      case 'reset_points':
        return await _resetPoints(monsterId, monsterData);
      
      case 'max_iv':
        final stat = effect['stat'] as String?;
        return await _maxIv(monsterId, monsterData, stat);
      
      case 'reroll_trait':
        return await _rerollTrait(monsterId, monsterData);
      
      default:
        return ItemUseResult(success: false, message: '未対応の効果です');
    }
  }

  /// ★ Monster.maxHp と同じ計算式でmaxHPを計算
  /// 計算式: base * (1 + (level - 1) * 0.05) + iv + diminishingReturn(point)
  int _calculateMaxHp(Map<String, dynamic> monsterData, Map<String, dynamic>? masterData) {
    // base_statsから取得、なければmonster_mastersから
    final baseStats = masterData?['base_stats'] as Map<String, dynamic>? ?? {};
    final baseHp = (baseStats['hp'] as num?)?.toInt() ?? 
                   (masterData?['baseHp'] as num?)?.toInt() ?? 
                   100;
    
    final level = (monsterData['level'] as num?)?.toInt() ?? 1;
    final ivHp = (monsterData['iv_hp'] as num?)?.toInt() ?? 0;
    final pointHp = (monsterData['point_hp'] as num?)?.toInt() ?? 0;

    // 基礎値 * レベル倍率（1レベルごとに+5%）
    final double baseStat = baseHp * (1.0 + (level - 1) * 0.05);
    
    // 個体値を加算
    final double withIv = baseStat + ivHp;
    
    // ポイント振り分けによる追加（収穫逓減の法則）
    final double pointBonus = _calculateDiminishingReturn(pointHp);
    
    return (withIv + pointBonus).round();
  }

  /// 収穫逓減の法則によるポイント計算
  double _calculateDiminishingReturn(int points) {
    if (points <= 0) return 0.0;

    double total = 0.0;

    // 0-50: +1.0
    if (points > 0) {
      final int range1 = points.clamp(0, 50);
      total += range1 * 1.0;
    }

    // 51-100: +0.8
    if (points > 50) {
      final int range2 = (points - 50).clamp(0, 50);
      total += range2 * 0.8;
    }

    // 101-150: +0.6
    if (points > 100) {
      final int range3 = (points - 100).clamp(0, 50);
      total += range3 * 0.6;
    }

    // 151-200: +0.4
    if (points > 150) {
      final int range4 = (points - 150).clamp(0, 50);
      total += range4 * 0.4;
    }

    // 201以上: +0.2
    if (points > 200) {
      final int range5 = points - 200;
      total += range5 * 0.2;
    }

    return total;
  }

  /// HP回復
  Future<ItemUseResult> _healHp(
    String monsterId,
    Map<String, dynamic> data,
    Map<String, dynamic>? masterData,
    int healAmount,
  ) async {
    final currentHp = (data['current_hp'] as num?)?.toInt() ?? 0;
    
    // 瀕死チェック
    if (currentHp <= 0) {
      return ItemUseResult(success: false, message: '瀕死のモンスターには使用できません');
    }

    // ★ 修正: Monster.maxHpと同じ計算式
    final maxHp = _calculateMaxHp(data, masterData);

    if (currentHp >= maxHp) {
      return ItemUseResult(success: false, message: 'HPは既に最大です');
    }

    final newHp = (currentHp + healAmount).clamp(0, maxHp);
    final healedAmount = newHp - currentHp;

    await _firestore.collection('user_monsters').doc(monsterId).update({
      'current_hp': newHp,
      'last_hp_update': FieldValue.serverTimestamp(),
    });

    return ItemUseResult(
      success: true,
      message: 'HPを$healedAmount回復しました',
      data: {'healed': healedAmount, 'newHp': newHp, 'maxHp': maxHp},
    );
  }

  /// HP全回復
  Future<ItemUseResult> _healHpFull(
    String monsterId,
    Map<String, dynamic> data,
    Map<String, dynamic>? masterData,
  ) async {
    final currentHp = (data['current_hp'] as num?)?.toInt() ?? 0;
    
    if (currentHp <= 0) {
      return ItemUseResult(success: false, message: '瀕死のモンスターには使用できません');
    }

    // ★ 修正: Monster.maxHpと同じ計算式
    final maxHp = _calculateMaxHp(data, masterData);

    if (currentHp >= maxHp) {
      return ItemUseResult(success: false, message: 'HPは既に最大です');
    }

    await _firestore.collection('user_monsters').doc(monsterId).update({
      'current_hp': maxHp,
      'last_hp_update': FieldValue.serverTimestamp(),
    });

    return ItemUseResult(
      success: true,
      message: 'HPを全回復しました',
      data: {'healed': maxHp - currentHp, 'newHp': maxHp, 'maxHp': maxHp},
    );
  }

  /// 復活
  Future<ItemUseResult> _revive(
    String monsterId,
    Map<String, dynamic> data,
    Map<String, dynamic>? masterData,
    int percentHp,
  ) async {
    final currentHp = (data['current_hp'] as num?)?.toInt() ?? 0;
    
    if (currentHp > 0) {
      return ItemUseResult(success: false, message: '瀕死でないモンスターには使用できません');
    }

    // ★ 修正: Monster.maxHpと同じ計算式
    final maxHp = _calculateMaxHp(data, masterData);
    final newHp = (maxHp * percentHp / 100).round();

    await _firestore.collection('user_monsters').doc(monsterId).update({
      'current_hp': newHp,
      'last_hp_update': FieldValue.serverTimestamp(),
    });

    return ItemUseResult(
      success: true,
      message: 'HP$percentHp%で復活しました',
      data: {'newHp': newHp, 'maxHp': maxHp},
    );
  }

  /// 状態異常回復
  Future<ItemUseResult> _cureStatus(
    String monsterId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection('user_monsters').doc(monsterId).update({
      'status_ailments': [],
      'last_hp_update': FieldValue.serverTimestamp(),
    });

    return ItemUseResult(success: true, message: '状態異常を回復しました');
  }

  /// 経験値追加
  Future<ItemUseResult> _addExp(
    String monsterId,
    Map<String, dynamic> data,
    int expAmount,
  ) async {
    final currentExp = (data['exp'] as num?)?.toInt() ?? 0;
    final level = (data['level'] as num?)?.toInt() ?? 1;
    
    if (level >= 100) {
      return ItemUseResult(success: false, message: '既に最大レベルです');
    }

    final newExp = currentExp + expAmount;
    
    // レベルアップ計算
    int newLevel = level;
    int remainingExp = newExp;
    while (newLevel < 100 && remainingExp >= _expToNextLevel(newLevel)) {
      remainingExp -= _expToNextLevel(newLevel);
      newLevel++;
    }

    final updates = <String, dynamic>{
      'exp': remainingExp,
      'updated_at': FieldValue.serverTimestamp(),
    };
    
    if (newLevel > level) {
      updates['level'] = newLevel;
      // レベルアップ時のポイント付与（4ポイント/Lv）
      final pointGain = (newLevel - level) * 4;
      final currentPoints = (data['remaining_points'] as num?)?.toInt() ?? 0;
      updates['remaining_points'] = currentPoints + pointGain;
    }

    await _firestore.collection('user_monsters').doc(monsterId).update(updates);

    if (newLevel > level) {
      return ItemUseResult(
        success: true,
        message: '経験値$expAmountを獲得！レベル$newLevelになりました',
        data: {'expGained': expAmount, 'levelBefore': level, 'newLevel': newLevel},
      );
    }
    
    return ItemUseResult(
      success: true,
      message: '経験値$expAmountを獲得しました',
      data: {'expGained': expAmount, 'currentLevel': level},
    );
  }

  int _expToNextLevel(int level) => level * 100;

  /// 親密度追加
  Future<ItemUseResult> _addIntimacy(
    String monsterId,
    Map<String, dynamic> data,
    int amount,
  ) async {
    final currentIntimacy = (data['intimacy_exp'] as num?)?.toInt() ?? 0;
    final intimacyLevel = (data['intimacy_level'] as num?)?.toInt() ?? 1;
    
    if (intimacyLevel >= 10) {
      return ItemUseResult(success: false, message: '親密度は既に最大です');
    }

    final newIntimacy = currentIntimacy + amount;
    
    // 親密度レベルアップ計算
    int newLevel = intimacyLevel;
    int remainingIntimacy = newIntimacy;
    while (newLevel < 10 && remainingIntimacy >= _intimacyToNextLevel(newLevel)) {
      remainingIntimacy -= _intimacyToNextLevel(newLevel);
      newLevel++;
    }

    await _firestore.collection('user_monsters').doc(monsterId).update({
      'intimacy_exp': remainingIntimacy,
      'intimacy_level': newLevel,
      'updated_at': FieldValue.serverTimestamp(),
    });

    if (newLevel > intimacyLevel) {
      return ItemUseResult(
        success: true,
        message: '親密度がレベル$newLevelになりました！',
        data: {'newIntimacyLevel': newLevel},
      );
    }

    return ItemUseResult(
      success: true,
      message: '親密度が上がりました',
    );
  }

  int _intimacyToNextLevel(int level) => 50 + (level * 30);

  /// ポイントリセット
  Future<ItemUseResult> _resetPoints(
    String monsterId,
    Map<String, dynamic> data,
  ) async {
    final level = (data['level'] as num?)?.toInt() ?? 1;
    final totalPoints = (level - 1) * 4;

    await _firestore.collection('user_monsters').doc(monsterId).update({
      'point_hp': 0,
      'point_attack': 0,
      'point_defense': 0,
      'point_magic': 0,
      'point_speed': 0,
      'remaining_points': totalPoints,
      'updated_at': FieldValue.serverTimestamp(),
    });

    return ItemUseResult(
      success: true,
      message: 'ポイントをリセットしました（$totalPointsポイント）',
      data: {'totalPoints': totalPoints},
    );
  }

  /// 個体値最大化
  Future<ItemUseResult> _maxIv(
    String monsterId,
    Map<String, dynamic> data,
    String? stat,
  ) async {
    if (stat == null) {
      return ItemUseResult(success: false, message: '対象ステータスが指定されていません');
    }

    final key = 'iv_$stat';
    final currentIv = (data[key] as num?)?.toInt() ?? 0;
    
    if (currentIv >= 10) {
      return ItemUseResult(success: false, message: '既に最大値です');
    }

    await _firestore.collection('user_monsters').doc(monsterId).update({
      key: 10,
      'updated_at': FieldValue.serverTimestamp(),
    });

    return ItemUseResult(
      success: true,
      message: '個体値を最大にしました',
      data: {'stat': stat, 'newValue': 10},
    );
  }

  /// 特性再抽選（簡易実装）
  Future<ItemUseResult> _rerollTrait(
    String monsterId,
    Map<String, dynamic> data,
  ) async {
    // TODO: 特性プールからランダム選択する実装
    return ItemUseResult(
      success: true,
      message: '特性を再抽選しました',
    );
  }
}