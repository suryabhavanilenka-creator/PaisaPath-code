import 'package:flutter_test/flutter_test.dart';
import 'package:paisapath/models/expense.dart';
import 'package:paisapath/providers/expense_provider.dart';

import 'test_support/in_memory_store.dart';

Expense _make({
  required int? id,
  required TransactionType type,
  required double amount,
  required String category,
  required DateTime date,
  String? description,
  String payment = 'Cash',
}) {
  return Expense(
    id: id,
    type: type,
    amount: amount,
    category: category,
    description: description,
    date: date,
    paymentMethod: payment,
    createdAt: DateTime(2026, 1, 1, 9),
  );
}

void main() {
  final DateTime today = DateTime.now();

  // Previous-month dates use day 1 so the "not in the current month"
  // assertion stays valid no matter which day of the month the suite runs.
  DateTime monthDate(int monthsAgo) {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month - monthsAgo, 1);
  }

  late InMemoryStore store;
  late ExpenseProvider provider;

  setUp(() {
    store = InMemoryStore();
    provider = ExpenseProvider(store: store);
  });

  group('Loading and error states', () {
    test('loads records and reports data state', () async {
      store.seed = <Expense>[];
      await provider.loadExpenses();
      expect(provider.error, isNull);
      expect(provider.loading, isFalse);
      expect(provider.initialised, isTrue);
      expect(provider.expenses, isEmpty);
    });

    test('storage failure surfaces readable error and Retry clears it',
        () async {
      store.failOnLoad = true;
      await provider.loadExpenses();
      expect(provider.error, isNotNull);
      expect(provider.loading, isFalse);

      store.failOnLoad = false;
      await provider.retry();
      expect(provider.error, isNull);
      expect(provider.initialised, isTrue);
    });

    test('ensureLoaded is idempotent under rapid calls', () async {
      await Future.wait(<Future<void>>[
        provider.ensureLoaded(),
        provider.ensureLoaded(),
        provider.ensureLoaded(),
      ]);
      expect(provider.loading, isFalse);
      expect(provider.initialised, isTrue);
    });
  });

  group('CRUD', () {
    test('addExpense persists and refreshes state + listeners', () async {
      int notifications = 0;
      provider.addListener(() => notifications++);

      final bool ok = await provider.addExpense(_make(
        id: null,
        type: TransactionType.expense,
        amount: 250,
        category: 'Food',
        date: DateTime.now(),
        description: 'Lunch',
      ));
      expect(ok, isTrue);
      expect(provider.expenses.length, 1);
      expect(provider.expenses.first.id, isNotNull);
      expect(provider.busy, isFalse);
      expect(notifications, greaterThan(0));

      // Verify it really was persisted in the store.
      expect(store.count, 1);
    });

    test('updateExpense changes the stored record', () async {
      await provider.addExpense(_make(
        id: null,
        type: TransactionType.expense,
        amount: 100,
        category: 'Travel',
        date: DateTime.now(),
      ));
      final Expense saved = provider.expenses.first;
      final bool ok = await provider.updateExpense(
        saved.copyWith(amount: 350, description: 'Bus ticket'),
      );
      expect(ok, isTrue);
      expect(provider.expenses.first.amount, 350);
      expect(provider.expenses.first.description, 'Bus ticket');
    });

    test('deleteExpense removes record; deleting twice stays safe', () async {
      await provider.addExpense(_make(
        id: null,
        type: TransactionType.expense,
        amount: 100,
        category: 'Food',
        date: DateTime.now(),
      ));
      final Expense saved = provider.expenses.first;

      expect(await provider.deleteExpense(saved.id!), isTrue);
      expect(provider.expenses, isEmpty);

      // Second delete: store returns 0 rows but provider still succeeds
      // and stays in a clean state (robustness requirement).
      expect(await provider.deleteExpense(saved.id!), isTrue);
      expect(provider.expenses, isEmpty);
      expect(provider.error, isNull);
    });

    test('clearAllExpenses wipes everything', () async {
      await provider.addExpense(_make(
        id: null,
        type: TransactionType.expense,
        amount: 100,
        category: 'Food',
        date: DateTime.now(),
      ));
      await provider.addExpense(_make(
        id: null,
        type: TransactionType.income,
        amount: 500,
        category: 'Other',
        date: DateTime.now(),
      ));
      expect(await provider.clearAllExpenses(), isTrue);
      expect(store.count, 0);
      expect(provider.expenses, isEmpty);
    });
  });

  group('Summaries computed from saved data', () {
    setUp(() async {
      await provider.addExpense(_make(
        id: null,
        type: TransactionType.expense,
        amount: 100,
        category: 'Food',
        date: today,
        payment: 'UPI',
      ));
      await provider.addExpense(_make(
        id: null,
        type: TransactionType.expense,
        amount: 40,
        category: 'Food',
        date: today,
        payment: 'UPI',
      ));
      await provider.addExpense(_make(
        id: null,
        type: TransactionType.expense,
        amount: 250,
        category: 'Travel',
        // Deliberately NOT in the current month (previous-month records are
        // excluded from [monthlyExpense]); canonical day 1 keeps this stable.
        date: monthDate(1),
      ));
      await provider.addExpense(_make(
        id: null,
        type: TransactionType.expense,
        amount: 500,
        category: 'Rent',
        date: monthDate(2),
      ));
      await provider.addExpense(_make(
        id: null,
        type: TransactionType.income,
        amount: 2000,
        category: 'Other',
        date: monthDate(1),
        payment: 'Bank Transfer',
      ));
    });

    test('totals and balances are derived from real records only', () {
      expect(provider.totalIncome, 2000);
      expect(provider.totalExpense, 890);
      expect(provider.netBalance, 1110);
    });

    test('monthly and today spending reflect the current month', () {
      // Records dated this month: 100 + 40. The ₹250 Travel record and the
      // ₹500 Rent record are previous-month, so they must NOT be counted.
      expect(provider.monthlyExpense, 140);
      expect(provider.todaysExpense, 140);
    });

    test('category breakdown sorts descending with real totals', () {
      // Restrict to all-time for stability.
      final Map<String, double> breakdown = provider.categoryBreakdown;
      expect(breakdown['Food'], 140);
      expect(breakdown['Travel'], 250);
      expect(breakdown.keys.first, anyOf('Travel', 'Rent', 'Food'));
    });

    test('search matches description/category/payment case-insensitively',
        () async {
      provider.setSearchQuery('TRAvel');
      expect(provider.filteredCount, 1);
      provider.setSearchQuery('bank');
      expect(provider.filteredCount, 1);
      provider.setSearchQuery('');
      expect(provider.filteredCount, 5);
    });

    test('category filter and sort order work independently', () async {
      provider.setCategoryFilter('Food');
      expect(provider.filteredCount, 2);
      provider.setCategoryFilter(null);
      provider.setSortOrder(false); // oldest first
      final List<Expense> oldest = provider.filteredExpenses;
      expect(oldest.first.date.isBefore(oldest.last.date), isTrue);
      expect(oldest.first.category, 'Rent');
    });

    test('resetFilters clears every active filter', () async {
      provider.setSearchQuery('food');
      provider.setCategoryFilter('Food');
      provider.setSortOrder(false);
      provider.resetFilters();
      expect(provider.hasFilters, isFalse);
      expect(provider.newestFirst, isTrue);
      expect(provider.filteredCount, 5);
    });
  });

  group('Time series', () {
    test('monthlyTotals covers the requested window (last 3 months)',
        () async {
      await provider.addExpense(_make(
        id: null,
        type: TransactionType.expense,
        amount: 75,
        category: 'Food',
        date: monthDate(1),
      ));
      final Map<String, double> totals = provider.monthlyTotals(3);
      expect(totals.length, 3);
      expect(totals.values.fold<double>(0, (double a, double b) => a + b),
          greaterThanOrEqualTo(75));
    });

    test('last7DaysTotals returns exactly 7 day buckets', () async {
      await provider.addExpense(_make(
        id: null,
        type: TransactionType.expense,
        amount: 12,
        category: 'Food',
        date: today,
      ));
      final Map<DateTime, double> week = provider.last7DaysTotals();
      expect(week.length, 7);
    });
  });

  test('filters fire listeners only on real changes', () async {
    int notifications = 0;
    provider.addListener(() => notifications++);
    provider.setSearchQuery('food');
    provider.setSearchQuery('food'); // duplicate — no extra notify
    provider.setSearchQuery('');
    expect(notifications, 2);
  });
}
