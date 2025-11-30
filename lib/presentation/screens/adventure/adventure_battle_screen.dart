import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/monster.dart';
import '../../../domain/models/stage/stage_data.dart';
import '../../../data/repositories/adventure_repository.dart';
import '../../../data/repositories/monster_repository_impl.dart';
import '../battle/battle_screen.dart';
import '../../bloc/item/item_bloc.dart';
import '../../bloc/item/item_event.dart';
import '../../bloc/item/item_state.dart';
import '../item/widgets/use_item_dialog.dart';
import '../../../domain/entities/item.dart';
import '../../../data/repositories/item_repository.dart';
import '../../../core/services/item_service.dart';

/// 冒険バトル画面（連続エンカウント管理）
class AdventureBattleScreen extends StatefulWidget {
  final List<Monster> party;
  final StageData stage;
  final int? autoLoopCount;

  const AdventureBattleScreen({
    Key? key,
    required this.party,
    required this.stage,
    this.autoLoopCount,
  }) : super(key: key);

  @override
  State<AdventureBattleScreen> createState() => _AdventureBattleScreenState();
}

class _AdventureBattleScreenState extends State<AdventureBattleScreen> {
  final AdventureRepository _adventureRepo = AdventureRepository();
  final MonsterRepositoryImpl _monsterRepo = MonsterRepositoryImpl(FirebaseFirestore.instance);
  
  int _currentEncounter = 0;
  int _totalEncounters = 5;
  bool _bossUnlocked = false;
  bool _isLoading = true;
  bool _isBattling = false;
  int _currentLoopCount = 0;
  int _totalDefeatedCount = 0;
  bool _isAutoMode = false;
  int _autoLoopTarget = 0;
  
  List<Monster> _currentParty = [];
  
  // 獲得報酬
  int _totalExp = 0;
  int _totalGold = 0;
  final List<String> _obtainedItems = [];
  final Map<String, int> _obtainedItemCounts = {}; 

  @override
  void initState() {
    super.initState();
    _currentParty = List.from(widget.party);
    _totalEncounters = widget.stage.encountersToBoss ?? 5;
    
    // AUTO周回モードの初期化
    if (widget.autoLoopCount != null) {
      _isAutoMode = true;
      _autoLoopTarget = widget.autoLoopCount!;
    }
    
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);
    
    try {
      const userId = 'dev_user_12345';
      final progress = await _adventureRepo.getProgress(userId, widget.stage.stageId);
      
      if (progress != null) {
        _currentEncounter = progress.encounterCount;
        _bossUnlocked = progress.bossUnlocked;
      }
      
      // パーティのHP状態を最新化
      await _refreshPartyHp();
    } catch (e) {
      print('❌ 進行状況読み込みエラー: $e');
    }
    
    setState(() => _isLoading = false);
    
