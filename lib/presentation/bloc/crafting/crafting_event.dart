// lib/presentation/bloc/crafting/crafting_event.dart

import 'package:equatable/equatable.dart';
import '../../../domain/entities/equipment_master.dart';

abstract class CraftingEvent extends Equatable {
  const CraftingEvent();

  @override
  List<Object?> get props => [];
}

/// 初期データ読み込み
class LoadCraftingData extends CraftingEvent {
  final String userId;

  const LoadCraftingData(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// カテゴリ変更
class ChangeCraftingCategory extends CraftingEvent {
  final String category;

  const ChangeCraftingCategory(this.category);

  @override
  List<Object?> get props => [category];
}

/// フィルター変更
class ChangeCraftingFilter extends CraftingEvent {
  final CraftingFilter filter;

  const ChangeCraftingFilter(this.filter);

  @override
  List<Object?> get props => [filter];
}

/// 装備選択
class SelectEquipment extends CraftingEvent {
  final EquipmentMaster equipment;

  const SelectEquipment(this.equipment);

  @override
  List<Object?> get props => [equipment];
}

/// 選択解除
class DeselectEquipment extends CraftingEvent {
  const DeselectEquipment();
}

/// 錬成実行
class CraftEquipment extends CraftingEvent {
  final String userId;
  final EquipmentMaster equipment;

  const CraftEquipment(this.userId, this.equipment);

  @override
  List<Object?> get props => [userId, equipment];
}

/// データ再読み込み
class RefreshCraftingData extends CraftingEvent {
  final String userId;

  const RefreshCraftingData(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// フィルター種別
enum CraftingFilter {
  all,       // すべて
  craftable, // 作成可能
  notOwned,  // 未所持
}