import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../services/update_service.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_widget.dart';
import '../widgets/expense_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/month_filter_sheet.dart';
import '../widgets/spending_chart.dart';
import 'expense_detail_screen.dart';

/// Screen 1 — Dashboard (PaisaPath redesign): financial summary,
/// spending overview chart and the searchable / filterable transaction list.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _DashboardLifecycle(
      child: _DashboardBody(),
    );
  }
}

class _DashboardLifecycle extends StatefulWidget {
  const _DashboardLifecycle({required this.child});
  final Widget child;

  @override
  State<_DashboardLifecycle> createState() => _DashboardLifecycleState();
}

class _DashboardLifecycleState extends State<_DashboardLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ExpenseProvider>().ensureLoaded();
        _checkForAppUpdate();
      }
    });
  }

  Future<void> _checkForAppUpdate() async {
    final AppUpdateInfo? update = await const UpdateService().checkForUpdate();
    if (update == null || !update.updateAvailable || !mounted) return;
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        // ignore: unused_local_variable
        return AlertDialog(
          icon: Icon(Icons.system_update_alt_rounded,
              color: AppTheme.primaryPlum, size: 36),
          title: const Text('Update available'),
          content: Text(
            'PaisaPath ${update.latestVersion} is available '
            '(you have ${update.currentVersion}).\n\n'
            'Download the new APK, then install it — your data is kept.',
            style: const TextStyle(fontSize: 13),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Later'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Download update'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                launchUrl(
                  Uri.parse(update.apkUrl),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: <Widget>[
            // PaisaPath logo mark
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.primaryPlum,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'P',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                RichText(
                  text: TextSpan(
                    children: <TextSpan>[
                      TextSpan(
                        text: 'Paisa',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryPlum,
                          letterSpacing: -0.3,
                        ),
                      ),
                      TextSpan(
                        text: 'Path',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.secondaryTeal,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              DateFormat('d MMM').format(DateTime.now()),
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        shape: const Border(),
      ),
      body: RefreshIndicator.adaptive(
        color: AppTheme.primaryPlum,
        onRefresh: () => context.read<ExpenseProvider>().loadExpenses(),
        child: const _DashboardScroll(),
      ),
    );
  }
}

class _DashboardScroll extends StatelessWidget {
  const _DashboardScroll();

  void _openDetail(BuildContext context, Expense expense) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExpenseDetailScreen(expense: expense),
      ),
    );
  }

  void _openAddExpense(BuildContext context) {
    Navigator.of(context).pushNamed('/add-expense');
  }

  @override
  Widget build(BuildContext context) {
    final ExpenseProvider provider = context.watch<ExpenseProvider>();
    final bool bootLoading = provider.loading && !provider.initialised;
    final bool bootError = provider.error != null && !provider.initialised;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        // ── Greeting + Net Balance Hero ────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _GreetingHero(provider: provider),
          ),
        ),
        // ── 7-day Spending Overview ────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _SpendingOverview(provider: provider),
          ),
        ),
        // ── Transactions header ────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _TransactionsHeader(provider: provider, onAdd: () => _openAddExpense(context)),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          sliver: SliverToBoxAdapter(child: _SearchField(provider: provider)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _FilterControls(provider: provider),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _CategoryFilterChips(provider: provider),
          ),
        ),
        // ── Type filter tabs ───────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _TypeFilterTabs(provider: provider),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        // ── Content states ─────────────────────────────────────────────
        if (bootLoading)
          const SliverToBoxAdapter(child: LoadingWidget())
        else if (bootError)
          SliverToBoxAdapter(
            child: AppErrorWidget(
              message: provider.error!,
              onRetry: context.read<ExpenseProvider>().retry,
            ),
          )
        else if (provider.expenses.isEmpty)
          SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.savings_rounded,
              title: 'Your ledger awaits',
              message: 'Start tracking your finances by adding your first transaction.',
              ctaLabel: 'Add first transaction',
              onCta: () => _openAddExpense(context),
            ),
          )
        else if (provider.filteredExpenses.isEmpty)
          const SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No matching transactions',
              message: 'Nothing matches your current search or filters.',
              ctaLabel: null,
              onCta: null,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
            sliver: SliverList.separated(
              itemCount: provider.filteredExpenses.length,
              separatorBuilder: (BuildContext ctx, int _) =>
                  const SizedBox(height: 6),
              itemBuilder: (BuildContext ctx, int index) {
                final List<Expense> items = provider.filteredExpenses;
                final Expense expense = items[index];
                // Group transactions under day headers (Today / Yest / date)
                // — a ledger-style structure.
                final bool startsNewDay = index == 0 ||
                    !_isSameDay(items[index - 1].date, expense.date);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (startsNewDay)
                      _DayHeader(date: expense.date),
                    ExpenseCard(
                      expense: expense,
                      onTap: () => _openDetail(context, expense),
                    ),
                  ],
                );
              },
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Greeting + Net Balance Hero card
// ────────────────────────────────────────────────────────────────────────────
class _GreetingHero extends StatelessWidget {
  const _GreetingHero({required this.provider});
  final ExpenseProvider provider;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double balance = provider.netBalance;
    final bool isPositive = balance >= 0;
    // Share of income that remains (savings rate), for the ring gauge.
    final double income = provider.totalIncome;
    final double expense = provider.totalExpense;
    final double savedRatio =
        income > 0 ? ((income - expense) / income).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // ── Greeting header (outside the card — different structure) ────
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      DateFormatter.greeting(DateTime.now()),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('EEEE, d MMMM').format(DateTime.now()),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (isPositive
                          ? AppTheme.incomeGreen
                          : AppTheme.expenseRed)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      isPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: isPositive
                          ? AppTheme.incomeGreen
                          : AppTheme.expenseRed,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPositive ? 'Surplus' : 'Deficit',
                      style: TextStyle(
                        color: isPositive
                            ? AppTheme.incomeGreen
                            : AppTheme.expenseRed,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Balance card: horizontal layout with savings ring ───────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: <Color>[
                AppTheme.primaryPlum,
                const Color(0xFF6B3A6A), // slightly lighter plum
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppTheme.primaryPlum.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Total Balance',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Scales down instead of truncating long ₹ amounts.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        CurrencyFormatter.format(balance.abs()),
                        maxLines: 1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      income > 0
                          ? 'You kept ${(savedRatio * 100).toStringAsFixed(0)}% of your income'
                          : 'Add income to see your savings rate',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 84,
                height: 84,
                child: CustomPaint(
                  painter: _SavingsRingPainter(
                    ratio: savedRatio,
                    trackColor: Colors.white.withValues(alpha: 0.15),
                    progressColor: AppTheme.secondaryTeal,
                  ),
                  child: Center(
                    child: Text(
                      income > 0
                          ? '${(savedRatio * 100).toStringAsFixed(0)}%'
                          : '–',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Income / Expenses chips BELOW the card (different structure) ─
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: <Widget>[
              Expanded(
                child: _MoneyChip(
                  icon: Icons.south_west_rounded,
                  label: 'Income',
                  value: CurrencyFormatter.formatShort(provider.totalIncome),
                  accent: AppTheme.incomeGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MoneyChip(
                  icon: Icons.north_east_rounded,
                  label: 'Expenses',
                  value: CurrencyFormatter.formatShort(provider.totalExpense),
                  accent: AppTheme.expenseRed,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Ring gauge showing the share of income kept (savings rate).
class _SavingsRingPainter extends CustomPainter {
  _SavingsRingPainter({
    required this.ratio,
    required this.trackColor,
    required this.progressColor,
  });

  final double ratio;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.shortestSide / 2 - 5;
    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..color = trackColor,
    );
    canvas.drawArc(
      arcRect,
      -3.14159 / 2, // start at 12 o'clock
      3.14159 * 2 * ratio,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..color = progressColor,
    );
  }

  @override
  bool shouldRepaint(covariant _SavingsRingPainter oldDelegate) =>
      oldDelegate.ratio != ratio ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.progressColor != progressColor;
}

/// Compact income/expense chip shown below the balance card.
class _MoneyChip extends StatelessWidget {
  const _MoneyChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                // Scales down instead of truncating long ₹ amounts.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                      color: accent,
                    ),
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

// ────────────────────────────────────────────────────────────────────────────
// 7-day Spending Overview
// ────────────────────────────────────────────────────────────────────────────
class _SpendingOverview extends StatelessWidget {
  const _SpendingOverview({required this.provider});
  final ExpenseProvider provider;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isLight = theme.brightness == Brightness.light;
    final Map<DateTime, double> last7 = provider.last7DaysTotals();
    double total = 0;
    for (final double v in last7.values) {
      total += v;
    }

    return Container(
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
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryPlum,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Spending Path',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentCoral.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '7d · ${CurrencyFormatter.formatShort(total)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accentCoral,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SpendingChart(
            height: 130,
            labels: last7.keys
                .map((DateTime d) => DateFormatter.dayLabel(d))
                .toList(),
            values: last7.values.toList(),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Transactions section header
// ────────────────────────────────────────────────────────────────────────────
class _TransactionsHeader extends StatelessWidget {
  const _TransactionsHeader({required this.provider, required this.onAdd});
  final ExpenseProvider provider;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Transactions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${provider.filteredCount} ${provider.filteredCount == 1 ? 'record' : 'records'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Type filter tabs (All / Expense / Income)
// ────────────────────────────────────────────────────────────────────────────
class _TypeFilterTabs extends StatelessWidget {
  const _TypeFilterTabs({required this.provider});
  final ExpenseProvider provider;

  @override
  Widget build(BuildContext context) {

    const List<(String, String)> tabs = <(String, String)>[
      ('all', 'All'),
      ('expense', 'Expenses'),
      ('income', 'Income'),
    ];
    return Row(
      children: tabs.map(((String, String) tab) {
        final bool selected = provider.typeFilter == tab.$1;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _TypeTab(
            label: tab.$2,
            selected: selected,
            onTap: () => provider.setTypeFilter(tab.$1),
          ),
        );
      }).toList(),
    );
  }
}

class _TypeTab extends StatelessWidget {
  const _TypeTab({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryPlum : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primaryPlum : Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Search field
// ────────────────────────────────────────────────────────────────────────────
class _SearchField extends StatefulWidget {
  const _SearchField({required this.provider});
  final ExpenseProvider provider;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ExpenseProvider provider = widget.provider;

    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.search,
      onChanged: provider.setSearchQuery,
      decoration: InputDecoration(
        hintText: 'Search transactions…',
        prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.onSurfaceVariant),
        suffixIcon: provider.searchQuery.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () {
                  _controller.clear();
                  provider.setSearchQuery('');
                  FocusManager.instance.primaryFocus?.unfocus();
                },
              ),
      ),
      style: theme.textTheme.bodyMedium,
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Filter controls (Month + Sort)
// ────────────────────────────────────────────────────────────────────────────
class _FilterControls extends StatelessWidget {
  const _FilterControls({required this.provider});
  final ExpenseProvider provider;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: FilterPill(
            icon: Icons.calendar_today_rounded,
            label: provider.monthFilter == null
                ? 'All Time'
                : monthLabelForKey(provider.monthFilter!),
            active: provider.monthFilter != null,
            onTap: () => MonthFilterSheet.show(
              context,
              months: provider.availableMonths,
              selected: provider.monthFilter,
              onSelected: provider.setMonthFilter,
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilterPill(
          icon: provider.newestFirst
              ? Icons.arrow_downward_rounded
              : Icons.arrow_upward_rounded,
          label: provider.newestFirst ? 'Newest' : 'Oldest',
          active: true,
          onTap: provider.toggleSortOrder,
        ),
      ],
    );
  }
}

/// Styled pill filter button.
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color fg = active ? AppTheme.primaryPlum : Theme.of(context).colorScheme.onSurfaceVariant;
    final Color bg = active
        ? AppTheme.primaryPlum.withValues(alpha: 0.10)
        : Theme.of(context).colorScheme.surfaceContainerLow;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Category filter chips
// ────────────────────────────────────────────────────────────────────────────
class _CategoryFilterChips extends StatelessWidget {
  const _CategoryFilterChips({required this.provider});
  final ExpenseProvider provider;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          _choiceChip(
            context,
            label: 'All',
            icon: Icons.apps_rounded,
            selected: provider.categoryFilter == null,
            onSelected: (_) => provider.setCategoryFilter(null),
          ),
          const SizedBox(width: 6),
          for (int i = 0; i < AppConstants.categories.length; i++)
            Padding(
              padding: EdgeInsets.only(
                right: i == AppConstants.categories.length - 1 ? 0 : 6,
              ),
              child: _choiceChip(
                context,
                label: AppConstants.categories[i],
                icon: AppConstants.categoryIcons[i],
                selected: provider.categoryFilter == AppConstants.categories[i],
                onSelected: (bool sel) => provider.setCategoryFilter(
                  sel ? AppConstants.categories[i] : null,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _choiceChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    final ThemeData theme = Theme.of(context);
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            size: 13,
            color: selected ? AppTheme.primaryPlum : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: onSelected,
      selectedColor: AppTheme.primaryPlum.withValues(alpha: 0.10),
      side: BorderSide(
        color: selected ? AppTheme.primaryPlum.withValues(alpha: 0.5) : theme.colorScheme.outlineVariant,
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? AppTheme.primaryPlum : theme.colorScheme.onSurfaceVariant,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}


/// Ledger-style day separator above a group of transactions.
class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 10, bottom: 2),
      child: Text(
        DateFormatter.dayLabel(date),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
