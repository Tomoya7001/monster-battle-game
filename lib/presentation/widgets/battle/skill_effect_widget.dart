import 'package:flutter/material.dart';
import 'dart:math';

/// 技エフェクト表示ウィジェット
class SkillEffectWidget extends StatefulWidget {
  final String element;
  final String skillType; // physical, special
  final bool isPlayerAttack;
  final VoidCallback? onComplete;

  const SkillEffectWidget({
    Key? key,
    required this.element,
    required this.skillType,
    required this.isPlayerAttack,
    this.onComplete,
  }) : super(key: key);

  @override
  State<SkillEffectWidget> createState() => _SkillEffectWidgetState();
}

class _SkillEffectWidgetState extends State<SkillEffectWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);

    // パーティクル生成
    _generateParticles();

    _controller.forward().whenComplete(() {
      widget.onComplete?.call();
    });
  }

  void _generateParticles() {
    final color = _getElementColor(widget.element);
    final particleCount = widget.skillType == 'physical' ? 8 : 12;

    for (int i = 0; i < particleCount; i++) {
      final angle = (2 * pi * i) / particleCount + _random.nextDouble() * 0.5;
      final distance = 50.0 + _random.nextDouble() * 30;

      _particles.add(_Particle(
        color: color,
        angle: angle,
        distance: distance,
        size: 6.0 + _random.nextDouble() * 8,
        delay: _random.nextDouble() * 0.2,
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
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(200, 200),
          painter: _SkillEffectPainter(
            element: widget.element,
            skillType: widget.skillType,
            progress: _controller.value,
            scale: _scaleAnimation.value,
            opacity: _opacityAnimation.value,
            particles: _particles,
          ),
        );
      },
    );
  }

  Color _getElementColor(String element) {
    switch (element.toLowerCase()) {
      case 'fire':
        return Colors.deepOrange;
      case 'water':
        return Colors.blue;
      case 'thunder':
        return Colors.yellow;
      case 'wind':
        return Colors.green;
      case 'earth':
        return Colors.brown;
      case 'light':
        return Colors.amber;
      case 'dark':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

class _Particle {
  final Color color;
  final double angle;
  final double distance;
  final double size;
  final double delay;

  _Particle({
    required this.color,
    required this.angle,
    required this.distance,
    required this.size,
    required this.delay,
  });
}

class _SkillEffectPainter extends CustomPainter {
  final String element;
  final String skillType;
  final double progress;
  final double scale;
  final double opacity;
  final List<_Particle> particles;

  _SkillEffectPainter({
    required this.element,
    required this.skillType,
    required this.progress,
    required this.scale,
    required this.opacity,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // メインエフェクト
    _drawMainEffect(canvas, center);

    // パーティクル
    _drawParticles(canvas, center);
  }

  void _drawMainEffect(Canvas canvas, Offset center) {
    final color = _getElementColor(element);
    final paint = Paint()
      ..color = color.withOpacity(opacity * 0.6)
      ..style = PaintingStyle.fill;

    // 属性別エフェクト
    switch (element.toLowerCase()) {
      case 'fire':
        _drawFireEffect(canvas, center, paint);
        break;
      case 'water':
        _drawWaterEffect(canvas, center, paint);
        break;
      case 'thunder':
        _drawThunderEffect(canvas, center, paint);
        break;
      case 'wind':
        _drawWindEffect(canvas, center, paint);
        break;
      case 'earth':
        _drawEarthEffect(canvas, center, paint);
        break;
      case 'light':
        _drawLightEffect(canvas, center, paint);
        break;
      case 'dark':
        _drawDarkEffect(canvas, center, paint);
        break;
      default:
        _drawDefaultEffect(canvas, center, paint);
    }
  }

  void _drawFireEffect(Canvas canvas, Offset center, Paint paint) {
    // 炎のような形状
    final path = Path();
    final radius = 40 * scale;

    for (int i = 0; i < 8; i++) {
      final angle = (2 * pi * i) / 8;
      final innerRadius = radius * 0.5;
      final outerRadius = radius * (0.8 + 0.4 * sin(progress * pi * 4 + i));

      if (i == 0) {
        path.moveTo(
          center.dx + cos(angle) * outerRadius,
          center.dy + sin(angle) * outerRadius,
        );
      }

      final midAngle = angle + pi / 8;
      path.quadraticBezierTo(
        center.dx + cos(midAngle) * innerRadius,
        center.dy + sin(midAngle) * innerRadius,
        center.dx + cos(angle + pi / 4) * (radius * (0.8 + 0.4 * sin(progress * pi * 4 + i + 1))),
        center.dy + sin(angle + pi / 4) * (radius * (0.8 + 0.4 * sin(progress * pi * 4 + i + 1))),
      );
    }

    path.close();
    canvas.drawPath(path, paint);

    // グロー効果
    paint
      ..color = Colors.yellow.withOpacity(opacity * 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, radius * 0.6, paint);
  }

  void _drawWaterEffect(Canvas canvas, Offset center, Paint paint) {
    // 水の波紋
    for (int i = 3; i >= 0; i--) {
      final ringProgress = (progress + i * 0.1).clamp(0.0, 1.0);
      final radius = 50 * ringProgress * scale;
      final ringOpacity = (1 - ringProgress) * opacity;

      paint
        ..color = Colors.blue.withOpacity(ringOpacity * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawCircle(center, radius, paint);
    }
  }

  void _drawThunderEffect(Canvas canvas, Offset center, Paint paint) {
    // 雷のジグザグ
    paint
      ..color = Colors.yellow.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final random = Random(42);
    for (int i = 0; i < 3; i++) {
      final path = Path();
      final startAngle = (2 * pi * i) / 3;
      var currentPos = center;
      path.moveTo(currentPos.dx, currentPos.dy);

      for (int j = 0; j < 4; j++) {
        final nextPos = Offset(
          currentPos.dx + cos(startAngle) * 15 * scale + (random.nextDouble() - 0.5) * 20,
          currentPos.dy + sin(startAngle) * 15 * scale + (random.nextDouble() - 0.5) * 20,
        );
        path.lineTo(nextPos.dx, nextPos.dy);
        currentPos = nextPos;
      }

      canvas.drawPath(path, paint);
    }

    // グロー
    paint
      ..color = Colors.white.withOpacity(opacity * 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, 20 * scale, paint);
  }

  void _drawWindEffect(Canvas canvas, Offset center, Paint paint) {
    // 風の渦巻き
    paint
      ..color = Colors.green.withOpacity(opacity * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < 3; i++) {
      final path = Path();
      final startAngle = progress * pi * 2 + (2 * pi * i) / 3;
      
      for (double t = 0; t < pi * 2; t += 0.1) {
        final radius = (10 + t * 8) * scale;
        final angle = startAngle + t;
        final x = center.dx + cos(angle) * radius;
        final y = center.dy + sin(angle) * radius;

        if (t == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, paint);
    }
  }

  void _drawEarthEffect(Canvas canvas, Offset center, Paint paint) {
    // 岩のような破片
    final random = Random(42);
    paint
      ..color = Colors.brown.withOpacity(opacity * 0.8)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 6; i++) {
      final angle = (2 * pi * i) / 6 + progress * pi / 4;
      final distance = (20 + random.nextDouble() * 20) * scale;
      final size = (8 + random.nextDouble() * 8) * scale;

      final rect = Rect.fromCenter(
        center: Offset(
          center.dx + cos(angle) * distance,
          center.dy + sin(angle) * distance,
        ),
        width: size,
        height: size,
      );

      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.rotate(angle + progress * pi);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: size, height: size),
        paint,
      );
      canvas.restore();
    }
  }

  void _drawLightEffect(Canvas canvas, Offset center, Paint paint) {
    // 光の放射
    paint
      ..color = Colors.amber.withOpacity(opacity * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (int i = 0; i < 8; i++) {
      final angle = (2 * pi * i) / 8 + progress * pi / 4;
      final length = 40 * scale;

      canvas.drawLine(
        center,
        Offset(
          center.dx + cos(angle) * length,
          center.dy + sin(angle) * length,
        ),
        paint,
      );
    }

    // 中心グロー
    paint
      ..color = Colors.white.withOpacity(opacity * 0.8)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(center, 15 * scale, paint);
  }

  void _drawDarkEffect(Canvas canvas, Offset center, Paint paint) {
    // 闇の渦
    for (int i = 0; i < 4; i++) {
      final ringOpacity = (1 - i * 0.2) * opacity;
      paint
        ..color = Colors.purple.withOpacity(ringOpacity * 0.5)
        ..style = PaintingStyle.fill;

      final radius = (50 - i * 10) * scale * (0.5 + 0.5 * progress);
      canvas.drawCircle(center, radius, paint);
    }

    // 中心の暗い核
    paint
      ..color = Colors.black.withOpacity(opacity * 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(center, 10 * scale, paint);
  }

  void _drawDefaultEffect(Canvas canvas, Offset center, Paint paint) {
    // デフォルトの衝撃波
    paint
      ..color = Colors.grey.withOpacity(opacity * 0.6)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 30 * scale, paint);
  }

  void _drawParticles(Canvas canvas, Offset center) {
    for (final particle in particles) {
      final particleProgress = (progress - particle.delay).clamp(0.0, 1.0);
      if (particleProgress <= 0) continue;

      final distance = particle.distance * particleProgress * scale;
      final particleOpacity = (1 - particleProgress) * opacity;
      final particleSize = particle.size * (1 - particleProgress * 0.5);

      final paint = Paint()
        ..color = particle.color.withOpacity(particleOpacity)
        ..style = PaintingStyle.fill;

      final pos = Offset(
        center.dx + cos(particle.angle) * distance,
        center.dy + sin(particle.angle) * distance,
      );

      canvas.drawCircle(pos, particleSize, paint);
    }
  }

  Color _getElementColor(String element) {
    switch (element.toLowerCase()) {
      case 'fire':
        return Colors.deepOrange;
      case 'water':
        return Colors.blue;
      case 'thunder':
        return Colors.yellow;
      case 'wind':
        return Colors.green;
      case 'earth':
        return Colors.brown;
      case 'light':
        return Colors.amber;
      case 'dark':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  bool shouldRepaint(covariant _SkillEffectPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.opacity != opacity ||
        oldDelegate.scale != scale;
  }
}

/// ヒットエフェクト（被ダメージ時の白フラッシュ）
class HitFlashWidget extends StatefulWidget {
  final Widget child;
  final bool isHit;
  final VoidCallback? onComplete;

  const HitFlashWidget({
    Key? key,
    required this.child,
    required this.isHit,
    this.onComplete,
  }) : super(key: key);

  @override
  State<HitFlashWidget> createState() => _HitFlashWidgetState();
}

class _HitFlashWidgetState extends State<HitFlashWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flashAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _flashAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.7), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.7, end: 0.0), weight: 20),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(HitFlashWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isHit && !oldWidget.isHit) {
      _controller.reset();
      _controller.forward().whenComplete(() {
        widget.onComplete?.call();
      });
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
      animation: _flashAnimation,
      builder: (context, child) {
        return ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.white.withOpacity(_flashAnimation.value),
            BlendMode.srcATop,
          ),
          child: widget.child,
        );
      },
    );
  }
}