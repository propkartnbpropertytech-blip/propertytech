import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/design_system/tokens/app_colors.dart';
import 'core/design_system/tokens/app_spacing.dart';
import 'core/design_system/tokens/app_typography.dart';
import 'core/utils/seo_helper.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  @override
  void initState() {
    super.initState();
    SeoHelper.updateTags(
      title: 'PropKart - Premium Property Management Software & CRM',
      description: 'PropKart is the future of property management. Find your dream home, manage property listings, and connect with top agents and builders effortlessly.',
      canonicalUrl: 'https://propkart.nbpropertytech.com/get-started',
      imageUrl: 'https://propkart.nbpropertytech.com/assets/logo.png',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 960) {
                return _buildLaptopLayout(context, constraints);
              } else {
                return _buildMobileLayout(context, constraints);
              }
            },
          ),
          Positioned(
            top: 24,
            left: 24,
            child: Row(
              children: [
                Image.asset(
                  'assets/logo.png',
                  width: 32,
                  height: 32,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.apartment_rounded,
                    color: AppColors.brandGreen,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'PropKart',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Beautiful Laptop/Desktop Split-Visual Layout
  Widget _buildLaptopLayout(BuildContext context, BoxConstraints constraints) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/propbg.jpg',
            fit: BoxFit.cover,
            alignment: const Alignment(0.4, 0.0),
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.darkSlate,
                child: const Center(
                  child: Icon(
                    Icons.apartment_rounded,
                    size: 150,
                    color: Colors.grey,
                  ),
                ),
              );
            },
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.darkBg,
                  AppColors.darkBg.withOpacity(0.95),
                  AppColors.darkBg.withOpacity(0.75),
                  AppColors.darkBg.withOpacity(0.0),
                ],
                stops: const [0.0, 0.4, 0.65, 1.0],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth * 0.08,
              vertical: AppSpacing.xxl,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.brandGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppBorderRadius.tag),
                        border: Border.all(
                          color: AppColors.brandGreen.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'PREMIUM REAL ESTATE',
                        style: CRMTypography.captionBold.copyWith(
                          color: AppColors.brandGreenHighlight,
                          fontSize: 12,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Treasure of listed\nproperties in your area',
                      style: CRMTypography.largeDisplay.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    Text(
                      'Find your dream home effortlessly. The ultimate real estate platform designed to streamline your property search and connect you with top listings.',
                      style: CRMTypography.body.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 17,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                    PremiumButton(
                      label: 'Get Started',
                      width: 220,
                      onPressed: () {
                        final from = GoRouterState.of(context).uri.queryParameters['from'];
                        if (from != null && from.isNotEmpty) {
                          context.go('/login?from=${Uri.encodeComponent(from)}');
                        } else {
                          context.go('/login');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Premium Mobile Bottom-Faded Stack Layout
  Widget _buildMobileLayout(BuildContext context, BoxConstraints constraints) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/propbg.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.darkSlate,
                child: const Center(
                  child: Icon(
                    Icons.apartment_rounded,
                    size: 150,
                    color: Colors.grey,
                  ),
                ),
              );
            },
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.darkBg.withOpacity(0.2),
                  AppColors.darkBg.withOpacity(0.8),
                  AppColors.darkBg,
                ],
                stops: const [0.0, 0.5, 0.85],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.brandGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppBorderRadius.tag),
                        border: Border.all(
                          color: AppColors.brandGreen.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'PREMIUM REAL ESTATE',
                        style: CRMTypography.captionBold.copyWith(
                          color: AppColors.brandGreenHighlight,
                          fontSize: 10,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      'Treasure of listed\nproperties in your area',
                      style: CRMTypography.display.copyWith(
                        color: Colors.white,
                        fontSize: 32,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      'Find your dream home effortlessly. The ultimate real estate platform designed to streamline your property search.',
                      style: CRMTypography.body.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PremiumButton(
                      label: 'Get Started',
                      onPressed: () {
                        final from = GoRouterState.of(context).uri.queryParameters['from'];
                        if (from != null && from.isNotEmpty) {
                          context.go('/login?from=${Uri.encodeComponent(from)}');
                        } else {
                          context.go('/login');
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.s),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
