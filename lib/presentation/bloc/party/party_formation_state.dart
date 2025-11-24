part of 'party_formation_bloc.dart';

abstract class PartyFormationState extends Equatable {
  const PartyFormationState();

  @override
  List<Object?> get props => [];
}

class PartyFormationInitial extends PartyFormationState {
  const PartyFormationInitial();
}

class PartyFormationLoading extends PartyFormationState {
  const PartyFormationLoading();
}

class PartyFormationLoaded extends PartyFormationState {
  final List<PartyPreset> presets;
  final List<Monster> allMonsters;
  final PartyPreset? currentPreset;
  final List<Monster> selectedMonsters;
  final String battleType;
  final String? errorMessage;

  const PartyFormationLoaded({
    required this.presets,
    required this.allMonsters,
    this.currentPreset,
    required this.selectedMonsters,
    required this.battleType,
    this.errorMessage,
  });

  PartyFormationLoaded copyWith({
    List<PartyPreset>? presets,
    List<Monster>? allMonsters,
    PartyPreset? currentPreset,
    List<Monster>? selectedMonsters,
    String? battleType,
    String? errorMessage,
  }) {
    return PartyFormationLoaded(
      presets: presets ?? this.presets,
      allMonsters: allMonsters ?? this.allMonsters,
      currentPreset: currentPreset ?? this.currentPreset,
      selectedMonsters: selectedMonsters ?? this.selectedMonsters,
      battleType: battleType ?? this.battleType,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        presets,
        allMonsters,
        currentPreset,
        selectedMonsters,
        battleType,
        errorMessage,
      ];
}

class PartyFormationError extends PartyFormationState {
  final String message;

  const PartyFormationError({required this.message});

  @override
  List<Object?> get props => [message];
}