import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'buttons.dart';

class CRMPlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  final List<String> upcomingFeatures;

  const CRMPlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
    required this.upcomingFeatures,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CRMColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(CRMSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Premium Styled Icon/Logo Container
                Container(
                  padding: const EdgeInsets.all(CRMSpacing.l),
                  decoration: BoxDecoration(
                    color: CRMColors.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 72,
                    color: CRMColors.primary,
                  ),
                ),
                const SizedBox(height: CRMSpacing.l),
                
                // Title
                Text(
                  title,
                  style: CRMTypography.pageTitle.copyWith(color: CRMColors.text),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: CRMSpacing.s),
                
                // Description
                Text(
                  description,
                  style: CRMTypography.body.copyWith(color: CRMColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: CRMSpacing.xl),
                
                // Roadmap / Upcoming Features Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(CRMSpacing.l),
                  decoration: BoxDecoration(
                    color: CRMColors.cardBg,
                    borderRadius: BorderRadius.circular(CRMBorderRadius.m),
                    border: Border.all(color: CRMColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.insights_rounded,
                            color: CRMColors.info,
                            size: 20,
                          ),
                          const SizedBox(width: CRMSpacing.xs),
                          Text(
                            'Roadmap & Planned Features',
                            style: CRMTypography.cardTitle.copyWith(color: CRMColors.text),
                          ),
                        ],
                      ),
                      const SizedBox(height: CRMSpacing.m),
                      Divider(color: CRMColors.border, height: 1),
                      const SizedBox(height: CRMSpacing.m),
                      ...upcomingFeatures.map((feature) => Padding(
                            padding: const EdgeInsets.only(bottom: CRMSpacing.s),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: CRMColors.success,
                                  size: 18,
                                ),
                                const SizedBox(width: CRMSpacing.s),
                                Expanded(
                                  child: Text(
                                    feature,
                                    style: CRMTypography.body.copyWith(
                                      color: CRMColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: CRMSpacing.xl),
                
                // Notify/Action Button
                CRMButton(
                  label: 'Back to Dashboard',
                  onPressed: () {
                    // Navigate back or to dashboard directly
                    Navigator.of(context).maybePop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
