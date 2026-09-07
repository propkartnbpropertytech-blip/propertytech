import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/design_system/tokens/app_spacing.dart';
import 'core/design_system/tokens/app_typography.dart';
import 'core/design_system/widgets/buttons.dart';
import 'core/design_system/widgets/crm_brand_lockup.dart';
import 'core/theme/theme_manager.dart';
import 'core/utils/seo_helper.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  static const _heroWhite = Color(0xFFFFFFFF);
  static const _heroMuted = Color(0xFFE8E8E6);
  static const _scrim = Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    SeoHelper.updateTags(
      title: 'PropKart - Premium Property Management Software & CRM',
      description:
          'PropKart is the future of property management. Find your dream home, manage property listings, and connect with top agents and builders effortlessly.',
      canonicalUrl: 'https://propkart.nbpropertytech.com/get-started',
      imageUrl: 'https://propkart.nbpropertytech.com/assets/logo.png',
    );
  }

  void _goToLogin() {
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    if (from != null && from.isNotEmpty) {
      context.go('/login?from=${Uri.encodeComponent(from)}');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager(),
      builder: (context, _) {
        final theme = ThemeManager().currentTheme;
        final isDark = ThemeManager().isDarkMode;
        final primaryColor = isDark ? theme.primaryDark : theme.primaryLight;

        return Scaffold(
          backgroundColor: _scrim,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;
              return Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/propbg.jpg',
                      fit: BoxFit.cover,
                      alignment: isDesktop
                          ? const Alignment(0.35, 0)
                          : Alignment.center,
                      errorBuilder: (context, error, stackTrace) {
                        return const ColoredBox(color: _scrim);
                      },
                    ),
                  ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: isDesktop
                          ? Alignment.centerLeft
                          : Alignment.topCenter,
                      end: isDesktop
                          ? Alignment.centerRight
                          : Alignment.bottomCenter,
                      colors: isDesktop
                          ? [
                              _scrim,
                              _scrim.withValues(alpha: 0.92),
                              _scrim.withValues(alpha: 0.55),
                              _scrim.withValues(alpha: 0.12),
                            ]
                          : [
                              _scrim.withValues(alpha: 0.25),
                              _scrim.withValues(alpha: 0.72),
                              _scrim.withValues(alpha: 0.96),
                            ],
                      stops: isDesktop
                          ? const [0.0, 0.38, 0.68, 1.0]
                          : const [0.0, 0.48, 1.0],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop
                        ? (constraints.maxWidth * 0.07).clamp(32, 80)
                        : CRMSpacing.l,
                    vertical: isDesktop ? CRMSpacing.l : CRMSpacing.m,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CRMBrandLockup(
                        compact: true,
                        wordmarkColor: _heroWhite,
                        markSize: 24,
                      ),
                      Expanded(
                        child: Align(
                          alignment: isDesktop
                              ? Alignment.centerLeft
                              : Alignment.bottomCenter,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isDesktop ? 560 : double.infinity,
                            ),
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  top: isDesktop ? 0 : CRMSpacing.xl,
                                  bottom: isDesktop ? 0 : CRMSpacing.l,
                                ),
                                child: _HeroCopy(
                                  isDesktop: isDesktop,
                                  onStarted: _goToLogin,
                                  titleColor: _heroWhite,
                                  mutedColor: _heroMuted,
                                  primaryColor: primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
      },
    );
  }
}

class _HeroCopy extends StatelessWidget {
  final bool isDesktop;
  final VoidCallback onStarted;
  final Color titleColor;
  final Color mutedColor;
  final Color primaryColor;

  const _HeroCopy({
    required this.isDesktop,
    required this.onStarted,
    required this.titleColor,
    required this.mutedColor,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(CRMBorderRadius.button),
          ),
          child: Text(
            'PREMIUM REAL ESTATE',
            style: CRMTypography.captionBold.copyWith(
              color: Colors.white,
              fontSize: isDesktop ? 12 : 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(height: isDesktop ? CRMSpacing.xl : CRMSpacing.m),
        Text(
          'Treasure of listed\nproperties in your area',
          style: CRMTypography.largeDisplay.copyWith(
            color: titleColor,
            fontSize: isDesktop ? 48 : 32,
            height: 1.12,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
          ),
        ),
        SizedBox(height: isDesktop ? CRMSpacing.l : CRMSpacing.m),
        Text(
          isDesktop
              ? 'Find your dream home effortlessly. The ultimate real estate platform designed to streamline your property search and connect you with top listings.'
              : 'Find your dream home effortlessly. The ultimate real estate platform designed to streamline your property search.',
          style: CRMTypography.body.copyWith(
            color: mutedColor,
            fontSize: isDesktop ? 17 : 15,
            height: 1.55,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: isDesktop ? CRMSpacing.xxl : CRMSpacing.xl),
        CRMButton(
          label: 'Get Started',
          onPressed: onStarted,
          width: isDesktop ? 220 : double.infinity,
          height: 52,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ],
    );
  }
}
