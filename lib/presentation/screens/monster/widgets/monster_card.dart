// lib/presentation/screens/monster/widgets/monster_card.dart

import 'package:flutter/material.dart';
import '../../../../domain/entities/monster.dart';

class MonsterCard extends StatelessWidget {
  final Monster monster;
  final VoidCallback onTap;
  final Function(bool) onFavoriteToggle;
  final Function(bool)? onLockToggle;
  final bool isCompact; // ✅ 追加: コンパクト表示フラグ

  const MonsterCard({
    super.key,
    required this.monster,
    required this.onTap,
    required this.onFavoriteToggle,
    this.onLockToggle,
    this.isCompact = false, // ✅ デフォルトは通常サイズ
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: _getRarityColor(),
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // モンスター画像エリア
                Expanded(
                  flex: isCompact ? 2 : 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getRarityColor().withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                    ),
                    child: Stack(
                      children: [
                        // モンスター画像（プレースホルダー）
                        Center(
                          child: Icon(
                            _getSpeciesIcon(),
                            size: isCompact ? 32 : 48,
                            color: _getElementColor(),
                          ),
                        ),
                        // レベル表示
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Lv.${monster.level}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isCompact ? 10 : 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        // HPバー
                        if (!isCompact)
                          Positioned(
                            bottom: 4,
                            right: 4,
                            left: 40,
                            child: _buildHpBar(),
                          ),
                      ],
                    ),
                  ),
                ),
                // 情報エリア
                Expanded(
                  flex: isCompact ? 1 : 2,
                  child: Padding(
                    padding: EdgeInsets.all(isCompact ? 4.0 : 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 名前
                        Text(
                          monster.monsterName,
                          style: TextStyle(
                            fontSize: isCompact ? 11 : 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!isCompact) ...[
                          const SizedBox(height: 4),
                          // レアリティ
                          Row(
                            children: [
                              Text(
                                monster.rarityStars,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getRarityColor(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // 種族・属性
                          Row(
                            children: [
                              _buildBadge(
                                monster.speciesName,
                                Colors.grey[700]!,
                              ),
                              const SizedBox(width: 4),
                              _buildBadge(
                                monster.elementName,
                                _getElementColor(),
                              ),
                            ],
                          ),
                        ] else ...[
                          // コンパクト表示ではレアリティのみ
                          Text(
                            monster.rarityStars,
                            style: TextStyle(
                              fontSize: 10,
                              color: _getRarityColor(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // お気に入りボタン
            Positioned(
              top: isCompact ? 4 : 8,
              right: isCompact ? 4 : 8,
              child: GestureDetector(
                onTap: () {
                  onFavoriteToggle(!monster.isFavorite);
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: EdgeInsets.all(isCompact ? 2 : 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    monster.isFavorite ? Icons.star : Icons.star_border,
                    color: monster.isFavorite ? Colors.amber : Colors.grey,
                    size: isCompact ? 16 : 20,
                  ),
                ),
              ),
            ),
            // ロックアイコン
            if (onLockToggle != null)
              Positioned(
                top: isCompact ? 4 : 8,
                left: isCompact ? 4 : 8,
                child: GestureDetector(
                  onTap: () {
                    onLockToggle!(!monster.isLocked);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: EdgeInsets.all(isCompact ? 2 : 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      monster.isLocked ? Icons.lock : Icons.lock_open,
                      color: monster.isLocked ? Colors.red : Colors.grey,
                      size: isCompact ? 16 : 20,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// HPバーを構築 ✅ 修正: currentHp / maxHp を正しく表示
  Widget _buildHpBar() {
    final percentage = monster.hpPercentage;
    final color = _getHpBarColor(percentage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ✅ 修正: 実際のHP値を表示（100固定ではない）
        Text(
          '${monster.currentHp}/${monster.maxHp}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(1, 1),
                blurRadius: 2,
                color: Colors.black,
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// バッジを構築
  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// レアリティカラーを取得
  Color _getRarityColor() {
    switch (monster.rarity) {
      case 5:
        return const Color(0xFFFFD700); // Gold
      case 4:
        return const Color(0xFF9C27B0); // Purple
      case 3:
        return const Color(0xFF2196F3); // Blue
      case 2:
        return const Color(0xFF4CAF50); // Green
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  /// 属性カラーを取得
  Color _getElementColor() {
    switch (monster.element.toLowerCase()) {
      case 'fire':
        return const Color(0xFFFF5722);
      case 'water':
        return const Color(0xFF2196F3);
      case 'thunder':
        return const Color(0xFFFFC107);
      case 'wind':
        return const Color(0xFF4CAF50);
      case 'earth':
        return const Color(0xFF795548);
      case 'light':
        return const Color(0xFFFFEB3B);
      case 'dark':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF95A5A6);
    }
  }

  /// HPバーの色を取得
  Color _getHpBarColor(double percentage) {
    if (percentage >= 0.7) {
      return Colors.green;
    } else if (percentage >= 0.3) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  /// 種族アイコンを取得
  IconData _getSpeciesIcon() {
    switch (monster.species.toLowerCase()) {
      case 'angel':
        return Icons.auto_awesome;
      case 'demon':
        return Icons.pest_control;
      case 'human':
        return Icons.person;
      case 'spirit':
        return Icons.cloud;
      case 'mechanoid':
        return Icons.precision_manufacturing;
      case 'dragon':
        return Icons.castle;
      case 'mutant':
        return Icons.psychology;
      default:
        return Icons.pets;
    }
  }
}