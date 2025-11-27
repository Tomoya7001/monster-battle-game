import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/monster.dart';
import '../../../domain/entities/equipment_master.dart';
import '../../../core/models/monster_filter.dart';
import '../../../core/services/monster_service.dart';
import '../../../data/repositories/equipment_repository.dart';
import '../../bloc/party/party_formation_bloc_v2.dart';
import '../../bloc/monster/monster_bloc.dart';
import '../../bloc/monster/monster_event.dart';
import '../../bloc/monster/monster_state.dart';
import '../../blocs/auth/auth_bloc.dart';

/// 新UI パーティ編成画面
class PartyFormationScreenV2 extends StatefulWidget {
  const PartyFormationScreenV2({Key? key}) : super(key: key);

  @override
  State<PartyFormationScreenV2> createState() => _PartyFormationScreenV2State();
}

class _PartyFormationScreenV2State extends State<PartyFormationScreenV2>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _userId;
  
  // 各タブのBlocを保持（タブ切り替え時のリロード防止）
  PartyFormationBlocV2? _pvpBloc;
  PartyFormationBlocV2? _adventureBloc;
  MonsterBloc? _monsterBloc;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authState = context.read<AuthBloc>().state;
    _userId = authState is Authenticated ? authState.userId : 'dev_user_12345';
    
    // Blocを一度だけ作成
    _pvpBloc ??= PartyFormationBlocV2(userId: _userId)
      ..add(const LoadPartyPresetsV2(battleType: 'pvp'));
    _adventureBloc ??= PartyFormationBlocV2(userId: _userId)
      ..add(const LoadPartyPresetsV2(battleType: 'adventure'));
    _monsterBloc ??= MonsterBloc();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pvpBloc?.close();
    _adventureBloc?.close();
    _monsterBloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('パーティ編成'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'PvP'),
            Tab(text: '冒険'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          MultiBlocProvider(
            providers: [
              BlocProvider.value(value: _pvpBloc!),
              BlocProvider.value(value: _monsterBloc!),
            ],
            child: _PartyFormationBody(battleType: 'pvp', userId: _userId),
          ),
          MultiBlocProvider(
            providers: [
              BlocProvider.value(value: _adventureBloc!),
              BlocProvider.value(value: _monsterBloc!),
            ],
            child: _PartyFormationBody(battleType: 'adventure', userId: _userId),
          ),
        ],
      ),
    );
  }
}

class _PartyFormationBody extends StatefulWidget {
  final String battleType;
  final String userId;
  const _PartyFormationBody({required this.battleType, required this.userId});

  @override
  State<_PartyFormationBody> createState() => _PartyFormationBodyState();
}

