import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/battle/battle_bloc.dart';
import '../../bloc/battle/battle_event.dart';
import '../../bloc/battle/battle_state.dart';
import '../../../domain/entities/monster.dart';
import '../../../domain/models/battle/battle_monster.dart';
import '../../../domain/models/battle/battle_skill.dart';
import '../../../domain/models/battle/battle_state_model.dart';
import '../../../domain/models/stage/stage_data.dart';
import 'battle_result_screen.dart';
import 'battle_result_screen_enhanced.dart'; // ★追加: 強化版結果画面
import '../../widgets/battle/battle_effect_widgets.dart';

class BattleScreen extends StatelessWidget {
  final List<Monster> playerParty;
  final StageData? stageData;

  const BattleScreen({
    Key? key,
    required this.playerParty,
    this.stageData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BattleBloc()
        ..add(
          stageData != null
              ? StartStageBattle(playerParty: playerParty, stageData: stageData!)
              : StartCpuBattle(playerParty: playerParty),
        ),
      child: _BattleScreenContent(stageData: stageData),
    );
  }
}

// ★修正: StatefulWidget に変更（エフェクトコントローラー用）
class _BattleScreenContent extends StatefulWidget {
  final StageData? stageData;

  const _BattleScreenContent({
    Key? key,
    this.stageData,
  }) : super(key: key);

  @override
  State<_BattleScreenContent> createState() => _BattleScreenContentState();
}

class _BattleScreenContentState extends State<_BattleScreenContent> {
  // ★追加: エフェクトコントローラー
  final BattleEffectController _effectController = BattleEffectController();

  @override
  void dispose() {
    _effectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ★修正: BattleEffectOverlay でラップ
    return BattleEffectOverlay(
      controller: _effectController,
      child: Scaffold(
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
            // ★追加: ダメージエフェクトのトリガー
            if (state is BattleInProgress) {
              final damageInfo = state.battleState.lastDamageInfo;
              if (damageInfo != null) {
                // 技エフェクト表示
                _effectController.triggerSkillEffect(
                  skillType: damageInfo.skillType,
                  element: damageInfo.element,
                  targetIsPlayer: damageInfo.targetIsPlayer,
                );
                
                // ダメージ数値表示（少し遅延）
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    _effectController.triggerDamage(
                      damage: damageInfo.damage,
                      isCritical: damageInfo.isCritical,
                      isEffective: damageInfo.isEffective,
                      isResisted: damageInfo.isResisted,
                      isHeal: damageInfo.isHeal,
                      targetIsPlayer: damageInfo.targetIsPlayer,
                    );
                  }
                });
              }
            }

