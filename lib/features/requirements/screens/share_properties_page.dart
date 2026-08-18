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
import '../../properties/models/property_model.dart';

import '../../../../core/utils/currency.dart';
import '../../../../core/utils/seo_helper.dart';

/// WhatsApp brand green — kept as a distinct constant for brand recognition.
const Color _kWhatsAppGreen = Color(0xFF25D366);

class SharePropertiesPage extends StatefulWidget {
  final String sessionId;
  final String? agentName;
  final String? agentMobile;

  const SharePropertiesPage({
    super.key,
    required this.sessionId,
    this.agentName,
    this.agentMobile,
  });

  @override
  State<SharePropertiesPage> createState() => _SharePropertiesPageState();
}

class _SharePropertiesPageState extends State<SharePropertiesPage> {
  bool _isLoading = true;
  String? _errorMessage;
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
          _agent = data['agent'];
          _properties = data['properties'] ?? [];
          _isLoading = false;
        });

        // Dynamic SEO Update
        final agentName = _agent?['full_name'] ?? 'Agent';
        String? firstImage;
        if (_properties.isNotEmpty) {
          try {
            final prop = PropertyModel.fromJson(Map<String, dynamic>.from(_properties.first as Map));
            if (prop.images.isNotEmpty) {
              firstImage = prop.images.first;
            }
          } catch (e) {
            debugPrint("Error parsing first property for SEO: $e");
          }
        }
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

  bool _isRentProperty(Map<String, dynamic> p) {
    try {
      final prop = PropertyModel.fromJson(p);
      final typeName = prop.listingTypeName.toLowerCase();
      if (typeName.contains('resale') || typeName.contains('re-sale') || typeName.contains('sale')) {
        return false;
      }
      if (typeName.contains('rent') || typeName.contains('rental')) {
        return true;
      }
    } catch (_) {}

    final listingType = p['listing_type'];
    String name = '';
    if (listingType is Map) {
      name = (listingType['name'] ?? '').toString().toLowerCase();
    } else if (listingType != null) {
      name = listingType.toString().toLowerCase();
    }
    if (name.contains('resale') || name.contains('re-sale') || name.contains('sale')) {
      return false;
    }
    return true;
  }

  bool get _isRentCollection {
    if (_properties.isEmpty) return true;
    int rentCount = 0;
    int resaleCount = 0;
    for (var p in _properties) {
      if (p is Map<String, dynamic>) {
        if (_isRentProperty(p)) {
          rentCount++;
        } else {
          resaleCount++;
        }
      }
    }
    return rentCount >= resaleCount;
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
    final agentName = _agent?['full_name'] ?? widget.agentName ?? 'Agent';
    final agentMobile = _agent?['mobile'] ?? widget.agentMobile ?? '';

    final isRentColl = _isRentCollection;
    final gradientColors = CRMColors.getGradientPrimaryColor(false, isRentColl);

    final headerBlock = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(CRMSpacing.l),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
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
    final prop = PropertyModel.fromJson(p);
    final isRentProp = _isRentProperty(p);
    final propPrimary = CRMColors.getPrimaryColor(false, isRentProp);

    final double priceVal = prop.price;
    final price = priceVal > 0
        ? '${CRMCurrencyFormatter.format(priceVal)} (${CRMCurrencyFormatter.formatWords(priceVal).replaceAll('₹', '')})'
        : 'Price N/A';
    final config = prop.configurationName ?? '${prop.bedrooms > 0 ? prop.bedrooms : "-"} BHK';
    String displayArea = prop.areaName;
    if (displayArea == 'N/A' || displayArea.trim().isEmpty) {
      final rawArea = p['area_name']?.toString().trim() ?? p['areaName']?.toString().trim() ?? '';
      final rawLandmark = p['landmark']?.toString().trim() ?? prop.landmark?.trim() ?? '';
      final rawAddress = p['address']?.toString().trim() ?? prop.address.trim();
      final rawCity = p['city_name']?.toString().trim() ?? p['cityName']?.toString().trim() ?? prop.cityName.trim();

      if (rawArea.isNotEmpty && rawArea != 'N/A') {
        displayArea = rawArea;
      } else if (rawLandmark.isNotEmpty && rawLandmark != 'N/A') {
        displayArea = rawLandmark;
      } else if (rawAddress.isNotEmpty && rawAddress != 'N/A') {
        displayArea = rawAddress;
      } else if (rawCity.isNotEmpty && rawCity != 'N/A') {
        displayArea = rawCity;
      } else {
        displayArea = '';
      }
    }
    final rawTitle = p['title']?.toString().trim() ?? p['name']?.toString().trim() ?? prop.title.trim();
    final String title;
    if (rawTitle.isNotEmpty && rawTitle != 'N/A') {
      title = rawTitle;
    } else if (displayArea.isNotEmpty && displayArea != 'N/A') {
      title = '$config in $displayArea';
    } else {
      title = config;
    }
    final imageUrls = prop.images;
    final hasImage = imageUrls.isNotEmpty;
    final areaSqft = prop.superBuiltupArea != null ? '${prop.superBuiltupArea!.toStringAsFixed(0)} sqft' : '';
    final bedrooms = prop.bedrooms > 0 ? '${prop.bedrooms}' : '';

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
                          cacheWidth: 800,
                          gaplessPlayback: true,
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                        ),
                        Container(
                          color: Colors.black.withValues(alpha: 0.45),
                        ),
                        Image.network(
                          imageUrls.first.toString(),
                          fit: BoxFit.contain,
                          cacheWidth: 800,
                          gaplessPlayback: true,
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
                    color: propPrimary,
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
                          color: propPrimary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(CRMBorderRadius.xs),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.bed_rounded, size: 14, color: propPrimary),
                            const SizedBox(width: 4),
                            Text(
                              bedrooms,
                              style: CRMTypography.captionBold.copyWith(color: propPrimary),
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
                          color: propPrimary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(CRMBorderRadius.xs),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.square_foot_rounded, size: 14, color: propPrimary),
                            const SizedBox(width: 4),
                            Text(
                              areaSqft,
                              style: CRMTypography.captionBold.copyWith(color: propPrimary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: CRMSpacing.m),
                
                Text(
                  prop.description ?? '',
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
                      backgroundColor: propPrimary,
                      onPressed: () => context.push('/share/${widget.sessionId}/property/${prop.id}'),
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m),
                    ),
                    if (agentMobile.isNotEmpty) ...[
                      CRMButton(
                        label: "Call Agent",
                        backgroundColor: propPrimary,
                        prefixIcon: Icons.phone_rounded,
                        onPressed: () => _launchUrlHelper("tel:$agentMobile", prop.id, "Call"),
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m),
                      ),
                      CRMButton(
                        label: "Interested",
                        backgroundColor: propPrimary,
                        prefixIcon: Icons.star_rounded,
                        onPressed: () {
                          final text = Uri.encodeComponent("Hi, I am interested in property ${prop.propertyCode} from your shortlisted share.");
                          _launchUrlHelper("https://wa.me/$agentMobile?text=$text", prop.id, "Interested");
                        },
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m),
                      ),
                      CRMButton(
                        label: "Schedule Visit",
                        backgroundColor: propPrimary,
                        prefixIcon: Icons.calendar_today_rounded,
                        onPressed: () {
                          final text = Uri.encodeComponent("Hi, I would like to schedule a visit for property ${prop.propertyCode} from your shortlisted share.");
                          _launchUrlHelper("https://wa.me/$agentMobile?text=$text", prop.id, "Schedule");
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
