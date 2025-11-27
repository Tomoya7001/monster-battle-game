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
import '../../widgets/battle/animated_hp_bar.dart';
import '../../widgets/battle/skill_effect_widget.dart';
import 'battle_result_screen.dart';

/// エフェクト対応バトル画面（差し替え版）
class BattleScreenWithEffects extends StatefulWidget {
  final List<Monster> playerParty;
  final StageData? stageData;

  const BattleScreenWithEffects({
    Key? key,
    required this.playerParty,
    this.stageData,
  }) : super(key: key);

  @override
  State<BattleScreenWithEffects> createState() => _BattleScreenWithEffectsState();
}

class _BattleScreenWithEffectsState extends State<BattleScreenWithEffects> {
  // エフェクト表示状態
  bool _showSkillEffect = false;
  String _effectElement = 'none';
  String _effectSkillType = 'physical';
  bool _isPlayerAttack = true;

  // ダメージ表示状態
  bool _showPlayerDamage = false;
  bool _showEnemyDamage = false;
  int _playerDamage = 0;
  int _enemyDamage = 0;
  bool _playerCritical = false;
  bool _enemyCritical = false;
  String? _playerEffectiveness;
  String? _enemyEffectiveness;

  // ヒットフラッシュ
  bool _playerHit = false;
  bool _enemyHit = false;

