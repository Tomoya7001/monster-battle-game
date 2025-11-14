import 'package:equatable/equatable.dart';

abstract class GachaState extends Equatable {
  final String selectedType;
  final int pityCount;
  final int gems;
  final int tickets;
  final int gachaTickets;

  const GachaState({
    this.selectedType = '通常',
    this.pityCount = 0,
    this.gems = 15000,
    this.tickets = 10,
    this.gachaTickets = 0,
  });

  @override
  List<Object?> get props => [selectedType, pityCount, gems, tickets, gachaTickets];
}

/// 初期状態
class GachaInitial extends GachaState {
  const GachaInitial({
    String selectedType = '通常',
    int pityCount = 0,
    int gems = 15000,
    int tickets = 10,
    int gachaTickets = 0,
  }) : super(
          selectedType: selectedType,
          pityCount: pityCount,
          gems: gems,
          tickets: tickets,
          gachaTickets: gachaTickets,
        );
}

/// ローディング状態
class GachaLoading extends GachaState {
  const GachaLoading({
    required String selectedType,
    required int pityCount,
    required int gems,
    required int tickets,
    int gachaTickets = 0,
  }) : super(
          selectedType: selectedType,
          pityCount: pityCount,
          gems: gems,
          tickets: tickets,
          gachaTickets: gachaTickets,
        );
}

/// ガチャ実行成功状態
class GachaLoaded extends GachaState {
  final List<dynamic> results;

  const GachaLoaded({
    required this.results,
    required String selectedType,
    required int pityCount,
    required int gems,
    required int tickets,
    int gachaTickets = 0,
  }) : super(
          selectedType: selectedType,
          pityCount: pityCount,
          gems: gems,
          tickets: tickets,
          gachaTickets: gachaTickets,
        );

  @override
  List<Object?> get props => [results, selectedType, pityCount, gems, tickets, gachaTickets];
}

/// エラー状態
class GachaError extends GachaState {
  final String error;

  const GachaError({
    required this.error,
    required String selectedType,
    required int pityCount,
    required int gems,
    required int tickets,
    int gachaTickets = 0,
  }) : super(
          selectedType: selectedType,
          pityCount: pityCount,
          gems: gems,
          tickets: tickets,
          gachaTickets: gachaTickets,
        );

  @override
  List<Object?> get props => [error, selectedType, pityCount, gems, tickets, gachaTickets];
}

/// チケット残高読み込み成功状態
class TicketBalanceLoaded extends GachaState {
  final int ticketCount;
  final int totalPulls;

  const TicketBalanceLoaded({
    required this.ticketCount,
    required this.totalPulls,
    required String selectedType,
    required int pityCount,
    required int gems,
    required int tickets,
  }) : super(
          selectedType: selectedType,
          pityCount: pityCount,
          gems: gems,
          tickets: tickets,
          gachaTickets: ticketCount,
        );

  @override
  List<Object?> get props => [ticketCount, totalPulls, selectedType, pityCount, gems, tickets];
}

/// チケット交換成功状態
class TicketExchangeSuccess extends GachaState {
  final Map<String, dynamic> reward;

  const TicketExchangeSuccess({
    required this.reward,
    required String selectedType,
    required int pityCount,
    required int gems,
    required int tickets,
    required int gachaTickets,
  }) : super(
          selectedType: selectedType,
          pityCount: pityCount,
          gems: gems,
          tickets: tickets,
          gachaTickets: gachaTickets,
        );

  @override
  List<Object?> get props => [reward, selectedType, pityCount, gems, tickets, gachaTickets];
}

/// ガチャ履歴読み込み成功
class GachaHistoryLoaded extends GachaState {
  final List<dynamic> history; // GachaHistory のリスト

  const GachaHistoryLoaded({
    required this.history,
    String selectedType = '通常',
    int pityCount = 0,
    int gems = 5000,
    int tickets = 10,
    int gachaTickets = 0,
  }) : super(
          selectedType: selectedType,
          pityCount: pityCount,
          gems: gems,
          tickets: tickets,
          gachaTickets: gachaTickets,
        );

  @override
  List<Object?> get props => [
        history,
        selectedType,
        pityCount,
        gems,
        tickets,
        gachaTickets,
      ];
}