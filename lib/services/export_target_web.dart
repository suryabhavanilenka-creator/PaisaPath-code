import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Web implementation: triggers a browser download of [content] as
/// [filename] (saved to the user's Downloads folder). Returns the
/// filename, since the browser controls the destination directory.
Future<String> exportCsvFile(String filename, String content) async {
  final web.Blob blob = web.Blob(
    <JSAny>[content.toJS].toJS,
    web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
  );
  final String url = web.URL.createObjectURL(blob);

  final web.HTMLAnchorElement anchor =
      web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = filename;
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();

  web.URL.revokeObjectURL(url);
  return filename;
}
