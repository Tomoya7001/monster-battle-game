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
      print('📊 ドキュメントID: ${doc.id}');
      print('📊 データ: ${doc.data()}');
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
    
    // Dart側でソート
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
    return UserAdventureProgress.fromJson(doc.data()!);
  }

  /// 進行状況更新
  Future<void> updateProgress(UserAdventureProgress progress) async {
    await _firestore
        .collection('user_adventure_progress')
        .doc('${progress.userId}_${progress.stageId}')
        .set(progress.toJson());
  }

  /// エンカウント回数増加
  Future<void> incrementEncounterCount(String userId, String stageId) async {
    final docRef = _firestore
        .collection('user_adventure_progress')
        .doc('${userId}_$stageId');

    final doc = await docRef.get();
    
    if (doc.exists) {
      final progress = UserAdventureProgress.fromJson(doc.data()!);
      final stage = await getStage(stageId);
      
      final newCount = progress.encounterCount + 1;
      final bossUnlocked = stage?.encountersToBoss != null && 
                          newCount >= stage!.encountersToBoss!;
      
      await docRef.set(progress.copyWith(
        encounterCount: newCount,
        bossUnlocked: bossUnlocked,
        lastUpdated: DateTime.now(),
      ).toJson());
    } else {
      await docRef.set(UserAdventureProgress(
        userId: userId,
        stageId: stageId,
        encounterCount: 1,
        bossUnlocked: false,
        lastUpdated: DateTime.now(),
      ).toJson());
    }
  }

  /// ボスステージクリア時にカウントリセット
  Future<void> resetEncounterCount(String userId, String stageId) async {
    final docRef = _firestore
        .collection('user_adventure_progress')
        .doc('${userId}_$stageId');

    await docRef.set(UserAdventureProgress(
      userId: userId,
      stageId: stageId,
      encounterCount: 0,
      bossUnlocked: false,
      lastUpdated: DateTime.now(),
    ).toJson());
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
    return Monster(
      id: randomId,
      userId: 'enemy',
      monsterId: randomId,
      monsterName: data['name'] as String,
      species: data['species'] as String,
      element: data['element'] as String,
      rarity: data['rarity'] as int,
      level: 50,
      exp: 0,
      currentHp: data['base_hp'] as int,
      lastHpUpdate: DateTime.now(),
      acquiredAt: DateTime.now(),
      baseHp: data['base_hp'] as int,
      baseAttack: data['base_attack'] as int,
      baseDefense: data['base_defense'] as int,
      baseMagic: data['base_magic'] as int,
      baseSpeed: data['base_speed'] as int,
      equippedSkills: List<String>.from(data['equipped_skills'] ?? []),
    );
  }

  /// ボスモンスター取得（3体）
  Future<List<Monster>> getBossMonsters(String stageId) async {
    final stage = await getStage(stageId);
    if (stage == null || stage.bossMonsterIds == null) return [];

    final monsters = <Monster>[];
    for (final monsterId in stage.bossMonsterIds!) {
      final doc = await _firestore
          .collection('monster_masters')
          .doc(monsterId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        monsters.add(Monster(
          id: monsterId,
          userId: 'boss',
          monsterId: monsterId,
          monsterName: data['name'] as String,
          species: data['species'] as String,
          element: data['element'] as String,
          rarity: data['rarity'] as int,
          level: 50,
          exp: 0,
          currentHp: data['base_hp'] as int,
          lastHpUpdate: DateTime.now(),
          acquiredAt: DateTime.now(),
          baseHp: data['base_hp'] as int,
          baseAttack: data['base_attack'] as int,
          baseDefense: data['base_defense'] as int,
          baseMagic: data['base_magic'] as int,
          baseSpeed: data['base_speed'] as int,
          equippedSkills: List<String>.from(data['equipped_skills'] ?? []),
        ));
      }
    }

    return monsters;
  }
}