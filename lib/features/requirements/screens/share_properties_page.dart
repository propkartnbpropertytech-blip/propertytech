import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/design_system/tokens/app_colors.dart';
import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../core/design_system/tokens/app_typography.dart';
import '../../../../core/design_system/tokens/app_shadows.dart';
import '../../../../core/design_system/widgets/buttons.dart';
import '../../../../core/design_system/widgets/cards.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/currency.dart';
import '../../../../core/utils/seo_helper.dart';

/// WhatsApp brand green — kept as a distinct constant for brand recognition.
const Color _kWhatsAppGreen = Color(0xFF25D366);

class SharePropertiesPage extends StatefulWidget {
  final String sessionId;

  const SharePropertiesPage({super.key, required this.sessionId});

  @override
  State<SharePropertiesPage> createState() => _SharePropertiesPageState();
}

class _SharePropertiesPageState extends State<SharePropertiesPage> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _session;
  Map<String, dynamic>? _agent;
  List<dynamic> _properties = [];

  @override
  void initState() {
    super.initState();
    _loadShareSession();
  }

  Future<void> _loadShareSession() async {
    try {
      final response = await DioClient.dio.get('/share-sessions/public/${widget.sessionId}');
      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        setState(() {
          _session = data['session'];
          _agent = data['agent'];
          _properties = data['properties'] ?? [];
          _isLoading = false;
        });

        // Dynamic SEO Update
        final agentName = _agent?['full_name'] ?? 'Agent';
        final firstImage = (_properties.isNotEmpty && _properties.first['images'] != null && (_properties.first['images'] as List).isNotEmpty)
            ? _properties.first['images'].first.toString()
            : null;
        SeoHelper.updateTags(
          title: 'Shortlisted Properties for You | Shared by $agentName - PropKart',
          description: 'Explore this curated list of shortlisted properties handpicked for your requirements by agent $agentName on PropKart.',
          canonicalUrl: 'https://propkart.nbpropertytech.com/share/${widget.sessionId}',
          imageUrl: firstImage ?? 'https://propkart.nbpropertytech.com/assets/logo.png',
        );
      } else {
        setState(() {
          _errorMessage = response.data['message'] ?? "Failed to load collection details.";
          _isLoading = false;
        });
      }
    } catch (e) {
      String msg = "Failed to load collection details.";
      if (e.toString().contains("404")) {
        msg = "This share link is no longer available.";
      } else if (e.toString().contains("410")) {
        msg = "This property collection has expired or has been revoked.";
      }
      setState(() {
        _errorMessage = msg;
        _isLoading = false;
      });
    }
  }

  Future<void> _logClick(String propertyId, String actionType) async {
    try {
      await DioClient.dio.post(
        '/share-sessions/public/${widget.sessionId}/click',
        data: {
          'propertyId': propertyId,
          'actionType': actionType,
        },
      );
    } catch (e) {
      debugPrint("Failed to log click event: $e");
    }
  }

  Future<void> _launchUrlHelper(String url, String propertyId, String actionType) async {
    await _logClick(propertyId, actionType);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: CRMColors.backgroundOf(context),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: CRMColors.backgroundOf(context),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(CRMSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.link_off_rounded, size: 64, color: CRMColors.danger),
                const SizedBox(height: CRMSpacing.m),
                Text(
                  _errorMessage!,
                  style: CRMTypography.sectionTitle.copyWith(color: CRMColors.text),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_properties.isEmpty) {
      return Scaffold(
        backgroundColor: CRMColors.backgroundOf(context),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(CRMSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: CRMColors.textMuted),
                const SizedBox(height: CRMSpacing.m),
                Text(
                  "No properties are available in this share.",
                  style: CRMTypography.sectionTitle.copyWith(color: CRMColors.text),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final agentName = _agent?['full_name'] ?? 'Agent';
    final agentMobile = _agent?['mobile'] ?? '';

    final headerBlock = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(CRMSpacing.l),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [CRMColors.primary.withValues(alpha: 0.85), CRMColors.primaryHover],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(CRMBorderRadius.card),
        boxShadow: CRMShadows.primaryGlow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Properties Selected For You",
            style: CRMTypography.title.copyWith(color: Colors.white, fontSize: 24),
          ),
          const SizedBox(height: CRMSpacing.xs),
          Text(
            "Based on your requirement, we shortlisted these properties. Swipe through them and contact us if you like any.",
            style: CRMTypography.body.copyWith(color: Colors.white.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );

    final agentContactCard = CRMCard(
      child: Padding(
        padding: const EdgeInsets.all(CRMSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Need Help?", style: CRMTypography.captionBold.copyWith(color: CRMColors.textMuted)),
            const SizedBox(height: CRMSpacing.xs),
            Text(agentName, style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: CRMColors.text)),
            if (agentMobile.isNotEmpty) ...[
              Text(agentMobile, style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary)),
              const SizedBox(height: CRMSpacing.m),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.phone_rounded, size: 16),
                      label: const Text("Call"),
                      onPressed: () => _launchUrlHelper("tel:$agentMobile", "session", "Call"),
                    ),
                  ),
                  const SizedBox(width: CRMSpacing.s),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kWhatsAppGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.button)),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                      label: const Text("WhatsApp"),
                      onPressed: () {
                        final text = Uri.encodeComponent("Hi, I was looking at the property shortlist you shared with me.");
                        _launchUrlHelper("https://wa.me/$agentMobile?text=$text", "session", "WhatsApp");
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );

    final propertiesList = Column(
      children: [
        for (int i = 0; i < _properties.length; i += (isDesktop ? 2 : 1)) ...[
          if (isDesktop) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildPropertyItem(context, _properties[i], agentMobile),
                ),
                const SizedBox(width: CRMSpacing.l),
                Expanded(
                  child: (i + 1 < _properties.length)
                      ? _buildPropertyItem(context, _properties[i + 1], agentMobile)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: CRMSpacing.l),
          ] else ...[
            _buildPropertyItem(context, _properties[i], agentMobile),
            const SizedBox(height: CRMSpacing.l),
          ],
        ],
      ],
    );

    return Scaffold(
      backgroundColor: CRMColors.backgroundOf(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: CRMSpacing.l),
          child: Column(
            children: [
              headerBlock,
              const SizedBox(height: CRMSpacing.l),
              if (isDesktop) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: propertiesList),
                    const SizedBox(width: CRMSpacing.l),
                    Expanded(flex: 1, child: agentContactCard),
                  ],
                ),
              ] else ...[
                agentContactCard,
                const SizedBox(height: CRMSpacing.l),
                propertiesList,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyItem(BuildContext context, Map<String, dynamic> p, String agentMobile) {
    final double? priceVal = p['price'] != null ? double.tryParse(p['price'].toString()) : null;
    final price = priceVal != null
        ? '${CRMCurrencyFormatter.format(priceVal)} (${CRMCurrencyFormatter.formatWords(priceVal).replaceAll('₹', '')})'
        : 'Price N/A';
    final config = p['configuration_name'] ?? '${p['bedrooms'] ?? "-"} BHK';
    final area = p['area_name'] ?? '';
    final title = '$config in $area';
    final imageUrls = p['images'] as List<dynamic>? ?? [];
    final hasImage = imageUrls.isNotEmpty;
    final areaSqft = p['super_builtup_area'] != null ? '${p['super_builtup_area']} sqft' : '';
    final bedrooms = p['bedrooms'] != null ? '${p['bedrooms']}' : '';

    return Container(
      decoration: BoxDecoration(
        color: CRMColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(CRMBorderRadius.l),
        border: Border.all(color: CRMColors.borderOf(context)),
        boxShadow: CRMShadows.medium,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property Image Banner
          AspectRatio(
            aspectRatio: 16 / 9,
            child: SizedBox(
              width: double.infinity,
              child: hasImage
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          imageUrls.first.toString(),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                        ),
                        Container(
                          color: Colors.black.withValues(alpha: 0.45),
                        ),
                        Image.network(
                          imageUrls.first.toString(),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: CRMColors.skeletonBase,
                            child: Icon(Icons.image_not_supported_rounded, size: 48, color: CRMColors.textMuted),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      color: CRMColors.skeletonBase,
                      child: Icon(Icons.image_rounded, size: 48, color: CRMColors.textMuted),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(CRMSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: CRMTypography.cardTitle.copyWith(
                    color: CRMColors.textOf(context),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: CRMSpacing.xs),
                Text(
                  price,
                  style: CRMTypography.cardTitle.copyWith(
                    color: CRMColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (p['society'] != null && p['society'].toString().isNotEmpty) ...[
                  const SizedBox(height: CRMSpacing.xxs),
                  Text(p['society'], style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context))),
                ],
                const SizedBox(height: CRMSpacing.m),
                
                // Quick Specs Row
                Row(
                  children: [
                    if (bedrooms.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: CRMColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(CRMBorderRadius.xs),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.bed_rounded, size: 14, color: CRMColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              bedrooms,
                              style: CRMTypography.captionBold.copyWith(color: CRMColors.primary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: CRMSpacing.s),
                    ],
                    if (areaSqft.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: CRMColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(CRMBorderRadius.xs),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.square_foot_rounded, size: 14, color: CRMColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              areaSqft,
                              style: CRMTypography.captionBold.copyWith(color: CRMColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: CRMSpacing.m),
                
                Text(
                  p['description'] ?? '',
                  style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: CRMSpacing.m),
                Divider(color: CRMColors.borderOf(context), height: 1),
                const SizedBox(height: CRMSpacing.m),
                
                // Buttons Row
                Wrap(
                  spacing: CRMSpacing.s,
                  runSpacing: CRMSpacing.s,
                  children: [
                    CRMButton(
                      label: "View Details",
                      onPressed: () => context.push('/share/${widget.sessionId}/property/${p['id']}'),
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m),
                    ),
                    if (agentMobile.isNotEmpty) ...[
                      CRMButton(
                        label: "Call Agent",
                        prefixIcon: Icons.phone_rounded,
                        onPressed: () => _launchUrlHelper("tel:$agentMobile", p['id'], "Call"),
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m),
                      ),
                      CRMButton(
                        label: "Interested",
                        prefixIcon: Icons.star_rounded,
                        onPressed: () {
                          final text = Uri.encodeComponent("Hi, I am interested in property ${p['property_code']} from your shortlisted share.");
                          _launchUrlHelper("https://wa.me/$agentMobile?text=$text", p['id'], "Interested");
                        },
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m),
                      ),
                      CRMButton(
                        label: "Schedule Visit",
                        prefixIcon: Icons.calendar_today_rounded,
                        onPressed: () {
                          final text = Uri.encodeComponent("Hi, I would like to schedule a visit for property ${p['property_code']} from your shortlisted share.");
                          _launchUrlHelper("https://wa.me/$agentMobile?text=$text", p['id'], "Schedule");
                        },
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
