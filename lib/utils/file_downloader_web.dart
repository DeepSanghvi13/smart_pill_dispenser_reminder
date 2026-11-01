// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

Future<void> downloadFile(Uint8List bytes, String filename) async {
  final mimeType = filename.toLowerCase().endsWith('.jpg') ||
          filename.toLowerCase().endsWith('.jpeg')
      ? 'image/jpeg'
      : 'image/png';
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