  // 前回HP（アニメーション用）
  int? _prevPlayerHp;
  int? _prevEnemyHp;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BattleBloc()
        ..add(
          widget.stageData != null
              ? StartStageBattle(playerParty: widget.playerParty, stageData: widget.stageData!)
              : StartCpuBattle(playerParty: widget.playerParty),
        ),
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: BlocConsumer<BattleBloc, BattleState>(
          listener: _handleBattleState,
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
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('バトル'),
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => _showBattleMenu(context),
      ),
      actions: [
        BlocBuilder<BattleBloc, BattleState>(
          builder: (context, state) {
            if (state is BattleInProgress) {
              return IconButton(
                icon: const Icon(Icons.list),
                onPressed: () => _showBattleLog(context, state.battleState),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  void _handleBattleState(BuildContext context, BattleState state) {
    if (state is BattlePlayerWin && state.result != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (ctx) => BattleResultScreen(
            result: state.result!,
            stageData: widget.stageData,
          ),
        ),
      );
    } else if (state is BattlePlayerLose && state.result != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (ctx) => BattleResultScreen(
            result: state.result!,
            stageData: widget.stageData,
          ),
        ),
      );
    }

    // HP変化検知（エフェクトトリガー）
    if (state is BattleInProgress) {
      final playerHp = state.battleState.playerActiveMonster?.currentHp;
      final enemyHp = state.battleState.enemyActiveMonster?.currentHp;

      if (_prevPlayerHp != null && playerHp != null && playerHp < _prevPlayerHp!) {
        _triggerPlayerDamage(_prevPlayerHp! - playerHp);
      }

      if (_prevEnemyHp != null && enemyHp != null && enemyHp < _prevEnemyHp!) {
        _triggerEnemyDamage(_prevEnemyHp! - enemyHp);
      }

      _prevPlayerHp = playerHp;
      _prevEnemyHp = enemyHp;
    }
  }

  void _triggerPlayerDamage(int damage) {
    setState(() {
      _playerDamage = damage;
      _showPlayerDamage = true;
      _playerHit = true;
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showPlayerDamage = false;
          _playerHit = false;
        });
      }
    });
  }

  void _triggerEnemyDamage(int damage) {
    setState(() {
      _enemyDamage = damage;
      _showEnemyDamage = true;
      _enemyHit = true;
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showEnemyDamage = false;
          _enemyHit = false;
        });
      }
    });
  }

  Widget _buildBattleUI(BuildContext context, BattleStateModel battleState, String? message) {
    return Stack(
      children: [
        // メインバトルUI
        Column(
          children: [
            // 相手モンスター
            if (battleState.enemyActiveMonster != null)
              _buildMonsterCard(
                battleState.enemyActiveMonster!,
                isEnemy: true,
                isHit: _enemyHit,
              ),

            // メッセージ
            _buildMessageBox(message),

            // 自分モンスター
            if (battleState.playerActiveMonster != null)
              _buildMonsterCard(
                battleState.playerActiveMonster!,
                isEnemy: false,
                isHit: _playerHit,
              ),

            // アクションボタン
            Expanded(
              child: _buildActionArea(context, battleState),
            ),
          ],
        ),

        // スキルエフェクトオーバーレイ
        if (_showSkillEffect)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: SkillEffectWidget(
                  element: _effectElement,
                  skillType: _effectSkillType,
                  isPlayerAttack: _isPlayerAttack,
                  onComplete: () {
                    setState(() {
                      _showSkillEffect = false;
                    });
                  },
                ),
              ),
            ),
          ),

        // ダメージ表示オーバーレイ（敵）
        if (_showEnemyDamage)
          Positioned(
            top: 120,
            left: 0,
            right: 0,
            child: Center(
              child: DamageText(
                damage: _enemyDamage,
                isCritical: _enemyCritical,
                effectivenessText: _enemyEffectiveness,
              ),
            ),
          ),

        // ダメージ表示オーバーレイ（自分）
        if (_showPlayerDamage)
          Positioned(
            bottom: 250,
            left: 0,
            right: 0,
            child: Center(
              child: DamageText(
                damage: _playerDamage,
                isCritical: _playerCritical,
                effectivenessText: _playerEffectiveness,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMonsterCard(BattleMonster monster, {required bool isEnemy, required bool isHit}) {
    return HitFlashWidget(
      isHit: isHit,
      child: Container(
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
            // 名前と属性
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

            // HPバー（アニメーション付き）
            Row(
              children: [
                const Text('HP: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${monster.currentHp} / ${monster.maxHp}'),
                      const SizedBox(height: 4),
                      AnimatedHpBar(
                        currentHp: monster.currentHp,
                        maxHp: monster.maxHp,
                        showDamageFlash: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // コストゲージ
            _buildCostGauge(monster, isEnemy),

            // 状態異常
            if (monster.statusAilment != null) ...[
              const SizedBox(height: 8),
              _buildStatusAilmentDisplay(monster.statusAilment!, monster.statusTurns),
            ],

            // バフ/デバフ
            if (_hasStatChanges(monster)) ...[
              const SizedBox(height: 8),
              _buildStatChangesDisplay(monster),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCostGauge(BattleMonster monster, bool isEnemy) {
    return Row(
      children: [
        const Text('コスト: ', style: TextStyle(fontWeight: FontWeight.bold)),
        ...List.generate(monster.maxCost, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(right: 4),
            width: 16,
            height: 16,
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
    );
  }

  Widget _buildMessageBox(String? message) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(minHeight: 50),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            message ?? '',
            key: ValueKey(message),
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildActionArea(BuildContext context, BattleStateModel battleState) {
    if (battleState.phase == BattlePhase.selectFirstMonster ||
        battleState.phase == BattlePhase.monsterFainted) {
      return _buildMonsterSelection(context, battleState);
    }

    if (battleState.phase == BattlePhase.actionSelect) {
      return _buildActionButtons(context, battleState);
    }

    return const SizedBox.shrink();
  }

  Widget _buildActionButtons(BuildContext context, BattleStateModel battleState) {
    final activeMonster = battleState.playerActiveMonster;
    if (activeMonster == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 技ボタン（2x2グリッド）
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: activeMonster.skills.length,
              itemBuilder: (context, index) {
                final skill = activeMonster.skills[index];
                return _buildSkillButton(context, skill, activeMonster);
              },
            ),
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
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkillButton(BuildContext context, BattleSkill skill, BattleMonster monster) {
    final canUse = monster.canUseSkill(skill);
    final elementColor = _getElementColor(skill.element);

    return ElevatedButton(
      onPressed: canUse
          ? () {
              // エフェクト再生
              setState(() {
                _showSkillEffect = true;
                _effectElement = skill.element;
                _effectSkillType = skill.type;
                _isPlayerAttack = true;
              });

              // 技使用
              Future.delayed(const Duration(milliseconds: 400), () {
                context.read<BattleBloc>().add(UseSkill(skill: skill));
              });
            }
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
                  Text('${skill.cost}', style: const TextStyle(fontSize: 11)),
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
                  Text('${skill.accuracy}%', style: const TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonsterSelection(BuildContext context, BattleStateModel battleState) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'モンスターを選択 (${battleState.playerFieldMonsterIds.length}/3体使用中)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: battleState.playerParty.length,
              itemBuilder: (context, index) {
                final monster = battleState.playerParty[index];
                return _buildMonsterSelectionTile(context, battleState, monster);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonsterSelectionTile(
    BuildContext context,
    BattleStateModel battleState,
    BattleMonster monster,
  ) {
    final monsterId = monster.baseMonster.id;
    final isActive = battleState.playerActiveMonster?.baseMonster.id == monsterId;
    final isFainted = monster.isFainted;
    final canSwitch = battleState.canSwitchTo(monsterId);

    Color backgroundColor;
    String subtitle;
    IconData icon;

    if (isActive) {
      backgroundColor = Colors.blue;
      subtitle = '出撃中';
      icon = Icons.check_circle;
    } else if (isFainted) {
      backgroundColor = Colors.red;
      subtitle = '瀕死';
      icon = Icons.cancel;
    } else if (canSwitch) {
      backgroundColor = Colors.green;
      subtitle = 'HP: ${monster.currentHp}/${monster.maxHp}';
      icon = Icons.arrow_forward_ios;
    } else {
      backgroundColor = Colors.grey;
      subtitle = 'HP: ${monster.currentHp}/${monster.maxHp} (3体制限)';
      icon = Icons.block;
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
        style: TextStyle(color: canSwitch ? Colors.black : Colors.grey),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: canSwitch ? Colors.black87 : Colors.grey,
          fontSize: 12,
        ),
      ),
      trailing: Icon(icon, color: canSwitch ? backgroundColor : Colors.grey),
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
              }
            }
          : null,
    );
  }

  // ヘルパーウィジェット
  Widget _buildElementBadge(String element) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getElementColor(element),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getElementName(element),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusAilmentDisplay(String ailment, int turns) {
    final data = _getStatusAilmentData(ailment);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: data['color'],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data['icon'], size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '${data['name']} (${turns}T)',
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

  bool _hasStatChanges(BattleMonster monster) {
    return monster.attackStage != 0 ||
        monster.defenseStage != 0 ||
        monster.magicStage != 0 ||
        monster.speedStage != 0;
  }

  Widget _buildStatChangesDisplay(BattleMonster monster) {
    final statChips = <Widget>[];
    final changes = {
      '攻': monster.attackStage,
      '防': monster.defenseStage,
      '魔': monster.magicStage,
      '速': monster.speedStage,
    };

    changes.forEach((stat, stage) {
      if (stage != 0) {
        final isPositive = stage > 0;
        final arrow = isPositive ? '↑' : '↓';
        statChips.add(Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isPositive ? Colors.green.shade100 : Colors.red.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$stat$arrow${stage.abs()}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ));
      }
    });

    return Wrap(spacing: 4, children: statChips);
  }

  void _showSwitchDialog(BuildContext context, BattleStateModel battleState) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: context.read<BattleBloc>(),
        child: _buildMonsterSelection(context, battleState),
      ),
    );
  }

  void _showBattleMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('メニュー'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('設定'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.red),
              title: const Text('降参'),
              onTap: () {
                Navigator.pop(ctx);
                _confirmSurrender(context);
              },
            ),
          ],
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

  void _confirmSurrender(BuildContext context) {
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
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<BattleBloc>().add(const ForceBattleEnd());
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('降参'),
          ),
        ],
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
                child: ListView.builder(
                  itemCount: battleState.battleLog.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(battleState.battleLog[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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
        return Colors.grey;
    }
  }

  String _getElementName(String element) {
    switch (element.toLowerCase()) {
      case 'fire':
        return '炎';
      case 'water':
        return '水';
      case 'thunder':
        return '雷';
      case 'wind':
        return '風';
      case 'earth':
        return '地';
      case 'light':
        return '光';
      case 'dark':
        return '闇';
      default:
        return '無';
    }
  }

  Map<String, dynamic> _getStatusAilmentData(String ailment) {
    switch (ailment) {
      case 'burn':
        return {'name': 'やけど', 'icon': Icons.local_fire_department, 'color': Colors.orange.shade600};
      case 'poison':
        return {'name': 'どく', 'icon': Icons.science, 'color': Colors.purple.shade600};
      case 'paralysis':
        return {'name': 'まひ', 'icon': Icons.flash_on, 'color': Colors.yellow.shade700};
      case 'sleep':
        return {'name': 'ねむり', 'icon': Icons.bedtime, 'color': Colors.blue.shade600};
      case 'freeze':
        return {'name': 'こおり', 'icon': Icons.ac_unit, 'color': Colors.cyan.shade600};
      case 'confusion':
        return {'name': 'こんらん', 'icon': Icons.psychology, 'color': Colors.pink.shade600};
      default:
        return {'name': ailment, 'icon': Icons.help_outline, 'color': Colors.grey.shade600};
    }
  }
}