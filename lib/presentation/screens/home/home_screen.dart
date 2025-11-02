import 'package:flutter/material.dart';
import '../gacha/gacha_screen.dart';

/// Week 7: シンプルなホーム画面
/// ガチャ画面実装の前に、まずこれを表示する
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('モンスター対戦ゲーム'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Week 7: ガチャ画面実装',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'これから実装する機能:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem('ガチャ画面'),
            _buildFeatureItem('単発/10連ガチャ'),
            _buildFeatureItem('結果表示'),
            _buildFeatureItem('天井カウンター'),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GachaScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                backgroundColor: Colors.blue,
              ),
              child: const Text(
                'ガチャ画面へ(実装中)',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
      // デバッグ用: 管理画面へのアクセス
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: 管理画面への遷移(デバッグ用)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('管理画面は AdminScreen() から'),
            ),
          );
        },
        backgroundColor: Colors.grey,
        child: const Icon(Icons.admin_panel_settings),
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            feature,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}