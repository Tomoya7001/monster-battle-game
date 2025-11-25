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
import '../../../domain/models/stage/stage_data.dart'; // ★追加
import '../../../domain/models/battle/battle_result.dart'; // ★追加
import '../../../core/services/battle/battle_calculation_service.dart';
import '../../../core/models/monster_model.dart';
import '../../../data/repositories/adventure_repository.dart';

class BattleBloc extends Bloc<BattleEvent, BattleState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();
  
  BattleStateModel? _battleState;
  StageData? _currentStage; // ★追加
  Timer? _connectionCheckTimer; // ★追加

  BattleBloc() : super(const BattleInitial()) {
    on<StartCpuBattle>(_onStartCpuBattle);
    on<StartStageBattle>(_onStartStageBattle); // ★追加
    on<SelectFirstMonster>(_onSelectFirstMonster);
    on<UseSkill>(_onUseSkill);
    on<SwitchMonster>(_onSwitchMonster);
    on<WaitTurn>(_onWaitTurn);
    on<ProcessTurnEnd>(_onProcessTurnEnd);
    on<EndBattle>(_onEndBattle);
    on<RetryAfterError>(_onRetryAfterError); // ★追加
    on<ForceBattleEnd>(_onForceBattleEnd); // ★追加
    on<StartAdventureEncounter>(_onStartAdventureEncounter);
    on<StartBossBattle>(_onStartBossBattle);

  }

  /// CPUバトル開始
  Future<void> _onStartCpuBattle(
    StartCpuBattle event,
    Emitter<BattleState> emit,
  ) async {
    emit(const BattleLoading());

    try {
      // ★追加: 接続チェック開始
      _startConnectionCheck();

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
    } on FirebaseException catch (e) {
      // ★追加: Firebaseエラー
      emit(BattleNetworkError(
        message: 'ネットワークエラーが発生しました',
        canRetry: true,
      ));
    } on TimeoutException {
      // ★追加: タイムアウト
      emit(const BattleNetworkError(
        message: '接続がタイムアウトしました',
        canRetry: true,
      ));
    } catch (e, stackTrace) {
      // ★追加: 詳細エラーログ
      print('バトル開始エラー: $e');
      print('スタックトレース: $stackTrace');
      emit(BattleError(message: 'バトル開始エラー: $e'));
    }
  }

  /// ★修正: ステージバトル開始（通常戦・ボス戦対応）
  Future<void> _onStartStageBattle(
    StartStageBattle event,
    Emitter<BattleState> emit,
  ) async {
    emit(const BattleLoading());

    try {
      _currentStage = event.stageData;
      _startConnectionCheck();

      // プレイヤーパーティのBattleMonster変換
      final playerParty = await _convertToBattleMonsters(event.playerParty)
          .timeout(const Duration(seconds: 10));

      final adventureRepo = AdventureRepository();
      List<BattleMonster> enemyParty;

      // ★修正: ボス戦か通常戦かで敵の取得方法を分岐
      if (event.stageData.stageType == 'boss') {
        // ボス戦: 最大3体を取得
        final bossMonsters = await adventureRepo.getBossMonsters(event.stageData.stageId);
        
        if (bossMonsters.isNotEmpty) {
          enemyParty = await _convertToBattleMonsters(bossMonsters);
          print('✅ ボスモンスター ${bossMonsters.length}体 取得成功');
        } else {
          // フォールバック: ダミー3体
          print('⚠️ ボスモンスター取得失敗、ダミーを使用');
          enemyParty = _generateDummyCpuParty();
        }
      } else {
        // 通常戦: ランダム1体
        final enemyMonster = await adventureRepo.getRandomEncounterMonster(event.stageData.stageId);
        
        if (enemyMonster != null) {
          enemyParty = await _convertToBattleMonsters([enemyMonster]);
          print('✅ エンカウントモンスター取得成功: ${enemyMonster.monsterName}');
        } else {
          // フォールバック: ダミー1体
          print('⚠️ エンカウントモンスター取得失敗、ダミーを使用');
          enemyParty = [_generateDummyCpuParty().first];
        }
      }

      // ★修正: maxDeployableCountをボス戦は3、通常戦は1に設定
      final maxDeployable = event.stageData.stageType == 'boss' ? 3 : 1;

      _battleState = BattleStateModel(
        playerParty: playerParty,
        enemyParty: enemyParty,
        battleType: event.stageData.stageType == 'boss' ? 'boss' : 'adventure',
        maxDeployableCount: maxDeployable,
      );

      _battleState!.addLog('${event.stageData.name} 開始！');

      // 先頭モンスターを自動選択
      final firstMonster = playerParty[0];
      _battleState!.playerActiveMonster = firstMonster;
      _battleState!.playerFieldMonsterIds.add(firstMonster.baseMonster.id);
      firstMonster.hasParticipated = true;
      _battleState!.addLog('${firstMonster.baseMonster.monsterName}を繰り出した！');

      // 敵も先頭モンスターを選択
      final enemyFirstMonster = enemyParty[0];
      _battleState!.enemyActiveMonster = enemyFirstMonster;
      _battleState!.enemyFieldMonsterIds.add(enemyFirstMonster.baseMonster.id);
      enemyFirstMonster.hasParticipated = true;
      
      final enemyAppearMessage = event.stageData.stageType == 'boss'
          ? 'ボス ${enemyFirstMonster.baseMonster.monsterName}が現れた！'
          : '野生の${enemyFirstMonster.baseMonster.monsterName}が現れた！';
      _battleState!.addLog(enemyAppearMessage);

      // 行動選択フェーズへ
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

  /// ★NEW: エラー後のリトライ
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

  /// ★NEW: バトル強制終了
  Future<void> _onForceBattleEnd(
    ForceBattleEnd event,
    Emitter<BattleState> emit,
  ) async {
    _stopConnectionCheck();
    _battleState = null;
    _currentStage = null;
    emit(const BattleInitial());
  }

  /// ★NEW: 接続チェック開始
  void _startConnectionCheck() {
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkConnection(),
    );
  }

  /// ★NEW: 接続チェック停止
  void _stopConnectionCheck() {
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = null;
  }

  /// ★NEW: 接続確認
  Future<void> _checkConnection() async {
    try {
      await _firestore
          .collection('_health_check')
          .doc('ping')
          .get()
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      print('接続チェック失敗: $e');
      // 必要に応じてイベント発火
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

  /// CPU行動実行（簡易AI）- ラッパーメソッド
  Future<void> _executeCpuAction(Emitter<BattleState> emit) async {
    await _executeCpuActionWithSkill(emit, null);
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
      _stopConnectionCheck();
      _battleState!.phase = BattlePhase.battleEnd;
      
      if (_battleState!.isPlayerWin) {
        _battleState!.addLog('プレイヤーの勝利！');
        
        try {
          final adventureRepo = AdventureRepository();
          const userId = 'dev_user_12345';
          
          if (_currentStage != null) {
            // ボス戦の場合は進行状況リセット
            if (_currentStage!.stageType == 'boss' && _currentStage!.parentStageId != null) {
              await adventureRepo.resetProgressAfterBossClear(userId, _currentStage!.parentStageId!);
            } else {
              // 通常戦は進行状況を更新
              await adventureRepo.incrementEncounterCount(userId, _currentStage!.stageId);
            }
          }
          
          // 経験値を実際に付与
          await _applyExpToMonsters();
          
          final result = await _generateBattleResult(isWin: true);
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
        
        try {
          final result = await _generateBattleResult(isWin: false);
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
            // ★修正: 交代可能なモンスターがいない場合は敗北
            _stopConnectionCheck();
            _battleState!.phase = BattlePhase.battleEnd;
            _battleState!.addLog('プレイヤーの敗北...');
            
            try {
              final result = await _generateBattleResult(isWin: false);
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
    _stopConnectionCheck(); // ★追加
    _battleState = null;
    _currentStage = null; // ★追加
    emit(const BattleInitial());
  }

  /// ★NEW: バトル結果を生成
  Future<BattleResult> _generateBattleResult({required bool isWin}) async {
    if (_battleState == null) {
      throw Exception('バトル状態が存在しません');
    }

    // 基本報酬
    BattleRewards rewards;
    if (_currentStage != null) {
      // ステージ報酬
      rewards = BattleRewards(
        exp: _currentStage!.rewards.exp,
        gold: _currentStage!.rewards.gold,
        items: [], // TODO: ドロップ抽選
        gems: _currentStage!.rewards.gems,
      );
    } else {
      // CPU戦の簡易報酬
      rewards = const BattleRewards(
        exp: 50,
        gold: 100,
        items: [],
        gems: 0,
      );
    }

    // 敗北時は報酬半減
    if (!isWin) {
      rewards = BattleRewards(
        exp: (rewards.exp * 0.5).round(),
        gold: (rewards.gold * 0.5).round(),
        items: [],
        gems: 0,
      );
    }

    // 経験値配分（参戦モンスター全員に均等）
    final List<MonsterExpGain> expGains = [];
    final participatedMonsters = _battleState!.playerParty
        .where((m) => m.hasParticipated)
        .toList();

    if (participatedMonsters.isNotEmpty && rewards.exp > 0) {
      final expPerMonster = (rewards.exp / participatedMonsters.length).round();
      
      for (final monster in participatedMonsters) {
        final levelBefore = monster.baseMonster.level;
        // TODO: 実際のレベルアップ処理
        final levelAfter = levelBefore; // 仮
        
        expGains.add(MonsterExpGain(
          monsterId: monster.baseMonster.id,
          monsterName: monster.baseMonster.monsterName,
          gainedExp: expPerMonster,
          levelBefore: levelBefore,
          levelAfter: levelAfter,
          didLevelUp: false,
        ));
      }
    }

    return BattleResult(
      isWin: isWin,
      turnCount: _battleState!.turnNumber,
      usedMonsterIds: _battleState!.playerUsedMonsterIds,
      rewards: rewards,
      expGains: expGains,
      completedAt: DateTime.now(),
    );
  }

  /// ★NEW: 経験値を実際にFirestoreのモンスターに付与
  Future<void> _applyExpToMonsters() async {
    if (_battleState == null || _currentStage == null) return;

    try {
      const userId = 'dev_user_12345';
      final expReward = _currentStage!.rewards.exp;
      
      // 参戦モンスターを取得
      final participatedMonsters = _battleState!.playerParty
          .where((m) => m.hasParticipated)
          .toList();

      if (participatedMonsters.isEmpty || expReward <= 0) return;

      // 経験値を均等に分配
      final expPerMonster = (expReward / participatedMonsters.length).round();

      for (final battleMonster in participatedMonsters) {
        final monsterId = battleMonster.baseMonster.id;
        
        // user_monstersコレクションから該当モンスターを取得
        final querySnapshot = await _firestore
            .collection('user_monsters')
            .where('user_id', isEqualTo: userId)
            .where('monster_id', isEqualTo: battleMonster.baseMonster.monsterId)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final docRef = querySnapshot.docs.first.reference;
          final currentData = querySnapshot.docs.first.data();
          final currentExp = currentData['exp'] as int? ?? 0;
          final currentLevel = currentData['level'] as int? ?? 1;
          
          // 新しい経験値を計算
          final newExp = currentExp + expPerMonster;
          
          // レベルアップ判定（簡易版: 100 * レベル で次レベル）
          int newLevel = currentLevel;
          int remainingExp = newExp;
          while (remainingExp >= _getExpForNextLevel(newLevel) && newLevel < 50) {
            remainingExp -= _getExpForNextLevel(newLevel);
            newLevel++;
          }
          
          // Firestoreを更新
          await docRef.update({
            'exp': remainingExp,
            'level': newLevel,
            'updated_at': FieldValue.serverTimestamp(),
          });
          
          print('✅ ${battleMonster.baseMonster.monsterName} に経験値 $expPerMonster 付与 (Lv$currentLevel → Lv$newLevel)');
        }
      }
    } catch (e) {
      print('❌ 経験値付与エラー: $e');
    }
  }

  /// 次のレベルに必要な経験値
  int _getExpForNextLevel(int currentLevel) {
    // レベル * 100 の経験値が必要（簡易版）
    return currentLevel * 100;
  }

  /// バトル履歴をFirestoreに保存
  Future<void> _saveBattleHistory({required bool isWin}) async {
    if (_battleState == null) return;

    try {
      final userId = 'dev_user_12345'; // TODO: AuthBlocから取得

      final battleData = {
        'user_id': userId,
        'battle_type': _currentStage != null ? 'stage' : 'cpu', // ★修正
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
          .timeout(const Duration(seconds: 10)); // ★追加
    } on FirebaseException catch (e) {
      print('バトル履歴保存エラー (Firebase): $e');
      // 保存失敗してもバトル終了は継続
    } on TimeoutException {
      print('バトル履歴保存タイムアウト');
    } catch (e) {
      print('バトル履歴保存エラー: $e');
    }
  }

  /// MonsterリストをBattleMonsterに変換
  Future<List<BattleMonster>> _convertToBattleMonsters(List<Monster> monsters) async {
    final List<BattleMonster> battleMonsters = [];

    try {
      for (final monster in monsters) {
        // ★追加: データ検証
        if (monster.id.isEmpty || monster.monsterName.isEmpty) {
          throw Exception('不正なモンスターデータ: ${monster.id}');
        }

        // 技を取得（モンスターのequippedSkillsから）
        final skills = await _loadSkills(monster.equippedSkills);
        battleMonsters.add(BattleMonster(
          baseMonster: monster,
          skills: skills,
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
      // デフォルト技を返す（テスト用）
      return _getDefaultSkills();
    }

    final List<BattleSkill> skills = [];
    for (final skillId in skillIds) {
      try {
        final doc = await _firestore
            .collection('skill_masters')
            .doc(skillId)
            .get()
            .timeout(const Duration(seconds: 5)); // ★追加
            
        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            // ★追加: データ検証
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

  /// ★NEW: ステージ用の敵パーティを生成
  Future<List<BattleMonster>> _generateStageEnemyParty(StageData stage) async {
    try {
      final List<BattleMonster> enemyParty = [];
      
      for (final monsterId in stage.encounterMonsterIds ?? []) {
        final doc = await _firestore
            .collection('monster_masters')
            .doc(monsterId)
            .get()
            .timeout(const Duration(seconds: 5));
            
        if (!doc.exists) {
          print('敵モンスターが見つかりません: $monsterId');
          continue;
        }
        
        final data = doc.data();
        if (data == null) continue;
        
        // TODO: monster_masterからMonsterエンティティを生成
        // 現在は簡易実装
      }
      
      // データがない場合はダミーを返す
      if (enemyParty.isEmpty) {
        return _generateDummyCpuParty();
      }
      
      return enemyParty;
    } catch (e) {
      print('ステージ敵パーティ生成エラー: $e');
      // エラー時はダミーパーティ
      return _generateDummyCpuParty();
    }
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

      // BattleMonsterに変換
      final enemyParty = await _convertToBattleMonsters([enemyMonster]);
      final playerParty = await _convertToBattleMonsters(event.playerParty);

      // バトル初期化（1vs1）
      _battleState = BattleStateModel(
        playerParty: playerParty,
        enemyParty: enemyParty,
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

      // BattleMonsterに変換
      final enemyParty = await _convertToBattleMonsters(bossMonsters);
      final playerParty = await _convertToBattleMonsters(event.playerParty);

      // バトル初期化（最大3vs3）
      _battleState = BattleStateModel(
        playerParty: playerParty,
        enemyParty: enemyParty,
      );

      emit(BattleInProgress(
        battleState: _battleState!,
        message: '最初に出すモンスターを選んでください',
      ));
    } catch (e) {
      emit(BattleError(message: 'ボスバトルの開始に失敗しました: $e'));
    }
  }

  @override
  Future<void> close() {
    _stopConnectionCheck(); // ★追加
    return super.close();
  }
}