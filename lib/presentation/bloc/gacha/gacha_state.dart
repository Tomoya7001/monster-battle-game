import 'package:equatable/equatable.dart';

enum GachaStatus {
  initial,
  loading,
  success,
  failure,
}

class GachaState extends Equatable {
  final GachaStatus status;
  final GachaType selectedType;
  final int freeGems;
  final int paidGems;
  final int tickets;
  final int pityCount;
  final List<UserMonster> results;
  final String? errorMessage;

  const GachaState({
    this.status = GachaStatus.initial,
    this.selectedType = GachaType.normal,
    this.freeGems = 0,
    this.paidGems = 0,
    this.tickets = 0,
    this.pityCount = 0,
    this.results = const [],
    this.errorMessage,
  });

  GachaState copyWith({
    GachaStatus? status,
    GachaType? selectedType,
    int? freeGems,
    int? paidGems,
    int? tickets,
    int? pityCount,
    List<UserMonster>? results,
    String? errorMessage,
  }) {
    return GachaState(
      status: status ?? this.status,
      selectedType: selectedType ?? this.selectedType,
      freeGems: freeGems ?? this.freeGems,
      paidGems: paidGems ?? this.paidGems,
      tickets: tickets ?? this.tickets,
      pityCount: pityCount ?? this.pityCount,
      results: results ?? this.results,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        selectedType,
        freeGems,
        paidGems,
        tickets,
        pityCount,
        results,
        errorMessage,
      ];
}