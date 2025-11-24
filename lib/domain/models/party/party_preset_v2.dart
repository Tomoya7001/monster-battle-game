import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// パーティプリセット v2
/// presetNumber (1-5) 追加版
class PartyPresetV2 extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String battleType; // 'pvp' or 'adventure'
  final int presetNumber; // 1-5
  final List<String> monsterIds; // 最大5体
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PartyPresetV2({
    required this.id,
    required this.userId,
    required this.name,
    required this.battleType,
    required this.presetNumber,
    required this.monsterIds,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PartyPresetV2.fromJson(Map<String, dynamic> json) {
    return PartyPresetV2(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? '無名のデッキ',
      battleType: json['battle_type'] as String? ?? 'pvp',
      presetNumber: json['preset_number'] as int? ?? 1,
      monsterIds: _parseMonsterIds(json['monster_ids']),
      isActive: json['is_active'] as bool? ?? false,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  static List<String> _parseMonsterIds(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'battle_type': battleType,
      'preset_number': presetNumber,
      'monster_ids': monsterIds,
      'is_active': isActive,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  PartyPresetV2 copyWith({
    String? id,
    String? userId,
    String? name,
    String? battleType,
    int? presetNumber,
    List<String>? monsterIds,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PartyPresetV2(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      battleType: battleType ?? this.battleType,
      presetNumber: presetNumber ?? this.presetNumber,
      monsterIds: monsterIds ?? this.monsterIds,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        battleType,
        presetNumber,
        monsterIds,
        isActive,
        createdAt,
        updatedAt,
      ];
}