import 'package:flutter/material.dart';
import 'dart:math';

import '../../../domain/models/battle/battle_monster.dart';
import '../../../domain/models/battle/battle_skill.dart';

// ============================================
// アニメーション付きHPバー
// ============================================

class AnimatedHpBar extends StatefulWidget {
  final int currentHp;
  final int maxHp;
  final int? previousHp;
  final Duration duration;
  final double height;
  final bool showValue;

  const AnimatedHpBar({
    Key? key,
    required this.currentHp,
    required this.maxHp,
    this.previousHp,
    this.duration = const Duration(milliseconds: 500),
    this.height = 16,
    this.showValue = true,
  }) : super(key: key);

  @override
  State<AnimatedHpBar> createState() => _AnimatedHpBarState();
}

class _AnimatedHpBarState extends State<AnimatedHpBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late double _previousRatio;
  late double _currentRatio;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    
    _previousRatio = (widget.previousHp ?? widget.currentHp) / widget.maxHp;
    _currentRatio = widget.currentHp / widget.maxHp;
    
    _animation = Tween<double>(
      begin: _previousRatio,
      end: _currentRatio,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    ));
    
    if (_previousRatio != _currentRatio) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedHpBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.currentHp != widget.currentHp) {
      _previousRatio = oldWidget.currentHp / widget.maxHp;
      _currentRatio = widget.currentHp / widget.maxHp;
      
      _animation = Tween<double>(
        begin: _previousRatio,
        end: _currentRatio,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutQuart,
      ));
      
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getHpColor(double ratio) {
    if (ratio > 0.5) {
      return Colors.green.shade500;
    } else if (ratio > 0.25) {
      return Colors.orange.shade500;
    } else {
      return Colors.red.shade500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final ratio = _animation.value.clamp(0.0, 1.0);
        final color = _getHpColor(ratio);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                // 背景
                Container(
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(widget.height / 2),
                  ),
                ),
                // 遅延バー（ダメージ表示用）
                if (_previousRatio > _currentRatio)
                  FractionallySizedBox(
                    widthFactor: _previousRatio.clamp(0.0, 1.0),
                    child: Container(
                      height: widget.height,
                      decoration: BoxDecoration(
                        color: Colors.red.shade300,
                        borderRadius: BorderRadius.circular(widget.height / 2),
                      ),
                    ),
                  ),
                // メインHP バー
                FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(
                    height: widget.height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.8),
                          color,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(widget.height / 2),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    // 光沢効果
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: widget.height / 2,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(widget.height / 2),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withOpacity(0.3),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (widget.showValue)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${widget.currentHp} / ${widget.maxHp}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ============================================
// アニメーション付きコストゲージ
// ============================================

class AnimatedCostGauge extends StatelessWidget {
  final int currentCost;
  final int maxCost;
  final Color activeColor;
  final Color inactiveColor;

  const AnimatedCostGauge({
    Key? key,
    required this.currentCost,
    required this.maxCost,
    this.activeColor = Colors.blue,
    this.inactiveColor = Colors.grey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxCost, (index) {
        final isActive = index < currentCost;
        final delay = index * 50;
        
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.0),
          duration: Duration(milliseconds: 200 + delay),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: isActive ? scale : 0.9,
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: isActive ? activeColor : inactiveColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isActive ? activeColor.withOpacity(0.8) : inactiveColor.withOpacity(0.5),
                    width: 1,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: activeColor.withOpacity(0.4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: isActive && index == maxCost - 1 && currentCost == maxCost
                    ? const Icon(Icons.flash_on, size: 12, color: Colors.white)
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
// 技エフェクトウィジェット
// ============================================

class SkillEffectWidget extends StatefulWidget {
  final String element;
  final String skillType; // physical, magical, buff, debuff, heal
  final VoidCallback? onComplete;

  const SkillEffectWidget({
    Key? key,
    required this.element,
    required this.skillType,
    this.onComplete,
  }) : super(key: key);

  @override
  State<SkillEffectWidget> createState() => _SkillEffectWidgetState();
}

class _SkillEffectWidgetState extends State<SkillEffectWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _generateParticles();
    
    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  void _generateParticles() {
    final count = widget.skillType == 'heal' ? 15 : 25;
    for (int i = 0; i < count; i++) {
      _particles.add(_Particle(
        angle: _random.nextDouble() * 2 * pi,
        distance: 30 + _random.nextDouble() * 80,
        size: 4 + _random.nextDouble() * 8,
        delay: _random.nextDouble() * 0.3,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getElementColor() {
    switch (widget.element.toLowerCase()) {
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(200, 200),
          painter: _SkillEffectPainter(
            progress: _controller.value,
            particles: _particles,
            color: _getElementColor(),
            skillType: widget.skillType,
          ),
        );
      },
    );
  }
}

class _Particle {
  final double angle;
  final double distance;
  final double size;
  final double delay;

  _Particle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.delay,
  });
}

class _SkillEffectPainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;
  final Color color;
  final String skillType;

  _SkillEffectPainter({
    required this.progress,
    required this.particles,
    required this.color,
    required this.skillType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    if (skillType == 'heal') {
      _paintHealEffect(canvas, center);
    } else if (skillType == 'buff' || skillType == 'debuff') {
      _paintStatusEffect(canvas, center);
    } else {
      _paintAttackEffect(canvas, center);
    }
  }

  void _paintAttackEffect(Canvas canvas, Offset center) {
    // 中心フラッシュ
    if (progress < 0.3) {
      final flashProgress = progress / 0.3;
      final flashPaint = Paint()
        ..color = color.withOpacity((1 - flashProgress) * 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      canvas.drawCircle(center, 40 * flashProgress, flashPaint);
    }

    // パーティクル
    for (final particle in particles) {
      final particleProgress = ((progress - particle.delay) / (1 - particle.delay)).clamp(0.0, 1.0);
      if (particleProgress <= 0) continue;

      final distance = particle.distance * particleProgress;
      final opacity = (1 - particleProgress).clamp(0.0, 1.0);
      final currentSize = particle.size * (1 - particleProgress * 0.5);

      final x = center.dx + cos(particle.angle) * distance;
      final y = center.dy + sin(particle.angle) * distance;

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(Offset(x, y), currentSize, paint);
    }
  }

  void _paintHealEffect(Canvas canvas, Offset center) {
    for (final particle in particles) {
      final particleProgress = ((progress - particle.delay) / (1 - particle.delay)).clamp(0.0, 1.0);
      if (particleProgress <= 0) continue;

      final x = center.dx + cos(particle.angle) * 30;
      final y = center.dy - particle.distance * particleProgress;
      final opacity = (1 - particleProgress).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = Colors.green.withOpacity(opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      // プラスマーク
      final plusSize = particle.size;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: plusSize, height: plusSize / 3),
        paint,
      );
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: plusSize / 3, height: plusSize),
        paint,
      );
    }
  }

  void _paintStatusEffect(Canvas canvas, Offset center) {
    final ringProgress = progress;
    final ringRadius = 40 + 30 * ringProgress;
    final opacity = (1 - progress * 0.5).clamp(0.0, 1.0);

    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawCircle(center, ringRadius, paint);

    // 矢印（バフ=上、デバフ=下）
    final arrowPaint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      final angle = i * pi / 2 + progress * pi;
      final arrowCenter = Offset(
        center.dx + cos(angle) * ringRadius,
        center.dy + sin(angle) * ringRadius,
      );

      final path = Path();
      if (skillType == 'buff') {
        path.moveTo(arrowCenter.dx, arrowCenter.dy - 8);
        path.lineTo(arrowCenter.dx - 5, arrowCenter.dy + 4);
        path.lineTo(arrowCenter.dx + 5, arrowCenter.dy + 4);
      } else {
        path.moveTo(arrowCenter.dx, arrowCenter.dy + 8);
        path.lineTo(arrowCenter.dx - 5, arrowCenter.dy - 4);
        path.lineTo(arrowCenter.dx + 5, arrowCenter.dy - 4);
      }
      path.close();
      canvas.drawPath(path, arrowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SkillEffectPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ============================================
// ダメージ数値表示
// ============================================

class DamageNumberWidget extends StatefulWidget {
  final int damage;
  final bool isCritical;
  final double effectiveness; // 1.0 = 普通, 1.5+ = 効果抜群, 0.5- = いまひとつ
  final bool isHeal;
  final VoidCallback? onComplete;

  const DamageNumberWidget({
    Key? key,
    required this.damage,
    this.isCritical = false,
    this.effectiveness = 1.0,
    this.isHeal = false,
    this.onComplete,
  }) : super(key: key);

  @override
  State<DamageNumberWidget> createState() => _DamageNumberWidgetState();
}

class _DamageNumberWidgetState extends State<DamageNumberWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _moveAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.2), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);

    _moveAnimation = Tween<double>(begin: 0, end: -30).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getColor() {
    if (widget.isHeal) return Colors.green;
    if (widget.isCritical) return Colors.red;
    if (widget.effectiveness >= 1.5) return Colors.orange;
    if (widget.effectiveness <= 0.5) return Colors.grey;
    return Colors.white;
  }

  double _getFontSize() {
    if (widget.isCritical) return 34;
    if (widget.effectiveness >= 1.5) return 30;
    if (widget.effectiveness <= 0.5) return 24;
    return 28;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _moveAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isCritical)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'CRITICAL!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Stack(
                    children: [
                      // 影
                      Text(
                        '${widget.isHeal ? '+' : ''}${widget.damage}',
                        style: TextStyle(
                          fontSize: _getFontSize(),
                          fontWeight: FontWeight.bold,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 3
                            ..color = Colors.black,
                        ),
                      ),
                      // 本体
                      Text(
                        '${widget.isHeal ? '+' : ''}${widget.damage}',
                        style: TextStyle(
                          fontSize: _getFontSize(),
                          fontWeight: FontWeight.bold,
                          color: _getColor(),
                        ),
                      ),
                    ],
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
// ヒットフラッシュオーバーレイ
// ============================================

class HitFlashOverlay extends StatefulWidget {
  final bool isActive;
  final Color color;
  final VoidCallback? onComplete;

  const HitFlashOverlay({
    Key? key,
    required this.isActive,
    this.color = Colors.red,
    this.onComplete,
  }) : super(key: key);

  @override
  State<HitFlashOverlay> createState() => _HitFlashOverlayState();
}

class _HitFlashOverlayState extends State<HitFlashOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.5), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 0.0), weight: 50),
    ]).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
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
      animation: _animation,
      builder: (context, child) {
        if (_animation.value == 0) return const SizedBox.shrink();
        return Container(
          color: widget.color.withOpacity(_animation.value),
        );
      },
    );
  }
}

