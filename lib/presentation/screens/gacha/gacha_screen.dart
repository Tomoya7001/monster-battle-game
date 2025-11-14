import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/gacha/gacha_bloc.dart';
import '../../bloc/gacha/gacha_event.dart';
import '../../bloc/gacha/gacha_state.dart';
import 'widgets/currency_display.dart';
import 'widgets/gacha_tabs.dart';
import 'widgets/pity_counter.dart';
import 'widgets/gacha_buttons.dart';
import 'widgets/gacha_animation.dart';
import 'widgets/ceiling_ticket_display.dart';
import 'modals/probability_modal.dart';
import 'modals/gacha_result_modal.dart';
import '../../../core/utils/preferences.dart';
import 'widgets/ticket_exchange_modal.dart';
import '../../blocs/auth/auth_bloc.dart';
import 'gacha_history_screen.dart';

class GachaScreenWithProvider extends StatelessWidget {
  const GachaScreenWithProvider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GachaBloc()..add(const InitializeGacha()),
      child: const GachaScreen(),
    );
  }
}

class GachaScreen extends StatefulWidget {
  const GachaScreen({Key? key}) : super(key: key);

  @override
  State<GachaScreen> createState() => _GachaScreenState();
}

class _GachaScreenState extends State<GachaScreen> {
  String _selectedTab = '通常';
  bool _isAnimating = false;
  bool _skipAnimation = false;
  List<dynamic>? _pendingResults;
  
  String? get _userId {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      return authState.userId;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadSkipSetting();
    // チケット残高読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = _userId;
      if (userId != null && userId.isNotEmpty) {
        context.read<GachaBloc>().add(LoadTicketBalance(userId));
      }
    });
  }

  Future<void> _loadSkipSetting() async {
    final skipSetting = await GachaPreferences.getSkipAnimation();
    if (mounted) {
      setState(() => _skipAnimation = skipSetting);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GachaBloc, GachaState>(
      listener: (context, state) {
        if (state is GachaLoading) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _isAnimating = true;
                _pendingResults = null;
                _skipAnimation = false;
              });
            }
          });
        } else if (state is GachaLoaded) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _pendingResults = state.results;
              });
            }
          });
        } else if (state is GachaError) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _isAnimating = false;
                _pendingResults = null;
              });
              _showErrorDialog(state.error);
            }
          });
        } else if (state is TicketExchangeSuccess) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _isAnimating = false;
              });
              _showExchangeSuccessDialog(state.reward);
            }
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ガチャ'),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: _showProbabilityModal,
            ),
          ],
        ),
        body: Stack(
          children: [
            _buildGachaUI(),
            if (_isAnimating && _pendingResults != null)
              _buildAnimationOverlay(),
            if (_isAnimating && !_skipAnimation && _pendingResults != null)
              _buildSkipButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildGachaUI() {
    return BlocBuilder<GachaBloc, GachaState>(
      builder: (context, state) {
        return SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),
              CurrencyDisplay(
                gems: state.gems,
                tickets: state.tickets,
              ),
              const SizedBox(height: 16),
              // 天井チケット表示（新規追加）
              CeilingTicketDisplay(
                userId: _userId ?? '', // nullの場合は空文字列
                currentTickets: state.gachaTickets,
              ),
              const SizedBox(height: 16),
              GachaTabs(
                selectedTab: _selectedTab,
                onTabChanged: (tab) {
                  setState(() => _selectedTab = tab);
                  context.read<GachaBloc>().add(ChangeGachaType(tab));
                },
              ),
              const SizedBox(height: 24),
              _buildGachaBanner(),
              const SizedBox(height: 24),
              PityCounter(
                current: state.pityCount,
                max: 100,
              ),
              const SizedBox(height: 24),
              GachaButtons(
                onSinglePull: _executeSinglePull,
                onMultiPull: _executeMultiPull,
                singleCost: 150,
                multiCost: 1500,
              ),
              const SizedBox(height: 16),
              _buildActionButtons(),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGachaBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getBannerTitle(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getBannerSubtitle(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: Icon(
              Icons.catching_pokemon,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton.icon(
          onPressed: _showProbabilityModal,
          icon: const Icon(Icons.info_outline),
          label: const Text('排出確率'),
        ),
        TextButton.icon(
          onPressed: _showHistory,
          icon: const Icon(Icons.history),
          label: const Text('履歴'),
        ),
      ],
    );
  }

  Widget _buildAnimationOverlay() {
    if (_pendingResults == null) return const SizedBox.shrink();

    final monsters = _pendingResults!.map((m) {
      return GachaMonster(
        name: m['name'] ?? '不明',
        rarity: m['rarity'] ?? 2,
        race: m['race'] ?? '不明',
        element: m['element'] ?? '不明',
      );
    }).toList();

    return GachaAnimationWidget(
      monsters: monsters,
      skipAnimation: _skipAnimation,
      isMultiPull: monsters.length > 1,
      onAnimationComplete: _onAnimationComplete,
    );
  }

  Widget _buildSkipButton() {
    return Positioned(
      right: 16,
      bottom: 16,
      child: ElevatedButton.icon(
        onPressed: () {
          if (mounted) {
            setState(() => _skipAnimation = true);
          }
        },
        icon: const Icon(Icons.fast_forward),
        label: const Text('スキップ'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.2),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  void _onAnimationComplete() {
    if (_pendingResults != null && mounted) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _isAnimating = false);
          _showResultModal(_pendingResults!);
          _pendingResults = null;
        }
      });
    }
  }

  String _getBannerTitle() {
    switch (_selectedTab) {
      case 'プレミアム':
        return 'プレミアムガチャ';
      case 'ピックアップ':
        return '炎属性ピックアップ！';
      default:
        return '通常ガチャ';
    }
  }

  String _getBannerSubtitle() {
    switch (_selectedTab) {
      case 'プレミアム':
        return '★4以上確定！';
      case 'ピックアップ':
        return '期間: 2025/11/01 - 11/07';
      default:
        return '全モンスター対象';
    }
  }

  void _executeSinglePull() {
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログインが必要です')),
      );
      return;
    }
    
    context.read<GachaBloc>().add(
          ExecuteGacha(
            gachaType: _selectedTab, 
            count: 1, 
            userId: userId, // 追加
          ),
        );
  }

  void _executeMultiPull() {
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログインが必要です')),
      );
      return;
    }
    
    context.read<GachaBloc>().add(
          ExecuteGacha(
            gachaType: _selectedTab, 
            count: 10, 
            userId: userId, // 追加
          ),
        );
  }

  void _showResultModal(List<dynamic> results) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GachaResultModal(results: results),
    );
  }

  void _showProbabilityModal() {
    showDialog(
      context: context,
      builder: (context) => const ProbabilityModal(),
    );
  }

  void _showHistory() {
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログインが必要です')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<GachaBloc>(),
          child: GachaHistoryScreen(userId: userId),
        ),
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showExchangeSuccessDialog(Map<String, dynamic> reward) {
    final userId = _userId;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.celebration, color: Colors.amber),
            const SizedBox(width: 8),
            const Text('交換成功!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.stars,
              size: 80,
              color: reward['rarity'] == 5 ? Colors.amber : Colors.purple,
            ),
            const SizedBox(height: 16),
            Text(
              '★${reward['rarity']}のモンスターを獲得しました!',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // チケット残高を再読み込み
              if (userId != null) {
                context.read<GachaBloc>().add(LoadTicketBalance(userId));
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}