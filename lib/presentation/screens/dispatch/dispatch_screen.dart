// lib/presentation/screens/dispatch/dispatch_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/dispatch/dispatch_bloc.dart';
import '../../bloc/dispatch/dispatch_event.dart';
import '../../bloc/dispatch/dispatch_state.dart';
import 'widgets/dispatch_slot_card.dart';
import 'widgets/dispatch_reward_dialog.dart';

class DispatchScreen extends StatefulWidget {
  final String userId;

  const DispatchScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<DispatchScreen> createState() => _DispatchScreenState();
}

class _DispatchScreenState extends State<DispatchScreen> {
  Timer? _uiRefreshTimer;

  @override
  void initState() {
    super.initState();
    // 1秒ごとにUIを更新（残り時間表示用）
    _uiRefreshTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _uiRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DispatchBloc()..add(LoadDispatchData(widget.userId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('探索'),
          actions: [
            BlocBuilder<DispatchBloc, DispatchState>(
              builder: (context, state) {
                if (state is DispatchLoaded) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.explore, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${state.unlockedLocations.length}箇所解放',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocConsumer<DispatchBloc, DispatchState>(
          listener: (context, state) {
            if (state is DispatchError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is DispatchStarted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('探索を開始しました'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is DispatchSlotUnlocked) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('枠${state.slotIndex}を解放しました'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is DispatchRewardClaimed) {
              // 報酬ダイアログ表示
              showDialog(
                context: context,
                builder: (_) => DispatchRewardDialog(
                  rewards: state.rewards,
                  expGained: state.expGained,
                  materialMasters: state.materialMasters,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is DispatchLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is DispatchLoaded) {
              return _buildContent(context, state);
            }

            return const Center(child: Text('データを読み込んでいます...'));
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, DispatchLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<DispatchBloc>().add(LoadDispatchData(widget.userId));
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 説明テキスト
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'モンスターを探索に派遣して素材を集めよう！\n派遣中のモンスターは冒険に参加できません。',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 解放済み探索先一覧
            if (state.unlockedLocations.isEmpty)
              _buildNoLocationsCard()
            else
              _buildUnlockedLocationsInfo(state),

            const SizedBox(height: 24),

            // 探索枠
            const Text(
              '探索枠',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // 枠1
            DispatchSlotCard(
              slotIndex: 1,
              dispatch: state.getDispatchBySlot(1),
              isUnlocked: true,
              unlockedLocations: state.unlockedLocations,
              availableMonsters: state.selectableMonsters,
              materialMasters: state.materialMasters,
              onStart: (locationId, durationHours, monsterIds) {
                context.read<DispatchBloc>().add(StartDispatch(
                      slotIndex: 1,
                      locationId: locationId,
                      durationHours: durationHours,
                      monsterIds: monsterIds,
                    ));
              },
              onClaim: (dispatchId) {
                context.read<DispatchBloc>().add(ClaimDispatchReward(dispatchId));
              },
              onCancel: (dispatchId) {
                _showCancelConfirmDialog(context, dispatchId);
              },
            ),
            const SizedBox(height: 12),

            // 枠2
            DispatchSlotCard(
              slotIndex: 2,
              dispatch: state.getDispatchBySlot(2),
              isUnlocked: state.isSlotUnlocked(2),
              unlockedLocations: state.unlockedLocations,
              availableMonsters: state.selectableMonsters,
              materialMasters: state.materialMasters,
              onStart: (locationId, durationHours, monsterIds) {
                context.read<DispatchBloc>().add(StartDispatch(
                      slotIndex: 2,
                      locationId: locationId,
                      durationHours: durationHours,
                      monsterIds: monsterIds,
                    ));
              },
              onClaim: (dispatchId) {
                context.read<DispatchBloc>().add(ClaimDispatchReward(dispatchId));
              },
              onCancel: (dispatchId) {
                _showCancelConfirmDialog(context, dispatchId);
              },
              onUnlock: () {
                _showUnlockConfirmDialog(context, 2);
              },
            ),
            const SizedBox(height: 12),

            // 枠3
            DispatchSlotCard(
              slotIndex: 3,
              dispatch: state.getDispatchBySlot(3),
              isUnlocked: state.isSlotUnlocked(3),
              unlockedLocations: state.unlockedLocations,
              availableMonsters: state.selectableMonsters,
              materialMasters: state.materialMasters,
              onStart: (locationId, durationHours, monsterIds) {
                context.read<DispatchBloc>().add(StartDispatch(
                      slotIndex: 3,
                      locationId: locationId,
                      durationHours: durationHours,
                      monsterIds: monsterIds,
                    ));
              },
              onClaim: (dispatchId) {
                context.read<DispatchBloc>().add(ClaimDispatchReward(dispatchId));
              },
              onCancel: (dispatchId) {
                _showCancelConfirmDialog(context, dispatchId);
              },
              onUnlock: () {
                _showUnlockConfirmDialog(context, 3);
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildNoLocationsCard() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '探索先がありません',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '冒険でボスを倒すと探索先が解放されます',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockedLocationsInfo(DispatchLoaded state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '解放済み探索先',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.unlockedLocations.map((location) {
                return Chip(
                  avatar: const Icon(Icons.check_circle, size: 18, color: Colors.green),
                  label: Text(
                    location.name,
                    style: const TextStyle(fontSize: 13),
                  ),
                  backgroundColor: Colors.green.shade50,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnlockConfirmDialog(BuildContext context, int slotIndex) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('枠$slotIndexを解放'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('探索枠を解放しますか？'),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.diamond, color: Colors.blue, size: 20),
                const SizedBox(width: 4),
                Text(
                  '500石',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<DispatchBloc>().add(UnlockDispatchSlot(slotIndex));
            },
            child: const Text('解放する'),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmDialog(BuildContext context, String dispatchId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('探索キャンセル'),
        content: const Text(
          '探索をキャンセルしますか？\n\n※開始から5分以内のみキャンセル可能です',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('戻る'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<DispatchBloc>().add(CancelDispatch(dispatchId));
            },
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }
}