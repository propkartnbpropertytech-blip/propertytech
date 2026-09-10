import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> downloadFile(List<int> bytes, String filename) async {
  if (Platform.isWindows) {
    Directory? downloadsDir = await getDownloadsDirectory();
    downloadsDir ??= await getApplicationDocumentsDirectory();
    final file = File('${downloadsDir.path}/$filename');
    await file.writeAsBytes(bytes);
    try {
      final xFile = XFile(file.path);
      await Share.shareXFiles([xFile], text: filename);
    } catch (_) {}
    return;
  }

  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/$filename');
  await file.writeAsBytes(bytes);
  final xFile = XFile(file.path);
  await Share.shareXFiles([xFile], text: filename);
}

Future<void> downloadFromUrl(String url, String filename) async {
  // Mobile fallback
}
