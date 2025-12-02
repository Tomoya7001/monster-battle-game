import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'draft_event.dart';
import 'draft_state.dart';
import '../../../domain/entities/monster.dart';

class DraftBloc extends Bloc<DraftEvent, DraftBlocState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  Timer? _matchingTimer;
  Timer? _selectionTimer;
  Timer? _cpuThinkingTimer;

  String? _battleId;
  bool _isCpuOpponent = false;
  DraftStateModel _draftState = const DraftStateModel();
  List<DraftMonster> _cpuSelection = [];

  // マッチング時間: 5〜13秒ランダム
  late int _matchingDuration;

  static const List<String> _cpuNames = [
    'りゅうのつかい', 'ほのおのけんし', 'みずのまほうつかい',
    'かぜのたびびと', 'やみのきし', 'ひかりのてんし',
    'いかずちのせんし', 'だいちのまもりて', 'ふぶきのおうじ',
    'ドラゴンマスター', 'フレイムソード', 'アクアウィザード',
  ];

  DraftBloc() : super(const DraftInitial()) {
    on<StartDraftMatching>(_onStartMatching);
    on<UpdateMatchingTimer>(_onUpdateMatchingTimer);
    on<DraftMatchFound>(_onMatchFound);
    on<ToggleMonsterSelection>(_onToggleSelection);
    on<ConfirmSelection>(_onConfirmSelection);
    on<UpdateTimer>(_onUpdateTimer);
    on<TimeExpired>(_onTimeExpired);
    on<OpponentConfirmed>(_onOpponentConfirmed);
    on<DraftBattleStart>(_onStartBattle);
    on<CancelDraftMatching>(_onCancel);
    on<DraftError>(_onError);
  }

  Future<void> _onStartMatching(
    StartDraftMatching event,
    Emitter<DraftBlocState> emit,
  ) async {
    // 5〜13秒のランダムでマッチング時間を決定
    _matchingDuration = 5 + _random.nextInt(9);
    
    emit(const DraftMatching(waitSeconds: 0));

    int waitSeconds = 0;
    _matchingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      waitSeconds++;

      if (waitSeconds >= _matchingDuration) {
        timer.cancel();
        _isCpuOpponent = true;
        add(DraftMatchFound(
          battleId: 'draft_cpu_${DateTime.now().millisecondsSinceEpoch}',
          poolMonsterIds: [],
        ));
      } else {
        add(UpdateMatchingTimer(waitSeconds: waitSeconds));
      }
    });
  }

  Future<void> _onUpdateMatchingTimer(
    UpdateMatchingTimer event,
    Emitter<DraftBlocState> emit,
  ) async {
    // CPUフォールバックメッセージは表示しない
    emit(DraftMatching(
      waitSeconds: event.waitSeconds,
      isCpuFallback: false,
    ));
  }

  Future<void> _onMatchFound(
    DraftMatchFound event,
    Emitter<DraftBlocState> emit,
  ) async {
    _battleId = event.battleId;
    _matchingTimer?.cancel();

    final pool = await _generateDraftPool();

    _draftState = DraftStateModel(
      pool: pool,
      selectedMonsters: [],
      remainingSeconds: 60,
      phase: DraftPhase.selecting,
    );

    emit(DraftSelecting(draftState: _draftState));
    _startSelectionTimer();
  }

  void _startSelectionTimer() {
    int remaining = 60;
    _selectionTimer?.cancel();
    _selectionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining--;

      if (remaining <= 0) {
        timer.cancel();
        add(const TimeExpired());
      } else {
        add(UpdateTimer(remainingSeconds: remaining));
      }
    });
  }

  Future<void> _onUpdateTimer(
    UpdateTimer event,
    Emitter<DraftBlocState> emit,
  ) async {
    _draftState = _draftState.copyWith(
      remainingSeconds: event.remainingSeconds,
    );

    if (state is DraftSelecting) {
      emit(DraftSelecting(draftState: _draftState));
    } else if (state is DraftWaitingOpponent) {
      emit(DraftWaitingOpponent(draftState: _draftState));
    }
  }

  Future<void> _onToggleSelection(
    ToggleMonsterSelection event,
    Emitter<DraftBlocState> emit,
  ) async {
    if (_draftState.isReady) return;

    final currentSelected = List<DraftMonster>.from(_draftState.selectedMonsters);
    final selectedIds = currentSelected.map((m) => m.monsterId).toSet();

    if (selectedIds.contains(event.monsterId)) {
      currentSelected.removeWhere((m) => m.monsterId == event.monsterId);
    } else {
      if (currentSelected.length < 5) {
        final monster = _draftState.pool.firstWhere(
          (m) => m.monsterId == event.monsterId,
        );
        currentSelected.add(monster);
      }
    }

    _draftState = _draftState.copyWith(selectedMonsters: currentSelected);
    emit(DraftSelecting(draftState: _draftState));
  }

  Future<void> _onConfirmSelection(
    ConfirmSelection event,
    Emitter<DraftBlocState> emit,
  ) async {
    if (_draftState.selectedMonsters.length != 5) return;

    _draftState = _draftState.copyWith(
      isReady: true,
      phase: DraftPhase.confirming,
    );

    _selectionTimer?.cancel();
    emit(DraftWaitingOpponent(draftState: _draftState));

    if (_isCpuOpponent) {
      final thinkTime = 2 + _random.nextInt(3);
      _cpuThinkingTimer = Timer(Duration(seconds: thinkTime), () {
        _cpuSelection = _generateCpuSelection();
        add(const OpponentConfirmed());
      });
    }
  }

  Future<void> _onTimeExpired(
    TimeExpired event,
    Emitter<DraftBlocState> emit,
  ) async {
    final currentSelected = List<DraftMonster>.from(_draftState.selectedMonsters);
    final selectedIds = currentSelected.map((m) => m.monsterId).toSet();

    final remaining = _draftState.pool
        .where((m) => !selectedIds.contains(m.monsterId))
        .toList();
    remaining.shuffle(_random);

    while (currentSelected.length < 5 && remaining.isNotEmpty) {
      currentSelected.add(remaining.removeLast());
    }

    _draftState = _draftState.copyWith(
      selectedMonsters: currentSelected,
      isReady: true,
      phase: DraftPhase.confirming,
    );

    emit(DraftWaitingOpponent(draftState: _draftState));

    if (_isCpuOpponent) {
      _cpuSelection = _generateCpuSelection();
      await Future.delayed(const Duration(seconds: 1));
      add(const OpponentConfirmed());
    }
  }

  Future<void> _onOpponentConfirmed(
    OpponentConfirmed event,
    Emitter<DraftBlocState> emit,
  ) async {
    _draftState = _draftState.copyWith(
      opponentReady: true,
      phase: DraftPhase.ready,
    );

    emit(DraftReady(
      draftState: _draftState,
      battleId: _battleId ?? '',
      isCpuOpponent: _isCpuOpponent,
    ));
  }

  Future<void> _onStartBattle(
    DraftBattleStart event,
    Emitter<DraftBlocState> emit,
  ) async {}

  Future<void> _onCancel(
    CancelDraftMatching event,
    Emitter<DraftBlocState> emit,
  ) async {
    _matchingTimer?.cancel();
    _selectionTimer?.cancel();
    _cpuThinkingTimer?.cancel();

    _draftState = const DraftStateModel();
    _battleId = null;
    _isCpuOpponent = false;
    _cpuSelection = [];

    emit(const DraftCancelled());
  }

  Future<void> _onError(
    DraftError event,
    Emitter<DraftBlocState> emit,
  ) async {
    emit(DraftErrorState(message: event.message));
  }

  Future<List<DraftMonster>> _generateDraftPool() async {
    try {
      final snapshot = await _firestore
          .collection('monster_masters')
          .get()
          .timeout(const Duration(seconds: 10));

      if (snapshot.docs.isEmpty) {
        return _generateDummyPool();
      }

      final allMonsters = <DraftMonster>[];
      for (final doc in snapshot.docs) {
        try {
          final monster = DraftMonster.fromFirestore(doc.data());
          if (monster.monsterId.isNotEmpty && monster.name.isNotEmpty) {
            allMonsters.add(monster);
          }
        } catch (e) {
          print('⚠️ モンスター変換エラー (${doc.id}): $e');
        }
      }

      if (allMonsters.isEmpty) {
        return _generateDummyPool();
      }

      final pool = <DraftMonster>[];
      final elements = ['fire', 'water', 'thunder', 'wind', 'earth', 'light', 'dark', 'none'];

      for (final element in elements) {
        final elementMonsters = allMonsters
            .where((m) => m.element.toLowerCase() == element)
            .toList();
        elementMonsters.shuffle(_random);

        final count = min(3, elementMonsters.length);
        for (int i = 0; i < count; i++) {
          if (pool.length < 25 && !pool.any((p) => p.monsterId == elementMonsters[i].monsterId)) {
            pool.add(elementMonsters[i]);
          }
        }
      }

      allMonsters.shuffle(_random);
      for (final monster in allMonsters) {
        if (pool.length >= 25) break;
        if (!pool.any((p) => p.monsterId == monster.monsterId)) {
          pool.add(monster);
        }
      }

      pool.shuffle(_random);
      return pool;
    } catch (e) {
      print('❌ プール生成エラー: $e');
      return _generateDummyPool();
    }
  }

  List<DraftMonster> _generateDummyPool() {
    final elements = ['fire', 'water', 'thunder', 'wind', 'earth', 'light', 'dark', 'none'];
    final species = ['dragon', 'angel', 'demon', 'human', 'spirit', 'mechanoid', 'mutant'];
    final pool = <DraftMonster>[];

    for (int i = 0; i < 25; i++) {
      pool.add(DraftMonster(
        monsterId: 'draft_dummy_$i',
        name: 'ドラフト${i + 1}号',
        element: elements[i % elements.length],
        species: species[i % species.length],
        rarity: 2 + (i % 4),
        hp: 50 + _random.nextInt(30),
        attack: 30 + _random.nextInt(20),
        defense: 30 + _random.nextInt(20),
        magic: 30 + _random.nextInt(20),
        speed: 30 + _random.nextInt(20),
        skills: [
          DraftSkillPreview(
            skillId: 'skill_$i',
            name: 'わざ${i + 1}',
            element: elements[i % elements.length],
            cost: 1 + (i % 3),
          ),
        ],
      ));
    }

    return pool;
  }

  List<DraftMonster> _generateCpuSelection() {
    final available = List<DraftMonster>.from(_draftState.pool);
    available.shuffle(_random);
    return available.take(5).toList();
  }

  String getCpuName() {
    return _cpuNames[_random.nextInt(_cpuNames.length)];
  }

  List<Monster> getPlayerPartyAsMonsters() {
    return _draftState.selectedMonsters.map((dm) {
      return Monster(
        id: 'draft_${dm.monsterId}',
        userId: 'draft_user',
        monsterId: dm.monsterId,
        monsterName: dm.name,
        species: dm.species,
        element: dm.element,
        rarity: dm.rarity,
        level: 50,
        exp: 0,
        currentHp: dm.lv50Hp,
        lastHpUpdate: DateTime.now(),
        acquiredAt: DateTime.now(),
        baseHp: dm.hp,
        baseAttack: dm.attack,
        baseDefense: dm.defense,
        baseMagic: dm.magic,
        baseSpeed: dm.speed,
        equippedSkills: dm.skills.map((s) => s.skillId).toList(),
        equippedEquipment: const [],
      );
    }).toList();
  }

  List<Monster> getCpuPartyAsMonsters() {
    return _cpuSelection.map((dm) {
      return Monster(
        id: 'cpu_${dm.monsterId}',
        userId: 'cpu_user',
        monsterId: dm.monsterId,
        monsterName: dm.name,
        species: dm.species,
        element: dm.element,
        rarity: dm.rarity,
        level: 50,
        exp: 0,
        currentHp: dm.lv50Hp,
        lastHpUpdate: DateTime.now(),
        acquiredAt: DateTime.now(),
        baseHp: dm.hp,
        baseAttack: dm.attack,
        baseDefense: dm.defense,
        baseMagic: dm.magic,
        baseSpeed: dm.speed,
        equippedSkills: dm.skills.map((s) => s.skillId).toList(),
        equippedEquipment: const [],
      );
    }).toList();
  }

  @override
  Future<void> close() {
    _matchingTimer?.cancel();
    _selectionTimer?.cancel();
    _cpuThinkingTimer?.cancel();
    return super.close();
  }
}
