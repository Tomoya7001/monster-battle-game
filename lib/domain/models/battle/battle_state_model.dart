import 'battle_monster.dart';
import 'battle_skill.dart';

/// バトル全体の状態
class BattleStateModel {
  // プレイヤー側
  final List<BattleMonster> playerParty; // 手持ち5体
  final List<String> playerUsedMonsterIds; // 使用済みモンスターID（最大3体）
  BattleMonster? playerActiveMonster;

  // 相手側（CPU）
  final List<BattleMonster> enemyParty;
  final List<String> enemyUsedMonsterIds;
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
  })  : playerUsedMonsterIds = [],
        enemyUsedMonsterIds = [],
        playerActiveMonster = null,
        enemyActiveMonster = null,
        turnNumber = 1,
        isPlayerTurn = true,
        phase = BattlePhase.selectFirstMonster,
        lastActionMessage = null,
        battleLog = [];

  /// プレイヤーが追加でモンスターを出せるか
  bool get canPlayerSendMore => playerUsedMonsterIds.length < 3;

  /// 相手が追加でモンスターを出せるか
  bool get canEnemySendMore => enemyUsedMonsterIds.length < 3;

  /// プレイヤーの勝利判定
  bool get isPlayerWin {
    // 相手の使用済み3体が全て瀕死
    if (enemyUsedMonsterIds.length >= 3) {
      return enemyParty
          .where((m) => enemyUsedMonsterIds.contains(m.baseMonster.id))
          .every((m) => m.isFainted);
    }
    // または相手のアクティブが瀕死で、これ以上出せない
    if (enemyActiveMonster?.isFainted == true && !canEnemySendMore) {
      return true;
    }
    return false;
  }

  /// 相手の勝利判定
  bool get isEnemyWin {
    if (playerUsedMonsterIds.length >= 3) {
      return playerParty
          .where((m) => playerUsedMonsterIds.contains(m.baseMonster.id))
          .every((m) => m.isFainted);
    }
    if (playerActiveMonster?.isFainted == true && !canPlayerSendMore) {
      return true;
    }
    return false;
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