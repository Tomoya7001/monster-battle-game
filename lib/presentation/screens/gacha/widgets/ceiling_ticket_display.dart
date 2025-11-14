import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/gacha_service.dart';
import '../../../bloc/gacha/gacha_bloc.dart';
import '../../../bloc/gacha/gacha_event.dart';
import 'ticket_exchange_modal.dart';

class CeilingTicketDisplay extends StatelessWidget {
  final String userId;
  final int currentTickets;

  const CeilingTicketDisplay({
    Key? key,
    required this.userId,
    this.currentTickets = 0,
  }) : super(key: key);

  void _showExchangeModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider.value(
        value: context.read<GachaBloc>(),
        child: TicketExchangeModal(
          userId: userId,
          currentTickets: currentTickets,
          onExchangeSuccess: () {
            Navigator.pop(ctx);
            context.read<GachaBloc>().add(LoadTicketBalance(userId));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canExchange50 = currentTickets >= 50;
    final canExchange100 = currentTickets >= 100;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade900,
            Colors.purple.shade700,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.confirmation_number,
                    color: Colors.amber,
                    size: 28,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '交換チケット',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$currentTickets枚',
                  style: TextStyle(
                    color: Colors.purple.shade900,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildProgressBar(
                  label: '★4確定',
                  current: currentTickets,
                  target: 50,
                  color: Colors.purple,
                  canExchange: canExchange50,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProgressBar(
                  label: '★5確定',
                  current: currentTickets,
                  target: 100,
                  color: Colors.amber,
                  canExchange: canExchange100,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  currentTickets >= 50 ? () => _showExchangeModal(context) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                disabledBackgroundColor: Colors.grey.shade700,
                foregroundColor: Colors.purple.shade900,
                disabledForegroundColor: Colors.grey.shade500,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                currentTickets >= 50 ? 'チケットを交換' : '50枚から交換可能',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar({
    required String label,
    required int current,
    required int target,
    required Color color,
    required bool canExchange,
  }) {
    final progress = (current / target).clamp(0.0, 1.0);
    final displayCount = current > target ? target : current;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$displayCount/$target',
              style: TextStyle(
                color: canExchange ? Colors.amber : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              canExchange ? Colors.amber : color,
            ),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}