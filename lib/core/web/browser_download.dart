import 'dart:typed_data';
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Triggers a browser file download for [bytes]. Admin-console-only helper —
/// this app targets web exclusively, so a plain (unconditional) dart:html
/// import is fine here.
void downloadBytes({required Uint8List bytes, required String filename, required String mimeType}) {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}

void printCurrentPage() {
  html.window.print();
}