            // 勝利時
            if (state is BattlePlayerWin) {
              if (state.result != null) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => BattleResultScreenEnhanced( // ★修正: 強化版に変更
                      result: state.result!,
                      stageData: widget.stageData,
                    ),
                  ),
                );
              } else {
                _showResultDialog(context, '勝利！', Colors.green);
              }
            } 
            // 敗北時
            else if (state is BattlePlayerLose) {
              if (state.result != null) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => BattleResultScreenEnhanced( // ★修正: 強化版に変更
                      result: state.result!,
                      stageData: widget.stageData,
                    ),
                  ),
                );
              } else {
                _showResultDialog(context, '敗北...', Colors.red);
              }
            } 
            // ネットワークエラー
            else if (state is BattleNetworkError) {
              _showErrorDialog(
                context,
                'ネットワークエラー',
                state.message,
                canRetry: state.canRetry,
              );
            } 
            // データエラー
            else if (state is BattleDataError) {
              _showErrorDialog(
                context,
                'データエラー',
                state.message,
                canRetry: false,
              );
            }
          },
          builder: (context, state) {
            if (state is BattleLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is BattleNetworkError) {
              return _buildErrorView(
                context,
                state.battleState,
                'ネットワークエラー',
                state.message,
                canRetry: state.canRetry,
              );
            }

            if (state is BattleDataError) {
              return _buildErrorView(
                context,
                null,
                'データエラー',
                state.message,
                canRetry: false,
              );
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
      ),
    );
  }
  
  Widget _buildErrorView(
    BuildContext context,
    BattleStateModel? battleState,
    String title,
    String message, {
    bool canRetry = true,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 72,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            
            if (canRetry) ...[
              ElevatedButton.icon(
                onPressed: () {
                  context.read<BattleBloc>().add(const RetryAfterError());
                },
                icon: const Icon(Icons.refresh),
                label: const Text('再試行'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            OutlinedButton.icon(
              onPressed: () {
                context.read<BattleBloc>().add(const ForceBattleEnd());
                Navigator.pop(context);
              },
              icon: const Icon(Icons.close),
              label: const Text('バトルを終了'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(
    BuildContext context,
    String title,
    String message, {
    bool canRetry = true,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          if (canRetry)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.read<BattleBloc>().add(const RetryAfterError());
              },
              child: const Text('再試行'),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<BattleBloc>().add(const ForceBattleEnd());
              Navigator.pop(context);
            },
            child: const Text('終了'),
          ),
        ],
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
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
        color: isEnemy ? Colors.red.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isEnemy ? Colors.red.shade200 : Colors.blue.shade200,
            width: 2,
        ),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // モンスター名と属性
            Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                Expanded(
                child: Text(
                    monster.baseMonster.monsterName,
                    style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    ),
                ),
                ),
                _buildElementBadge(monster.baseMonster.elementName),
            ],
            ),
            
            const SizedBox(height: 8),

            // HP情報（アニメーション付き）
            Row(
              children: [
                const Text('HP: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: AnimatedHpBar(
                    currentHp: monster.currentHp,
                    maxHp: monster.maxHp,
                    height: 12,
                    showValue: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // コストゲージ（アニメーション付き）
            Row(
              children: [
                const Text('コスト: ', style: TextStyle(fontWeight: FontWeight.bold)),
                AnimatedCostGauge(
                  currentCost: monster.currentCost,
                  maxCost: monster.maxCost,
                  activeColor: isEnemy ? Colors.red : Colors.blue,
                ),
                const SizedBox(width: 8),
                Text('${monster.currentCost}/${monster.maxCost}'),
              ],
            ),

            // 状態異常表示
            if (monster.statusAilment != null) ...[
            const SizedBox(height: 8),
            _buildStatusAilmentDisplay(monster.statusAilment!, monster.statusTurns),
            ],

            // バフ/デバフ表示
            if (_hasStatChanges(monster)) ...[
            const SizedBox(height: 8),
            _buildStatChangesDisplay(monster),
            ],
        ],
        ),
    );
  }

  Widget _buildStatusAilmentDisplay(String ailment, int turns) {
    final statusData = _getStatusAilmentData(ailment);
    
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
        color: statusData['color'],
        borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
            Icon(statusData['icon'], size: 16, color: Colors.white),
            const SizedBox(width: 4),
            Text(
            '${statusData['name']} (${turns}T)',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
            ),
            ),
        ],
        ),
    );
  }

  Map<String, dynamic> _getStatusAilmentData(String ailment) {
    switch (ailment) {
        case 'burn':
        return {
            'name': 'やけど',
            'icon': Icons.local_fire_department,
            'color': Colors.orange.shade600,
        };
        case 'poison':
        return {
            'name': 'どく',
            'icon': Icons.science,
            'color': Colors.purple.shade600,
        };
        case 'paralysis':
        return {
            'name': 'まひ',
            'icon': Icons.flash_on,
            'color': Colors.yellow.shade700,
        };
        case 'sleep':
        return {
            'name': 'ねむり',
            'icon': Icons.bedtime,
            'color': Colors.blue.shade600,
        };
        case 'freeze':
        return {
            'name': 'こおり',
            'icon': Icons.ac_unit,
            'color': Colors.cyan.shade600,
        };
        case 'confusion':
        return {
            'name': 'こんらん',
            'icon': Icons.psychology,
            'color': Colors.pink.shade600,
        };
        default:
        return {
            'name': ailment,
            'icon': Icons.help_outline,
            'color': Colors.grey.shade600,
        };
    }
  }

  bool _hasStatChanges(BattleMonster monster) {
    return monster.attackStage != 0 ||
        monster.defenseStage != 0 ||
        monster.magicStage != 0 ||
        monster.speedStage != 0 ||
        monster.accuracyStage != 0 ||
        monster.evasionStage != 0;
  }

  Widget _buildStatChangesDisplay(BattleMonster monster) {
    final List<Widget> statChips = [];

    final statChanges = {
      '攻': monster.attackStage,
      '防': monster.defenseStage,
      '魔': monster.magicStage,
      '速': monster.speedStage,
      '命': monster.accuracyStage,
      '回': monster.evasionStage,
    };

    statChanges.forEach((stat, stage) {
      if (stage != 0) {
        statChips.add(_buildStatChip(stat, stage, monster));
      }
    });

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: statChips,
    );
  }

  Widget _buildStatChip(String statName, int stage, BattleMonster monster) {
    final isPositive = stage > 0;
    final absStage = stage.abs();
    final arrow = isPositive ? '↑' : '↓';
    final arrowText = arrow * absStage.clamp(1, 3);
    
    int turnsRemaining = 0;
    switch (statName) {
      case '攻':
        turnsRemaining = monster.attackStageTurns;
        break;
      case '防':
        turnsRemaining = monster.defenseStageTurns;
        break;
      case '魔':
        turnsRemaining = monster.magicStageTurns;
        break;
      case '速':
        turnsRemaining = monster.speedStageTurns;
        break;
      case '命':
        turnsRemaining = monster.accuracyStageTurns;
        break;
      case '回':
        turnsRemaining = monster.evasionStageTurns;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isPositive ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPositive ? Colors.green.shade300 : Colors.red.shade300,
        ),
      ),
      child: Text(
        turnsRemaining > 0 ? '$statName$arrowText(${turnsRemaining}T)' : '$statName$arrowText',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
        ),
      ),
    );
  }

  Widget _buildElementBadge(String element) {
    final elementColors = {
        'fire': Colors.orange,
        'water': Colors.blue,
        'thunder': Colors.yellow.shade700,
        'wind': Colors.green,
        'earth': Colors.brown,
        'light': Colors.amber,
        'dark': Colors.purple,
        'none': Colors.grey,
    };

    final elementNames = {
        'fire': '炎',
        'water': '水',
        'thunder': '雷',
        'wind': '風',
        'earth': '地',
        'light': '光',
        'dark': '闇',
        'none': '無',
    };

    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
        color: elementColors[element] ?? Colors.grey,
        borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
        elementNames[element] ?? element,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
        ),
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
              childAspectRatio: 2.0,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: activeMonster.skills.length,
            itemBuilder: (context, index) {
              final skill = activeMonster.skills[index];
              final canUse = activeMonster.canUseSkill(skill);

              final elementColor = _getElementColor(skill.element);

              return ElevatedButton(
                onPressed: canUse
                    ? () => context.read<BattleBloc>().add(UseSkill(skill: skill))
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canUse ? elementColor : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.flash_on, size: 12),
                            Text(
                              '${skill.cost}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                        if (skill.powerMultiplier > 0)
                          Text(
                            '${(skill.powerMultiplier * 100).toInt()}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        Row(
                          children: [
                            const Icon(Icons.gps_fixed, size: 10),
                            Text(
                              '${skill.accuracy}%',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    if (skill.effects.isNotEmpty)
                      const SizedBox(height: 2),
                    if (skill.effects.isNotEmpty)
                      Row(
                        children: [
                          if (skill.effects.containsKey('status_ailment'))
                            const Icon(Icons.warning_amber, size: 11),
                          if (skill.effects.containsKey('buff') || skill.effects.containsKey('debuff'))
                            const Icon(Icons.trending_up, size: 11),
                        ],
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
                  onPressed: battleState.hasAvailableSwitchMonster
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

  Color _getElementColor(String element) {
    switch (element.toLowerCase()) {
      case 'fire':
        return Colors.deepOrange;
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
        return Colors.purple.shade700;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _buildMonsterSelection(BuildContext context, BattleStateModel battleState, {bool isBottomSheet = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'モンスターを選択: (${battleState.playerFieldMonsterIds.length}/3体使用中)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...battleState.playerParty.map((monster) {
              final monsterId = monster.baseMonster.id;
              final isActive = battleState.playerActiveMonster?.baseMonster.id == monsterId;
              final isFainted = monster.isFainted;
              final isFieldMonster = battleState.playerFieldMonsterIds.contains(monsterId);
              
              final canSwitch = battleState.canSwitchTo(monsterId);

              String subtitle;
              Color backgroundColor;
              IconData icon;
              
              if (isActive) {
                  subtitle = '出撃中';
                  backgroundColor = Colors.blue;
                  icon = Icons.check_circle;
              } else if (isFainted) {
                  subtitle = '瀕死';
                  backgroundColor = Colors.red;
                  icon = Icons.cancel;
              } else if (isFieldMonster) {
                  subtitle = 'HP: ${monster.currentHp}/${monster.maxHp} (戻せます)';
                  backgroundColor = Colors.orange;
                  icon = Icons.arrow_back;
              } else if (!battleState.canPlayerSendMore) {
                  subtitle = 'HP: ${monster.currentHp}/${monster.maxHp} (3体制限)';
                  backgroundColor = Colors.grey;
                  icon = Icons.block;
              } else {
                  subtitle = 'HP: ${monster.currentHp}/${monster.maxHp}';
                  backgroundColor = Colors.green;
                  icon = Icons.arrow_forward_ios;
              }

              return ListTile(
                  enabled: canSwitch,
                  leading: CircleAvatar(
                  backgroundColor: canSwitch ? backgroundColor : Colors.grey,
                  child: Text(
                      monster.baseMonster.monsterName.substring(0, 1),
                      style: const TextStyle(color: Colors.white),
                  ),
                  ),
                  title: Text(
                  monster.baseMonster.monsterName,
                  style: TextStyle(
                      color: canSwitch ? Colors.black : Colors.grey,
                  ),
                  ),
                  subtitle: Text(
                  subtitle,
                  style: TextStyle(
                      color: canSwitch ? Colors.black87 : Colors.grey,
                      fontSize: 12,
                  ),
                  ),
                  trailing: Icon(
                  icon,
                  color: canSwitch ? backgroundColor : Colors.grey,
                  ),
                  onTap: canSwitch
                      ? () {
                          if (battleState.phase == BattlePhase.selectFirstMonster) {
                          context.read<BattleBloc>().add(SelectFirstMonster(monsterId: monsterId));
                          } else {
                          final isForcedSwitch = battleState.phase == BattlePhase.monsterFainted;
                          context.read<BattleBloc>().add(SwitchMonster(
                            monsterId: monsterId,
                            isForcedSwitch: isForcedSwitch,
                          ));
                          if (isBottomSheet) {
                              Navigator.pop(context);
                          }
                          }
                      }
                      : null,
              );
          }).toList(),
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
      builder: (ctx) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'バトルログ',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              
              Expanded(
                child: battleState.battleLog.isEmpty
                    ? const Center(
                        child: Text(
                          'ログはまだありません',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: battleState.battleLog.length,
                        itemBuilder: (context, index) {
                          final log = battleState.battleLog[index];
                          return _buildLogItem(log);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogItem(String log) {
    LogType logType = _detectLogType(log);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: logType.backgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: logType.borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            logType.icon,
            size: 16,
            color: logType.iconColor,
          ),
          const SizedBox(width: 8),
          
          Expanded(
            child: Text(
              log,
              style: TextStyle(
                fontSize: 13,
                color: logType.textColor,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  LogType _detectLogType(String log) {
    if (log.contains('ダメージ') || log.contains('攻撃')) {
      return LogType(
        icon: Icons.flash_on,
        iconColor: Colors.red.shade700,
        backgroundColor: Colors.red.shade50,
        borderColor: Colors.red.shade200,
        textColor: Colors.red.shade900,
      );
    }
    
    if (log.contains('回復')) {
      return LogType(
        icon: Icons.favorite,
        iconColor: Colors.green.shade700,
        backgroundColor: Colors.green.shade50,
        borderColor: Colors.green.shade200,
        textColor: Colors.green.shade900,
      );
    }
    
    if (log.contains('やけど') || log.contains('どく') || log.contains('まひ') ||
        log.contains('ねむり') || log.contains('こおり') || log.contains('こんらん')) {
      return LogType(
        icon: Icons.warning,
        iconColor: Colors.purple.shade700,
        backgroundColor: Colors.purple.shade50,
        borderColor: Colors.purple.shade200,
        textColor: Colors.purple.shade900,
      );
    }
    
    if (log.contains('上がった') || log.contains('下がった') || log.contains('元に戻った')) {
      return LogType(
        icon: Icons.trending_up,
        iconColor: Colors.blue.shade700,
        backgroundColor: Colors.blue.shade50,
        borderColor: Colors.blue.shade200,
        textColor: Colors.blue.shade900,
      );
    }
    
    if (log.contains('繰り出した') || log.contains('交代')) {
      return LogType(
        icon: Icons.swap_horiz,
        iconColor: Colors.orange.shade700,
        backgroundColor: Colors.orange.shade50,
        borderColor: Colors.orange.shade200,
        textColor: Colors.orange.shade900,
      );
    }
    
    if (log.contains('倒れた')) {
      return LogType(
        icon: Icons.cancel,
        iconColor: Colors.grey.shade700,
        backgroundColor: Colors.grey.shade100,
        borderColor: Colors.grey.shade300,
        textColor: Colors.grey.shade900,
      );
    }
    
    return LogType(
      icon: Icons.info_outline,
      iconColor: Colors.grey.shade600,
      backgroundColor: Colors.grey.shade50,
      borderColor: Colors.grey.shade200,
      textColor: Colors.grey.shade800,
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

class LogType {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  LogType({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });
}