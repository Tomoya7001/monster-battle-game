// lib/domain/entities/dispatch.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// 探索先マスターデータ
class DispatchLocation {
  final String locationId;
  final String name;
  final String? nameEn;
  final String description;
  final DispatchUnlockCondition unlockCondition;
  final List<DispatchOption> dispatchOptions;
  final int requiredMonsterCount;
  final int maxMonsterCount;
  final int recommendedLevel;
  final String? icon;
  final String? backgroundImage;
  final int displayOrder;
  final bool isActive;

  DispatchLocation({
    required this.locationId,
    required this.name,
    this.nameEn,
    required this.description,
    required this.unlockCondition,
    required this.dispatchOptions,
    this.requiredMonsterCount = 1,
    this.maxMonsterCount = 3,
    this.recommendedLevel = 1,
    this.icon,
    this.backgroundImage,
    this.displayOrder = 0,
    this.isActive = true,
  });

  factory DispatchLocation.fromJson(Map<String, dynamic> json) {
    final conditionJson = json['unlock_condition'] as Map<String, dynamic>? ?? {};
    final optionsJson = json['dispatch_options'] as List<dynamic>? ?? [];

    return DispatchLocation(
      locationId: json['location_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameEn: json['name_en'] as String?,
      description: json['description'] as String? ?? '',
      unlockCondition: DispatchUnlockCondition.fromJson(conditionJson),
      dispatchOptions: optionsJson
          .map((e) => DispatchOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      requiredMonsterCount: json['required_monster_count'] as int? ?? 1,
      maxMonsterCount: json['max_monster_count'] as int? ?? 3,
      recommendedLevel: json['recommended_level'] as int? ?? 1,
      icon: json['icon'] as String?,
      backgroundImage: json['background_image'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location_id': locationId,
      'name': name,
      'name_en': nameEn,
      'description': description,
      'unlock_condition': unlockCondition.toJson(),
      'dispatch_options': dispatchOptions.map((e) => e.toJson()).toList(),
      'required_monster_count': requiredMonsterCount,
      'max_monster_count': maxMonsterCount,
      'recommended_level': recommendedLevel,
      'icon': icon,
      'background_image': backgroundImage,
      'display_order': displayOrder,
      'is_active': isActive,
    };
  }

  /// 6時間オプションを取得
  DispatchOption? get option6Hours =>
      dispatchOptions.where((o) => o.durationHours == 6).firstOrNull;

  /// 12時間オプションを取得
  DispatchOption? get option12Hours =>
      dispatchOptions.where((o) => o.durationHours == 12).firstOrNull;
}

/// 探索解放条件
class DispatchUnlockCondition {
  final String type;
  final String? stageId;

  DispatchUnlockCondition({
    required this.type,
    this.stageId,
  });

  factory DispatchUnlockCondition.fromJson(Map<String, dynamic> json) {
    return DispatchUnlockCondition(
      type: json['type'] as String? ?? 'none',
      stageId: json['stage_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'stage_id': stageId,
    };
  }

  /// ボスクリア条件かどうか
  bool get isBossClear => type == 'boss_clear';
}

/// 探索オプション（6時間/12時間）
class DispatchOption {
  final int durationHours;
  final int baseExp;
  final List<DispatchReward> rewards;

  DispatchOption({
    required this.durationHours,
    required this.baseExp,
    required this.rewards,
  });

  factory DispatchOption.fromJson(Map<String, dynamic> json) {
    final rewardsJson = json['rewards'] as List<dynamic>? ?? [];

    return DispatchOption(
      durationHours: json['duration_hours'] as int? ?? 6,
      baseExp: json['base_exp'] as int? ?? 0,
      rewards: rewardsJson
          .map((e) => DispatchReward.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'duration_hours': durationHours,
      'base_exp': baseExp,
      'rewards': rewards.map((e) => e.toJson()).toList(),
    };
  }

  /// 時間表示用文字列
  String get durationText => '$durationHours時間';
}

/// 探索報酬定義
class DispatchReward {
  final String materialId;
  final int minQty;
  final int maxQty;
  final int rate;

  DispatchReward({
    required this.materialId,
    required this.minQty,
    required this.maxQty,
    required this.rate,
  });

  factory DispatchReward.fromJson(Map<String, dynamic> json) {
    return DispatchReward(
      materialId: json['material_id'] as String? ?? '',
      minQty: json['min_qty'] as int? ?? 1,
      maxQty: json['max_qty'] as int? ?? 1,
      rate: json['rate'] as int? ?? 100,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'material_id': materialId,
      'min_qty': minQty,
      'max_qty': maxQty,
      'rate': rate,
    };
  }
}

/// 探索ステータス
enum DispatchStatus {
  inProgress,  // 探索中
  completed,   // 完了（報酬未受取）
  claimed,     // 報酬受取済み
}

/// ユーザー探索データ
class UserDispatch {
  final String id;
  final String userId;
  final int slotIndex;
  final String locationId;
  final int durationHours;
  final List<String> monsterIds;
  final DispatchStatus status;
  final DateTime startedAt;
  final DateTime completedAt;
  final DateTime? claimedAt;
  final List<DispatchRewardResult>? rewards;

  UserDispatch({
    required this.id,
    required this.userId,
    required this.slotIndex,
    required this.locationId,
    required this.durationHours,
    required this.monsterIds,
    required this.status,
    required this.startedAt,
    required this.completedAt,
    this.claimedAt,
    this.rewards,
  });

  factory UserDispatch.fromJson(Map<String, dynamic> json, String docId) {
    return UserDispatch(
      id: docId,
      userId: json['user_id'] as String? ?? '',
      slotIndex: json['slot_index'] as int? ?? 1,
      locationId: json['location_id'] as String? ?? '',
      durationHours: json['duration_hours'] as int? ?? 6,
      monsterIds: List<String>.from(json['monster_ids'] ?? []),
      status: _parseStatus(json['status'] as String?),
      startedAt: (json['started_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (json['completed_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      claimedAt: (json['claimed_at'] as Timestamp?)?.toDate(),
      rewards: (json['rewards'] as List<dynamic>?)
          ?.map((e) => DispatchRewardResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'slot_index': slotIndex,
      'location_id': locationId,
      'duration_hours': durationHours,
      'monster_ids': monsterIds,
      'status': _statusToString(status),
      'started_at': Timestamp.fromDate(startedAt),
      'completed_at': Timestamp.fromDate(completedAt),
      'claimed_at': claimedAt != null ? Timestamp.fromDate(claimedAt!) : null,
      'rewards': rewards?.map((e) => e.toJson()).toList(),
    };
  }

  static DispatchStatus _parseStatus(String? status) {
    switch (status) {
      case 'in_progress':
        return DispatchStatus.inProgress;
      case 'completed':
        return DispatchStatus.completed;
      case 'claimed':
        return DispatchStatus.claimed;
      default:
        return DispatchStatus.inProgress;
    }
  }

  static String _statusToString(DispatchStatus status) {
    switch (status) {
      case DispatchStatus.inProgress:
        return 'in_progress';
      case DispatchStatus.completed:
        return 'completed';
      case DispatchStatus.claimed:
        return 'claimed';
    }
  }

  /// 探索が完了しているか（時間経過で判定）
  bool get isTimeCompleted => DateTime.now().isAfter(completedAt);

  /// 残り時間（秒）
  int get remainingSeconds {
    final diff = completedAt.difference(DateTime.now());
    return diff.isNegative ? 0 : diff.inSeconds;
  }

  /// 残り時間表示
  String get remainingTimeText {
    final seconds = remainingSeconds;
    if (seconds <= 0) return '完了';

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  /// 進行率（0.0〜1.0）
  double get progressRate {
    final total = durationHours * 3600;
    final elapsed = total - remainingSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  UserDispatch copyWith({
    String? id,
    String? userId,
    int? slotIndex,
    String? locationId,
    int? durationHours,
    List<String>? monsterIds,
    DispatchStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? claimedAt,
    List<DispatchRewardResult>? rewards,
  }) {
    return UserDispatch(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      slotIndex: slotIndex ?? this.slotIndex,
      locationId: locationId ?? this.locationId,
      durationHours: durationHours ?? this.durationHours,
      monsterIds: monsterIds ?? this.monsterIds,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      claimedAt: claimedAt ?? this.claimedAt,
      rewards: rewards ?? this.rewards,
    );
  }
}

/// 探索報酬結果
class DispatchRewardResult {
  final String materialId;
  final int quantity;

  DispatchRewardResult({
    required this.materialId,
    required this.quantity,
  });

  factory DispatchRewardResult.fromJson(Map<String, dynamic> json) {
    return DispatchRewardResult(
      materialId: json['material_id'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'material_id': materialId,
      'quantity': quantity,
    };
  }
}

/// ユーザー探索設定（枠解放状況など）
class UserDispatchSettings {
  final String userId;
  final int unlockedSlots;
  final DateTime? lastUpdated;

  UserDispatchSettings({
    required this.userId,
    this.unlockedSlots = 1,
    this.lastUpdated,
  });

  factory UserDispatchSettings.fromJson(Map<String, dynamic> json) {
    return UserDispatchSettings(
      userId: json['user_id'] as String? ?? '',
      unlockedSlots: json['unlocked_slots'] as int? ?? 1,
      lastUpdated: (json['last_updated'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'unlocked_slots': unlockedSlots,
      'last_updated': FieldValue.serverTimestamp(),
    };
  }

  /// 枠が解放されているか
  bool isSlotUnlocked(int slotIndex) => slotIndex <= unlockedSlots;

  UserDispatchSettings copyWith({
    String? userId,
    int? unlockedSlots,
    DateTime? lastUpdated,
  }) {
    return UserDispatchSettings(
      userId: userId ?? this.userId,
      unlockedSlots: unlockedSlots ?? this.unlockedSlots,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}