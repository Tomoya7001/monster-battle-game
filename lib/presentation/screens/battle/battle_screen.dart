import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/battle/battle_bloc.dart';
import '../../bloc/battle/battle_event.dart';
import '../../bloc/battle/battle_state.dart';
import '../../../domain/entities/monster.dart';
import '../../../domain/models/battle/battle_monster.dart';
import '../../../domain/models/battle/battle_skill.dart';
import '../../../domain/models/battle/battle_state_model.dart';

class BattleScreen extends StatelessWidget {
  final List<Monster> playerParty;

  const BattleScreen({
    Key? key,
    required this.playerParty,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BattleBloc()..add(StartCpuBattle(playerParty: playerParty)),
      child: const _BattleScreenContent(),
    );
  }
}

class _BattleScreenContent extends StatelessWidget {
  const _BattleScreenContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('バトル'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('バトル終了'),
                content: const Text('バトルを終了しますか？'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('キャンセル'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    child: const Text('終了'),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          // バトルログボタン
          BlocBuilder<BattleBloc, BattleState>(
            builder: (context, state) {
              if (state is BattleInProgress || 
                  state is BattlePlayerWin || 
                  state is BattlePlayerLose) {
                final battleState = state is BattleInProgress
                    ? state.battleState
                    : state is BattlePlayerWin
                        ? state.battleState
                        : (state as BattlePlayerLose).battleState;
                        
                return IconButton(
                  icon: const Icon(Icons.list),
                  onPressed: () => _showBattleLog(context, battleState),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<BattleBloc, BattleState>(
        listener: (context, state) {
          if (state is BattlePlayerWin) {
            _showResultDialog(context, '勝利！', Colors.green);
          } else if (state is BattlePlayerLose) {
            _showResultDialog(context, '敗北...', Colors.red);
          }
        },
        builder: (context, state) {
          if (state is BattleLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BattleError) {
            return Center(child: Text('エラー: ${state.message}'));
          }

          if (state is BattleInProgress) {
            return _buildBattleUI(context, state.battleState, state.message);
          }

          if (state is BattlePlayerWin || state is BattlePlayerLose) {
            final battleState = state is BattlePlayerWin
                ? state.battleState
                : (state as BattlePlayerLose).battleState;
            return _buildBattleUI(context, battleState, null);
          }

          return const Center(child: Text('バトル準備中...'));
        },
      ),
    );
  }

  Widget _buildBattleUI(BuildContext context, BattleStateModel battleState, String? message) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 
                     AppBar().preferredSize.height - 
                     MediaQuery.of(context).padding.top,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 相手のモンスター情報
            if (battleState.enemyActiveMonster != null)
              _buildMonsterInfo(battleState.enemyActiveMonster!, isEnemy: true),

            // メッセージ表示
            if (message != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              )
            else
              const SizedBox(height: 50),

            // 自分のモンスター情報
            if (battleState.playerActiveMonster != null)
              _buildMonsterInfo(battleState.playerActiveMonster!, isEnemy: false),

            // アクションボタン
            if (battleState.phase == BattlePhase.selectFirstMonster)
              _buildMonsterSelection(context, battleState)
            else if (battleState.phase == BattlePhase.actionSelect)
              _buildActionButtons(context, battleState)
            else if (battleState.phase == BattlePhase.monsterFainted)
              _buildMonsterSelection(context, battleState)
            else
              const SizedBox(height: 16),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMonsterInfo(BattleMonster monster, {required bool isEnemy}) {
    final hpPercentage = monster.hpPercentage;
    final hpColor = hpPercentage > 0.5
        ? Colors.green
        : hpPercentage > 0.25
            ? Colors.orange
            : Colors.red;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEnemy ? Colors.red.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnemy ? Colors.red.shade200 : Colors.blue.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                monster.baseMonster.monsterName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Lv.50',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // HP バー
          Row(
            children: [
              const Text('HP: '),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: hpPercentage,
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: hpColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('${monster.currentHp}/${monster.maxHp}'),
            ],
          ),

          const SizedBox(height: 8),

          // コストゲージ
          Row(
            children: [
              const Text('コスト: '),
              ...List.generate(monster.maxCost, (index) {
                return Container(
                  margin: const EdgeInsets.only(right: 4),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: index < monster.currentCost
                        ? (isEnemy ? Colors.red : Colors.blue)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
              const SizedBox(width: 8),
              Text('${monster.currentCost}/${monster.maxCost}'),
            ],
          ),

          const SizedBox(height: 4),

          // 属性表示
          Text(
            '属性: ${monster.baseMonster.elementName}',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, BattleStateModel battleState) {
    final activeMonster = battleState.playerActiveMonster;
    if (activeMonster == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 技ボタン（2x2グリッド）
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: activeMonster.skills.length,
            itemBuilder: (context, index) {
              final skill = activeMonster.skills[index];
              final canUse = activeMonster.canUseSkill(skill);

              return ElevatedButton(
                onPressed: canUse
                    ? () => context.read<BattleBloc>().add(UseSkill(skill: skill))
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canUse ? Colors.blue : Colors.grey,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      skill.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'コスト: ${skill.cost}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // 交代・待機ボタン
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: battleState.canPlayerSendMore
                      ? () => _showSwitchDialog(context, battleState)
                      : null,
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('交代'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.read<BattleBloc>().add(const WaitTurn()),
                  icon: const Icon(Icons.hourglass_empty),
                  label: const Text('待機'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonsterSelection(BuildContext context, BattleStateModel battleState, {bool isBottomSheet = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'モンスターを選択:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...battleState.playerParty.map((monster) {
            final isUsed = battleState.playerUsedMonsterIds.contains(monster.baseMonster.id);
            final isActive = battleState.playerActiveMonster?.baseMonster.id == monster.baseMonster.id;

            return ListTile(
              enabled: !isUsed || isActive,
              leading: CircleAvatar(
                backgroundColor: isActive
                    ? Colors.blue
                    : isUsed
                        ? Colors.grey
                        : Colors.green,
                child: Text(
                  monster.baseMonster.monsterName.substring(0, 1),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(monster.baseMonster.monsterName),
              subtitle: Text(
                isActive
                    ? '出撃中'
                    : isUsed
                        ? '使用済み'
                        : 'HP: ${monster.currentHp}/${monster.maxHp}',
              ),
              trailing: isUsed
                  ? const Icon(Icons.check, color: Colors.grey)
                  : const Icon(Icons.arrow_forward_ios),
              onTap: isUsed
                  ? null
                  : () {
                      if (isBottomSheet) {
                        Navigator.pop(context);
                      }
                      if (battleState.phase == BattlePhase.selectFirstMonster) {
                        context.read<BattleBloc>().add(
                          SelectFirstMonster(monsterId: monster.baseMonster.id),
                        );
                      } else {
                        context.read<BattleBloc>().add(
                          SwitchMonster(monsterId: monster.baseMonster.id),
                        );
                      }
                    },
            );
          }),
          const SizedBox(height: 8),
          Text(
            '使用可能: ${3 - battleState.playerUsedMonsterIds.length}体',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  void _showSwitchDialog(BuildContext context, BattleStateModel battleState) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: context.read<BattleBloc>(),
        child: _buildMonsterSelection(context, battleState, isBottomSheet: true),
      ),
    );
  }

  void _showBattleLog(BuildContext context, BattleStateModel battleState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('バトルログ'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: battleState.battleLog.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  battleState.battleLog[index],
                  style: const TextStyle(fontSize: 12),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showResultDialog(BuildContext context, String title, Color color) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          style: TextStyle(color: color, fontSize: 24),
          textAlign: TextAlign.center,
        ),
        content: const Text('バトルが終了しました'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}