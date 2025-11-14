import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class GachaAnimationWidget extends StatefulWidget {
  final List<GachaMonster> monsters;
  final VoidCallback onAnimationComplete;
  final bool skipAnimation;
  final bool isMultiPull;

  const GachaAnimationWidget({
    Key? key,
    required this.monsters,
    required this.onAnimationComplete,
    this.skipAnimation = false,
    this.isMultiPull = false,
  }) : super(key: key);

  @override
  State<GachaAnimationWidget> createState() => _GachaAnimationWidgetState();
}

class _GachaAnimationWidgetState extends State<GachaAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  int _currentIndex = 0;
  bool _showRarity = false;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();

    if (widget.skipAnimation) {
      _skipToResult();
      return;
    }

    _setupAnimations();
    _startAnimation();
  }

  @override
  void didUpdateWidget(GachaAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (!oldWidget.skipAnimation && widget.skipAnimation && !_isCompleted) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isCompleted) {
          _completeAnimation();
        }
      });
    }
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
  }

  Future<void> _startAnimation() async {
    if (widget.isMultiPull) {
      await _show10PullAnimation();
    } else {
      await _showSinglePullAnimation();
    }

    _completeAnimation();
  }

  Future<void> _showSinglePullAnimation() async {
    for (int i = 0; i < widget.monsters.length; i++) {
      if (widget.skipAnimation || !mounted) break;
      
      if (mounted) {
        setState(() {
          _currentIndex = i;
          _showRarity = false;
        });
      }

      await _fadeController.forward();
      await Future.delayed(const Duration(milliseconds: 300));

      if (widget.skipAnimation || !mounted) break;
      
      if (mounted) {
        setState(() => _showRarity = true);
      }
      await _scaleController.forward();

      final rarity = widget.monsters[i].rarity;
      final waitDuration = _getWaitDurationByRarity(rarity);
      
      await Future.delayed(waitDuration);

      if (widget.skipAnimation || !mounted) break;

      if (i < widget.monsters.length - 1) {
        await _fadeController.reverse();
        await _scaleController.reverse();
      }
    }
  }

  Future<void> _show10PullAnimation() async {
    if (widget.skipAnimation || !mounted) return;
    
    await _fadeController.forward();
    if (mounted) {
      setState(() => _showRarity = true);
    }
    await _scaleController.forward();

    if (widget.skipAnimation || !mounted) return;

    final maxRarity = widget.monsters
        .map((m) => m.rarity)
        .reduce((a, b) => a > b ? a : b);
    final waitDuration = _getWaitDurationByRarity(maxRarity);
    await Future.delayed(waitDuration);
  }

  Duration _getWaitDurationByRarity(int rarity) {
    switch (rarity) {
      case 5:
        return const Duration(milliseconds: 2000);
      case 4:
        return const Duration(milliseconds: 1500);
      default:
        return const Duration(milliseconds: 1000);
    }
  }

  void _skipToResult() {
    _isCompleted = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onAnimationComplete();
      }
    });
  }

  void _completeAnimation() {
    if (_isCompleted) return;
    _isCompleted = true;
    
    if (mounted) {
      widget.onAnimationComplete();
    }
  }

  @override
    void dispose() {
    // アニメーションを強制停止してから破棄
    if (_fadeController.isAnimating) {
        _fadeController.stop();
    }
    _fadeController.dispose();
    
    if (_scaleController.isAnimating) {
        _scaleController.stop();
    }
    _scaleController.dispose();
    
    super.dispose();
    }

  @override
  Widget build(BuildContext context) {
    if (widget.skipAnimation || _isCompleted) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.black87,
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: widget.isMultiPull
              ? _build10PullLayout()
              : _buildSinglePullLayout(),
        ),
      ),
    );
  }

  Widget _buildSinglePullLayout() {
    if (_currentIndex >= widget.monsters.length) {
      return const SizedBox.shrink();
    }
    
    final monster = widget.monsters[_currentIndex];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: _getRarityColor(monster.rarity).withOpacity(0.3),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Center(
            child: Icon(
              Icons.catching_pokemon,
              size: 100,
              color: _getRarityColor(monster.rarity),
            ),
          ),
        ),
        const SizedBox(height: 32),
        if (_showRarity)
          ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    monster.rarity,
                    (index) => Icon(
                      Icons.star,
                      color: _getRarityColor(monster.rarity),
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  monster.name,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _getRarityColor(monster.rarity),
                  ),
                ),
                Text(
                  '${monster.race} / ${monster.element}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _build10PullLayout() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GridView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.7,
        ),
        itemCount: widget.monsters.length,
        itemBuilder: (context, index) {
          final monster = widget.monsters[index];
          return _buildMonsterCard(monster);
        },
      ),
    );
  }

  Widget _buildMonsterCard(GachaMonster monster) {
    return Container(
      decoration: BoxDecoration(
        color: _getRarityColor(monster.rarity).withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getRarityColor(monster.rarity),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.catching_pokemon,
            size: 40,
            color: _getRarityColor(monster.rarity),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              monster.rarity,
              (index) => Icon(
                Icons.star,
                color: _getRarityColor(monster.rarity),
                size: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRarityColor(int rarity) {
    switch (rarity) {
      case 5:
        return Colors.amber;
      case 4:
        return Colors.purple;
      case 3:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

class GachaMonster {
  final String name;
  final int rarity;
  final String race;
  final String element;

  GachaMonster({
    required this.name,
    required this.rarity,
    required this.race,
    required this.element,
  });
}