// lib/domain/entities/material.dart

import 'package:flutter/material.dart';

/// 素材マスターエンティティ
class MaterialMaster {
  final String materialId;
  final String name;
  final String nameEn;
  final String category; // common, element, species, boss
  final String subCategory;
  final int rarity;
  final String description;
  final String icon;
  final int sellPrice;
  final List<String> dropStages;
  final int dropRate;

  const MaterialMaster({
    required this.materialId,
    required this.name,
    this.nameEn = '',
    required this.category,
    this.subCategory = '',
    required this.rarity,
    this.description = '',
    this.icon = '',
    this.sellPrice = 0,
    this.dropStages = const [],
    this.dropRate = 0,
  });

  factory MaterialMaster.fromJson(Map<String, dynamic> json) {
    return MaterialMaster(
      materialId: json['item_id']?.toString() ?? json['material_id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      category: json['category'] as String? ?? 'common',
      subCategory: json['sub_category'] as String? ?? '',
      rarity: json['rarity'] as int? ?? 1,
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      sellPrice: json['sell_price'] as int? ?? 0,
      dropStages: (json['drop_stages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      dropRate: json['drop_rate'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'material_id': materialId,
      'name': name,
      'name_en': nameEn,
      'category': category,
      'sub_category': subCategory,
      'rarity': rarity,
      'description': description,
      'icon': icon,
      'sell_price': sellPrice,
      'drop_stages': dropStages,
      'drop_rate': dropRate,
    };
  }

  Color get rarityColor {
    switch (rarity) {
      case 5:
        return const Color(0xFFFFD700); // Gold
      case 4:
        return const Color(0xFF9B59B6); // Purple
      case 3:
        return const Color(0xFF3498DB); // Blue
      case 2:
        return const Color(0xFF27AE60); // Green
      case 1:
      default:
        return const Color(0xFF95A5A6); // Gray
    }
  }

  String get rarityStars => '★' * rarity;

  String get categoryName {
    switch (category) {
      case 'common':
        return '汎用素材';
      case 'element':
        return '属性素材';
      case 'species':
        return '種族素材';
      case 'boss':
        return 'ボス素材';
      default:
        return '素材';
    }
  }

  IconData get categoryIcon {
    switch (category) {
      case 'common':
        return Icons.inventory_2;
      case 'element':
        return Icons.auto_awesome;
      case 'species':
        return Icons.pets;
      case 'boss':
        return Icons.emoji_events;
      default:
        return Icons.help_outline;
    }
  }
}

/// ユーザー所持素材
class UserMaterial {
  final String id;
  final String userId;
  final String materialId;
  final int quantity;
  final DateTime? updatedAt;

  const UserMaterial({
    required this.id,
    required this.userId,
    required this.materialId,
    required this.quantity,
    this.updatedAt,
  });

  factory UserMaterial.fromFirestore(String docId, Map<String, dynamic> data) {
    return UserMaterial(
      id: docId,
      userId: data['user_id'] as String? ?? '',
      materialId: data['material_id'] as String? ?? data['item_id'] as String? ?? '',
      quantity: data['quantity'] as int? ?? 0,
      updatedAt: data['updated_at'] != null
          ? (data['updated_at'] as dynamic).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'material_id': materialId,
      'quantity': quantity,
      'updated_at': DateTime.now(),
    };
  }

  UserMaterial copyWith({
    String? id,
    String? userId,
    String? materialId,
    int? quantity,
    DateTime? updatedAt,
  }) {
    return UserMaterial(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      materialId: materialId ?? this.materialId,
      quantity: quantity ?? this.quantity,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 錬成に必要な素材情報
class CraftingMaterial {
  final String materialId;
  final int requiredQuantity;
  final int currentQuantity;
  final MaterialMaster? master;

  const CraftingMaterial({
    required this.materialId,
    required this.requiredQuantity,
    this.currentQuantity = 0,
    this.master,
  });

  bool get isEnough => currentQuantity >= requiredQuantity;

  int get shortage => requiredQuantity - currentQuantity;
}

/// 錬成レシピ
class CraftingRecipe {
  final int commonMaterials;
  final int monsterMaterials;
  final int gold;
  final List<CraftingMaterial> specificMaterials;

  const CraftingRecipe({
    this.commonMaterials = 0,
    this.monsterMaterials = 0,
    this.gold = 0,
    this.specificMaterials = const [],
  });

  factory CraftingRecipe.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const CraftingRecipe();
    }
    
    return CraftingRecipe(
      commonMaterials: json['common_materials'] as int? ?? 0,
      monsterMaterials: json['monster_materials'] as int? ?? 0,
      gold: json['gold'] as int? ?? 0,
      specificMaterials: (json['specific_materials'] as List<dynamic>?)
              ?.map((e) => CraftingMaterial(
                    materialId: e['material_id'] as String? ?? '',
                    requiredQuantity: e['quantity'] as int? ?? 0,
                  ))
              .toList() ??
          [],
    );
  }
}