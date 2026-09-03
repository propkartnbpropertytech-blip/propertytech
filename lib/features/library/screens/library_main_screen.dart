import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/crm_page_header.dart';

class LibraryMainScreen extends StatelessWidget {
  const LibraryMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1024;
    final isTablet = size.width >= 600 && size.width < 1024;

    return Scaffold(
      backgroundColor: CRMColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(CRMSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CRMPageHeader(
                title: 'Library',
              ),
              const SizedBox(height: CRMSpacing.xl),

              // Grid Section
              LayoutBuilder(
                builder: (context, constraints) {
                  int columns = isDesktop ? 3 : (isTablet ? 2 : 1);
                  double spacing = CRMSpacing.xl;
                  double cardWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      _LibraryCategoryCard(
                        width: cardWidth,
                        title: 'Rental Library',
                        subtitle: 'Property Leasing & Tenant Records',
                        description: 'Store and manage all rental-related documents including lease agreements, tenant and owner ID verifications, utility bills, rent receipts, security deposits, and walkthrough media.',
                        icon: Icons.receipt_long_rounded,
                        color: CRMColors.primaryOf(context),
                        bulletPoints: const [
                          'Rental & Lease Agreements',
                          'Tenant & Owner ID Proofs',
                          'Rent & Security Deposit Receipts',
                          'Utility Bills (Electricity, Water, Maintenance)',
                          'Property Inspection Photos & Videos'
                        ],
                        onTap: () => context.go('/rental-library'),
                      ),
                      _LibraryCategoryCard(
                        width: cardWidth,
                        title: 'Re-Sale Library',
                        subtitle: 'Property Purchases & Sales',
                        description: 'Organize transaction deeds and sales checklists, legal society NOCs, building blueprints, tax records, registration agreements, and bank loan approvals.',
                        icon: Icons.handshake_rounded,
                        color: CRMColors.resaleAccent,
                        bulletPoints: const [
                          'Sale Deeds & Agreements',
                          'Property Legal Documents',
                          'Society NOCs & Floor Plans',
                          'Tax Assessment & Municipal Receipts',
                          'Home Loan Sanctions & Approvals'
                        ],
                        onTap: () => context.go('/resale-library'),
                      ),
                      _LibraryCategoryCard(
                        width: cardWidth,
                        title: 'Service Agent Library',
                        subtitle: 'Vendor Agreements & Invoices',
                        description: 'Manage active contracts, GST registrations, price catalogs, and project work proofs for builders, plumbers, AC technicians, cleaning agencies, and electricians.',
                        icon: Icons.badge_rounded,
                        color: CRMColors.info,
                        bulletPoints: const [
                          'Aadhaar / ID Verification Proofs',
                          'GST Registration Certificates',
                          'Vendor Service Agreements (SLAs)',
                          'Price Catalogs & Project Quotations',
                          'Invoices & Completed Work Showcase'
                        ],
                        onTap: () => context.go('/service-agent-library'),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryCategoryCard extends StatefulWidget {
  final double width;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> bulletPoints;
  final VoidCallback onTap;

  const _LibraryCategoryCard({
    required this.width,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.bulletPoints,
    required this.onTap,
  });

  @override
  State<_LibraryCategoryCard> createState() => _LibraryCategoryCardState();
}

class _LibraryCategoryCardState extends State<_LibraryCategoryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: widget.width,
          transform: Matrix4.identity()..translate(0.0, _isHovered ? -6.0 : 0.0),
          child: CRMCard(
            elevated: _isHovered,
            padding: const EdgeInsets.all(CRMSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Icon & Title Area
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(CRMSpacing.m),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.color.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.color,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: CRMSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: CRMTypography.sectionTitle.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: CRMColors.textOf(context),
                            ),
                          ),
                          Text(
                            widget.subtitle,
                            style: CRMTypography.benefit.copyWith(
                              color: CRMColors.textSecondaryOf(context),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: CRMSpacing.l),
                
                // Description Text
                Text(
                  widget.description,
                  style: CRMTypography.body.copyWith(
                    color: CRMColors.textSecondaryOf(context),
                    height: 1.45,
                    fontSize: 13.5,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: CRMSpacing.l),
                
                const Divider(height: 1),
                const SizedBox(height: CRMSpacing.m),

                // Content Checklist Checklist Title
                Text(
                  'VAULT CHECKLIST:',
                  style: CRMTypography.captionBold.copyWith(
                    color: CRMColors.textMutedOf(context),
                    letterSpacing: 0.8,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: CRMSpacing.s),

                // Bullet Points Checklist
                Column(
                  children: widget.bulletPoints.map((bp) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            color: widget.color.withOpacity(0.7),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              bp,
                              style: CRMTypography.caption.copyWith(
                                color: CRMColors.textOf(context),
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: CRMSpacing.xl),

                // Bottom Action Link Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Browse Vault',
                      style: CRMTypography.bodyMedium.copyWith(
                        color: widget.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: widget.color,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
