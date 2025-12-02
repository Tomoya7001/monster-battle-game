// lib/presentation/screens/battle/pvp_battle_screen.dart
// PvPカジュアルマッチ用バトル画面（Lv50固定制、45秒制限、CPU AI付き）

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/monster.dart';
import '../../bloc/pvp_battle/pvp_battle_bloc.dart';
import '../../bloc/pvp_battle/pvp_battle_event.dart';
import '../../bloc/pvp_battle/pvp_battle_state.dart';
import 'battle_result_screen.dart';

/// PvPバトル画面
class PvpBattleScreen extends StatelessWidget {
  final List<Monster> playerParty;
  final String playerId;
  final String playerName;
  final String opponentName;
  final bool isCpuOpponent;

  const PvpBattleScreen({
    Key? key,
    required this.playerParty,
    required this.playerId,
    required this.playerName,
    required this.opponentName,
    this.isCpuOpponent = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PvpBattleBloc()
        ..add(StartCasualMatch(
          playerParty: playerParty,
          playerId: playerId,
          playerName: playerName,
          opponentName: opponentName,
          isCpuOpponent: isCpuOpponent,
        )),
      child: _PvpBattleContent(
        playerName: playerName,
        opponentName: opponentName,
        isCpuOpponent: isCpuOpponent,
      ),
    );
  }
}

class _PvpBattleContent extends StatefulWidget {
  final String playerName;
  final String opponentName;
  final bool isCpuOpponent;

  const _PvpBattleContent({
    required this.playerName,
    required this.opponentName,
    required this.isCpuOpponent,
  });

  @override
  State<_PvpBattleContent> createState() => _PvpBattleContentState();
}

class _PvpBattleContentState extends State<_PvpBattleContent> {
  // ターン制限タイマー
  Timer? _turnTimer;
  int _remainingSeconds = 45;
  int _consecutiveTimeouts = 0;
  
  // CPU思考タイマー
  Timer? _cpuThinkTimer;
  bool _isCpuThinking = false;

  @override
  void dispose() {
    _turnTimer?.cancel();
    _cpuThinkTimer?.cancel();
    super.dispose();
  }

  void _startTurnTimer() {
    _turnTimer?.cancel();
    _remainingSeconds = 45;

    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        timer.cancel();
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    _consecutiveTimeouts++;
    context.read<PvpBattleBloc>().add(
      TimeoutAction(consecutiveTimeouts: _consecutiveTimeouts),
    );
    
    if (_consecutiveTimeouts < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('時間切れ！待機を選択しました。次も時間切れで敗北です。'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _onActionSelected() {
    _turnTimer?.cancel();
    _consecutiveTimeouts = 0;
  }

  void _scheduleCpuAction() {
    if (!widget.isCpuOpponent || _isCpuThinking) return;

    _isCpuThinking = true;

    // CPU思考時間: 3〜10秒ランダム
    final thinkTime = 3 + Random().nextInt(8);

    _cpuThinkTimer = Timer(Duration(seconds: thinkTime), () {
      if (!mounted) return;
      _isCpuThinking = false;
      context.read<PvpBattleBloc>().add(const ExecuteCpuAction());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PvpBattleBloc, PvpBattleState>(
      listener: (context, state) {
        // バトル終了時
        if (state.status == PvpBattleStatus.finished && state.result != null) {
          _turnTimer?.cancel();
          _cpuThinkTimer?.cancel();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BattleResultScreen(
                result: state.result!,
              ),
            ),
          );
        }

        // プレイヤーのターン開始時
        if (state.status == PvpBattleStatus.inProgress && 
            state.isPlayerTurn &&
            !state.needsMonsterSwitch) {
          _startTurnTimer();
        }

        // CPUのターン時
        if (state.status == PvpBattleStatus.inProgress && 
            !state.isPlayerTurn && 
            widget.isCpuOpponent) {
          _scheduleCpuAction();
        }
      },
      builder: (context, state) {
        switch (state.status) {
          case PvpBattleStatus.initial:
          case PvpBattleStatus.loading:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );

          case PvpBattleStatus.error:
            return Scaffold(
              appBar: AppBar(title: const Text('エラー')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(state.errorMessage ?? 'エラーが発生しました'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('戻る'),
                    ),
                  ],
                ),
              ),
            );

          case PvpBattleStatus.selectingFirstMonster:
            return _buildMonsterSelectionScreen(state);

          case PvpBattleStatus.inProgress:
          case PvpBattleStatus.waitingForOpponent:
            return _buildBattleScreen(state);

          case PvpBattleStatus.finished:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
        }
      },
    );
  }

