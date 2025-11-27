/// ドラフトバトルの状態管理モデル
class DraftState {
  final List<DraftMonster> pool; // 25体のプール
  final List<DraftMonster> selectedMonsters; // 選択済み（最大5体）
  final int remainingSeconds; // 残り秒数
  final DraftPhase phase;
  final bool isReady; // 確定ボタン押下済み
  final bool opponentReady; // 相手が確定済み

  const DraftState({
    this.pool = const [],
    this.selectedMonsters = const [],
    this.remainingSeconds = 60,
    this.phase = DraftPhase.waiting,
    this.isReady = false,
    this.opponentReady = false,
  });

  DraftState copyWith({
    List<DraftMonster>? pool,
    List<DraftMonster>? selectedMonsters,
    int? remainingSeconds,
    DraftPhase? phase,
    bool? isReady,
    bool? opponentReady,
  }) {
    return DraftState(
      pool: pool ?? this.pool,
      selectedMonsters: selectedMonsters ?? this.selectedMonsters,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      phase: phase ?? this.phase,
      isReady: isReady ?? this.isReady,
      opponentReady: opponentReady ?? this.opponentReady,
    );
  }

  /// 選択可能か
  bool get canSelect => selectedMonsters.length < 5 && !isReady;

  /// 確定可能か（5体選択済み）
  bool get canConfirm => selectedMonsters.length == 5 && !isReady;

  /// 選択済みモンスターのID一覧
  Set<String> get selectedIds =>
      selectedMonsters.map((m) => m.monsterId).toSet();
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
    final skillList = (data['default_skills'] as List<dynamic>?)
            ?.map((s) => DraftSkillPreview(
                  skillId: s['skill_id'] ?? '',
                  name: s['name'] ?? '',
                  element: s['element'] ?? 'none',
                  cost: s['cost'] ?? 1,
                ))
            .toList() ??
        [];

    return DraftMonster(
      monsterId: data['monster_id'] ?? '',
      name: data['name'] ?? '',
      element: data['element'] ?? 'none',
      species: data['species'] ?? '',
      rarity: data['rarity'] ?? 1,
      hp: data['base_hp'] ?? 50,
      attack: data['base_attack'] ?? 30,
      defense: data['base_defense'] ?? 30,
      magic: data['base_magic'] ?? 30,
      speed: data['base_speed'] ?? 30,
      skills: skillList,
      imageUrl: data['image_url'],
    );
  }

  /// Lv50換算ステータス
  int get lv50Hp => (hp * 2.0 + 50).round();
  int get lv50Attack => (attack * 2.0).round();
  int get lv50Defense => (defense * 2.0).round();
  int get lv50Magic => (magic * 2.0).round();
  int get lv50Speed => (speed * 2.0).round();
}

/// 技プレビュー（ドラフト選択画面用）
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
  waiting,    // マッチング待機中
  selecting,  // 選択中（60秒）
  confirming, // 確定待ち（両者確定待ち）
  ready,      // バトル開始準備完了
}