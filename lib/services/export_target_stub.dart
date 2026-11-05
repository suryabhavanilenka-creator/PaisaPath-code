/// Fallback for platforms with neither IO files nor a browser DOM.
Future<String> exportCsvFile(String filename, String content) async {
  throw UnsupportedError(
      'CSV export is not supported on this platform ($filename).');
}
