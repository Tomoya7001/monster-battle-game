import 'package:equatable/equatable.dart';

// ============================================
// BLoC States
// ============================================

/// ドラフトBLoCの状態基底クラス
abstract class DraftBlocState extends Equatable {
  const DraftBlocState();

  @override
  List<Object?> get props => [];
}

/// 初期状態
class DraftInitial extends DraftBlocState {
  const DraftInitial();
}

/// マッチング中
class DraftMatching extends DraftBlocState {
  final int waitSeconds;
  final bool isCpuFallback;

  const DraftMatching({
    required this.waitSeconds,
    this.isCpuFallback = false,
  });

  @override
  List<Object?> get props => [waitSeconds, isCpuFallback];
}

/// モンスター選択中
class DraftSelecting extends DraftBlocState {
  final DraftStateModel draftState;

  const DraftSelecting({required this.draftState});

  @override
  List<Object?> get props => [draftState];
}

/// 相手待機中
class DraftWaitingOpponent extends DraftBlocState {
  final DraftStateModel draftState;

  const DraftWaitingOpponent({required this.draftState});

  @override
  List<Object?> get props => [draftState];
}

/// バトル準備完了
class DraftReady extends DraftBlocState {
  final DraftStateModel draftState;
  final String battleId;
  final bool isCpuOpponent;

  const DraftReady({
    required this.draftState,
    required this.battleId,
    required this.isCpuOpponent,
  });

  @override
  List<Object?> get props => [draftState, battleId, isCpuOpponent];
}

/// キャンセル
class DraftCancelled extends DraftBlocState {
  const DraftCancelled();
}

/// エラー
class DraftErrorState extends DraftBlocState {
  final String message;

  const DraftErrorState({required this.message});

  @override
  List<Object?> get props => [message];
}

// ============================================
// Domain Models
// ============================================

/// ドラフトバトルの状態管理モデル
class DraftStateModel {
  final List<DraftMonster> pool;
  final List<DraftMonster> selectedMonsters;
  final int remainingSeconds;
  final DraftPhase phase;
  final bool isReady;
  final bool opponentReady;

  const DraftStateModel({
    this.pool = const [],
    this.selectedMonsters = const [],
    this.remainingSeconds = 60,
    this.phase = DraftPhase.waiting,
    this.isReady = false,
    this.opponentReady = false,
  });

  DraftStateModel copyWith({
    List<DraftMonster>? pool,
    List<DraftMonster>? selectedMonsters,
    int? remainingSeconds,
    DraftPhase? phase,
    bool? isReady,
    bool? opponentReady,
  }) {
    return DraftStateModel(
      pool: pool ?? this.pool,
      selectedMonsters: selectedMonsters ?? this.selectedMonsters,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      phase: phase ?? this.phase,
      isReady: isReady ?? this.isReady,
      opponentReady: opponentReady ?? this.opponentReady,
    );
  }

  bool get canSelect => selectedMonsters.length < 5 && !isReady;
  bool get canConfirm => selectedMonsters.length == 5 && !isReady;
  Set<String> get selectedIds => selectedMonsters.map((m) => m.monsterId).toSet();
}

/// ドラフト用モンスターデータ
class DraftMonster {
  final String monsterId;
  final String name;
  final String element;
  final String species;
  final int rarity;
  final int hp;
  final int attack;
  final int defense;
  final int magic;
  final int speed;
  final List<DraftSkillPreview> skills;
  final String? imageUrl;

  const DraftMonster({
    required this.monsterId,
    required this.name,
    required this.element,
    required this.species,
    required this.rarity,
    required this.hp,
    required this.attack,
    required this.defense,
    required this.magic,
    required this.speed,
    this.skills = const [],
    this.imageUrl,
  });

  factory DraftMonster.fromFirestore(Map<String, dynamic> data) {
    final skillList = <DraftSkillPreview>[];
    final defaultSkills = data['default_skills'];
    if (defaultSkills is List) {
      for (final s in defaultSkills) {
        if (s is Map<String, dynamic>) {
          skillList.add(DraftSkillPreview(
            skillId: _asString(s['skill_id']),
            name: _asString(s['name']),
            element: _asString(s['element'], defaultValue: 'none'),
            cost: _asInt(s['cost'], defaultValue: 1),
          ));
        }
      }
    }

    return DraftMonster(
      monsterId: _asString(data['monster_id']),
      name: _asString(data['name']),
      element: _asString(data['element'], defaultValue: 'none'),
      species: _asString(data['species']),
      rarity: _asInt(data['rarity'], defaultValue: 1),
      hp: _asInt(data['base_hp'], defaultValue: 50),
      attack: _asInt(data['base_attack'], defaultValue: 30),
      defense: _asInt(data['base_defense'], defaultValue: 30),
      magic: _asInt(data['base_magic'], defaultValue: 30),
      speed: _asInt(data['base_speed'], defaultValue: 30),
      skills: skillList,
      imageUrl: data['image_url'] as String?,
    );
  }

  static String _asString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    return value.toString();
  }

  static int _asInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  int get lv50Hp => (hp * 2.0 + 50).round();
  int get lv50Attack => (attack * 2.0).round();
  int get lv50Defense => (defense * 2.0).round();
  int get lv50Magic => (magic * 2.0).round();
  int get lv50Speed => (speed * 2.0).round();
}

/// 技プレビュー
class DraftSkillPreview {
  final String skillId;
  final String name;
  final String element;
  final int cost;

  const DraftSkillPreview({
    required this.skillId,
    required this.name,
    required this.element,
    required this.cost,
  });
}

/// ドラフトフェーズ
enum DraftPhase {
  waiting,
  selecting,
  confirming,
  ready,
}