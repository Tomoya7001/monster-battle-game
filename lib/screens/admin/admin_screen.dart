// lib/screens/admin/admin_screen.dart
import 'package:flutter/material.dart';
import '../../utils/data_importer.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final DataImporter _importer = DataImporter();
  bool _isImporting = false;
  String _currentTask = '';
  double _progress = 0.0;
  final List<String> _logs = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('管理画面'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImportSection(),
            const SizedBox(height: 32),
            if (_isImporting) _buildProgressSection(),
            if (_isImporting) const SizedBox(height: 32),
            _buildLogSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildImportSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'マスターデータ投入',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload),
              label: const Text('モンスターマスター投入'),
              onPressed: _isImporting ? null : () => _importData('monster'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload),
              label: const Text('技マスター投入'),
              onPressed: _isImporting ? null : () => _importData('skill'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload),
              label: const Text('装備マスター投入'),
              onPressed: _isImporting ? null : () => _importData('equipment'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload),
              label: const Text('特性マスター投入'),
              onPressed: _isImporting ? null : () => _importData('trait'),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.cloud_upload),
              label: const Text('全データ一括投入'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: _isImporting ? null : _importAllData,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever),
              label: const Text('全データ削除（開発用）'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: _isImporting ? null : _confirmDelete,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '進捗状況',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(_currentTask),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 8),
            Text('${(_progress * 100).toInt()}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildLogSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ログ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.clear),
                  label: const Text('クリア'),
                  onPressed: () {
                    setState(() {
                      _logs.clear();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      _logs[index],
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importData(String type) async {
    setState(() {
      _isImporting = true;
      _currentTask = '${type}データを投入中...';
      _progress = 0.0;
      _logs.add('[${DateTime.now()}] ${type}データ投入開始');
    });

    try {
      switch (type) {
        case 'monster':
          await _importer.importMonsters(
            onProgress: (current, total) {
              setState(() {
                _progress = current / total;
                _logs.add('[$current/$total] モンスターデータ投入中...');
              });
            },
          );
          break;
        case 'skill':
          await _importer.importSkills(
            onProgress: (current, total) {
              setState(() {
                _progress = current / total;
                _logs.add('[$current/$total] 技データ投入中...');
              });
            },
          );
          break;
        case 'equipment':
          await _importer.importEquipment(
            onProgress: (current, total) {
              setState(() {
                _progress = current / total;
                _logs.add('[$current/$total] 装備データ投入中...');
              });
            },
          );
          break;
        case 'trait':
          await _importer.importTraits(
            onProgress: (current, total) {
              setState(() {
                _progress = current / total;
                _logs.add('[$current/$total] 特性データ投入中...');
              });
            },
          );
          break;
      }

      setState(() {
        _logs.add('✅ ${type}データの投入が完了しました');
      });
    } catch (e) {
      setState(() {
        _logs.add('❌ エラー: $e');
      });
    } finally {
      setState(() {
        _isImporting = false;
        _currentTask = '';
        _progress = 0.0;
      });
    }
  }

  Future<void> _importAllData() async {
    setState(() {
      _isImporting = true;
      _logs.add('[${DateTime.now()}] 全データ一括投入開始');
    });

    try {
      await _importer.importAll(
        onProgress: (task, current, total) {
          setState(() {
            _currentTask = '$taskデータ投入中...';
            _progress = current / total;
            _logs.add('[$current/$total] $taskデータ投入中...');
          });
        },
      );

      setState(() {
        _logs.add('✅ 全データの投入が完了しました');
      });
    } catch (e) {
      setState(() {
        _logs.add('❌ エラー: $e');
      });
    } finally {
      setState(() {
        _isImporting = false;
        _currentTask = '';
        _progress = 0.0;
      });
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('警告'),
        content: const Text('全てのマスターデータを削除します。\nこの操作は取り消せません。\n本当に実行しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteAllData();
    }
  }

  Future<void> _deleteAllData() async {
    setState(() {
      _isImporting = true;
      _currentTask = 'データ削除中...';
      _logs.add('[${DateTime.now()}] 全データ削除開始');
    });

    try {
      await _importer.deleteAll();
      setState(() {
        _logs.add('✅ 全データの削除が完了しました');
      });
    } catch (e) {
      setState(() {
        _logs.add('❌ エラー: $e');
      });
    } finally {
      setState(() {
        _isImporting = false;
        _currentTask = '';
      });
    }
  }
}