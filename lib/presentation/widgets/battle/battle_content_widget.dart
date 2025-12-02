import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/battle/battle_bloc.dart';
import '../../bloc/battle/battle_event.dart';
import '../../bloc/battle/battle_state.dart';
import '../../../domain/models/battle/battle_monster.dart';
import '../../../domain/models/battle/battle_skill.dart';
import '../../../domain/models/battle/battle_state_model.dart';
import 'battle_effect_widgets.dart';

/// 共通バトルUIウィジェット
/// 全てのバトル画面（冒険、CPU戦、ドラフト）で使用
class BattleContentWidget extends StatefulWidget {
  final BattleStateModel battleState;
  final String? message;
  final String battleType; // 'adventure', 'boss', 'cpu', 'draft'
  final VoidCallback? onBattleEnd;

  const BattleContentWidget({
    Key? key,
    required this.battleState,
    this.message,
    this.battleType = 'cpu',
    this.onBattleEnd,
  }) : super(key: key);

  @override
  State<BattleContentWidget> createState() => _BattleContentWidgetState();
}

class _BattleContentWidgetState extends State<BattleContentWidget> {
  // エフェクト制御用
  int? _playerPreviousHp;
  int? _enemyPreviousHp;
  int? _playerDamageDealt;
  int? _enemyDamageDealt;
  bool _showPlayerDamage = false;
  bool _showEnemyDamage = false;
  bool _isPlayerCritical = false;
  bool _isEnemyCritical = false;
  double _playerEffectiveness = 1.0;
  double _enemyEffectiveness = 1.0;
  bool _isPlayerHeal = false;
  bool _isEnemyHeal = false;
  String? _playerSkillElement;
  String? _enemySkillElement;
  String? _playerSkillType;
  String? _enemySkillType;
  bool _showPlayerSkillEffect = false;
  bool _showEnemySkillEffect = false;
  
  // 前回のモンスターIDを記録（交代時のリセット用）
  String? _lastPlayerMonsterId;
  String? _lastEnemyMonsterId;

  @override
  void didUpdateWidget(BattleContentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final currentPlayerMonsterId = widget.battleState.playerActiveMonster?.baseMonster.id;
    final currentEnemyMonsterId = widget.battleState.enemyActiveMonster?.baseMonster.id;
    
    // モンスターが変わった場合はエフェクトをリセット
    if (_lastPlayerMonsterId != null && _lastPlayerMonsterId != currentPlayerMonsterId) {
      _resetPlayerEffects();
    }
    if (_lastEnemyMonsterId != null && _lastEnemyMonsterId != currentEnemyMonsterId) {
      _resetEnemyEffects();
    }
    
    _lastPlayerMonsterId = currentPlayerMonsterId;
    _lastEnemyMonsterId = currentEnemyMonsterId;

    // HP変化を検知してエフェクトをトリガー
    final oldPlayerHp = oldWidget.battleState.playerActiveMonster?.currentHp;
    final newPlayerHp = widget.battleState.playerActiveMonster?.currentHp;
    final oldEnemyHp = oldWidget.battleState.enemyActiveMonster?.currentHp;
    final newEnemyHp = widget.battleState.enemyActiveMonster?.currentHp;
    
    final oldPlayerMonsterId = oldWidget.battleState.playerActiveMonster?.baseMonster.id;
    final oldEnemyMonsterId = oldWidget.battleState.enemyActiveMonster?.baseMonster.id;

    // プレイヤーがダメージを受けた（同じモンスターの場合のみ）
    if (oldPlayerHp != null && newPlayerHp != null && 
        oldPlayerMonsterId == currentPlayerMonsterId &&
        oldPlayerMonsterId != null &&
        newPlayerHp < oldPlayerHp) {
      final damage = oldPlayerHp - newPlayerHp;
      if (damage > 0) {  // 実際にダメージがある場合のみ
        setState(() {
          _playerPreviousHp = oldPlayerHp;
          _playerDamageDealt = damage;
          _showPlayerDamage = true;
          _isPlayerHeal = false;
          _showPlayerSkillEffect = true;
          _playerSkillType = 'physical';
        });
        _resetPlayerDamageAfterDelay();
      }
    }

    // プレイヤーが回復した（同じモンスターの場合のみ）
    if (oldPlayerHp != null && newPlayerHp != null && 
        oldPlayerMonsterId == currentPlayerMonsterId &&
        oldPlayerMonsterId != null &&
        newPlayerHp > oldPlayerHp) {
      final heal = newPlayerHp - oldPlayerHp;
      if (heal > 0) {  // 実際に回復がある場合のみ
        setState(() {
          _playerPreviousHp = oldPlayerHp;
          _playerDamageDealt = heal;
          _showPlayerDamage = true;
          _isPlayerHeal = true;
          _showPlayerSkillEffect = true;
          _playerSkillType = 'heal';
        });
        _resetPlayerDamageAfterDelay();
      }
    }

    // 敵がダメージを受けた（同じモンスターの場合のみ）
    if (oldEnemyHp != null && newEnemyHp != null && 
        oldEnemyMonsterId == currentEnemyMonsterId &&
        oldEnemyMonsterId != null &&
        newEnemyHp < oldEnemyHp) {
      final damage = oldEnemyHp - newEnemyHp;
      if (damage > 0) {  // 実際にダメージがある場合のみ
        setState(() {
          _enemyPreviousHp = oldEnemyHp;
          _enemyDamageDealt = damage;
          _showEnemyDamage = true;
          _isEnemyHeal = false;
          _showEnemySkillEffect = true;
          _enemySkillType = 'physical';
        });
        _resetEnemyDamageAfterDelay();
      }
    }

    // 敵が回復した（同じモンスターの場合のみ）
    if (oldEnemyHp != null && newEnemyHp != null && 
        oldEnemyMonsterId == currentEnemyMonsterId &&
        oldEnemyMonsterId != null &&
        newEnemyHp > oldEnemyHp) {
      final heal = newEnemyHp - oldEnemyHp;
      if (heal > 0) {  // 実際に回復がある場合のみ
        setState(() {
          _enemyPreviousHp = oldEnemyHp;
          _enemyDamageDealt = heal;
          _showEnemyDamage = true;
          _isEnemyHeal = true;
          _showEnemySkillEffect = true;
          _enemySkillType = 'heal';
        });
        _resetEnemyDamageAfterDelay();
      }
    }
  }

