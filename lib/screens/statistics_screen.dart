import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../widgets/category_icon.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/spending_chart.dart';

/// Analytics ranges offered on the Insights screen.
enum StatsRange {
  thisMonth,
  last3Months,
  thisYear,
  allTime;

  String get label {
    switch (this) {
      case StatsRange.thisMonth:
        return 'This Month';
      case StatsRange.last3Months:
        return 'Last 3 Months';
      case StatsRange.thisYear:
        return 'This Year';
      case StatsRange.allTime:
        return 'All Time';
    }
  }
}

/// Screen 2 — Insights: PaisaPath redesigned analytics dashboard.
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Insights',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Your financial picture',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: const _InsightsBody(),
    );
  }
}

class _InsightsBody extends StatefulWidget {
  const _InsightsBody();

  @override
  State<_InsightsBody> createState() => _InsightsBodyState();
}

class _InsightsBodyState extends State<_InsightsBody> {
  StatsRange _range = StatsRange.thisMonth;

  DateTime get _rangeStart {
    final DateTime now = DateTime.now();
    switch (_range) {
      case StatsRange.thisMonth:
        return DateTime(now.year, now.month);
      case StatsRange.last3Months:
        return DateTime(now.year, now.month - 2);
      case StatsRange.thisYear:
        return DateTime(now.year, 1);
      case StatsRange.allTime:
        return AppConstants.firstSelectableDate;
    }
  }

  bool _inRange(Expense e) =>
      !e.date.isBefore(_rangeStart) &&
      e.date.isBefore(DateTime.now().add(const Duration(days: 1)));

