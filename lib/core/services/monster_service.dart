import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/monster_model.dart';
import '../models/monster_filter.dart';
import '../../domain/entities/monster.dart';

/// モンスター管理サービス
/// 
/// Firestoreの user_monsters と monster_masters コレクションを操作します。
class MonsterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ユーザーの所持モンスター一覧を取得
  Future<List<Monster>> getUserMonsters(
    String userId, {
    MonsterFilter? filter,
    MonsterSortType sortType = MonsterSortType.levelDesc,
  }) async {
    try {
      // user_monstersコレクションからユーザーのモンスターを取得
      Query<Map<String, dynamic>> query = _firestore
          .collection('user_monsters')
          .where('user_id', isEqualTo: userId);

      // Firestoreクエリで可能なフィルタリング
      if (filter != null) {
        // お気に入りフィルター
        if (filter.favoriteOnly == true) {
          query = query.where('is_favorite', isEqualTo: true);
        }

        // ロックフィルター
        if (filter.lockedOnly == true) {
          query = query.where('is_locked', isEqualTo: true);
        }

        // レアリティフィルター（monster_mastersから取得後にフィルタ）
        // 種族フィルター（monster_mastersから取得後にフィルタ）
        // 属性フィルター（monster_mastersから取得後にフィルタ）
      }

      final snapshot = await query.get();

      // モンスターマスタデータを一括取得
      final monsterIds = snapshot.docs
          .map((doc) => doc.data()['monster_id'] as String?)
          .where((id) => id != null)
          .toSet()
          .toList();

      final masterDataMap = await _getMonsterMasterData(
        monsterIds.whereType<String>().toList(),
        );

      // Monsterエンティティに変換
      List<Monster> monsters = snapshot.docs.map((doc) {
        final monsterId = doc.data()['monster_id'] as String?;
        final masterData = masterDataMap[monsterId];
        return MonsterModel.fromFirestore(doc, masterData);
      }).toList();

      // アプリ側でのフィルタリング
      if (filter != null) {
        monsters = _applyFilter(monsters, filter);
      }

      // ソート
      monsters = _applySort(monsters, sortType);

      return monsters;
    } catch (e) {
      print('Error getting user monsters: $e');
      rethrow;
    }
  }

  /// モンスターマスタデータを取得
  Future<Map<String, Map<String, dynamic>>> _getMonsterMasterData(
    List<String> monsterIds,
  ) async {
    if (monsterIds.isEmpty) return {};

    try {
      final Map<String, Map<String, dynamic>> masterDataMap = {};

      // 一括取得（Firestoreの制限により10件ずつ）
      for (int i = 0; i < monsterIds.length; i += 10) {
        final batch = monsterIds.skip(i).take(10).toList();
        final snapshot = await _firestore
            .collection('monster_masters')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (var doc in snapshot.docs) {
          masterDataMap[doc.id] = doc.data();
        }
      }

      return masterDataMap;
    } catch (e) {
      print('Error getting monster master data: $e');
      return {};
    }
  }

  /// フィルターを適用
  List<Monster> _applyFilter(List<Monster> monsters, MonsterFilter filter) {
    return monsters.where((monster) {
      // 種族フィルター（大文字・小文字を区別しない）
      if (filter.species != null && 
          monster.species.toLowerCase() != filter.species!.toLowerCase()) {
        return false;
      }

      // 属性フィルター（大文字・小文字を区別しない）
      if (filter.element != null && 
          monster.element.toLowerCase() != filter.element!.toLowerCase()) {
        return false;
      }

      // レアリティフィルター
      if (filter.rarity != null && monster.rarity != filter.rarity) {
        return false;
      }

      // 検索キーワード
      if (filter.searchKeyword != null && filter.searchKeyword!.isNotEmpty) {
        final keyword = filter.searchKeyword!.toLowerCase();
        final name = monster.monsterName.toLowerCase();
        if (!name.contains(keyword)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// ソートを適用
  List<Monster> _applySort(List<Monster> monsters, MonsterSortType sortType) {
    final sorted = List<Monster>.from(monsters);

    switch (sortType) {
      case MonsterSortType.levelDesc:
        sorted.sort((a, b) => b.level.compareTo(a.level));
        break;

      case MonsterSortType.levelAsc:
        sorted.sort((a, b) => a.level.compareTo(b.level));
        break;

      case MonsterSortType.rarityDesc:
        sorted.sort((a, b) {
          final rarityCompare = b.rarity.compareTo(a.rarity);
          if (rarityCompare != 0) return rarityCompare;
          return b.level.compareTo(a.level); // レアリティが同じならレベル降順
        });
        break;

      case MonsterSortType.rarityAsc:
        sorted.sort((a, b) {
          final rarityCompare = a.rarity.compareTo(b.rarity);
          if (rarityCompare != 0) return rarityCompare;
          return a.level.compareTo(b.level); // レアリティが同じならレベル昇順
        });
        break;

      case MonsterSortType.acquiredDesc:
        sorted.sort((a, b) => b.acquiredAt.compareTo(a.acquiredAt));
        break;

      case MonsterSortType.acquiredAsc:
        sorted.sort((a, b) => a.acquiredAt.compareTo(b.acquiredAt));
        break;

      case MonsterSortType.favoriteFirst:
        sorted.sort((a, b) {
          if (a.isFavorite && !b.isFavorite) return -1;
          if (!a.isFavorite && b.isFavorite) return 1;
          return b.level.compareTo(a.level); // お気に入り状態が同じならレベル降順
        });
        break;

      case MonsterSortType.nameAsc:
        sorted.sort((a, b) => a.monsterName.compareTo(b.monsterName));
        break;

      case MonsterSortType.nameDesc:
        sorted.sort((a, b) => b.monsterName.compareTo(a.monsterName));
        break;
    }

    return sorted;
  }

  /// モンスター詳細を取得
  Future<Monster?> getMonsterById(String monsterId) async {
    try {
      final doc = await _firestore.collection('user_monsters').doc(monsterId).get();

      if (!doc.exists) {
        return null;
      }

      // モンスターマスタデータを取得
      final userMonsterData = doc.data()!;
      final masterMonsterId = userMonsterData['monster_id'] as String?;

      Map<String, dynamic>? masterData;
      if (masterMonsterId != null) {
        final masterDoc =
            await _firestore.collection('monster_masters').doc(masterMonsterId).get();
        if (masterDoc.exists) {
          masterData = masterDoc.data();
        }
      }

      return MonsterModel.fromFirestore(doc, masterData);
    } catch (e) {
      print('Error getting monster by id: $e');
      return null;
    }
  }

  /// お気に入り状態を更新
  Future<void> toggleFavorite(String monsterId, bool isFavorite) async {
    try {
      await _firestore.collection('user_monsters').doc(monsterId).update({
        'is_favorite': isFavorite,
      });
    } catch (e) {
      print('Error toggling favorite: $e');
      rethrow;
    }
  }

  /// ロック状態を更新
  Future<void> toggleLock(String monsterId, bool isLocked) async {
    try {
      await _firestore.collection('user_monsters').doc(monsterId).update({
        'is_locked': isLocked,
      });
    } catch (e) {
      print('Error toggling lock: $e');
      rethrow;
    }
  }

  /// モンスターのHPを更新
  Future<void> updateMonsterHp(String monsterId, int newHp) async {
    try {
      await _firestore.collection('user_monsters').doc(monsterId).update({
        'current_hp': newHp,
        'last_hp_update': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating monster HP: $e');
      rethrow;
    }
  }

  /// モンスターのHPを全回復
  Future<void> healMonster(String monsterId, int maxHp) async {
    try {
      await _firestore.collection('user_monsters').doc(monsterId).update({
        'current_hp': maxHp,
        'last_hp_update': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error healing monster: $e');
      rethrow;
    }
  }

  /// ユーザーの所持モンスター数を取得
  Future<int> getMonsterCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('user_monsters')
          .where('user_id', isEqualTo: userId)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting monster count: $e');
      return 0;
    }
  }

    /// テスト用: ダミーモンスターを生成
    Future<int> createDummyMonsters({
      required String userId,
      required int count,
    }) async {
      final masters = await _firestore
          .collection('monster_masters')
          .limit(count)
          .get();

      if (masters.docs.isEmpty) return 0;

      final batch = _firestore.batch();
      final now = FieldValue.serverTimestamp();

      for (var i = 0; i < count; i++) {
        final masterSnap = masters.docs[i % masters.docs.length];
        final masterId = masterSnap.id;
        final master = masterSnap.data();

        // 既存仕様に合わせて適当にばらつきを出す例
        final level   = 1 + (i % 50);
        final ivHp    = ((i * 3) % 21) - 10; // -10〜+10
        final pointHp = ((i * 7) % 32);      // 0〜31

        final baseHp  = _getBaseHpFromMaster(master);
        final growth  = _getGrowthHpFromMaster(master); // 無ければ 0

        final currentHp = _calcInitialHp(
          baseHp: baseHp,
          ivHp: ivHp,
          pointHp: pointHp,
          level: level,
          growthHpPerLevel: growth,
        );

        final newDoc = _firestore.collection('user_monsters').doc();
        final data = {
          'user_id': userId,
          'monster_id': masterId,
          'level': level,
          'exp': 0,
          'iv_hp': ivHp,
          'point_hp': pointHp,
          'current_hp': currentHp,   // ← 100 固定を廃止
          'last_hp_update': now,
          'created_at': now,
          'updated_at': now,
          'is_favorite': false,
          'is_locked': false,
        };

        batch.set(newDoc, data);
      }

      await batch.commit();
      return count;
    }

    // ───────────────────── ヘルパ ─────────────────────

    int _getBaseHpFromMaster(Map<String, dynamic> master) {
      final baseStats = master['base_stats'] as Map<String, dynamic>?;
      final hp1 = (baseStats?['hp'] as num?)?.toInt();
      if (hp1 != null) return hp1;

      final hp2 = (master['baseHp'] as num?)?.toInt();
      return hp2 ?? 100; // 最終フォールバック
    }

    int _getGrowthHpFromMaster(Map<String, dynamic> master) {
      final growth = master['growth'] as Map<String, dynamic>?;
      final g1 = (growth?['hp'] as num?)?.toInt();
      if (g1 != null) return g1;

      final g2 = (master['growthHp'] as num?)?.toInt();
      return g2 ?? 0;
    }

    int _calcInitialHp({
      required int baseHp,
      required int ivHp,
      required int pointHp,
      required int level,
      required int growthHpPerLevel,
    }) {
      final lvBonus = (level > 1) ? growthHpPerLevel * (level - 1) : 0;
      final hp = baseHp + ivHp + pointHp + lvBonus;
      return hp < 1 ? 1 : hp; // 簡易クランプ
    }
  }
