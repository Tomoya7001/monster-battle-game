import 'battle_monster.dart';
import 'battle_skill.dart';

/// バトル全体の状態
class BattleStateModel {
  final String battleType; // 'cpu', 'pvp', 'adventure', 'boss'
  final int maxDeployableCount; // 最大出撃数（通常3、冒険エンカウント1）
  // プレイヤー側
  final List<BattleMonster> playerParty; // 手持ち5体
  final Set<String> playerFieldMonsterIds; // 場に出したモンスターID（瀕死含む、最大3体）
  BattleMonster? playerActiveMonster;
  bool playerSwitchedThisTurn;

  // 相手側（CPU）
  final List<BattleMonster> enemyParty;
  final Set<String> enemyFieldMonsterIds; // 場に出したモンスターID
  BattleMonster? enemyActiveMonster;
  bool enemySwitchedThisTurn;

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
    this.battleType = 'cpu',
    this.maxDeployableCount = 3,
  })  : playerFieldMonsterIds = {},
        enemyFieldMonsterIds = {},
        playerActiveMonster = null,
        enemyActiveMonster = null,
        playerSwitchedThisTurn = false,
        enemySwitchedThisTurn = false,
        turnNumber = 1,
        isPlayerTurn = true,
        phase = BattlePhase.selectFirstMonster,
        lastActionMessage = null,
        battleLog = [];

  /// プレイヤーが追加でモンスターを出せるか
  bool get canPlayerSendMore => playerFieldMonsterIds.length < maxDeployableCount;

  /// 相手が追加でモンスターを出せるか
  bool get canEnemySendMore => enemyFieldMonsterIds.length < maxDeployableCount;

  /// ★修正: 交代可能なモンスターが存在するか（3体制限を考慮）
  bool get hasAvailableSwitchMonster {
    return playerParty.any((m) {
      // 瀕死は交代不可
      if (m.isFainted) return false;
      // 現在出撃中は交代不可
      if (m.baseMonster.id == playerActiveMonster?.baseMonster.id) return false;
      // 既に場に出したモンスターは交代可能（瀕死でなければ戻れる）
      if (playerFieldMonsterIds.contains(m.baseMonster.id)) return true;
      // 新しいモンスターの場合は3体制限をチェック
      return canPlayerSendMore;
    });
  }

  /// ★追加: 敵側の交代可能判定
  bool get hasEnemyAvailableSwitchMonster {
    return enemyParty.any((m) {
      if (m.isFainted) return false;
      if (m.baseMonster.id == enemyActiveMonster?.baseMonster.id) return false;
      if (enemyFieldMonsterIds.contains(m.baseMonster.id)) return true;
      return canEnemySendMore;
    });
  }

  /// プレイヤーが使用したモンスターIDリスト（Firestore保存用）
  List<String> get playerUsedMonsterIds => playerFieldMonsterIds.toList();

  /// 相手が使用したモンスターIDリスト（Firestore保存用）
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
    // 敵のアクティブモンスターが瀕死
    if (enemyActiveMonster == null || !enemyActiveMonster!.isFainted) {
      return false;
    }
    
    // 敵に交代可能なモンスターがいない
    return !hasEnemyAvailableSwitchMonster;
  }

  /// ★修正: 相手の勝利判定（シンプル化）
  bool get isEnemyWin {
    // プレイヤーのアクティブモンスターが瀕死
    if (playerActiveMonster == null || !playerActiveMonster!.isFainted) {
      return false;
    }
    
    // プレイヤーに交代可能なモンスターがいない
    return !hasAvailableSwitchMonster;
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