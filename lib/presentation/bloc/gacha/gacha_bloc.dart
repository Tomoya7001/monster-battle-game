import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'gacha_event.dart';
import 'gacha_state.dart';
import '../../../core/services/gacha_service.dart';

class GachaBloc extends Bloc<GachaEvent, GachaState> {
  final GachaService _gachaService;
  final Random _random = Random();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // ✅ 追加

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
      final results = <Map<String, dynamic>>[];
      
      // ✅ 修正: モンスターを生成し、Firestoreに保存
      for (int i = 0; i < event.count; i++) {
        final monsterData = await _generateAndSaveMonster(
          event.gachaType,
          event.userId,
        );
        results.add(monsterData);
      }

      if (event.userId != null && event.userId!.isNotEmpty) {
        try {
          await _gachaService.addTickets(event.userId!, event.count);
        } catch (e) {
          print('チケット追加エラー: $e');
        }
      }

      final newGems = state.gems - cost;
      final newPityCount = state.pityCount + event.count;
      final newGachaTickets = state.gachaTickets + event.count;

      if (event.userId != null && event.userId!.isNotEmpty) {
        try {
          await _gachaService.saveGachaHistory(
            userId: event.userId!,
            gachaType: event.gachaType,
            pullCount: event.count,
            results: results,
            gemsUsed: cost,
            ticketsUsed: 0,
          );
        } catch (e) {
          print('ガチャ履歴保存エラー: $e');
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
      final ticketCount = await _gachaService.getTicketBalance(event.userId);

      emit(TicketBalanceLoaded(
        ticketCount: ticketCount,
        totalPulls: 0,
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

      final ticketBalance = await _gachaService.getTicketBalance(event.userId);

      emit(TicketExchangeSuccess(
        reward: reward,
        selectedType: state.selectedType,
        pityCount: state.pityCount,
        gems: state.gems,
        tickets: state.tickets,
        gachaTickets: ticketBalance,
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

  // ✅ 新規追加: モンスターを生成してFirestoreに保存
  Future<Map<String, dynamic>> _generateAndSaveMonster(
    String gachaType,
    String? userId,
  ) async {
    final rarity = _determineRarity(gachaType);
    
    // monster_mastersからランダムにマスターデータを取得
    final masterData = await _getRandomMonsterMaster(rarity);
    
    if (masterData == null || userId == null || userId.isEmpty) {
      // マスターデータがない場合は仮データを返す（保存なし）
      return _generateFallbackMonster(gachaType);
    }
    
    final masterId = masterData['id'] as String;
    final master = masterData['data'] as Map<String, dynamic>;
    
    // 個体値をランダム生成（-10〜+10）
    final ivHp = _random.nextInt(21) - 10;
    final ivAttack = _random.nextInt(21) - 10;
    final ivDefense = _random.nextInt(21) - 10;
    final ivMagic = _random.nextInt(21) - 10;
    final ivSpeed = _random.nextInt(21) - 10;
    
    // 基礎ステータス取得
    final baseStats = master['base_stats'] as Map<String, dynamic>? ?? {};
    final baseHp = (baseStats['hp'] as num?)?.toInt() ?? 100;
    
    // 成長率取得
    final growthData = master['growth'] as Map<String, dynamic>? ?? {};
    final growthHp = (growthData['hp'] as num?)?.toInt() ?? 0;
    
    // 初期HP計算（レベル1なのでレベルボーナスなし）
    final currentHp = baseHp + ivHp;
    
    // Firestoreに保存
    final now = FieldValue.serverTimestamp();
    final newDoc = _firestore.collection('user_monsters').doc();
    
    final monsterData = {
      'user_id': userId,
      'monster_id': masterId,
      'level': 1,
      'exp': 0,
      'current_hp': currentHp > 0 ? currentHp : 1,
      'last_hp_update': now,
      'intimacy_level': 1,
      'intimacy_exp': 0,
      'iv_hp': ivHp,
      'iv_attack': ivAttack,
      'iv_defense': ivDefense,
      'iv_magic': ivMagic,
      'iv_speed': ivSpeed,
      'point_hp': 0,
      'point_attack': 0,
      'point_defense': 0,
      'point_magic': 0,
      'point_speed': 0,
      'remaining_points': 0,
      'main_trait_id': null,
      'equipped_skills': <String>[],
      'equipped_equipment': <String>[],
      'skin_id': 1,
      'is_favorite': false,
      'is_locked': false,
      'acquired_at': now,
      'last_used_at': null,
      'created_at': now,
      'updated_at': now,
    };
    
    await newDoc.set(monsterData);
    
    // 表示用データを返す
    final monsterName = master['name'] as String? ?? '不明';
    final species = master['species'] as String? ?? 'human';
    final attributesData = master['attributes'];
    String element;
    if (attributesData is List && attributesData.isNotEmpty) {
      element = attributesData.first.toString();
    } else if (attributesData is String) {
      element = attributesData;
    } else {
      element = 'none';
    }
    final monsterRarity = master['rarity'] as int? ?? rarity;
    
    return {
      'id': newDoc.id,
      'name': monsterName,
      'rarity': monsterRarity,
      'race': _getSpeciesDisplayName(species),
      'element': _getElementDisplayName(element),
      'level': 1,
      'hp': currentHp > 0 ? currentHp : 1,
      'attack': (baseStats['attack'] as num?)?.toInt() ?? 50,
      'defense': (baseStats['defense'] as num?)?.toInt() ?? 50,
      'magic': (baseStats['magic'] as num?)?.toInt() ?? 50,
      'speed': (baseStats['speed'] as num?)?.toInt() ?? 50,
    };
  }
  
  // ✅ 新規追加: レアリティに基づいてランダムなモンスターマスターを取得
  Future<Map<String, dynamic>?> _getRandomMonsterMaster(int rarity) async {
    try {
      // 指定レアリティのモンスターを取得
      var query = _firestore
          .collection('monster_masters')
          .where('rarity', isEqualTo: rarity);
      
      final snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) {
        // 指定レアリティがない場合は全モンスターから取得
        final allSnapshot = await _firestore
            .collection('monster_masters')
            .limit(100)
            .get();
        
        if (allSnapshot.docs.isEmpty) return null;
        
        final randomIndex = _random.nextInt(allSnapshot.docs.length);
        final doc = allSnapshot.docs[randomIndex];
        return {
          'id': doc.id,
          'data': doc.data(),
        };
      }
      
      final randomIndex = _random.nextInt(snapshot.docs.length);
      final doc = snapshot.docs[randomIndex];
      return {
        'id': doc.id,
        'data': doc.data(),
      };
    } catch (e) {
      print('モンスターマスター取得エラー: $e');
      return null;
    }
  }
  
  // ✅ 新規追加: フォールバック用モンスターデータ
  Map<String, dynamic> _generateFallbackMonster(String gachaType) {
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
  
  // ✅ 新規追加: 種族表示名変換
  String _getSpeciesDisplayName(String species) {
    switch (species.toLowerCase()) {
      case 'angel':
        return 'エンジェル';
      case 'demon':
        return 'デーモン';
      case 'human':
        return 'ヒューマン';
      case 'spirit':
        return 'スピリット';
      case 'mechanoid':
        return 'メカノイド';
      case 'dragon':
        return 'ドラゴン';
      case 'mutant':
        return 'ミュータント';
      default:
        return '不明';
    }
  }
  
  // ✅ 新規追加: 属性表示名変換
  String _getElementDisplayName(String element) {
    switch (element.toLowerCase()) {
      case 'fire':
        return '炎';
      case 'water':
        return '水';
      case 'thunder':
        return '雷';
      case 'wind':
        return '風';
      case 'earth':
        return '大地';
      case 'light':
        return '光';
      case 'dark':
        return '闘';
      case 'none':
        return '無';
      default:
        return '不明';
    }
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