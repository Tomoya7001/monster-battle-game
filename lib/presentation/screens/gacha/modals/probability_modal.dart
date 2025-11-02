import 'package:flutter/material.dart';

/// 排出確率モーダル
/// 
/// ガチャの排出確率を表示
/// Day 2: 基本的な確率表示
/// Week 8: ピックアップガチャの詳細確率
class ProbabilityModal extends StatelessWidget {
  const ProbabilityModal({super.key});

  /// モーダルを表示
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const ProbabilityModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '排出確率',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // 注意書き
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '提供割合の合算値であり、実際の出現率とは異なる場合があります',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 確率リスト
          Expanded(
            child: ListView(
              children: [
                const Text(
                  'レアリティ別確率',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildProbabilityItem(
                  rarity: '★★★★★',
                  probability: '2%',
                  color: Colors.orange,
                  description: 'ウルトラレア',
                ),
                _buildProbabilityItem(
                  rarity: '★★★★',
                  probability: '15%',
                  color: Colors.purple,
                  description: 'スーパーレア',
                ),
                _buildProbabilityItem(
                  rarity: '★★★',
                  probability: '30%',
                  color: Colors.blue,
                  description: 'レア',
                ),
                _buildProbabilityItem(
                  rarity: '★★',
                  probability: '53%',
                  color: Colors.grey,
                  description: 'ノーマル',
                ),
                
                const Divider(height: 32),
                
                // 天井システムの説明
                const Text(
                  '天井システム',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildInfoCard(
                  icon: Icons.auto_awesome,
                  title: '100連で★5確定',
                  description: '100連以内に★5が出なかった場合、100連目で★5が確定で排出されます。',
                ),
                
                const SizedBox(height: 12),
                
                _buildInfoCard(
                  icon: Icons.trending_up,
                  title: 'カウンター継続',
                  description: '天井到達後もカウンターは継続し、200連目で再度★5が確定します。',
                ),
                
                const SizedBox(height: 12),
                
                _buildInfoCard(
                  icon: Icons.refresh,
                  title: 'ガチャ別カウント',
                  description: '天井カウンターはガチャの種類ごとに独立してカウントされます。',
                ),
                
                const SizedBox(height: 24),
                
                // 10連の保証
                const Text(
                  '10連ガチャの保証',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildInfoCard(
                  icon: Icons.verified,
                  title: '★3以上確定',
                  description: '10連ガチャでは、10回のうち少なくとも1回は★3以上のモンスターが排出されます。',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 確率アイテム
  Widget _buildProbabilityItem({
    required String rarity,
    required String probability,
    required Color color,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // カラーインジケーター
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          // レアリティ情報
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rarity,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // 確率
          Text(
            probability,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 情報カード
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}