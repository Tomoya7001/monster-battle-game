import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

import 'battle_event.dart';
import 'battle_state.dart';
import '../../../domain/entities/monster.dart';
import '../../../domain/models/battle/battle_monster.dart';
import '../../../domain/models/battle/battle_skill.dart';
import '../../../domain/models/battle/battle_state_model.dart';
import '../../../core/services/battle/battle_calculation_service.dart';
import '../../../core/models/monster_model.dart';

class BattleBloc extends Bloc<BattleEvent, BattleState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();
  
  BattleStateModel? _battleState;

  BattleBloc() : super(const BattleInitial()) {
    on<StartCpuBattle>(_onStartCpuBattle);
    on<SelectFirstMonster>(_onSelectFirstMonster);
    on<UseSkill>(_onUseSkill);
    on<SwitchMonster>(_onSwitchMonster);
    on<WaitTurn>(_onWaitTurn);
    on<ProcessTurnEnd>(_onProcessTurnEnd);
    on<EndBattle>(_onEndBattle);
  }

  /// CPUバトル開始
  Future<void> _onStartCpuBattle(
    StartCpuBattle event,
    Emitter<BattleState> emit,
  ) async {
    emit(const BattleLoading());

    try {
      // プレイヤーパーティのBattleMonster変換
      final playerParty = await _convertToBattleMonsters(event.playerParty);
      
      // CPUパーティ生成（簡易版：ランダムなモンスター3体）
      final enemyParty = await _generateCpuParty();

      _battleState = BattleStateModel(
        playerParty: playerParty,
        enemyParty: enemyParty,
      );

      _battleState!.addLog('バトル開始！');

      emit(BattleInProgress(
        battleState: _battleState!,
        message: '最初に出すモンスターを選んでください',
      ));
    } catch (e) {
      emit(BattleError(message: 'バトル開始エラー: $e'));
    }
  }

  /// 初期モンスター選択
  Future<void> _onSelectFirstMonster(
    SelectFirstMonster event,
    Emitter<BattleState> emit,
    ) async {
    if (_battleState == null) return;

    // プレイヤーのモンスター選択
    final playerMonster = _battleState!.playerParty
        .firstWhere((m) => m.baseMonster.id == event.monsterId);
    
    _battleState!.playerActiveMonster = playerMonster;
    _battleState!.playerFieldMonsterIds.add(event.monsterId); // ★修正: Setに追加
    playerMonster.hasParticipated = true;

    _battleState!.addLog('${playerMonster.baseMonster.monsterName}を繰り出した！');

    // CPUも最初のモンスターを選択
    final cpuMonster = _battleState!.enemyParty[0];
    _battleState!.enemyActiveMonster = cpuMonster;
    _battleState!.enemyFieldMonsterIds.add(cpuMonster.baseMonster.id); // ★修正: Setに追加
    cpuMonster.hasParticipated = true;

    _battleState!.addLog('相手は${cpuMonster.baseMonster.monsterName}を繰り出した！');

    // 行動選択フェーズへ
    _battleState!.phase = BattlePhase.actionSelect;

    emit(BattleInProgress(
        battleState: _battleState!,
        message: '行動を選んでください',
    ));
    }

  /// 技使用
  Future<void> _onUseSkill(
    UseSkill event,
    Emitter<BattleState> emit,
  ) async {
    if (_battleState == null) return;
    if (_battleState!.playerActiveMonster == null) return;
    if (_battleState!.enemyActiveMonster == null) return;

    final playerMonster = _battleState!.playerActiveMonster!;
    final enemyMonster = _battleState!.enemyActiveMonster!;
    final skill = event.skill;

    // コスト確認
    if (!playerMonster.canUseSkill(skill)) {
      emit(BattleInProgress(
        battleState: _battleState!,
        message: 'コストが足りません',
      ));
      return;
    }

    _battleState!.phase = BattlePhase.executing;

    // すばやさ判定
    final playerFirst = BattleCalculationService.isPlayerFirst(playerMonster, enemyMonster);

    if (playerFirst) {
      // プレイヤー先制
      await _executePlayerAction(skill, emit);
      if (!_battleState!.isBattleEnd && enemyMonster.canAct) {
        await _executeCpuAction(emit);
      }
    } else {
      // CPU先制
      await _executeCpuAction(emit);
      if (!_battleState!.isBattleEnd && playerMonster.canAct) {
        await _executePlayerAction(skill, emit);
      }
    }

    // ターン終了処理
    add(const ProcessTurnEnd());
  }

  /// プレイヤーアクション実行
  Future<void> _executePlayerAction(BattleSkill skill, Emitter<BattleState> emit) async {
    final attacker = _battleState!.playerActiveMonster!;
    final defender = _battleState!.enemyActiveMonster!;

    // コスト消費
    attacker.useSkill(skill);
    _battleState!.addLog('${attacker.baseMonster.monsterName}の${skill.name}！');

    // 命中判定
    if (!BattleCalculationService.checkHit(skill, attacker, defender)) {
      _battleState!.addLog('攻撃は外れた！');
      emit(BattleInProgress(battleState: _battleState!, message: '攻撃は外れた！'));
      return;
    }

    // ダメージ計算
    final result = BattleCalculationService.calculateDamage(
      attacker: attacker,
      defender: defender,
      skill: skill,
    );

    if (result.damage > 0) {
      defender.takeDamage(result.damage);

      String message = '${result.damage}のダメージ！';
      if (result.isCritical) {
        message = '急所に当たった！$message';
      }
      if (result.effectivenessText.isNotEmpty) {
        message = '${result.effectivenessText} $message';
      }

      _battleState!.addLog(message);

      if (defender.isFainted) {
        _battleState!.addLog('${defender.baseMonster.monsterName}は倒れた！');
      }
    }

    emit(BattleInProgress(battleState: _battleState!, message: _battleState!.lastActionMessage));
  }

  /// CPU行動実行（簡易AI）
  Future<void> _executeCpuAction(Emitter<BattleState> emit) async {
    final cpuMonster = _battleState!.enemyActiveMonster!;
    final playerMonster = _battleState!.playerActiveMonster!;

    // 使用可能な技を取得
    final usableSkills = cpuMonster.skills
        .where((s) => cpuMonster.canUseSkill(s) && s.isAttack)
        .toList();

    if (usableSkills.isEmpty) {
      // 技が使えない場合は待機
      _battleState!.addLog('${cpuMonster.baseMonster.monsterName}は様子を見ている');
      return;
    }

    // ランダムで技を選択（簡易AI）
    final skill = usableSkills[_random.nextInt(usableSkills.length)];

    cpuMonster.useSkill(skill);
    _battleState!.addLog('相手の${cpuMonster.baseMonster.monsterName}の${skill.name}！');

    // 命中判定
    if (!BattleCalculationService.checkHit(skill, cpuMonster, playerMonster)) {
      _battleState!.addLog('攻撃は外れた！');
      emit(BattleInProgress(battleState: _battleState!, message: '攻撃は外れた！'));
      return;
    }

    // ダメージ計算
    final result = BattleCalculationService.calculateDamage(
      attacker: cpuMonster,
      defender: playerMonster,
      skill: skill,
    );

    if (result.damage > 0) {
      playerMonster.takeDamage(result.damage);

      String message = '${result.damage}のダメージ！';
      if (result.isCritical) {
        message = '急所に当たった！$message';
      }
      if (result.effectivenessText.isNotEmpty) {
        message = '${result.effectivenessText} $message';
      }

      _battleState!.addLog(message);

      if (playerMonster.isFainted) {
        _battleState!.addLog('${playerMonster.baseMonster.monsterName}は倒れた！');
      }
    }

    emit(BattleInProgress(battleState: _battleState!, message: _battleState!.lastActionMessage));
  }

  /// モンスター交代
  Future<void> _onSwitchMonster(
    SwitchMonster event,
    Emitter<BattleState> emit,
    ) async {
    if (_battleState == null) return;

    // ★修正: 交代可能かチェック
    if (!_battleState!.canSwitchTo(event.monsterId)) {
        String message = 'このモンスターには交代できません';
        
        final monster = _battleState!.playerParty
            .firstWhere((m) => m.baseMonster.id == event.monsterId);
        
        if (monster.isFainted) {
        message = 'このモンスターは瀕死です';
        } else if (_battleState!.playerActiveMonster?.baseMonster.id == event.monsterId) {
        message = 'このモンスターは既に場に出ています';
        } else if (!_battleState!.canPlayerSendMore) {
        message = 'これ以上モンスターを出せません（3体制限）';
        }
        
        emit(BattleInProgress(
        battleState: _battleState!,
        message: message,
        ));
        return;
    }

    final newMonster = _battleState!.playerParty
        .firstWhere((m) => m.baseMonster.id == event.monsterId);

    // ★修正: 新しいモンスターの場合のみFieldIdsに追加
    if (!_battleState!.playerFieldMonsterIds.contains(event.monsterId)) {
        _battleState!.playerFieldMonsterIds.add(event.monsterId);
    }

    // 交代処理
    _battleState!.playerActiveMonster?.resetStages();
    _battleState!.playerActiveMonster = newMonster;
    newMonster.hasParticipated = true;
    newMonster.resetCost(); // コストリセット

    emit(BattleInProgress(
        battleState: _battleState!,
        message: '${newMonster.baseMonster.monsterName}に交代！',
    ));

    // 少し待ってからCPU行動
    await Future.delayed(const Duration(milliseconds: 100));

    if (_battleState!.enemyActiveMonster?.canAct == true) {
        await _executeCpuAction(emit);
    }

    add(const ProcessTurnEnd());
    }

  /// 待機
  Future<void> _onWaitTurn(
    WaitTurn event,
    Emitter<BattleState> emit,
  ) async {
    if (_battleState == null) return;

    _battleState!.addLog('${_battleState!.playerActiveMonster?.baseMonster.monsterName}は様子を見ている');

    // CPUのターン
    if (_battleState!.enemyActiveMonster?.canAct == true) {
      await _executeCpuAction(emit);
    }

    add(const ProcessTurnEnd());
  }

  /// ターン終了処理
  Future<void> _onProcessTurnEnd(
    ProcessTurnEnd event,
    Emitter<BattleState> emit,
  ) async {
    if (_battleState == null) return;

    // バトル終了判定（最優先）
    if (_battleState!.isBattleEnd) {
      _battleState!.phase = BattlePhase.battleEnd;
      
      if (_battleState!.isPlayerWin) {
        _battleState!.addLog('プレイヤーの勝利！');
        await _saveBattleHistory(isWin: true);
        emit(BattlePlayerWin(battleState: _battleState!));
      } else {
        _battleState!.addLog('プレイヤーの敗北...');
        await _saveBattleHistory(isWin: false);
        emit(BattlePlayerLose(battleState: _battleState!));
      }
      return;
    }

    // プレイヤーモンスター瀕死処理
    if (_battleState!.playerActiveMonster?.isFainted == true) {
      if (_battleState!.canPlayerSendMore) {
        _battleState!.phase = BattlePhase.monsterFainted;
        _battleState!.addLog('次のモンスターを選んでください');
        emit(BattleInProgress(
          battleState: _battleState!,
          message: '次のモンスターを選んでください',
        ));
        return;
      } else {
        // これ以上出せない場合は敗北
        _battleState!.phase = BattlePhase.battleEnd;
        _battleState!.addLog('プレイヤーの敗北...');
        await _saveBattleHistory(isWin: false);
        emit(BattlePlayerLose(battleState: _battleState!));
        return;
      }
    }

    // 相手モンスター瀕死処理
    if (_battleState!.enemyActiveMonster?.isFainted == true) {
    if (_battleState!.canEnemySendMore) {
        // ★修正: 瀕死でない未使用モンスターを探す
        final availableMonster = _battleState!.enemyParty.firstWhere(
        (m) => !m.isFainted && 
                m.baseMonster.id != _battleState!.enemyActiveMonster?.baseMonster.id,
        orElse: () => throw Exception('No available monster'),
        );
        
        // 新しいモンスターの場合のみFieldIdsに追加
        if (!_battleState!.enemyFieldMonsterIds.contains(availableMonster.baseMonster.id)) {
        _battleState!.enemyFieldMonsterIds.add(availableMonster.baseMonster.id);
        }
        
        _battleState!.enemyActiveMonster = availableMonster;
        availableMonster.hasParticipated = true;
        availableMonster.resetCost();
        _battleState!.addLog('相手は${availableMonster.baseMonster.monsterName}を繰り出した！');
    }
    }

    // コスト回復（交代したターンはスキップ）
    if (!_battleState!.playerSwitchedThisTurn) {
      _battleState!.playerActiveMonster?.recoverCost();
    }
    if (!_battleState!.enemySwitchedThisTurn) {
      _battleState!.enemyActiveMonster?.recoverCost();
    }

    // 交代フラグをリセット
    _battleState!.playerSwitchedThisTurn = false;
    _battleState!.enemySwitchedThisTurn = false;

    // ターン数増加
    _battleState!.turnNumber++;
    _battleState!.phase = BattlePhase.actionSelect;

    emit(BattleInProgress(
      battleState: _battleState!,
      message: 'ターン${_battleState!.turnNumber}',
    ));
  }

  /// バトル終了
  Future<void> _onEndBattle(
    EndBattle event,
    Emitter<BattleState> emit,
  ) async {
    _battleState = null;
    emit(const BattleInitial());
  }

  /// バトル履歴をFirestoreに保存
  Future<void> _saveBattleHistory({required bool isWin}) async {
    if (_battleState == null) return;

    try {
      final userId = 'dev_user_12345'; // TODO: AuthBlocから取得

      final battleData = {
        'user_id': userId,
        'battle_type': 'cpu',
        'result': isWin ? 'win' : 'lose',
        'turn_count': _battleState!.turnNumber,
        'battle_log': _battleState!.battleLog,
        'player_party': _battleState!.playerUsedMonsterIds,
        'enemy_party': _battleState!.enemyUsedMonsterIds,
        'created_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('battle_history').add(battleData);
    } catch (e) {
      print('バトル履歴保存エラー: $e');
    }
  }

  /// MonsterリストをBattleMonsterに変換
  Future<List<BattleMonster>> _convertToBattleMonsters(List<Monster> monsters) async {
    final List<BattleMonster> battleMonsters = [];

    for (final monster in monsters) {
      // 技を取得（モンスターのequippedSkillsから）
      final skills = await _loadSkills(monster.equippedSkills);
      battleMonsters.add(BattleMonster(
        baseMonster: monster,
        skills: skills,
      ));
    }

    return battleMonsters;
  }

  /// Firestoreから技データを読み込み
  Future<List<BattleSkill>> _loadSkills(List<String> skillIds) async {
    if (skillIds.isEmpty) {
      // デフォルト技を返す（テスト用）
      return _getDefaultSkills();
    }

    final List<BattleSkill> skills = [];
    for (final skillId in skillIds) {
      try {
        final doc = await _firestore.collection('skill_masters').doc(skillId).get();
        if (doc.exists) {
          skills.add(BattleSkill.fromFirestore(doc.data()!));
        }
      } catch (e) {
        print('技読み込みエラー: $skillId - $e');
      }
    }

    // 技が足りない場合はデフォルト技で補完
    if (skills.isEmpty) {
      return _getDefaultSkills();
    }

    return skills;
  }

  /// デフォルト技（テスト用）
  List<BattleSkill> _getDefaultSkills() {
    return [
      BattleSkill(
        id: 'default_1',
        name: 'たいあたり',
        type: 'physical',
        element: 'none',
        cost: 1,
        powerMultiplier: 1.0,
        accuracy: 100,
        target: 'enemy',
        effects: {},
        description: '体当たりで攻撃',
      ),
      BattleSkill(
        id: 'default_2',
        name: 'ひっかく',
        type: 'physical',
        element: 'none',
        cost: 1,
        powerMultiplier: 1.1,
        accuracy: 100,
        target: 'enemy',
        effects: {},
        description: '爪で引っ掻く',
      ),
      BattleSkill(
        id: 'default_3',
        name: '強打',
        type: 'physical',
        element: 'none',
        cost: 2,
        powerMultiplier: 1.5,
        accuracy: 95,
        target: 'enemy',
        effects: {},
        description: '強力な一撃',
      ),
      BattleSkill(
        id: 'default_4',
        name: '渾身撃',
        type: 'physical',
        element: 'none',
        cost: 3,
        powerMultiplier: 2.0,
        accuracy: 90,
        target: 'enemy',
        effects: {},
        description: '全力の攻撃',
      ),
    ];
  }

  /// CPUパーティ生成（簡易版）
  Future<List<BattleMonster>> _generateCpuParty() async {
    // Phase 1では常にダミーモンスター（弱い）を使用
    return _generateDummyCpuParty();
  }

  /// ダミーCPUパーティ
  List<BattleMonster> _generateDummyCpuParty() {
    final dummyMonsters = <Monster>[
      Monster(
        id: 'cpu_1',
        userId: 'cpu',
        monsterId: 'cpu_master_1',
        monsterName: 'スライム',
        species: 'spirit',
        element: 'water',
        rarity: 2,
        level: 50,
        exp: 0,
        currentHp: 100,
        lastHpUpdate: DateTime.now(),
        acquiredAt: DateTime.now(),
        baseHp: 65,
        baseAttack: 30,
        baseDefense: 35,
        baseMagic: 28,
        baseSpeed: 25,
      ),
      Monster(
        id: 'cpu_2',
        userId: 'cpu',
        monsterId: 'cpu_master_2',
        monsterName: 'ゴブリン',
        species: 'demon',
        element: 'dark',
        rarity: 2,
        level: 50,
        exp: 0,
        currentHp: 100,
        lastHpUpdate: DateTime.now(),
        acquiredAt: DateTime.now(),
        baseHp: 60,
        baseAttack: 35,
        baseDefense: 30,
        baseMagic: 25,
        baseSpeed: 32,
      ),
      Monster(
        id: 'cpu_3',
        userId: 'cpu',
        monsterId: 'cpu_master_3',
        monsterName: 'コボルト',
        species: 'human',
        element: 'earth',
        rarity: 2,
        level: 50,
        exp: 0,
        currentHp: 100,
        lastHpUpdate: DateTime.now(),
        acquiredAt: DateTime.now(),
        baseHp: 68,
        baseAttack: 32,
        baseDefense: 38,
        baseMagic: 26,
        baseSpeed: 28,
      ),
    ];

    return dummyMonsters.map((m) => BattleMonster(
      baseMonster: m,
      skills: _getDefaultSkills(),
    )).toList();
  }
}