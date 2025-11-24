part of 'party_formation_bloc.dart';

abstract class PartyFormationEvent extends Equatable {
  const PartyFormationEvent();

  @override
  List<Object?> get props => [];
}

class LoadPartyPresets extends PartyFormationEvent {
  final String battleType; // 'pvp' or 'adventure'

  const LoadPartyPresets({required this.battleType});

  @override
  List<Object?> get props => [battleType];
}

class SelectMonster extends PartyFormationEvent {
  final Monster monster;

  const SelectMonster({required this.monster});

  @override
  List<Object?> get props => [monster];
}

class RemoveMonster extends PartyFormationEvent {
  final String monsterId;

  const RemoveMonster({required this.monsterId});

  @override
  List<Object?> get props => [monsterId];
}

class SavePartyPreset extends PartyFormationEvent {
  final String? presetId;
  final String name;
  final bool isActive;

  const SavePartyPreset({
    this.presetId,
    required this.name,
    this.isActive = false,
  });

  @override
  List<Object?> get props => [presetId, name, isActive];
}

class DeletePartyPreset extends PartyFormationEvent {
  final String presetId;

  const DeletePartyPreset({required this.presetId});

  @override
  List<Object?> get props => [presetId];
}

class ActivatePreset extends PartyFormationEvent {
  final String presetId;

  const ActivatePreset({required this.presetId});

  @override
  List<Object?> get props => [presetId];
}