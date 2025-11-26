// lib/domain/entities/item.dart
import 'package:freezed_annotation/freezed_annotation.dart';

/// アイテムカテゴリ
enum ItemCategory {
  consumable,  // 消耗品
  material,    // 素材
  equipment,   // 装備（参照用）
  valuable,    // 貴重品
}

/// アイテムサブカテゴリ
enum ItemSubCategory {
  healing,     // 回復系
  revive,      // 復活系
  growth,      // 育成系
  intimacy,    // 親密度系
  special,     // 特殊
  ivAdjust,    // 個体値調整
  element,     // 属性素材
  common,      // 汎用素材
  species,     // 種族素材
  boss,        // ボス素材
}

// lib/domain/entities/item.dart

/// アイテムエンティティ（Freezedなし版）
class Item {
  final String itemId;
  final String name;
  final String? nameEn;
  final String category;
  final String subCategory;
  final int rarity;
  final String description;
  final Map<String, dynamic>? effect;
  final String? icon;
  final int sellPrice;
  final int buyPrice;
  final int maxStack;
  final bool isUsableInBattle;
  final List<String> dropStages;
  final int dropRate;
  final int displayOrder;
  final bool isActive;

  Item({
    required this.itemId,
    required this.name,
    this.nameEn,
    required this.category,
    required this.subCategory,
    required this.rarity,
    required this.description,
    this.effect,
    this.icon,
    this.sellPrice = 0,
    this.buyPrice = 0,
    this.maxStack = 99,
    this.isUsableInBattle = false,
    this.dropStages = const [],
    this.dropRate = 0,
    this.displayOrder = 0,
    this.isActive = true,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      itemId: json['itemId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameEn: json['nameEn'] as String?,
      category: json['category'] as String? ?? '',
      subCategory: json['subCategory'] as String? ?? '',
      rarity: json['rarity'] as int? ?? 1,
      description: json['description'] as String? ?? '',
      effect: json['effect'] as Map<String, dynamic>?,
      icon: json['icon'] as String?,
      sellPrice: json['sellPrice'] as int? ?? 0,
      buyPrice: json['buyPrice'] as int? ?? 0,
      maxStack: json['maxStack'] as int? ?? 99,
      isUsableInBattle: json['isUsableInBattle'] as bool? ?? false,
      dropStages: List<String>.from(json['dropStages'] ?? []),
      dropRate: json['dropRate'] as int? ?? 0,
      displayOrder: json['displayOrder'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'name': name,
      'nameEn': nameEn,
      'category': category,
      'subCategory': subCategory,
      'rarity': rarity,
      'description': description,
      'effect': effect,
      'icon': icon,
      'sellPrice': sellPrice,
      'buyPrice': buyPrice,
      'maxStack': maxStack,
      'isUsableInBattle': isUsableInBattle,
      'dropStages': dropStages,
      'dropRate': dropRate,
      'displayOrder': displayOrder,
      'isActive': isActive,
    };
  }

  /// 消耗品かどうか
  bool get isConsumable => category == 'consumable';

  /// 素材かどうか
  bool get isMaterial => category == 'material';

  /// 回復アイテムかどうか
  bool get isHealingItem => 
      subCategory == 'healing' || subCategory == 'revive';

  /// レアリティに応じた色
  int get rarityColor {
    switch (rarity) {
      case 1: return 0xFF9E9E9E; // グレー
      case 2: return 0xFF4CAF50; // 緑
      case 3: return 0xFF2196F3; // 青
      case 4: return 0xFF9C27B0; // 紫
      case 5: return 0xFFFF9800; // オレンジ
      default: return 0xFF9E9E9E;
    }
  }

  /// レアリティの星表示
  String get rarityStars => '★' * rarity;
}