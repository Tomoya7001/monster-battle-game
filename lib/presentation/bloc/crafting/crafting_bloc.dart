// lib/presentation/bloc/crafting/crafting_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/equipment_master.dart';
import '../../../core/services/crafting_service.dart';
import 'crafting_event.dart';
import 'crafting_state.dart';

class CraftingBloc extends Bloc<CraftingEvent, CraftingState> {
  final CraftingService _craftingService;
  final FirebaseFirestore _firestore;

  CraftingBloc({
    CraftingService? craftingService,
    FirebaseFirestore? firestore,
  })  : _craftingService = craftingService ?? CraftingService(),
        _firestore = firestore ?? FirebaseFirestore.instance,
        super(const CraftingState()) {
    on<LoadCraftingData>(_onLoadCraftingData);
    on<ChangeCraftingCategory>(_onChangeCraftingCategory);
    on<ChangeCraftingFilter>(_onChangeCraftingFilter);
    on<SelectEquipment>(_onSelectEquipment);
    on<DeselectEquipment>(_onDeselectEquipment);
    on<CraftEquipment>(_onCraftEquipment);
    on<RefreshCraftingData>(_onRefreshCraftingData);
  }

  Future<void> _onLoadCraftingData(
    LoadCraftingData event,
    Emitter<CraftingState> emit,
  ) async {
    emit(state.copyWith(status: CraftingStatus.loading));

    try {
      // 装備マスター取得
      final equipments = await _getEquipmentMasters();

      // ユーザー所持装備取得
      final userEquipments = await _craftingService.getUserEquipmentQuantities(event.userId);

      // ユーザーゴールド取得
      final gold = await _craftingService.getUserGold(event.userId);

      // 素材総数取得
      final commonMaterials = await _craftingService.getTotalCommonMaterials(event.userId);
      final monsterMaterials = await _craftingService.getTotalMonsterMaterials(event.userId);

      // 各装備の錬成可否チェック
      final availabilities = <String, CraftingAvailability>{};
      for (final equipment in equipments) {
        final availability = await _craftingService.checkCraftingAvailability(
          event.userId,
          equipment,
        );
        availabilities[equipment.equipmentId] = availability;
      }

      // フィルタリング適用
      final filtered = _applyFilters(
        equipments,
        state.currentCategory,
        state.currentFilter,
        userEquipments,
        availabilities,
      );

      emit(state.copyWith(
        status: CraftingStatus.loaded,
        allEquipments: equipments,
        filteredEquipments: filtered,
        userEquipmentQuantities: userEquipments,
        availabilities: availabilities,
        userGold: gold,
        totalCommonMaterials: commonMaterials,
        totalMonsterMaterials: monsterMaterials,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CraftingStatus.error,
        errorMessage: 'データの読み込みに失敗しました: $e',
      ));
    }
  }

  Future<void> _onChangeCraftingCategory(
    ChangeCraftingCategory event,
    Emitter<CraftingState> emit,
  ) async {
    final filtered = _applyFilters(
      state.allEquipments,
      event.category,
      state.currentFilter,
      state.userEquipmentQuantities,
      state.availabilities,
    );

    emit(state.copyWith(
      currentCategory: event.category,
      filteredEquipments: filtered,
      clearSelected: true,
    ));
  }

  Future<void> _onChangeCraftingFilter(
    ChangeCraftingFilter event,
    Emitter<CraftingState> emit,
  ) async {
    final filtered = _applyFilters(
      state.allEquipments,
      state.currentCategory,
      event.filter,
      state.userEquipmentQuantities,
      state.availabilities,
    );

    emit(state.copyWith(
      currentFilter: event.filter,
      filteredEquipments: filtered,
    ));
  }

  Future<void> _onSelectEquipment(
    SelectEquipment event,
    Emitter<CraftingState> emit,
  ) async {
    final availability = state.availabilities[event.equipment.equipmentId];

    emit(state.copyWith(
      selectedEquipment: event.equipment,
      selectedAvailability: availability,
    ));
  }

