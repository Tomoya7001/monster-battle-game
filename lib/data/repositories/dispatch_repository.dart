// lib/data/repositories/dispatch_repository.dart

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/dispatch.dart';
import '../../domain/entities/monster.dart';

/// 探索リポジトリ
class DispatchRepository {
  final FirebaseFirestore _firestore;
  Map<String, DispatchLocation>? _locationMasterCache;
  
  /// 探索枠解放コスト
  static const int slotUnlockCost = 500;
  
  /// 最大探索枠数
  static const int maxSlots = 3;

  DispatchRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ========== マスターデータ ==========

  /// 探索先マスター全取得（キャッシュ付き）
  Future<Map<String, DispatchLocation>> getLocationMasters() async {
    if (_locationMasterCache != null) return _locationMasterCache!;

    final snapshot = await _firestore.collection('dispatch_locations').get();

    _locationMasterCache = {};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      data['location_id'] = doc.id;
      _locationMasterCache![doc.id] = DispatchLocation.fromJson(data);
    }

    return _locationMasterCache!;
  }

  /// 探索先マスター単体取得
  Future<DispatchLocation?> getLocationMaster(String locationId) async {
    final masters = await getLocationMasters();
    return masters[locationId];
  }

  /// 解放済み探索先一覧取得
  Future<List<DispatchLocation>> getUnlockedLocations(String userId) async {
    final allLocations = await getLocationMasters();
    final unlockedLocations = <DispatchLocation>[];

    for (final location in allLocations.values) {
      if (!location.isActive) continue;

      final isUnlocked = await _checkLocationUnlocked(userId, location);
      if (isUnlocked) {
        unlockedLocations.add(location);
      }
    }

    unlockedLocations.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return unlockedLocations;
  }

  /// 探索先解放チェック
  Future<bool> _checkLocationUnlocked(
    String userId,
    DispatchLocation location,
  ) async {
    final condition = location.unlockCondition;

    if (condition.type == 'none') return true;

    if (condition.isBossClear && condition.stageId != null) {
      // ボスクリア条件: user_adventure_progressのboss_defeatedを確認
      final progressDoc = await _firestore
          .collection('user_adventure_progress')
          .doc('${userId}_${condition.stageId}')
          .get();

      if (!progressDoc.exists) return false;

      final data = progressDoc.data()!;
      return data['boss_defeated'] as bool? ?? false;
    }

    return false;
  }

  // ========== ユーザー探索設定 ==========

  /// ユーザー探索設定取得
  Future<UserDispatchSettings> getUserSettings(String userId) async {
    final doc = await _firestore
        .collection('user_dispatch_settings')
        .doc(userId)
        .get();

    if (!doc.exists) {
      // 初期設定を作成
      final settings = UserDispatchSettings(userId: userId, unlockedSlots: 1);
      await _firestore
          .collection('user_dispatch_settings')
          .doc(userId)
          .set(settings.toJson());
      return settings;
    }

    return UserDispatchSettings.fromJson(doc.data()!);
  }

  /// 探索枠解放
  Future<bool> unlockSlot(String userId, int slotIndex) async {
    if (slotIndex < 2 || slotIndex > maxSlots) return false;

    final settings = await getUserSettings(userId);

    // 既に解放済み
    if (settings.isSlotUnlocked(slotIndex)) return true;

    // 順番に解放する必要がある
    if (slotIndex > settings.unlockedSlots + 1) return false;

    // 石消費チェック（ここでは確認のみ、実際の消費は呼び出し側で行う）
    await _firestore
        .collection('user_dispatch_settings')
        .doc(userId)
        .update({
          'unlocked_slots': slotIndex,
          'last_updated': FieldValue.serverTimestamp(),
        });

    return true;
  }

  // ========== 探索操作 ==========

  /// 進行中の探索一覧取得
  Future<List<UserDispatch>> getActiveDispatches(String userId) async {
    final snapshot = await _firestore
        .collection('user_dispatches')
        .where('user_id', isEqualTo: userId)
        .where('status', whereIn: ['in_progress', 'completed'])
        .get();

    final dispatches = snapshot.docs
        .map((doc) => UserDispatch.fromJson(doc.data(), doc.id))
        .toList();

    // 時間経過で完了したものはステータスを更新
    for (final dispatch in dispatches) {
      if (dispatch.status == DispatchStatus.inProgress && dispatch.isTimeCompleted) {
        await _updateDispatchStatus(dispatch.id, DispatchStatus.completed);
      }
    }

    // 再取得
    final updatedSnapshot = await _firestore
        .collection('user_dispatches')
        .where('user_id', isEqualTo: userId)
        .where('status', whereIn: ['in_progress', 'completed'])
        .get();

    return updatedSnapshot.docs
        .map((doc) => UserDispatch.fromJson(doc.data(), doc.id))
        .toList()
      ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
  }

  /// 探索開始
  Future<UserDispatch?> startDispatch({
    required String userId,
    required int slotIndex,
    required String locationId,
    required int durationHours,
    required List<String> monsterIds,
  }) async {
    // 探索先存在確認
    final location = await getLocationMaster(locationId);
    if (location == null) {
      print('❌ 探索先が見つかりません: $locationId');
      return null;
    }

    // 枠が解放されているか確認
    final settings = await getUserSettings(userId);
    if (!settings.isSlotUnlocked(slotIndex)) {
      print('❌ 枠が解放されていません: $slotIndex');
      return null;
    }

    // 既にその枠で探索中でないか確認
    final existingDispatches = await getActiveDispatches(userId);
    final slotInUse = existingDispatches.any((d) => d.slotIndex == slotIndex);
    if (slotInUse) {
      print('❌ 枠 $slotIndex は既に使用中です');
      return null;
    }

    // 探索データ作成
    final now = DateTime.now();
    final completedAt = now.add(Duration(hours: durationHours));

    final dispatchData = {
      'user_id': userId,
      'slot_index': slotIndex,
      'location_id': locationId,
      'duration_hours': durationHours,
      'monster_ids': monsterIds,
      'status': 'in_progress',
      'started_at': Timestamp.fromDate(now),
      'completed_at': Timestamp.fromDate(completedAt),
      'claimed_at': null,
      'rewards': null,
    };

    final docRef = await _firestore.collection('user_dispatches').add(dispatchData);

    print('✅ 探索開始: ${docRef.id}');

    return UserDispatch.fromJson(dispatchData, docRef.id);
  }

  /// 探索ステータス更新
  Future<void> _updateDispatchStatus(String dispatchId, DispatchStatus status) async {
    await _firestore.collection('user_dispatches').doc(dispatchId).update({
      'status': status == DispatchStatus.inProgress
          ? 'in_progress'
          : status == DispatchStatus.completed
              ? 'completed'
              : 'claimed',
    });
  }

  /// 報酬受取
  Future<List<DispatchRewardResult>?> claimReward(String dispatchId) async {
    final doc = await _firestore.collection('user_dispatches').doc(dispatchId).get();
    if (!doc.exists) return null;

    final dispatch = UserDispatch.fromJson(doc.data()!, dispatchId);

    // 既に受取済み
    if (dispatch.status == DispatchStatus.claimed) {
      return dispatch.rewards;
    }

    // まだ完了していない
    if (!dispatch.isTimeCompleted) {
      print('❌ 探索がまだ完了していません');
      return null;
    }

    // 報酬を計算
    final location = await getLocationMaster(dispatch.locationId);
    if (location == null) return null;

    final option = location.dispatchOptions
        .where((o) => o.durationHours == dispatch.durationHours)
        .firstOrNull;
    if (option == null) return null;

    final rewards = _calculateRewards(option);

    // 報酬を付与
    final claimUserId = dispatch.userId;
    for (final reward in rewards) {
      await _addMaterial(claimUserId, reward.materialId, reward.quantity);
    }

    // 経験値をモンスターに付与
    for (final monsterId in dispatch.monsterIds) {
      await _addMonsterExp(claimUserId, monsterId, option.baseExp);
    }

    // ステータス更新
    await _firestore.collection('user_dispatches').doc(dispatchId).update({
      'status': 'claimed',
      'claimed_at': FieldValue.serverTimestamp(),
      'rewards': rewards.map((r) => r.toJson()).toList(),
    });

    print('✅ 報酬受取完了: $dispatchId');

    return rewards;
  }

  /// 報酬計算
  List<DispatchRewardResult> _calculateRewards(DispatchOption option) {
    final random = Random();
    final results = <DispatchRewardResult>[];

    for (final reward in option.rewards) {
      // 確率判定
      final roll = random.nextInt(100);
      if (roll >= reward.rate) continue;

      // 数量決定
      final quantity = reward.minQty +
          random.nextInt(reward.maxQty - reward.minQty + 1);

      results.add(DispatchRewardResult(
        materialId: reward.materialId,
        quantity: quantity,
      ));
    }

    return results;
  }

  /// 素材追加（内部用）
  Future<void> _addMaterial(String userId, String materialId, int quantity) async {
    final docId = '${userId}_$materialId';
    final docRef = _firestore.collection('user_materials').doc(docId);

    final doc = await docRef.get();

    if (doc.exists) {
      final currentQty = doc.data()!['quantity'] as int? ?? 0;
      await docRef.update({
        'quantity': currentQty + quantity,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } else {
      await docRef.set({
        'user_id': userId,
        'material_id': materialId,
        'quantity': quantity,
        'acquired_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    }
  }

  /// モンスター経験値追加
  Future<void> _addMonsterExp(String userId, String monsterId, int exp) async {
    try {
      final doc = await _firestore
          .collection('user_monsters')
          .doc(monsterId)
          .get();

      if (!doc.exists) return;

      final data = doc.data()!;
      final currentExp = data['exp'] as int? ?? 0;

      await _firestore.collection('user_monsters').doc(monsterId).update({
        'exp': currentExp + exp,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ モンスター経験値追加エラー: $e');
    }
  }

  /// 探索キャンセル（開始直後のみ可能にする場合）
  Future<bool> cancelDispatch(String dispatchId) async {
    final doc = await _firestore.collection('user_dispatches').doc(dispatchId).get();
    if (!doc.exists) return false;

    final dispatch = UserDispatch.fromJson(doc.data()!, dispatchId);

    // 完了済みはキャンセル不可
    if (dispatch.isTimeCompleted) return false;

    // 開始から5分以内のみキャンセル可能
    final elapsed = DateTime.now().difference(dispatch.startedAt);
    if (elapsed.inMinutes > 5) return false;

    await _firestore.collection('user_dispatches').doc(dispatchId).delete();
    return true;
  }

  /// 派遣中のモンスターID一覧取得
  Future<Set<String>> getDispatchedMonsterIds(String userId) async {
    final dispatches = await getActiveDispatches(userId);
    final monsterIds = <String>{};

    for (final dispatch in dispatches) {
      monsterIds.addAll(dispatch.monsterIds);
    }

    return monsterIds;
  }

  /// モンスターが派遣中かどうか
  Future<bool> isMonsterDispatched(String userId, String monsterId) async {
    final dispatchedIds = await getDispatchedMonsterIds(userId);
    return dispatchedIds.contains(monsterId);
  }

  /// キャッシュクリア
  void clearCache() {
    _locationMasterCache = null;
  }
}