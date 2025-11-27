import 'package:flutter/material.dart';
import '../../../../domain/entities/monster.dart';

class MonsterCard extends StatelessWidget {
  final Monster monster;
  final VoidCallback onTap;
  final bool isCompact;
  
  // ★ お気に入り表示制御
  final bool showFavoriteIcon;
  final Function(bool)? onFavoriteToggle;
  
  // ★ 鍵マーク表示制御
  final bool showLockIcon;
  final Function(bool)? onLockToggle;

  const MonsterCard({
    super.key,
    required this.monster,
    required this.onTap,
    this.isCompact = false,
    this.showFavoriteIcon = true,
    this.onFavoriteToggle,
    this.showLockIcon = false,
    this.onLockToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: _getRarityColor(), width: 2),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // モンスター画像エリア
                Expanded(
                  flex: isCompact ? 3 : 4,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _getElementColor().withOpacity(0.3),
                          _getElementColor().withOpacity(0.1),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            _getSpeciesIcon(),
                            size: isCompact ? 28 : 52,
                            color: _getElementColor(),
                          ),
                        ),
                        // レベル表示
                        Positioned(
                          bottom: 2,
                          left: 2,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isCompact ? 3 : 6,
                              vertical: isCompact ? 1 : 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Lv.${monster.level}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isCompact ? 8 : 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        // HPバー（大表示のみ詳細表示）
                        if (!isCompact)
                          Positioned(
                            bottom: 4,
                            right: 4,
                            left: 36,
                            child: _buildHpBar(),
                          )
                        else
                          // コンパクト時は簡易HPバー
                          Positioned(
                            bottom: 2,
                            right: 2,
                            left: 28,
                            child: _buildCompactHpBar(),
                          ),
                      ],
                    ),
                  ),
                ),
                // 情報エリア
                Expanded(
                  flex: isCompact ? 2 : 3,
                  child: Padding(
                    padding: EdgeInsets.all(isCompact ? 3.0 : 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          monster.monsterName,
                          style: TextStyle(
                            fontSize: isCompact ? 9 : 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          monster.rarityStars,
                          style: TextStyle(
                            fontSize: isCompact ? 8 : 11,
                            color: _getRarityColor(),
                          ),
                        ),
                        if (!isCompact) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Flexible(child: _buildBadge(monster.elementName, _getElementColor())),
                              const SizedBox(width: 2),
                              Flexible(child: _buildBadge(monster.speciesName, Colors.grey[600]!)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // 装備スロット表示
                          _buildEquipmentSlots(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // ★ お気に入りアイコン（表示のみ or タップ可能）
            if (showFavoriteIcon && monster.isFavorite)
              Positioned(
                top: isCompact ? 2 : 6,
                right: isCompact ? 2 : 6,
                child: GestureDetector(
                  onTap: onFavoriteToggle != null ? () => onFavoriteToggle!(!monster.isFavorite) : null,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: EdgeInsets.all(isCompact ? 2 : 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: isCompact ? 12 : 18,
                    ),
                  ),
                ),
              ),
            // ★ 鍵アイコン（詳細画面からのみ操作可能）
            if (showLockIcon && monster.isLocked)
              Positioned(
                top: isCompact ? 2 : 6,
                left: isCompact ? 2 : 6,
                child: GestureDetector(
                  onTap: onLockToggle != null ? () => onLockToggle!(!monster.isLocked) : null,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: EdgeInsets.all(isCompact ? 2 : 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock,
                      color: Colors.red,
                      size: isCompact ? 12 : 18,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHpBar() {
    final percentage = monster.hpPercentage;
    final color = _getHpBarColor(percentage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${monster.currentHp}/${monster.maxHp}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black)],
          ),
        ),
        const SizedBox(height: 2),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactHpBar() {
    final percentage = monster.hpPercentage;
    final color = _getHpBarColor(percentage);

    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: percentage.clamp(0.0, 1.0),
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 4,
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildEquipmentSlots() {
    final equippedCount = monster.equippedEquipment.length;
    // 基本1個、ヒューマン種族は2個（本来は特性で判定すべき）
    final maxSlots = monster.species.toLowerCase() == 'human' ? 2 : 1;
    
    return Row(
      children: [
        Icon(Icons.shield, size: 10, color: Colors.grey[600]),
        const SizedBox(width: 2),
        Text(
          '$equippedCount/$maxSlots',
          style: TextStyle(fontSize: 9, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Color _getRarityColor() {
    switch (monster.rarity) {
      case 5: return const Color(0xFFFFD700);
      case 4: return const Color(0xFF9C27B0);
      case 3: return const Color(0xFF2196F3);
      case 2: return const Color(0xFF4CAF50);
      default: return const Color(0xFF9E9E9E);
    }
  }

  Color _getElementColor() {
    switch (monster.element.toLowerCase()) {
      case 'fire': return const Color(0xFFFF5722);
      case 'water': return const Color(0xFF2196F3);
      case 'thunder': return const Color(0xFFFFC107);
      case 'wind': return const Color(0xFF4CAF50);
      case 'earth': return const Color(0xFF795548);
      case 'light': return const Color(0xFFFFEB3B);
      case 'dark': return const Color(0xFF9C27B0);
      default: return const Color(0xFF95A5A6);
    }
  }

  Color _getHpBarColor(double percentage) {
    if (percentage >= 0.7) return Colors.green;
    if (percentage >= 0.3) return Colors.orange;
    return Colors.red;
  }

  IconData _getSpeciesIcon() {
    switch (monster.species.toLowerCase()) {
      case 'angel': return Icons.auto_awesome;
      case 'demon': return Icons.pest_control;
      case 'human': return Icons.person;
      case 'spirit': return Icons.cloud;
      case 'mechanoid': return Icons.precision_manufacturing;
      case 'dragon': return Icons.castle;
      case 'mutant': return Icons.psychology;
      default: return Icons.pets;
    }
  }
}