// lib/presentation/widgets/battle/battle_effect_widgets.dart

import 'dart:math';
import 'package:flutter/material.dart';
import '../../../domain/models/battle/battle_monster.dart';

/// 属性別の色を定義
class ElementColors {
  static Color getColor(String element) {
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
      case 'none':
      default:
        return Colors.grey;
    }
  }
}

// ============================================
// BattleMonsterCard - バトル画面のモンスターカード
// ============================================

class BattleMonsterCard extends StatelessWidget {
  final BattleMonster monster;
  final bool isEnemy;
  final int? previousHp;
  final int? damageDealt;
  final bool showDamage;
  final bool isCritical;
  final double effectiveness;
  final bool isHeal;
  final String? skillElement;
  final String? skillType;
  final bool showSkillEffect;

  const BattleMonsterCard({
    Key? key,
    required this.monster,
    required this.isEnemy,
    this.previousHp,
    this.damageDealt,
    this.showDamage = false,
    this.isCritical = false,
    this.effectiveness = 1.0,
    this.isHeal = false,
    this.skillElement,
    this.skillType,
    this.showSkillEffect = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // モンスター情報カード
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isEnemy ? Colors.red.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEnemy ? Colors.red.shade200 : Colors.blue.shade200,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
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
                  _buildElementBadge(monster.baseMonster.element),
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
                      previousHp: previousHp,
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
        ),

        // ダメージ数値ポップアップ
        if (showDamage && damageDealt != null)
          Positioned(
            top: -10,
            right: 30,
            child: DamageNumberWidget(
              damage: damageDealt!,
              isCritical: isCritical,
              isEffective: effectiveness > 1.0,
              isResisted: effectiveness < 1.0,
              isHeal: isHeal,
            ),
          ),

        // 技エフェクト
        if (showSkillEffect && skillType != null)
          Positioned.fill(
            child: SkillEffectWidget(
              skillType: skillType!,
              element: skillElement ?? 'none',
            ),
          ),
      ],
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
      'dark': '闘',
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
}

// ============================================
// AnimatedHpBar - アニメーション付きHPバー
// ============================================

class AnimatedHpBar extends StatefulWidget {
  final int currentHp;
  final int maxHp;
  final int? previousHp;
  final double height;
  final bool showValue;

  const AnimatedHpBar({
    Key? key,
    required this.currentHp,
    required this.maxHp,
    this.previousHp,
    this.height = 12,
    this.showValue = false,
  }) : super(key: key);

  @override
  State<AnimatedHpBar> createState() => _AnimatedHpBarState();
}

class _AnimatedHpBarState extends State<AnimatedHpBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _delayedBarAnimation;
  double _previousPercentage = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _delayedBarAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
    );
    _previousPercentage = widget.currentHp / widget.maxHp;
  }

  @override
  void didUpdateWidget(AnimatedHpBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.currentHp != widget.currentHp) {
      final oldPercentage = oldWidget.currentHp / widget.maxHp;
      final newPercentage = widget.currentHp / widget.maxHp;
      
      _previousPercentage = oldPercentage;
      _delayedBarAnimation = Tween<double>(
        begin: oldPercentage,
        end: newPercentage,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));
      
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getHpColor(double percentage) {
    if (percentage > 0.5) return Colors.green;
    if (percentage > 0.25) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final percentage = widget.currentHp / widget.maxHp;
    final hpColor = _getHpColor(percentage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              // 背景
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(widget.height / 2),
                ),
              ),
              
              // 遅延バー（赤い残像）
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FractionallySizedBox(
                    widthFactor: _delayedBarAnimation.value.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red.shade300,
                        borderRadius: BorderRadius.circular(widget.height / 2),
                      ),
                    ),
                  );
                },
              ),
              
              // 実際のHPバー
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                widthFactor: percentage.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [hpColor.withOpacity(0.8), hpColor],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(widget.height / 2),
                    boxShadow: [
                      BoxShadow(
                        color: hpColor.withOpacity(0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  // 光沢効果
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.height / 2),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.3),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.showValue) ...[
          const SizedBox(height: 2),
          Text(
            '${widget.currentHp}/${widget.maxHp}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================
// AnimatedCostGauge - アニメーション付きコストゲージ
// ============================================

class AnimatedCostGauge extends StatelessWidget {
  final int currentCost;
  final int maxCost;
  final Color activeColor;
  final Color inactiveColor;
  final double size;

  const AnimatedCostGauge({
    Key? key,
    required this.currentCost,
    required this.maxCost,
    this.activeColor = Colors.blue,
    this.inactiveColor = Colors.grey,
    this.size = 18,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxCost, (index) {
        final isActive = index < currentCost;
        final isFull = currentCost == maxCost;
        
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: isActive ? 1.0 : 0.0),
          duration: Duration(milliseconds: 200 + (index * 50)),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (value * 0.2),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.lerp(
                    inactiveColor.withOpacity(0.3),
                    isFull ? Colors.amber : activeColor,
                    value,
                  ),
                  border: Border.all(
                    color: Color.lerp(
                      inactiveColor.withOpacity(0.5),
                      isFull ? Colors.amber.shade700 : activeColor.withOpacity(0.8),
                      value,
                    )!,
                    width: 2,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: (isFull ? Colors.amber : activeColor).withOpacity(0.4 * value),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: isFull && isActive
                    ? Icon(
                        Icons.flash_on,
                        size: size * 0.6,
                        color: Colors.white,
                      )
                    : null,
              ),
            );
          },
        );
      }),
    );
  }
}

