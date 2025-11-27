// lib/domain/entities/material.dart

/// 素材カテゴリ
enum MaterialCategory {
  common,   // 汎用素材
  element,  // 属性素材
  species,  // 種族素材
  area,     // エリア素材
  boss,     // ボス素材
}

/// 素材エンティティ
class Material {
  final String materialId;
  final String name;
  final String? nameEn;
  final String category;
  final int rarity;
  final String description;
  final String? icon;
  final int sellPrice;
  final int maxStack;
  final int displayOrder;
  final bool isActive;

  Material({
    required this.materialId,
    required this.name,
    this.nameEn,
    required this.category,
    required this.rarity,
    required this.description,
    this.icon,
    this.sellPrice = 0,
    this.maxStack = 999,
    this.displayOrder = 0,
    this.isActive = true,
  });

  factory Material.fromJson(Map<String, dynamic> json) {
    return Material(
      materialId: json['material_id'] as String? ?? json['materialId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? json['nameEn'] as String?,
      category: json['category'] as String? ?? 'common',
      rarity: json['rarity'] as int? ?? 1,
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String?,
      sellPrice: json['sell_price'] as int? ?? json['sellPrice'] as int? ?? 0,
      maxStack: json['max_stack'] as int? ?? json['maxStack'] as int? ?? 999,
      displayOrder: json['display_order'] as int? ?? json['displayOrder'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'material_id': materialId,
      'name': name,
      'name_en': nameEn,
      'category': category,
      'rarity': rarity,
      'description': description,
      'icon': icon,
      'sell_price': sellPrice,
      'max_stack': maxStack,
      'display_order': displayOrder,
      'is_active': isActive,
    };
  }

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

  /// カテゴリ表示名
  String get categoryDisplayName {
    switch (category) {
      case 'common': return '汎用';
      case 'element': return '属性';
      case 'species': return '種族';
      case 'area': return 'エリア';
      case 'boss': return 'ボス';
      default: return category;
    }
  }
}

/// ユーザー所持素材
class UserMaterial {
  final String id;
  final String userId;
  final String materialId;
  final int quantity;
  final DateTime acquiredAt;
  final DateTime updatedAt;

  UserMaterial({
    required this.id,
    required this.userId,
    required this.materialId,
    required this.quantity,
    required this.acquiredAt,
    required this.updatedAt,
  });

  factory UserMaterial.fromJson(Map<String, dynamic> json, String docId) {
    return UserMaterial(
      id: docId,
      userId: json['user_id'] as String? ?? '',
      materialId: json['material_id'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      acquiredAt: json['acquired_at'] != null
          ? (json['acquired_at'] as dynamic).toDate()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? (json['updated_at'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'material_id': materialId,
      'quantity': quantity,
      'acquired_at': acquiredAt,
      'updated_at': updatedAt,
    };
  }

  UserMaterial copyWith({
    String? id,
    String? userId,
    String? materialId,
    int? quantity,
    DateTime? acquiredAt,
    DateTime? updatedAt,
  }) {
    return UserMaterial(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      materialId: materialId ?? this.materialId,
      quantity: quantity ?? this.quantity,
      acquiredAt: acquiredAt ?? this.acquiredAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}