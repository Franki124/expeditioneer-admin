import 'dart:async';
import 'dart:typed_data';
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

class PickedFile {
  const PickedFile({required this.bytes, required this.name, required this.mimeType});

  final Uint8List bytes;
  final String name;
  final String mimeType;
}

/// Opens the browser's native file picker and resolves once a file is
/// selected and read, or null if the user cancels.
Future<PickedFile?> pickFile({String accept = 'image/*'}) {
  final completer = Completer<PickedFile?>();
  final input = html.FileUploadInputElement()..accept = accept;
  input.click();

  input.onChange.listen((event) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      completer.complete(null);
      return;
    }
    final file = files[0];
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    reader.onLoadEnd.listen((event) {
      final result = reader.result;
      if (result is! List<int>) {
        completer.complete(null);
        return;
      }
      completer.complete(PickedFile(
        bytes: Uint8List.fromList(result),
        name: file.name,
        mimeType: file.type,
      ));
    });
  });

  return completer.future;
}
