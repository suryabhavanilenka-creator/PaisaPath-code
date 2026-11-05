import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// IO implementation: writes [content] as [filename] under
/// `<app documents>/paisapath_exports` and then opens the Android share
/// sheet so the user can save the file somewhere reachable (Files, Drive,
/// WhatsApp…). The app-private documents directory is not visible to file
/// managers, so handing the file to the system share flow is the only
/// user-accessible route. Returns the absolute internal path.
Future<String> exportCsvFile(String filename, String content) async {
  final Directory docs = await getApplicationDocumentsDirectory();
  final Directory dir =
      Directory('${docs.path}${Platform.pathSeparator}paisapath_exports');
  if (!dir.existsSync()) {
    await dir.create(recursive: true);
  }
  final File file = File('${dir.path}${Platform.pathSeparator}$filename');
  await file.writeAsString(content, flush: true);

  await SharePlus.instance.share(
    ShareParams(
      files: <XFile>[XFile(file.path, mimeType: 'text/csv')],
      text: 'SpendWise — transactions export',
      title: filename,
    ),
  );
  return file.path;
}
