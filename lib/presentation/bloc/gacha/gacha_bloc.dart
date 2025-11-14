import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'gacha_event.dart';
import 'gacha_state.dart';
import '../../../core/services/gacha_service.dart';

class GachaBloc extends Bloc<GachaEvent, GachaState> {
  final GachaService _gachaService;
  final Random _random = Random();

  GachaBloc({GachaService? gachaService})
      : _gachaService = gachaService ?? GachaService(),
        super(const GachaInitial()) {
    on<InitializeGacha>(_onInitialize);
    on<ExecuteGacha>(_onExecute);
    on<ChangeGachaType>(_onChangeType);
    on<ResetPityCounter>(_onResetPity);
    on<LoadTicketBalance>(_onLoadTicketBalance);
    on<ExchangeTickets>(_onExchangeTickets);
    on<LoadGachaHistory>(_onLoadGachaHistory);
  }

  Future<void> _onInitialize(
    InitializeGacha event,
    Emitter<GachaState> emit,
  ) async {
    emit(const GachaInitial());
  }

  Future<void> _onExecute(
    ExecuteGacha event,
    Emitter<GachaState> emit,
  ) async {
    emit(GachaLoading(
      selectedType: state.selectedType,
      pityCount: state.pityCount,
      gems: state.gems,
      tickets: state.tickets,
      gachaTickets: state.gachaTickets,
    ));

    final cost = event.count == 1 ? 150 : 1500;
    if (state.gems < cost) {
      emit(GachaError(
        error: '石が不足しています',
        selectedType: state.selectedType,
        pityCount: state.pityCount,
        gems: state.gems,
        tickets: state.tickets,
        gachaTickets: state.gachaTickets,
      ));
      return;
    }

    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final results = List.generate(event.count, (index) {
        return _generateRandomMonster(event.gachaType);
      });

      // ガチャチケット追加
      if (event.userId != null && event.userId!.isNotEmpty) {
        try {
          await _gachaService.addTickets(event.userId!, event.count);
        } catch (e) {
          print('チケット追加エラー: $e');
          // エラーが発生してもガチャ結果は返す（チケットは次回同期）
        }
      }

      final newGems = state.gems - cost;
      final newPityCount = state.pityCount + event.count;
      final newGachaTickets = state.gachaTickets + event.count;

      // ガチャ履歴を保存
      if (event.userId != null && event.userId!.isNotEmpty) {
        try {
          await _gachaService.saveGachaHistory(
            userId: event.userId!,
            gachaType: event.gachaType,
            pullCount: event.count,
            results: results,
            gemsUsed: cost,
            ticketsUsed: 0, // 現在は石のみ
          );
        } catch (e) {
          print('ガチャ履歴保存エラー: $e');
          // エラーが出てもガチャ結果は表示する
        }
      }

      emit(GachaLoaded(
        results: results,
        selectedType: state.selectedType,
        pityCount: newPityCount,
        gems: newGems,
        tickets: state.tickets,
        gachaTickets: newGachaTickets,
      ));
    } catch (e) {
      emit(GachaError(
        error: 'ガチャの実行に失敗しました: $e',
        selectedType: state.selectedType,
        pityCount: state.pityCount,
        gems: state.gems,
        tickets: state.tickets,
        gachaTickets: state.gachaTickets,
      ));
    }
  }

  Future<void> _onChangeType(
    ChangeGachaType event,
    Emitter<GachaState> emit,
  ) async {
    emit(GachaInitial(
      selectedType: event.gachaType,
      pityCount: state.pityCount,
      gems: state.gems,
      tickets: state.tickets,
      gachaTickets: state.gachaTickets,
    ));
  }

  Future<void> _onResetPity(
    ResetPityCounter event,
    Emitter<GachaState> emit,
  ) async {
    emit(GachaInitial(
      selectedType: state.selectedType,
      pityCount: 0,
      gems: state.gems,
      tickets: state.tickets,
      gachaTickets: state.gachaTickets,
    ));
  }

  Future<void> _onLoadTicketBalance(
    LoadTicketBalance event,
    Emitter<GachaState> emit,
  ) async {
    try {
      final ticketData = await _gachaService.getTicketBalance(event.userId);

      emit(TicketBalanceLoaded(
        ticketCount: ticketData.ticketCount,
        totalPulls: ticketData.totalPulls,
        selectedType: state.selectedType,
        pityCount: state.pityCount,
        gems: state.gems,
        tickets: state.tickets,
      ));
    } catch (e) {
      emit(GachaError(
        error: 'チケット残高の取得に失敗しました: $e',
        selectedType: state.selectedType,
        pityCount: state.pityCount,
        gems: state.gems,
        tickets: state.tickets,
        gachaTickets: state.gachaTickets,
      ));
    }
  }

  Future<void> _onExchangeTickets(
    ExchangeTickets event,
    Emitter<GachaState> emit,
  ) async {
    emit(GachaLoading(
      selectedType: state.selectedType,
      pityCount: state.pityCount,
      gems: state.gems,
      tickets: state.tickets,
      gachaTickets: state.gachaTickets,
    ));

    try {
      final reward = await _gachaService.exchangeTickets(
        userId: event.userId,
        optionId: event.optionId,
      );

      // チケット残高を再取得
      final ticketData = await _gachaService.getTicketBalance(event.userId);

      emit(TicketExchangeSuccess(
        reward: reward,
        selectedType: state.selectedType,
        pityCount: state.pityCount,
        gems: state.gems,
        tickets: state.tickets,
        gachaTickets: ticketData.ticketCount,
      ));
    } catch (e) {
      emit(GachaError(
        error: 'チケット交換に失敗しました: $e',
        selectedType: state.selectedType,
        pityCount: state.pityCount,
        gems: state.gems,
        tickets: state.tickets,
        gachaTickets: state.gachaTickets,
      ));
    }
  }

  Future<void> _onLoadGachaHistory(
    LoadGachaHistory event,
    Emitter<GachaState> emit,
  ) async {
    try {
      final history = await _gachaService.getGachaHistory(event.userId);

      emit(GachaHistoryLoaded(
        history: history,
        selectedType: state.selectedType,
        pityCount: state.pityCount,
        gems: state.gems,
        tickets: state.tickets,
        gachaTickets: state.gachaTickets,
      ));
    } catch (e) {
      emit(GachaError(
        error: 'ガチャ履歴の取得に失敗しました: $e',
        selectedType: state.selectedType,
        pityCount: state.pityCount,
        gems: state.gems,
        tickets: state.tickets,
        gachaTickets: state.gachaTickets,
      ));
    }
  }

  Map<String, dynamic> _generateRandomMonster(String gachaType) {
    int rarity = _determineRarity(gachaType);
    final races = ['エンジェル', 'デーモン', 'ヒューマン', 'スピリット', 'ミュータント', 'メカノイド', 'ドラゴン'];
    final elements = ['炎', '水', '雷', '風', '大地', '光', '闇'];

    final race = races[_random.nextInt(races.length)];
    final element = elements[_random.nextInt(elements.length)];

    return {
      'id': 'temp_${_random.nextInt(10000)}',
      'name': '$element の$race',
      'rarity': rarity,
      'race': race,
      'element': element,
      'level': 1,
      'hp': 100 + _random.nextInt(50),
      'attack': 50 + _random.nextInt(30),
      'defense': 40 + _random.nextInt(20),
      'magic': 45 + _random.nextInt(25),
      'speed': 60 + _random.nextInt(40),
    };
  }

  int _determineRarity(String gachaType) {
    final roll = _random.nextDouble() * 100;

    if (gachaType == 'プレミアム') {
      if (roll < 10) return 5;
      return 4;
    } else if (gachaType == 'ピックアップ') {
      if (roll < 5) return 5;
      if (roll < 20) return 4;
      if (roll < 50) return 3;
      return 2;
    } else {
      if (roll < 2) return 5;
      if (roll < 17) return 4;
      if (roll < 47) return 3;
      return 2;
    }
  }
}