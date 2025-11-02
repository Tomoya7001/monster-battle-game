import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'widgets/currency_display.dart';
import 'widgets/gacha_tabs.dart';
import 'widgets/pity_counter.dart';
import 'widgets/gacha_buttons.dart';
import 'modals/probability_modal.dart';
import 'modals/gacha_result_modal.dart';
import '../../bloc/gacha/gacha_bloc.dart';
import '../../bloc/gacha/gacha_event.dart';
import '../../bloc/gacha/gacha_state.dart';

/// Week 7: ガチャ画面
/// 
/// Day 1-2: UI実装完了 ✅
/// Day 3-4: BLoC統合完了 ✅
/// Day 5-6: 演出とアニメーション
class GachaScreen extends StatelessWidget {
  const GachaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GachaBloc()
        ..add(const GachaInitialize('test_user')), // TODO: 実際のユーザーID
      child: Scaffold(
        appBar: AppBar(
          title: const Text('召喚'),
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ガチャ履歴(Week 8で実装)')),
                );
              },
            ),
          ],
        ),
        body: const GachaScreenContent(),
      ),
    );
  }
}

class GachaScreenContent extends StatelessWidget {
  const GachaScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GachaBloc, GachaState>(
      listener: (context, state) {
        // 成功時: 結果モーダル表示
        if (state.status == GachaStatus.success && state.results.isNotEmpty) {
          GachaResultModal.show(
            context,
            results: state.results,
            onClose: () {
              context.read<GachaBloc>().add(const GachaResultClosed());
            },
          );
        }
        
        // 失敗時: エラーメッセージ表示
        if (state.status == GachaStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'エラーが発生しました'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        return Stack(
          children: [
            Column(
              children: [
                // 通貨表示(BLoCから取得)
                CurrencyDisplay(
                  freeGems: state.freeGems,
                  tickets: state.tickets,
                ),
                
                // タブ切り替え
                GachaTabs(
                  initialType: state.selectedType,
                  onTypeChanged: (type) {
                    context.read<GachaBloc>().add(GachaTypeChanged(type));
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
                
                // 天井カウンター(BLoCから取得)
                PityCounter(
                  currentCount: state.pityCount,
                  pityLimit: 100,
                ),
                
                // ガチャボタン
                GachaButtons(
                  isLoading: state.status == GachaStatus.loading,
                  onSinglePressed: () {
                    context.read<GachaBloc>().add(
                      const GachaDrawSingle('test_user'), // TODO: 実際のユーザーID
                    );
                  },
                  onMultiPressed: () {
                    context.read<GachaBloc>().add(
                      const GachaDrawMulti('test_user'), // TODO: 実際のユーザーID
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
            ),
            
            // ローディングオーバーレイ
            if (state.status == GachaStatus.loading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '召喚中...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}