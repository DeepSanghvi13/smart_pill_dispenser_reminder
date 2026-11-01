import 'dart:typed_data';
import 'file_downloader_stub.dart'
    if (dart.library.html) 'file_downloader_web.dart' as impl;

Future<void> downloadImageFile(Uint8List bytes, String filename) =>
    impl.downloadFile(bytes, filename);

