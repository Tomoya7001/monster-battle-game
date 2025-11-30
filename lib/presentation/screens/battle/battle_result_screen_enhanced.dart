// lib/presentation/screens/battle/battle_result_screen_enhanced.dart

import 'dart:math';
import 'package:flutter/material.dart';
import '../../../domain/models/battle/battle_result.dart';
import '../../../domain/models/stage/stage_data.dart';

/// 強化版バトル結果画面
class BattleResultScreenEnhanced extends StatefulWidget {
  final BattleResult result;
  final StageData? stageData;

  const BattleResultScreenEnhanced({
    Key? key,
    required this.result,
    this.stageData,
  }) : super(key: key);

  @override
  State<BattleResultScreenEnhanced> createState() => _BattleResultScreenEnhancedState();
}

class _BattleResultScreenEnhancedState extends State<BattleResultScreenEnhanced>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _contentController;
  late AnimationController _rewardsController;
  late AnimationController _confettiController;

  late Animation<double> _headerScale;
  late Animation<double> _headerOpacity;
  late Animation<Offset> _contentSlide;
  late Animation<double> _contentOpacity;

  @override
  void initState() {
    super.initState();
    
    // ヘッダーアニメーション
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
    ]).animate(_headerController);
    _headerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: const Interval(0.0, 0.5)),
    );

    // コンテンツアニメーション
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _contentController, curve: Curves.easeOut));
    _contentOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(_contentController);

    // 報酬アニメーション
    _rewardsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // 紙吹雪アニメーション（勝利時）
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // アニメーション開始
    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _headerController.forward();
    
    await Future.delayed(const Duration(milliseconds: 400));
    _contentController.forward();
    
    await Future.delayed(const Duration(milliseconds: 300));
    _rewardsController.forward();
    
    if (widget.result.isWin) {
      _confettiController.repeat();
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    _contentController.dispose();
    _rewardsController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop(widget.result.isWin);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // 背景グラデーション
            _buildBackground(),
            
            // 紙吹雪（勝利時）
            if (widget.result.isWin) _buildConfetti(),
            
            // メインコンテンツ
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      
                      // 勝敗ヘッダー
                      _buildAnimatedHeader(),
                      
                      const SizedBox(height: 24),
                      
                      // コンテンツ
                      SlideTransition(
                        position: _contentSlide,
                        child: FadeTransition(
                          opacity: _contentOpacity,
                          child: Column(
                            children: [
                              // ステージ情報
                              if (widget.stageData != null) ...[
                                _buildStageCard(),
                                const SizedBox(height: 16),
                              ],
                              
                              // バトル統計
                              _buildBattleStatsCard(),
                              
                              const SizedBox(height: 16),
                              
                              // MVP表示
                              if (widget.result.expGains.isNotEmpty)
                                _buildMvpCard(),
                              
                              const SizedBox(height: 16),
                              
                              // 報酬
                              _buildAnimatedRewards(),
                              
                              const SizedBox(height: 16),
                              
                              // 経験値獲得
                              if (widget.result.expGains.isNotEmpty)
                                _buildExpGainsCard(),
                              
                              const SizedBox(height: 24),
                              
                              // ボタン
                              _buildButtons(),
                              
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 背景
  Widget _buildBackground() {
    final colors = widget.result.isWin
        ? [Colors.green.shade800, Colors.green.shade400, Colors.teal.shade300]
        : [Colors.red.shade900, Colors.red.shade600, Colors.grey.shade700];
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
    );
  }

  /// 紙吹雪
  Widget _buildConfetti() {
    return AnimatedBuilder(
      animation: _confettiController,
      builder: (context, child) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _ConfettiPainter(progress: _confettiController.value),
        );
      },
    );
  }

  /// アニメーション付きヘッダー
  Widget _buildAnimatedHeader() {
    return ScaleTransition(
      scale: _headerScale,
      child: FadeTransition(
        opacity: _headerOpacity,
        child: Column(
          children: [
            // アイコン
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
                boxShadow: [
                  BoxShadow(
                    color: (widget.result.isWin ? Colors.yellow : Colors.red).withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                widget.result.isWin ? Icons.emoji_events : Icons.cancel,
                size: 72,
                color: widget.result.isWin ? Colors.amber : Colors.white70,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // テキスト
            Text(
              widget.result.isWin ? 'VICTORY!' : 'DEFEAT...',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 4,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              widget.result.isWin ? 'おめでとうございます！' : '次は頑張りましょう',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ステージカード
  Widget _buildStageCard() {
    return _buildCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.flag, color: Colors.blue.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.stageData!.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.stageData!.description != null)
                  Text(
                    widget.stageData!.description!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          if (widget.result.isWin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'CLEAR',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// バトル統計カード
  Widget _buildBattleStatsCard() {
    return _buildCard(
      title: 'バトル統計',
      child: Column(
        children: [
          _buildStatRow(
            icon: Icons.timer,
            label: 'ターン数',
            value: '${widget.result.turnCount}ターン',
          ),
          const Divider(height: 24),
          _buildStatRow(
            icon: Icons.group,
            label: '使用モンスター',
            value: '${widget.result.usedMonsterIds.length}体',
          ),
          const Divider(height: 24),
          _buildStatRow(
            icon: Icons.sports_martial_arts,
            label: '撃破数',
            value: '${widget.result.defeatedEnemyIds.length}体',
          ),
        ],
      ),
    );
  }

  /// MVP表示
  Widget _buildMvpCard() {
    // 最も経験値を獲得したモンスターをMVPとする
    // ★修正: gainedExp を使用
    final mvp = widget.result.expGains.reduce(
      (a, b) => a.gainedExp > b.gainedExp ? a : b,
    );
    
    return _buildCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade600, Colors.orange],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'MVP',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber, width: 3),
                ),
                child: Icon(
                  Icons.pets,
                  size: 32,
                  color: Colors.amber.shade700,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mvp.monsterName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // ★修正: gainedExp を使用
                  Text(
                    '+${mvp.gainedExp} EXP',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// アニメーション付き報酬
  Widget _buildAnimatedRewards() {
    final rewards = widget.result.rewards;
    
    return _buildCard(
      title: '獲得報酬',
      child: AnimatedBuilder(
        animation: _rewardsController,
        builder: (context, child) {
          return Column(
            children: [
              // 経験値
              _buildRewardItem(
                icon: Icons.auto_awesome,
                iconColor: Colors.purple,
                label: '経験値',
                value: rewards.exp,
                delay: 0.0,
              ),
              const SizedBox(height: 12),
              
              // ゴールド
              _buildRewardItem(
                icon: Icons.monetization_on,
                iconColor: Colors.amber,
                label: 'ゴールド',
                value: rewards.gold,
                delay: 0.2,
              ),
              
              // ジェム
              if (rewards.gems > 0) ...[
                const SizedBox(height: 12),
                _buildRewardItem(
                  icon: Icons.diamond,
                  iconColor: Colors.cyan,
                  label: 'ジェム',
                  value: rewards.gems,
                  delay: 0.4,
                ),
              ],
              
              // アイテム
              if (rewards.items.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  '獲得アイテム',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...rewards.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.inventory_2, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(item.itemName),
                      ),
                      Text(
                        'x${item.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildRewardItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required int value,
    required double delay,
  }) {
    final progress = ((_rewardsController.value - delay) / (1 - delay)).clamp(0.0, 1.0);
    final displayValue = (value * progress).round();
    
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(fontSize: 15),
        ),
        const Spacer(),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.elasticOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: progress > 0.9 ? scale : 1.0,
              child: Text(
                '+$displayValue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// 経験値獲得カード
  Widget _buildExpGainsCard() {
    return _buildCard(
      title: '経験値獲得',
      child: Column(
        children: widget.result.expGains.map((gain) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.pets, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gain.monsterName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      // ★修正: levelBefore, levelAfter を使用
                      Text(
                        'Lv.${gain.levelBefore} → Lv.${gain.levelAfter}',
                        style: TextStyle(
                          fontSize: 12,
                          color: gain.didLevelUp
                              ? Colors.green.shade700
                              : Colors.grey.shade600,
                          fontWeight: gain.didLevelUp
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // ★修正: gainedExp を使用
                    Text(
                      '+${gain.gainedExp}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    // ★修正: didLevelUp を使用
                    if (gain.didLevelUp)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'LEVEL UP!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// ボタン
  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              // ★修正: 勝敗結果を返しながら戻る
              Navigator.of(context).pop(widget.result.isWin);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.grey.shade800,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'ホームへ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        if (widget.result.isWin && widget.stageData != null) ...[
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // ★修正: 勝敗結果を返す
                Navigator.of(context).pop(widget.result.isWin);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '次へ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// カード共通ウィジェット
  Widget _buildCard({String? title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(label),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

/// 紙吹雪ペインター
class _ConfettiPainter extends CustomPainter {
  final double progress;
  final Random _random = Random(42);

  _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.cyan,
    ];

    for (int i = 0; i < 50; i++) {
      final x = _random.nextDouble() * size.width;
      final baseY = _random.nextDouble() * size.height * 0.3;
      final y = baseY + (progress * size.height * 1.5) + (sin(progress * 10 + i) * 20);
      
      if (y > size.height) continue;
      
      final color = colors[i % colors.length];
      final paint = Paint()..color = color.withOpacity(0.8);
      
      final rectSize = 6 + _random.nextDouble() * 6;
      final rotation = progress * 10 + i;
      
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: rectSize, height: rectSize * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}