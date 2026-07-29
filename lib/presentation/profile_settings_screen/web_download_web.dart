// Web-specific implementation using dart:html
import 'package:web/web.dart' as web;

void downloadFile(String content, String filename) {
  // Encode content as a data URI and trigger anchor click
  final encoded = Uri.encodeComponent(content);
  final dataUri = 'data:text/plain;charset=utf-8,$encoded';
  // Use web package's document/anchor APIs
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = dataUri;
  anchor.download = filename;
  web.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
}
