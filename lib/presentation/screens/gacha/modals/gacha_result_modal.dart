import 'package:flutter/material.dart';

/// ガチャ結果表示モーダル
class GachaResultModal extends StatelessWidget {
  final List<dynamic> results;

  const GachaResultModal({
    Key? key,
    required this.results,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMulti = results.length > 1;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMulti ? 600 : 400,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: isMulti ? _buildMultiResults() : _buildSingleResult(),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade700, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.celebration, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              results.length > 1 ? '10連結果' : 'ガチャ結果',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleResult() {
    final monster = results.first as Map<String, dynamic>;
    final rarity = monster['rarity'] as int? ?? 2;
    final name = monster['name'] as String? ?? '不明';
    final race = monster['race'] as String? ?? '不明';
    final element = monster['element'] as String? ?? '不明';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: _getRarityColor(rarity).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.catching_pokemon,
                size: 80,
                color: _getRarityColor(rarity),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              rarity,
              (index) => Icon(
                Icons.star,
                color: _getRarityColor(rarity),
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _getRarityColor(rarity),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '$race / $element',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          if (rarity >= 4)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.new_releases, color: Colors.white, size: 20),
                  SizedBox(width: 4),
                  Text(
                    'NEW!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMultiResults() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 0.7,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final monster = results[index] as Map<String, dynamic>;
        return _buildMonsterCard(monster);
      },
    );
  }

  Widget _buildMonsterCard(Map<String, dynamic> monster) {
    final rarity = monster['rarity'] as int? ?? 2;
    final name = monster['name'] as String? ?? '不明';

    return Container(
      decoration: BoxDecoration(
        color: _getRarityColor(rarity).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getRarityColor(rarity),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Icon(
              Icons.catching_pokemon,
              size: 28,
              color: _getRarityColor(rarity),
            ),
          ),
          const SizedBox(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              rarity,
              (index) => Icon(
                Icons.star,
                color: _getRarityColor(rarity),
                size: 7,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Text(
              name,
              style: const TextStyle(fontSize: 7),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (results.length > 1) _buildSummary(),
          if (results.length > 1) const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('閉じる'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final star5Count = results.where((m) {
      final monster = m as Map<String, dynamic>;
      return (monster['rarity'] as int? ?? 2) == 5;
    }).length;
    
    final star4Count = results.where((m) {
      final monster = m as Map<String, dynamic>;
      return (monster['rarity'] as int? ?? 2) == 4;
    }).length;
    
    final star3Count = results.where((m) {
      final monster = m as Map<String, dynamic>;
      return (monster['rarity'] as int? ?? 2) == 3;
    }).length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (star5Count > 0)
            _buildSummaryItem('★5', star5Count, Colors.amber),
          if (star4Count > 0)
            _buildSummaryItem('★4', star4Count, Colors.purple),
          if (star3Count > 0)
            _buildSummaryItem('★3', star3Count, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '×$count',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
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
      default:
        return Colors.grey;
    }
  }
}