  Future<void> _onDeselectEquipment(
    DeselectEquipment event,
    Emitter<CraftingState> emit,
  ) async {
    emit(state.copyWith(clearSelected: true));
  }

  Future<void> _onCraftEquipment(
    CraftEquipment event,
    Emitter<CraftingState> emit,
  ) async {
    emit(state.copyWith(status: CraftingStatus.crafting));

    try {
      final result = await _craftingService.craftEquipment(
        event.userId,
        event.equipment,
      );

      if (result.success) {
        // データ再読み込み
        add(RefreshCraftingData(event.userId));

        emit(state.copyWith(
          status: CraftingStatus.craftingSuccess,
          successMessage: '${event.equipment.name}を錬成しました！',
          clearSelected: true,
        ));
      } else {
        emit(state.copyWith(
          status: CraftingStatus.craftingError,
          errorMessage: result.message,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: CraftingStatus.craftingError,
        errorMessage: '錬成に失敗しました: $e',
      ));
    }
  }

  Future<void> _onRefreshCraftingData(
    RefreshCraftingData event,
    Emitter<CraftingState> emit,
  ) async {
    try {
      // ユーザー所持装備取得
      final userEquipments = await _craftingService.getUserEquipmentQuantities(event.userId);

      // ユーザーゴールド取得
      final gold = await _craftingService.getUserGold(event.userId);

      // 素材総数取得
      final commonMaterials = await _craftingService.getTotalCommonMaterials(event.userId);
      final monsterMaterials = await _craftingService.getTotalMonsterMaterials(event.userId);

      // 各装備の錬成可否チェック
      final availabilities = <String, CraftingAvailability>{};
      for (final equipment in state.allEquipments) {
        final availability = await _craftingService.checkCraftingAvailability(
          event.userId,
          equipment,
        );
        availabilities[equipment.equipmentId] = availability;
      }

      // フィルタリング適用
      final filtered = _applyFilters(
        state.allEquipments,
        state.currentCategory,
        state.currentFilter,
        userEquipments,
        availabilities,
      );

      emit(state.copyWith(
        status: CraftingStatus.loaded,
        filteredEquipments: filtered,
        userEquipmentQuantities: userEquipments,
        availabilities: availabilities,
        userGold: gold,
        totalCommonMaterials: commonMaterials,
        totalMonsterMaterials: monsterMaterials,
        clearSuccess: true,
      ));
    } catch (e) {
      print('Error refreshing crafting data: $e');
    }
  }

  /// 装備マスターを取得
  Future<List<EquipmentMaster>> _getEquipmentMasters() async {
    final snapshot = await _firestore
        .collection('equipment_masters')
        .orderBy('rarity', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['equipment_id'] = doc.id;
      return EquipmentMaster.fromJson(data);
    }).toList();
  }

  /// フィルタリング適用
  List<EquipmentMaster> _applyFilters(
    List<EquipmentMaster> equipments,
    String category,
    CraftingFilter filter,
    Map<String, int> userEquipments,
    Map<String, CraftingAvailability> availabilities,
  ) {
    var filtered = equipments.toList();

    // カテゴリフィルター
    if (category != 'all') {
      filtered = filtered.where((e) => e.category == category).toList();
    }

    // 作成可能フィルター
    switch (filter) {
      case CraftingFilter.craftable:
        filtered = filtered.where((e) {
          final availability = availabilities[e.equipmentId];
          return availability?.canCraft == true;
        }).toList();
        break;
      case CraftingFilter.notOwned:
        filtered = filtered.where((e) {
          final owned = userEquipments[e.equipmentId] ?? 0;
          return owned == 0;
        }).toList();
        break;
      case CraftingFilter.all:
        break;
    }

    // レアリティ降順でソート
    filtered.sort((a, b) => b.rarity.compareTo(a.rarity));

    return filtered;
  }
}