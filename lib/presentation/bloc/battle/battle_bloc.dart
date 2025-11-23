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

    // ★Week 3追加: 状態異常による行動判定
    final actionResult = BattleCalculationService.checkStatusAction(playerMonster);
    if (!actionResult.canAct) {
      _battleState!.addLog(actionResult.message);
      
      // 行動不能でもターンは消費するのでCPU行動へ
      if (_battleState!.enemyActiveMonster?.canAct == true) {
        await _executeCpuAction(emit);
      }
      add(const ProcessTurnEnd());
      return;
    }

    // コスト確認
    if (!playerMonster.canUseSkill(skill)) {
      emit(BattleInProgress(
        battleState: _battleState!,
        message: 'コストが足りません',
      ));
      return;
    }

    _battleState!.phase = BattlePhase.executing;

    // ★修正: 優先度を考慮した行動順決定
    final playerPriority = BattleCalculationService.getPriority(skill);
    
    // CPUの技を事前に選択して優先度を取得
    final cpuSkills = enemyMonster.skills.where((s) => enemyMonster.canUseSkill(s)).toList();
    BattleSkill? cpuSkill;
    int cpuPriority = 0;
    
    if (cpuSkills.isNotEmpty) {
      cpuSkill = cpuSkills[_random.nextInt(cpuSkills.length)];
      cpuPriority = BattleCalculationService.getPriority(cpuSkill);
    }

    // 行動順決定ロジック
    bool playerFirst;
    
    if (playerPriority != cpuPriority) {
      // 優先度が異なる場合は優先度の高い方が先制
      playerFirst = playerPriority > cpuPriority;
    } else {
      // 優先度が同じ場合は素早さで判定
      playerFirst = BattleCalculationService.isPlayerFirst(playerMonster, enemyMonster);
    }

    if (playerFirst) {
      // プレイヤー先制
      await _executePlayerSkill(playerMonster, enemyMonster, skill, emit);
      if (!_battleState!.isBattleEnd && enemyMonster.canAct) {
        await _executeCpuActionWithSkill(emit, cpuSkill);
      }
    } else {
      // CPU先制
      await _executeCpuActionWithSkill(emit, cpuSkill);
      if (!_battleState!.isBattleEnd && playerMonster.canAct) {
        await _executePlayerSkill(playerMonster, enemyMonster, skill, emit);
      }
    }

    // ターン終了処理
    add(const ProcessTurnEnd());
  }

  /// プレイヤーの技実行
  Future<void> _executePlayerSkill(
    BattleMonster playerMonster,
    BattleMonster enemyMonster,
    BattleSkill skill,
    Emitter<BattleState> emit,
  ) async {
    // コスト消費
    playerMonster.useSkill(skill);
    _battleState!.addLog('${playerMonster.baseMonster.monsterName}の${skill.name}！');

    // 1. 攻撃処理（最優先）
    int damageDealt = 0;
    if (skill.isAttack) {
      // ★追加: まもる判定
      if (enemyMonster.isProtecting) {
        _battleState!.addLog('${enemyMonster.baseMonster.monsterName}は攻撃を防いだ！');
        emit(BattleInProgress(battleState: _battleState!, message: '攻撃を防いだ！'));
        return;
      }
      
      // 命中判定
      if (!BattleCalculationService.checkHit(skill, playerMonster, enemyMonster)) {
        _battleState!.addLog('攻撃は外れた！');
        emit(BattleInProgress(battleState: _battleState!, message: '攻撃は外れた！'));
        return;
      }

      // ダメージ計算
      final result = BattleCalculationService.calculateDamage(
        attacker: playerMonster,
        defender: enemyMonster,
        skill: skill,
      );

      if (result.damage > 0) {
        damageDealt = result.damage; // ★追加: ダメージを記録
        enemyMonster.takeDamage(result.damage);

        String message = '${result.damage}のダメージ！';
        if (result.isCritical) {
          message = '急所に当たった！$message';
        }
        if (result.effectivenessText.isNotEmpty) {
          message = '${result.effectivenessText} $message';
        }

        _battleState!.addLog(message);

        if (enemyMonster.isFainted) {
          _battleState!.addLog('${enemyMonster.baseMonster.monsterName}は倒れた！');
        }
      }
    }

    // 2. ドレイン技の処理（攻撃後、反動前）
    final drainMessages = BattleCalculationService.applyDrain(
      skill: skill,
      user: playerMonster,
      damageDealt: damageDealt,
    );
    for (var msg in drainMessages) {
      _battleState!.addLog(msg);
    }

    // 3. 反動技の処理（ドレイン後）
    final recoilMessages = BattleCalculationService.applyRecoil(
      skill: skill,
      user: playerMonster,
      damageDealt: damageDealt,
    );
    for (var msg in recoilMessages) {
      _battleState!.addLog(msg);
    }

    // 4. 回復処理（非攻撃技の回復）
    final healMessages = BattleCalculationService.applyHeal(
      skill: skill,
      user: playerMonster,
      target: enemyMonster,
    );
    for (var msg in healMessages) {
      _battleState!.addLog(msg);
    }

    // ★追加: まもる処理
    final protectMessages = BattleCalculationService.applyProtect(
      skill: skill,
      user: playerMonster,
    );
    for (var msg in protectMessages) {
      _battleState!.addLog(msg);
    }

    // 5. バフ・デバフ効果を適用
    if (!enemyMonster.isFainted) {
      final statChangeMessages = BattleCalculationService.applyStatChanges(
        skill: skill,
        user: playerMonster,
        target: enemyMonster,
      );
      for (var msg in statChangeMessages) {
        _battleState!.addLog(msg);
      }
    }

    // 6. 状態異常を付与
    if (skill.isAttack && !enemyMonster.isFainted) {
      final statusMessages = BattleCalculationService.applyStatusAilments(
        skill: skill,
        target: enemyMonster,
      );
      for (var msg in statusMessages) {
        _battleState!.addLog(msg);
      }
    }

    emit(BattleInProgress(battleState: _battleState!, message: _battleState!.lastActionMessage));
  }

  /// CPU行動実行（事前に選択された技を使用）
  Future<void> _executeCpuActionWithSkill(Emitter<BattleState> emit, BattleSkill? preSelectedSkill) async {
    if (_battleState == null) return;
    if (_battleState!.enemyActiveMonster == null) return;
    if (_battleState!.playerActiveMonster == null) return;

    final cpuMonster = _battleState!.enemyActiveMonster!;
    final playerMonster = _battleState!.playerActiveMonster!;

    // ★Week 3追加: 状態異常による行動判定
    final actionResult = BattleCalculationService.checkStatusAction(cpuMonster);
    if (!actionResult.canAct) {
      _battleState!.addLog(actionResult.message);
      return;
    }

    // 事前に選択された技がある場合はそれを使用、なければランダム選択
    BattleSkill skill;
    if (preSelectedSkill != null && cpuMonster.canUseSkill(preSelectedSkill)) {
      skill = preSelectedSkill;
    } else {
      // 使用可能な技を取得（回復技も含む）
      final usableSkills = cpuMonster.skills
          .where((s) => cpuMonster.canUseSkill(s))
          .toList();

      if (usableSkills.isEmpty) {
        // 技が使えない場合は待機
        _battleState!.addLog('${cpuMonster.baseMonster.monsterName}は様子を見ている');
        return;
      }

      // ランダムで技を選択（簡易AI）
      skill = usableSkills[_random.nextInt(usableSkills.length)];
    }

    cpuMonster.useSkill(skill);
    _battleState!.addLog('相手の${cpuMonster.baseMonster.monsterName}の${skill.name}！');

    // 1. 攻撃処理（最優先）
    int damageDealt = 0;
    if (skill.isAttack) {
      // ★追加: まもる判定
      if (playerMonster.isProtecting) {
        _battleState!.addLog('${playerMonster.baseMonster.monsterName}は攻撃を防いだ！');
        emit(BattleInProgress(battleState: _battleState!, message: '攻撃を防いだ！'));
        return;
      }
      
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
        damageDealt = result.damage;
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
    }

    // 2. ドレイン技の処理（攻撃後、反動前）
    final drainMessages = BattleCalculationService.applyDrain(
      skill: skill,
      user: cpuMonster,
      damageDealt: damageDealt,
    );
    for (var msg in drainMessages) {
      _battleState!.addLog(msg);
    }

    // 3. 反動技の処理（ドレイン後）
    final recoilMessages = BattleCalculationService.applyRecoil(
      skill: skill,
      user: cpuMonster,
      damageDealt: damageDealt,
    );
    for (var msg in recoilMessages) {
      _battleState!.addLog(msg);
    }

    // 4. 回復処理（非攻撃技の回復）
    final healMessages = BattleCalculationService.applyHeal(
      skill: skill,
      user: cpuMonster,
      target: playerMonster,
    );
    for (var msg in healMessages) {
      _battleState!.addLog(msg);
    }

    // ★追加: まもる処理
    final protectMessages = BattleCalculationService.applyProtect(
      skill: skill,
      user: cpuMonster,
    );
    for (var msg in protectMessages) {
      _battleState!.addLog(msg);
    }

    // 5. バフ・デバフ効果を適用
    if (!playerMonster.isFainted) {
      final statChangeMessages = BattleCalculationService.applyStatChanges(
        skill: skill,
        user: cpuMonster,
        target: playerMonster,
      );
      for (var msg in statChangeMessages) {
        _battleState!.addLog(msg);
      }
    }

    // 6. 状態異常を付与
    if (skill.isAttack && !playerMonster.isFainted) {
      final statusMessages = BattleCalculationService.applyStatusAilments(
        skill: skill,
        target: playerMonster,
      );
      for (var msg in statusMessages) {
        _battleState!.addLog(msg);
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

  // 交代可能かチェック
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

  // 新しいモンスターの場合のみFieldIdsに追加
  if (!_battleState!.playerFieldMonsterIds.contains(event.monsterId)) {
    _battleState!.playerFieldMonsterIds.add(event.monsterId);
  }

  // 交代処理
  _battleState!.playerActiveMonster?.resetStages();
  _battleState!.playerActiveMonster = newMonster;
  newMonster.hasParticipated = true;
  newMonster.resetCost();
  _battleState!.playerSwitchedThisTurn = true;

  emit(BattleInProgress(
    battleState: _battleState!,
    message: '${newMonster.baseMonster.monsterName}に交代！',
  ));

  // 瀕死による強制交代の場合はCPU行動をスキップ
  if (!event.isForcedSwitch) {
    // 自主的な交代の場合のみCPU攻撃を受ける
    await Future.delayed(const Duration(milliseconds: 100));

    if (_battleState!.enemyActiveMonster?.canAct == true) {
      await _executeCpuAction(emit);
    }
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
        if (_battleState!.hasAvailableSwitchMonster) {
            _battleState!.phase = BattlePhase.monsterFainted;
            _battleState!.addLog('次のモンスターを選んでください');
            emit(BattleInProgress(
            battleState: _battleState!,
            message: '次のモンスターを選んでください',
            ));
            return;
        } else {
            // 交代可能なモンスターがいない場合は敗北
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
        _battleState!.enemySwitchedThisTurn = true; // ★追加: 交代フラグ設定
        _battleState!.addLog('相手は${availableMonster.baseMonster.monsterName}を繰り出した！');
    }
    }

    // ★Week 3追加: ターン開始時の状態異常処理
    if (_battleState!.playerActiveMonster != null) {
      final statusMessages = BattleCalculationService.processStatusAilmentStart(
        _battleState!.playerActiveMonster!,
      );
      for (var msg in statusMessages) {
        _battleState!.addLog(msg);
      }
      
      // 状態異常で瀕死になった場合の処理
      if (_battleState!.playerActiveMonster!.isFainted) {
        _battleState!.addLog('${_battleState!.playerActiveMonster!.baseMonster.monsterName}は倒れた！');
      }
    }

    if (_battleState!.enemyActiveMonster != null) {
      final statusMessages = BattleCalculationService.processStatusAilmentStart(
        _battleState!.enemyActiveMonster!,
      );
      for (var msg in statusMessages) {
        _battleState!.addLog(msg);
      }
      
      if (_battleState!.enemyActiveMonster!.isFainted) {
        _battleState!.addLog('${_battleState!.enemyActiveMonster!.baseMonster.monsterName}は倒れた！');
      }
    }

    // コスト回復（交代したターンはスキップ、麻痺状態は回復量-1）
    if (!_battleState!.playerSwitchedThisTurn && _battleState!.playerActiveMonster != null) {
      final recoveryAmount = BattleCalculationService.getCostRecoveryAmount(
        _battleState!.playerActiveMonster!,
      );
      _battleState!.playerActiveMonster!.currentCost = 
        (_battleState!.playerActiveMonster!.currentCost + recoveryAmount)
        .clamp(0, _battleState!.playerActiveMonster!.maxCost);
    }
    if (!_battleState!.enemySwitchedThisTurn && _battleState!.enemyActiveMonster != null) {
      final recoveryAmount = BattleCalculationService.getCostRecoveryAmount(
        _battleState!.enemyActiveMonster!,
      );
      _battleState!.enemyActiveMonster!.currentCost = 
        (_battleState!.enemyActiveMonster!.currentCost + recoveryAmount)
        .clamp(0, _battleState!.enemyActiveMonster!.maxCost);
    }

    // ★Week 3追加: ターン終了時の状態異常処理（持続ターン減少）
    if (_battleState!.playerActiveMonster != null) {
      final statusMessages = BattleCalculationService.processStatusAilmentEnd(
        _battleState!.playerActiveMonster!,
      );
      for (var msg in statusMessages) {
        _battleState!.addLog(msg);
      }
    }

    if (_battleState!.enemyActiveMonster != null) {
      final statusMessages = BattleCalculationService.processStatusAilmentEnd(
        _battleState!.enemyActiveMonster!,
      );
      for (var msg in statusMessages) {
        _battleState!.addLog(msg);
      }
    }

    // ★NEW: バフ/デバフの持続ターン減算
    if (_battleState!.playerActiveMonster != null) {
      final buffMessages = BattleCalculationService.decreaseStatStageTurns(
        _battleState!.playerActiveMonster!,
      );
      for (var msg in buffMessages) {
        _battleState!.addLog(msg);
      }
    }

    if (_battleState!.enemyActiveMonster != null) {
      final buffMessages = BattleCalculationService.decreaseStatStageTurns(
        _battleState!.enemyActiveMonster!,
      );
      for (var msg in buffMessages) {
        _battleState!.addLog(msg);
      }
    }

    // 交代フラグをリセット
    _battleState!.playerSwitchedThisTurn = false;
    _battleState!.enemySwitchedThisTurn = false;

    // ★追加: まもる状態をリセット
    if (_battleState!.playerActiveMonster != null) {
      _battleState!.playerActiveMonster!.resetProtecting();
    }
    if (_battleState!.enemyActiveMonster != null) {
      _battleState!.enemyActiveMonster!.resetProtecting();
    }

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