import 'package:equatable/equatable.dart';

abstract class GachaEvent extends Equatable {
  const GachaEvent();
}

class LoadGachaData extends GachaEvent {
  final String userId;

  const LoadGachaData({required this.userId});

  @override
  List<Object> get props => [userId];
}

class SelectGachaType extends GachaEvent {
  final String type;

  const SelectGachaType({required this.type});

  @override
  List<Object> get props => [type];
}

class DrawSingleGacha extends GachaEvent {
  final String userId;
  final bool useFreeTicket;
  final int count;

  const DrawSingleGacha({
    required this.userId,
    this.useFreeTicket = false,
    this.count = 1,
  });

  @override
  List<Object> get props => [userId, useFreeTicket, count];
}

class DrawMultiGacha extends GachaEvent {
  final String userId;
  final bool useTickets;
  final int count;

  const DrawMultiGacha({
    required this.userId,
    this.useTickets = false,
    this.count = 10,
  });

  @override
  List<Object> get props => [userId, useTickets, count];
}

class ExchangeTickets extends GachaEvent {
  final String userId;
  final String optionId;

  const ExchangeTickets({
    required this.userId,
    required this.optionId,
  });

  @override
  List<Object> get props => [userId, optionId];
}

class LoadGachaHistory extends GachaEvent {
  final String userId;

  const LoadGachaHistory({required this.userId});

  @override
  List<Object> get props => [userId];
}