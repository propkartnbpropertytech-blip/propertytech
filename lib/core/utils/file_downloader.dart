import 'file_downloader_stub.dart'
    if (dart.library.html) 'file_downloader_web.dart'
    if (dart.library.io) 'file_downloader_mobile.dart';

abstract class FileDownloader {
  static Future<void> download(List<int> bytes, String filename) {
    return downloadFile(bytes, filename);
  }
}
