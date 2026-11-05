import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../widgets/category_icon.dart';
import 'add_expense_screen.dart';

/// Screen 2 — full detail view of a single transaction with edit & delete.
class ExpenseDetailScreen extends StatelessWidget {
  const ExpenseDetailScreen({super.key, required this.expense});

  final Expense expense;

  Future<void> _confirmDelete(BuildContext context) async {
    final ThemeData theme = Theme.of(context);
    final ExpenseProvider provider = context.read<ExpenseProvider>();

    // Immediately stop if we still see a provider (context valid here).
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: Icon(
            Icons.delete_forever_rounded,
            color: theme.colorScheme.error,
            size: 40,
          ),
          title: const Text('Delete transaction?'),
          content: const Text(
            'This will permanently remove this transaction. '
            'This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (provider.busy) return; // repeated fast taps on delete

    final bool ok = await provider.deleteExpense(expense.id!);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Transaction deleted'
            : 'Transaction not found — it may already be deleted'),
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.of(context).pop(); // back to the list either way
  }

  void _openEdit(BuildContext context) {
    Navigator.of(context)
        .push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => AddExpenseScreen(editTarget: expense),
          ),
        )
        .then((bool? updated) {
          // The add/edit screen signals success with `true`; close the stale
          // detail view so the dashboard shows the refreshed data.
          if (updated == true && context.mounted) {
            Navigator.of(context).pop();
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String headline =
        (expense.description ?? '').trim().isNotEmpty
            ? expense.description!.trim()
            : expense.category;
    final String? subline =
        headline == expense.category ? null : expense.category;

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction Details')),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // ---- Amount hero ----
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          CategoryIcon(
                            category: expense.category,
                            size: 58,
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                '${expense.isIncome ? '+' : '−'}${CurrencyFormatter.format(expense.amount)}',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: expense.isIncome
                                      ? scheme.secondary
                                      : scheme.primary,
                                ),
                              ),
                              Text(
                                expense.isIncome ? 'Income' : 'Expense',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        headline,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge,
                      ),
                      if (subline != null) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          subline,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // ---- Info rows ----
                Card(
                  child: Column(
                    children: <Widget>[
                      _row(context, 'Category', expense.category,
                          leading: const Icon(Icons.label_rounded)),
                      Divider(),
                      _row(context, 'Date', DateFormatter.format(expense.date),
                          leading: const Icon(Icons.calendar_month_rounded)),
                      Divider(),
                      _row(context, 'Time', _timeLabel(expense.date),
                          leading: const Icon(Icons.access_time_rounded)),
                      Divider(),
                      _row(context, 'Payment Method', expense.paymentMethod,
                          leading: const Icon(Icons.payments_rounded)),
                      Divider(),
                      _row(context, 'Transaction Type',
                          expense.isIncome ? 'Income' : 'Expense',
                          leading: const Icon(Icons.swap_vert_rounded)),
                      Divider(),
                      _row(
                        context,
                        'Description',
                        (expense.description ?? '').trim().isEmpty
                            ? 'No description'
                            : expense.description!,
                        leading: const Icon(Icons.notes_rounded),
                      ),
                      Divider(),
                      _row(
                        context,
                        'Recorded',
                        DateFormatter.formatWithTime(expense.createdAt),
                        leading: const Icon(Icons.history_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                // ---- Actions ----
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        onPressed: () => _openEdit(context),
                        icon: const Icon(Icons.edit_rounded, size: 20),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.error,
                          foregroundColor: scheme.onError,
                          minimumSize: const Size.fromHeight(50),
                        ),
                        onPressed: () => _confirmDelete(context),
                        icon: const Icon(Icons.delete_rounded, size: 20),
                        label: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back to list'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _timeLabel(DateTime date) {    const List<String> meridiem = <String>['AM', 'PM'];
    int hour = date.hour;
    final bool pm = hour >= 12;
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return '${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} ${meridiem[pm ? 1 : 0]}';
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    required Widget leading,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: <Widget>[
          IconTheme(
            data: IconThemeData(size: 20, color: scheme.onSurfaceVariant),
            child: leading,
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

