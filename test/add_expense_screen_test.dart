import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:paisapath/models/expense.dart';
import 'package:paisapath/providers/expense_provider.dart';
import 'package:paisapath/screens/add_expense_screen.dart';

import 'test_support/in_memory_store.dart';

/// Builds the form on a tall surface (800×1400 logical) so the Save button
/// at the bottom of the scrollable form is built and hit-testable.
///
/// The form is pushed above a host page so that the success path's
/// `Navigator.pop` reveals a real Scaffold underneath — that Scaffold
/// hosts the SnackBar the flow tests assert on.
void pumpFormSetup(WidgetTester tester, {Expense? editTarget}) {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> pumpForm(
  WidgetTester tester, {
  required ExpenseProvider provider,
}) async {
  pumpFormSetup(tester);
  await tester.pumpWidget(
    ChangeNotifierProvider<ExpenseProvider>.value(
      value: provider,
      child: MaterialApp(
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AddExpenseScreen(),
                  ),
                ),
                child: const Text('open form'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open form'));
  await tester.pumpAndSettle();
}

Expense sample(int id) => Expense(
      id: id,
      type: TransactionType.expense,
      amount: 50,
      category: 'Food',
      description: null,
      date: DateTime.now(),
      paymentMethod: 'Cash',
      createdAt: DateTime.now(),
    );

void main() {
  testWidgets('FORM: all required fields render correctly',
      (WidgetTester tester) async {
    final ExpenseProvider provider = ExpenseProvider(store: InMemoryStore());
    await pumpForm(tester, provider: provider);

    // Type selector is a custom Expense/Income toggle pair.
    expect(find.text('Expense'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2)); // amount + description
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Payment Method'), findsOneWidget);
    expect(find.text('Date'), findsOneWidget);
    expect(find.text('Food'), findsWidgets);
    expect(find.text('Save Transaction'), findsOneWidget);
  });

  testWidgets('FORM: empty amount is rejected with a clear error',
      (WidgetTester tester) async {
    final ExpenseProvider provider = ExpenseProvider(store: InMemoryStore());
    await pumpForm(tester, provider: provider);

    await tester.tap(find.text('Save Transaction'));
    await tester.pumpAndSettle();

    expect(find.text('Amount is required'), findsOneWidget);
    expect(find.text('Please select a payment method'), findsOneWidget);
    // Nothing saved.
    expect(provider.expenses, isEmpty);
  });

  testWidgets('FORM: zero amount is rejected', (WidgetTester tester) async {
    final ExpenseProvider provider = ExpenseProvider(store: InMemoryStore());
    await pumpForm(tester, provider: provider);

    await tester.enterText(find.byType(TextFormField).first, '0');
    await tester.tap(find.text('Save Transaction'));
    await tester.pumpAndSettle();

    expect(find.text('Amount must be greater than zero'), findsOneWidget);
    expect(provider.expenses, isEmpty);
  });

  testWidgets('FORM: non-numeric amount is rejected',
      (WidgetTester tester) async {
    final ExpenseProvider provider = ExpenseProvider(store: InMemoryStore());
    await pumpForm(tester, provider: provider);

    // Input formatters strip letters, so simulate the junk a paste could
    // still deliver: a malformed decimal that survives sanitising.
    final TextField field =
        tester.widget<TextField>(find.byType(TextField).first);
    field.controller!.text = '1.2.3';
    await tester.pump();

    await tester.tap(find.text('Save Transaction'));
    await tester.pumpAndSettle();

    expect(find.text('Amount must be numeric'), findsOneWidget);
    expect(provider.expenses, isEmpty);
  });

  testWidgets('FLOW: a complete valid expense saves and returns',
      (WidgetTester tester) async {
    final InMemoryStore store = InMemoryStore();
    final ExpenseProvider provider = ExpenseProvider(store: store);
    await pumpForm(tester, provider: provider);

    // 1. Amount (defaults to Expense type, today's date).
    await tester.enterText(find.byType(TextFormField).first, '480');
    await tester.pump();

    // 2. Category chip 'Food'.
    await tester.tap(find.text('Food').first);
    await tester.pump();

    // 3. Payment method dropdown.
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('UPI').last);
    await tester.pumpAndSettle();

    // 4. Save.
    await tester.tap(find.text('Save Transaction'));
    await tester.pumpAndSettle();

    // Success confirmation + back to dashboard-equivalent screen.
    expect(find.text('Expense saved successfully'), findsOneWidget);
    expect(store.count, 1);
    expect(provider.expenses.length, 1);
    expect(provider.expenses.first.amount, 480);
    expect(provider.expenses.first.category, 'Food');
    expect(provider.expenses.first.paymentMethod, 'UPI');
    expect(provider.expenses.first.type, TransactionType.expense);
  });

  testWidgets('FORM: edit mode pre-fills and updates via provider',
      (WidgetTester tester) async {
    final InMemoryStore store = InMemoryStore();
    final ExpenseProvider provider = ExpenseProvider(store: store);
    await provider.addExpense(sample(1));
    final Expense saved = provider.expenses.first;

    pumpFormSetup(tester);
    pumpFormSetup(tester);
    await tester.pumpWidget(
      ChangeNotifierProvider<ExpenseProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Builder(
            builder: (BuildContext context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AddExpenseScreen(editTarget: saved),
                    ),
                  ),
                  child: const Text('open form'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open form'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Transaction'), findsOneWidget);
    expect(find.text('Save Transaction'), findsNothing);
    expect(find.text('Update Transaction'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '650');
    await tester.tap(find.text('Update Transaction'));
    await tester.pumpAndSettle();

    expect(find.text('Transaction updated'), findsOneWidget);
    expect(provider.expenses.first.amount, 650);
  });
}