  /// 最初のモンスター選択画面
  Widget _buildMonsterSelectionScreen(PvpBattleState state) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('モンスターを選択'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'vs ${state.opponentName}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '最初に出すモンスターを選んでください',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: ListView.builder(
                itemCount: state.playerParty.length,
                itemBuilder: (context, index) {
                  final monster = state.playerParty[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getElementColor(monster.element),
                        child: Text(
                          monster.name.substring(0, 1),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        monster.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Lv.50 | HP: ${monster.maxHp} | 速: ${monster.speed}',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        context.read<PvpBattleBloc>().add(
                          SelectFirstMonster(monster),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// バトル画面
  Widget _buildBattleScreen(PvpBattleState state) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カジュアルマッチ'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _showBattleMenu(context),
        ),
        actions: [
          // ターン制限タイマー表示
          if (state.isPlayerTurn && !state.needsMonsterSwitch)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _remainingSeconds <= 10
                    ? Colors.red.withOpacity(0.8)
                    : Colors.blue.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    '$_remainingSeconds秒',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          
          // ターン表示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade700,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Turn ${state.turnCount}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 対戦相手エリア
          _buildOpponentArea(state),

          const Divider(height: 1),

          // バトルログ
          Expanded(child: _buildBattleLog(state)),

          const Divider(height: 1),

          // プレイヤーエリア
          _buildPlayerArea(state),

          // コマンドエリア or モンスター選択
          if (state.needsMonsterSwitch)
            _buildMonsterSwitchArea(state)
          else if (state.isPlayerTurn)
            _buildCommandArea(state)
          else
            _buildWaitingArea(),
        ],
      ),
    );
  }

