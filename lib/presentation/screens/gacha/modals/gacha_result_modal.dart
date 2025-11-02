import 'package:flutter/material.dart';

class GachaResultModal extends StatelessWidget {
  final List<UserMonster> results;
  final VoidCallback onClose;

  const GachaResultModal({
    super.key,
    required this.results,
    required this.onClose,
  });

  static Future<void> show(
    BuildContext context, {
    required List<UserMonster> results,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GachaResultModal(
        results: results,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSingle = results.length == 1;

    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24.0),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isSingle ? '召喚結果' : '10連召喚結果',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: isSingle
                  ? _buildSingleResult(results.first)
                  : _buildMultiResults(results),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onClose,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('閉じる'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleResult(UserMonster monster) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // TODO: モンスター画像表示
        Container(
          width: 200,
          height: 200,
          color: _getRarityColor(monster.rarity),
          child: const Center(
            child: Icon(Icons.pets, size: 100, color: Colors.white),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          monster.name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            monster.rarity,
            (index) => const Icon(
              Icons.star,
              color: Colors.orange,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMultiResults(List<UserMonster> monsters) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: monsters.length,
      itemBuilder: (context, index) {
        final monster = monsters[index];
        return Card(
          color: _getRarityColor(monster.rarity),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // TODO: モンスター画像表示
              const Icon(Icons.pets, size: 48, color: Colors.white),
              const SizedBox(height: 4),
              Text(
                monster.name,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  monster.rarity,
                  (index) => const Icon(
                    Icons.star,
                    color: Colors.orange,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getRarityColor(int rarity) {
    switch (rarity) {
      case 5:
        return Colors.orange;
      case 4:
        return Colors.purple;
      case 3:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}