// ============================================
// SkillEffectWidget - 技エフェクト
// ============================================

class SkillEffectWidget extends StatefulWidget {
  final String skillType; // 'physical', 'magical', 'heal', 'buff', 'debuff'
  final String element;

  const SkillEffectWidget({
    Key? key,
    required this.skillType,
    required this.element,
  }) : super(key: key);

  @override
  State<SkillEffectWidget> createState() => _SkillEffectWidgetState();
}

class _SkillEffectWidgetState extends State<SkillEffectWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elementColor = ElementColors.getColor(widget.element);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _SkillEffectPainter(
            progress: _controller.value,
            skillType: widget.skillType,
            color: elementColor,
          ),
        );
      },
    );
  }
}

class _SkillEffectPainter extends CustomPainter {
  final double progress;
  final String skillType;
  final Color color;
  final Random _random = Random(42);

  _SkillEffectPainter({
    required this.progress,
    required this.skillType,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (skillType == 'physical' || skillType == 'magical') {
      _paintAttackEffect(canvas, size);
    } else if (skillType == 'heal') {
      _paintHealEffect(canvas, size);
    } else {
      _paintBuffEffect(canvas, size);
    }
  }

  void _paintAttackEffect(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final particleCount = 25;

    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * pi + _random.nextDouble() * 0.5;
      final distance = progress * 80 * (0.5 + _random.nextDouble() * 0.5);
      final particleSize = (1 - progress) * 8 * (0.5 + _random.nextDouble() * 0.5);

      final x = center.dx + cos(angle) * distance;
      final y = center.dy + sin(angle) * distance;

      final paint = Paint()
        ..color = color.withOpacity((1 - progress) * 0.8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }

    // 中心フラッシュ
    if (progress < 0.5) {
      final flashPaint = Paint()
        ..color = Colors.white.withOpacity((0.5 - progress) * 1.5)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 30 * (1 - progress * 2), flashPaint);
    }
  }

  void _paintHealEffect(Canvas canvas, Size size) {
    final particleCount = 15;

    for (int i = 0; i < particleCount; i++) {
      final x = size.width * (0.2 + _random.nextDouble() * 0.6);
      final startY = size.height * 0.8;
      final y = startY - (progress * size.height * 0.5) - (_random.nextDouble() * 30);

      final particleSize = (1 - progress * 0.5) * 6;

      final paint = Paint()
        ..color = Colors.green.withOpacity((1 - progress) * 0.7)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
  }

  void _paintBuffEffect(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = 40 + progress * 30;

    final paint = Paint()
      ..color = color.withOpacity((1 - progress) * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _SkillEffectPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ============================================
// DamageNumberWidget - ダメージ数値ポップアップ
// ============================================

class DamageNumberWidget extends StatefulWidget {
  final int damage;
  final bool isCritical;
  final bool isEffective;
  final bool isResisted;
  final bool isHeal;

  const DamageNumberWidget({
    Key? key,
    required this.damage,
    this.isCritical = false,
    this.isEffective = false,
    this.isResisted = false,
    this.isHeal = false,
  }) : super(key: key);

  @override
  State<DamageNumberWidget> createState() => _DamageNumberWidgetState();
}

class _DamageNumberWidgetState extends State<DamageNumberWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _positionAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 70),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);

    _positionAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -30),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color textColor;
    String prefix = '';
    String suffix = '';
    double fontSize = 28;