// ============================================
// エフェクト付きモンスターカード
// ============================================

class BattleMonsterCard extends StatefulWidget {
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
  final VoidCallback? onEffectComplete;

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
    this.onEffectComplete,
  }) : super(key: key);

  @override
  State<BattleMonsterCard> createState() => _BattleMonsterCardState();
}

class _BattleMonsterCardState extends State<BattleMonsterCard> {
  bool _showHitFlash = false;

  @override
  void didUpdateWidget(BattleMonsterCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showDamage && !oldWidget.showDamage && !widget.isHeal) {
      setState(() => _showHitFlash = true);
    }
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

  @override
  Widget build(BuildContext context) {
    final monster = widget.monster;
    final element = monster.baseMonster.element;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // メインカード
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isEnemy ? Colors.red.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isEnemy ? Colors.red.shade200 : Colors.blue.shade200,
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
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
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
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // HPバー（アニメーション付き）
              Row(
                children: [
                  const Text('HP: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: AnimatedHpBar(
                      currentHp: monster.currentHp,
                      maxHp: monster.maxHp,
                      previousHp: widget.previousHp,
                      height: 14,
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
                    activeColor: widget.isEnemy ? Colors.red : Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${monster.currentCost}/${monster.maxCost}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),

              // 状態異常表示
              if (monster.statusAilment != null && monster.statusAilment!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildStatusAilmentBadge(monster.statusAilment!),
              ],

              // バフ/デバフ表示
              if (_hasStatChanges(monster)) ...[
                const SizedBox(height: 8),
                _buildStatChangesDisplay(monster),
              ],
            ],
          ),
        ),

