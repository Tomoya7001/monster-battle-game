import 'package:flutter/material.dart';
import 'widgets/currency_display.dart';
import 'widgets/gacha_tabs.dart';
import 'widgets/pity_counter.dart';
import 'widgets/gacha_buttons.dart';
import 'modals/probability_modal.dart';

/// Week 7: ガチャ画面
/// 
/// Day 1-2: UI実装完了 ✅
/// Day 3-4: BLoC統合、ガチャ実行処理
/// Day 5-6: 演出とアニメーション
class GachaScreen extends StatelessWidget {
  const GachaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('召喚'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: Week 8でガチャ履歴画面実装
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ガチャ履歴(Week 8で実装)')),
              );
            },
          ),
        ],
      ),
      body: const GachaScreenContent(),
    );
  }
}

class GachaScreenContent extends StatelessWidget {
  const GachaScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 通貨表示 ✅
        const CurrencyDisplay(
          freeGems: 1500,
          tickets: 5,
        ),
        
        // タブ切り替え ✅
        GachaTabs(
          onTypeChanged: (type) {
            debugPrint('[GachaScreen] Tab changed to: $type');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${type.displayName}ガチャに切り替え'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),
        
        // ガチャ演出エリア
        Expanded(
          child: Container(
            color: Colors.grey[200],
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.casino, size: 100, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'ガチャ演出エリア\n(Day 5-6で実装)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // 天井カウンター ✅
        const PityCounter(
          currentCount: 25,
          pityLimit: 100,
        ),
        
        // ガチャボタン ✅
        GachaButtons(
          onSinglePressed: () {
            // TODO: Day 3-4でガチャ実行処理実装
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('単発ガチャ(Day 3-4で実装)')),
            );
          },
          onMultiPressed: () {
            // TODO: Day 3-4でガチャ実行処理実装
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('10連ガチャ(Day 3-4で実装)')),
            );
          },
        ),
        
        // 下部メニュー
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  // 排出確率モーダル表示 ✅
                  ProbabilityModal.show(context);
                },
                child: const Text('排出確率'),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('詳細(Week 8で実装)')),
                  );
                },
                child: const Text('詳細'),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('履歴(Week 8で実装)')),
                  );
                },
                child: const Text('履歴'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}