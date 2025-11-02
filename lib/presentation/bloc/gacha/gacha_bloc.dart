import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math';
import 'gacha_event.dart';
import 'gacha_state.dart';
import '../../../../domain/entities/monster.dart';

/// ガチャのBLoC
/// 
/// Day 3-4: 基本実装
/// - 初期化
/// - タイプ変更
/// - 単発/10連ガチャ実行
/// 
/// 注意: Week 6で実装したGachaServiceは Day 3-4 では未使用
///       仮データで動作確認を行います
class GachaBloc extends Bloc<GachaEvent, GachaState> {
  GachaBloc() : super(const GachaState()) {
    on<GachaInitialize>(_onInitialize);
    on<GachaTypeChanged>(_onTypeChanged);
    on<GachaDrawSingle>(_onDrawSingle);
    on<GachaDrawMulti>(_onDrawMulti);
    on<GachaResultClosed>(_onResultClosed);
  }

  /// 初期化処理
  Future<void> _onInitialize(
    GachaInitialize event,
    Emitter<GachaState> emit,
  ) async {
    try {
      // TODO: Firestoreからユーザーの通貨情報を取得
      // Week 7では仮データを使用
      
      emit(state.copyWith(
        status: GachaStatus.initial,
        freeGems: 1500,  // 仮データ
        paidGems: 0,
        tickets: 5,
        pityCount: 25,   // 仮データ
      ));
    } catch (e) {
      emit(state.copyWith(
        status: GachaStatus.failure,
        errorMessage: '初期化に失敗しました: $e',
      ));
    }
  }

  /// ガチャタイプ変更
  void _onTypeChanged(
    GachaTypeChanged event,
    Emitter<GachaState> emit,
  ) {
    emit(state.copyWith(
      selectedType: event.type,
    ));
  }

  /// 単発ガチャ実行
  Future<void> _onDrawSingle(
    GachaDrawSingle event,
    Emitter<GachaState> emit,
  ) async {
    // ローディング開始
    emit(state.copyWith(status: GachaStatus.loading));

    try {
      // 通貨チェック
      const cost = 150;
      if (state.freeGems < cost) {
        throw Exception('石が不足しています');
      }

      // TODO: Week 8以降で GachaService を使ってガチャ実行
      // final result = await _gachaService.drawSingle(userId: event.userId);
      
      // Week 7では仮データを使用
      await Future.delayed(const Duration(seconds: 1)); // 演出用の遅延
      
      // 仮のモンスター作成
      final result = _createDummyMonster();
      
      // TODO: Week 8以降で Firestoreに保存
      // - user_monstersコレクションに追加
      // - usersコレクションの通貨を減算
      // - gacha_pity_countersを更新
      
      // 成功状態に更新
      emit(state.copyWith(
        status: GachaStatus.success,
        results: [result],
        freeGems: state.freeGems - cost,
        pityCount: state.pityCount + 1,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: GachaStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  /// 10連ガチャ実行
  Future<void> _onDrawMulti(
    GachaDrawMulti event,
    Emitter<GachaState> emit,
  ) async {
    // ローディング開始
    emit(state.copyWith(status: GachaStatus.loading));

    try {
      // 通貨チェック
      const cost = 1500;
      if (state.freeGems < cost) {
        throw Exception('石が不足しています');
      }

      // TODO: Week 8以降で GachaService を使ってガチャ実行
      // final results = await _gachaService.drawMulti(userId: event.userId);
      
      // Week 7では仮データを使用
      await Future.delayed(const Duration(seconds: 2)); // 演出用の遅延
      
      // 仮のモンスター10体作成
      final results = List.generate(10, (index) => _createDummyMonster());
      
      // TODO: Week 8以降で Firestoreに保存
      
      // 成功状態に更新
      emit(state.copyWith(
        status: GachaStatus.success,
        results: results,
        freeGems: state.freeGems - cost,
        pityCount: state.pityCount + 10,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: GachaStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  /// 結果モーダルを閉じる
  void _onResultClosed(
    GachaResultClosed event,
    Emitter<GachaState> emit,
  ) {
    emit(state.copyWith(
      status: GachaStatus.initial,
      results: [],
    ));
  }

  /// ダミーモンスター作成(開発用)
  Monster _createDummyMonster() {
    final random = Random();
    
    // ランダムでレアリティを決定
    final randomValue = random.nextInt(100);
    final rarity = randomValue < 2 ? 5 : randomValue < 17 ? 4 : randomValue < 47 ? 3 : 2;
    
    // ランダムで種族と属性を決定
    final species = ['dragon', 'angel', 'demon', 'human', 'spirit', 'mechanoid', 'mutant'];
    final elements = ['fire', 'water', 'thunder', 'wind', 'earth', 'light', 'dark'];
    
    final randomSpecies = species[random.nextInt(species.length)];
    final randomElement = elements[random.nextInt(elements.length)];
    
    final now = DateTime.now();
    // 一意なIDを生成（マイクロ秒 + ランダム値）
    final uniqueId = 'dummy_${now.microsecondsSinceEpoch}_${random.nextInt(99999)}';
    
    return Monster(
      id: uniqueId,
      masterId: 'master_${random.nextInt(100).toString().padLeft(3, '0')}',
      userId: 'test_user',
      name: 'テストモンスター★$rarity',
      level: 1,
      exp: 0,
      species: randomSpecies,
      element: randomElement,
      rarity: rarity,
      hp: 100,
      maxHp: 100,
      attack: 50 + random.nextInt(20),
      defense: 40 + random.nextInt(20),
      magic: 30 + random.nextInt(20),
      speed: 60 + random.nextInt(20),
      ivHp: random.nextInt(11),
      ivAttack: random.nextInt(11),
      ivDefense: random.nextInt(11),
      ivMagic: random.nextInt(11),
      ivSpeed: random.nextInt(11),
      pointHp: 0,
      pointAttack: 0,
      pointDefense: 0,
      pointMagic: 0,
      pointSpeed: 0,
      remainingPoints: 0,
      skillIds: [],
      mainAbilityId: 'ability_${random.nextInt(100).toString().padLeft(3, '0')}',
      equipmentIds: [],
      acquiredAt: now,
    );
  }
}