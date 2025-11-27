// lib/core/services/crafting_service.dart
//
// 既存の lib/domain/entities/material.dart の MaterialMaster を使用

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/equipment_master.dart';
import '../../domain/entities/material.dart';
import '../../data/repositories/material_repository.dart';

/// 錬成結果
class CraftingResult {
  final bool success;
  final String message;
  final String? equipmentId;
  final int? newQuantity;

  const CraftingResult({
    required this.success,
    required this.message,
    this.equipmentId,
    this.newQuantity,
  });

  factory CraftingResult.success(String equipmentId, int newQuantity) {
    return CraftingResult(
      success: true,
      message: '錬成に成功しました！',
      equipmentId: equipmentId,
      newQuantity: newQuantity,
    );
  }

  factory CraftingResult.failure(String message) {
    return CraftingResult(
      success: false,
      message: message,
    );
  }
}

/// 錬成可否チェック結果
class CraftingAvailability {
  final bool canCraft;
  final bool hasEnoughGold;
  final bool hasEnoughCommonMaterials;
  final bool hasEnoughMonsterMaterials;
  final int currentGold;
  final int requiredGold;
  final int currentCommonMaterials;
  final int requiredCommonMaterials;
  final int currentMonsterMaterials;
  final int requiredMonsterMaterials;
  final List<MaterialShortage> shortages;

  const CraftingAvailability({
    required this.canCraft,
    required this.hasEnoughGold,
    required this.hasEnoughCommonMaterials,
    required this.hasEnoughMonsterMaterials,
    required this.currentGold,
    required this.requiredGold,
    required this.currentCommonMaterials,
    required this.requiredCommonMaterials,
    required this.currentMonsterMaterials,
    required this.requiredMonsterMaterials,
    this.shortages = const [],
  });

  factory CraftingAvailability.unavailable() {
    return const CraftingAvailability(
      canCraft: false,
      hasEnoughGold: false,
      hasEnoughCommonMaterials: false,
      hasEnoughMonsterMaterials: false,
      currentGold: 0,
      requiredGold: 0,
      currentCommonMaterials: 0,
      requiredCommonMaterials: 0,
      currentMonsterMaterials: 0,
      requiredMonsterMaterials: 0,
    );
  }
}

/// 素材不足情報
class MaterialShortage {
  final String materialId;
  final String materialName;
  final int required;
  final int current;
  final List<String> dropStages;

  const MaterialShortage({
    required this.materialId,
    required this.materialName,
    required this.required,
    required this.current,
    this.dropStages = const [],
  });

  int get shortage => required - current;
}

class CraftingService {
  final FirebaseFirestore _firestore;
  final MaterialRepository _materialRepository;

  CraftingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _materialRepository = MaterialRepository(firestore: firestore);

