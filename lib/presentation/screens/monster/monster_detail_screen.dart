import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/monster.dart';
import '../../../core/services/monster_service.dart';
import '../../bloc/monster/monster_bloc.dart';
import '../../bloc/monster/monster_event.dart';
import '../../bloc/monster/monster_state.dart';

class MonsterDetailScreen extends StatefulWidget {
  final Monster monster;

  const MonsterDetailScreen({super.key, required this.monster});

  @override
  State<MonsterDetailScreen> createState() => _MonsterDetailScreenState();
}

class _MonsterDetailScreenState extends State<MonsterDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showPvPStats = false;
  final MonsterService _monsterService = MonsterService();
  List<Map<String, dynamic>> _availableSkills = [];
  List<Map<String, dynamic>> _availableTraits = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMasterData();
  }

  Future<void> _loadMasterData() async {
    final skills = await _monsterService.getAvailableSkills();
    final traits = await _monsterService.getAvailableTraits();
    setState(() {
      _availableSkills = skills;
      _availableTraits = traits;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MonsterBloc, MonsterState>(
      listener: (context, state) {
        if (state is MonsterUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), duration: const Duration(seconds: 1)),
          );
        } else if (state is MonsterError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        Monster monster = widget.monster;
        if (state is MonsterUpdated && state.monster.id == widget.monster.id) {
          monster = state.monster;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(monster.monsterName),
            actions: [
              IconButton(
                icon: Icon(monster.isFavorite ? Icons.star : Icons.star_border,
                    color: monster.isFavorite ? Colors.amber : null),
                onPressed: () => context.read<MonsterBloc>().add(
                    ToggleFavorite(monsterId: monster.id, isFavorite: !monster.isFavorite)),
              ),
              IconButton(
                icon: Icon(monster.isLocked ? Icons.lock : Icons.lock_open,
                    color: monster.isLocked ? Colors.red : null),
                onPressed: () => context.read<MonsterBloc>().add(
                    ToggleLock(monsterId: monster.id, isLocked: !monster.isLocked)),
              ),
            ],
          ),
          body: Column(
            children: [
              _buildHeader(monster),
              TabBar(
                controller: _tabController,
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: 'ステータス'),
                  Tab(text: '技'),
                  Tab(text: '特性'),
                ],
              ),
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

  Widget _buildHeader(Monster monster) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_getElementColor(monster.element), _getElementColor(monster.element).withOpacity(0.6)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
            child: Icon(_getSpeciesIcon(monster.species), size: 50, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(monster.monsterName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Row(children: [
                  _buildBadge('Lv.${monster.level}'),
                  const SizedBox(width: 8),
                  _buildBadge(monster.rarityStars),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  _buildBadge(monster.speciesName),
                  const SizedBox(width: 8),
                  _buildBadge(monster.elementName),
                ]),
                const SizedBox(height: 8),
                Text('HP: ${monster.currentHp}/${monster.maxHp}', style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatusTab(Monster monster) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (monster.level >= 50)
            SwitchListTile(
              title: const Text('PvP時(Lv50)'),
              value: _showPvPStats,
              onChanged: (v) => setState(() => _showPvPStats = v),
            ),
          _buildStatsCard(monster),
          const SizedBox(height: 16),
          _buildPointsCard(monster),
        ],
      ),
    );
  }

  Widget _buildStatsCard(Monster monster) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_showPvPStats ? 'PvP時(Lv50)' : '現在', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildStatBar('HP', _showPvPStats ? monster.lv50MaxHp : monster.maxHp, monster.ivHp),
            _buildStatBar('攻撃', _showPvPStats ? monster.lv50Attack : monster.attack, monster.ivAttack),
            _buildStatBar('防御', _showPvPStats ? monster.lv50Defense : monster.defense, monster.ivDefense),
            _buildStatBar('魔力', _showPvPStats ? monster.lv50Magic : monster.magic, monster.ivMagic),
            _buildStatBar('素早さ', _showPvPStats ? monster.lv50Speed : monster.speed, monster.ivSpeed),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBar(String label, int value, int iv) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 50, child: Text(label, style: const TextStyle(fontSize: 12))),
          Expanded(child: LinearProgressIndicator(value: value / 500, minHeight: 12)),
          const SizedBox(width: 8),
          SizedBox(width: 40, child: Text('$value', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(width: 8),
          SizedBox(
            width: 35,
            child: Text('${iv >= 0 ? '+' : ''}$iv', style: TextStyle(fontSize: 10, color: iv >= 0 ? Colors.green : Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsCard(Monster monster) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ポイント振り分け', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('残り: ${monster.remainingPoints}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            _buildPointRow(monster, 'hp', 'HP', monster.pointHp),
            _buildPointRow(monster, 'attack', '攻撃', monster.pointAttack),
            _buildPointRow(monster, 'defense', '防御', monster.pointDefense),
            _buildPointRow(monster, 'magic', '魔力', monster.pointMagic),
            _buildPointRow(monster, 'speed', '素早さ', monster.pointSpeed),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showResetDialog(monster),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('リセット'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointRow(Monster monster, String statType, String label, int current) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 50, child: Text(label)),
          Text('+$current', style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: current > 0
                ? () => context.read<MonsterBloc>().add(AllocatePoints(monsterId: monster.id, statType: statType, amount: -1))
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: monster.remainingPoints > 0
                ? () => context.read<MonsterBloc>().add(AllocatePoints(monsterId: monster.id, statType: statType, amount: 1))
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: monster.remainingPoints >= 10
                ? () => context.read<MonsterBloc>().add(AllocatePoints(monsterId: monster.id, statType: statType, amount: 10))
                : null,
          ),
        ],
      ),
    );
  }

  void _showResetDialog(Monster monster) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ポイントリセット'),
        content: const Text('振り分けたポイントをリセットしますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<MonsterBloc>().add(ResetPoints(monsterId: monster.id));
            },
            child: const Text('リセット'),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsTab(Monster monster) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ★修正: 装備中の技を常に表示
        const Text(
          '装備中の技（最大4個）',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        // 装備中の技リスト
        if (monster.equippedSkills.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                '技が装備されていません。\n下から技を選択して追加してください。',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...monster.equippedSkills.map((skillId) {
            final skill = _availableSkills.firstWhere(
              (s) => s['skill_id'] == skillId,
              orElse: () => {'name': skillId, 'cost': '?', 'power': '?'},
            );
            return Card(
              color: Colors.blue.shade50,
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bolt, color: Colors.white),
                ),
                title: Text(
                  skill['name'] as String? ?? skillId,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'コスト: ${skill['cost']} / 威力: ${skill['power']}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  tooltip: '装備解除',
                  onPressed: () {
                    final newSkills = List<String>.from(monster.equippedSkills)
                      ..remove(skillId);
                    context.read<MonsterBloc>().add(
                      UpdateEquippedSkills(
                        monsterId: monster.id,
                        skillIds: newSkills,
                      ),
                    );
                  },
                ),
              ),
            );
          }),
        
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        
        // ★修正: 常に「利用可能な技」セクションを表示
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '利用可能な技',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (monster.equippedSkills.length >= 4)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Text(
                  '装備枠が満杯です',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        // ★修正: 装備していない技を常に表示
        ..._availableSkills
            .where((s) => !monster.equippedSkills.contains(s['skill_id']))
            .map((skill) {
          final isMaxEquipped = monster.equippedSkills.length >= 4;
          
          return Card(
            color: isMaxEquipped ? Colors.grey.shade100 : null,
            child: ListTile(
              enabled: !isMaxEquipped,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isMaxEquipped ? Colors.grey : Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
              title: Text(
                skill['name'] as String? ?? '',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isMaxEquipped ? Colors.grey : Colors.black,
                ),
              ),
              subtitle: Text(
                'コスト: ${skill['cost']} / 威力: ${skill['power']}',
                style: TextStyle(
                  color: isMaxEquipped ? Colors.grey : Colors.black87,
                ),
              ),
              trailing: IconButton(
                icon: Icon(
                  Icons.add_circle,
                  color: isMaxEquipped ? Colors.grey : Colors.green,
                ),
                tooltip: isMaxEquipped ? '装備枠が満杯です' : '装備する',
                onPressed: isMaxEquipped
                    ? null
                    : () {
                        final newSkills = List<String>.from(monster.equippedSkills)
                          ..add(skill['skill_id'].toString());
                        context.read<MonsterBloc>().add(
                          UpdateEquippedSkills(
                            monsterId: monster.id,
                            skillIds: newSkills,
                          ),
                        );
                      },
              ),
            ),
          );
        }),
        
        // ヘルプテキスト
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'ヒント',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                '• 最大4つまで技を装備できます\n'
                '• バトルでは装備した技のみ使用可能です\n'
                '• 技の付け替えはいつでも可能です',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildTraitsTab(Monster monster) {
    final mainTraits = _availableTraits.where((t) => t['type'] == 'main').toList();
    final subTraits = _availableTraits.where((t) => t['type'] == 'sub').toList();
    final currentMainTrait = mainTraits.firstWhere((t) => t['trait_id'] == monster.mainTraitId, orElse: () => {'name': 'なし', 'description': ''});

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('メイン特性', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Card(
            child: ListTile(
              title: Text(currentMainTrait['name'] as String? ?? 'なし'),
              subtitle: Text(currentMainTrait['description'] as String? ?? ''),
            ),
          ),
          const SizedBox(height: 16),
          const Text('サブ特性一覧', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ...subTraits.map((trait) => Card(
                child: ListTile(
                  title: Text(trait['name'] as String? ?? ''),
                  subtitle: Text(trait['description'] as String? ?? ''),
                ),
              )),
        ],
      ),
    );
  }

  Color _getElementColor(String element) {
    switch (element) {
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

  IconData _getSpeciesIcon(String species) {
    switch (species) {
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