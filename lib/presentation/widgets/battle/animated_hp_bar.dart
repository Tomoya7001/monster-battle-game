import 'package:flutter/material.dart';

/// アニメーション付きHPバー
class AnimatedHpBar extends StatefulWidget {
  final int currentHp;
  final int maxHp;
  final Duration animationDuration;
  final bool showDamageFlash;

  const AnimatedHpBar({
    Key? key,
    required this.currentHp,
    required this.maxHp,
    this.animationDuration = const Duration(milliseconds: 500),
    this.showDamageFlash = false,
  }) : super(key: key);

  @override
  State<AnimatedHpBar> createState() => _AnimatedHpBarState();
}

class _AnimatedHpBarState extends State<AnimatedHpBar>
    with TickerProviderStateMixin {
  late AnimationController _hpController;
  late AnimationController _flashController;
  late Animation<double> _hpAnimation;
  late Animation<Color?> _flashAnimation;

  double _previousHpPercentage = 1.0;

  @override
  void initState() {
    super.initState();

    _hpController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _flashController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _hpAnimation = Tween<double>(
      begin: 1.0,
      end: widget.currentHp / widget.maxHp,
    ).animate(CurvedAnimation(
      parent: _hpController,
      curve: Curves.easeOutCubic,
    ));

    _flashAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.red.withOpacity(0.5),
    ).animate(CurvedAnimation(
      parent: _flashController,
      curve: Curves.easeInOut,
    ));

    _previousHpPercentage = widget.currentHp / widget.maxHp;
  }

  @override
  void didUpdateWidget(AnimatedHpBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newPercentage = widget.currentHp / widget.maxHp;
    final oldPercentage = oldWidget.currentHp / oldWidget.maxHp;

    if (newPercentage != oldPercentage) {
      _hpAnimation = Tween<double>(
        begin: _previousHpPercentage,
        end: newPercentage,
      ).animate(CurvedAnimation(
        parent: _hpController,
        curve: Curves.easeOutCubic,
      ));

      _hpController.reset();
      _hpController.forward();

      // ダメージを受けた場合、フラッシュ
      if (newPercentage < oldPercentage && widget.showDamageFlash) {
        _flashController.forward().then((_) {
          _flashController.reverse();
        });
      }

      _previousHpPercentage = newPercentage;
    }
  }

  @override
  void dispose() {
    _hpController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_hpAnimation, _flashAnimation]),
      builder: (context, child) {
        final percentage = _hpAnimation.value;
        final hpColor = _getHpColor(percentage);

        return Stack(
          children: [
            // HPバー背景
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(6),
              ),
            ),

            // HPバー本体（アニメーション）
            FractionallySizedBox(
              widthFactor: percentage.clamp(0.0, 1.0),
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      hpColor,
                      hpColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: hpColor.withOpacity(0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),

            // ダメージフラッシュ
            if (_flashAnimation.value != Colors.transparent)
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: _flashAnimation.value,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
          ],
        );
      },
    );
  }

  Color _getHpColor(double percentage) {
    if (percentage > 0.5) {
      return Colors.green;
    } else if (percentage > 0.25) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}

/// ダメージ数値表示（フェードイン/アウト）
class DamageText extends StatefulWidget {
  final int damage;
  final bool isCritical;
  final String? effectivenessText;
  final VoidCallback? onAnimationComplete;

  const DamageText({
    Key? key,
    required this.damage,
    this.isCritical = false,
    this.effectivenessText,
    this.onAnimationComplete,
  }) : super(key: key);

  @override
  State<DamageText> createState() => _DamageTextState();
}

class _DamageTextState extends State<DamageText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _positionAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0),
        weight: 20,
      ),
    ]).animate(_controller);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.5, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0),
        weight: 50,
      ),
    ]).animate(_controller);

    _positionAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -30),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward().whenComplete(() {
      widget.onAnimationComplete?.call();
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
          offset: _positionAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 効果テキスト
                  if (widget.effectivenessText != null)
                    Text(
                      widget.effectivenessText!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _getEffectivenessColor(widget.effectivenessText!),
                      ),
                    ),

                  // クリティカル表示
                  if (widget.isCritical)
                    const Text(
                      '急所！',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),

                  // ダメージ数値
                  Text(
                    '${widget.damage}',
                    style: TextStyle(
                      fontSize: widget.isCritical ? 32 : 24,
                      fontWeight: FontWeight.bold,
                      color: widget.isCritical ? Colors.orange : Colors.red,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(2, 2),
                          blurRadius: 4,
                        ),
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

  Color _getEffectivenessColor(String text) {
    if (text.contains('効果抜群')) {
      return Colors.green;
    } else if (text.contains('いまひとつ')) {
      return Colors.grey;
    }
    return Colors.white;
  }
}

/// 回復数値表示
class HealText extends StatefulWidget {
  final int amount;
  final VoidCallback? onAnimationComplete;

  const HealText({
    Key? key,
    required this.amount,
    this.onAnimationComplete,
  }) : super(key: key);

  @override
  State<HealText> createState() => _HealTextState();
}

class _HealTextState extends State<HealText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _positionAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0),
        weight: 20,
      ),
    ]).animate(_controller);

    _positionAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -20),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward().whenComplete(() {
      widget.onAnimationComplete?.call();
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
          offset: _positionAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Text(
              '+${widget.amount}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(1, 1),
                    blurRadius: 2,
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