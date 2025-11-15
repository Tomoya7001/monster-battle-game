import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/gacha/gacha_bloc.dart';
import '../../bloc/gacha/gacha_event.dart';
import '../../bloc/gacha/gacha_state.dart';
import '../../../core/models/gacha_history.dart';
import 'package:intl/intl.dart';

class GachaHistoryScreen extends StatefulWidget {
  final String userId;

  const GachaHistoryScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<GachaHistoryScreen> createState() => _GachaHistoryScreenState();
}

class _GachaHistoryScreenState extends State<GachaHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // 履歴を読み込み
    context.read<GachaBloc>().add(LoadGachaHistory(userId: widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ガチャ履歴'),
      ),
      body: BlocBuilder<GachaBloc, GachaState>(
        builder: (context, state) {
          if (state is GachaLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is GachaError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.error),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<GachaBloc>()
                          .add(LoadGachaHistory(userId: widget.userId));
                    },
                    child: const Text('再読み込み'),
                  ),
                ],
              ),
            );
          }

          if (state is GachaHistoryLoaded) {
            final history = state.history.cast<GachaHistory>();

            if (history.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ガチャ履歴がありません',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                return _buildHistoryCard(context, item);
              },
            );
          }

          return const Center(child: Text('履歴を読み込んでいます...'));
        },
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, GachaHistory history) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: _buildGachaTypeIcon(history.gachaType),
        title: Text(
          '${history.gachaType}ガチャ (${history.pullCount}回)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          dateFormat.format(history.pulledAt),
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.diamond, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                Text('${history.gemsUsed}'),
              ],
            ),
            if (history.ticketsUsed > 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.confirmation_number,
                      size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text('${history.ticketsUsed}'),
                ],
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildResultsGrid(history.results),
          ),
        ],
      ),
    );
  }

  Widget _buildGachaTypeIcon(String gachaType) {
    IconData icon;
    Color color;

    switch (gachaType) {
      case 'プレミアム':
        icon = Icons.workspace_premium;
        color = Colors.amber;
        break;
      case 'ピックアップ':
        icon = Icons.star;
        color = Colors.purple;
        break;
      default:
        icon = Icons.catching_pokemon;
        color = Colors.blue;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.2),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildResultsGrid(List<GachaHistoryResult> results) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: results.map((result) {
        return _buildResultChip(result);
      }).toList(),
    );
  }

  Widget _buildResultChip(GachaHistoryResult result) {
    final rarityColor = _getRarityColor(result.rarity);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: rarityColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: rarityColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '★' * result.rarity,
            style: TextStyle(
              color: rarityColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            result.monsterName,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRarityColor(int rarity) {
    switch (rarity) {
      case 5:
        return Colors.amber;
      case 4:
        return Colors.purple;
      case 3:
        return Colors.blue;
      case 2:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}