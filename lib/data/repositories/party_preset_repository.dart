import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/party/party_preset_v2.dart';

class PartyPresetRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'party_presets';

  /// プリセット保存（ドキュメントIDを予測可能に）
  Future<void> savePreset(PartyPresetV2 preset) async {
    // ★修正: ドキュメントIDを予測可能にする
    final docId = '${preset.userId}_${preset.battleType}_${preset.presetNumber}';
    
    await _firestore
        .collection(_collectionPath)
        .doc(docId)
        .set(preset.toJson(), SetOptions(merge: true));
  }

  /// ユーザーの全プリセット取得
    Future<List<PartyPresetV2>> getUserPresets(
    String userId,
    String battleType,
    ) async {
    // ★追加: 初回取得時に古いドキュメントをクリーンアップ
    await cleanupOldPresets(userId, battleType);

    final snapshot = await _firestore
        .collection(_collectionPath)
        .where('user_id', isEqualTo: userId)
        .get();

    final presets = snapshot.docs
        .map((doc) => PartyPresetV2.fromJson({...doc.data(), 'id': doc.id}))
        .where((preset) => preset.battleType == battleType)
        .toList();

    presets.sort((a, b) => a.presetNumber.compareTo(b.presetNumber));

    return presets;
    }

  /// アクティブなプリセット取得
  Future<PartyPresetV2?> getActivePreset(
    String userId,
    String battleType,
  ) async {
    // ★修正: クエリを単純化
    final snapshot = await _firestore
        .collection(_collectionPath)
        .where('user_id', isEqualTo: userId)
        .get();

    // ★追加: クライアント側フィルタリング
    final activePresets = snapshot.docs
        .map((doc) => PartyPresetV2.fromJson({...doc.data(), 'id': doc.id}))
        .where((preset) => 
            preset.battleType == battleType && 
            preset.isActive)
        .toList();

    return activePresets.isNotEmpty ? activePresets.first : null;
  }

  /// アクティブプリセット設定
  Future<void> setActivePreset(
    String userId,
    String battleType,
    String presetId,
  ) async {
    // ★修正: クエリを単純化
    final snapshot = await _firestore
        .collection(_collectionPath)
        .where('user_id', isEqualTo: userId)
        .get();

    final batch = _firestore.batch();
    
    // ★追加: クライアント側フィルタリング
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['battle_type'] == battleType) {
        if (doc.id == presetId) {
          batch.update(doc.reference, {'is_active': true});
        } else {
          batch.update(doc.reference, {'is_active': false});
        }
      }
    }

    await batch.commit();
  }

  /// プリセット削除
  Future<void> deletePreset(String presetId) async {
    await _firestore.collection(_collectionPath).doc(presetId).delete();
  }

  /// プリセット名変更
  Future<void> updatePresetName(String presetId, String newName) async {
    await _firestore.collection(_collectionPath).doc(presetId).update({
      'name': newName,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// 古い形式のドキュメントを削除
    Future<void> cleanupOldPresets(String userId, String battleType) async {
    final snapshot = await _firestore
        .collection(_collectionPath)
        .where('user_id', isEqualTo: userId)
        .get();

    final batch = _firestore.batch();
    
    for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['battle_type'] == battleType) {
        final presetNumber = data['preset_number'] as int;
        final expectedId = '${userId}_${battleType}_$presetNumber';
        
        // 古い形式のID（ランダムなID）を削除
        if (doc.id != expectedId) {
            batch.delete(doc.reference);
        }
        }
    }

    await batch.commit();
    }
}