  @override
  Widget build(BuildContext context) {
    final ExpenseProvider provider = context.watch<ExpenseProvider>();
    final ThemeData theme = Theme.of(context);
    final bool bootLoading = provider.loading && !provider.initialised;
    final bool bootError = provider.error != null && !provider.initialised;

    if (bootLoading) {
      return const LoadingWidget(label: 'Crunching your numbers…');
    }
    if (bootError) {
      return AppErrorWidget(
        message: provider.error!,
        onRetry: context.read<ExpenseProvider>().retry,
      );
    }
    if (provider.expenses.isEmpty) {
      return const EmptyState(
        icon: Icons.bar_chart_outlined,
        title: 'No insights yet',
        message: 'Add transactions to unlock your spending story.',
      );
    }

    final List<Expense> ranged = provider.expenses.where(_inRange).toList();
    final double income = _sum(ranged, (Expense e) => e.isIncome);
    final double expense = _sum(ranged, (Expense e) => e.isExpense);
    final double net = income - expense;
    final double savings = income > 0 ? ((net / income) * 100).clamp(0, 100) : 0;

    final Map<String, double> byCategory = <String, double>{};
    for (final Expense e in ranged.where((Expense e) => e.isExpense)) {
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
    }
    final List<MapEntry<String, double>> sortedCategories =
        byCategory.entries.toList()
          ..sort((MapEntry<String, double> a, MapEntry<String, double> b) =>
              b.value.compareTo(a.value));
    final double categoryTotal = expense;

    final Map<String, double> months6 = provider.monthlyTotals(6);
    final Map<int, double> dailies =
        provider.dailyTotalsForMonth(DateTime.now());

    final int elapsedDays = DateTime.now().difference(_rangeStart).inDays + 1;
    final double avgDaily = elapsedDays > 0 ? expense / elapsedDays : 0;

    final MapEntry<String, double>? highest =
        sortedCategories.isEmpty ? null : sortedCategories.first;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // ── Range selector ──────────────────────────────────────────
          _RangeSelector(
            selected: _range,
            onChanged: (StatsRange r) => setState(() => _range = r),
          ),
          const SizedBox(height: 16),

          // ── Hero summary card ───────────────────────────────────────
          _InsightHeroCard(
            income: income,
            expense: expense,
            net: net,
            savings: savings,
          ),
          const SizedBox(height: 14),

          // ── Highlights row ──────────────────────────────────────────
          Row(
            children: <Widget>[
              Expanded(
                child: _HighlightTile(
                  label: 'Top Category',
                  value: highest?.key ?? '–',
                  icon: Icons.star_rounded,
                  iconColor: AppTheme.accentCoral,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HighlightTile(
                  label: 'Avg / Day',
                  value: CurrencyFormatter.formatShort(avgDaily),
                  icon: Icons.av_timer_rounded,
                  iconColor: AppTheme.secondaryTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Monthly income vs expenses (grouped bars) ───────────────
          _PanelCard(
            title: 'Monthly Trend',
            subtitle: 'Last 6 months · income vs expenses',
            accentColor: AppTheme.primaryPlum,
            child: SpendingChart(
              height: 170,
              labels: months6.keys
                  .map((String key) => _monthShort(key))
                  .toList(),
              values: months6.values.toList(),
              secondaryValues:
                  provider.monthlyIncomeTotals(6).values.toList(),
              showValueLabels: true,
            ),
          ),
          const SizedBox(height: 14),

          // ── Daily spending ──────────────────────────────────────────
          _PanelCard(
            title: 'Daily Spending',
            subtitle: DateFormatter.formatMonth(DateTime.now()),
            accentColor: AppTheme.secondaryTeal,
            child: SpendingChart(
              height: 150,
              labels: dailies.keys
                  .map((int day) =>
                      day == 1 ||
                              day == 5 ||
                              day % 5 == 0 ||
                              day == dailies.length
                          ? '$day'
                          : '')
                  .toList(),
              values: dailies.values.toList(),
            ),
          ),
          const SizedBox(height: 16),

          // ── Category breakdown ──────────────────────────────────────
          _PanelCard(
            title: 'Category Breakdown',
            subtitle:
                '${sortedCategories.length} ${sortedCategories.length == 1 ? 'category' : 'categories'} in range',
            accentColor: AppTheme.accentCoral,
            child: sortedCategories.isEmpty
                ? Text(
                    'No expenses in this period. Add some to see your breakdown.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                : Column(
                    children: <Widget>[
                      for (int i = 0; i < sortedCategories.length; i++)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: i == sortedCategories.length - 1 ? 0 : 14,
                          ),
                          child: _CategoryBreakdownRow(
                            category: sortedCategories[i].key,
                            amount: sortedCategories[i].value,
                            max: sortedCategories.first.value,
                            total: categoryTotal,
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  static double _sum(Iterable<Expense> items, bool Function(Expense) predicate) {
    double sum = 0;
    for (final Expense e in items) {
      if (predicate(e)) sum += e.amount;
    }
    return sum;
  }

  static String _monthShort(String key) {
    const List<String> months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final List<String> parts = key.split('-');
    final int month = int.tryParse(parts.length > 1 ? parts[1] : '1') ?? 1;
    return months[(month - 1).clamp(0, 11)];
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Range Selector
// ────────────────────────────────────────────────────────────────────────────
class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.selected, required this.onChanged});
  final StatsRange selected;
  final ValueChanged<StatsRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: StatsRange.values.map((StatsRange r) {
          final bool sel = selected == r;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.primaryPlum : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: sel
                        ? AppTheme.primaryPlum
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Text(
                  r.label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: sel
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Hero Summary Card (Income / Expense / Net / Savings %)
// ────────────────────────────────────────────────────────────────────────────
class _InsightHeroCard extends StatelessWidget {
  const _InsightHeroCard({
    required this.income,
    required this.expense,
    required this.net,
    required this.savings,
  });

  final double income;
  final double expense;
  final double net;
  final double savings;

  @override
  Widget build(BuildContext context) {
    final bool isPositive = net >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppTheme.primaryPlum,
            const Color(0xFF6B3A6A),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.primaryPlum.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _HeroFigure(
                  label: 'Income',
                  value: CurrencyFormatter.formatShort(income),
                  color: AppTheme.secondaryTeal,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _HeroFigure(
                  label: 'Expenses',
                  value: CurrencyFormatter.formatShort(expense),
                  color: AppTheme.accentCoral,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Net Balance',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    Text(
                      '${isPositive ? '+' : ''}${CurrencyFormatter.formatShort(net)}',
                      style: TextStyle(
                        color: isPositive ? AppTheme.secondaryTeal : AppTheme.accentCoral,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    const Text(
                      'Savings Rate',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    Text(
                      '${savings.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroFigure extends StatelessWidget {
  const _HeroFigure({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Highlight tile
// ────────────────────────────────────────────────────────────────────────────
class _HighlightTile extends StatelessWidget {
  const _HighlightTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isLight = theme.brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: isLight
            ? <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Panel card (chart wrapper)
// ────────────────────────────────────────────────────────────────────────────
class _PanelCard extends StatelessWidget {
  const _PanelCard({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.accentColor,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isLight = theme.brightness == Brightness.light;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: isLight
            ? <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text(
                      subtitle,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Category Breakdown Row
// ────────────────────────────────────────────────────────────────────────────
class _CategoryBreakdownRow extends StatelessWidget {
  const _CategoryBreakdownRow({
    required this.category,
    required this.amount,
    required this.max,
    required this.total,
  });

  final String category;
  final double amount;
  final double max;
  final double total;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final double fraction = max <= 0 ? 0 : (amount / max).clamp(0.0, 1.0);
    final int percent =
        total <= 0 ? 0 : ((amount / total) * 100).round();
    final Color catColor = AppConstants.colorFor(category);

    return Row(
      children: <Widget>[
        CategoryIcon(category: category, size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      category,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatShort(amount),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 6,
                        backgroundColor:
                            scheme.outlineVariant.withValues(alpha: 0.5),
                        valueColor: AlwaysStoppedAnimation<Color>(catColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '$percent%',
                      textAlign: TextAlign.right,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
