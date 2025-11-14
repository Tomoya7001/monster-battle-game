import 'package:equatable/equatable.dart';

abstract class GachaEvent extends Equatable {
  const GachaEvent();

  @override
  List<Object?> get props => [];
}

/// 初期化イベント
class InitializeGacha extends GachaEvent {
  const InitializeGacha();
}

class ExecuteGacha extends GachaEvent {
  final String gachaType;
  final int count;
  final String? userId; // 追加

  const ExecuteGacha({
    required this.gachaType,
    required this.count,
    this.userId, // 追加
  });

  @override
  List<Object?> get props => [gachaType, count, userId]; // 修正
}

/// ガチャタイプ変更イベント
class ChangeGachaType extends GachaEvent {
  final String gachaType;

  const ChangeGachaType(this.gachaType);

  @override
  List<Object?> get props => [gachaType];
}

/// 天井カウンターリセットイベント
class ResetPityCounter extends GachaEvent {
  const ResetPityCounter();
}

/// チケット残高読み込みイベント
class LoadTicketBalance extends GachaEvent {
  final String userId;

  const LoadTicketBalance(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// チケット交換イベント
class ExchangeTickets extends GachaEvent {
  final String userId;
  final String optionId;

  const ExchangeTickets({
    required this.userId,
    required this.optionId,
  });

  @override
  List<Object?> get props => [userId, optionId];
}

/// ガチャ履歴取得イベント
class LoadGachaHistory extends GachaEvent {
  final String userId;

  const LoadGachaHistory(this.userId);

  @override
  List<Object?> get props => [userId];
}