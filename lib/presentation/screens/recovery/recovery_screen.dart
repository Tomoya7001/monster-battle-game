import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/monster.dart';
import '../../../data/repositories/monster_repository_impl.dart';

/// 回復タブ（モンスターセンター）
class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({Key? key}) : super(key: key);

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  final MonsterRepositoryImpl _monsterRepo = MonsterRepositoryImpl(FirebaseFirestore.instance);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Monster> _monsters = [];
  bool _isLoading = true;
  
  // 回復状況
  DateTime? _lastFreeRecovery;
  int _adRecoveryCount = 0;
  DateTime? _lastAdRecoveryDate;
  
  static const int freeRecoveryCooldownHours = 8;
  static const int maxAdRecoveryPerDay = 5;
  static const int stoneRecoveryCost = 100;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      const userId = 'dev_user_12345';
      
      // モンスター一覧取得（正しいメソッド名）
      final monsters = await _monsterRepo.getMonsters(userId);
      _monsters = monsters;
      
      // 回復状況取得
      await _loadRecoveryStatus(userId);
    } catch (e) {
      print('❌ データ読み込みエラー: $e');
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadRecoveryStatus(String userId) async {
    try {
      final doc = await _firestore
          .collection('user_recovery_status')
          .doc(userId)
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        _lastFreeRecovery = (data['last_free_recovery'] as Timestamp?)?.toDate();
        _adRecoveryCount = data['ad_recovery_count'] as int? ?? 0;
        _lastAdRecoveryDate = (data['last_ad_recovery_date'] as Timestamp?)?.toDate();
        
        // 日付が変わっていたら広告回数リセット
        if (_lastAdRecoveryDate != null) {
          final now = DateTime.now();
          if (_lastAdRecoveryDate!.day != now.day ||
              _lastAdRecoveryDate!.month != now.month ||
              _lastAdRecoveryDate!.year != now.year) {
            _adRecoveryCount = 0;
          }
        }
      }
    } catch (e) {
      print('❌ 回復状況読み込みエラー: $e');
    }
  }

  Future<void> _saveRecoveryStatus(String type) async {
    try {
      const userId = 'dev_user_12345';
      final now = DateTime.now();
      
      final updates = <String, dynamic>{
        'user_id': userId,
        'updated_at': FieldValue.serverTimestamp(),
      };
      
      if (type == 'free') {
        updates['last_free_recovery'] = Timestamp.fromDate(now);
        _lastFreeRecovery = now;
      } else if (type == 'ad') {
        updates['ad_recovery_count'] = _adRecoveryCount + 1;
        updates['last_ad_recovery_date'] = Timestamp.fromDate(now);
        _adRecoveryCount++;
        _lastAdRecoveryDate = now;
      }
      
      await _firestore
          .collection('user_recovery_status')
          .doc(userId)
          .set(updates, SetOptions(merge: true));
    } catch (e) {
      print('❌ 回復状況保存エラー: $e');
    }
  }

  bool get _canUseFreeRecovery {
    if (_lastFreeRecovery == null) return true;
    final elapsed = DateTime.now().difference(_lastFreeRecovery!);
    return elapsed.inHours >= freeRecoveryCooldownHours;
  }

  String get _freeRecoveryCooldownText {
    if (_lastFreeRecovery == null) return '';
    final elapsed = DateTime.now().difference(_lastFreeRecovery!);
    final remaining = Duration(hours: freeRecoveryCooldownHours) - elapsed;
    if (remaining.isNegative) return '';
    
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    return 'あと ${hours}時間${minutes}分';
  }

  bool get _canUseAdRecovery {
    return _adRecoveryCount < maxAdRecoveryPerDay;
  }

  int get _monstersNeedingRecovery {
    return _monsters.where((m) => m.currentHp < m.maxHp).length;
  }

  int get _faintedMonsterCount {
    return _monsters.where((m) => m.currentHp <= 0).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('モンスターセンター'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatusCard(),
                    const SizedBox(height: 16),
                    _buildRecoveryOptions(),
                    const SizedBox(height: 16),
                    _buildMonsterList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.local_hospital, size: 48, color: Colors.green),
            const SizedBox(height: 8),
            const Text(
              'モンスターセンター',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              '全モンスターのHPを回復します',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatusItem(
                  icon: Icons.pets,
                  label: '所持数',
                  value: '${_monsters.length}体',
                  color: Colors.blue,
                ),
                _buildStatusItem(
                  icon: Icons.healing,
                  label: '回復必要',
                  value: '$_monstersNeedingRecovery体',
                  color: Colors.orange,
                ),
                _buildStatusItem(
                  icon: Icons.heart_broken,
                  label: '瀕死',
                  value: '$_faintedMonsterCount体',
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildRecoveryOptions() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '回復方法',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // 無料回復（8時間に1回）
            _buildRecoveryButton(
              icon: Icons.favorite,
              title: '無料回復',
              subtitle: _canUseFreeRecovery 
                  ? '全モンスターを全回復' 
                  : _freeRecoveryCooldownText,
              buttonText: '回復する',
              color: Colors.green,
              enabled: _canUseFreeRecovery && _monstersNeedingRecovery > 0,
              onPressed: () => _performRecovery('free'),
            ),
            const SizedBox(height: 12),
            
            // 広告視聴回復（1日5回）
            _buildRecoveryButton(
              icon: Icons.play_circle_fill,
              title: '広告を見て回復',
              subtitle: '残り ${maxAdRecoveryPerDay - _adRecoveryCount}回/日',
              buttonText: '広告を見る',
              color: Colors.blue,
              enabled: _canUseAdRecovery && _monstersNeedingRecovery > 0,
              onPressed: () => _performRecovery('ad'),
            ),
            const SizedBox(height: 12),
            
            // 石で回復（無制限）
            _buildRecoveryButton(
              icon: Icons.diamond,
              title: '石で回復',
              subtitle: '$stoneRecoveryCost石で即時回復',
              buttonText: '${stoneRecoveryCost}石',
              color: Colors.purple,
              enabled: _monstersNeedingRecovery > 0,
              onPressed: () => _confirmStoneRecovery(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecoveryButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required Color color,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: enabled ? color.withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? color.withOpacity(0.3) : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: enabled ? color : Colors.grey, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: enabled ? Colors.black : Colors.grey,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: enabled ? Colors.grey.shade600 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: enabled ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  Widget _buildMonsterList() {
    final sortedMonsters = List<Monster>.from(_monsters)
      ..sort((a, b) {
        // 瀕死 → HP低い順
        if (a.currentHp <= 0 && b.currentHp > 0) return -1;
        if (a.currentHp > 0 && b.currentHp <= 0) return 1;
        return a.hpPercentage.compareTo(b.hpPercentage);
      });
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'モンスター状態',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            if (sortedMonsters.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('モンスターがいません', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...sortedMonsters.map((monster) => _buildMonsterRow(monster)),
          ],
        ),
      ),
    );
  }

  Widget _buildMonsterRow(Monster monster) {
    final hpPercent = monster.hpPercentage;
    final isFainted = monster.currentHp <= 0;
    final needsRecovery = monster.currentHp < monster.maxHp;
    
    Color hpColor;
    if (isFainted) {
      hpColor = Colors.grey;
    } else if (hpPercent > 0.5) {
      hpColor = Colors.green;
    } else if (hpPercent > 0.2) {
      hpColor = Colors.orange;
    } else {
      hpColor = Colors.red;
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isFainted ? Colors.red.shade50 : (needsRecovery ? Colors.orange.shade50 : Colors.green.shade50),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // レアリティ表示
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getRarityColor(monster.rarity),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                monster.monsterName.substring(0, 1),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      monster.monsterName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isFainted ? Colors.grey : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (isFainted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '瀕死',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: hpPercent,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(hpColor),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${monster.currentHp}/${monster.maxHp}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRarityColor(int rarity) {
    switch (rarity) {
      case 5: return Colors.amber;
      case 4: return Colors.purple;
      case 3: return Colors.blue;
      default: return Colors.grey;
    }
  }

  Future<void> _performRecovery(String type) async {
    if (_monstersNeedingRecovery == 0) {
      _showSnackBar('回復が必要なモンスターがいません');
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // 全モンスターのHPを全回復
      final hpUpdates = <String, int>{};
      for (final monster in _monsters) {
        if (monster.currentHp < monster.maxHp) {
          hpUpdates[monster.id] = monster.maxHp;
        }
      }
      
      if (hpUpdates.isNotEmpty) {
        await _monsterRepo.updateMonstersHp(hpUpdates);
      }
      
      // 回復状況を保存
      await _saveRecoveryStatus(type);
      
      // データ再読み込み
      await _loadData();
      
      _showSnackBar('全モンスターを回復しました！', isSuccess: true);
    } catch (e) {
      print('❌ 回復エラー: $e');
      _showSnackBar('回復に失敗しました');
    }
    
    setState(() => _isLoading = false);
  }

  void _confirmStoneRecovery() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('石で回復'),
        content: Text('$stoneRecoveryCost石を消費して全モンスターを回復しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performStoneRecovery();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text('回復する'),
          ),
        ],
      ),
    );
  }

  Future<void> _performStoneRecovery() async {
    setState(() => _isLoading = true);
    
    try {
      const userId = 'dev_user_12345';
      
      // 石の残高確認
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final currentStone = userDoc.data()?['stone'] as int? ?? 0;
      
      if (currentStone < stoneRecoveryCost) {
        _showSnackBar('石が足りません（所持: $currentStone石）');
        setState(() => _isLoading = false);
        return;
      }
      
      // 石を消費
      await _firestore.collection('users').doc(userId).update({
        'stone': currentStone - stoneRecoveryCost,
      });
      
      // 回復実行
      final hpUpdates = <String, int>{};
      for (final monster in _monsters) {
        if (monster.currentHp < monster.maxHp) {
          hpUpdates[monster.id] = monster.maxHp;
        }
      }
      
      if (hpUpdates.isNotEmpty) {
        await _monsterRepo.updateMonstersHp(hpUpdates);
      }
      
      await _loadData();
      
      _showSnackBar('全モンスターを回復しました！', isSuccess: true);
    } catch (e) {
      print('❌ 石回復エラー: $e');
      _showSnackBar('回復に失敗しました');
    }
    
    setState(() => _isLoading = false);
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }
}