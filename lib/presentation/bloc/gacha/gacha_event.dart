import 'package:equatable/equatable.dart';

abstract class GachaEvent extends Equatable {
  const GachaEvent();

  @override
  List<Object?> get props => [];
}

class GachaInitialize extends GachaEvent {
  final String userId;

  const GachaInitialize(this.userId);

  @override
  List<Object?> get props => [userId];
}

class GachaTypeChanged extends GachaEvent {
  final GachaType type;

  const GachaTypeChanged(this.type);

  @override
  List<Object?> get props => [type];
}

class GachaDrawSingle extends GachaEvent {
  final String userId;

  const GachaDrawSingle(this.userId);

  @override
  List<Object?> get props => [userId];
}

class GachaDrawMulti extends GachaEvent {
  final String userId;

  const GachaDrawMulti(this.userId);

  @override
  List<Object?> get props => [userId];
}