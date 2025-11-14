import 'package:cloud_firestore/cloud_firestore.dart';

/// ガチャ履歴モデル
class GachaHistory {
  final String id;
  final String userId;
  final String gachaType; // '通常', 'プレミアム', 'ピックアップ'
  final int pullCount; // 1 or 10
  final List<GachaHistoryResult> results;
  final int gemsUsed;
  final int ticketsUsed;
  final DateTime pulledAt;

  const GachaHistory({
    required this.id,
    required this.userId,
    required this.gachaType,
    required this.pullCount,
    required this.results,
    required this.gemsUsed,
    required this.ticketsUsed,
    required this.pulledAt,
  });

  factory GachaHistory.fromJson(Map<String, dynamic> json, String id) {
    return GachaHistory(
      id: id,
      userId: json['userId'] as String? ?? '',
      gachaType: json['gachaType'] as String? ?? '通常',
      pullCount: json['pullCount'] as int? ?? 1,
      results: (json['results'] as List<dynamic>?)
              ?.map((e) => GachaHistoryResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      gemsUsed: json['gemsUsed'] as int? ?? 0,
      ticketsUsed: json['ticketsUsed'] as int? ?? 0,
      pulledAt: (json['pulledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'gachaType': gachaType,
      'pullCount': pullCount,
      'results': results.map((e) => e.toJson()).toList(),
      'gemsUsed': gemsUsed,
      'ticketsUsed': ticketsUsed,
      'pulledAt': Timestamp.fromDate(pulledAt),
    };
  }
}

/// ガチャ結果（個別）
class GachaHistoryResult {
  final String monsterId;
  final String monsterName;
  final int rarity;
  final String race;
  final String element;

  const GachaHistoryResult({
    required this.monsterId,
    required this.monsterName,
    required this.rarity,
    required this.race,
    required this.element,
  });

  factory GachaHistoryResult.fromJson(Map<String, dynamic> json) {
    return GachaHistoryResult(
      monsterId: json['monsterId'] as String? ?? '',
      monsterName: json['monsterName'] as String? ?? '不明',
      rarity: json['rarity'] as int? ?? 2,
      race: json['race'] as String? ?? '不明',
      element: json['element'] as String? ?? '不明',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monsterId': monsterId,
      'monsterName': monsterName,
      'rarity': rarity,
      'race': race,
      'element': element,
    };
  }
}