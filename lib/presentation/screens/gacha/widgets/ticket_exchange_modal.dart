import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/gacha_ticket.dart';
import '../../../../core/services/gacha_service.dart' hide TicketExchangeOption;
import '../../../bloc/gacha/gacha_bloc.dart';
import '../../../bloc/gacha/gacha_event.dart';

class TicketExchangeModal extends StatefulWidget {
  final String userId;
  final int currentTickets;
  final VoidCallback onExchangeSuccess;

  const TicketExchangeModal({
    Key? key,
    required this.userId,
    required this.currentTickets,
    required this.onExchangeSuccess,
  }) : super(key: key);

  @override
  State<TicketExchangeModal> createState() => _TicketExchangeModalState();
}

class _TicketExchangeModalState extends State<TicketExchangeModal> {
  final GachaService _gachaService = GachaService();
  List<TicketExchangeOption> _options = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final options = await _gachaService.getExchangeOptions();
      if (mounted) {
        setState(() {
          _options = options;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('交換オプションの読み込みに失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _executeExchange(TicketExchangeOption option) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認'),
        content: Text(
          '${option.name}と交換しますか?\n'
          '必要チケット: ${option.requiredTickets}枚',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('交換する'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // BLoCを通じて交換実行
    context.read<GachaBloc>().add(
          ExchangeTickets(
            userId: widget.userId,
            optionId: option.id,
          ),
        );

    widget.onExchangeSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'チケット交換',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.confirmation_number,
                          color: Colors.purple,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.currentTickets}枚',
                          style: TextStyle(
                            color: Colors.purple.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: _options.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final option = _options[index];
                    final canExchange =
                        widget.currentTickets >= option.requiredTickets;
                    return _buildOptionCard(option, canExchange);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(TicketExchangeOption option, bool canExchange) {
    Color cardColor;
    Color accentColor;
    IconData icon;

    switch (option.rewardType) {
      case 'star5':
        cardColor = Colors.amber.shade50;
        accentColor = Colors.amber;
        icon = Icons.stars;
        break;
      case 'star4':
        cardColor = Colors.purple.shade50;
        accentColor = Colors.purple;
        icon = Icons.star;
        break;
      default:
        cardColor = Colors.blue.shade50;
        accentColor = Colors.blue;
        icon = Icons.card_giftcard;
    }

    return Card(
      elevation: canExchange ? 4 : 1,
      color: canExchange ? cardColor : Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: canExchange ? accentColor : Colors.grey.shade300,
          width: canExchange ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: canExchange ? () => _executeExchange(option) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: canExchange ? accentColor : Colors.grey,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: canExchange
                                ? Colors.grey.shade800
                                : Colors.grey,
                          ),
                        ),
                        if (option.description != null)
                          Text(
                            option.description!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: canExchange ? accentColor : Colors.grey,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${option.requiredTickets}枚',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (!canExchange)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'チケットが不足しています（あと${option.requiredTickets - widget.currentTickets}枚）',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}