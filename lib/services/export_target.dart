/// Platform routing for the CSV export sink.
///
/// - On IO platforms (Android/desktop) the CSV is written to the app
///   documents directory and handed to the system share sheet, so the
///   user can save it somewhere reachable.
/// - On web the CSV is handed to the browser as a download and the
///   filename is returned.
library;

export 'export_target_stub.dart'
    if (dart.library.io) 'export_target_io.dart'
    if (dart.library.html) 'export_target_web.dart';
