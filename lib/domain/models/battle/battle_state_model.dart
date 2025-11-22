import 'battle_monster.dart';
import 'battle_skill.dart';

/// バトル全体の状態
class BattleStateModel {
  // プレイヤー側
  final List<BattleMonster> playerParty; // 手持ち5体
  final Set<String> playerFieldMonsterIds; // 場に出したモンスターID（瀕死含む、最大3体）
  BattleMonster? playerActiveMonster;
  bool playerSwitchedThisTurn; // ★追加: このターンに交代したか

  // 相手側（CPU）
  final List<BattleMonster> enemyParty;
  final Set<String> enemyFieldMonsterIds; // 場に出したモンスターID
  BattleMonster? enemyActiveMonster;
  bool enemySwitchedThisTurn; // ★追加: このターンに交代したか

  // ターン管理
  int turnNumber;
  bool isPlayerTurn;
  
  // バトル状態
  BattlePhase phase;
  String? lastActionMessage;
  List<String> battleLog;

  BattleStateModel({
    required this.playerParty,
    required this.enemyParty,
  })  : playerFieldMonsterIds = {},
        enemyFieldMonsterIds = {},
        playerActiveMonster = null,
        enemyActiveMonster = null,
        playerSwitchedThisTurn = false, // ★追加
        enemySwitchedThisTurn = false, // ★追加
        turnNumber = 1,
        isPlayerTurn = true,
        phase = BattlePhase.selectFirstMonster,
        lastActionMessage = null,
        battleLog = [];

  /// プレイヤーが追加でモンスターを出せるか
  bool get canPlayerSendMore => playerFieldMonsterIds.length < 3;

  /// 相手が追加でモンスターを出せるか
  bool get canEnemySendMore => enemyFieldMonsterIds.length < 3;

  /// 交代可能なモンスターが存在するか（既に使ったモンスター含む）
bool get hasAvailableSwitchMonster {
  return playerParty.any((m) => 
    !m.isFainted && 
    m.baseMonster.id != playerActiveMonster?.baseMonster.id
  );
}

  /// ★追加: プレイヤーが使用したモンスターIDリスト（Firestore保存用）
  List<String> get playerUsedMonsterIds => playerFieldMonsterIds.toList();

  /// ★追加: 相手が使用したモンスターIDリスト（Firestore保存用）
  List<String> get enemyUsedMonsterIds => enemyFieldMonsterIds.toList();

  /// モンスターが交代可能か判定（詳細ログ付き）
    bool canSwitchTo(String monsterId, {bool debug = false}) {
    if (debug) {
        print('=== canSwitchTo Debug ===');
        print('Target Monster ID: $monsterId');
        print('Active Monster ID: ${playerActiveMonster?.baseMonster.id}');
        print('Field Monster IDs: $playerFieldMonsterIds');
        print('canPlayerSendMore: $canPlayerSendMore');
    }
    
    // 現在場に出ているモンスターには交代できない
    if (playerActiveMonster?.baseMonster.id == monsterId) {
        if (debug) print('❌ Already active');
        return false;
    }
    
    // 瀕死のモンスターには交代できない
    final monster = playerParty.firstWhere(
        (m) => m.baseMonster.id == monsterId,
        orElse: () => throw Exception('Monster not found: $monsterId'),
    );
    
    if (monster.isFainted) {
        if (debug) print('❌ Fainted');
        return false;
    }
    
    // 既に場に出したモンスターは常に交代可能
    if (playerFieldMonsterIds.contains(monsterId)) {
        if (debug) print('✅ Already used, can switch back');
        return true;
    }
    
    // 新しいモンスターの場合は3体制限をチェック
    if (!canPlayerSendMore) {
        if (debug) print('❌ 3-monster limit reached');
        return false;
    }
    
    if (debug) print('✅ Can switch (new monster)');
    return true;
    }

  /// プレイヤーの勝利判定
  bool get isPlayerWin {
    // 場に出した相手のモンスターが全て瀕死
    if (enemyFieldMonsterIds.isEmpty) return false;
    
    final fieldMonsters = enemyParty
        .where((m) => enemyFieldMonsterIds.contains(m.baseMonster.id));
    
    if (fieldMonsters.isEmpty) return false;
    
    return fieldMonsters.every((m) => m.isFainted);
  }

  /// 相手の勝利判定
  bool get isEnemyWin {
    if (playerFieldMonsterIds.isEmpty) return false;
    
    final fieldMonsters = playerParty
        .where((m) => playerFieldMonsterIds.contains(m.baseMonster.id));
    
    if (fieldMonsters.isEmpty) return false;
    
    return fieldMonsters.every((m) => m.isFainted);
  }

  /// バトル終了判定
  bool get isBattleEnd => isPlayerWin || isEnemyWin;

  /// ログ追加
  void addLog(String message) {
    battleLog.add('[$turnNumber] $message');
    lastActionMessage = message;
  }
}

/// バトルフェーズ
enum BattlePhase {
  selectFirstMonster, // 初期モンスター選択
  actionSelect,       // 行動選択（技/交代/待機）
  executing,          // 行動実行中
  turnEnd,            // ターン終了処理
  monsterFainted,     // モンスター瀕死、交代選択
  battleEnd,          // バトル終了
}