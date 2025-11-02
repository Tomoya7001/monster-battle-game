// lib/screens/admin/data_import_screen.dart

import 'package:flutter/material.dart';
import '../../utils/data_import.dart';

class DataImportScreen extends StatefulWidget {
  const DataImportScreen({Key? key}) : super(key: key);

  @override
  State<DataImportScreen> createState() => _DataImportScreenState();
}

class _DataImportScreenState extends State<DataImportScreen> {
  final DataImporter _importer = DataImporter();
  bool _isImporting = false;
  String _statusMessage = '準備完了';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('マスターデータ投入'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚠️ 注意事項',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• この操作は開発環境でのみ実行してください\n'
                      '• 既存のマスターデータは上書きされます\n'
                      '• 投入には数分かかる場合があります',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isImporting ? null : _importAllData,
              icon: _isImporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.upload),
              label: Text(_isImporting ? '投入中...' : 'すべて投入'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ステータス',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_statusMessage),
                  ],
                ),
              ),
            ),
            const Spacer(),
            const Text(
              '投入されるデータ:\n'
              '• モンスターマスター: 30体\n'
              '• 技マスター: 26種類\n'
              '• 装備マスター: 22種類\n'
              '• 特性マスター: 56種類',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}