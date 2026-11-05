import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../utils/date_formatter.dart';

/// Bottom sheet letting the user pick a month filter, built from months
/// that actually contain saved transactions (plus the current month).
class MonthFilterSheet extends StatelessWidget {
  const MonthFilterSheet({super.key, required this.months, this.selected});

  final List<String> months; // keys like '2026-11', newest first
  final String? selected;

  static Future<void> show(
    BuildContext context, {
    required List<String> months,
    required String? selected,
    required ValueChanged<String?> onSelected,
  }) async {
    final String? result = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) =>
          MonthFilterSheet(months: months, selected: selected),
    );
    if (result != null) onSelected(result);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text('Filter by month', style: theme.textTheme.titleLarge),
          ),
          ListTile(
            leading: const Icon(Icons.public_rounded),
            title: const Text('All time'),
            selected: selected == null,
            onTap: () => Navigator.of(context).pop(null),
          ),
          ...months.map<Widget>((String key) {
            final DateTime month = _monthFromKey(key);
            return ListTile(
              leading: const Icon(Icons.calendar_month_rounded),
              title: Text(DateFormatter.formatMonth(month)),
              selected: key == selected,
              onTap: () => Navigator.of(context).pop(key),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static DateTime _monthFromKey(String key) {
    final List<String> parts = key.split('-');
    final int year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final int month = int.tryParse(parts.length > 1 ? parts[1] : '') ?? DateTime.now().month;
    return DateTime(year, month);
  }
}

/// Parses a MonthFilterSheet selection back to a display label.
String monthLabelForKey(String key) {
  final DateTime month = _monthFromKeyPublic(key);
  return DateFormatter.formatMonth(month);
}

DateTime _monthFromKeyPublic(String key) {
  final List<String> parts = key.split('-');
  final int year = int.tryParse(parts[0]) ?? DateTime.now().year;
  final int month = int.tryParse(parts.length > 1 ? parts[1] : '') ?? DateTime.now().month;
  return DateTime(year, month);
}

/// Total records represented by an [Expense] list — helper for headers.
String transactionCountLabel(int count) =>
    count == 1 ? 'Transaction' : 'Transactions';
