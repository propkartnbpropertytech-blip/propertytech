import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../../../core/utils/app_logger.dart';

class UploadLimitsManager extends ChangeNotifier {
  static final UploadLimitsManager _instance = UploadLimitsManager._internal();
  factory UploadLimitsManager() => _instance;

  static const String imagesPrefsKey = 'propkart_property_max_images';
  static const String videosPrefsKey = 'propkart_property_max_videos';
  static const int defaultMaxImages = 30;
  static const int defaultMaxVideos = 5;

  int _maxImages = defaultMaxImages;
  int _maxVideos = defaultMaxVideos;
  bool _isLoaded = false;
  bool _isSyncing = false;

  UploadLimitsManager._internal() {
    _loadPersisted();
  }

  int get maxImages => _maxImages;
  int get maxVideos => _maxVideos;
  bool get isLoaded => _isLoaded;
  bool get isSyncing => _isSyncing;

  Future<void> _loadPersisted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedImages = prefs.getInt(imagesPrefsKey);
      final cachedVideos = prefs.getInt(videosPrefsKey);
      if (cachedImages != null) {
        _maxImages = cachedImages.clamp(0, 100);
      }
      if (cachedVideos != null) {
        _maxVideos = cachedVideos.clamp(0, 20);
      }
      _isLoaded = true;
      notifyListeners();
    } catch (_) {
      _isLoaded = true;
    }

    await fetchFromBackend(silent: true);
  }

  Future<void> fetchFromBackend({bool silent = false}) async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final response = await ApiClient().get('/config/upload-limits');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        final serverImages = (data?['max_images'] as num?)?.toInt();
        final serverVideos = (data?['max_videos'] as num?)?.toInt();
        var changed = false;
        if (serverImages != null) {
          final clamped = serverImages.clamp(0, 100);
          if (clamped != _maxImages) {
            _maxImages = clamped;
            changed = true;
          }
        }
        if (serverVideos != null) {
          final clamped = serverVideos.clamp(0, 20);
          if (clamped != _maxVideos) {
            _maxVideos = clamped;
            changed = true;
          }
        }
        if (changed) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(imagesPrefsKey, _maxImages);
          await prefs.setInt(videosPrefsKey, _maxVideos);
          notifyListeners();
        }
      }
      _isLoaded = true;
    } catch (e) {
      if (!silent) {
        AppLogger.w("UploadLimitsManager: Failed to fetch limits from backend: $e");
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> setLimits({
    required int maxImages,
    required int maxVideos,
    bool syncBackend = true,
  }) async {
    final clampedImages = maxImages.clamp(0, 100);
    final clampedVideos = maxVideos.clamp(0, 20);
    final changed = (_maxImages != clampedImages) || (_maxVideos != clampedVideos);

    _maxImages = clampedImages;
    _maxVideos = clampedVideos;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(imagesPrefsKey, _maxImages);
      await prefs.setInt(videosPrefsKey, _maxVideos);
    } catch (_) {}

    if (syncBackend) {
      try {
        final response = await ApiClient().put('/config/upload-limits', {
          'max_images': clampedImages,
          'max_videos': clampedVideos,
        });
        if (response.statusCode == 200) {
          AppLogger.d(
            "UploadLimitsManager: Persisted image=$clampedImages video=$clampedVideos to database",
          );
          return true;
        }
        return false;
      } catch (e) {
        AppLogger.e("UploadLimitsManager: Failed to persist limits to database: $e");
        return false;
      }
    }
    return changed;
  }
}
