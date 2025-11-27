// lib/presentation/screens/crafting/crafting_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/equipment_master.dart';
import '../../../core/services/crafting_service.dart';
import '../../bloc/crafting/crafting_bloc.dart';
import '../../bloc/crafting/crafting_event.dart';
import '../../bloc/crafting/crafting_state.dart';

class CraftingScreen extends StatelessWidget {
  const CraftingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: 認証完了後、実際のuserIdに置き換え
    const userId = 'dev_user_12345';

    return BlocProvider(
      create: (context) => CraftingBloc()..add(const LoadCraftingData(userId)),
      child: const _CraftingScreenContent(userId: userId),
    );
  }
}

class _CraftingScreenContent extends StatelessWidget {
  final String userId;

  const _CraftingScreenContent({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('錬成'),
        actions: [
          // 素材所持数表示
          BlocBuilder<CraftingBloc, CraftingState>(
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      _formatNumber(state.userGold),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<CraftingBloc, CraftingState>(
        listener: (context, state) {
          if (state.status == CraftingStatus.craftingSuccess && state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state.status == CraftingStatus.craftingError && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.status == CraftingStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == CraftingStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.errorMessage ?? 'エラーが発生しました'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<CraftingBloc>().add(LoadCraftingData(userId));
                    },
                    child: const Text('再読み込み'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // 素材サマリー
              _buildMaterialSummary(state),
              
              // カテゴリタブ
              _buildCategoryTabs(context, state),
              
              // フィルター
              _buildFilterChips(context, state),
              
              // 装備リスト
              Expanded(
                child: _buildEquipmentGrid(context, state),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMaterialSummary(CraftingState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMaterialChip(
            icon: Icons.inventory_2,
            label: '汎用素材',
            count: state.totalCommonMaterials,
            color: Colors.grey,
          ),
          _buildMaterialChip(
            icon: Icons.pets,
            label: 'モンスター素材',
            count: state.totalMonsterMaterials,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialChip({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        Text(
          _formatNumber(count),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildCategoryTabs(BuildContext context, CraftingState state) {
    final categories = [
      ('all', 'すべて', Icons.apps),
      ('weapon', '武器', Icons.gavel),
      ('armor', '防具', Icons.shield),
      ('accessory', 'アクセサリー', Icons.watch),
      ('special', '特殊', Icons.auto_awesome),
    ];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final (category, label, icon) = categories[index];
          final isSelected = state.currentCategory == category;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: Icon(icon, size: 18),
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  context.read<CraftingBloc>().add(ChangeCraftingCategory(category));
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, CraftingState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text('フィルター: ', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          ...CraftingFilter.values.map((filter) {
            final isSelected = state.currentFilter == filter;
            String label;
            switch (filter) {
              case CraftingFilter.all:
                label = 'すべて';
                break;
              case CraftingFilter.craftable:
                label = '作成可能';
                break;
              case CraftingFilter.notOwned:
                label = '未所持';
                break;
            }
            
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(label, style: const TextStyle(fontSize: 12)),
                selected: isSelected,
                onSelected: (selected) {
                  context.read<CraftingBloc>().add(ChangeCraftingFilter(filter));
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEquipmentGrid(BuildContext context, CraftingState state) {
    if (state.filteredEquipments.isEmpty) {
      return const Center(
        child: Text('該当する装備がありません'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: state.filteredEquipments.length,
      itemBuilder: (context, index) {
        final equipment = state.filteredEquipments[index];
        final availability = state.availabilities[equipment.equipmentId];
        final ownedCount = state.userEquipmentQuantities[equipment.equipmentId] ?? 0;

        return _EquipmentCard(
          equipment: equipment,
          availability: availability,
          ownedCount: ownedCount,
          onTap: () => _showEquipmentDetail(context, equipment, availability, ownedCount),
        );
      },
    );
  }

  void _showEquipmentDetail(
    BuildContext context,
    EquipmentMaster equipment,
    CraftingAvailability? availability,
    int ownedCount,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return BlocProvider.value(
          value: context.read<CraftingBloc>(),
          child: _EquipmentDetailSheet(
            equipment: equipment,
            availability: availability,
            ownedCount: ownedCount,
            userId: userId,
          ),
        );
      },
    );
  }

  String _formatNumber(int number) {
    if (number >= 10000) {
      return '${(number / 10000).toStringAsFixed(1)}万';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}

/// 装備カード
class _EquipmentCard extends StatelessWidget {
  final EquipmentMaster equipment;
  final CraftingAvailability? availability;
  final int ownedCount;
  final VoidCallback onTap;

  const _EquipmentCard({
    required this.equipment,
    this.availability,
    required this.ownedCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final canCraft = availability?.canCraft == true;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ヘッダー（レアリティ）
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: equipment.rarityColor.withOpacity(0.2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    equipment.rarityStars,
                    style: TextStyle(color: equipment.rarityColor),
                  ),
                  if (ownedCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '所持: $ownedCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                ],
              ),
            ),

            // アイコン
            Expanded(
              child: Center(
                child: Icon(
                  equipment.categoryIcon,
                  size: 48,
                  color: equipment.rarityColor,
                ),
              ),
            ),

            // 名前と状態
            Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    equipment.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        canCraft ? Icons.check_circle : Icons.cancel,
                        size: 14,
                        color: canCraft ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        canCraft ? '作成可能' : '素材不足',
                        style: TextStyle(
                          fontSize: 11,
                          color: canCraft ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 装備詳細シート
class _EquipmentDetailSheet extends StatelessWidget {
  final EquipmentMaster equipment;
  final CraftingAvailability? availability;
  final int ownedCount;
  final String userId;

  const _EquipmentDetailSheet({
    required this.equipment,
    this.availability,
    required this.ownedCount,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final canCraft = availability?.canCraft == true;

    return BlocBuilder<CraftingBloc, CraftingState>(
      builder: (context, state) {
        final isCrafting = state.status == CraftingStatus.crafting;

        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              Row(
                children: [
                  Icon(equipment.categoryIcon, size: 40, color: equipment.rarityColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          equipment.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              equipment.rarityStars,
                              style: TextStyle(color: equipment.rarityColor),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              equipment.categoryName,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (ownedCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '所持: $ownedCount',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // 説明
              Text(
                equipment.description,
                style: TextStyle(color: Colors.grey.shade600),
              ),

              const Divider(height: 24),

              // 効果
              const Text(
                '効果',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(equipment.effectsText),

              if (equipment.restrictionText != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        equipment.restrictionText!,
                        style: TextStyle(color: Colors.orange.shade700),
                      ),
                    ],
                  ),
                ),
              ],

              const Divider(height: 24),

              // 必要素材
              const Text(
                '必要素材',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),

              if (availability != null) ...[
                _buildMaterialRow(
                  icon: Icons.monetization_on,
                  iconColor: Colors.amber,
                  label: 'ゴールド',
                  required: availability!.requiredGold,
                  current: availability!.currentGold,
                  isEnough: availability!.hasEnoughGold,
                ),
                const SizedBox(height: 8),
                _buildMaterialRow(
                  icon: Icons.inventory_2,
                  iconColor: Colors.grey,
                  label: '汎用素材',
                  required: availability!.requiredCommonMaterials,
                  current: availability!.currentCommonMaterials,
                  isEnough: availability!.hasEnoughCommonMaterials,
                ),
                const SizedBox(height: 8),
                _buildMaterialRow(
                  icon: Icons.pets,
                  iconColor: Colors.purple,
                  label: 'モンスター素材',
                  required: availability!.requiredMonsterMaterials,
                  current: availability!.currentMonsterMaterials,
                  isEnough: availability!.hasEnoughMonsterMaterials,
                ),
              ],

              const SizedBox(height: 24),

              // 錬成ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canCraft && !isCrafting
                      ? () {
                          context.read<CraftingBloc>().add(
                                CraftEquipment(userId, equipment),
                              );
                          Navigator.pop(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canCraft ? Colors.blue : Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isCrafting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          canCraft ? '錬成する' : '素材が不足しています',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 8),

              // キャンセルボタン
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('閉じる'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMaterialRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required int required,
    required int current,
    required bool isEnough,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Icon(
          isEnough ? Icons.check_circle : Icons.cancel,
          size: 16,
          color: isEnough ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 4),
        Text(
          '$current / $required',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isEnough ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }
}