  /// プレイヤー側エフェクトリセット
  void _resetPlayerEffects() {
    setState(() {
      _playerPreviousHp = null;
      _playerDamageDealt = null;
      _showPlayerDamage = false;
      _showPlayerSkillEffect = false;
      _isPlayerHeal = false;
    });
  }

  /// 敵側エフェクトリセット
  void _resetEnemyEffects() {
    setState(() {
      _enemyPreviousHp = null;
      _enemyDamageDealt = null;
      _showEnemyDamage = false;
      _showEnemySkillEffect = false;
      _isEnemyHeal = false;
    });
  }

  void _resetPlayerDamageAfterDelay() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showPlayerDamage = false;
          _showPlayerSkillEffect = false;
          _playerDamageDealt = null;
          _playerPreviousHp = null;
        });
      }
    });
  }

  void _resetEnemyDamageAfterDelay() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showEnemyDamage = false;
          _showEnemySkillEffect = false;
          _enemyDamageDealt = null;
          _enemyPreviousHp = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final battleState = widget.battleState;

    return Column(
      children: [
        // 敵モンスター
        if (battleState.enemyActiveMonster != null)
          BattleMonsterCard(
            monster: battleState.enemyActiveMonster!,
            isEnemy: true,
            previousHp: _enemyPreviousHp,
            damageDealt: _enemyDamageDealt,
            showDamage: _showEnemyDamage,
            isCritical: _isEnemyCritical,
            effectiveness: _enemyEffectiveness,
            isHeal: _isEnemyHeal,
            skillElement: _enemySkillElement,
            skillType: _enemySkillType,
            showSkillEffect: _showEnemySkillEffect,
          ),

        // メッセージ表示
        _buildMessageBox(widget.message),

        // 自分のモンスター
        if (battleState.playerActiveMonster != null)
          BattleMonsterCard(
            monster: battleState.playerActiveMonster!,
            isEnemy: false,
            previousHp: _playerPreviousHp,
            damageDealt: _playerDamageDealt,
            showDamage: _showPlayerDamage,
            isCritical: _isPlayerCritical,
            effectiveness: _playerEffectiveness,
            isHeal: _isPlayerHeal,
            skillElement: _playerSkillElement,
            skillType: _playerSkillType,
            showSkillEffect: _showPlayerSkillEffect,
          ),

        // アクションエリア
        Expanded(
          child: _buildActionArea(context, battleState),
        ),
      ],
    );
  }

  Widget _buildMessageBox(String? message) {
    if (message == null || message.isEmpty) {
      return const SizedBox(height: 50);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        message,
        style: const TextStyle(fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildActionArea(BuildContext context, BattleStateModel battleState) {
    switch (battleState.phase) {
      case BattlePhase.selectFirstMonster:
        return _buildMonsterSelection(context, battleState, isFirstSelect: true);
      case BattlePhase.monsterFainted:
        return _buildMonsterSelection(context, battleState, isFirstSelect: false);
      case BattlePhase.actionSelect:
        return _buildActionButtons(context, battleState);
      default:
        return const SizedBox.shrink();
    }
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
                final canUse = activeMonster.canUseSkill(skill);
                final elementColor = _getElementColor(skill.element);

                return _SkillButton(
                  skill: skill,
                  canUse: canUse,
                  elementColor: elementColor,
                  onPressed: () {
                    context.read<BattleBloc>().add(UseSkill(skill: skill));
                  },
                );
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
                    foregroundColor: Colors.white,
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
                    foregroundColor: Colors.white,
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

  Widget _buildMonsterSelection(
    BuildContext context,
    BattleStateModel battleState, {
    required bool isFirstSelect,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isFirstSelect
                ? 'モンスターを選択'
                : '次のモンスターを選択 (${battleState.playerFieldMonsterIds.length}/3体使用中)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: battleState.playerParty.length,
              itemBuilder: (context, index) {
                final monster = battleState.playerParty[index];
                final monsterId = monster.baseMonster.id;
                final isActive = battleState.playerActiveMonster?.baseMonster.id == monsterId;
                final isFainted = monster.isFainted;
                final canSwitch = battleState.canSwitchTo(monsterId);

                return _MonsterSelectTile(
                  monster: monster,
                  isActive: isActive,
                  isFainted: isFainted,
                  canSwitch: canSwitch,
                  onTap: () {
                    if (isFirstSelect) {
                      context.read<BattleBloc>().add(SelectFirstMonster(monsterId: monsterId));
                    } else {
                      context.read<BattleBloc>().add(SwitchMonster(
                            monsterId: monsterId,
                            isForcedSwitch: true,
                          ));
                    }
                  },
                );
              },
            ),
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
        child: Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '交代するモンスターを選択',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: battleState.playerParty.length,
                  itemBuilder: (context, index) {
                    final monster = battleState.playerParty[index];
                    final monsterId = monster.baseMonster.id;
                    final isActive = battleState.playerActiveMonster?.baseMonster.id == monsterId;
                    final isFainted = monster.isFainted;
                    final canSwitch = battleState.canSwitchTo(monsterId);

                    return _MonsterSelectTile(
                      monster: monster,
                      isActive: isActive,
                      isFainted: isFainted,
                      canSwitch: canSwitch,
                      onTap: () {
                        Navigator.pop(ctx);
                        context.read<BattleBloc>().add(SwitchMonster(
                              monsterId: monsterId,
                              isForcedSwitch: false,
                            ));
                      },
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
}

// ============================================
// 技ボタン
// ============================================

class _SkillButton extends StatelessWidget {
  final BattleSkill skill;
  final bool canUse;
  final Color elementColor;
  final VoidCallback onPressed;

  const _SkillButton({
    Key? key,
    required this.skill,
    required this.canUse,
    required this.elementColor,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: canUse ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: canUse ? elementColor : Colors.grey.shade400,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: canUse ? 4 : 0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flash_on, size: 12),
                    Text('${skill.cost}', style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
              if (skill.isAttack) ...[
                const SizedBox(width: 4),
                Icon(
                  skill.type == 'physical' ? Icons.fitness_center : Icons.auto_fix_high,
                  size: 14,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================
// モンスター選択タイル
// ============================================

class _MonsterSelectTile extends StatelessWidget {
  final BattleMonster monster;
  final bool isActive;
  final bool isFainted;
  final bool canSwitch;
  final VoidCallback onTap;

  const _MonsterSelectTile({
    Key? key,
    required this.monster,
    required this.isActive,
    required this.isFainted,
    required this.canSwitch,
    required this.onTap,
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    final element = monster.baseMonster.element;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isActive
          ? Colors.blue.shade50
          : (isFainted ? Colors.grey.shade200 : Colors.white),
      child: ListTile(
        enabled: canSwitch,
        leading: CircleAvatar(
          backgroundColor: canSwitch ? _getElementColor(element) : Colors.grey,
          child: Text(
            monster.baseMonster.monsterName.isNotEmpty
                ? monster.baseMonster.monsterName.substring(0, 1)
                : '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          monster.baseMonster.monsterName,
          style: TextStyle(
            color: canSwitch ? Colors.black : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: AnimatedHpBar(
                currentHp: monster.currentHp,
                maxHp: monster.maxHp,
                height: 10,
                showValue: false,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              // 瀕死を最優先表示
              isFainted
                  ? '瀕死'
                  : (isActive ? '出撃中' : '${monster.currentHp}/${monster.maxHp}'),
              style: TextStyle(
                fontSize: 12,
                color: isFainted
                    ? Colors.red
                    : (isActive ? Colors.blue : Colors.grey.shade700),
              ),
            ),
          ],
        ),
        trailing: Icon(
          // 瀕死を最優先表示
          isFainted
              ? Icons.cancel
              : (isActive ? Icons.check_circle : Icons.arrow_forward_ios),
          color: isFainted
              ? Colors.red
              : (isActive ? Colors.blue : Colors.green),
        ),
        onTap: canSwitch ? onTap : null,
      ),
    );
  }
}
