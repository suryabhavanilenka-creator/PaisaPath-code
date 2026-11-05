import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../screens/add_expense_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/statistics_screen.dart';
import '../utils/app_theme.dart';

/// Route names and the navigation shell (bottom navigation + FAB host).
class AppRoutes {
  static const String home = '/';
  static const String addExpense = '/add-expense';

  /// Push pages (no bottom nav) map to builders directly.
  static Route<void> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case addExpense:
        final Object? args = settings.arguments;
        final Expense? editTarget = args is Expense ? args : null;
        return MaterialPageRoute<void>(
          builder: (_) => AddExpenseScreen(editTarget: editTarget),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const _MainShell(),
          settings: settings,
        );
    }
  }
}

/// Screen index of the bottom navigation tabs.
enum TabItem { home, statistics, profile, settings }

/// Decides whether to show the first-launch onboarding or the main shell.
/// The choice is persisted in shared_preferences (`onboarding_done`).
class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key});

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  late final Future<bool> _seen = OnboardingScreen.hasSeen();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _seen,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          // Brief splash while the flag is read from storage.
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data != true) {
          return const OnboardingScreen();
        }
        return const _MainShell();
      },
    );
  }
}

/// Top-level shell hosting the main tabs and the dashboard FAB.
class _MainShell extends StatefulWidget {
  const _MainShell();

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  TabItem _current = TabItem.home;

  static const String _addHeroTag = 'add-expense-fab';

  @override
  Widget build(BuildContext context) {
    final bool showFab = _current == TabItem.home || _current == TabItem.statistics;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: IndexedStack(
        index: TabItem.values.indexOf(_current),
        children: const <Widget>[
          DashboardScreen(),
          StatisticsScreen(),
          ProfileScreen(),
          SettingsScreen(),
        ],
      ),
      // Center-docked round FAB, per the mockup design.
      floatingActionButton: showFab
          ? FloatingActionButton(
              heroTag: _addHeroTag,
              tooltip: 'Add Transaction',
              backgroundColor: AppTheme.primaryPlum,
              foregroundColor: Colors.white,
              elevation: 6,
              shape: const CircleBorder(),
              onPressed: () => _openAddExpense(context),
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomBar(
        current: _current,
        onSelected: (TabItem item) => setState(() => _current = item),
        scheme: scheme,
        isDark: Theme.of(context).brightness == Brightness.dark,
      ),
    );
  }

  void _openAddExpense(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.addExpense);
  }
}

/// Mockup-style bottom bar: four destinations with a centre gap where the
/// round FAB docks. Replaces the Material NavigationBar for this design.
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.current,
    required this.onSelected,
    required this.scheme,
    required this.isDark,
  });

  final TabItem current;
  final ValueChanged<TabItem> onSelected;
  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface2 : AppTheme.surfaceWhite,
        border: Border(
          top: BorderSide(color: scheme.outlineVariant, width: 0.8),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: <Widget>[
              _BarItem(
                item: TabItem.home,
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                current: current,
                onSelected: onSelected,
                scheme: scheme,
              ),
              _BarItem(
                item: TabItem.statistics,
                icon: Icons.insights_outlined,
                activeIcon: Icons.insights_rounded,
                label: 'Insights',
                current: current,
                onSelected: onSelected,
                scheme: scheme,
              ),
              // Centre gap for the docked FAB.
              const SizedBox(width: 72),
              _BarItem(
                item: TabItem.profile,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                current: current,
                onSelected: onSelected,
                scheme: scheme,
              ),
              _BarItem(
                item: TabItem.settings,
                icon: Icons.tune_outlined,
                activeIcon: Icons.tune_rounded,
                label: 'Settings',
                current: current,
                onSelected: onSelected,
                scheme: scheme,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  const _BarItem({
    required this.item,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.current,
    required this.onSelected,
    required this.scheme,
  });

  final TabItem item;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final TabItem current;
  final ValueChanged<TabItem> onSelected;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final bool selected = current == item;
    final Color color =
        selected ? AppTheme.primaryPlum : scheme.onSurfaceVariant;
    return Expanded(
      child: InkWell(
        onTap: () => onSelected(item),
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(selected ? activeIcon : icon, size: 23, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