  /// 装備の錬成可否をチェック
  Future<CraftingAvailability> checkCraftingAvailability(
    String userId,
    EquipmentMaster equipment,
  ) async {
    try {
      // 錬成情報がない場合
      if (equipment.crafting == null) {
        return CraftingAvailability.unavailable();
      }

      final crafting = equipment.crafting!;
      final requiredGold = crafting['gold'] as int? ?? 0;
      final requiredCommon = crafting['common_materials'] as int? ?? 0;
      final requiredMonster = crafting['monster_materials'] as int? ?? 0;

      // ユーザーのゴールドを取得
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final currentGold = userDoc.data()?['gold'] as int? ?? 0;

      // ユーザーの素材を取得
      final userMaterials = await _materialRepository.getUserMaterials(userId);
      final masters = await _materialRepository.getMaterialMasters();

      // 汎用素材とモンスター素材のカウント
      int currentCommon = 0;
      int currentMonster = 0;

      for (final entry in userMaterials.entries) {
        final master = masters[entry.key];
        if (master != null) {
          final subCategory = master.subCategory;
          if (subCategory == 'common') {
            currentCommon += entry.value;
          } else if (subCategory == 'species' || 
                     subCategory == 'element' ||
                     subCategory == 'boss') {
            currentMonster += entry.value;
          }
        }
      }

      // 不足素材リスト
      final shortages = <MaterialShortage>[];
      
      if (currentGold < requiredGold) {
        shortages.add(MaterialShortage(
          materialId: 'gold',
          materialName: 'ゴールド',
          required: requiredGold,
          current: currentGold,
        ));
      }
      
      if (currentCommon < requiredCommon) {
        shortages.add(MaterialShortage(
          materialId: 'common_materials',
          materialName: '汎用素材',
          required: requiredCommon,
          current: currentCommon,
          dropStages: ['stage_1-1', 'stage_1-2', 'stage_1-3'],
        ));
      }
      
      if (currentMonster < requiredMonster) {
        shortages.add(MaterialShortage(
          materialId: 'monster_materials',
          materialName: 'モンスター素材',
          required: requiredMonster,
          current: currentMonster,
          dropStages: ['stage_2-1', 'stage_2-2', 'stage_3-1'],
        ));
      }

      final hasEnoughGold = currentGold >= requiredGold;
      final hasEnoughCommon = currentCommon >= requiredCommon;
      final hasEnoughMonster = currentMonster >= requiredMonster;
      final canCraft = hasEnoughGold && hasEnoughCommon && hasEnoughMonster;

      return CraftingAvailability(
        canCraft: canCraft,
        hasEnoughGold: hasEnoughGold,
        hasEnoughCommonMaterials: hasEnoughCommon,
        hasEnoughMonsterMaterials: hasEnoughMonster,
        currentGold: currentGold,
        requiredGold: requiredGold,
        currentCommonMaterials: currentCommon,
        requiredCommonMaterials: requiredCommon,
        currentMonsterMaterials: currentMonster,
        requiredMonsterMaterials: requiredMonster,
        shortages: shortages,
      );
    } catch (e) {
      print('Error checking crafting availability: $e');
      return CraftingAvailability.unavailable();
    }
  }

