import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:paisapath/models/expense.dart';
import 'package:paisapath/navigation/app_navigation.dart';
import 'package:paisapath/providers/expense_provider.dart';
import 'package:paisapath/screens/dashboard_screen.dart';

import 'test_support/in_memory_store.dart';

/// Shared pump helper: builds the dashboard exactly as the real app does
/// (Provider + navigator with the /add-expense route) against an
/// in-memory store so tests never touch device storage.
///
/// Uses a tall test surface (800×1400 logical) so the state widgets and
/// transaction cards below the summary/chart section are actually built —
/// CustomScrollView lazy-builds children outside the viewport.
void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> pumpDashboard(
  WidgetTester tester, {
  required ExpenseProvider provider,
}) async {
  _useTallSurface(tester);
  await tester.pumpWidget(
    ChangeNotifierProvider<ExpenseProvider>.value(
      value: provider,
      child: MaterialApp(
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: const DashboardScreen(),
      ),
    ),
  );
  // First frame → ensureLoaded fired via post-frame callback.
  await tester.pump();
  await tester.pump();
}

Expense _sampleExpense(int id,
    {String category = 'Food',
    double amount = 120,
    String? description = 'Cafeteria coffee',
    String payment = 'UPI'}) {
  return Expense(
    id: id,
    type: TransactionType.expense,
    amount: amount,
    category: category,
    description: description,
    date: DateTime.now().subtract(Duration(minutes: id * 7)),
    paymentMethod: payment,
    createdAt: DateTime.now().subtract(Duration(minutes: id * 7)),
  );
}

void main() {
  testWidgets('DASHBOARD: renders summary + saved transactions correctly',
      (WidgetTester tester) async {
    final InMemoryStore store = InMemoryStore(seed: <Expense>[
      _sampleExpense(1),
      _sampleExpense(2, category: 'Travel', amount: 45, description: 'Bus fare'),
    ]);
    final ExpenseProvider provider = ExpenseProvider(store: store);
    await provider.loadExpenses();

    await pumpDashboard(tester, provider: provider);

    // Hero + summaries from real data.
    expect(find.text('Total Balance'), findsOneWidget);
    expect(find.text('Income'), findsAtLeastNWidgets(1));
    expect(find.text('Expenses'), findsAtLeastNWidgets(1));
    expect(find.textContaining('₹165'), findsAtLeastNWidgets(1)); // 120+45
    // Transaction cards from the store.
    expect(find.text('Cafeteria coffee'), findsOneWidget);
    expect(find.text('Bus fare'), findsOneWidget);
    expect(find.byIcon(Icons.edit_rounded, skipOffstage: false)
        .evaluate()
        .isEmpty, isTrue); // no phantom widgets leaking from other screens
    expect(find.text('2 records'), findsWidgets);
  });

  testWidgets('Dashboard empty state displays when no transactions exist',
      (WidgetTester tester) async {
    final ExpenseProvider provider = ExpenseProvider(store: InMemoryStore());
    await provider.loadExpenses();

    await pumpDashboard(tester, provider: provider);

    expect(find.text('Your ledger awaits'), findsOneWidget);
    expect(find.text('Start tracking your finances by adding your first transaction.'),
        findsOneWidget);
    expect(find.text('Add first transaction'), findsOneWidget);
  });

  testWidgets('Dashboard error state shows message and Retry button',
      (WidgetTester tester) async {
    final InMemoryStore store = InMemoryStore()..failOnLoad = true;
    final ExpenseProvider provider = ExpenseProvider(store: store);
    await provider.loadExpenses();

    await pumpDashboard(tester, provider: provider);

    expect(find.text('Something went wrong'), findsOneWidget);
    final Finder retryButton = find.widgetWithText(FilledButton, 'Retry');
    expect(retryButton, findsOneWidget);

    // Recover: fix the store and tap Retry.
    store.failOnLoad = false;
    store.seed = <Expense>[_sampleExpense(1)];
    // The fake loads seed data into the live map at construction/reset time,
    // so re-apply it after the simulated repair before Retry reloads.
    store.reset();
    await tester.tap(retryButton);
    await tester.pump();
    await tester.pump();

    expect(find.text('Something went wrong'), findsNothing);
    expect(find.text('Cafeteria coffee'), findsOneWidget);
  });

  testWidgets('Dashboard search filters the visible list',
      (WidgetTester tester) async {
    final InMemoryStore store = InMemoryStore(seed: <Expense>[
      _sampleExpense(1),
      _sampleExpense(2, category: 'Travel', amount: 45, description: 'Bus fare'),
    ]);
    final ExpenseProvider provider = ExpenseProvider(store: store);
    await provider.loadExpenses();

    await pumpDashboard(tester, provider: provider);

    await tester.enterText(find.byType(TextField), 'bus');
    await tester.pumpAndSettle();

    expect(find.text('Bus fare'), findsOneWidget);
    expect(find.text('Cafeteria coffee'), findsNothing);
    expect(find.text('1 record'), findsWidgets);
  });
}
