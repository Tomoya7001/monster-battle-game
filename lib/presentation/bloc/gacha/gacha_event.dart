import 'package:equatable/equatable.dart';
import '../../screens/gacha/widgets/gacha_tabs.dart';

/// ガチャ関連のイベント
abstract class GachaEvent extends Equatable {
  const GachaEvent();

  @override
  List<Object?> get props => [];
}

/// 初期化イベント
/// ユーザーの通貨情報と天井カウンターを取得
class GachaInitialize extends GachaEvent {
  final String userId;

  const GachaInitialize(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// ガチャタイプ変更イベント
class GachaTypeChanged extends GachaEvent {
  final GachaType type;

  const GachaTypeChanged(this.type);

  @override
  List<Object?> get props => [type];
}

/// 単発ガチャ実行イベント
class GachaDrawSingle extends GachaEvent {
  final String userId;

  const GachaDrawSingle(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// 10連ガチャ実行イベント
class GachaDrawMulti extends GachaEvent {
  final String userId;

  const GachaDrawMulti(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// 結果モーダルを閉じるイベント
class GachaResultClosed extends GachaEvent {
  const GachaResultClosed();
}