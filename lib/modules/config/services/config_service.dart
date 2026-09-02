import 'dart:convert';
import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/constants/app_constants.dart';

class AppConfigModel {
  final bool maintenanceMode;
  final String maintenanceMessage;
  final String androidLink;
  final String iosLink;
  final String minVersion;
  final String maxVersion;
  final int latestTermsVersion;
  final int latestPrivacyVersion;
  final bool enableAi;
  final bool enableWhatsapp;
  final bool enableNotifications;
  final String releaseNotes;
  final String versionStatus; // 'latest', 'softUpdate', 'forceUpdate'

  AppConfigModel({
    required this.maintenanceMode,
    required this.maintenanceMessage,
    required this.androidLink,
    required this.iosLink,
    required this.minVersion,
    required this.maxVersion,
    required this.latestTermsVersion,
    required this.latestPrivacyVersion,
    required this.enableAi,
    required this.enableWhatsapp,
    required this.enableNotifications,
    required this.releaseNotes,
    required this.versionStatus,
  });

  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    return AppConfigModel(
      maintenanceMode: json['maintenance_mode'] ?? false,
      maintenanceMessage: json['maintenance_message'] ?? '',
      androidLink: json['android_link'] ?? 'comingsoon',
      iosLink: json['ios_link'] ?? 'comingsoon',
      minVersion: json['min_version'] ?? '1.1.2',
      maxVersion: json['max_version'] ?? '1.1.5',
      latestTermsVersion: json['latest_terms_version'] ?? 1,
      latestPrivacyVersion: json['latest_privacy_version'] ?? 1,
      enableAi: json['enable_ai'] ?? true,
      enableWhatsapp: json['enable_whatsapp'] ?? true,
      enableNotifications: json['enable_notifications'] ?? true,
      releaseNotes: json['release_notes'] ?? '',
      versionStatus: json['versionStatus'] ?? 'latest',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maintenance_mode': maintenanceMode,
      'maintenance_message': maintenanceMessage,
      'android_link': androidLink,
      'ios_link': iosLink,
      'min_version': minVersion,
      'max_version': maxVersion,
      'latest_terms_version': latestTermsVersion,
      'latest_privacy_version': latestPrivacyVersion,
      'enable_ai': enableAi,
      'enable_whatsapp': enableWhatsapp,
      'enable_notifications': enableNotifications,
      'release_notes': releaseNotes,
      'versionStatus': versionStatus,
    };
  }
}

class ConfigService {
  static const String _cacheKey = 'cached_app_config';
  static const String _lastCheckedKey = 'config_last_checked_timestamp';

  Future<AppConfigModel> fetchAppConfig() async {
    // Return early if running under test to avoid network hang
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) {
        return AppConfigModel(
          maintenanceMode: false,
          maintenanceMessage: '',
          androidLink: 'comingsoon',
          iosLink: 'comingsoon',
          minVersion: '1.1.2',
          maxVersion: '1.1.5',
          latestTermsVersion: 1,
          latestPrivacyVersion: 1,
          enableAi: true,
          enableWhatsapp: true,
          enableNotifications: true,
          releaseNotes: 'Test Fallback',
          versionStatus: 'latest',
        );
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    
    // 1. Resolve dynamic version info safely
    String currentVersion = AppConstants.appVersion;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final pVer = packageInfo.version.trim();
      if (pVer.isNotEmpty && pVer != '1.0.0') {
        try {
          final pSemver = Version.parse(pVer);
          final appSemver = Version.parse(AppConstants.appVersion);
          currentVersion = pSemver > appSemver ? pVer : AppConstants.appVersion;
        } catch (_) {
          currentVersion = AppConstants.appVersion;
        }
      }
    } catch (_) {
      // Graceful fallback for missing native channel integration
    }

    try {
      // 2. Query backend configuration endpoint
      final response = await DioClient.dio.get(
        '/config',
        queryParameters: {'app_version': currentVersion},
      );

      if (response.statusCode == 200 && response.data != null) {
        final payload = Map<String, dynamic>.from(response.data['data'] as Map);
        
        // Ensure versionStatus accurately reflects currentVersion against server limits
        final recalculatedStatus = _calculateVersionStatus(
          currentVersion: currentVersion,
          minVersion: payload['min_version']?.toString() ?? '1.1.2',
          maxVersion: payload['max_version']?.toString() ?? '1.1.5',
        );
        payload['versionStatus'] = recalculatedStatus;

        // Save fetched data to local SharedPreferences cache
        await prefs.setString(_cacheKey, json.encode(payload));
        await prefs.setString(_lastCheckedKey, DateTime.now().toIso8601String());

        return AppConfigModel.fromJson(payload);
      }
    } catch (e) {
      // Offline/Timeout Fallback: Retrieve configuration from local cache
      final cachedJsonString = prefs.getString(_cacheKey);
      if (cachedJsonString != null) {
        final Map<String, dynamic> cachedMap = Map<String, dynamic>.from(json.decode(cachedJsonString) as Map);
        
        // Recalculate versionStatus locally based on current client version vs cached min/max version limits
        final config = AppConfigModel.fromJson(cachedMap);
        final recalculatedStatus = _calculateVersionStatus(
          currentVersion: currentVersion,
          minVersion: config.minVersion,
          maxVersion: config.maxVersion,
        );

        cachedMap['versionStatus'] = recalculatedStatus;
        return AppConfigModel.fromJson(cachedMap);
      }
    }

    // Default configuration if completely offline on first launch
    return AppConfigModel(
      maintenanceMode: false,
      maintenanceMessage: '',
      androidLink: 'comingsoon',
      iosLink: 'comingsoon',
      minVersion: '1.1.2',
      maxVersion: '1.1.5',
      latestTermsVersion: 1,
      latestPrivacyVersion: 1,
      enableAi: true,
      enableWhatsapp: true,
      enableNotifications: true,
      releaseNotes: 'Offline Mode Fallback',
      versionStatus: 'latest',
    );
  }

  String _calculateVersionStatus({
    required String currentVersion,
    required String minVersion,
    required String maxVersion,
  }) {
    try {
      final clientSemver = Version.parse(currentVersion);
      final minSemver = Version.parse(minVersion);
      final maxSemver = Version.parse(maxVersion);

      if (clientSemver < minSemver) {
        return 'forceUpdate';
      } else if (clientSemver < maxSemver) {
        return 'softUpdate';
      }
    } catch (e) {
      // Graceful fallback to latest on version parsing errors
    }
    return 'latest';
  }

  Future<String> getLastCheckedTime() async {
    final prefs = await SharedPreferences.getInstance();
    final checkedStr = prefs.getString(_lastCheckedKey);
    if (checkedStr != null) {
      final dt = DateTime.parse(checkedStr);
      final timeStr = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      return "Today, $timeStr";
    }
    return "Never Checked";
  }
}
