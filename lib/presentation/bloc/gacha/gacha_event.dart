import 'package:equatable/equatable.dart';

abstract class GachaEvent extends Equatable {
  const GachaEvent();

  @override
  List<Object?> get props => [];
}

// 初期化イベント
class InitializeGacha extends GachaEvent {
  const InitializeGacha();
}

// ガチャ実行イベント
class ExecuteGacha extends GachaEvent {
  final String gachaType;
  final int count;
  final String? userId;

  const ExecuteGacha({
    required this.gachaType,
    required this.count,
    this.userId,
  });

  @override
  List<Object?> get props => [gachaType, count, userId];
}

// ガチャタイプ変更イベント
class ChangeGachaType extends GachaEvent {
  final String gachaType;

  const ChangeGachaType(this.gachaType);

  @override
  List<Object> get props => [gachaType];
}

// 天井カウンターリセットイベント
class ResetPityCounter extends GachaEvent {
  const ResetPityCounter();
}

// チケット残高読み込みイベント
class LoadTicketBalance extends GachaEvent {
  final String userId;

  const LoadTicketBalance(this.userId);

  @override
  List<Object> get props => [userId];
}

// チケット交換イベント
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

// ガチャ履歴読み込みイベント
class LoadGachaHistory extends GachaEvent {
  final String userId;

  const LoadGachaHistory({required this.userId});

  @override
  List<Object> get props => [userId];
}

// その他の既存イベント（互換性のため残す）
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