  Widget _buildOpponentArea(PvpBattleState state) {
    final enemy = state.enemyActiveMonster;
    if (enemy == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.red.shade50,
      child: Row(
        children: [
          // 敵情報
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.opponentName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getElementColor(enemy.element),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${enemy.name} Lv.50',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // HPバー
                _buildHpBar(enemy.currentHp, enemy.maxHp, Colors.red),
              ],
            ),
          ),

          // コストゲージ
          _buildCostGauge(state.enemyCost, isEnemy: true),
          
          // 使用モンスター数
          const SizedBox(width: 8),
          _buildMonsterCount(state.enemyUsedMonsterCount, isEnemy: true),
        ],
      ),
    );
  }

  Widget _buildPlayerArea(PvpBattleState state) {
    final player = state.playerActiveMonster;
    if (player == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          // プレイヤー情報
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.playerName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getElementColor(player.element),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${player.name} Lv.50',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // HPバー
                _buildHpBar(player.currentHp, player.maxHp, Colors.green),
              ],
            ),
          ),

          // コストゲージ
          _buildCostGauge(state.playerCost, isEnemy: false),
          
          // 使用モンスター数
          const SizedBox(width: 8),
          _buildMonsterCount(state.playerUsedMonsterCount, isEnemy: false),
        ],
      ),
    );
  }

  Widget _buildHpBar(int current, int max, Color color) {
    final ratio = max > 0 ? current / max : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 12,
          width: 150,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(6),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: ratio.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: ratio > 0.5
                    ? Colors.green
                    : ratio > 0.25
                        ? Colors.orange
                        : Colors.red,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$current / $max',
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildCostGauge(int cost, {required bool isEnemy}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isEnemy ? Colors.red.shade100 : Colors.blue.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Text(
            'コスト',
            style: TextStyle(fontSize: 10),
          ),
          Text(
            '$cost',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isEnemy ? Colors.red : Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonsterCount(int count, {required bool isEnemy}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Text(
            '使用',
            style: TextStyle(fontSize: 10),
          ),
          Text(
            '$count/3',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBattleLog(PvpBattleState state) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: ListView.builder(
        reverse: true,
        itemCount: state.battleLog.length,
        itemBuilder: (context, index) {
          final log = state.battleLog[state.battleLog.length - 1 - index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              log,
              style: const TextStyle(fontSize: 12),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommandArea(PvpBattleState state) {
    final player = state.playerActiveMonster;
    if (player == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey.shade100,
      child: Column(
        children: [
          // 技ボタン（2×2グリッド）
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: player.skills.length,
            itemBuilder: (context, index) {
              final skill = player.skills[index];
              final canUse = skill.cost <= state.playerCost;

              return ElevatedButton(
                onPressed: canUse
                    ? () {
                        _onActionSelected();
                        context.read<PvpBattleBloc>().add(SelectSkill(skill));
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canUse
                      ? _getElementColor(skill.element)
                      : Colors.grey.shade400,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      skill.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'コスト${skill.cost} / 威力${skill.power}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          // 交代・待機ボタン
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.canSwitch
                      ? () {
                          _onActionSelected();
                          context.read<PvpBattleBloc>().add(const RequestSwitch());
                        }
                      : null,
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('交代'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _onActionSelected();
                    context.read<PvpBattleBloc>().add(const SelectWait());
                  },
                  icon: const Icon(Icons.hourglass_empty),
                  label: const Text('待機'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonsterSwitchArea(PvpBattleState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.orange.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.isForcedSwitch 
                ? '次のモンスターを選択（残り${3 - state.playerUsedMonsterCount}体）'
                : 'モンスターを選択',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: state.playerBench.length,
              itemBuilder: (context, index) {
                final monster = state.playerBench[index];
                final canSelect = monster.currentHp > 0 &&
                    state.playerUsedMonsterCount < 3;

                return GestureDetector(
                  onTap: canSelect
                      ? () {
                          _onActionSelected();
                          context.read<PvpBattleBloc>().add(
                            SelectSwitchMonster(monster),
                          );
                        }
                      : null,
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: canSelect ? Colors.white : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: canSelect 
                            ? _getElementColor(monster.element)
                            : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          monster.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: canSelect ? Colors.black : Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'HP: ${monster.currentHp}/${monster.maxHp}',
                          style: TextStyle(
                            fontSize: 10,
                            color: canSelect ? Colors.black54 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // キャンセルボタン（強制交代でない場合）
          if (!state.isForcedSwitch) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  context.read<PvpBattleBloc>().add(const RequestSwitch());
                },
                child: const Text('キャンセル'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWaitingArea() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.grey.shade200,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text(
            '相手のターン...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getElementColor(String element) {
    switch (element.toLowerCase()) {
      case 'fire':
        return Colors.red;
      case 'water':
        return Colors.blue;
      case 'thunder':
        return Colors.amber.shade700;
      case 'wind':
        return Colors.green;
      case 'earth':
        return Colors.brown;
      case 'light':
        return Colors.yellow.shade700;
      case 'dark':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _showBattleMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('設定'),
              onTap: () {
                Navigator.pop(ctx);
                // TODO: 設定画面
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.red),
              title: const Text(
                '降参',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showSurrenderDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('閉じる'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _showSurrenderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('降参'),
        content: const Text('本当に降参しますか？\nこの対戦は敗北となります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<PvpBattleBloc>().add(const Surrender());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('降参'),
          ),
        ],
      ),
    );
  }
}
