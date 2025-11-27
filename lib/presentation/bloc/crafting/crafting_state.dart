// lib/presentation/bloc/crafting/crafting_state.dart

import 'package:equatable/equatable.dart';
import '../../../domain/entities/equipment_master.dart';
import '../../../core/services/crafting_service.dart';
import 'crafting_event.dart';

enum CraftingStatus {
  initial,
  loading,
  loaded,
  crafting,
  craftingSuccess,
  craftingError,
  error,
}

class CraftingState extends Equatable {
  final CraftingStatus status;
  final List<EquipmentMaster> allEquipments;
  final List<EquipmentMaster> filteredEquipments;
  final Map<String, int> userEquipmentQuantities;
  final Map<String, CraftingAvailability> availabilities;
  final String currentCategory;
  final CraftingFilter currentFilter;
  final EquipmentMaster? selectedEquipment;
  final CraftingAvailability? selectedAvailability;
  final int userGold;
  final int totalCommonMaterials;
  final int totalMonsterMaterials;
  final String? errorMessage;
  final String? successMessage;

  const CraftingState({
    this.status = CraftingStatus.initial,
    this.allEquipments = const [],
    this.filteredEquipments = const [],
    this.userEquipmentQuantities = const {},
    this.availabilities = const {},
    this.currentCategory = 'all',
    this.currentFilter = CraftingFilter.all,
    this.selectedEquipment,
    this.selectedAvailability,
    this.userGold = 0,
    this.totalCommonMaterials = 0,
    this.totalMonsterMaterials = 0,
    this.errorMessage,
    this.successMessage,
  });

  CraftingState copyWith({
    CraftingStatus? status,
    List<EquipmentMaster>? allEquipments,
    List<EquipmentMaster>? filteredEquipments,
    Map<String, int>? userEquipmentQuantities,
    Map<String, CraftingAvailability>? availabilities,
    String? currentCategory,
    CraftingFilter? currentFilter,
    EquipmentMaster? selectedEquipment,
    CraftingAvailability? selectedAvailability,
    int? userGold,
    int? totalCommonMaterials,
    int? totalMonsterMaterials,
    String? errorMessage,
    String? successMessage,
    bool clearSelected = false,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return CraftingState(
      status: status ?? this.status,
      allEquipments: allEquipments ?? this.allEquipments,
      filteredEquipments: filteredEquipments ?? this.filteredEquipments,
      userEquipmentQuantities: userEquipmentQuantities ?? this.userEquipmentQuantities,
      availabilities: availabilities ?? this.availabilities,
      currentCategory: currentCategory ?? this.currentCategory,
      currentFilter: currentFilter ?? this.currentFilter,
      selectedEquipment: clearSelected ? null : (selectedEquipment ?? this.selectedEquipment),
      selectedAvailability: clearSelected ? null : (selectedAvailability ?? this.selectedAvailability),
      userGold: userGold ?? this.userGold,
      totalCommonMaterials: totalCommonMaterials ?? this.totalCommonMaterials,
      totalMonsterMaterials: totalMonsterMaterials ?? this.totalMonsterMaterials,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        allEquipments,
        filteredEquipments,
        userEquipmentQuantities,
        availabilities,
        currentCategory,
        currentFilter,
        selectedEquipment,
        selectedAvailability,
        userGold,
        totalCommonMaterials,
        totalMonsterMaterials,
        errorMessage,
        successMessage,
      ];
}