  /// 装備を錬成
  Future<CraftingResult> craftEquipment(
    String userId,
    EquipmentMaster equipment,
  ) async {
    try {
      // 錬成可否チェック
      final availability = await checkCraftingAvailability(userId, equipment);
      if (!availability.canCraft) {
        if (!availability.hasEnoughGold) {
          return CraftingResult.failure('ゴールドが不足しています');
        }
        if (!availability.hasEnoughCommonMaterials) {
          return CraftingResult.failure('汎用素材が不足しています');
        }
        if (!availability.hasEnoughMonsterMaterials) {
          return CraftingResult.failure('モンスター素材が不足しています');
        }
        return CraftingResult.failure('錬成に必要な素材が不足しています');
      }

      final crafting = equipment.crafting!;
      final requiredGold = crafting['gold'] as int? ?? 0;
      final requiredCommon = crafting['common_materials'] as int? ?? 0;
      final requiredMonster = crafting['monster_materials'] as int? ?? 0;

      // トランザクションで実行
      final result = await _firestore.runTransaction<CraftingResult>((transaction) async {
        // 1. ゴールド消費
        final userRef = _firestore.collection('users').doc(userId);
        final userDoc = await transaction.get(userRef);
        final currentGold = userDoc.data()?['gold'] as int? ?? 0;
        
        if (currentGold < requiredGold) {
          return CraftingResult.failure('ゴールドが不足しています');
        }
        
        transaction.update(userRef, {
          'gold': currentGold - requiredGold,
        });

        // 2. 素材消費（汎用素材とモンスター素材を消費）
        await _consumeMaterialsInTransaction(
          transaction,
          userId,
          requiredCommon,
          requiredMonster,
        );

        // 3. 装備を追加
        final equipmentRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('user_equipment')
            .doc(equipment.equipmentId);
        
        final equipDoc = await transaction.get(equipmentRef);
        int newQuantity = 1;
        
        if (equipDoc.exists) {
          final currentQuantity = equipDoc.data()?['quantity'] as int? ?? 0;
          newQuantity = currentQuantity + 1;
          transaction.update(equipmentRef, {
            'quantity': newQuantity,
            'updated_at': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.set(equipmentRef, {
            'equipment_id': equipment.equipmentId,
            'quantity': 1,
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          });
        }

        return CraftingResult.success(equipment.equipmentId, newQuantity);
      });

      return result;
    } catch (e) {
      print('Error crafting equipment: $e');
      return CraftingResult.failure('錬成に失敗しました: $e');
    }
  }

  /// トランザクション内で素材を消費
  Future<void> _consumeMaterialsInTransaction(
    Transaction transaction,
    String userId,
    int commonRequired,
    int monsterRequired,
  ) async {
    // ユーザーの素材を取得
    final materialsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('user_items')
        .get();

    final masters = await _materialRepository.getMaterialMasters();
    
    int commonRemaining = commonRequired;
    int monsterRemaining = monsterRequired;

    for (final doc in materialsSnapshot.docs) {
      if (commonRemaining <= 0 && monsterRemaining <= 0) break;

      final data = doc.data();
      final itemId = data['item_id'] as String? ?? doc.id;
      final quantity = data['quantity'] as int? ?? 0;
      final master = masters[itemId];

      if (master == null || quantity <= 0) continue;

      int consumed = 0;
      final subCategory = master.subCategory;

      if (subCategory == 'common' && commonRemaining > 0) {
        consumed = quantity >= commonRemaining ? commonRemaining : quantity;
        commonRemaining -= consumed;
      } else if ((subCategory == 'species' || 
                  subCategory == 'element' ||
                  subCategory == 'boss') && 
                 monsterRemaining > 0) {
        consumed = quantity >= monsterRemaining ? monsterRemaining : quantity;
        monsterRemaining -= consumed;
      }

      if (consumed > 0) {
        transaction.update(doc.reference, {
          'quantity': quantity - consumed,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  /// ユーザーの所持装備数を取得
  Future<Map<String, int>> getUserEquipmentQuantities(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('user_equipment')
          .get();

      final quantities = <String, int>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final equipmentId = data['equipment_id'] as String? ?? doc.id;
        final quantity = data['quantity'] as int? ?? 0;
        quantities[equipmentId] = quantity;
      }
      return quantities;
    } catch (e) {
      print('Error getting user equipment quantities: $e');
      return {};
    }
  }

  /// ユーザーのゴールドを取得
  Future<int> getUserGold(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data()?['gold'] as int? ?? 0;
    } catch (e) {
      print('Error getting user gold: $e');
      return 0;
    }
  }

  /// 汎用素材の合計を取得
  Future<int> getTotalCommonMaterials(String userId) async {
    try {
      final userMaterials = await _materialRepository.getUserMaterials(userId);
      final masters = await _materialRepository.getMaterialMasters();
      
      int total = 0;
      for (final entry in userMaterials.entries) {
        final master = masters[entry.key];
        if (master != null && master.subCategory == 'common') {
          total += entry.value;
        }
      }
      return total;
    } catch (e) {
      print('Error getting common materials: $e');
      return 0;
    }
  }

  /// モンスター素材の合計を取得
  Future<int> getTotalMonsterMaterials(String userId) async {
    try {
      final userMaterials = await _materialRepository.getUserMaterials(userId);
      final masters = await _materialRepository.getMaterialMasters();
      
      int total = 0;
      for (final entry in userMaterials.entries) {
        final master = masters[entry.key];
        if (master != null && 
            (master.subCategory == 'species' || 
             master.subCategory == 'element' ||
             master.subCategory == 'boss')) {
          total += entry.value;
        }
      }
      return total;
    } catch (e) {
      print('Error getting monster materials: $e');
      return 0;
    }
  }
}