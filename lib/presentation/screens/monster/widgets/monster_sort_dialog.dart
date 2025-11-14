import 'package:flutter/material.dart';
import '../../../../core/models/monster_filter.dart';

/// モンスターソートダイアログ
/// 
/// レベル・レアリティ・取得日時などでソートします。
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
      title: const Text('ソート'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: MonsterSortType.values.map((sortType) {
          return RadioListTile<MonsterSortType>(
            title: Text(sortType.displayName),
            value: sortType,
            groupValue: currentSort,
            onChanged: (value) {
              if (value != null) {
                onSelect(value);
                Navigator.pop(context);
              }
            },
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}