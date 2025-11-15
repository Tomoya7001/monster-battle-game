import 'package:flutter/material.dart';
import '../../../../core/models/monster_filter.dart';

/// モンスターフィルターダイアログ
class MonsterFilterDialog extends StatefulWidget {
  final MonsterFilter currentFilter;
  final Function(MonsterFilter) onApply;

  const MonsterFilterDialog({
    super.key,
    required this.currentFilter,
    required this.onApply,
  });

  @override
  State<MonsterFilterDialog> createState() => _MonsterFilterDialogState();
}

class _MonsterFilterDialogState extends State<MonsterFilterDialog> {
  late String? _selectedSpecies;
  late String? _selectedElement;
  late int? _selectedRarity;
  late bool _favoriteOnly;
  late bool _lockedOnly;

  final List<String> speciesList = [
    'angel',
    'demon',
    'human',
    'spirit',
    'mechanoid',
    'dragon',
    'mutant',
  ];

  final Map<String, String> speciesNameMap = {
    'angel': '天使',
    'demon': '悪魔',
    'human': 'ヒューマン',
    'spirit': '精霊',
    'mechanoid': '機械',
    'dragon': 'ドラゴン',
    'mutant': 'ミュータント',
  };

  final List<String> elementList = [
    'fire',
    'water',
    'thunder',
    'wind',
    'earth',
    'light',
    'dark',
  ];

  final Map<String, String> elementNameMap = {
    'fire': '火',
    'water': '水',
    'thunder': '雷',
    'wind': '風',
    'earth': '土',
    'light': '光',
    'dark': '闇',
  };

  final List<int> rarityList = [2, 3, 4, 5];

  @override
  void initState() {
    super.initState();
    _selectedSpecies = widget.currentFilter.species;
    _selectedElement = widget.currentFilter.element;
    _selectedRarity = widget.currentFilter.rarity;
    _favoriteOnly = widget.currentFilter.favoriteOnly ?? false;
    _lockedOnly = widget.currentFilter.lockedOnly ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('フィルター'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 種族フィルター
            const Text(
              '種族',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildFilterChip(
                  label: 'すべて',
                  selected: _selectedSpecies == null,
                  onTap: () => setState(() => _selectedSpecies = null),
                ),
                ...speciesList.map((species) {
                  return _buildFilterChip(
                    label: speciesNameMap[species] ?? species,
                    selected: _selectedSpecies == species,
                    onTap: () => setState(() => _selectedSpecies = species),
                  );
                }),
              ],
            ),
            const SizedBox(height: 16),

            // 属性フィルター
            const Text(
              '属性',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildFilterChip(
                  label: 'すべて',
                  selected: _selectedElement == null,
                  onTap: () => setState(() => _selectedElement = null),
                ),
                ...elementList.map((element) {
                  return _buildFilterChip(
                    label: elementNameMap[element] ?? element,
                    selected: _selectedElement == element,
                    onTap: () => setState(() => _selectedElement = element),
                  );
                }),
              ],
            ),
            const SizedBox(height: 16),

            // レアリティフィルター
            const Text(
              'レアリティ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildFilterChip(
                  label: 'すべて',
                  selected: _selectedRarity == null,
                  onTap: () => setState(() => _selectedRarity = null),
                ),
                ...rarityList.map((rarity) {
                  return _buildFilterChip(
                    label: '★$rarity',
                    selected: _selectedRarity == rarity,
                    onTap: () => setState(() => _selectedRarity = rarity),
                  );
                }),
              ],
            ),
            const SizedBox(height: 16),

            // その他フィルター
            const Text(
              'その他',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('お気に入りのみ'),
              value: _favoriteOnly,
              onChanged: (value) {
                setState(() => _favoriteOnly = value ?? false);
              },
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            CheckboxListTile(
              title: const Text('ロック中のみ'),
              value: _lockedOnly,
              onChanged: (value) {
                setState(() => _lockedOnly = value ?? false);
              },
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: () {
            // すべてクリア
            setState(() {
              _selectedSpecies = null;
              _selectedElement = null;
              _selectedRarity = null;
              _favoriteOnly = false;
              _lockedOnly = false;
            });
          },
          child: const Text('クリア'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApply(MonsterFilter(
              species: _selectedSpecies,
              element: _selectedElement,
              rarity: _selectedRarity,
              favoriteOnly: _favoriteOnly,
              lockedOnly: _lockedOnly,
            ));
            Navigator.pop(context);
          },
          child: const Text('適用'),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: Colors.blue.withOpacity(0.3),
      checkmarkColor: Colors.blue,
    );
  }
}