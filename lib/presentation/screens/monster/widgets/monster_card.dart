import 'package:flutter/material.dart';
import '../../../../domain/entities/monster.dart';

/// モンスターカード
/// 
/// GridView内で表示される個々のモンスターのカードです。
/// モンスター画像、名前、レベル、レアリティ、HP状態などを表示します。
class MonsterCard extends StatelessWidget {
  final Monster monster;
  final VoidCallback onTap;
  final Function(bool) onFavoriteToggle;
  final Function(bool)? onLockToggle; // ✅ 追加: ロック機能のコールバック

  const MonsterCard({
    super.key,
    required this.monster,
    required this.onTap,
    required this.onFavoriteToggle,
    this.onLockToggle, // ✅ 追加: オプショナル
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
            // メインコンテンツ
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // モンスター画像エリア
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getElementColor().withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 暫定: アイコン表示（後で画像に置き換え）
                          Icon(
                            _getSpeciesIcon(),
                            size: 60,
                            color: _getElementColor(),
                          ),
                          const SizedBox(height: 8),
                          // HPバー
                          _buildHpBar(),
                        ],
                      ),
                    ),
                  ),
                ),
                // 情報エリア
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 名前
                        Text(
                          monster.monsterName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // レベル・レアリティ
                        Row(
                          children: [
                            Text(
                              'Lv.${monster.level}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // お気に入りボタン
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                // ✅ 修正: イベント伝播を停止
                onTap: () {
                  onFavoriteToggle(!monster.isFavorite);
                },
                behavior: HitTestBehavior.opaque, // ✅ 追加: タップ領域を明確化
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    monster.isFavorite ? Icons.star : Icons.star_border,
                    color: monster.isFavorite ? Colors.amber : Colors.grey,
                    size: 20,
                  ),
                ),
              ),
            ),
            // ロックアイコン（表示のみ → タップ可能に変更）
            // ✅ 修正: ロックボタンをタップ可能に
            Positioned(
              top: 8,
              left: 8,
              child: GestureDetector(
                onTap: onLockToggle != null
                    ? () {
                        onLockToggle!(!monster.isLocked);
                      }
                    : null,
                behavior: HitTestBehavior.opaque, // ✅ 追加: タップ領域を明確化
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    monster.isLocked ? Icons.lock : Icons.lock_open,
                    color: monster.isLocked ? Colors.red[400] : Colors.grey,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// HPバーを構築
  Widget _buildHpBar() {
    final percentage = monster.hpPercentage;
    final color = _getHpBarColor(percentage);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // HPテキスト
          Text(
            'HP: ${monster.currentHp}/${monster.maxHp}',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          // HPバー
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// バッジを構築
  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// レアリティカラーを取得
  Color _getRarityColor() {
    switch (monster.rarity) {
      case 5:
        return const Color(0xFFFFD700); // 金
      case 4:
        return const Color(0xFF9B59B6); // 紫
      case 3:
        return const Color(0xFF3498DB); // 青
      case 2:
      default:
        return const Color(0xFF95A5A6); // 灰色
    }
  }

  /// 属性カラーを取得
  Color _getElementColor() {
    switch (monster.element) {
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
      case 'none':
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
    switch (monster.species) {
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