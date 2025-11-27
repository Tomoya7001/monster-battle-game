// lib/presentation/bloc/item/item_state.dart
import 'package:equatable/equatable.dart';
import '../../../domain/entities/item.dart';
import '../../../domain/entities/user_item.dart';
import '../../../domain/entities/equipment_master.dart';

enum ItemStatus { initial, loading, loaded, error, using }

class ItemState extends Equatable {
  final ItemStatus status;
  final List<Item> itemMasters;
  final List<UserItem> userItems;
  final List<EquipmentMaster> equipmentMasters;
  final int selectedCategoryIndex;
  final String? errorMessage;
  final String? useResultMessage;
  final bool? useResultSuccess;
  
  const ItemState({
    this.status = ItemStatus.initial,
    this.itemMasters = const [],
    this.userItems = const [],
    this.equipmentMasters = const [],
    this.selectedCategoryIndex = 0,
    this.errorMessage,
    this.useResultMessage,
    this.useResultSuccess,
  });
  
  static const categoryNames = ['装備', '素材', '消耗品', '貴重品'];
  static const categoryKeys = ['equipment', 'material', 'consumable', 'valuable'];
  
  /// 現在のカテゴリのアイテム一覧
  List<MapEntry<Item, int>> get currentCategoryItems {
    final categoryKey = categoryKeys[selectedCategoryIndex];
    final userItemMap = {for (var ui in userItems) ui.itemId: ui.quantity};
    
    return itemMasters
        .where((item) => item.category == categoryKey && item.isActive)
        .where((item) => userItemMap.containsKey(item.itemId))
        .map((item) => MapEntry(item, userItemMap[item.itemId] ?? 0))
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) => a.key.displayOrder.compareTo(b.key.displayOrder));
  }

  /// カテゴリ別装備一覧
  List<EquipmentMaster> getEquipmentsByCategory(String category) {
    return equipmentMasters
        .where((e) => e.category == category)
        .toList()
      ..sort((a, b) => a.rarity.compareTo(b.rarity));
  }
  
  ItemState copyWith({
    ItemStatus? status,
    List<Item>? itemMasters,
    List<UserItem>? userItems,
    List<EquipmentMaster>? equipmentMasters,
    int? selectedCategoryIndex,
    String? errorMessage,
    String? useResultMessage,
    bool? useResultSuccess,
  }) {
    return ItemState(
      status: status ?? this.status,
      itemMasters: itemMasters ?? this.itemMasters,
      userItems: userItems ?? this.userItems,
      equipmentMasters: equipmentMasters ?? this.equipmentMasters,
      selectedCategoryIndex: selectedCategoryIndex ?? this.selectedCategoryIndex,
      errorMessage: errorMessage,
      useResultMessage: useResultMessage,
      useResultSuccess: useResultSuccess,
    );
  }
  
  @override
  List<Object?> get props => [
    status,
    itemMasters,
    userItems,
    equipmentMasters,
    selectedCategoryIndex,
    errorMessage,
    useResultMessage,
    useResultSuccess,
  ];
}