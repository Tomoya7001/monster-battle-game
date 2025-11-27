// lib/presentation/bloc/item/item_event.dart
import 'package:equatable/equatable.dart';

abstract class ItemEvent extends Equatable {
  const ItemEvent();
  
  @override
  List<Object?> get props => [];
}

/// アイテム一覧読み込み
class LoadItems extends ItemEvent {
  final String userId;
  
  const LoadItems({required this.userId});
  
  @override
  List<Object?> get props => [userId];
}

/// カテゴリ変更
class ChangeCategory extends ItemEvent {
  final int categoryIndex;
  
  const ChangeCategory(this.categoryIndex);
  
  @override
  List<Object?> get props => [categoryIndex];
}

/// アイテム使用
class UseItem extends ItemEvent {
  final String userId;
  final String itemId;
  final String targetMonsterId;
  
  const UseItem({
    required this.userId,
    required this.itemId,
    required this.targetMonsterId,
  });
  
  @override
  List<Object?> get props => [userId, itemId, targetMonsterId];
}

/// アイテム使用結果クリア
class ClearUseResult extends ItemEvent {
  const ClearUseResult();
}

/// 装備をモンスターに装着
class EquipToMonster extends ItemEvent {
  final String monsterId;
  final String equipmentId;
  final int slot;
  
  const EquipToMonster({
    required this.monsterId,
    required this.equipmentId,
    this.slot = 0,
  });
  
  @override
  List<Object?> get props => [monsterId, equipmentId, slot];
}

/// 装備を外す
class UnequipFromMonster extends ItemEvent {
  final String monsterId;
  final String equipmentId;
  
  const UnequipFromMonster({
    required this.monsterId,
    required this.equipmentId,
  });
  
  @override
  List<Object?> get props => [monsterId, equipmentId];
}