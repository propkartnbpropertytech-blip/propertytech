import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class GalleryMediaSaver {
  static const MethodChannel _channel = MethodChannel('com.nbpropertytech.propkart/media_saver');

  /// Saves a ZIP file to Downloads folder on Android & Windows
  static Future<String?> saveZipToDownloads({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (kIsWeb) return null;

    if (Platform.isAndroid) {
      try {
        final path = await _channel.invokeMethod<String>('saveZipToDownloads', {
          'bytes': bytes,
          'fileName': fileName,
        });
        return path;
      } catch (e) {
        debugPrint('Error saving zip on Android: $e');
        return null;
      }
    } else if (Platform.isWindows) {
      try {
        Directory? dir = await getDownloadsDirectory();
        dir ??= await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);
        return file.path;
      } catch (e) {
        debugPrint('Error saving zip on Windows: $e');
        return null;
      }
    }
    return null;
  }

  /// Saves / extracts images directly to device's Gallery / Photos app
  static Future<int> saveImagesToGallery({
    required List<Map<String, dynamic>> images,
    required String albumName,
  }) async {
    if (kIsWeb) return 0;

    if (Platform.isAndroid) {
      try {
        final count = await _channel.invokeMethod<int>('saveImagesToGallery', {
          'images': images,
          'albumName': albumName,
        });
        return count ?? 0;
      } catch (e) {
        debugPrint('Error saving images to Android gallery: $e');
        return 0;
      }
    } else if (Platform.isWindows) {
      try {
        Directory? dir = await getDownloadsDirectory();
        dir ??= await getApplicationDocumentsDirectory();
        final folder = Directory('${dir.path}/$albumName');
        if (!await folder.exists()) await folder.create(recursive: true);
        int saved = 0;
        for (final img in images) {
          final bytes = img['bytes'] as Uint8List?;
          final name = img['fileName'] as String?;
          if (bytes != null && name != null) {
            await File('${folder.path}/$name').writeAsBytes(bytes);
            saved++;
          }
        }
        return saved;
      } catch (_) {
        return 0;
      }
    }
    return 0;
  }
}
