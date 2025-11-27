// lib/domain/entities/equipment_master.dart

import 'package:flutter/material.dart';

/// 装備マスターエンティティ
class EquipmentMaster {
  final String equipmentId;
  final String name;
  final String nameEn;
  final int rarity;
  final String category;
  final String description;
  final List<Map<String, dynamic>> effects;
  final Map<String, dynamic> restrictions;
  final Map<String, dynamic>? crafting;

  const EquipmentMaster({
    required this.equipmentId,
    required this.name,
    this.nameEn = '',
    required this.rarity,
    required this.category,
    required this.description,
    this.effects = const [],
    this.restrictions = const {},
    this.crafting,
  });

  factory EquipmentMaster.fromJson(Map<String, dynamic> json) {
    return EquipmentMaster(
      equipmentId: json['equipment_id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      rarity: json['rarity'] as int? ?? 2,
      category: json['category'] as String? ?? 'accessory',
      description: json['description'] as String? ?? '',
      effects: (json['effects'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      restrictions: json['restrictions'] != null
          ? Map<String, dynamic>.from(json['restrictions'] as Map)
          : {},
      crafting: json['crafting'] != null
          ? Map<String, dynamic>.from(json['crafting'] as Map)
          : null,
    );
  }

  Color get rarityColor {
    switch (rarity) {
      case 5:
        return const Color(0xFFFFD700);
      case 4:
        return const Color(0xFF9B59B6);
      case 3:
        return const Color(0xFF3498DB);
      case 2:
      default:
        return const Color(0xFF95A5A6);
    }
  }

  String get rarityStars => '★' * rarity;

  String get categoryName {
    switch (category) {
      case 'weapon':
        return '武器';
      case 'armor':
        return '防具';
      case 'accessory':
        return 'アクセサリー';
      case 'special':
        return '特殊';
      default:
        return '不明';
    }
  }

  IconData get categoryIcon {
    switch (category) {
      case 'weapon':
        return Icons.gavel;
      case 'armor':
        return Icons.shield;
      case 'accessory':
        return Icons.watch;
      case 'special':
        return Icons.auto_awesome;
      default:
        return Icons.help_outline;
    }
  }

  String get effectsText {
    if (effects.isEmpty) return 'なし';
    
    return effects.map((effect) {
      final type = effect['type'] as String?;
      switch (type) {
        case 'stat_boost':
          final stat = _translateStat(effect['stat'] as String?);
          final percent = ((effect['boost_percentage'] as num?) ?? 0) * 100;
          return '$stat +${percent.toInt()}%';
        case 'critical_rate_boost':
          final boost = ((effect['boost'] as num?) ?? 0) * 100;
          return 'クリ率 +${boost.toInt()}%';
        case 'accuracy_boost':
          final boost = ((effect['boost'] as num?) ?? 0) * 100;
          return '命中 +${boost.toInt()}%';
        case 'turn_healing':
          final percent = ((effect['heal_percentage'] as num?) ?? 0) * 100;
          return '毎ターンHP ${percent.toStringAsFixed(1)}%回復';
        case 'reflect_damage':
          final percent = ((effect['percentage'] as num?) ?? 0) * 100;
          return 'ダメージ${percent.toInt()}%反射';
        case 'all_stats_boost':
          final percent = ((effect['boost_percentage'] as num?) ?? 0) * 100;
          return '全ステ +${percent.toInt()}%';
        case 'initial_cost_boost':
          final amount = effect['amount'] as int? ?? 0;
          return '初期コスト +$amount';
        case 'endure':
          return 'HP1で耐える(1回)';
        case 'status_resistance':
          final status = effect['status'] as String?;
          return '${_translateStatus(status)}耐性';
        case 'attribute_boost':
          final attr = effect['attribute'] as String?;
          final percent = ((effect['boost_percentage'] as num?) ?? 0) * 100;
          return '${_translateAttribute(attr)}技 +${percent.toInt()}%';
        default:
          return type ?? '';
      }
    }).join(', ');
  }

  String? get restrictionText {
    if (restrictions.isEmpty) return null;
    
    final parts = <String>[];
    if (restrictions['species'] != null) {
      parts.add('${_translateSpecies(restrictions['species'] as String?)}専用');
    }
    if (restrictions['attribute'] != null) {
      parts.add('${_translateAttribute(restrictions['attribute'] as String?)}属性専用');
    }
    if (restrictions['monster_rarity'] != null) {
      parts.add('★${restrictions['monster_rarity']}専用');
    }
    
    return parts.isEmpty ? null : parts.join(', ');
  }

  bool canEquip({
    required String species,
    required String element,
    required int monsterRarity,
  }) {
    if (restrictions['species'] != null) {
      if (restrictions['species'].toString().toLowerCase() != species.toLowerCase()) {
        return false;
      }
    }
    if (restrictions['attribute'] != null) {
      if (restrictions['attribute'].toString().toLowerCase() != element.toLowerCase()) {
        return false;
      }
    }
    if (restrictions['monster_rarity'] != null) {
      if (restrictions['monster_rarity'] as int != monsterRarity) {
        return false;
      }
    }
    return true;
  }

  String _translateStat(String? stat) {
    switch (stat) {
      case 'attack': return '攻撃';
      case 'defense': return '防御';
      case 'magic': return '魔力';
      case 'speed': return '素早さ';
      case 'hp': return 'HP';
      default: return stat ?? '';
    }
  }

  String _translateStatus(String? status) {
    switch (status) {
      case 'paralysis': return '麻痺';
      case 'poison': return '毒';
      case 'burn': return '火傷';
      case 'freeze': return '凍結';
      case 'sleep': return '睡眠';
      default: return status ?? '';
    }
  }

  String _translateAttribute(String? attr) {
    switch (attr?.toLowerCase()) {
      case 'fire': return '炎';
      case 'water': return '水';
      case 'thunder': return '雷';
      case 'wind': return '風';
      case 'earth': return '大地';
      case 'light': return '光';
      case 'dark': return '闇';
      default: return attr ?? '';
    }
  }

  String _translateSpecies(String? species) {
    switch (species?.toLowerCase()) {
      case 'angel': return 'エンジェル';
      case 'demon': return 'デーモン';
      case 'human': return 'ヒューマン';
      case 'spirit': return 'スピリット';
      case 'mechanoid': return 'メカノイド';
      case 'dragon': return 'ドラゴン';
      case 'mutant': return 'ミュータント';
      default: return species ?? '';
    }
  }
}