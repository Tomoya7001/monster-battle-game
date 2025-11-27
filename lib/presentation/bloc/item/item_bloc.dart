// lib/presentation/bloc/item/item_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/item_repository.dart';
import '../../../data/repositories/equipment_repository.dart';
import '../../../core/services/item_service.dart';
import 'item_event.dart';
import 'item_state.dart';

class ItemBloc extends Bloc<ItemEvent, ItemState> {
  final ItemRepository _itemRepository;
  final EquipmentRepository _equipmentRepository;
  final ItemService _itemService;
  
  ItemBloc({
    ItemRepository? itemRepository,
    EquipmentRepository? equipmentRepository,
    ItemService? itemService,
  })  : _itemRepository = itemRepository ?? ItemRepository(),
        _equipmentRepository = equipmentRepository ?? EquipmentRepository(),
        _itemService = itemService ?? ItemService(),
        super(const ItemState()) {
    on<LoadItems>(_onLoadItems);
    on<ChangeCategory>(_onChangeCategory);
    on<UseItem>(_onUseItem);
    on<ClearUseResult>(_onClearUseResult);
    on<EquipToMonster>(_onEquipToMonster);
    on<UnequipFromMonster>(_onUnequipFromMonster);
  }

  Future<void> _onLoadItems(LoadItems event, Emitter<ItemState> emit) async {
    emit(state.copyWith(status: ItemStatus.loading));
    
    try {
      final masters = await _itemRepository.getItemMasters();
      final userItems = await _itemRepository.getUserItems(event.userId);
      final equipmentMasters = await _equipmentRepository.getEquipmentMasters();
      
      emit(state.copyWith(
        status: ItemStatus.loaded,
        itemMasters: masters.values.toList(),
        userItems: userItems,
        equipmentMasters: equipmentMasters.values.toList(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ItemStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onChangeCategory(ChangeCategory event, Emitter<ItemState> emit) {
    emit(state.copyWith(selectedCategoryIndex: event.categoryIndex));
  }

  Future<void> _onUseItem(UseItem event, Emitter<ItemState> emit) async {
    emit(state.copyWith(status: ItemStatus.using));
    
    try {
      final result = await _itemService.useItem(
        userId: event.userId,
        itemId: event.itemId,
        targetMonsterId: event.targetMonsterId,
      );
      
      if (result.success) {
        final userItems = await _itemRepository.getUserItems(event.userId);
        emit(state.copyWith(
          status: ItemStatus.loaded,
          userItems: userItems,
          useResultMessage: result.message,
          useResultSuccess: true,
        ));
      } else {
        emit(state.copyWith(
          status: ItemStatus.loaded,
          useResultMessage: result.message,
          useResultSuccess: false,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: ItemStatus.loaded,
        useResultMessage: 'エラー: $e',
        useResultSuccess: false,
      ));
    }
  }

  void _onClearUseResult(ClearUseResult event, Emitter<ItemState> emit) {
    emit(state.copyWith(
      useResultMessage: null,
      useResultSuccess: null,
    ));
  }

  Future<void> _onEquipToMonster(EquipToMonster event, Emitter<ItemState> emit) async {
    emit(state.copyWith(status: ItemStatus.using));
    
    try {
      final success = await _equipmentRepository.equipToMonster(
        monsterId: event.monsterId,
        equipmentId: event.equipmentId,
        slot: event.slot,
      );
      
      emit(state.copyWith(
        status: ItemStatus.loaded,
        useResultMessage: success ? '装備しました' : '装備に失敗しました',
        useResultSuccess: success,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ItemStatus.loaded,
        useResultMessage: 'エラー: $e',
        useResultSuccess: false,
      ));
    }
  }

  Future<void> _onUnequipFromMonster(UnequipFromMonster event, Emitter<ItemState> emit) async {
    emit(state.copyWith(status: ItemStatus.using));
    
    try {
      final success = await _equipmentRepository.unequipFromMonster(
        monsterId: event.monsterId,
        equipmentId: event.equipmentId,
      );
      
      emit(state.copyWith(
        status: ItemStatus.loaded,
        useResultMessage: success ? '装備を外しました' : '装備解除に失敗しました',
        useResultSuccess: success,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ItemStatus.loaded,
        useResultMessage: 'エラー: $e',
        useResultSuccess: false,
      ));
    }
  }
}