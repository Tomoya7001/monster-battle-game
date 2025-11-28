import 'dart:math';
import 'package:flutter/material.dart';

/// 技エフェクトウィジェット
class SkillEffectWidget extends StatefulWidget {
  final String element;
  final String skillType; // physical, magical, buff, debuff, heal
  final VoidCallback? onComplete;

  const SkillEffectWidget({
    Key? key,
    required this.element,
    this.skillType = 'physical',
    this.onComplete,
  }) : super(key: key);

  @override
  State<SkillEffectWidget> createState() => _SkillEffectWidgetState();
}

class _SkillEffectWidgetState extends State<SkillEffectWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _EffectPainter(
            element: widget.element,
            skillType: widget.skillType,
            progress: _animation.value,
            particles: _particles,
          ),
          size: const Size(200, 200),
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

class _EffectPainter extends CustomPainter {
  final String element;
  final String skillType;
  final double progress;
  final List<_Particle> particles;

  _EffectPainter({
    required this.element,
    required this.skillType,
    required this.progress,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final color = _getElementColor(element);

    if (skillType == 'heal') {
      _drawHealEffect(canvas, center, color);
    } else if (skillType == 'buff' || skillType == 'debuff') {
      _drawStatusEffect(canvas, center, color, skillType == 'buff');
    } else {
      _drawAttackEffect(canvas, center, color);
    }
  }

  void _drawAttackEffect(Canvas canvas, Offset center, Color color) {
    for (final particle in particles) {
      final adjustedProgress = ((progress - particle.delay) / (1 - particle.delay)).clamp(0.0, 1.0);
      if (adjustedProgress <= 0) continue;

      final distance = particle.distance * adjustedProgress;
      final x = center.dx + cos(particle.angle) * distance;
      final y = center.dy + sin(particle.angle) * distance;
      final opacity = (1 - adjustedProgress).clamp(0.0, 1.0);
      final currentSize = particle.size * (1 - adjustedProgress * 0.5);

      final paint = Paint()
        ..color = color.withOpacity(opacity * 0.8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), currentSize, paint);

      // グロー効果
      final glowPaint = Paint()
        ..color = color.withOpacity(opacity * 0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(x, y), currentSize * 1.5, glowPaint);
    }

    // 中心のフラッシュ
    if (progress < 0.3) {
      final flashOpacity = (1 - progress / 0.3).clamp(0.0, 1.0);
      final flashPaint = Paint()
        ..color = Colors.white.withOpacity(flashOpacity * 0.8)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(center, 30 * (1 - progress / 0.3), flashPaint);
    }
  }

  void _drawHealEffect(Canvas canvas, Offset center, Color color) {
    // 上昇するパーティクル
    for (final particle in particles) {
      final adjustedProgress = ((progress - particle.delay) / (1 - particle.delay)).clamp(0.0, 1.0);
      if (adjustedProgress <= 0) continue;

      final x = center.dx + cos(particle.angle) * 30;
      final y = center.dy - particle.distance * adjustedProgress;
      final opacity = (1 - adjustedProgress).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = Colors.green.withOpacity(opacity * 0.8)
        ..style = PaintingStyle.fill;

      // プラスマーク
      final path = Path();
      final s = particle.size;
      path.moveTo(x - s / 4, y);
      path.lineTo(x + s / 4, y);
      path.moveTo(x, y - s / 4);
      path.lineTo(x, y + s / 4);

      final strokePaint = Paint()
        ..color = Colors.green.withOpacity(opacity * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawPath(path, strokePaint);
    }
  }

  void _drawStatusEffect(Canvas canvas, Offset center, Color color, bool isBuff) {
    // 回転するリング
    final ringPaint = Paint()
      ..color = color.withOpacity((1 - progress) * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final radius = 40 + progress * 30;
    canvas.drawCircle(center, radius, ringPaint);

    // 矢印（バフは上、デバフは下）
    for (int i = 0; i < 4; i++) {
      final angle = progress * pi + i * pi / 2;
      final x = center.dx + cos(angle) * radius;
      final y = center.dy + sin(angle) * radius;
      final opacity = (1 - progress).clamp(0.0, 1.0);

      final arrowPaint = Paint()
        ..color = color.withOpacity(opacity * 0.8)
        ..style = PaintingStyle.fill;

      final path = Path();
      final direction = isBuff ? -1 : 1;
      path.moveTo(x, y + direction * 8);
      path.lineTo(x - 4, y - direction * 4);
      path.lineTo(x + 4, y - direction * 4);
      path.close();

      canvas.drawPath(path, arrowPaint);
    }
  }

  Color _getElementColor(String element) {
    switch (element.toLowerCase()) {
      case 'fire':
        return Colors.deepOrange;
      case 'water':
        return Colors.blue;
      case 'thunder':
        return Colors.amber;
      case 'wind':
        return Colors.green;
      case 'earth':
        return Colors.brown;
      case 'light':
        return Colors.yellow;
      case 'dark':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  bool shouldRepaint(covariant _EffectPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// ダメージ数値表示ウィジェット
class DamageNumberWidget extends StatefulWidget {
  final int damage;
  final bool isCritical;
  final bool isHealing;
  final double effectiveness; // 1.0=普通, 1.5=効果抜群, 0.5=効果いまひとつ
  final VoidCallback? onComplete;

  const DamageNumberWidget({
    Key? key,
    required this.damage,
    this.isCritical = false,
    this.isHealing = false,
    this.effectiveness = 1.0,
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
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.2), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
    ]).animate(_controller);

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
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
              child: _buildDamageText(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDamageText() {
    Color color;
    String prefix = '';
    double fontSize = 28;

    if (widget.isHealing) {
      color = Colors.green;
      prefix = '+';
    } else if (widget.isCritical) {
      color = Colors.red;
      fontSize = 34;
    } else if (widget.effectiveness > 1.0) {
      color = Colors.orange;
    } else if (widget.effectiveness < 1.0) {
      color = Colors.grey;
      fontSize = 24;
    } else {
      color = Colors.white;
    }

    return Stack(
      children: [
        // 影
        Text(
          '$prefix${widget.damage}',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = Colors.black,
          ),
        ),
        // 本体
        Text(
          '$prefix${widget.damage}',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        // クリティカル表示
        if (widget.isCritical)
          Positioned(
            top: -10,
            right: -10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'CRITICAL!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// ヒットエフェクト（被ダメージ時の点滅）
class HitFlashOverlay extends StatefulWidget {
  final VoidCallback? onComplete;

  const HitFlashOverlay({Key? key, this.onComplete}) : super(key: key);

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
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.5), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 0.0), weight: 50),
    ]).animate(_controller);

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
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
        return Container(
          color: Colors.red.withOpacity(_animation.value),
        );
      },
    );
  }
}