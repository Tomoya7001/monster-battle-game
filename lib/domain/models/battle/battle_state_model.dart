import 'battle_monster.dart';
import 'battle_skill.dart';

/// バトル全体の状態
class BattleStateModel {
  // プレイヤー側
  final List<BattleMonster> playerParty; // 手持ち5体
  final Set<String> playerFieldMonsterIds; // ★修正: 場に出したモンスターID（瀕死含む、最大3体）
  BattleMonster? playerActiveMonster;

  // 相手側（CPU）
  final List<BattleMonster> enemyParty;
  final Set<String> enemyFieldMonsterIds; // ★修正: 場に出したモンスターID
  BattleMonster? enemyActiveMonster;

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
        turnNumber = 1,
        isPlayerTurn = true,
        phase = BattlePhase.selectFirstMonster,
        lastActionMessage = null,
        battleLog = [];

  /// プレイヤーが追加でモンスターを出せるか
  bool get canPlayerSendMore => playerFieldMonsterIds.length < 3;

  /// 相手が追加でモンスターを出せるか
  bool get canEnemySendMore => enemyFieldMonsterIds.length < 3;

  /// ★追加: モンスターが交代可能か判定
  bool canSwitchTo(String monsterId) {
    // 現在場に出ているモンスターには交代できない
    if (playerActiveMonster?.baseMonster.id == monsterId) {
      return false;
    }
    
    // 瀕死のモンスターには交代できない
    final monster = playerParty.firstWhere(
      (m) => m.baseMonster.id == monsterId,
      orElse: () => throw Exception('Monster not found'),
    );
    
    if (monster.isFainted) {
      return false;
    }
    
    // 3体制限チェック（新しいモンスターの場合のみ）
    if (!playerFieldMonsterIds.contains(monsterId) && !canPlayerSendMore) {
      return false;
    }
    
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