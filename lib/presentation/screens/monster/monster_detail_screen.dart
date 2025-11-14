import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // ✅ 追加
import '../../../domain/entities/monster.dart';
import '../../bloc/monster/monster_bloc.dart'; // ✅ 追加
import '../../bloc/monster/monster_event.dart'; // ✅ 追加
import '../../bloc/monster/monster_state.dart'; // ✅ 追加

/// モンスター詳細画面
/// 
/// モンスターの詳細情報を表示します。
/// - ステータス（現在レベル / PvP時Lv50）
/// - 技一覧
/// - 特性
/// - 装備
class MonsterDetailScreen extends StatefulWidget {
  final Monster monster;

  const MonsterDetailScreen({
    super.key,
    required this.monster,
  });

  @override
  State<MonsterDetailScreen> createState() => _MonsterDetailScreenState();
}

class _MonsterDetailScreenState extends State<MonsterDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showPvPStats = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 修正: BlocBuilderでMonsterの最新状態を取得
    return BlocConsumer<MonsterBloc, MonsterState>(
      listener: (context, state) {
        if (state is MonsterUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is MonsterError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        // ✅ 修正: 最新のモンスター情報を取得
        Monster monster = widget.monster;
        
        // MonsterUpdatedまたはMonsterDetailLoadedの場合、最新データを使用
        if (state is MonsterUpdated && state.monster.id == widget.monster.id) {
          monster = state.monster;
        } else if (state is MonsterDetailLoaded && state.monster.id == widget.monster.id) {
          monster = state.monster;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(monster.monsterName),
            actions: [
              // お気に入りボタン
              IconButton(
                icon: Icon(
                  monster.isFavorite ? Icons.star : Icons.star_border,
                  color: monster.isFavorite ? Colors.amber : null,
                ),
                onPressed: () {
                  // ✅ 実装: お気に入りトグル
                  context.read<MonsterBloc>().add(
                        ToggleFavorite(
                          monsterId: monster.id,
                          isFavorite: !monster.isFavorite,
                        ),
                      );
                },
              ),
              // ロックボタン
              IconButton(
                icon: Icon(
                  monster.isLocked ? Icons.lock : Icons.lock_open,
                  color: monster.isLocked ? Colors.red : null,
                ),
                onPressed: () {
                  // ✅ 実装: ロックトグル
                  context.read<MonsterBloc>().add(
                        ToggleLock(
                          monsterId: monster.id,
                          isLocked: !monster.isLocked,
                        ),
                      );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // モンスター画像・基本情報
              _buildHeader(monster),
              // タブバー
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.blue,
                  tabs: const [
                    Tab(text: 'ステータス'),
                    Tab(text: '技'),
                    Tab(text: '特性・装備'),
                  ],
                ),
              ),
              // タブビュー
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStatusTab(monster),
                    _buildSkillsTab(monster),
                    _buildTraitsTab(monster),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ヘッダー部分を構築
  Widget _buildHeader(Monster monster) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getElementColor(monster.element),
            _getElementColor(monster.element).withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          // モンスター画像（暫定: アイコン）
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getSpeciesIcon(monster.species),
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          // 基本情報
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monster.monsterName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoBadge('Lv.${monster.level}'),
                    const SizedBox(width: 8),
                    _buildInfoBadge(monster.rarityStars),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoBadge(monster.speciesName),
                    const SizedBox(width: 8),
                    _buildInfoBadge(monster.elementName),
                  ],
                ),
                const SizedBox(height: 12),
                // HPバー
                _buildHpBar(monster),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ステータスタブを構築
  Widget _buildStatusTab(Monster monster) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lv50以上の場合、切り替えスイッチを表示
          if (monster.level >= 50) ...[
            SwitchListTile(
              title: const Text('PvP時のステータス（Lv50）を表示'),
              value: _showPvPStats,
              onChanged: (value) {
                setState(() => _showPvPStats = value);
              },
            ),
            const Divider(),
            const SizedBox(height: 8),
          ],
          // ステータス表示
          _buildStatsSection(monster, _showPvPStats),
          const SizedBox(height: 24),
          // 個体値表示
          _buildIVSection(monster),
          const SizedBox(height: 24),
          // ポイント振り分け表示
          _buildPointsSection(monster),
        ],
      ),
    );
  }

  /// ステータスセクションを構築
  Widget _buildStatsSection(Monster monster, bool showPvP) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              showPvP ? 'PvP時のステータス（Lv50）' : '現在のステータス',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              'HP',
              showPvP ? monster.lv50MaxHp : monster.maxHp,
              Colors.red,
            ),
            _buildStatRow(
              '攻撃',
              showPvP ? monster.lv50Attack : monster.attack,
              Colors.orange,
            ),
            _buildStatRow(
              '防御',
              showPvP ? monster.lv50Defense : monster.defense,
              Colors.blue,
            ),
            _buildStatRow(
              '魔力',
              showPvP ? monster.lv50Magic : monster.magic,
              Colors.purple,
            ),
            _buildStatRow(
              '素早さ',
              showPvP ? monster.lv50Speed : monster.speed,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  /// ステータス行を構築
  Widget _buildStatRow(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: LinearProgressIndicator(
              value: value / 500, // 最大500として正規化
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 20,
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 50,
            child: Text(
              value.toString(),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 個体値セクションを構築
  Widget _buildIVSection(Monster monster) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '個体値（-10～+10）',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildIVRow('HP', monster.ivHp),
            _buildIVRow('攻撃', monster.ivAttack),
            _buildIVRow('防御', monster.ivDefense),
            _buildIVRow('魔力', monster.ivMagic),
            _buildIVRow('素早さ', monster.ivSpeed),
          ],
        ),
      ),
    );
  }

  /// 個体値行を構築
  Widget _buildIVRow(String label, int iv) {
    final color = iv >= 5 ? Colors.green : (iv <= -5 ? Colors.red : Colors.grey);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(label),
          ),
          const SizedBox(width: 16),
          Text(
            '${iv >= 0 ? '+' : ''}$iv',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// ポイント振り分けセクションを構築
  Widget _buildPointsSection(Monster monster) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ポイント振り分け',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '残り: ${monster.remainingPoints}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPointRow('HP', monster.pointHp),
            _buildPointRow('攻撃', monster.pointAttack),
            _buildPointRow('防御', monster.pointDefense),
            _buildPointRow('魔力', monster.pointMagic),
            _buildPointRow('素早さ', monster.pointSpeed),
          ],
        ),
      ),
    );
  }

  /// ポイント行を構築
  Widget _buildPointRow(String label, int points) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(label),
          ),
          const SizedBox(width: 16),
          Text(
            '+$points',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 技タブを構築
  Widget _buildSkillsTab(Monster monster) {
    // TODO: 技マスタデータから取得
    return const Center(
      child: Text('技一覧（未実装）'),
    );
  }

  /// 特性・装備タブを構築
  Widget _buildTraitsTab(Monster monster) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 特性セクション
          const Text(
            '特性',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('特性データ（未実装）'),
            ),
          ),
          const SizedBox(height: 24),
          // 装備セクション
          const Text(
            '装備',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                monster.equippedEquipment.isEmpty
                    ? '装備なし'
                    : '装備: ${monster.equippedEquipment.length}個',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// HPバーを構築
  Widget _buildHpBar(Monster monster) {
    final percentage = monster.hpPercentage;
    final color = _getHpBarColor(percentage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HP: ${monster.currentHp}/${monster.maxHp}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 情報バッジを構築
  Widget _buildInfoBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  /// 属性カラーを取得
  Color _getElementColor(String element) {
    switch (element) {
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
  IconData _getSpeciesIcon(String species) {
    switch (species) {
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