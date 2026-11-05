/// Indian Rupee formatting helpers used by every money display in the app.
library;

import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  /// ₹ symbol used across the app.
  static const String symbol = '₹';

  static final NumberFormat _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: symbol,
    decimalDigits: 2,
  );

  /// Formats with Indian digit grouping, always 2 decimals,
  /// e.g. `-123456.5` → `₹1,23,456.50`.
  static String format(num amount) {
    try {
      return _inr.format(amount);
    } catch (_) {
      // Fallback if intl grouping unexpectedly fails.
      return '$symbol${amount.toStringAsFixed(2)}';
    }
  }

  /// Same formatting without trailing decimals, e.g. `₹1,23,456`.
  static String formatShort(num amount) =>
      format(amount).replaceFirst(RegExp(r'\.00$'), '');

  /// Strips any symbol, group separators and spaces from user input.
  static double parseAmount(String raw) {
    final String cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }
}
