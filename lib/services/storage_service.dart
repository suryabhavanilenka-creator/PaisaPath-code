import '../models/expense.dart';

import 'export_target.dart';

/// Builds and saves the transactions CSV export.
///
/// The sink is platform-specific via [saveTextFile]:
/// - Android: file written under `<app documents>/paisapath_exports`,
///   the absolute path is returned.
/// - Web: the browser downloads the file; the filename is returned.
class StorageService {
  const StorageService();

  /// Exports [expenses] to a CSV file with a stable header row.
  /// Records are written in chronological creation order (ascending id).
  /// Returns the file path (Android) or filename (web) on success;
  /// throws on errors so callers can surface a failure snackbar.
  Future<String> exportToCsv(List<Expense> expenses) async {
    final DateTime now = DateTime.now();
    final String stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}'
        '_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final String filename = 'spendwise_expenses_$stamp.csv';

    // Chronological creation order (ascending id), independent of the
    // dashboard's newest-first display sort.
    final List<Expense> ordered = <Expense>[...expenses]..sort(
        (Expense a, Expense b) => (a.id ?? 0).compareTo(b.id ?? 0),
      );
    return exportCsvFile(filename, buildCsv(ordered));
  }

  /// Builds the RFC-4180-style CSV document for [expenses].
  String buildCsv(List<Expense> expenses) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('Id,Type,Amount,Category,Date,Time,Payment Method,Description');
    for (final Expense e in expenses) {
      buffer.writeln(<String>[
        '${e.id ?? ''}',
        e.type.key,
        e.amount.toStringAsFixed(2),
        _csvField(e.category),
        _ddMmYyyy(e.date),
        _hhMm(e.date),
        _csvField(e.paymentMethod),
        _csvField(e.description ?? ''),
      ].join(','));
    }
    return buffer.toString();
  }

  /// Escapes a value for RFC-4180-style CSV output.
  String _csvField(String value) {
    final bool needsQuotes =
        value.contains(',') || value.contains('"') || value.contains('\n');
    final String escaped = value.replaceAll('"', '""');
    if (needsQuotes) return '"$escaped"';
    return escaped;
  }

  String _ddMmYyyy(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _hhMm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