    // AUTO周回モードなら自動開始
    if (_isAutoMode && _canBattle) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted && _isAutoMode) {
        _startEncounterBattle();
      }
    }
  }

  Future<void> _refreshPartyHp() async {
    try {
      final updatedParty = <Monster>[];
      for (final monster in _currentParty) {
        final updated = await _monsterRepo.getMonster(monster.id);
        if (updated != null) {
          updatedParty.add(updated);
        } else {
          updatedParty.add(monster);
        }
      }
      setState(() {
        _currentParty = updatedParty;
      });
    } catch (e) {
      print('❌ パーティHP更新エラー: $e');
    }
  }

  bool get _canBattle {
    final availableCount = _currentParty.where((m) => m.currentHp > 0).length;
    return availableCount >= 3;
  }

  int get _availableMonsterCount {
    return _currentParty.where((m) => m.currentHp > 0).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stage.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _showExitConfirmDialog(),
        ),
        actions: [
          if (_isAutoMode)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.repeat, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    'AUTO $_currentLoopCount/$_autoLoopTarget',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProgressCard(),
          const SizedBox(height: 16),
          _buildPartyStatusCard(),
          const SizedBox(height: 16),
          _buildRewardsCard(),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final displayEncounter = _currentEncounter.clamp(0, _totalEncounters);
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '進行状況',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_bossUnlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text('BOSS解放', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // エンカウント進行バー
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: displayEncounter / _totalEncounters,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _bossUnlocked ? Colors.purple : Colors.blue,
                      ),
                      minHeight: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$displayEncounter / $_totalEncounters',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // エンカウントアイコン
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_totalEncounters, (index) {
                final isCompleted = index < _currentEncounter;
                final isCurrent = index == _currentEncounter && !_bossUnlocked;
                
                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green
                        : isCurrent
                            ? Colors.orange
                            : Colors.grey.shade300,
                    shape: BoxShape.circle,
                    border: isCurrent
                        ? Border.all(color: Colors.orange.shade700, width: 3)
                        : null,
                  ),
                  child: Icon(
                    isCompleted ? Icons.check : Icons.pets,
                    color: isCompleted || isCurrent ? Colors.white : Colors.grey,
                    size: 20,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartyStatusCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'パーティ状態',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '戦闘可能: $_availableMonsterCount / ${_currentParty.length}',
                  style: TextStyle(
                    color: _canBattle ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            ..._currentParty.map((monster) => _buildMonsterStatusRow(monster)),
            
            if (!_canBattle) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '戦闘可能なモンスターが3体未満です。\n回復してから再挑戦してください。',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMonsterStatusRow(Monster monster) {
    final hpPercent = monster.hpPercentage;
    final isFainted = monster.currentHp <= 0;
    
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
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isFainted ? Colors.grey : Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                monster.monsterName.substring(0, 1),
                style: TextStyle(
                  color: isFainted ? Colors.white : Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monster.monsterName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isFainted ? Colors.grey : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: hpPercent,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(hpColor),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          
          Text(
            isFainted ? '瀕死' : '${monster.currentHp}/${monster.maxHp}',
            style: TextStyle(
              fontSize: 12,
              color: isFainted ? Colors.red : Colors.grey.shade600,
              fontWeight: isFainted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsCard() {
    if (_totalExp == 0 && _totalGold == 0 && _obtainedItems.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      elevation: 4,
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '獲得報酬',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (_totalExp > 0) ...[
                  const Icon(Icons.star, color: Colors.orange, size: 20),
                  const SizedBox(width: 4),
                  Text('EXP: $_totalExp'),
                  const SizedBox(width: 16),
                ],
                if (_totalGold > 0) ...[
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text('$_totalGold G'),
                ],
              ],
            ),
            if (_totalDefeatedCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                '撃破数: $_totalDefeatedCount体',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ボス戦ボタン（ボス解放時のみ、単独で大きく）
        if (_bossUnlocked) ...[
          ElevatedButton.icon(
            onPressed: _canBattle && !_isBattling ? _startBossBattle : null,
            icon: Icon(_isBattling ? Icons.hourglass_empty : Icons.shield),
            label: Text(_isBattling ? 'バトル中...' : 'ボスに挑戦'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          
          // 冒険を続ける + AUTO（横並び）
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: _canBattle && !_isBattling ? _startEncounterBattle : null,
                  icon: const Icon(Icons.explore, size: 20),
                  label: const Text('冒険を続ける'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _isAutoMode
                    ? ElevatedButton.icon(
                        onPressed: _stopAutoLoop,
                        icon: const Icon(Icons.stop, size: 20),
                        label: Text('$_currentLoopCount/$_autoLoopTarget'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _canBattle && !_isBattling ? _showAutoLoopDialog : null,
                        icon: const Icon(Icons.repeat, size: 20),
                        label: const Text('AUTO'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
              ),
            ],
          ),
        ],
        
        // 通常エンカウント時（ボス未解放）
        if (!_bossUnlocked) ...[
          // 次のバトルへ + AUTO（横並び）
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: _canBattle && !_isBattling ? _startEncounterBattle : null,
                  icon: Icon(_isBattling ? Icons.hourglass_empty : Icons.play_arrow, size: 20),
                  label: Text(_isBattling ? 'バトル中...' : '次のバトルへ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _isAutoMode
                    ? ElevatedButton.icon(
                        onPressed: _stopAutoLoop,
                        icon: const Icon(Icons.stop, size: 20),
                        label: Text('$_currentLoopCount/$_autoLoopTarget'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _canBattle && !_isBattling ? _showAutoLoopDialog : null,
                        icon: const Icon(Icons.repeat, size: 20),
                        label: const Text('AUTO'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
              ),
            ],
          ),
        ],
        
        const SizedBox(height: 12),
        
        // HP回復ボタン
        ElevatedButton.icon(
          onPressed: () => _showRecoveryOptionDialog(),
          icon: const Icon(Icons.local_hospital),
          label: const Text('HP回復'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade400,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  /// AUTO周回開始ダイアログ
  void _showAutoLoopDialog() {
    int selectedCount = 5;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.repeat, color: Colors.orange),
              SizedBox(width: 8),
              Text('AUTO周回'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('周回回数を選択してください'),
              const SizedBox(height: 16),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [5, 10, 20, 50].map((count) {
                  final isSelected = selectedCount == count;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedCount = count),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.orange : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected 
                            ? Border.all(color: Colors.orange.shade700, width: 2)
                            : null,
                      ),
                      child: Text(
                        '$count回',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '注意事項',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '・敗北時は自動で停止します\n・ボス解放時も停止します\n・途中で停止することもできます',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('キャンセル'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _startAutoLoop(selectedCount);
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('開始'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startAutoLoop(int count) {
    setState(() {
      _isAutoMode = true;
      _autoLoopTarget = count;
      _currentLoopCount = 0;
    });
    
    // 最初のバトルを開始
    _startEncounterBattle();
  }

  void _stopAutoLoop() {
    setState(() {
        _isAutoMode = false;
        // _autoLoopTarget は保持（結果画面で使用）
    });
    }

  /// 回復オプション選択ダイアログ
  void _showRecoveryOptionDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'HP回復方法を選択',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // モンスターセンターへ移動
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context); // 冒険画面を閉じてホームに戻る
              },
              icon: const Icon(Icons.home),
              label: const Text('モンスターセンターへ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            
            // 回復アイテム使用
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _showUseItemDialog();
              },
              icon: const Icon(Icons.medical_services),
              label: const Text('回復アイテムを使う'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            
            // キャンセル
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('キャンセル'),
            ),
            
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 回復アイテム使用ダイアログ
  void _showUseItemDialog() async {
    const userId = 'dev_user_12345';
    final itemRepo = ItemRepository();
    
    setState(() => _isLoading = true);
    
    try {
      // 回復系アイテムのみ取得
      final masters = await itemRepo.getItemMasters();
      final userItems = await itemRepo.getUserItems(userId);
      
      // 回復系アイテムをフィルタリング
      final healingItems = <Item>[];
      final itemQuantities = <String, int>{};
      
      for (final userItem in userItems) {
        if (userItem.quantity <= 0) continue;
        
        final master = masters[userItem.itemId];
        if (master != null && master.isHealingItem) {
          healingItems.add(master);
          itemQuantities[master.itemId] = userItem.quantity;
        }
      }
      
      setState(() => _isLoading = false);
      
      if (!mounted) return;
      
      if (healingItems.isEmpty) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.medical_services, color: Colors.grey),
                SizedBox(width: 8),
                Text('回復アイテム'),
              ],
            ),
            content: const Text('回復アイテムを持っていません。\nモンスターセンターをご利用ください。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('閉じる'),
              ),
            ],
          ),
        );
        return;
      }
      
      // アイテム選択ダイアログ
      _showItemSelectionDialog(healingItems, itemQuantities, userId);
      
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('アイテム読み込みエラー: $e');
    }
  }

  /// アイテム選択ダイアログ
  void _showItemSelectionDialog(
    List<Item> items,
    Map<String, int> quantities,
    String userId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.medical_services, color: Colors.blue),
            SizedBox(width: 8),
            Text('回復アイテム選択'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final qty = quantities[item.itemId] ?? 0;
              
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(item.rarityColor),
                    child: Text(
                      item.rarityStars.substring(0, 1),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(item.name),
                  subtitle: Text(
                    '${item.description}\n所持数: $qty',
                    style: const TextStyle(fontSize: 12),
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showMonsterSelectionForItem(item, userId);
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  /// モンスター選択ダイアログ（UseItemDialog利用）
  void _showMonsterSelectionForItem(Item item, String userId) {
    showDialog(
      context: context,
      builder: (ctx) => UseItemDialog(
        item: item,
        userId: userId,
        onUse: (monsterId) async {
          Navigator.pop(ctx);
          await _useItemOnMonster(item, monsterId, userId);
        },
      ),
    );
  }

  /// アイテム使用実行
  Future<void> _useItemOnMonster(Item item, String monsterId, String userId) async {
    setState(() => _isLoading = true);
    
    try {
      final itemService = ItemService();
      final result = await itemService.useItem(
        userId: userId,
        itemId: item.itemId,
        targetMonsterId: monsterId,
      );
      
      await _refreshPartyHp();
      
      setState(() => _isLoading = false);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
      
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('アイテム使用エラー: $e');
    }
  }

  Future<void> _startEncounterBattle() async {
  if (!_canBattle || _isBattling) return;
  
  setState(() => _isBattling = true);
  
  try {
    if (!mounted) return;
    
    print('🎮 AUTO: バトル開始 (isAutoMode: $_isAutoMode, loopCount: $_currentLoopCount/$_autoLoopTarget)');
    
    final result = await Navigator.push<bool?>(
      context,
      MaterialPageRoute(
        builder: (ctx) => BattleScreen(
          playerParty: _currentParty,
          stageData: widget.stage,
          isAutoMode: _isAutoMode,
          currentLoop: _currentLoopCount,
          totalLoop: _autoLoopTarget,
        ),
      ),
    );
    
    print('🎮 AUTO: バトル結果 result=$result');
    
    // ★修正: 先に_isBattlingをfalseにする
    setState(() => _isBattling = false);
    
    // 強制終了（null）の場合は何もしない
    if (result == null) {
      print('🎮 AUTO: 強制終了のためAUTO停止');
      return;
    }
    
    // バトル結果処理
    await _handleBattleResult(result);
  } catch (e) {
    print('🎮 AUTO: エラー $e');
    _showErrorSnackBar('エラー: $e');
    setState(() => _isBattling = false);
  }
}

  Future<void> _startBossBattle() async {
    if (!_canBattle || _isBattling) return;
    
    setState(() => _isBattling = true);
    
    try {
      final bossStageId = widget.stage.bossStageId;
      if (bossStageId == null) {
        _showErrorSnackBar('ボスステージが設定されていません');
        setState(() => _isBattling = false);
        return;
      }
      
      final bossStage = await _adventureRepo.getStage(bossStageId);
      if (bossStage == null) {
        _showErrorSnackBar('ボスステージの取得に失敗しました');
        setState(() => _isBattling = false);
        return;
      }
      
      if (!mounted) return;
      
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (ctx) => BattleScreen(
            playerParty: _currentParty,
            stageData: bossStage,
          ),
        ),
      );
      
      // ボス戦結果処理
      await _handleBossBattleResult(result ?? false);
    } catch (e) {
      _showErrorSnackBar('エラー: $e');
    }
    
    setState(() => _isBattling = false);
  }

  Future<void> _handleBattleResult(bool isWin) async {
    print('🎮 AUTO: _handleBattleResult開始 isWin=$isWin, _isAutoMode=$_isAutoMode');
    
    await _refreshPartyHp();
    await _loadProgress();
    
    print('🎮 AUTO: HP更新完了 _canBattle=$_canBattle, _bossUnlocked=$_bossUnlocked');
    
    if (isWin) {
      _totalExp += widget.stage.rewards.exp;
      _totalGold += widget.stage.rewards.gold;
      _totalDefeatedCount++;

      // ★追加: ドロップアイテムを累積（将来的にステージからドロップを取得）
    // TODO: 実際のドロップアイテム処理を追加
    // for (final item in droppedItems) {
    //   _obtainedItemCounts[item] = (_obtainedItemCounts[item] ?? 0) + 1;
    // }
      
      // AUTO周回処理
      if (_isAutoMode) {
        _currentLoopCount++;
        print('🎮 AUTO: 周回カウント $_currentLoopCount/$_autoLoopTarget');
        
        // 周回完了チェック
        if (_currentLoopCount >= _autoLoopTarget) {
          print('🎮 AUTO: 周回完了で停止');
          _stopAutoLoop();
          _showAutoCompleteDialog();
          setState(() {});
          return;
        }
        
        // ★削除: ボス解放時の停止処理を削除
        // ボス解放後もAUTO周回を継続する
        
        // 戦闘可能なら次のバトルへ、不可能なら停止
        if (_canBattle) {
        print('🎮 AUTO: 次のバトルへ遷移準備');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted && _isAutoMode) {
            print('🎮 AUTO: 次のバトル開始');
            _startEncounterBattle();
            return;  // ★追加: ここでreturnして、下の setState(() => _isBattling = false) を実行しない
        } else {
            print('🎮 AUTO: mounted=$mounted, _isAutoMode=$_isAutoMode で開始せず');
        }
        } else {
          print('🎮 AUTO: HP不足で停止');
          _stopAutoLoop();
          _showAutoStoppedDialog();
        }
      }
    } else {
      print('🎮 AUTO: 敗北');
      if (_isAutoMode) {
        _stopAutoLoop();
      }
      _showDefeatDialog();
    }
    
    setState(() {});
  }

  void _showAutoStoppedDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
        title: const Row(
            children: [
            Icon(Icons.pause_circle, color: Colors.orange),
            SizedBox(width: 8),
            Text('AUTO停止'),
            ],
        ),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            const Text('戦闘可能なモンスターが不足したため\nAUTO周回を停止しました。'),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text('【獲得報酬】', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('周回数: $_currentLoopCount / $_autoLoopTarget'),
            const SizedBox(height: 4),
            Row(
                children: [
                const Icon(Icons.star, color: Colors.orange, size: 20),
                const SizedBox(width: 4),
                Text('EXP: $_totalExp'),
                ],
            ),
            const SizedBox(height: 4),
            Row(
                children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text('ゴールド: $_totalGold G'),
                ],
            ),
            const SizedBox(height: 4),
            Row(
                children: [
                const Icon(Icons.pets, color: Colors.blue, size: 20),
                const SizedBox(width: 4),
                Text('撃破数: $_totalDefeatedCount体'),
                ],
            ),
            if (_obtainedItemCounts.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('【ドロップアイテム】', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ..._obtainedItemCounts.entries.map((e) => 
                Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: Text('・${e.key} x${e.value}'),
                ),
                ),
            ],
            ],
        ),
        actions: [
            ElevatedButton(
            onPressed: () {
                Navigator.pop(ctx);
            },
            child: const Text('回復して続ける'),
            ),
            ElevatedButton(
            onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('終了'),
            ),
        ],
        ),
    );
    }

  Future<void> _handleBossBattleResult(bool isWin) async {
    await _refreshPartyHp();
    
    if (isWin) {
      _totalExp += (widget.stage.rewards.exp * 3);
      _totalGold += (widget.stage.rewards.gold * 3);
      
      // ボス撃破でエンカウントリセット
      await _loadProgress();
      
      _showBossVictoryDialog();
    } else {
      _showDefeatDialog();
    }
    
    setState(() {});
  }

  void _showAutoCompleteDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
        title: const Row(
            children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('AUTO周回完了'),
            ],
        ),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text('$_autoLoopTarget回の周回が完了しました！'),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text('【獲得報酬】', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
                children: [
                const Icon(Icons.star, color: Colors.orange, size: 20),
                const SizedBox(width: 4),
                Text('EXP: $_totalExp'),
                ],
            ),
            const SizedBox(height: 4),
            Row(
                children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text('ゴールド: $_totalGold G'),
                ],
            ),
            const SizedBox(height: 4),
            Row(
                children: [
                const Icon(Icons.pets, color: Colors.blue, size: 20),
                const SizedBox(width: 4),
                Text('撃破数: $_totalDefeatedCount体'),
                ],
            ),
            if (_obtainedItemCounts.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('【ドロップアイテム】', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ..._obtainedItemCounts.entries.map((e) => 
                Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: Text('・${e.key} x${e.value}'),
                ),
                ),
            ],
            ],
        ),
        actions: [
            ElevatedButton(
            onPressed: () {
                Navigator.pop(ctx);
            },
            child: const Text('続ける'),
            ),
            ElevatedButton(
            onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('終了'),
            ),
        ],
        ),
    );
    }

  void _showDefeatDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.sentiment_dissatisfied, color: Colors.red),
            SizedBox(width: 8),
            Text('戦闘終了'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('戦闘可能なモンスターが不足しています。'),
            const SizedBox(height: 12),
            Text('獲得EXP: $_totalExp'),
            Text('獲得ゴールド: $_totalGold G'),
            if (_totalDefeatedCount > 0)
              Text('撃破数: $_totalDefeatedCount体'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: const Text('回復して続ける'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('終了'),
          ),
        ],
      ),
    );
  }

  void _showBossVictoryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber),
            SizedBox(width: 8),
            Text('ボス撃破！'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('おめでとうございます！ボスを倒しました。'),
            const SizedBox(height: 12),
            Text('獲得EXP: $_totalExp'),
            Text('獲得ゴールド: $_totalGold G'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: const Text('続ける'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('終了'),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmDialog() {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
        title: const Text('冒険を終了'),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            const Text('冒険を終了しますか？'),
            if (_isAutoMode) ...[
                const SizedBox(height: 8),
                const Text(
                'AUTO周回も停止します。',
                style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
            ],
            if (_totalExp > 0 || _totalGold > 0 || _totalDefeatedCount > 0) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text('【獲得報酬】', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                if (_totalExp > 0)
                Row(
                    children: [
                    const Icon(Icons.star, color: Colors.orange, size: 18),
                    const SizedBox(width: 4),
                    Text('EXP: $_totalExp', style: const TextStyle(fontSize: 14)),
                    ],
                ),
                if (_totalGold > 0) ...[
                const SizedBox(height: 4),
                Row(
                    children: [
                    const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text('ゴールド: $_totalGold G', style: const TextStyle(fontSize: 14)),
                    ],
                ),
                ],
                if (_totalDefeatedCount > 0) ...[
                const SizedBox(height: 4),
                Row(
                    children: [
                    const Icon(Icons.pets, color: Colors.blue, size: 18),
                    const SizedBox(width: 4),
                    Text('撃破数: $_totalDefeatedCount体', style: const TextStyle(fontSize: 14)),
                    ],
                ),
                ],
                if (_obtainedItemCounts.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('【ドロップアイテム】', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                ..._obtainedItemCounts.entries.map((e) => 
                    Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: Text('・${e.key} x${e.value}', style: const TextStyle(fontSize: 14)),
                    ),
                ),
                ],
            ],
            ],
        ),
        actions: [
            TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
            ),
            ElevatedButton(
            onPressed: () {
                if (_isAutoMode) {
                _stopAutoLoop();
                }
                Navigator.pop(ctx);
                Navigator.pop(context);
            },
            child: const Text('終了'),
            ),
        ],
        ),
    );
    }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}