class _PartyFormationBodyState extends State<_PartyFormationBody>
    with AutomaticKeepAliveClientMixin {
  final EquipmentRepository _equipmentRepository = EquipmentRepository();
  final MonsterService _monsterService = MonsterService();
  Map<String, EquipmentMaster> _equipmentMasters = {};
  Set<String> _partyEquippedIds = {};
  int _selectedSlotIndex = 0;
  bool _isEquipping = false;
  bool _favoriteOnly = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadMasterData();
  }

  Future<void> _loadMasterData() async {
    final equipments = await _equipmentRepository.getEquipmentMasters();
    if (mounted) {
      setState(() => _equipmentMasters = equipments);
    }
  }

  void _updatePartyEquippedIds(List<Monster> selectedMonsters, String? excludeMonsterId) {
    final Set<String> equippedIds = {};
    for (final monster in selectedMonsters) {
      if (monster.id != excludeMonsterId) {
        equippedIds.addAll(monster.equippedEquipment);
      }
    }
    _partyEquippedIds = equippedIds;
  }

  Color get _themeColor => widget.battleType == 'pvp'
      ? const Color(0xFFE53935)
      : const Color(0xFF43A047);

  Color get _themeLightColor => widget.battleType == 'pvp'
      ? const Color(0xFFFFEBEE)
      : const Color(0xFFE8F5E9);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocConsumer<PartyFormationBlocV2, PartyFormationStateV2>(
      listener: (context, state) {
        if (state is PartyFormationErrorV2) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
        if (state is PartyFormationLoadedV2) {
          _updatePartyEquippedIds(
            state.selectedMonsters,
            state.selectedMonsters.isNotEmpty && _selectedSlotIndex < state.selectedMonsters.length
                ? state.selectedMonsters[_selectedSlotIndex].id
                : null,
          );
        }
      },
      builder: (context, state) {
        if (state is PartyFormationLoadingV2) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is PartyFormationLoadedV2) {
          if (_selectedSlotIndex >= state.selectedMonsters.length && state.selectedMonsters.isNotEmpty) {
            _selectedSlotIndex = 0;
          }
          return _buildContent(context, state);
        }
        return const Center(child: Text('読み込み中...'));
      },
    );
  }

  Widget _buildContent(BuildContext context, PartyFormationLoadedV2 state) {
    return Column(
      children: [
        _buildPresetBar(context, state),
        _buildPartySlots(context, state),
        if (state.selectedMonsters.isNotEmpty)
          _buildCompactDetailPanel(context, state),
        Expanded(child: _buildMonsterSelector(context, state)),
      ],
    );
  }

  Widget _buildPresetBar(BuildContext context, PartyFormationLoadedV2 state) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 2)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(5, (index) {
          final presetNumber = index + 1;
          final isSelected = state.currentPresetNumber == presetNumber;
          final monsterCount = state.getMonsterCountForPreset(presetNumber);

          return GestureDetector(
            onTap: () {
              setState(() => _selectedSlotIndex = 0);
              context.read<PartyFormationBlocV2>().add(SelectPresetV2(presetNumber: presetNumber));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 50,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(colors: [_themeColor, _themeColor.withOpacity(0.7)])
                    : null,
                color: isSelected ? null : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$presetNumber', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey[600])),
                  Text('$monsterCount/5', style: TextStyle(fontSize: 8, color: isSelected ? Colors.white70 : Colors.grey[500])),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPartySlots(BuildContext context, PartyFormationLoadedV2 state) {
    return Container(
      margin: const EdgeInsets.fromLTRB(6, 4, 6, 2),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 2)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(widget.battleType == 'pvp' ? Icons.sports_kabaddi : Icons.explore, color: _themeColor, size: 12),
              const SizedBox(width: 3),
              Text(widget.battleType == 'pvp' ? 'PvP' : '冒険', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: _themeLightColor, borderRadius: BorderRadius.circular(6)),
                child: Text('${state.selectedMonsters.length}/5', style: TextStyle(color: _themeColor, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
              if (state.selectedMonsters.isNotEmpty) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    setState(() => _selectedSlotIndex = 0);
                    context.read<PartyFormationBlocV2>().add(const ClearSelectionV2());
                  },
                  child: Text('クリア', style: TextStyle(color: Colors.grey[500], fontSize: 9)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(5, (index) {
              final monster = index < state.selectedMonsters.length ? state.selectedMonsters[index] : null;
              final isSelected = index == _selectedSlotIndex && monster != null;

              return Expanded(
                child: GestureDetector(
                  onTap: monster != null
                      ? () {
                          setState(() {
                            _selectedSlotIndex = index;
                            _updatePartyEquippedIds(state.selectedMonsters, monster.id);
                          });
                        }
                      : null,
                  child: _buildSlotCard(monster: monster, index: index, isLeader: widget.battleType == 'adventure' && index == 0, isSelected: isSelected, onRemove: monster != null ? () {
                    if (_selectedSlotIndex >= state.selectedMonsters.length - 1 && _selectedSlotIndex > 0) {
                      setState(() => _selectedSlotIndex--);
                    }
                    context.read<PartyFormationBlocV2>().add(RemoveMonsterV2(monsterId: monster.id));
                  } : null),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotCard({required Monster? monster, required int index, required bool isLeader, required bool isSelected, VoidCallback? onRemove}) {
    if (monster == null) {
      return Container(
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(5), border: Border.all(color: Colors.grey[300]!)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.add, size: 14, color: Colors.grey[400]),
          Text('空き', style: TextStyle(color: Colors.grey[400], fontSize: 7)),
        ]),
      );
    }

    final equipCount = monster.equippedEquipment.length;
    final maxSlots = monster.species.toLowerCase() == 'human' ? 2 : 1;

    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_getRarityColor(monster.rarity), _getRarityColor(monster.rarity).withOpacity(0.7)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        borderRadius: BorderRadius.circular(5),
        border: isSelected ? Border.all(color: _themeColor, width: 2) : null,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(2),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 18, height: 18, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: Icon(_getSpeciesIcon(monster.species), color: Colors.white, size: 10)),
              const SizedBox(height: 1),
              Text(monster.monsterName.length > 3 ? '${monster.monsterName.substring(0, 3)}…' : monster.monsterName, style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('Lv${monster.level}', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 6)),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(maxSlots, (i) => Container(width: 6, height: 6, margin: const EdgeInsets.symmetric(horizontal: 1), decoration: BoxDecoration(color: i < equipCount ? Colors.amber : Colors.white.withOpacity(0.3), shape: BoxShape.circle)))),
            ]),
          ),
          if (onRemove != null)
            Positioned(top: 0, right: 0, child: GestureDetector(onTap: onRemove, child: Container(padding: const EdgeInsets.all(1), decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle), child: const Icon(Icons.close, size: 7, color: Colors.white)))),
          if (isLeader)
            Positioned(bottom: 0, left: 0, child: Container(padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1), decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(2)), child: const Text('先頭', style: TextStyle(color: Colors.black87, fontSize: 5, fontWeight: FontWeight.bold)))),
        ],
      ),
    );
  }

  /// コンパクト詳細パネル
  Widget _buildCompactDetailPanel(BuildContext context, PartyFormationLoadedV2 state) {
    if (state.selectedMonsters.isEmpty || _selectedSlotIndex >= state.selectedMonsters.length) return const SizedBox.shrink();

    final monster = state.selectedMonsters[_selectedSlotIndex];
    final maxSlots = monster.species.toLowerCase() == 'human' ? 2 : 1;
    final equippedIds = monster.equippedEquipment;

    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _themeColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // 左: モンスター情報
          Expanded(
            child: Row(
              children: [
                // レアリティ＋名前＋レベル
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                          decoration: BoxDecoration(color: _getRarityColor(monster.rarity), borderRadius: BorderRadius.circular(2)),
                          child: Text('★${monster.rarity}', style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 4),
                        Text(monster.monsterName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 3),
                        Text('Lv.${monster.level}', style: TextStyle(fontSize: 9, color: Colors.grey[600])),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // 種族・属性・HP
                    Row(
                      children: [
                        Icon(_getSpeciesIcon(monster.species), size: 10, color: Colors.grey[600]),
                        const SizedBox(width: 2),
                        Text(monster.speciesName, style: TextStyle(fontSize: 8, color: Colors.grey[600])),
                        const SizedBox(width: 6),
                        Icon(Icons.auto_awesome, size: 10, color: _getElementColor(monster.element)),
                        const SizedBox(width: 2),
                        Text(monster.elementName, style: TextStyle(fontSize: 8, color: Colors.grey[600])),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 50,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: monster.currentHp / monster.maxHp,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(monster.hpPercentage > 0.5 ? Colors.green : (monster.hpPercentage > 0.2 ? Colors.orange : Colors.red)),
                              minHeight: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text('${monster.currentHp}/${monster.maxHp}', style: const TextStyle(fontSize: 7)),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                // ステータス
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                  child: Row(
                    children: [
                      _buildMiniStat('攻', monster.attack),
                      _buildMiniStat('防', monster.defense),
                      _buildMiniStat('魔', monster.magic),
                      _buildMiniStat('速', monster.speed),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 右: 装備スロット（正方形）
          Row(
            children: List.generate(maxSlots, (slotIndex) {
              final equipmentId = slotIndex < equippedIds.length ? equippedIds[slotIndex] : null;
              final equipment = equipmentId != null ? _equipmentMasters[equipmentId] : null;

              return GestureDetector(
                onTap: () => _showEquipmentSelectDialog(monster, slotIndex, state),
                child: Container(
                  width: 40,
                  height: 40,
                  margin: EdgeInsets.only(left: slotIndex > 0 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: equipment != null ? Colors.white : Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: equipment?.rarityColor ?? Colors.grey[300]!, width: equipment != null ? 2 : 1),
                  ),
                  child: equipment != null
                      ? Stack(
                          children: [
                            Center(child: Icon(equipment.categoryIcon, size: 18, color: equipment.rarityColor)),
                            Positioned(top: 1, right: 1, child: GestureDetector(
                              onTap: () => _unequipEquipment(monster, equipmentId!),
                              child: Container(padding: const EdgeInsets.all(1), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, size: 8, color: Colors.white)),
                            )),
                            Positioned(bottom: 1, left: 0, right: 0, child: Text(equipment.name, style: const TextStyle(fontSize: 5), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ],
                        )
                      : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add, size: 14, color: Colors.grey[400]),
                          Text('装備', style: TextStyle(fontSize: 6, color: Colors.grey[400])),
                        ]),
                ),
              );
            }),
          ),
          if (_isEquipping)
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(left: 4),
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 7, color: Colors.grey[600])),
          Text('$value', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showEquipmentSelectDialog(Monster monster, int slotIndex, PartyFormationLoadedV2 state) {
    _updatePartyEquippedIds(state.selectedMonsters, monster.id);

    final equippable = _equipmentMasters.values.where((eq) {
      return eq.canEquip(species: monster.species, element: monster.element, monsterRarity: monster.rarity)
          && !monster.equippedEquipment.contains(eq.equipmentId)
          && !_partyEquippedIds.contains(eq.equipmentId);
    }).toList()..sort((a, b) => b.rarity.compareTo(a.rarity));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
        child: Column(
          children: [
            Container(margin: const EdgeInsets.only(top: 6), width: 28, height: 3, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Padding(padding: const EdgeInsets.all(8), child: Text('装備を選択', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            Expanded(
              child: equippable.isEmpty
                  ? Center(child: Text('装備可能な装備がありません', style: TextStyle(color: Colors.grey[500], fontSize: 11)))
                  : ListView.builder(
                      itemCount: equippable.length,
                      itemBuilder: (context, index) {
                        final eq = equippable[index];
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          leading: Container(width: 28, height: 28, decoration: BoxDecoration(color: eq.rarityColor.withOpacity(0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: eq.rarityColor)), child: Icon(eq.categoryIcon, size: 14, color: eq.rarityColor)),
                          title: Text(eq.name, style: const TextStyle(fontSize: 11)),
                          subtitle: Text(eq.effectsText, style: const TextStyle(fontSize: 8), maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: Text(eq.rarityStars, style: TextStyle(color: eq.rarityColor, fontSize: 9)),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            _equipEquipment(monster, eq.equipmentId, slotIndex);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _equipEquipment(Monster monster, String equipmentId, int slot) async {
    setState(() => _isEquipping = true);

    final newEquipment = List<String>.from(monster.equippedEquipment);
    if (slot < newEquipment.length) {
      newEquipment[slot] = equipmentId;
    } else {
      newEquipment.add(equipmentId);
    }

    context.read<MonsterBloc>().add(UpdateEquippedEquipment(monsterId: monster.id, equipmentIds: newEquipment));

    // 非同期で更新を待機
    await Future.delayed(const Duration(milliseconds: 200));
    
    // 画面全体をリロードせず、パーティデータのみ更新
    context.read<PartyFormationBlocV2>().add(LoadPartyPresetsV2(battleType: widget.battleType));
    
    if (mounted) setState(() => _isEquipping = false);
  }

  Future<void> _unequipEquipment(Monster monster, String equipmentId) async {
    setState(() => _isEquipping = true);

    final newEquipment = List<String>.from(monster.equippedEquipment)..remove(equipmentId);
    context.read<MonsterBloc>().add(UpdateEquippedEquipment(monsterId: monster.id, equipmentIds: newEquipment));

    await Future.delayed(const Duration(milliseconds: 200));
    context.read<PartyFormationBlocV2>().add(LoadPartyPresetsV2(battleType: widget.battleType));
    
    if (mounted) setState(() => _isEquipping = false);
  }

  Widget _buildMonsterSelector(BuildContext context, PartyFormationLoadedV2 state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 2, offset: const Offset(0, -1))],
      ),
      child: Column(
        children: [
          Container(margin: const EdgeInsets.only(top: 4), width: 24, height: 3, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            child: Row(
              children: [
                const Text('モンスター選択', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                const Spacer(),
                // お気に入りフィルター
                GestureDetector(
                  onTap: () => setState(() => _favoriteOnly = !_favoriteOnly),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: _favoriteOnly ? Colors.amber : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 10, color: _favoriteOnly ? Colors.white : Colors.grey[600]),
                        const SizedBox(width: 2),
                        Text('お気に入り', style: TextStyle(fontSize: 8, color: _favoriteOnly ? Colors.white : Colors.grey[600])),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                _buildFilterButton(context, state),
                const SizedBox(width: 4),
                _buildSortButton(context, state),
              ],
            ),
          ),
          Expanded(child: _buildMonsterGrid(context, state)),
        ],
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context, PartyFormationLoadedV2 state) {
    final hasFilter = state.filter.species != null || state.filter.element != null || state.filter.rarity != null;
    return GestureDetector(
      onTap: () => _showFilterSheet(context, state),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(color: hasFilter ? _themeColor : Colors.grey[200], borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.filter_list, size: 10, color: hasFilter ? Colors.white : Colors.grey[600]),
          const SizedBox(width: 2),
          Text('フィルター', style: TextStyle(fontSize: 8, color: hasFilter ? Colors.white : Colors.grey[600])),
        ]),
      ),
    );
  }

  Widget _buildSortButton(BuildContext context, PartyFormationLoadedV2 state) {
    return GestureDetector(
      onTap: () => _showSortSheet(context, state),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.sort, size: 10, color: Colors.grey[600]),
          const SizedBox(width: 2),
          Text('ソート', style: TextStyle(fontSize: 8, color: Colors.grey[600])),
        ]),
      ),
    );
  }

  Widget _buildMonsterGrid(BuildContext context, PartyFormationLoadedV2 state) {
    final monsters = _applyFilterAndSort(state);
    final selectedIds = state.selectedMonsters.map((m) => m.id).toSet();

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 3, mainAxisSpacing: 3, childAspectRatio: 0.78),
      itemCount: monsters.length,
      itemBuilder: (context, index) {
        final monster = monsters[index];
        final isSelected = selectedIds.contains(monster.id);
        final isDuplicate = widget.battleType == 'pvp' && state.selectedMonsters.any((m) => m.monsterId == monster.monsterId && m.id != monster.id);
        final canSelect = state.selectedMonsters.length < 5 && !isSelected && !isDuplicate;

        return _buildMonsterCard(monster: monster, isSelected: isSelected, isDuplicate: isDuplicate, canSelect: canSelect, onTap: canSelect ? () => context.read<PartyFormationBlocV2>().add(SelectMonsterV2(monster: monster)) : null);
      },
    );
  }

  Widget _buildMonsterCard({required Monster monster, required bool isSelected, required bool isDuplicate, required bool canSelect, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? _themeColor.withOpacity(0.15) : (isDuplicate ? Colors.grey[200] : Colors.white),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: isSelected ? _themeColor : Colors.grey[300]!, width: isSelected ? 1.5 : 1),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(2),
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1), decoration: BoxDecoration(color: _getRarityColor(monster.rarity), borderRadius: BorderRadius.circular(2)), child: Text('★${monster.rarity}', style: const TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.bold))),
                    if (monster.isFavorite) const Icon(Icons.star, size: 8, color: Colors.amber),
                  ],
                ),
                const Spacer(),
                Icon(_getSpeciesIcon(monster.species), size: 16, color: isDuplicate ? Colors.grey : _getElementColor(monster.element)),
                const SizedBox(height: 1),
                Text(monster.monsterName, style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: isDuplicate ? Colors.grey : Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                Text('Lv${monster.level}', style: TextStyle(fontSize: 6, color: isDuplicate ? Colors.grey : Colors.grey[600])),
                const Spacer(),
              ]),
            ),
            if (isSelected)
              Positioned(top: 1, right: 1, child: Container(padding: const EdgeInsets.all(1), decoration: BoxDecoration(color: _themeColor, shape: BoxShape.circle), child: const Icon(Icons.check, size: 6, color: Colors.white))),
            if (isDuplicate)
              Positioned.fill(child: Container(decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(5)), child: const Center(child: Text('選択済', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold))))),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context, PartyFormationLoadedV2 state) {
    final bloc = context.read<PartyFormationBlocV2>();
    String? selectedSpecies = state.filter.species;
    String? selectedElement = state.filter.element;
    int? selectedRarity = state.filter.rarity;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (builderContext, setState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.45,
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
            child: Column(
              children: [
                Container(margin: const EdgeInsets.only(top: 6), width: 24, height: 3, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('フィルター', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    TextButton(onPressed: () { bloc.add(const ChangeFilterV2(filter: MonsterFilter())); Navigator.pop(sheetContext); }, child: const Text('クリア', style: TextStyle(fontSize: 10))),
                  ]),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('種族', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                      const SizedBox(height: 4),
                      Wrap(spacing: 4, runSpacing: 4, children: [
                        _buildFilterChip('全て', selectedSpecies == null, () => setState(() => selectedSpecies = null)),
                        ...['angel', 'demon', 'human', 'spirit', 'mechanoid', 'dragon', 'mutant'].map((s) => _buildFilterChip(s, selectedSpecies == s, () => setState(() => selectedSpecies = s))),
                      ]),
                      const SizedBox(height: 8),
                      const Text('属性', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                      const SizedBox(height: 4),
                      Wrap(spacing: 4, runSpacing: 4, children: [
                        _buildFilterChip('全て', selectedElement == null, () => setState(() => selectedElement = null)),
                        ...['fire', 'water', 'thunder', 'wind', 'earth', 'light', 'dark'].map((e) => _buildFilterChip(e, selectedElement == e, () => setState(() => selectedElement = e))),
                      ]),
                      const SizedBox(height: 8),
                      const Text('レアリティ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                      const SizedBox(height: 4),
                      Wrap(spacing: 4, runSpacing: 4, children: [
                        _buildFilterChip('全て', selectedRarity == null, () => setState(() => selectedRarity = null)),
                        ...[2, 3, 4, 5].map((r) => _buildFilterChip('★$r', selectedRarity == r, () => setState(() => selectedRarity = r))),
                      ]),
                    ]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: SizedBox(width: double.infinity, height: 32, child: ElevatedButton(onPressed: () { bloc.add(ChangeFilterV2(filter: MonsterFilter(species: selectedSpecies, element: selectedElement, rarity: selectedRarity))); Navigator.pop(sheetContext); }, style: ElevatedButton.styleFrom(backgroundColor: _themeColor), child: const Text('適用', style: TextStyle(fontSize: 11)))),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(color: isSelected ? _themeColor : Colors.grey[200], borderRadius: BorderRadius.circular(10)),
        child: Text(label, style: TextStyle(fontSize: 9, color: isSelected ? Colors.white : Colors.grey[700], fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  void _showSortSheet(BuildContext context, PartyFormationLoadedV2 state) {
    final bloc = context.read<PartyFormationBlocV2>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(margin: const EdgeInsets.only(top: 6), width: 24, height: 3, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const Padding(padding: EdgeInsets.all(8), child: Text('ソート', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
          ...MonsterSortType.values.take(6).map((sortType) => ListTile(dense: true, visualDensity: VisualDensity.compact, leading: Icon(state.sortType == sortType ? Icons.check : Icons.sort, color: state.sortType == sortType ? _themeColor : Colors.grey, size: 14), title: Text(sortType.displayName, style: const TextStyle(fontSize: 11)), onTap: () { bloc.add(ChangeSortTypeV2(sortType: sortType)); Navigator.pop(sheetContext); })),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  List<Monster> _applyFilterAndSort(PartyFormationLoadedV2 state) {
    var monsters = List<Monster>.from(state.allMonsters);
    
    // お気に入りフィルター
    if (_favoriteOnly) {
      monsters = monsters.where((m) => m.isFavorite).toList();
    }
    
    if (state.filter.species != null) monsters = monsters.where((m) => m.species.toLowerCase() == state.filter.species!.toLowerCase()).toList();
    if (state.filter.element != null) monsters = monsters.where((m) => m.element.toLowerCase() == state.filter.element!.toLowerCase()).toList();
    if (state.filter.rarity != null) monsters = monsters.where((m) => m.rarity == state.filter.rarity).toList();

    switch (state.sortType) {
      case MonsterSortType.levelDesc: monsters.sort((a, b) => b.level.compareTo(a.level)); break;
      case MonsterSortType.levelAsc: monsters.sort((a, b) => a.level.compareTo(b.level)); break;
      case MonsterSortType.rarityDesc: monsters.sort((a, b) => b.rarity.compareTo(a.rarity)); break;
      case MonsterSortType.rarityAsc: monsters.sort((a, b) => a.rarity.compareTo(b.rarity)); break;
      case MonsterSortType.hpDesc: monsters.sort((a, b) => b.currentHp.compareTo(a.currentHp)); break;
      case MonsterSortType.hpAsc: monsters.sort((a, b) => a.currentHp.compareTo(b.currentHp)); break;
      case MonsterSortType.favoriteFirst: monsters.sort((a, b) { if (a.isFavorite && !b.isFavorite) return -1; if (!a.isFavorite && b.isFavorite) return 1; return b.level.compareTo(a.level); }); break;
      default: monsters.sort((a, b) => b.level.compareTo(a.level));
    }
    return monsters;
  }

  Color _getRarityColor(int rarity) => switch (rarity) { 2 => Colors.grey, 3 => Colors.blue, 4 => Colors.purple, 5 => Colors.orange, _ => Colors.grey };
  Color _getElementColor(String element) => switch (element) { 'fire' => Colors.deepOrange, 'water' => Colors.blue, 'thunder' => Colors.amber, 'wind' => Colors.green, 'earth' => Colors.brown, 'light' => Colors.yellow[700]!, 'dark' => Colors.purple, _ => Colors.grey };
  IconData _getSpeciesIcon(String species) => switch (species) { 'angel' => Icons.auto_awesome, 'demon' => Icons.pest_control, 'human' => Icons.person, 'spirit' => Icons.cloud, 'mechanoid' => Icons.precision_manufacturing, 'dragon' => Icons.castle, 'mutant' => Icons.psychology, _ => Icons.pets };
}