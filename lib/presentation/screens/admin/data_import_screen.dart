// lib/screens/admin/data_import_screen.dart

import 'package:flutter/material.dart';
import '../../../utils/data_importer.dart';

class DataImportScreen extends StatefulWidget {
  const DataImportScreen({Key? key}) : super(key: key);

  @override
  State<DataImportScreen> createState() => _DataImportScreenState();
}

class _DataImportScreenState extends State<DataImportScreen> {
  final DataImporter _importer = DataImporter();
  bool _isImporting = false;
  String _statusMessage = '準備完了';
  
  // 開発用ユーザーID
  static const String _devUserId = 'dev_user_12345';

  Future<void> _importAllData() async {
    setState(() {
      _isImporting = true;
      _statusMessage = 'データ投入中...';
    });

    try {
      await _importer.importAllMasterData();
      await _importer.validateData();
      
      setState(() {
        _statusMessage = '✅ すべてのデータ投入完了！';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('マスターデータの投入が完了しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ エラー: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }

  /// スターターパック付与
  Future<void> _grantStarterPack() async {
    final confirmed = await _showConfirmDialog(
      '開発用スターターパック',
      '以下を付与します：\n'
      '・回復アイテム各種\n'
      '・経験値アイテム各種\n'
      '・素材各種\n'
      '・コイン 100,000\n'
      '・石 1,000\n'
      '・ジェム 500\n'
      '・モンスターHP全回復\n\n'
      '続行しますか？',
    );
    
    if (confirmed != true) return;
    
    await _executeWithLoading(() async {
      await _importer.grantDevStarterPack(_devUserId);
    }, '✅ スターターパック付与完了');
  }

  /// HP全回復
  Future<void> _healAllMonsters() async {
    final confirmed = await _showConfirmDialog(
      'HP全回復',
      'すべてのモンスターのHPを全回復します。\n続行しますか？',
    );
    
    if (confirmed != true) return;
    
    await _executeWithLoading(() async {
      await _importer.healAllMonsters(_devUserId);
    }, '✅ HP全回復完了');
  }

  /// 通貨付与ダイアログ
  Future<void> _showCurrencyDialog() async {
    final coinController = TextEditingController(text: '10000');
    final stoneController = TextEditingController(text: '100');
    final gemController = TextEditingController(text: '50');
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('通貨付与'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: coinController,
              decoration: const InputDecoration(
                labelText: 'コイン',
                prefixIcon: Icon(Icons.monetization_on, color: Colors.amber),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: stoneController,
              decoration: const InputDecoration(
                labelText: '石',
                prefixIcon: Icon(Icons.diamond, color: Colors.blue),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: gemController,
              decoration: const InputDecoration(
                labelText: 'ジェム',
                prefixIcon: Icon(Icons.auto_awesome, color: Colors.purple),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('付与'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    final coin = int.tryParse(coinController.text) ?? 0;
    final stone = int.tryParse(stoneController.text) ?? 0;
    final gem = int.tryParse(gemController.text) ?? 0;
    
    await _executeWithLoading(() async {
      await _importer.grantCurrencyToUser(
        userId: _devUserId,
        coin: coin,
        stone: stone,
        gem: gem,
      );
    }, '✅ 通貨付与完了');
  }

  /// アイテム付与ダイアログ
  Future<void> _showItemGrantDialog() async {
    final itemIdController = TextEditingController();
    final quantityController = TextEditingController(text: '10');
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アイテム付与'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: itemIdController,
              decoration: const InputDecoration(
                labelText: 'アイテムID',
                hintText: '例: potion_small',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(labelText: '個数'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const Text(
              '主なアイテムID:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              '・potion_small/medium/large\n'
              '・revive_half/full\n'
              '・exp_candy_s/m/l\n'
              '・fire/water/thunder_fragment\n'
              '・iron_ore, magic_ore',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('付与'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    final itemId = itemIdController.text.trim();
    final quantity = int.tryParse(quantityController.text) ?? 0;
    
    if (itemId.isEmpty || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('アイテムIDと個数を正しく入力してください')),
      );
      return;
    }
    
    await _executeWithLoading(() async {
      await _importer.grantItemsToUser(
        userId: _devUserId,
        items: {itemId: quantity},
      );
    }, '✅ $itemId x$quantity 付与完了');
  }

  /// 確認ダイアログ表示
  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('実行'),
          ),
        ],
      ),
    );
  }

  /// ローディング付き実行
  Future<void> _executeWithLoading(
    Future<void> Function() action,
    String successMessage,
  ) async {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      await action();
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ エラー: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('開発者ツール'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 注意事項
            Card(
              color: Colors.orange.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ 開発環境専用',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('対象ユーザー: dev_user_12345'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // マスターデータ投入セクション
            _buildSectionTitle('📦 マスターデータ投入'),
            const SizedBox(height: 8),
            
            ElevatedButton.icon(
              onPressed: _isImporting ? null : _importAllData,
              icon: _isImporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload),
              label: Text(_isImporting ? '投入中...' : '全マスターデータ投入'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.blue,
              ),
            ),
            
            const SizedBox(height: 8),
            
            ElevatedButton.icon(
              onPressed: () async {
                final confirmed = await _showConfirmDialog(
                  '冒険システム用データ',
                  '統一技マスタとステージマスタを投入します。',
                );
                if (confirmed != true) return;
                
                await _executeWithLoading(() async {
                  await _importer.importAllMasterDataExtended();
                }, '✅ 冒険システム用データ投入完了');
              },
              icon: const Icon(Icons.explore),
              label: const Text('冒険システム用データ投入'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.deepPurple,
              ),
            ),
            
            const SizedBox(height: 8),
            
            ElevatedButton.icon(
              onPressed: () async {
                final confirmed = await _showConfirmDialog(
                  '探索システム用データ',
                  '素材マスタと探索先マスタを投入します。',
                );
                if (confirmed != true) return;
                
                await _executeWithLoading(() async {
                  await _importer.importDispatchSystemData();
                }, '✅ 探索システム用データ投入完了');
              },
              icon: const Icon(Icons.hiking),
              label: const Text('探索システム用データ投入'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.brown,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // ステータス表示
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(_statusMessage),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 開発用データ付与セクション
            _buildSectionTitle('🎁 開発用データ付与'),
            const SizedBox(height: 8),
            
            ElevatedButton.icon(
              onPressed: _grantStarterPack,
              icon: const Icon(Icons.card_giftcard),
              label: const Text('スターターパック付与'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.green,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _healAllMonsters,
                    icon: const Icon(Icons.favorite),
                    label: const Text('HP全回復'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.pink,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showCurrencyDialog,
                    icon: const Icon(Icons.monetization_on),
                    label: const Text('通貨付与'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.amber,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            ElevatedButton.icon(
              onPressed: _showItemGrantDialog,
              icon: const Icon(Icons.inventory),
              label: const Text('個別アイテム付与'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.teal,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // データ情報
            const Text(
              '投入されるマスターデータ:\n'
              '• モンスター: 30体\n'
              '• 技: 26種類 + 追加技\n'
              '• 装備: 22種類\n'
              '• 特性: 56種類\n'
              '• アイテム: 20種類\n'
              '• ステージ: 4種類',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}