    if (widget.isHeal) {
      textColor = Colors.green;
      prefix = '+';
    } else if (widget.isCritical) {
      textColor = Colors.red;
      fontSize = 34;
      suffix = '\nCRITICAL!';
    } else if (widget.isEffective) {
      textColor = Colors.orange;
      suffix = '\n効果抜群！';
    } else if (widget.isResisted) {
      textColor = Colors.grey;
      suffix = '\nいまひとつ...';
    } else {
      textColor = Colors.white;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _positionAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$prefix${widget.damage}',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2)),
                      ],
                    ),
                  ),
                  if (suffix.isNotEmpty)
                    Text(
                      suffix.trim(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        shadows: const [
                          Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================
// HitFlashOverlay - ヒットフラッシュ
// ============================================

class HitFlashOverlay extends StatefulWidget {
  final bool isActive;
  final Color color;

  const HitFlashOverlay({
    Key? key,
    required this.isActive,
    this.color = Colors.red,
  }) : super(key: key);

  @override
  State<HitFlashOverlay> createState() => _HitFlashOverlayState();
}

class _HitFlashOverlayState extends State<HitFlashOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.5), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 0.0), weight: 50),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(HitFlashOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return IgnorePointer(
          child: Container(
            color: widget.color.withOpacity(_opacityAnimation.value),
          ),
        );
      },
    );
  }
}

// ============================================
// BattleEffectController - エフェクト制御
// ============================================

class BattleEffectController extends ChangeNotifier {
  // ★修正: フィールド名を変更して衝突を回避
  String? _skillType;
  String? _skillElement;
  bool _isSkillEffectVisible = false;
  int? _damageValue;
  bool _isCritical = false;
  bool _isEffective = false;
  bool _isResisted = false;
  bool _isHeal = false;
  bool _isDamageVisible = false;
  bool _targetIsPlayer = false;

  // ゲッター
  String? get skillType => _skillType;
  String? get skillElement => _skillElement;
  bool get isSkillEffectVisible => _isSkillEffectVisible;
  int? get damageValue => _damageValue;
  bool get isCritical => _isCritical;
  bool get isEffective => _isEffective;
  bool get isResisted => _isResisted;
  bool get isHeal => _isHeal;
  bool get isDamageVisible => _isDamageVisible;
  bool get targetIsPlayer => _targetIsPlayer;

  void triggerSkillEffect({
    required String skillType,
    required String element,
    required bool targetIsPlayer,
  }) {
    _skillType = skillType;
    _skillElement = element;
    _targetIsPlayer = targetIsPlayer;
    _isSkillEffectVisible = true;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 600), () {
      clearSkillEffect();
    });
  }

  void triggerDamage({
    required int damage,
    required bool isCritical,
    required bool isEffective,
    required bool isResisted,
    required bool isHeal,
    required bool targetIsPlayer,
  }) {
    _damageValue = damage;
    _isCritical = isCritical;
    _isEffective = isEffective;
    _isResisted = isResisted;
    _isHeal = isHeal;
    _targetIsPlayer = targetIsPlayer;
    _isDamageVisible = true;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 800), () {
      clearDamage();
    });
  }

  void clearSkillEffect() {
    _isSkillEffectVisible = false;
    notifyListeners();
  }

  void clearDamage() {
    _isDamageVisible = false;
    notifyListeners();
  }

  void clearAll() {
    _isSkillEffectVisible = false;
    _isDamageVisible = false;
    notifyListeners();
  }
}

// ============================================
// BattleEffectOverlay - エフェクトオーバーレイ
// ============================================

class BattleEffectOverlay extends StatelessWidget {
  final BattleEffectController controller;
  final Widget child;

  const BattleEffectOverlay({
    Key? key,
    required this.controller,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Stack(
          children: [
            child,
            
            // ヒットフラッシュ
            if (controller.isDamageVisible && controller.targetIsPlayer)
              Positioned.fill(
                child: HitFlashOverlay(
                  isActive: controller.isDamageVisible,
                  color: Colors.red,
                ),
              ),
          ],
        );
      },
    );
  }
}