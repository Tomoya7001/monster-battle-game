// lib/presentation/bloc/item/item_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/item_repository.dart';
import '../../../core/services/item_service.dart';
import 'item_event.dart';
import 'item_state.dart';

class ItemBloc extends Bloc<ItemEvent, ItemState> {
  final ItemRepository _itemRepository;
  final ItemService _itemService;
  
  ItemBloc({
    ItemRepository? itemRepository,
    ItemService? itemService,
  })  : _itemRepository = itemRepository ?? ItemRepository(),
        _itemService = itemService ?? ItemService(),
        super(const ItemState()) {
    on<LoadItems>(_onLoadItems);
    on<ChangeCategory>(_onChangeCategory);
    on<UseItem>(_onUseItem);
    on<ClearUseResult>(_onClearUseResult);
  }

  Future<void> _onLoadItems(LoadItems event, Emitter<ItemState> emit) async {
    emit(state.copyWith(status: ItemStatus.loading));
    
    try {
      final masters = await _itemRepository.getItemMasters();
      final userItems = await _itemRepository.getUserItems(event.userId);
      
      emit(state.copyWith(
        status: ItemStatus.loaded,
        itemMasters: masters.values.toList(),
        userItems: userItems,
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
        // アイテム一覧を再取得
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
}