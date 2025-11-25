import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/stage/stage_data.dart';
import '../../domain/entities/monster.dart';

class AdventureRepository {
  final FirebaseFirestore _firestore;

  AdventureRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 全ステージ取得
  Future<List<StageData>> getAllStages() async {
    final snapshot = await _firestore
        .collection('stage_masters')
        .get();

    print('📊 取得ドキュメント数: ${snapshot.docs.length}');
    
    final stages = <StageData>[];
    for (final doc in snapshot.docs) {
      try {
        stages.add(StageData.fromJson(doc.data()));
      } catch (e) {
        print('❌ パースエラー: $e');
      }
    }
    
    stages.sort((a, b) => a.difficulty.compareTo(b.difficulty));
    return stages;
  }

  /// 通常ステージ一覧取得
  Future<List<StageData>> getNormalStages() async {
    final snapshot = await _firestore
        .collection('stage_masters')
        .where('stage_type', isEqualTo: 'normal')
        .get();

    final stages = snapshot.docs
        .map((doc) => StageData.fromJson(doc.data()))
        .toList();
    
    stages.sort((a, b) => a.difficulty.compareTo(b.difficulty));
    return stages;
  }

  /// ステージ取得
  Future<StageData?> getStage(String stageId) async {
    final doc = await _firestore
        .collection('stage_masters')
        .doc(stageId)
        .get();

    if (!doc.exists) return null;
    return StageData.fromJson(doc.data()!);
  }

