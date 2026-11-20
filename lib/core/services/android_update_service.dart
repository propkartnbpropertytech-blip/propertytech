import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import '../navigation/app_router.dart';
import '../constants/app_constants.dart';
import '../../modules/config/services/config_service.dart';
import '../../modules/version/presentation/update_dialogs.dart';

/// Centralized service managing Android Google Play Store update detection,
/// automatic rechecking on app open/resume, and modern update dialog notifications.
class AndroidUpdateService with WidgetsBindingObserver {
  static final AndroidUpdateService _instance = AndroidUpdateService._internal();
  factory AndroidUpdateService() => _instance;
  AndroidUpdateService._internal();

  final ConfigService _configService = ConfigService();
  bool _isInitialized = false;
  bool _isChecking = false;
  bool _isDialogShowing = false;
  DateTime? _lastCheckedAt;

  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.nbpropertytech.propkart';
  static const String playStoreMarketUri =
      'market://details?id=com.nbpropertytech.propkart';

  /// Returns true only when running as an Android mobile app.
  static bool get isAndroidMobile =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Initializes lifecycle listening so the app automatically checks for updates
  /// whenever opened or resumed from background.
  void initialize() {
    if (_isInitialized) return;
    if (!isAndroidMobile) return;

    _isInitialized = true;
    WidgetsBinding.instance.addObserver(this);

    // Initial check after the app finishes rendering its first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkForUpdates();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!isAndroidMobile) return;
    if (state == AppLifecycleState.resumed) {
      // Recheck when app is opened / resumed from the background
      final now = DateTime.now();
      // Throttle rapid re-opens within 3 minutes to maintain smooth UX
      if (_lastCheckedAt == null ||
          now.difference(_lastCheckedAt!).inMinutes >= 3) {
        checkForUpdates();
      }
    }
  }

  /// Automatically or manually checks whether a newer version is available on Google Play.
  /// If newer, displays the modern update popup with Cancel and Update Now options.
  /// If latest version is already installed, does not display any popup.
  Future<bool> checkForUpdates({
    BuildContext? context,
    bool isManualCheck = false,
  }) async {
    // Strictly restrict to Android mobile unless manual check in test environment
    if (!isManualCheck && !isAndroidMobile) {
      return false;
    }

    if (_isChecking || _isDialogShowing) return false;
    _isChecking = true;

    try {
      // 1. Resolve current installed version
      String currentVersion = AppConstants.appVersion;
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        final pVer = packageInfo.version.trim();
        if (pVer.isNotEmpty && pVer != '1.0.0') {
          currentVersion = pVer;
        }
      } catch (_) {}

      // 2. Fetch remote app configuration (contains Play Store max_version & links)
      final config = await _configService.fetchAppConfig();
      _lastCheckedAt = DateTime.now();

      final latestVersion = config.maxVersion.trim();
      final isNewer = isNewerVersion(latestVersion, currentVersion);

      // 3. If a newer version is available, show modern update notification
      if (isNewer || config.versionStatus == 'softUpdate' || config.versionStatus == 'forceUpdate') {
        final targetContext = context ?? AppRouter.rootNavigatorKey.currentContext;
        if (targetContext != null && targetContext.mounted) {
          _isDialogShowing = true;
          await showDialog(
            context: targetContext,
            barrierDismissible: config.versionStatus != 'forceUpdate',
            builder: (dialogCtx) => UpdateDialog(
              isForceUpdate: config.versionStatus == 'forceUpdate',
              androidLink: (config.androidLink.isNotEmpty && config.androidLink != 'comingsoon')
                  ? config.androidLink
                  : playStoreUrl,
              iosLink: config.iosLink,
              newVersion: latestVersion,
              releaseNotes: config.releaseNotes.isNotEmpty ? config.releaseNotes : null,
              onDismiss: () {
                _isDialogShowing = false;
                Navigator.of(dialogCtx).pop();
              },
            ),
          );
          _isDialogShowing = false;
          return true;
        }
      }

      // If user already has the latest version installed, never display the update popup
      return false;
    } catch (e) {
      debugPrint('[AndroidUpdateService] Check failed: $e');
      return false;
    } finally {
      _isChecking = false;
    }
  }

  /// Reliable semantic version comparison (latest vs current).
  /// Returns true if latest > current.
  static bool isNewerVersion(String latest, String current) {
    try {
      final cleanLatest = latest.trim().replaceFirst(RegExp(r'^[vV]'), '');
      final cleanCurrent = current.trim().replaceFirst(RegExp(r'^[vV]'), '');

      // Parse pure semver (ignore +build metadata for semver comparison)
      final semLatest = Version.parse(cleanLatest.split('+').first);
      final semCurrent = Version.parse(cleanCurrent.split('+').first);

      if (semLatest > semCurrent) return true;
      if (semLatest < semCurrent) return false;

      // If semver is identical, check build number if available (e.g. 1.1.4+6 vs 1.1.4+5)
      final buildLatest = cleanLatest.contains('+')
          ? int.tryParse(cleanLatest.split('+').last)
          : null;
      final buildCurrent = cleanCurrent.contains('+')
          ? int.tryParse(cleanCurrent.split('+').last)
          : null;
      if (buildLatest != null && buildCurrent != null) {
        return buildLatest > buildCurrent;
      }
    } catch (_) {
      // Fallback manual comparison if pub_semver fails
      final lParts = latest.split(RegExp(r'[.+_-]')).map((s) => int.tryParse(s) ?? 0).toList();
      final cParts = current.split(RegExp(r'[.+_-]')).map((s) => int.tryParse(s) ?? 0).toList();
      final maxLen = lParts.length > cParts.length ? lParts.length : cParts.length;
      for (int i = 0; i < maxLen; i++) {
        final l = i < lParts.length ? lParts[i] : 0;
        final c = i < cParts.length ? cParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
    }
    return false;
  }

  /// Disposes resources (primarily for testing)
  void dispose() {
    if (_isInitialized) {
      WidgetsBinding.instance.removeObserver(this);
      _isInitialized = false;
    }
  }
}
