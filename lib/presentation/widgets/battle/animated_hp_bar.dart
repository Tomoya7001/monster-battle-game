import 'package:flutter/material.dart';

/// アニメーション付きHPバー
class AnimatedHpBar extends StatefulWidget {
  final int currentHp;
  final int maxHp;
  final int? previousHp;
  final double height;
  final Duration animationDuration;
  final VoidCallback? onAnimationComplete;

  const AnimatedHpBar({
    Key? key,
    required this.currentHp,
    required this.maxHp,
    this.previousHp,
    this.height = 16,
    this.animationDuration = const Duration(milliseconds: 500),
    this.onAnimationComplete,
  }) : super(key: key);

  @override
  State<AnimatedHpBar> createState() => _AnimatedHpBarState();
}

class _AnimatedHpBarState extends State<AnimatedHpBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late double _startRatio;
  late double _endRatio;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _startRatio = (widget.previousHp ?? widget.currentHp) / widget.maxHp;
    _endRatio = widget.currentHp / widget.maxHp;

    _animation = Tween<double>(
      begin: _startRatio,
      end: _endRatio,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    ));

    if (widget.previousHp != null && widget.previousHp != widget.currentHp) {
      _controller.forward().then((_) {
        widget.onAnimationComplete?.call();
      });
    }
  }

  @override
  void didUpdateWidget(AnimatedHpBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.currentHp != widget.currentHp) {
      _startRatio = oldWidget.currentHp / widget.maxHp;
      _endRatio = widget.currentHp / widget.maxHp;

      _animation = Tween<double>(
        begin: _startRatio,
        end: _endRatio,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutQuart,
      ));

      _controller.reset();
      _controller.forward().then((_) {
        widget.onAnimationComplete?.call();
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
      animation: _animation,
      builder: (context, child) {
        final ratio = _animation.value.clamp(0.0, 1.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HP数値
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'HP',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  '${(widget.maxHp * ratio).round()} / ${widget.maxHp}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // バー本体
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
                if (_startRatio > _endRatio)
                  FractionallySizedBox(
                    widthFactor: _startRatio,
                    child: Container(
                      height: widget.height,
                      decoration: BoxDecoration(
                        color: Colors.red.shade200,
                        borderRadius: BorderRadius.circular(widget.height / 2),
                      ),
                    ),
                  ),
                // メインバー
                FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(
                    height: widget.height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _getGradientColors(ratio),
                      ),
                      borderRadius: BorderRadius.circular(widget.height / 2),
                      boxShadow: [
                        BoxShadow(
                          color: _getHpColor(ratio).withOpacity(0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                // 光沢
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(widget.height / 2),
                    child: FractionallySizedBox(
                      widthFactor: ratio,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.3),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Color _getHpColor(double ratio) {
    if (ratio > 0.5) return Colors.green;
    if (ratio > 0.25) return Colors.orange;
    return Colors.red;
  }

  List<Color> _getGradientColors(double ratio) {
    if (ratio > 0.5) {
      return [Colors.green.shade400, Colors.green.shade600];
    } else if (ratio > 0.25) {
      return [Colors.orange.shade400, Colors.orange.shade600];
    } else {
      return [Colors.red.shade400, Colors.red.shade600];
    }
  }
}

/// コストゲージ（アニメーション付き）
class AnimatedCostGauge extends StatelessWidget {
  final int currentCost;
  final int maxCost;
  final Color color;

  const AnimatedCostGauge({
    Key? key,
    required this.currentCost,
    required this.maxCost,
    this.color = Colors.blue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'コスト: ',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        ...List.generate(maxCost, (index) {
          final isFilled = index < currentCost;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: isFilled ? 1.0 : 0.0),
            duration: Duration(milliseconds: 200 + index * 50),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + value * 0.2,
                child: Container(
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: isFilled ? color : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: isFilled
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: isFilled
                      ? Icon(
                          Icons.flash_on,
                          size: 12,
                          color: Colors.white.withOpacity(value),
                        )
                      : null,
                ),
              );
            },
          );
        }),
        const SizedBox(width: 8),
        Text(
          '$currentCost/$maxCost',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}