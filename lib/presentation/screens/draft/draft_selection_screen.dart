import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/draft/draft_bloc.dart';
import '../../bloc/draft/draft_event.dart';
import '../../bloc/draft/draft_state.dart';
import '../../../domain/entities/monster.dart';
import '../../bloc/battle/battle_bloc.dart';
import '../../bloc/battle/battle_event.dart';
import '../../bloc/battle/battle_state.dart';
import '../../widgets/battle/battle_content_widget.dart';
import '../../widgets/battle/battle_effect_widgets.dart';
import '../battle/battle_result_screen.dart';
import '../battle/pvp_matching_screen.dart';

class DraftSelectionScreen extends StatelessWidget {
  const DraftSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DraftBloc()..add(const StartDraftMatching()),
      child: const _DraftSelectionContent(),
    );
  }
}

class _DraftSelectionContent extends StatelessWidget {
  const _DraftSelectionContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ドラフトバトル'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showCancelDialog(context),
        ),
      ),
      body: BlocConsumer<DraftBloc, DraftBlocState>(
        listener: (context, state) {
          if (state is DraftReady) {
            _navigateToBattle(context, state);
          } else if (state is DraftCancelled) {
            Navigator.of(context).pop();
          } else if (state is DraftErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is DraftMatching) {
            return _buildMatchingView(state);
          }

          if (state is DraftSelecting) {
            return _buildSelectionView(context, state.draftState);
          }

          if (state is DraftWaitingOpponent) {
            return _WaitingOpponentView(draftState: state.draftState);
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildMatchingView(DraftMatching state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          const Text('対戦相手を探しています...', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            '${state.waitSeconds}秒',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionView(BuildContext context, DraftStateModel draftState) {
    return Column(
      children: [
        _buildHeader(context, draftState),
        Expanded(
          child: _build25MonsterGrid(context, draftState),
        ),
        _buildFooter(context, draftState),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, DraftStateModel draftState) {
    final remainingColor = draftState.remainingSeconds <= 10
        ? Colors.red
        : (draftState.remainingSeconds <= 30 ? Colors.orange : Colors.green);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.grey.shade100,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.timer, color: remainingColor, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${draftState.remainingSeconds}秒',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: remainingColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: draftState.canConfirm ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${draftState.selectedMonsters.length}/5',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: draftState.remainingSeconds / 60.0,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(remainingColor),
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  Widget _build25MonsterGrid(BuildContext context, DraftStateModel draftState) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final availableWidth = constraints.maxWidth;
        
        final cellWidth = (availableWidth - 24) / 5;
        final cellHeight = (availableHeight - 24) / 5;
        final cellSize = cellWidth < cellHeight ? cellWidth : cellHeight;

        return Center(
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: draftState.pool.map((monster) {
                final isSelected = draftState.selectedIds.contains(monster.monsterId);
                final canSelect = !isSelected && draftState.canSelect;

                return SizedBox(
                  width: cellSize - 4,
                  height: cellSize - 4,
                  child: _MiniMonsterCard(
                    monster: monster,
                    isSelected: isSelected,
                    canSelect: canSelect,
                    onTap: () {
                      context.read<DraftBloc>().add(
                            ToggleMonsterSelection(monsterId: monster.monsterId),
                          );
                    },
                    onLongPress: () => _showMonsterDetail(context, monster),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context, DraftStateModel draftState) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (draftState.selectedMonsters.isNotEmpty)
              SizedBox(
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...draftState.selectedMonsters.map((m) => Container(
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: _getElementColor(m.element),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              m.name.isNotEmpty ? m.name.substring(0, 1) : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )),
                    ...List.generate(5 - draftState.selectedMonsters.length, (i) {
                      return Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade400, width: 1),
                        ),
                        child: const Icon(Icons.add, size: 16, color: Colors.grey),
                      );
                    }),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: draftState.canConfirm
                    ? () => context.read<DraftBloc>().add(const ConfirmSelection())
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  draftState.canConfirm ? '選択確定' : 'あと${5 - draftState.selectedMonsters.length}体選択',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('キャンセル'),
        content: const Text('ドラフトバトルをキャンセルしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('いいえ'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<DraftBloc>().add(const CancelDraftMatching());
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('はい'),
          ),
        ],
      ),
    );
  }

  void _showMonsterDetail(BuildContext context, DraftMonster monster) {
    showDialog(
      context: context,
      builder: (ctx) => _MonsterDetailDialog(monster: monster),
    );
  }

  void _navigateToBattle(BuildContext context, DraftReady state) {
    final bloc = context.read<DraftBloc>();
    final playerParty = bloc.getPlayerPartyAsMonsters();
    final cpuParty = bloc.getCpuPartyAsMonsters();

    // ★修正: pushでバトル画面に遷移
    // 結果画面からはpopUntilでバトル選択画面まで一気に戻る
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => _DraftBattleScreen(
          playerParty: playerParty,
          enemyParty: cpuParty,
          battleId: state.battleId,
          isCpuOpponent: state.isCpuOpponent,
        ),
      ),
    );
  }

  Color _getElementColor(String element) {
    switch (element.toLowerCase()) {
      case 'fire': return Colors.deepOrange;
      case 'water': return Colors.blue;
      case 'thunder': return Colors.amber.shade700;
      case 'wind': return Colors.green;
      case 'earth': return Colors.brown;
      case 'light': return Colors.yellow.shade700;
      case 'dark': return Colors.purple.shade700;
      default: return Colors.grey;
    }
  }
}

// ============================================
// ミニモンスターカード（5x5グリッド用）
// ============================================

class _MiniMonsterCard extends StatelessWidget {
  final DraftMonster monster;
  final bool isSelected;
  final bool canSelect;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _MiniMonsterCard({
    Key? key,
    required this.monster,
    required this.isSelected,
    required this.canSelect,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: _getElementColor(monster.element),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: _getElementColor(monster.element).withOpacity(0.2),
                        child: Text(
                          monster.name.isNotEmpty ? monster.name.substring(0, 1) : '?',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getElementColor(monster.element),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          monster.name.length > 4 ? monster.name.substring(0, 4) : monster.name,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Text(
                        '★' * monster.rarity,
                        style: const TextStyle(color: Colors.orange, fontSize: 8),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: 6,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(1),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 10, color: Colors.white),
                ),
              ),
            if (!canSelect && !isSelected)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getElementColor(String element) {
    switch (element.toLowerCase()) {
      case 'fire': return Colors.deepOrange;
      case 'water': return Colors.blue;
      case 'thunder': return Colors.amber.shade700;
      case 'wind': return Colors.green;
      case 'earth': return Colors.brown;
      case 'light': return Colors.yellow.shade700;
      case 'dark': return Colors.purple.shade700;
      default: return Colors.grey;
    }
  }
}

// ============================================
// 待機画面（パーティ編成風）
// ============================================

class _WaitingOpponentView extends StatefulWidget {
  final DraftStateModel draftState;

  const _WaitingOpponentView({Key? key, required this.draftState}) : super(key: key);

  @override
  State<_WaitingOpponentView> createState() => _WaitingOpponentViewState();
}

class _WaitingOpponentViewState extends State<_WaitingOpponentView> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final selectedMonsters = widget.draftState.selectedMonsters;
    if (selectedMonsters.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final selectedMonster = selectedMonsters[_selectedIndex];

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 12),
              Text('相手の選択を待っています...', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
        
        // パーティ横並び
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(selectedMonsters.length, (index) {
              final monster = selectedMonsters[index];
              final isActive = index == _selectedIndex;

              return GestureDetector(
                onTap: () => setState(() => _selectedIndex = index),
                child: Container(
                  width: 56,
                  height: 56,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? _getElementColor(monster.element)
                        : _getElementColor(monster.element).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: _getElementColor(monster.element).withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        monster.name.isNotEmpty ? monster.name.substring(0, 1) : '?',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isActive ? 20 : 16,
                        ),
                      ),
                      Text(
                        '★' * monster.rarity,
                        style: TextStyle(color: Colors.white, fontSize: isActive ? 8 : 6),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),

        // 詳細表示
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildMonsterDetail(selectedMonster),
          ),
        ),
      ],
    );
  }

  Widget _buildMonsterDetail(DraftMonster monster) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ヘッダー
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getElementColor(monster.element),
                _getElementColor(monster.element).withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white,
                child: Text(
                  monster.name.isNotEmpty ? monster.name.substring(0, 1) : '?',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _getElementColor(monster.element),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      monster.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getElementName(monster.element),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '★' * monster.rarity,
                          style: const TextStyle(color: Colors.amber, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ステータス
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Lv50 ステータス', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Divider(),
                _buildStatBar('HP', monster.lv50Hp, 250, Colors.green),
                _buildStatBar('攻撃', monster.lv50Attack, 150, Colors.red),
                _buildStatBar('防御', monster.lv50Defense, 150, Colors.blue),
                _buildStatBar('魔力', monster.lv50Magic, 150, Colors.purple),
                _buildStatBar('素早さ', monster.lv50Speed, 150, Colors.orange),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 技
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('技', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Divider(),
                if (monster.skills.isEmpty)
                  const Text('技情報なし', style: TextStyle(color: Colors.grey))
                else
                  ...monster.skills.map((skill) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getElementColor(skill.element),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'C${skill.cost}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(skill.name, style: const TextStyle(fontSize: 14))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getElementColor(skill.element).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getElementName(skill.element),
                                style: TextStyle(fontSize: 10, color: _getElementColor(skill.element)),
                              ),
                            ),
                          ],
                        ),
                      )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatBar(String label, int value, int maxValue, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 50, child: Text(label, style: const TextStyle(fontSize: 13))),
          Expanded(
            child: AnimatedHpBar(
              currentHp: value,
              maxHp: maxValue,
              height: 14,
              showValue: false,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text('$value', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Color _getElementColor(String element) {
    switch (element.toLowerCase()) {
      case 'fire': return Colors.deepOrange;
      case 'water': return Colors.blue;
      case 'thunder': return Colors.amber.shade700;
      case 'wind': return Colors.green;
      case 'earth': return Colors.brown;
      case 'light': return Colors.yellow.shade700;
      case 'dark': return Colors.purple.shade700;
      default: return Colors.grey;
    }
  }

  String _getElementName(String element) {
    switch (element.toLowerCase()) {
      case 'fire': return '炎';
      case 'water': return '水';
      case 'thunder': return '雷';
      case 'wind': return '風';
      case 'earth': return '地';
      case 'light': return '光';
      case 'dark': return '闇';
      default: return '無';
    }
  }
}

// ============================================
// モンスター詳細ダイアログ
// ============================================

class _MonsterDetailDialog extends StatelessWidget {
  final DraftMonster monster;

  const _MonsterDetailDialog({Key? key, required this.monster}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getElementColor(monster.element),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getElementName(monster.element),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    monster.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Text('★' * monster.rarity, style: const TextStyle(color: Colors.orange)),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Lv50ステータス', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildStatRow('HP', monster.lv50Hp),
            _buildStatRow('攻撃', monster.lv50Attack),
            _buildStatRow('防御', monster.lv50Defense),
            _buildStatRow('魔力', monster.lv50Magic),
            _buildStatRow('素早さ', monster.lv50Speed),
            if (monster.skills.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('技', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...monster.skills.map((skill) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getElementColor(skill.element),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('C${skill.cost}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                        const SizedBox(width: 8),
                        Text(skill.name),
                      ],
                    ),
                  )),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('閉じる'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _getElementColor(String element) {
    switch (element.toLowerCase()) {
      case 'fire': return Colors.deepOrange;
      case 'water': return Colors.blue;
      case 'thunder': return Colors.amber.shade700;
      case 'wind': return Colors.green;
      case 'earth': return Colors.brown;
      case 'light': return Colors.yellow.shade700;
      case 'dark': return Colors.purple.shade700;
      default: return Colors.grey;
    }
  }

  String _getElementName(String element) {
    switch (element.toLowerCase()) {
      case 'fire': return '炎';
      case 'water': return '水';
      case 'thunder': return '雷';
      case 'wind': return '風';
      case 'earth': return '地';
      case 'light': return '光';
      case 'dark': return '闇';
      default: return '無';
    }
  }
}

// ============================================
// ドラフトバトル画面（共通ウィジェット使用）
// ============================================

class _DraftBattleScreen extends StatelessWidget {
  final List<Monster> playerParty;
  final List<Monster> enemyParty;
  final String battleId;
  final bool isCpuOpponent;

  const _DraftBattleScreen({
    Key? key,
    required this.playerParty,
    required this.enemyParty,
    required this.battleId,
    required this.isCpuOpponent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BattleBloc()
        ..add(StartDraftBattle(
          playerParty: playerParty,
          enemyParty: enemyParty,
          battleId: battleId,
          isCpuOpponent: isCpuOpponent,
        )),
      child: const _DraftBattleContent(),
    );
  }
}

class _DraftBattleContent extends StatelessWidget {
  const _DraftBattleContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ドラフトバトル'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _showBattleMenu(context),
        ),
        actions: [
          BlocBuilder<BattleBloc, BattleState>(
            builder: (context, state) {
              if (state is BattleInProgress) {
                return IconButton(
                  icon: const Icon(Icons.list_alt),
                  onPressed: () => _showBattleLog(context, state.battleState),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<BattleBloc, BattleState>(
        listener: (context, state) {
          if (state is BattlePlayerWin && state.result != null) {
            // ★修正: pushで結果画面に遷移
            // 結果画面からはpopUntilでバトル選択画面まで戻る
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => BattleResultScreen(result: state.result!, stageData: null),
              ),
            );
          } else if (state is BattlePlayerLose && state.result != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => BattleResultScreen(result: state.result!, stageData: null),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is BattleLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BattleError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('エラー: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('戻る'),
                  ),
                ],
              ),
            );
          }

          if (state is BattleInProgress) {
            // 共通バトルウィジェットを使用
            return BattleContentWidget(
              battleState: state.battleState,
              message: state.message,
              battleType: 'draft',
            );
          }

          return const Center(child: Text('バトル準備中...'));
        },
      ),
    );
  }

  void _showBattleMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('メニュー'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.red),
              title: const Text('降参'),
              onTap: () {
                Navigator.of(dialogContext).pop();
                _confirmSurrender(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('閉じる')),
        ],
      ),
    );
  }

  void _confirmSurrender(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('降参'),
        content: const Text('本当に降参しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('キャンセル')),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<BattleBloc>().add(const ForceBattleEnd());
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('降参'),
          ),
        ],
      ),
    );
  }

  void _showBattleLog(BuildContext context, dynamic battleState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('バトルログ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: battleState.battleLog.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(battleState.battleLog[index], style: const TextStyle(fontSize: 14)),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
