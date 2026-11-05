import 'package:flutter_test/flutter_test.dart';
import 'package:paisapath/models/expense.dart';
import 'package:paisapath/utils/currency_formatter.dart';
import 'package:paisapath/utils/date_formatter.dart';
import 'package:paisapath/utils/app_constants.dart';

void main() {
  group('Expense model', () {
    test('toMap → fromMap round-trips all fields', () {
      final DateTime date = DateTime(2026, 11, 2, 14, 35);
      final Expense original = Expense(
        id: 7,
        type: TransactionType.income,
        amount: 1234.5,
        category: 'Food',
        description: 'Lunch',
        date: date,
        paymentMethod: 'UPI',
        createdAt: DateTime(2026, 11, 2, 15, 0),
      );

      final Expense back = Expense.fromMap(original.toMap());

      expect(back.id, 7);
      expect(back.type, TransactionType.income);
      expect(back.amount, 1234.5);
      expect(back.category, 'Food');
      expect(back.description, 'Lunch');
      expect(back.date, date);
      expect(back.paymentMethod, 'UPI');
      expect(back.createdAt, DateTime(2026, 11, 2, 15, 0));
    });

    test('malformed map values fall back to safe defaults (no crash)', () {
      final Expense e = Expense.fromMap(<String, Object?>{
        'id': 'not-a-number',
        'type': 'totally-unknown',
        'amount': '12.5',
        'category': null,
        'date': 'oops',
        'payment_method': null,
        'created_at': null,
      });
      expect(e.id, isNull);
      expect(e.type, TransactionType.expense);
      expect(e.amount, 12.5);
      expect(e.category, 'Other');
      expect(e.date, isA<DateTime>());
    });

    test('signedAmount is negative for expenses and positive for income', () {
      final Expense expense = Expense(
        id: 1,
        type: TransactionType.expense,
        amount: 50,
        category: 'Food',
        description: null,
        date: DateTime(2026, 1, 1),
        paymentMethod: 'Cash',
        createdAt: DateTime(2026, 1, 1),
      );
      expect(expense.signedAmount, -50);

      final Expense income = expense.copyWith(type: TransactionType.income);
      expect(income.signedAmount, 50);
    });
  });

  group('Currency formatting', () {
    test('formats Indian digit grouping with ₹ symbol', () {
      expect(CurrencyFormatter.format(123456.5), '₹1,23,456.50');
      expect(CurrencyFormatter.format(0), '₹0.00');
      expect(CurrencyFormatter.format(10000000), '₹1,00,00,000.00');
    });

    test('parses cleaned amounts from strings', () {
      expect(CurrencyFormatter.parseAmount('123.45'), 123.45);
      expect(CurrencyFormatter.parseAmount('not-a-number'), 0.0);
    });
  });

  group('Date formatting', () {
    test('shows DD MMM YYYY style dates', () {
      expect(
        DateFormatter.format(DateTime(2026, 11, 2)),
        contains('Nov 2026'),
      );
      expect(DateFormatter.isSameDay(
          DateTime(2026, 11, 2), DateTime(2026, 11, 2, 23, 59)), isTrue);
      expect(DateFormatter.isSameDay(
          DateTime(2026, 11, 2), DateTime(2026, 11, 3)), isFalse);
    });
  });

  group('App constants', () {
    test('categories and icons are aligned', () {
      expect(AppConstants.categories.length, AppConstants.categoryIcons.length);
      expect(AppConstants.categories.length, AppConstants.categoryColors.length);
      expect(
        AppConstants.iconFor('Food'),
        AppConstants.categoryIcons.first,
      );
    });
  });
}
