import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:pub_semver/pub_semver.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/design_system/tokens/app_typography.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'core/network/sync_manager.dart';
import 'modules/config/services/config_service.dart';
import 'modules/legal/services/legal_service.dart';
import 'modules/version/presentation/update_dialogs.dart';
import 'modules/legal/presentation/legal_acceptance_popup.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;
  
  String _clientVersion = AppConstants.appVersion;
  String _loadingMessage = "Initializing system...";
  bool _showRetryButton = false;
  late DateTime _startTime;
  
  final ConfigService _configService = ConfigService();
  final LegalService _legalService = LegalService();

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _setupAnimations();
    _startInitializationSequence();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startInitializationSequence() async {
    setState(() {
      _showRetryButton = false;
      _loadingMessage = "Resolving app version...";
    });

    // 1. Resolve dynamic client version safely
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final pVersion = packageInfo.version.trim();
      String resolvedVersion = AppConstants.appVersion;
      if (pVersion.isNotEmpty && pVersion != "1.0.0") {
        try {
          final pSemver = Version.parse(pVersion);
          final cSemver = Version.parse(AppConstants.appVersion);
          resolvedVersion = pSemver > cSemver ? pVersion : AppConstants.appVersion;
        } catch (_) {
          resolvedVersion = AppConstants.appVersion;
        }
      }
      if (mounted) {
        setState(() {
          _clientVersion = resolvedVersion;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _clientVersion = AppConstants.appVersion;
        });
      }
    }

    if (mounted) {
      setState(() {
        _loadingMessage = "Loading application configuration...";
      });
    }

    try {
      // 2. Fetch remote configuration (or load offline cache fallback)
      final config = await _configService.fetchAppConfig();
      
      // 3. Check for maintenance mode
      if (config.maintenanceMode) {
        if (mounted) {
          setState(() {
            _loadingMessage = config.maintenanceMessage;
          });
          _showMaintenanceDialog(config.maintenanceMessage);
        }
        return;
      }

      // 4. Evaluate version status
      if (config.versionStatus == "forceUpdate") {
        if (mounted) {
          _showForceUpdateDialog(config.androidLink, config.iosLink);
        }
        return;
      } else if (config.versionStatus == "softUpdate") {
        if (mounted) {
          await _showSoftUpdateDialog(config.androidLink, config.iosLink);
        }
      }

      // 5. Check Authentication state
      if (mounted) {
        setState(() {
          _loadingMessage = "Checking authentication...";
        });
      }
      
      final authBloc = context.read<AuthBloc>();
      var authState = authBloc.state;
      if (authState is AuthInitial || authState is AuthLoading) {
        authState = await authBloc.stream.firstWhere(
          (state) => state is! AuthInitial && state is! AuthLoading,
        );
      }
      if (!mounted) return;

      if (authState is Authenticated) {
        final userId = authState.user.id;
        
        if (mounted) {
          setState(() {
            _loadingMessage = "Checking legal compliance...";
          });
        }

        // Check legal compliance
        final acceptance = await _legalService.checkUserAcceptance(userId);
        
        final latestTerms = config.latestTermsVersion;
        final latestPrivacy = config.latestPrivacyVersion;
        final acceptedTerms = acceptance['accepted_terms_version'] ?? 0;
        final acceptedPrivacy = acceptance['accepted_privacy_version'] ?? 0;

        if (acceptedTerms < latestTerms || acceptedPrivacy < latestPrivacy) {
          // Trigger legal acceptance popup
          if (mounted) {
            _showLegalAcceptancePopup(
              userId: userId,
              latestTerms: latestTerms,
              latestPrivacy: latestPrivacy,
            );
          }
          return;
        }

        // 6. Perform background synchronization
        if (mounted) {
          setState(() {
            _loadingMessage = "Synchronizing listings data...";
          });
        }

        final hasCache = await SyncManager().hasLocalCache();
        if (hasCache || SyncManager().isSyncCompleted) {
          SyncManager().performStartupSync().catchError((e) {
            // Log background refresh failures but proceed
          });
          _navigateToHome();
        } else {
          // First launch blocking synchronization
          try {
            await SyncManager().performStartupSync();
            _navigateToHome();
          } catch (syncErr) {
            // If sync fails but we have cached database records, bypass
            _navigateToHome();
          }
        }
      } else {
        // Redirect unauthenticated user to Get Started page
        _navigateToGetStarted();
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingMessage = "An error occurred during initialization.";
          _showRetryButton = true;
        });
      }
    }
  }

  Future<void> _navigateToHome() async {
    if (!mounted) return;
    await _ensureMinSplashDelay();
    if (!mounted) return;
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    if (from != null && from.isNotEmpty) {
      context.go(Uri.decodeComponent(from));
    } else {
      context.go('/dashboard');
    }
  }

  Future<void> _navigateToGetStarted() async {
    if (!mounted) return;
    await _ensureMinSplashDelay();
    if (!mounted) return;
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    if (from != null && from.isNotEmpty) {
      context.go('/get-started?from=${Uri.encodeComponent(from)}');
    } else {
      context.go('/get-started');
    }
  }

  Future<void> _ensureMinSplashDelay() async {
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) {
        return;
      }
    } catch (_) {}

    // Check if we are redirecting back to a previous page (e.g. on refresh/deep link)
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    final isRedirect = from != null && from.isNotEmpty;

    final elapsed = DateTime.now().difference(_startTime);
    final minDuration = isRedirect ? Duration.zero : const Duration(milliseconds: 3000); // 3.0 seconds cinematic animation
    if (elapsed < minDuration) {
      await Future.delayed(minDuration - elapsed);
    }
  }

  void _showMaintenanceDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          backgroundColor: AppColors.darkSlate,
          title: Row(
            children: [
              Icon(Icons.build_rounded, color: AppColors.brandGreenHighlight),
              const SizedBox(width: AppSpacing.s),
              const Text('Maintenance Mode', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Text(message, style: TextStyle(color: AppColors.textMuted)),
        ),
      ),
    );
  }

  void _showForceUpdateDialog(String androidLink, String iosLink) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: UpdateDialog(
          isForceUpdate: true,
          androidLink: androidLink,
          iosLink: iosLink,
          onDismiss: () {},
        ),
      ),
    );
  }

  Future<void> _showSoftUpdateDialog(String androidLink, String iosLink) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => UpdateDialog(
        isForceUpdate: false,
        androidLink: androidLink,
        iosLink: iosLink,
        onDismiss: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showLegalAcceptancePopup({
    required String userId,
    required int latestTerms,
    required int latestPrivacy,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: LegalAcceptancePopup(
          userId: userId,
          latestTermsVersion: latestTerms,
          latestPrivacyVersion: latestPrivacy,
          clientVersion: _clientVersion,
          onAccepted: () {
            Navigator.of(context).pop();
            _startInitializationSequence(); // re-verify flow
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color versionColor = Colors.white54;
    const Color primaryColor = Color(0xFFA65D4A);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Center Cinematic Logo Animation
            Center(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final shimmerVal = _shimmerAnimation.value;
                  return Opacity(
                    opacity: _opacityAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            begin: Alignment(shimmerVal - 1.5, shimmerVal - 1.5),
                            end: Alignment(shimmerVal, shimmerVal),
                            colors: const [
                              Colors.transparent,
                              Colors.white38,
                              Colors.transparent,
                            ],
                            stops: const [0.3, 0.5, 0.7],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.srcATop,
                        child: child,
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: 'app_logo',
                  child: Image.asset(
                    'assets/logo.png',
                    width: 120,
                    height: 120,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.apartment_rounded,
                      size: 100,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
            ),

            // Retry UI if connection fails
            if (_showRetryButton)
              Positioned(
                bottom: 80,
                left: 40,
                right: 40,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _loadingMessage,
                      textAlign: TextAlign.center,
                      style: CRMTypography.body.copyWith(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry Connection'),
                      onPressed: _startInitializationSequence,
                    ),
                  ],
                ),
              ),

            // Version number always at the bottom
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Text(
                  'Version $_clientVersion',
                  style: CRMTypography.subheadline.copyWith(
                    color: versionColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}