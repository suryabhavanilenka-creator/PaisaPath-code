/// Date formatting helpers. The app shows dates in DD MMM YYYY format
/// (e.g. `02 Nov 2026`) everywhere.
library;

import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  /// `02 Nov 2026`
  static String format(DateTime date) => DateFormat('dd MMM yyyy').format(date);

  /// `02 Nov 2026, 4:30 PM` — used on detail screens.
  static String formatWithTime(DateTime date) =>
      DateFormat('dd MMM yyyy, hh:mm a').format(date);

  /// Short month + year header, e.g. `Nov 2026`.
  static String formatMonth(DateTime date) =>
      DateFormat('MMM yyyy').format(date);

  /// Weekday label for charts / dashboard greeting, e.g. `Mon` or `Today`.
  /// Short forms ("Yest") keep seven-bar chart labels collision-free.
  static String dayLabel(DateTime date) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime day = DateTime(date.year, date.month, date.day);
    if (day == today) return 'Today';
    if (day == today.subtract(const Duration(days: 1))) return 'Yest';
    return DateFormat('dd MMM').format(date);
  }

  /// Human-friendly greeting for the dashboard header.
  static String greeting(DateTime now) {
    final int hour = now.hour;
    if (hour < 12) return 'Good Morning 👋';
    if (hour < 17) return 'Good Afternoon 👋';
    return 'Good Evening 👋';
  }

  /// Monday-start week header, helpful for grouping lists by day.
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Removes the time component.
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Stable key for grouping by month: `2026-11`.
  static String monthKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';
}
