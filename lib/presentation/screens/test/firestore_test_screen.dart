import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreTestScreen extends StatefulWidget {
  const FirestoreTestScreen({super.key});

  @override
  State<FirestoreTestScreen> createState() => _FirestoreTestScreenState();
}

class _FirestoreTestScreenState extends State<FirestoreTestScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _statusMessage = '準備完了';
  bool _isLoading = false;
  Map<String, dynamic>? _readData;

  // 書き込みテスト
  Future<void> _testWrite() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '書き込み中...';
    });

    try {
      await _firestore.collection('test').doc('test1').set({
        'message': 'Hello Firestore!',
        'timestamp': FieldValue.serverTimestamp(),
        'count': 1,
      });

      setState(() {
        _statusMessage = '✅ 書き込み成功！';
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Firestoreへの書き込みが成功しました'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _statusMessage = '❌ 書き込み失敗: $e';
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラー: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 読み取りテスト
  Future<void> _testRead() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '読み取り中...';
      _readData = null;
    });

    try {
      final doc = await _firestore.collection('test').doc('test1').get();

      if (doc.exists) {
        setState(() {
          _readData = doc.data();
          _statusMessage = '✅ 読み取り成功！';
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Firestoreからの読み取りが成功しました'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _statusMessage = '⚠️ ドキュメントが存在しません';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ 読み取り失敗: $e';
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラー: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // リアルタイム監視テスト
  Future<void> _testStream() async {
    setState(() {
      _statusMessage = 'リアルタイム監視を開始しました';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('下のリアルタイムデータを確認してください'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // 削除テスト
  Future<void> _testDelete() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '削除中...';
    });

    try {
      await _firestore.collection('test').doc('test1').delete();

      setState(() {
        _statusMessage = '✅ 削除成功！';
        _readData = null;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ドキュメントを削除しました'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      setState(() {
        _statusMessage = '❌ 削除失敗: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore テスト'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ステータス表示
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      const Icon(Icons.cloud_done, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      _statusMessage,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // テストボタン群
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testWrite,
              icon: const Icon(Icons.edit),
              label: const Text('1. 書き込みテスト'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testRead,
              icon: const Icon(Icons.download),
              label: const Text('2. 読み取りテスト'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testStream,
              icon: const Icon(Icons.stream),
              label: const Text('3. リアルタイム監視'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testDelete,
              icon: const Icon(Icons.delete),
              label: const Text('4. 削除テスト'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // 読み取ったデータの表示
            if (_readData != null) ...[
              const Text(
                '📄 読み取ったデータ:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('message: ${_readData!['message']}'),
                      Text('count: ${_readData!['count']}'),
                      Text('timestamp: ${_readData!['timestamp']}'),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // リアルタイム監視
            const Text(
              '🔴 リアルタイムデータ:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('test').doc('test1').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Card(
                    color: Colors.red[100],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('エラー: ${snapshot.error}'),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                if (!snapshot.data!.exists) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('ドキュメントが存在しません'),
                    ),
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                return Card(
                  color: Colors.green[100],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('✅ 接続中'),
                        const Divider(),
                        Text('message: ${data['message']}'),
                        Text('count: ${data['count']}'),
                        Text('timestamp: ${data['timestamp']}'),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // 説明
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 テスト手順',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text('1. 「書き込みテスト」を実行'),
                    const Text('2. 「読み取りテスト」を実行'),
                    const Text('3. Firebase Consoleで確認'),
                    const Text('4. 「リアルタイム監視」を開始'),
                    const Text('5. Consoleで手動編集して動作確認'),
                    const Text('6. 「削除テスト」で削除'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
