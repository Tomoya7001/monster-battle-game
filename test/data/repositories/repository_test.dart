import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:monster_battle_game/data/repositories/monster_repository_impl.dart';
import 'package:monster_battle_game/domain/entities/monster.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late MonsterRepositoryImpl repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = MonsterRepositoryImpl(firestore);
  });

  group('MonsterRepository Tests', () {
    test('createMonster should add monster to Firestore', () async {
      // Arrange
      final monster = Monster(
        id: 'test_1',
        masterId: 'monster_001',
        userId: 'user_123',
        name: 'テストドラゴン',
        level: 1,
        exp: 0,
        species: 'dragon', // ← 修正
        element: 'fire',   // ← 修正
        rarity: 5,
        hp: 100,
        maxHp: 100,
        attack: 80,
        defense: 60,
        magic: 70,
        speed: 90,
        ivHp: 5,
        ivAttack: 8,
        ivDefense: 3,
        ivMagic: 6,
        ivSpeed: 10,
        pointHp: 0,
        pointAttack: 0,
        pointDefense: 0,
        pointMagic: 0,
        pointSpeed: 0,
        remainingPoints: 0,
        skillIds: [],
        mainAbilityId: 'ability_001',
        subAbilityId: null,
        equipmentIds: [],
        acquiredAt: DateTime.now(),
        lastBattleAt: null,
        inParty: false,
        partySlot: null,
        isFavorite: false,
        isLocked: false,
      );

      // Act
      await repository.createMonster(monster);

      // Assert
      final doc = await firestore
          .collection('monsters')
          .doc('test_1')
          .get();
      expect(doc.exists, true);
      expect(doc.data()?['name'], 'テストドラゴン');
      expect(doc.data()?['species'], 'dragon');
      expect(doc.data()?['element'], 'fire');
    });

    test('getMonster should return monster from Firestore', () async {
      // Arrange
      final monsterData = {
        'id': 'test_1',
        'masterId': 'monster_001',
        'userId': 'user_123',
        'name': 'テストエンジェル',
        'level': 10,
        'exp': 500,
        'species': 'angel',
        'element': 'light',
        'rarity': 4,
        'hp': 120,
        'maxHp': 150,
        'attack': 60,
        'defense': 70,
        'magic': 90,
        'speed': 65,
        'ivHp': 7,
        'ivAttack': 4,
        'ivDefense': 9,
        'ivMagic': 10,
        'ivSpeed': 5,
        'pointHp': 10,
        'pointAttack': 5,
        'pointDefense': 15,
        'pointMagic': 20,
        'pointSpeed': 8,
        'remainingPoints': 2,
        'skillIds': ['skill_001', 'skill_002'],
        'mainAbilityId': 'ability_002',
        'subAbilityId': 'ability_003',
        'equipmentIds': ['equip_001'],
        'acquiredAt': DateTime.now().toIso8601String(),
        'lastBattleAt': null,
        'inParty': true,
        'partySlot': 0,
        'isFavorite': true,
        'isLocked': false,
      };
      await firestore.collection('monsters').doc('test_1').set(monsterData);

      // Act
      final monster = await repository.getMonster('test_1');

      // Assert
      expect(monster, isNotNull);
      expect(monster?.name, 'テストエンジェル');
      expect(monster?.species, 'angel');
      expect(monster?.element, 'light');
      expect(monster?.level, 10);
      expect(monster?.rarity, 4);
    });
  });
}