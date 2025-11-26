// lib/domain/entities/user_item.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// ユーザー所持アイテム
class UserItem {
  final String id;
  final String userId;  // ← 修正: oderId → userId
  final String itemId;
  final int quantity;
  final DateTime acquiredAt;
  final DateTime updatedAt;

  UserItem({
    required this.id,
    required this.userId,
    required this.itemId,
    required this.quantity,
    required this.acquiredAt,
    required this.updatedAt,
  });

  factory UserItem.fromJson(Map<String, dynamic> json, String docId) {
    return UserItem(
      id: docId,
      userId: json['user_id'] as String? ?? '',
      itemId: json['item_id'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      acquiredAt: (json['acquired_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'item_id': itemId,
      'quantity': quantity,
      'acquired_at': Timestamp.fromDate(acquiredAt),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  UserItem copyWith({
    String? id,
    String? userId,
    String? itemId,
    int? quantity,
    DateTime? acquiredAt,
    DateTime? updatedAt,
  }) {
    return UserItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
      acquiredAt: acquiredAt ?? this.acquiredAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}