        // ヒットフラッシュ
        if (_showHitFlash)
          Positioned.fill(
            child: HitFlashOverlay(
              isActive: _showHitFlash,
              color: widget.isEnemy ? Colors.white : Colors.red,
              onComplete: () => setState(() => _showHitFlash = false),
            ),
          ),

        // ダメージ数値
        if (widget.showDamage && widget.damageDealt != null)
          Positioned(
            top: -20,
            left: 0,
            right: 0,
            child: Center(
              child: DamageNumberWidget(
                damage: widget.damageDealt!,
                isCritical: widget.isCritical,
                effectiveness: widget.effectiveness,
                isHeal: widget.isHeal,
                onComplete: widget.onEffectComplete,
              ),
            ),
          ),

        // 技エフェクト
        if (widget.showSkillEffect && widget.skillElement != null)
          Positioned.fill(
            child: Center(
              child: SkillEffectWidget(
                element: widget.skillElement!,
                skillType: widget.skillType ?? 'physical',
                onComplete: widget.onEffectComplete,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusAilmentBadge(String ailment) {
    final ailmentInfo = _getAilmentInfo(ailment);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ailmentInfo['color'] as Color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ailmentInfo['icon'] as IconData, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            ailmentInfo['name'] as String,
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

  Map<String, dynamic> _getAilmentInfo(String ailment) {
    switch (ailment.toLowerCase()) {
      case 'poison':
        return {'name': '毒', 'icon': Icons.science, 'color': Colors.purple};
      case 'burn':
        return {'name': '火傷', 'icon': Icons.local_fire_department, 'color': Colors.orange};
      case 'paralysis':
        return {'name': '麻痺', 'icon': Icons.flash_on, 'color': Colors.yellow.shade700};
      case 'sleep':
        return {'name': '睡眠', 'icon': Icons.bedtime, 'color': Colors.indigo};
      case 'freeze':
        return {'name': '凍結', 'icon': Icons.ac_unit, 'color': Colors.cyan};
      case 'confusion':
        return {'name': '混乱', 'icon': Icons.psychology, 'color': Colors.pink};
      default:
        return {'name': ailment, 'icon': Icons.help_outline, 'color': Colors.grey};
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
      '攻': (monster.attackStage, monster.attackStageTurns),
      '防': (monster.defenseStage, monster.defenseStageTurns),
      '魔': (monster.magicStage, monster.magicStageTurns),
      '速': (monster.speedStage, monster.speedStageTurns),
      '命': (monster.accuracyStage, monster.accuracyStageTurns),
      '回': (monster.evasionStage, monster.evasionStageTurns),
    };

    statChanges.forEach((stat, values) {
      final stage = values.$1;
      final turns = values.$2;
      if (stage != 0) {
        statChips.add(_buildStatChip(stat, stage, turns));
      }
    });

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: statChips,
    );
  }

  Widget _buildStatChip(String statName, int stage, int turnsRemaining) {
    final isPositive = stage > 0;
    final absStage = stage.abs();
    final arrow = isPositive ? '↑' : '↓';
    final arrowText = arrow * absStage.clamp(1, 3);

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