  /// 進行状況取得
  Future<UserAdventureProgress?> getProgress(String userId, String stageId) async {
    final doc = await _firestore
        .collection('user_adventure_progress')
        .doc('${userId}_$stageId')
        .get();

    if (!doc.exists) return null;
    
    final data = doc.data()!;
    return UserAdventureProgress(
      userId: data['user_id'] as String? ?? userId,
      stageId: data['stage_id'] as String? ?? stageId,
      encounterCount: data['encounter_count'] as int? ?? 0,
      bossUnlocked: data['boss_unlocked'] as bool? ?? false,
      lastUpdated: (data['last_updated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// 進行状況更新
  Future<void> updateProgress(UserAdventureProgress progress) async {
    await _firestore
        .collection('user_adventure_progress')
        .doc('${progress.userId}_${progress.stageId}')
        .set({
          'user_id': progress.userId,
          'stage_id': progress.stageId,
          'encounter_count': progress.encounterCount,
          'boss_unlocked': progress.bossUnlocked,
          'last_updated': FieldValue.serverTimestamp(),
        });
  }

  /// ★修正: エンカウント回数増加（5/5 max対応）
  Future<void> incrementEncounterCount(String userId, String stageId) async {
    final docRef = _firestore
        .collection('user_adventure_progress')
        .doc('${userId}_$stageId');

    final doc = await docRef.get();
    final stage = await getStage(stageId);
    final encountersToBoss = stage?.encountersToBoss ?? 5;
    
    if (doc.exists) {
      final data = doc.data()!;
      final currentCount = data['encounter_count'] as int? ?? 0;
      
      // ★修正: maxを超えないように
      final newCount = (currentCount + 1).clamp(0, encountersToBoss);
      final bossUnlocked = newCount >= encountersToBoss;
      
      await docRef.set({
        'user_id': userId,
        'stage_id': stageId,
        'encounter_count': newCount,
        'boss_unlocked': bossUnlocked,
        'last_updated': FieldValue.serverTimestamp(),
      });
    } else {
      await docRef.set({
        'user_id': userId,
        'stage_id': stageId,
        'encounter_count': 1,
        'boss_unlocked': false,
        'last_updated': FieldValue.serverTimestamp(),
      });
    }
  }

  /// ★追加: ボスクリア時に進行状況リセット
  Future<void> resetProgressAfterBossClear(String userId, String stageId) async {
    final docRef = _firestore
        .collection('user_adventure_progress')
        .doc('${userId}_$stageId');

    await docRef.set({
      'user_id': userId,
      'stage_id': stageId,
      'encounter_count': 0,
      'boss_unlocked': false,
      'last_updated': FieldValue.serverTimestamp(),
    });
  }

  /// ランダムエンカウントモンスター取得
  Future<Monster?> getRandomEncounterMonster(String stageId) async {
    final stage = await getStage(stageId);
    if (stage == null || stage.encounterMonsterIds == null) return null;

    final monsterIds = stage.encounterMonsterIds!;
    if (monsterIds.isEmpty) return null;

    final randomId = monsterIds[DateTime.now().millisecondsSinceEpoch % monsterIds.length];
    
    final doc = await _firestore
        .collection('monster_masters')
        .doc(randomId)
        .get();

    if (!doc.exists) return null;
    
    final data = doc.data()!;
    final baseStats = data['base_stats'] as Map<String, dynamic>? ?? {};
    final attributes = data['attributes'] as List<dynamic>? ?? [];

    return Monster(
      id: 'enemy_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'enemy',
      monsterId: randomId,
      monsterName: data['name'] as String? ?? 'Unknown',
      species: data['species'] as String? ?? 'unknown',
      element: attributes.isNotEmpty ? (attributes[0] as String).toLowerCase() : 'none',
      rarity: data['rarity'] as int? ?? 2,
      level: 50,
      exp: 0,
      currentHp: (baseStats['hp'] as num?)?.toInt() ?? 100,
      lastHpUpdate: DateTime.now(),
      acquiredAt: DateTime.now(),
      baseHp: (baseStats['hp'] as num?)?.toInt() ?? 100,
      baseAttack: (baseStats['attack'] as num?)?.toInt() ?? 50,
      baseDefense: (baseStats['defense'] as num?)?.toInt() ?? 50,
      baseMagic: (baseStats['magic'] as num?)?.toInt() ?? 50,
      baseSpeed: (baseStats['speed'] as num?)?.toInt() ?? 50,
      equippedSkills: List<String>.from(data['learnable_skills'] ?? []),
    );
  }

  /// ボスモンスター取得（最大3体）
  Future<List<Monster>> getBossMonsters(String stageId) async {
    print('🔍 getBossMonsters: stageId = $stageId');
    
    final stage = await getStage(stageId);
    if (stage == null) {
      print('❌ ステージが見つかりません: $stageId');
      return [];
    }
    
    print('📊 ステージデータ: ${stage.name}, bossMonsterIds = ${stage.bossMonsterIds}');
    
    if (stage.bossMonsterIds == null || stage.bossMonsterIds!.isEmpty) {
      print('❌ bossMonsterIdsが空です');
      return [];
    }

    final monsters = <Monster>[];
    for (final monsterId in stage.bossMonsterIds!) {
      print('🔍 ボスモンスター取得中: $monsterId');
      
      final doc = await _firestore
          .collection('monster_masters')
          .doc(monsterId)
          .get();

      if (!doc.exists) {
        print('❌ モンスターが見つかりません: $monsterId');
        continue;
      }

      final data = doc.data()!;
      print('✅ モンスターデータ取得: ${data['name']}');
      
      final baseStats = data['base_stats'] as Map<String, dynamic>? ?? {};
      final attributes = data['attributes'] as List<dynamic>? ?? [];

      monsters.add(Monster(
        id: 'boss_${monsterId}_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'boss',
        monsterId: monsterId,
        monsterName: data['name'] as String? ?? 'Unknown Boss',
        species: data['species'] as String? ?? 'unknown',
        element: attributes.isNotEmpty ? (attributes[0] as String).toLowerCase() : 'none',
        rarity: data['rarity'] as int? ?? 4,
        level: 50,
        exp: 0,
        currentHp: (baseStats['hp'] as num?)?.toInt() ?? 150,
        lastHpUpdate: DateTime.now(),
        acquiredAt: DateTime.now(),
        baseHp: (baseStats['hp'] as num?)?.toInt() ?? 150,
        baseAttack: (baseStats['attack'] as num?)?.toInt() ?? 80,
        baseDefense: (baseStats['defense'] as num?)?.toInt() ?? 80,
        baseMagic: (baseStats['magic'] as num?)?.toInt() ?? 80,
        baseSpeed: (baseStats['speed'] as num?)?.toInt() ?? 80,
        equippedSkills: List<String>.from(data['learnable_skills'] ?? []),
      ));
    }

    print('✅ getBossMonsters 完了: ${monsters.length}体取得');
    return monsters;
  }
}