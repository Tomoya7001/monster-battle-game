import 'package:flutter/material.dart';
import '../../../../domain/entities/monster.dart';

/// ガチャ結果表示モーダル
/// 
/// Day 4: 基本実装
/// Day 5-6: 演出追加
class GachaResultModal extends StatelessWidget {
  final List<Monster> results;
  final VoidCallback onClose;

  const GachaResultModal({
    super.key,
    required this.results,
    required this.onClose,
  });

  /// モーダルを表示
  static Future<void> show(
    BuildContext context, {
    required List<Monster> results,
    required VoidCallback onClose,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GachaResultModal(
        results: results,
        onClose: onClose,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSingle = results.length == 1;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // タイトル
            Text(
              isSingle ? '召喚結果' : '10連召喚結果',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // 結果表示（スクロール可能）
            Flexible(
              child: SingleChildScrollView(
                child: isSingle
                    ? _buildSingleResult(results.first)
                    : _buildMultiResults(results),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 閉じるボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onClose();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '閉じる',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 単発結果表示
  Widget _buildSingleResult(Monster monster) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // レアリティ表示
        _buildRarityStars(monster.rarity),
        const SizedBox(height: 16),
        
        // モンスター画像(仮)
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: _getRarityColor(monster.rarity).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getRarityColor(monster.rarity),
              width: 3,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.pets,
              size: 120,
              color: _getRarityColor(monster.rarity),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // モンスター名
        Text(
          monster.name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        // レベル表示
        Text(
          'Lv.${monster.level}',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// 10連結果表示
  Widget _buildMultiResults(List<Monster> monsters) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: monsters.length,
      itemBuilder: (context, index) {
        final monster = monsters[index];
        return _buildResultCard(monster);
      },
    );
  }

  /// 結果カード
  Widget _buildResultCard(Monster monster) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _getRarityColor(monster.rarity).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getRarityColor(monster.rarity),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // モンスター画像(仮)
          Icon(
            Icons.pets,
            size: 40,
            color: _getRarityColor(monster.rarity),
          ),
          const SizedBox(height: 4),
          
          // モンスター名
          Text(
            monster.name,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          
          // レアリティ星
          _buildRarityStars(monster.rarity, size: 10),
        ],
      ),
    );
  }

  /// レアリティの星表示
  Widget _buildRarityStars(int rarity, {double size = 20}) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 2,
      children: List.generate(
        rarity,
        (index) => Icon(
          Icons.star,
          color: _getRarityColor(rarity),
          size: size,
        ),
      ),
    );
  }

  /// レアリティに応じた色を取得
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