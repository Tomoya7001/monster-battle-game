import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'dart:async';

import 'battle_event.dart';
import 'battle_state.dart';
import '../../../domain/entities/monster.dart';
import '../../../domain/models/battle/battle_monster.dart';
import '../../../domain/models/battle/battle_skill.dart';
import '../../../domain/models/battle/battle_state_model.dart';
import '../../../domain/models/stage/stage_data.dart';
import '../../../domain/models/battle/battle_result.dart';
import '../../../core/services/battle/battle_calculation_service.dart';
import '../../../data/repositories/adventure_repository.dart';
import '../../../data/repositories/monster_repository_impl.dart';
import '../../../data/repositories/equipment_repository.dart';
import '../../../domain/entities/equipment_master.dart';

/// バトル設定クラス（BattleBlocの外部に配置）
class BattleSettings {
  /// 交代時に相手の攻撃を受ける仕様を有効にする
  /// true: ポケモン式（交代時に攻撃を受ける）
  /// false: 通常（交代後に相手ターン）
  static bool enablePursuitOnSwitch = true;
  
  /// 追い打ち技（交代時に威力2倍になる技）を有効にする
  static bool enablePursuitSkills = true;
}

class BattleBloc extends Bloc<BattleEvent, BattleState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();
  
  BattleStateModel? _battleState;
  StageData? _currentStage;
  final EquipmentRepository _equipmentRepository = EquipmentRepository();
  Timer? _connectionCheckTimer;

  BattleBloc() : super(const BattleInitial()) {
    on<StartCpuBattle>(_onStartCpuBattle);
    on<StartStageBattle>(_onStartStageBattle);
    on<SelectFirstMonster>(_onSelectFirstMonster);
    on<UseSkill>(_onUseSkill);
    on<SwitchMonster>(_onSwitchMonster); // ★ 内部で設定に応じて分岐
    on<WaitTurn>(_onWaitTurn);
    on<ProcessTurnEnd>(_onProcessTurnEnd);
    on<EndBattle>(_onEndBattle);
    on<RetryAfterError>(_onRetryAfterError);
    on<ForceBattleEnd>(_onForceBattleEnd);
    on<StartAdventureEncounter>(_onStartAdventureEncounter);
    on<StartBossBattle>(_onStartBossBattle);
    on<StartDraftBattle>(_onStartDraftBattle);
  }

  /// CPUバトル開始
  Future<void> _onStartCpuBattle(
    StartCpuBattle event,
    Emitter<BattleState> emit,
  ) async {
    emit(const BattleLoading());

    try {
      _startConnectionCheck();

      // CPU戦: フルHP（useCurrentHp: false）
      final playerParty = await _convertToBattleMonsters(event.playerParty, useCurrentHp: false);
      final enemyParty = await _generateCpuParty();

      _battleState = BattleStateModel(
        playerParty: playerParty,
        enemyParty: enemyParty,
        battleType: 'cpu',
      );

      _battleState!.addLog('バトル開始！');

      emit(BattleInProgress(
        battleState: _battleState!,
        message: '最初に出すモンスターを選んでください',
      ));
    } on FirebaseException catch (e) {
      emit(BattleNetworkError(
        message: 'ネットワークエラーが発生しました: $e',
        canRetry: true,
      ));
    } on TimeoutException {
      emit(const BattleNetworkError(
        message: '接続がタイムアウトしました',
        canRetry: true,
      ));
    } catch (e, stackTrace) {
      print('バトル開始エラー: $e');
      print('スタックトレース: $stackTrace');
      emit(BattleError(message: 'バトル開始エラー: $e'));
    }
  }

  /// ステージバトル開始（通常戦・ボス戦対応）
  Future<void> _onStartStageBattle(
    StartStageBattle event,
    Emitter<BattleState> emit,
  ) async {
    emit(const BattleLoading());

    try {
      _currentStage = event.stageData;
      _startConnectionCheck();

      // 冒険/ボス戦: 現在HP使用
      final playerParty = await _convertToBattleMonsters(event.playerParty, useCurrentHp: true)
          .timeout(const Duration(seconds: 10));

      final adventureRepo = AdventureRepository();
      List<BattleMonster> enemyParty;

      if (event.stageData.stageType == 'boss') {
        print('🎯 ボス戦開始: ${event.stageData.stageId}');
        final bossMonsters = await adventureRepo.getBossMonsters(event.stageData.stageId);
        
        if (bossMonsters.isNotEmpty) {
          enemyParty = await _convertToBattleMonsters(bossMonsters);
          print('✅ ボスモンスター ${bossMonsters.length}体 取得成功');
        } else {
          print('⚠️ ボスモンスター取得失敗、ダミーを使用');
          enemyParty = _generateDummyCpuParty();
        }
      } else {
        final enemyMonster = await adventureRepo.getRandomEncounterMonster(event.stageData.stageId);
        
        if (enemyMonster != null) {
          enemyParty = await _convertToBattleMonsters([enemyMonster]);
          print('✅ エンカウントモンスター取得成功: ${enemyMonster.monsterName}');
        } else {
          print('⚠️ エンカウントモンスター取得失敗、ダミーを使用');
          enemyParty = [_generateDummyCpuParty().first];
        }
      }

      _battleState = BattleStateModel(
        playerParty: playerParty,
        enemyParty: enemyParty,
        battleType: event.stageData.stageType == 'boss' ? 'boss' : 'adventure',
        maxDeployableCount: 3,
      );

      _battleState!.addLog('${event.stageData.name} 開始！');

      final firstMonster = playerParty[0];
      _battleState!.playerActiveMonster = firstMonster;
      _battleState!.playerFieldMonsterIds.add(firstMonster.baseMonster.id);
      firstMonster.hasParticipated = true;
      _battleState!.addLog('${firstMonster.baseMonster.monsterName}を繰り出した！');

      final enemyFirstMonster = enemyParty[0];
      _battleState!.enemyActiveMonster = enemyFirstMonster;
      _battleState!.enemyFieldMonsterIds.add(enemyFirstMonster.baseMonster.id);
      enemyFirstMonster.hasParticipated = true;
      
      final enemyAppearMessage = event.stageData.stageType == 'boss'
          ? 'ボス ${enemyFirstMonster.baseMonster.monsterName}が現れた！'
          : '野生の${enemyFirstMonster.baseMonster.monsterName}が現れた！';
      _battleState!.addLog(enemyAppearMessage);

      _battleState!.phase = BattlePhase.actionSelect;

      emit(BattleInProgress(
        battleState: _battleState!,
        message: '行動を選んでください',
      ));
    } on FirebaseException catch (e) {
      emit(BattleNetworkError(
        message: 'ステージデータの読み込みに失敗しました: $e',
        canRetry: true,
      ));
    } on TimeoutException {
      emit(const BattleNetworkError(
        message: 'ステージの読み込みがタイムアウトしました',
        canRetry: true,
      ));
    } catch (e, stackTrace) {
      print('ステージバトル開始エラー: $e');
      print('スタックトレース: $stackTrace');
      emit(BattleError(message: 'ステージバトル開始エラー: $e'));
    }
  }

  /// エラー後のリトライ
  Future<void> _onRetryAfterError(
    RetryAfterError event,
    Emitter<BattleState> emit,
  ) async {
    if (_battleState != null) {
      emit(BattleInProgress(
        battleState: _battleState!,
        message: '接続を再試行しています...',
      ));
    } else {
      emit(const BattleInitial());
    }
  }

  /// バトル強制終了
  Future<void> _onForceBattleEnd(
    ForceBattleEnd event,
    Emitter<BattleState> emit,
  ) async {
    _stopConnectionCheck();
    _battleState = null;
    _currentStage = null;
    emit(const BattleInitial());
  }

  /// 接続チェック開始
  void _startConnectionCheck() {
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkConnection(),
    );
  }

  /// 接続チェック停止
  void _stopConnectionCheck() {
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = null;
  }

  /// 接続確認
  Future<void> _checkConnection() async {
    try {
      await _firestore
          .collection('_health_check')
          .doc('ping')
          .get()
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      print('接続チェック失敗: $e');
    }
  }

  /// 初期モンスター選択
  Future<void> _onSelectFirstMonster(
    SelectFirstMonster event,
    Emitter<BattleState> emit,
  ) async {
    if (_battleState == null) return;

    final playerMonster = _battleState!.playerParty
        .firstWhere((m) => m.baseMonster.id == event.monsterId);
    
    _battleState!.playerActiveMonster = playerMonster;
    _battleState!.playerFieldMonsterIds.add(event.monsterId);
    playerMonster.hasParticipated = true;

    _battleState!.addLog('${playerMonster.baseMonster.monsterName}を繰り出した！');

    final cpuMonster = _battleState!.enemyParty[0];
    _battleState!.enemyActiveMonster = cpuMonster;
    _battleState!.enemyFieldMonsterIds.add(cpuMonster.baseMonster.id);
    cpuMonster.hasParticipated = true;

    _battleState!.addLog('相手は${cpuMonster.baseMonster.monsterName}を繰り出した！');

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

    final actionResult = BattleCalculationService.checkStatusAction(playerMonster);
    if (!actionResult.canAct) {
      _battleState!.addLog(actionResult.message);
      
      if (_battleState!.enemyActiveMonster?.canAct == true) {
        await _executeCpuAction(emit);
      }
      add(const ProcessTurnEnd());
      return;
    }

    if (!playerMonster.canUseSkill(skill)) {
      emit(BattleInProgress(
        battleState: _battleState!,
        message: 'コストが足りません',
      ));
      return;
    }

    _battleState!.phase = BattlePhase.executing;

    final playerPriority = BattleCalculationService.getPriority(skill);
    
    final cpuSkills = enemyMonster.skills.where((s) => enemyMonster.canUseSkill(s)).toList();
    BattleSkill? cpuSkill;
    int cpuPriority = 0;
    
    if (cpuSkills.isNotEmpty) {
      cpuSkill = cpuSkills[_random.nextInt(cpuSkills.length)];
      cpuPriority = BattleCalculationService.getPriority(cpuSkill);
    }

    bool playerFirst;
    
    if (playerPriority != cpuPriority) {
      playerFirst = playerPriority > cpuPriority;
    } else {
      playerFirst = BattleCalculationService.isPlayerFirst(playerMonster, enemyMonster);
    }

    if (playerFirst) {
      await _executePlayerSkill(playerMonster, enemyMonster, skill, emit);
      if (!_battleState!.isBattleEnd && enemyMonster.canAct) {
        await _executeCpuActionWithSkill(emit, cpuSkill);
      }
    } else {
      await _executeCpuActionWithSkill(emit, cpuSkill);
      if (!_battleState!.isBattleEnd && playerMonster.canAct) {
        await _executePlayerSkill(playerMonster, enemyMonster, skill, emit);
      }
    }

    add(const ProcessTurnEnd());
  }

  /// プレイヤーの技実行
  Future<void> _executePlayerSkill(
    BattleMonster playerMonster,
    BattleMonster enemyMonster,
    BattleSkill skill,
    Emitter<BattleState> emit,
  ) async {
    playerMonster.useSkill(skill);
    _battleState!.addLog('${playerMonster.baseMonster.monsterName}の${skill.name}！');

    int damageDealt = 0;
    if (skill.isAttack) {
      if (enemyMonster.isProtecting) {
        _battleState!.addLog('${enemyMonster.baseMonster.monsterName}は攻撃を防いだ！');
        emit(BattleInProgress(battleState: _battleState!, message: '攻撃を防いだ！'));
        return;
      }
      
      if (!BattleCalculationService.checkHit(skill, playerMonster, enemyMonster)) {
        _battleState!.addLog('攻撃は外れた！');
        emit(BattleInProgress(battleState: _battleState!, message: '攻撃は外れた！'));
        return;
      }

      final result = BattleCalculationService.calculateDamage(
        attacker: playerMonster,
        defender: enemyMonster,
        skill: skill,
      );

      if (result.damage > 0) {
        damageDealt = result.damage;
        enemyMonster.takeDamage(result.damage);

        // ダメージ反射
        final reflectPercentage = enemyMonster.reflectDamagePercentage;
        if (reflectPercentage > 0 && result.damage > 0) {
          final reflectDamage = (result.damage * reflectPercentage).round();
          if (reflectDamage > 0) {
            playerMonster.takeDamage(reflectDamage);
            _battleState!.addLog('${playerMonster.baseMonster.monsterName}は反射ダメージを${reflectDamage}受けた！');
          }
        }

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

    final drainMessages = BattleCalculationService.applyDrain(
      skill: skill,
      user: playerMonster,
      damageDealt: damageDealt,
    );
    for (var msg in drainMessages) {
      _battleState!.addLog(msg);
    }

    final recoilMessages = BattleCalculationService.applyRecoil(
      skill: skill,
      user: playerMonster,
      damageDealt: damageDealt,
    );
    for (var msg in recoilMessages) {
      _battleState!.addLog(msg);
    }

    final healMessages = BattleCalculationService.applyHeal(
      skill: skill,
      user: playerMonster,
      target: enemyMonster,
    );
    for (var msg in healMessages) {
      _battleState!.addLog(msg);
    }

    final protectMessages = BattleCalculationService.applyProtect(
      skill: skill,
      user: playerMonster,
    );
    for (var msg in protectMessages) {
      _battleState!.addLog(msg);
    }

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

    final actionResult = BattleCalculationService.checkStatusAction(cpuMonster);
    if (!actionResult.canAct) {
      _battleState!.addLog(actionResult.message);
      return;
    }

    BattleSkill skill;
    if (preSelectedSkill != null && cpuMonster.canUseSkill(preSelectedSkill)) {
      skill = preSelectedSkill;
    } else {
      final usableSkills = cpuMonster.skills
          .where((s) => cpuMonster.canUseSkill(s))
          .toList();

      if (usableSkills.isEmpty) {
        _battleState!.addLog('${cpuMonster.baseMonster.monsterName}は様子を見ている');
        return;
      }

      skill = usableSkills[_random.nextInt(usableSkills.length)];
    }

    cpuMonster.useSkill(skill);
    _battleState!.addLog('相手の${cpuMonster.baseMonster.monsterName}の${skill.name}！');

    int damageDealt = 0;
    if (skill.isAttack) {
      if (playerMonster.isProtecting) {
        _battleState!.addLog('${playerMonster.baseMonster.monsterName}は攻撃を防いだ！');
        emit(BattleInProgress(battleState: _battleState!, message: '攻撃を防いだ！'));
        return;
      }
      
      if (!BattleCalculationService.checkHit(skill, cpuMonster, playerMonster)) {
        _battleState!.addLog('攻撃は外れた！');
        emit(BattleInProgress(battleState: _battleState!, message: '攻撃は外れた！'));
        return;
      }

      final result = BattleCalculationService.calculateDamage(
        attacker: cpuMonster,
        defender: playerMonster,
        skill: skill,
      );

      if (result.damage > 0) {
        damageDealt = result.damage;
        playerMonster.takeDamage(result.damage);

        // ダメージ反射
        final reflectPercentage = playerMonster.reflectDamagePercentage;
        if (reflectPercentage > 0 && result.damage > 0) {
          final reflectDamage = (result.damage * reflectPercentage).round();
          if (reflectDamage > 0) {
            cpuMonster.takeDamage(reflectDamage);
            _battleState!.addLog('${cpuMonster.baseMonster.monsterName}は反射ダメージを${reflectDamage}受けた！');
          }
        }

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

    final drainMessages = BattleCalculationService.applyDrain(
      skill: skill,
      user: cpuMonster,
      damageDealt: damageDealt,
    );
    for (var msg in drainMessages) {
      _battleState!.addLog(msg);
    }

    final recoilMessages = BattleCalculationService.applyRecoil(
      skill: skill,
      user: cpuMonster,
      damageDealt: damageDealt,
    );
    for (var msg in recoilMessages) {
      _battleState!.addLog(msg);
    }

    final healMessages = BattleCalculationService.applyHeal(
      skill: skill,
      user: cpuMonster,
      target: playerMonster,
    );
    for (var msg in healMessages) {
      _battleState!.addLog(msg);
    }

    final protectMessages = BattleCalculationService.applyProtect(
      skill: skill,
      user: cpuMonster,
    );
    for (var msg in protectMessages) {
      _battleState!.addLog(msg);
    }

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

  /// CPU行動実行（簡易AI）- ラッパーメソッド
  Future<void> _executeCpuAction(Emitter<BattleState> emit) async {
    await _executeCpuActionWithSkill(emit, null);
  }

  /// モンスター交代（設定に応じて分岐）
  Future<void> _onSwitchMonster(
    SwitchMonster event,
    Emitter<BattleState> emit,
  ) async {
    if (BattleSettings.enablePursuitOnSwitch) {
      await _onSwitchMonsterWithPursuit(event, emit);
    } else {
      await _onSwitchMonsterNormal(event, emit);
    }
  }

  /// モンスター交代（通常版 - 交代後に相手ターン）
  Future<void> _onSwitchMonsterNormal(
    SwitchMonster event,
    Emitter<BattleState> emit,
  ) async {
    if (_battleState == null) return;

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

    if (!_battleState!.playerFieldMonsterIds.contains(event.monsterId)) {
      _battleState!.playerFieldMonsterIds.add(event.monsterId);
    }

    _battleState!.playerActiveMonster?.resetStages();
    _battleState!.playerActiveMonster = newMonster;
    newMonster.hasParticipated = true;
    newMonster.resetCost();
    _battleState!.playerSwitchedThisTurn = true;

    _battleState!.addLog('${newMonster.baseMonster.monsterName}を繰り出した！');

    emit(BattleInProgress(
      battleState: _battleState!,
      message: '${newMonster.baseMonster.monsterName}に交代！',
    ));

    if (!event.isForcedSwitch) {
      await Future.delayed(const Duration(milliseconds: 100));

      if (_battleState!.enemyActiveMonster?.canAct == true) {
        await _executeCpuAction(emit);
      }
    }

    add(const ProcessTurnEnd());
  }

  /// モンスター交代（交代時に攻撃を受ける仕様）
  Future<void> _onSwitchMonsterWithPursuit(
    SwitchMonster event,
    Emitter<BattleState> emit,
  ) async {
    if (_battleState == null) return;

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

    // 交代宣言ログ
    final currentMonster = _battleState!.playerActiveMonster;
    final newMonster = _battleState!.playerParty
        .firstWhere((m) => m.baseMonster.id == event.monsterId);
    
    _battleState!.addLog('${currentMonster?.baseMonster.monsterName}を${newMonster.baseMonster.monsterName}に交代！');

    // 瀕死による強制交代でなければ、相手の攻撃を受ける
    if (!event.isForcedSwitch && currentMonster != null && !currentMonster.isFainted) {
      emit(BattleInProgress(
        battleState: _battleState!,
        message: '交代中...',
      ));

      // 相手の攻撃を受ける（交代前のモンスターが対象）
      if (_battleState!.enemyActiveMonster?.canAct == true) {
        await _executeCpuAttackOnSwitch(emit, currentMonster);
      }

      // 交代前のモンスターが倒れた場合
      if (currentMonster.isFainted) {
        _battleState!.addLog('${currentMonster.baseMonster.monsterName}は倒れた！');
      }
    }

    // 交代実行
    if (!_battleState!.playerFieldMonsterIds.contains(event.monsterId)) {
      _battleState!.playerFieldMonsterIds.add(event.monsterId);
    }

    // 前のモンスターのステータスリセット
    currentMonster?.resetStages();
    
    // 新しいモンスターをアクティブに
    _battleState!.playerActiveMonster = newMonster;
    newMonster.hasParticipated = true;
    newMonster.resetCost();
    _battleState!.playerSwitchedThisTurn = true;

    _battleState!.addLog('${newMonster.baseMonster.monsterName}を繰り出した！');

    emit(BattleInProgress(
      battleState: _battleState!,
      message: '${newMonster.baseMonster.monsterName}に交代！',
    ));

    // 交代完了後はターン終了（相手は既に攻撃済み）
    add(const ProcessTurnEnd());
  }

  /// 交代時の相手攻撃（交代するモンスターに攻撃）
  Future<void> _executeCpuAttackOnSwitch(
    Emitter<BattleState> emit,
    BattleMonster switchingMonster,
  ) async {
    if (_battleState == null) return;
    if (_battleState!.enemyActiveMonster == null) return;

    final cpuMonster = _battleState!.enemyActiveMonster!;

    // CPUの行動チェック
    final actionResult = BattleCalculationService.checkStatusAction(cpuMonster);
    if (!actionResult.canAct) {
      _battleState!.addLog(actionResult.message);
      return;
    }

    // 使用可能な技からランダム選択（追い打ち技があれば優先）
    final usableSkills = cpuMonster.skills
        .where((s) => cpuMonster.canUseSkill(s))
        .toList();

    if (usableSkills.isEmpty) {
      _battleState!.addLog('相手の${cpuMonster.baseMonster.monsterName}は様子を見ている');
      return;
    }

    // 追い打ち技を探す
    BattleSkill skill;
    final pursuitSkills = usableSkills.where((s) => _isPursuitSkill(s)).toList();
    if (BattleSettings.enablePursuitSkills && pursuitSkills.isNotEmpty) {
      skill = pursuitSkills[_random.nextInt(pursuitSkills.length)];
    } else {
      skill = usableSkills[_random.nextInt(usableSkills.length)];
    }

    // 技使用
    cpuMonster.useSkill(skill);
    _battleState!.addLog('相手の${cpuMonster.baseMonster.monsterName}の${skill.name}！');

    if (skill.isAttack) {
      // まもる状態チェック
      if (switchingMonster.isProtecting) {
        _battleState!.addLog('${switchingMonster.baseMonster.monsterName}は攻撃を防いだ！');
        return;
      }

      // 命中判定
      if (!BattleCalculationService.checkHit(skill, cpuMonster, switchingMonster)) {
        _battleState!.addLog('攻撃は外れた！');
        return;
      }

      // ダメージ計算（追い打ち技なら威力2倍）
      final pursuitMultiplier = _getPursuitMultiplier(skill);
      final result = BattleCalculationService.calculateDamage(
        attacker: cpuMonster,
        defender: switchingMonster,
        skill: skill,
      );

      if (result.damage > 0) {
        final finalDamage = (result.damage * pursuitMultiplier).round();
        switchingMonster.takeDamage(finalDamage);

        String message = '${finalDamage}のダメージ！';
        if (pursuitMultiplier > 1.0) {
          message = '交代先への攻撃！$message';
        }
        if (result.isCritical) {
          message = '急所に当たった！$message';
        }
        if (result.effectivenessText.isNotEmpty) {
          message = '${result.effectivenessText} $message';
        }

        _battleState!.addLog(message);
      }
    }

    // 状態異常・バフ/デバフ適用
    if (!switchingMonster.isFainted) {
      final statChangeMessages = BattleCalculationService.applyStatChanges(
        skill: skill,
        user: cpuMonster,
        target: switchingMonster,
      );
      for (var msg in statChangeMessages) {
        _battleState!.addLog(msg);
      }

      if (skill.isAttack) {
        final statusMessages = BattleCalculationService.applyStatusAilments(
          skill: skill,
          target: switchingMonster,
        );
        for (var msg in statusMessages) {
          _battleState!.addLog(msg);
        }
      }
    }

    emit(BattleInProgress(
      battleState: _battleState!,
      message: _battleState!.lastActionMessage,
    ));

    // 少し待機（演出のため）
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// 追い打ち技かどうかを判定
  bool _isPursuitSkill(BattleSkill skill) {
    return skill.effects.containsKey('pursuit');
  }

  /// 追い打ち技の威力倍率を取得
  double _getPursuitMultiplier(BattleSkill skill) {
    if (!_isPursuitSkill(skill)) return 1.0;
    
    final pursuit = skill.effects['pursuit'];
    if (pursuit is Map<String, dynamic>) {
      return (pursuit['damage_multiplier'] as num?)?.toDouble() ?? 2.0;
    }
    return 2.0;
  }

  /// 待機
  Future<void> _onWaitTurn(
    WaitTurn event,
    Emitter<BattleState> emit,
  ) async {
    if (_battleState == null) return;

    _battleState!.addLog('${_battleState!.playerActiveMonster?.baseMonster.monsterName}は様子を見ている');

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
      _stopConnectionCheck();
      _battleState!.phase = BattlePhase.battleEnd;
      
      if (_battleState!.isPlayerWin) {
        _battleState!.addLog('プレイヤーの勝利！');
        
        try {
          final adventureRepo = AdventureRepository();
          const userId = 'dev_user_12345';
          
          if (_currentStage != null) {
            if (_currentStage!.stageType == 'boss' && _currentStage!.parentStageId != null) {
              await adventureRepo.resetProgressAfterBossClear(userId, _currentStage!.parentStageId!);
            } else if (_currentStage!.stageType != 'boss') {
              await adventureRepo.incrementEncounterCount(userId, _currentStage!.stageId);
            }
            
            await _applyGoldToUser();
          }
          
          // HP永続化
          await _saveMonsterHpAfterBattle();

          final expGains = await _applyExpToMonsters();
          final result = await _generateBattleResult(isWin: true, expGains: expGains);
          await _saveBattleHistory(isWin: true);
          
          emit(BattlePlayerWin(
            battleState: _battleState!,
            result: result,
          ));
        } catch (e) {
          print('バトル結果保存エラー: $e');
          emit(BattlePlayerWin(
            battleState: _battleState!,
            result: null,
          ));
        }
      } else {
        _battleState!.addLog('プレイヤーの敗北...');
        
        // HP永続化（敗北時も保存）
        await _saveMonsterHpAfterBattle();

        try {
          final result = await _generateBattleResult(isWin: false, expGains: []);
          await _saveBattleHistory(isWin: false);
          emit(BattlePlayerLose(
            battleState: _battleState!,
            result: result,
          ));
        } catch (e) {
          print('バトル結果保存エラー: $e');
          emit(BattlePlayerLose(
            battleState: _battleState!,
            result: null,
          ));
        }
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
        _stopConnectionCheck();
        _battleState!.phase = BattlePhase.battleEnd;
        _battleState!.addLog('プレイヤーの敗北...');

        // HP永続化（敗北時も保存）
        await _saveMonsterHpAfterBattle();
        
        try {
          final result = await _generateBattleResult(isWin: false, expGains: []);
          await _saveBattleHistory(isWin: false);
          emit(BattlePlayerLose(
            battleState: _battleState!,
            result: result,
          ));
        } catch (e) {
          print('バトル結果保存エラー: $e');
          emit(BattlePlayerLose(
            battleState: _battleState!,
            result: null,
          ));
        }
        return;
      }
    }

    // 相手モンスター瀕死処理
    if (_battleState!.enemyActiveMonster?.isFainted == true) {
      if (_battleState!.canEnemySendMore) {
        final availableMonster = _battleState!.enemyParty.firstWhere(
          (m) => !m.isFainted && 
                  m.baseMonster.id != _battleState!.enemyActiveMonster?.baseMonster.id,
          orElse: () => throw Exception('No available monster'),
        );
        
        if (!_battleState!.enemyFieldMonsterIds.contains(availableMonster.baseMonster.id)) {
          _battleState!.enemyFieldMonsterIds.add(availableMonster.baseMonster.id);
        }
        
        _battleState!.enemyActiveMonster = availableMonster;
        availableMonster.hasParticipated = true;
        availableMonster.resetCost();
        _battleState!.enemySwitchedThisTurn = true;
        _battleState!.addLog('相手は${availableMonster.baseMonster.monsterName}を繰り出した！');
      }
    }

    // 状態異常処理
    if (_battleState!.playerActiveMonster != null) {
      final statusMessages = BattleCalculationService.processStatusAilmentStart(
        _battleState!.playerActiveMonster!,
      );
      for (var msg in statusMessages) {
        _battleState!.addLog(msg);
      }
      
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

    // コスト回復
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

    // 装備効果（毎ターンHP回復など）
    if (_battleState!.playerActiveMonster != null) {
      final equipMessages = _battleState!.playerActiveMonster!.processEquipmentTurnEnd();
      for (var msg in equipMessages) {
        _battleState!.addLog(msg);
      }
    }
    if (_battleState!.enemyActiveMonster != null) {
      final equipMessages = _battleState!.enemyActiveMonster!.processEquipmentTurnEnd();
      for (var msg in equipMessages) {
        _battleState!.addLog(msg);
      }
    }

    // ターン終了時の状態異常処理
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

    // バフ/デバフの持続ターン減算
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

    // まもる状態をリセット
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
    _stopConnectionCheck();
    _battleState = null;
    _currentStage = null;
    emit(const BattleInitial());
  }

  /// バトル結果生成
  Future<BattleResult> _generateBattleResult({
    required bool isWin,
    List<MonsterExpGain> expGains = const [],
  }) async {
    final rewards = _currentStage != null
        ? BattleRewards(
            exp: isWin ? _currentStage!.rewards.exp : 0,
            gold: isWin ? _currentStage!.rewards.gold : 0,
            gems: 0,
            items: [],
          )
        : const BattleRewards(exp: 0, gold: 0, gems: 0, items: []);

    return BattleResult(
      isWin: isWin,
      turnCount: _battleState?.turnNumber ?? 0,
      usedMonsterIds: _battleState?.playerUsedMonsterIds ?? [],
      defeatedEnemyIds: _battleState?.enemyUsedMonsterIds ?? [],
      rewards: rewards,
      expGains: expGains,
    );
  }

  /// 経験値を実際にFirestoreのモンスターに付与
  Future<List<MonsterExpGain>> _applyExpToMonsters() async {
    final expGains = <MonsterExpGain>[];
    
    if (_battleState == null || _currentStage == null) return expGains;

    try {
      const userId = 'dev_user_12345';
      final expReward = _currentStage!.rewards.exp;
      
      final participatedMonsters = _battleState!.playerParty
          .where((m) => m.hasParticipated)
          .toList();

      if (participatedMonsters.isEmpty || expReward <= 0) return expGains;

      final expPerMonster = (expReward / participatedMonsters.length).round();

      for (final battleMonster in participatedMonsters) {
        final docRef = _firestore.collection('user_monsters').doc(battleMonster.baseMonster.id);
        final doc = await docRef.get();

        if (doc.exists) {
          final currentData = doc.data()!;
          final currentExp = currentData['exp'] as int? ?? 0;
          final currentLevel = currentData['level'] as int? ?? 1;
          
          int newExp = currentExp + expPerMonster;
          int newLevel = currentLevel;
          
          while (newExp >= _getExpForNextLevel(newLevel) && newLevel < 100) {
            newExp -= _getExpForNextLevel(newLevel);
            newLevel++;
          }
          
          await docRef.update({
            'exp': newExp,
            'level': newLevel,
            'updated_at': FieldValue.serverTimestamp(),
          });
          
          expGains.add(MonsterExpGain(
            monsterId: battleMonster.baseMonster.id,
            monsterName: battleMonster.baseMonster.monsterName,
            gainedExp: expPerMonster,
            levelBefore: currentLevel,
            levelAfter: newLevel,
          ));
          
          print('✅ ${battleMonster.baseMonster.monsterName} に経験値 $expPerMonster 付与 (Lv$currentLevel → Lv$newLevel)');
        }
      }
    } catch (e) {
      print('❌ 経験値付与エラー: $e');
    }
    
    return expGains;
  }

  /// ゴールドを付与（usersコレクションのcoinを更新）
  Future<void> _applyGoldToUser() async {
    if (_currentStage == null) return;

    try {
      const userId = 'dev_user_12345';
      final goldReward = _currentStage!.rewards.gold;
      
      if (goldReward <= 0) return;

      final userDoc = _firestore.collection('users').doc(userId);
      final doc = await userDoc.get();
      
      if (doc.exists) {
        final currentCoin = doc.data()?['coin'] as int? ?? 0;
        await userDoc.update({
          'coin': currentCoin + goldReward,
        });
        print('✅ ゴールド $goldReward 付与 ($currentCoin → ${currentCoin + goldReward})');
      } else {
        await userDoc.set({
          'coin': goldReward,
          'stone': 0,
        }, SetOptions(merge: true));
        print('✅ 新規ユーザーにゴールド $goldReward 付与');
      }
    } catch (e) {
      print('❌ ゴールド付与エラー: $e');
    }
  }

  /// バトル終了後のHP永続化（冒険/ボス戦のみ）
  Future<void> _saveMonsterHpAfterBattle() async {
    if (_battleState == null) return;
    
    // 冒険/ボス戦以外ではHP保存しない（PvP/CPU/ドラフトは元のHPに戻す）
    final battleType = _battleState!.battleType;
    if (battleType != 'adventure' && battleType != 'boss') {
      print('📊 HP保存スキップ（バトルタイプ: $battleType - HP変更なし）');
      return;
    }

    try {
      final monsterHpMap = <String, int>{};

      for (final battleMonster in _battleState!.playerParty) {
        if (battleMonster.hasParticipated) {
          final monsterId = battleMonster.baseMonster.id;
          
          // 敵モンスター（cpu_, enemy_, boss_で始まるID）は保存しない
          if (monsterId.startsWith('cpu_') || 
              monsterId.startsWith('enemy_') || 
              monsterId.startsWith('boss_')) {
            continue;
          }
          
          // HP割合を計算して実際のHPに変換
          final battleHpRatio = battleMonster.currentHp / battleMonster.maxHp;
          final actualHp = (battleMonster.baseMonster.maxHp * battleHpRatio).round();
          
          monsterHpMap[monsterId] = actualHp;
          print('📊 ${battleMonster.baseMonster.monsterName}: バトルHP ${battleMonster.currentHp}/${battleMonster.maxHp} → 実際HP $actualHp/${battleMonster.baseMonster.maxHp}');
        }
      }

      if (monsterHpMap.isNotEmpty) {
        final monsterRepo = MonsterRepositoryImpl(_firestore);
        await monsterRepo.updateMonstersHp(monsterHpMap);
        print('✅ バトル後HP保存完了: ${monsterHpMap.length}体');
      }
    } catch (e) {
      print('❌ HP保存エラー: $e');
    }
  }

  /// 次のレベルに必要な経験値
  int _getExpForNextLevel(int currentLevel) {
    return currentLevel * 100;
  }

  /// バトル履歴をFirestoreに保存
  Future<void> _saveBattleHistory({required bool isWin}) async {
    if (_battleState == null) return;

    try {
      const userId = 'dev_user_12345';

      final battleData = {
        'user_id': userId,
        'battle_type': _currentStage != null ? 'stage' : _battleState!.battleType,
        'stage_id': _currentStage?.stageId,
        'result': isWin ? 'win' : 'lose',
        'turn_count': _battleState!.turnNumber,
        'battle_log': _battleState!.battleLog,
        'player_party': _battleState!.playerUsedMonsterIds,
        'enemy_party': _battleState!.enemyUsedMonsterIds,
        'created_at': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('battle_history')
          .add(battleData)
          .timeout(const Duration(seconds: 10));
    } on FirebaseException catch (e) {
      print('バトル履歴保存エラー (Firebase): $e');
    } on TimeoutException {
      print('バトル履歴保存タイムアウト');
    } catch (e) {
      print('バトル履歴保存エラー: $e');
    }
  }

  /// MonsterリストをBattleMonsterに変換
  /// [useCurrentHp] - trueの場合は現在HPを使用（冒険/ボス戦）、falseはフルHP（PvP/CPU/ドラフト）
  Future<List<BattleMonster>> _convertToBattleMonsters(
    List<Monster> monsters, {
    bool useCurrentHp = false,
  }) async {
    final List<BattleMonster> battleMonsters = [];

    // 装備マスターデータを取得
    final equipmentMap = await _equipmentRepository.getEquipmentMasters();

    try {
      for (final monster in monsters) {
        if (monster.id.isEmpty || monster.monsterName.isEmpty) {
          throw Exception('不正なモンスターデータ: ${monster.id}');
        }

        final skills = await _loadSkills(monster.equippedSkills);
        
        // 装備を取得
        final List<EquipmentMaster> monsterEquipments = [];
        for (final equipId in monster.equippedEquipment) {
          final equipment = equipmentMap[equipId];
          if (equipment != null) {
            monsterEquipments.add(equipment);
            print('🛡️ ${monster.monsterName}: 装備「${equipment.name}」を適用');
          }
        }
        
        int initialHp;
        if (useCurrentHp) {
          // 冒険/ボス戦: 現在HP割合をLv50用HPに変換（瀕死は0のまま）
          final hpRatio = monster.hpPercentage;
          initialHp = (monster.lv50MaxHp * hpRatio).round();
          print('📊 ${monster.monsterName}: HP ${monster.currentHp}/${monster.maxHp} (${(hpRatio * 100).toInt()}%) → バトルHP $initialHp/${monster.lv50MaxHp}');
        } else {
          // PvP/CPU/ドラフト: フルHP
          initialHp = monster.lv50MaxHp;
        }
        
        battleMonsters.add(BattleMonster(
          baseMonster: monster,
          skills: skills,
          equipments: monsterEquipments,
          initialHp: initialHp,
        ));
      }
    } catch (e, stackTrace) {
      print('BattleMonster変換エラー: $e');
      print('スタックトレース: $stackTrace');
      rethrow;
    }

    return battleMonsters;
  }

  /// Firestoreから技データを読み込み
  Future<List<BattleSkill>> _loadSkills(List<String> skillIds) async {
    if (skillIds.isEmpty) {
      return _getDefaultSkills();
    }

    final List<BattleSkill> skills = [];
    for (final skillId in skillIds) {
      try {
        final doc = await _firestore
            .collection('skill_masters')
            .doc(skillId)
            .get()
            .timeout(const Duration(seconds: 5));
            
        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            if (!data.containsKey('name') || !data.containsKey('cost')) {
              print('不完全な技データ: $skillId');
              continue;
            }
            skills.add(BattleSkill.fromFirestore(data));
          }
        } else {
          print('技が見つかりません: $skillId');
        }
      } on TimeoutException {
        print('技読み込みタイムアウト: $skillId');
      } catch (e) {
        print('技読み込みエラー: $skillId - $e');
      }
    }

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
      equipments: const [],
    )).toList();
  }

  /// 冒険エンカウントバトル開始
  Future<void> _onStartAdventureEncounter(
    StartAdventureEncounter event,
    Emitter<BattleState> emit,
  ) async {
    try {
      emit(const BattleLoading());

      final adventureRepo = AdventureRepository();
      final enemyMonster = await adventureRepo.getRandomEncounterMonster(event.stageId);
      
      if (enemyMonster == null) {
        emit(const BattleError(message: 'エンカウントに失敗しました'));
        return;
      }

      final enemyParty = await _convertToBattleMonsters([enemyMonster]);
      // 冒険: 現在HP使用
      final playerParty = await _convertToBattleMonsters(event.playerParty, useCurrentHp: true);

      _battleState = BattleStateModel(
        playerParty: playerParty,
        enemyParty: enemyParty,
        battleType: 'adventure',
      );

      emit(BattleInProgress(
        battleState: _battleState!,
        message: '最初に出すモンスターを選んでください',
      ));
    } catch (e) {
      emit(BattleError(message: 'バトルの開始に失敗しました: $e'));
    }
  }

  /// ボスバトル開始
  Future<void> _onStartBossBattle(
    StartBossBattle event,
    Emitter<BattleState> emit,
  ) async {
    try {
      emit(const BattleLoading());

      final adventureRepo = AdventureRepository();
      final bossMonsters = await adventureRepo.getBossMonsters(event.stageId);
      
      if (bossMonsters.isEmpty) {
        emit(const BattleError(message: 'ボスモンスターの取得に失敗しました'));
        return;
      }

      final enemyParty = await _convertToBattleMonsters(bossMonsters);
      // ボス戦: 現在HP使用
      final playerParty = await _convertToBattleMonsters(event.playerParty, useCurrentHp: true);

      _battleState = BattleStateModel(
        playerParty: playerParty,
        enemyParty: enemyParty,
        battleType: 'boss',
      );

      emit(BattleInProgress(
        battleState: _battleState!,
        message: '最初に出すモンスターを選んでください',
      ));
    } catch (e) {
      emit(BattleError(message: 'ボスバトルの開始に失敗しました: $e'));
    }
  }

  /// ドラフトバトル開始
  Future<void> _onStartDraftBattle(
    StartDraftBattle event,
    Emitter<BattleState> emit,
  ) async {
    emit(const BattleLoading());

    try {
      // ドラフト: フルHP、Lv50固定
      final playerParty = await _convertToBattleMonsters(
        event.playerParty, 
        useCurrentHp: false,
      ).timeout(const Duration(seconds: 10));

      final enemyParty = await _convertToBattleMonsters(
        event.enemyParty,
        useCurrentHp: false,
      ).timeout(const Duration(seconds: 10));

      _battleState = BattleStateModel(
        playerParty: playerParty,
        enemyParty: enemyParty,
        battleType: 'draft',
        maxDeployableCount: 3,
      );

      _battleState!.addLog('ドラフトバトル開始！');

      emit(BattleInProgress(
        battleState: _battleState!,
        message: '最初に出すモンスターを選んでください',
      ));
    } catch (e) {
      emit(BattleError(message: 'ドラフトバトル開始エラー: $e'));
    }
  }

  @override
  Future<void> close() {
    _stopConnectionCheck();
    return super.close();
  }
}