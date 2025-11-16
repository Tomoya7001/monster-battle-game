import 'package:cloud_firestore/cloud_firestore.dart';

class MasterDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> insertDummySkillData() async {
    final skills = [
      {'skill_id': 'skill_001', 'name': 'ファイアボール', 'element': 'fire', 'cost': 2, 'power': 80, 'accuracy': 95, 'type': 'attack'},
      {'skill_id': 'skill_002', 'name': 'アクアショット', 'element': 'water', 'cost': 2, 'power': 75, 'accuracy': 100, 'type': 'attack'},
      {'skill_id': 'skill_003', 'name': 'サンダーボルト', 'element': 'thunder', 'cost': 3, 'power': 120, 'accuracy': 85, 'type': 'attack'},
      {'skill_id': 'skill_004', 'name': 'ヒール', 'element': 'light', 'cost': 2, 'power': 0, 'accuracy': 100, 'type': 'heal', 'heal_amount': 50},
      {'skill_id': 'skill_005', 'name': '攻撃強化', 'element': 'none', 'cost': 1, 'power': 0, 'accuracy': 100, 'type': 'buff', 'buff_stat': 'attack', 'buff_amount': 20},
      {'skill_id': 'skill_006', 'name': '防御強化', 'element': 'none', 'cost': 1, 'power': 0, 'accuracy': 100, 'type': 'buff', 'buff_stat': 'defense', 'buff_amount': 20},
      {'skill_id': 'skill_007', 'name': 'ダークスラッシュ', 'element': 'dark', 'cost': 3, 'power': 110, 'accuracy': 90, 'type': 'attack'},
      {'skill_id': 'skill_008', 'name': 'ウインドカッター', 'element': 'wind', 'cost': 2, 'power': 70, 'accuracy': 100, 'type': 'attack'},
      {'skill_id': 'skill_009', 'name': 'アースクエイク', 'element': 'earth', 'cost': 4, 'power': 150, 'accuracy': 80, 'type': 'attack'},
      {'skill_id': 'skill_010', 'name': 'ホーリーレイ', 'element': 'light', 'cost': 5, 'power': 200, 'accuracy': 75, 'type': 'attack'},
    ];

    final batch = _firestore.batch();
    for (var skill in skills) {
      final docRef = _firestore.collection('skill_masters').doc(skill['skill_id'] as String);
      batch.set(docRef, skill);
    }
    await batch.commit();
  }

  Future<void> insertDummyTraitData() async {
    final traits = [
      {'trait_id': 'trait_001', 'name': '猛火', 'description': 'HP30%以下で炎技1.3倍', 'type': 'main'},
      {'trait_id': 'trait_002', 'name': '激流', 'description': 'HP30%以下で水技1.3倍', 'type': 'main'},
      {'trait_id': 'trait_003', 'name': '新緑', 'description': 'HP30%以下で草技1.3倍', 'type': 'main'},
      {'trait_id': 'trait_004', 'name': '攻撃+5%', 'description': '攻撃力が5%上昇', 'type': 'sub'},
      {'trait_id': 'trait_005', 'name': '防御+5%', 'description': '防御力が5%上昇', 'type': 'sub'},
      {'trait_id': 'trait_006', 'name': 'HP+10%', 'description': '最大HPが10%上昇', 'type': 'sub'},
      {'trait_id': 'trait_007', 'name': 'クリティカル+10%', 'description': 'クリティカル率+10%', 'type': 'sub'},
      {'trait_id': 'trait_008', 'name': '先制攻撃', 'description': '先制攻撃時ダメージ1.2倍', 'type': 'sub'},
      {'trait_id': 'trait_009', 'name': '状態異常耐性', 'description': '状態異常になりにくい', 'type': 'sub'},
      {'trait_id': 'trait_010', 'name': '回避+10%', 'description': '回避率が10%上昇', 'type': 'sub'},
    ];

    final batch = _firestore.batch();
    for (var trait in traits) {
      final docRef = _firestore.collection('trait_masters').doc(trait['trait_id'] as String);
      batch.set(docRef, trait);
    }
    await batch.commit();
  }
}