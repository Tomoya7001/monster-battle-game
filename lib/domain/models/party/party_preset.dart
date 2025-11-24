import 'package:equatable/equatable.dart';

/// パーティプリセット
class PartyPreset extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String battleType; // 'pvp' or 'adventure'
  final List<String> monsterIds; // 最大5体
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PartyPreset({
    required this.id,
    required this.userId,
    required this.name,
    required this.battleType,
    required this.monsterIds,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PartyPreset.fromJson(Map<String, dynamic> json) {
    return PartyPreset(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      battleType: json['battle_type'] as String,
      monsterIds: (json['monster_ids'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      isActive: json['is_active'] as bool,
      createdAt: (json['created_at'] as dynamic).toDate(),
      updatedAt: (json['updated_at'] as dynamic).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'battle_type': battleType,
      'monster_ids': monsterIds,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        battleType,
        monsterIds,
        isActive,
        createdAt,
        updatedAt,
      ];
}