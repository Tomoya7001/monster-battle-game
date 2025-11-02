import 'package:equatable/equatable.dart';
import '../../../../domain/entities/monster.dart';
import '../../screens/gacha/widgets/gacha_tabs.dart';

/// ガチャの状態
enum GachaStatus {
  initial,   // 初期状態
  loading,   // ローディング中(ガチャ実行中)
  success,   // 成功(結果表示)
  failure,   // 失敗(エラー)
}

/// ガチャの状態管理
class GachaState extends Equatable {
  final GachaStatus status;
  final GachaType selectedType;
  final int freeGems;      // 無償石
  final int paidGems;      // 有償石
  final int tickets;       // ガチャチケット
  final int pityCount;     // 天井カウント
  final List<Monster> results; // ガチャ結果
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

  /// 状態をコピーして更新
  GachaState copyWith({
    GachaStatus? status,
    GachaType? selectedType,
    int? freeGems,
    int? paidGems,
    int? tickets,
    int? pityCount,
    List<Monster>? results,
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
      errorMessage: errorMessage,
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