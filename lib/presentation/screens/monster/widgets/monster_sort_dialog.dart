// lib/presentation/screens/monster/widgets/monster_sort_dialog.dart

import 'package:flutter/material.dart';
import '../../../../core/models/monster_filter.dart';

class MonsterSortDialog extends StatelessWidget {
  final MonsterSortType currentSort;
  final Function(MonsterSortType) onSelect;

  const MonsterSortDialog({
    super.key,
    required this.currentSort,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('並び替え'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: MonsterSortType.values.length,
          itemBuilder: (context, index) {
            final sortType = MonsterSortType.values[index];
            final isSelected = sortType == currentSort;

            return ListTile(
              title: Text(sortType.displayName),
              trailing: isSelected
                  ? Icon(
                      Icons.check,
                      color: Theme.of(context).primaryColor,
                    )
                  : null,
              selected: isSelected,
              onTap: () {
                onSelect(sortType);
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
      ],
    );
  }
}