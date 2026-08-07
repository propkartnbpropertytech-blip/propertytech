import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/design_system/tokens/app_colors.dart';
import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../core/design_system/tokens/app_typography.dart';
import '../../../../core/design_system/tokens/app_shadows.dart';
import '../../../../core/design_system/widgets/cards.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/utils/seo_helper.dart';

/// WhatsApp brand green — kept as a distinct constant for brand recognition.
const Color _kWhatsAppGreen = Color(0xFF25D366);

class PublicPropertyDetailScreen extends StatefulWidget {
  final String sessionId;
  final String propertyId;

  const PublicPropertyDetailScreen({
    super.key,
    required this.sessionId,
    required this.propertyId,
  });

  @override
  State<PublicPropertyDetailScreen> createState() => _PublicPropertyDetailScreenState();
}

class _PublicPropertyDetailScreenState extends State<PublicPropertyDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _agent;
  Map<String, dynamic>? _property;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadPropertyDetails();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadPropertyDetails() async {
    try {
      final response = await DioClient.dio.get('/share-sessions/public/${widget.sessionId}');
      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        final agent = data['agent'];
        final List<dynamic> properties = data['properties'] ?? [];

        final prop = properties.firstWhere(
          (p) => p['id'] == widget.propertyId,
          orElse: () => null,
        );

        if (prop != null) {
          setState(() {
            _agent = agent;
            _property = prop;
            _isLoading = false;
          });

          // Dynamic SEO Update
          final config = prop['configuration_name'] ?? '${prop['bedrooms'] ?? "-"} BHK';
          final area = prop['area_name'] ?? '';
          final double? priceVal = prop['price'] != null ? double.tryParse(prop['price'].toString()) : null;
          final priceStr = priceVal != null
              ? CRMCurrencyFormatter.formatWords(priceVal).replaceAll('₹', '')
              : 'Price on Request';
          final title = '$config in $area | $priceStr - PropKart';
          final description = prop['description'] ?? 'Check out this property shortlist shared on PropKart.';
          final imageUrls = prop['images'] as List<dynamic>? ?? [];
          final firstImage = imageUrls.isNotEmpty ? imageUrls.first.toString() : null;

          SeoHelper.updateTags(
            title: title,
            description: description,
            canonicalUrl: 'https://propkart.nbpropertytech.com/share/${widget.sessionId}/property/${widget.propertyId}',
            imageUrl: firstImage ?? 'https://propkart.nbpropertytech.com/assets/logo.png',
          );
        } else {
          setState(() {
            _errorMessage = "Property not found in this shortlist.";
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = response.data['message'] ?? "Failed to load property details.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load property details.";
        _isLoading = false;
      });
    }
  }

  Future<void> _logClick(String actionType) async {
    try {
      await DioClient.dio.post(
        '/share-sessions/public/${widget.sessionId}/click',
        data: {
          'propertyId': widget.propertyId,
          'actionType': actionType,
        },
      );
    } catch (e) {
      debugPrint("Failed to log click event: $e");
    }
  }

  Future<void> _launchUrlHelper(String url, String actionType) async {
    await _logClick(actionType);
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: CRMColors.text),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(CRMSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 64, color: CRMColors.danger),
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

    final p = _property!;
    final agentName = _agent?['full_name'] ?? 'Agent';
    final agentMobile = _agent?['mobile'] ?? '';
    final code = p['property_code'] ?? '';
    final double? priceVal = p['price'] != null ? double.tryParse(p['price'].toString()) : null;
    final price = priceVal != null
        ? '${CRMCurrencyFormatter.format(priceVal)} (${CRMCurrencyFormatter.formatWords(priceVal).replaceAll('₹', '')})'
        : 'Price N/A';
    final config = p['configuration_name'] ?? '${p['bedrooms'] ?? "-"} BHK';
    final areaName = p['area_name'] ?? '';
    final images = p['images'] as List<dynamic>? ?? [];
    final amenities = p['amenities'] as List<dynamic>? ?? [];
    final society = p['society'] ?? '';

    Widget buildImageSection({required double height}) {
      if (images.isNotEmpty) {
        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            SizedBox(
              height: height,
              width: double.infinity,
              child: PageView.builder(
                controller: _pageController,
                itemCount: images.length,
                onPageChanged: (index) => setState(() => _currentImageIndex = index),
                itemBuilder: (context, index) {
                  final imageUrl = images[index].toString();
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // Blurred background
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                      // Overlay
                      Container(
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                      // Foreground contain image
                      Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: CRMColors.skeletonBase,
                          child: Icon(Icons.image_not_supported_rounded, size: 64, color: CRMColors.textMuted),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            if (images.length > 1) ...[
              // Left Arrow Button
              if (_currentImageIndex > 0)
                Positioned(
                  left: CRMSpacing.s,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
                        onPressed: () {
                          _pageController.animateToPage(
                            _currentImageIndex - 1,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              // Right Arrow Button
              if (_currentImageIndex < images.length - 1)
                Positioned(
                  right: CRMSpacing.s,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.white),
                        onPressed: () {
                          _pageController.animateToPage(
                            _currentImageIndex + 1,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
            Positioned(
              bottom: CRMSpacing.s,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.s, vertical: CRMSpacing.xxs),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(CRMBorderRadius.round),
                ),
                child: Text(
                  "${_currentImageIndex + 1} / ${images.length}",
                  style: CRMTypography.captionBold.copyWith(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        );
      } else {
        return Container(
          height: height,
          width: double.infinity,
          color: CRMColors.skeletonBase,
          child: Icon(Icons.image_rounded, size: 64, color: CRMColors.textMuted),
        );
      }
    }

    Widget buildDetailsSection() {
      String getValue(dynamic json, String key) {
        if (json == null) return '';
        if (json[key] != null && json[key].toString().isNotEmpty) {
          return json[key].toString();
        }
        return '';
      }

      // 1. Basic Details Items
      final List<_DetailItem> basicItems = [];
      
      final listingType = getValue(p, 'listing_type_name');
      final isRent = listingType.toLowerCase() == 'rent';
      if (listingType.isNotEmpty && listingType != 'N/A') {
        basicItems.add(_DetailItem('Listing Type', listingType, Icons.sell_outlined));
      }
      
      final category = getValue(p, 'category_name');
      if (category.isNotEmpty && category != 'N/A') {
        basicItems.add(_DetailItem('Category', category, Icons.category_outlined));
      }
      
      final propType = getValue(p, 'property_type_name');
      if (propType.isNotEmpty && propType != 'N/A') {
        basicItems.add(_DetailItem('Property Type', propType, Icons.home_work_outlined));
      }
      
      final configName = getValue(p, 'configuration_name');
      if (configName.isNotEmpty && configName != 'N/A') {
        basicItems.add(_DetailItem('Configuration', configName, Icons.dashboard_outlined));
      }
      
      final status = getValue(p, 'property_status_name');
      if (status.isNotEmpty && status != 'N/A') {
        basicItems.add(_DetailItem('Status', status, Icons.info_outline));
      }
      
      basicItems.add(_DetailItem('Price', price, Icons.monetization_on_outlined));
      
      final maintenanceVal = p['maintenance'] != null ? double.tryParse(p['maintenance'].toString()) : null;
      final maintenanceStr = (maintenanceVal != null && maintenanceVal > 0) ? CRMCurrencyFormatter.format(maintenanceVal) : "₹0";
      if (isRent) {
        basicItems.add(_DetailItem('Maintenance', '$maintenanceStr/mo', Icons.build_circle_outlined));
      }
      


      // 2. Specifications & Floor Details Items
      final List<_DetailItem> specsItems = [];
      
      final bedroomsVal = p['bedrooms'] != null ? int.tryParse(p['bedrooms'].toString()) : 0;
      if (bedroomsVal != null && bedroomsVal > 0) {
        specsItems.add(_DetailItem('Bedrooms', '$bedroomsVal', Icons.king_bed_outlined));
      }
      
      final bathroomsVal = p['bathrooms'] != null ? int.tryParse(p['bathrooms'].toString()) : 0;
      if (bathroomsVal != null && bathroomsVal > 0) {
        specsItems.add(_DetailItem('Bathrooms', '$bathroomsVal', Icons.bathtub_outlined));
      }
      
      final balconiesVal = p['balconies'] != null ? int.tryParse(p['balconies'].toString()) : 0;
      if (balconiesVal != null && balconiesVal > 0) {
        specsItems.add(_DetailItem('Balconies', '$balconiesVal', Icons.balcony_outlined));
      }
      
      final floorNo = p['floor_no'] != null ? p['floor_no'].toString() : '';
      final totalFloor = p['total_floor'] != null ? p['total_floor'].toString() : '';
      if (floorNo.isNotEmpty || totalFloor.isNotEmpty) {
        String floorStr = '';
        if (floorNo.isNotEmpty && totalFloor.isNotEmpty) {
          floorStr = '$floorNo / $totalFloor';
        } else if (floorNo.isNotEmpty) {
          floorStr = floorNo;
        } else {
          floorStr = 'Total: $totalFloor';
        }
        specsItems.add(_DetailItem('Floor', floorStr, Icons.layers_outlined));
      }
      
      final ageVal = p['age_of_property'] != null ? int.tryParse(p['age_of_property'].toString()) : 0;
      if (ageVal != null && ageVal > 0) {
        String ageDisplay = '';
        if (ageVal <= 1) {
          ageDisplay = '0 to 1 years';
        } else if (ageVal <= 5) {
          ageDisplay = '1 to 5 years';
        } else if (ageVal <= 10) {
          ageDisplay = '5 to 10 years';
        } else if (ageVal <= 14) {
          ageDisplay = '10+ years';
        } else if (ageVal <= 19) {
          ageDisplay = '15+ years';
        } else {
          ageDisplay = '20+ years';
        }
        specsItems.add(_DetailItem('Age (Years)', ageDisplay, Icons.hourglass_empty_rounded));
      }
      
      final superAreaVal = p['super_builtup_area'] != null ? double.tryParse(p['super_builtup_area'].toString()) : 0;
      if (superAreaVal != null && superAreaVal > 0) {
        specsItems.add(_DetailItem('Super Built-up Area', '${superAreaVal.toStringAsFixed(0)} Sq. Ft.', Icons.square_foot_outlined));
      }
      
      final carpetAreaVal = p['carpet_area'] != null ? double.tryParse(p['carpet_area'].toString()) : 0;
      if (carpetAreaVal != null && carpetAreaVal > 0) {
        specsItems.add(_DetailItem('Carpet Area', '${carpetAreaVal.toStringAsFixed(0)} Sq. Ft.', Icons.aspect_ratio_rounded));
      }
      
      final plotAreaVal = p['plot_area'] != null ? double.tryParse(p['plot_area'].toString()) : 0;
      if (plotAreaVal != null && plotAreaVal > 0) {
        specsItems.add(_DetailItem('Plot Area', '${plotAreaVal.toStringAsFixed(0)} Sq. Yds.', Icons.terrain_outlined));
      }
      
      final furnishing = getValue(p, 'furnishing_type_name');
      if (furnishing.isNotEmpty && furnishing != 'N/A') {
        specsItems.add(_DetailItem('Furnishing', furnishing, Icons.chair_outlined));
      }
      
      final facing = getValue(p, 'facing_type_name');
      if (facing.isNotEmpty && facing != 'N/A') {
        specsItems.add(_DetailItem('Facing', facing, Icons.compass_calibration_outlined));
      }
      
      final availFrom = _getAvailableFromFormatted(p);
      if (availFrom != null) {
        specsItems.add(_DetailItem('Available From', availFrom, Icons.event_available_rounded));
      } else {
        specsItems.add(_DetailItem('Available From', 'Not Available', Icons.event_busy_rounded));
      }
      
      final parkingVal = p['parking'] != null ? int.tryParse(p['parking'].toString()) : 0;
      if (parkingVal != null && parkingVal > 0) {
        specsItems.add(_DetailItem('Parking', _getParkingDisplay(parkingVal), Icons.local_parking_rounded));
      }

      // 3. Location & Address Items
      final List<_DetailItem> locationItems = [];
      
      final city = getValue(p, 'city_name');
      if (city.isNotEmpty) {
        locationItems.add(_DetailItem('City', city, Icons.location_city_outlined));
      }
      
      if (areaName.isNotEmpty) {
        locationItems.add(_DetailItem('Area', areaName, Icons.map_outlined));
      }
      
      final pincode = getValue(p, 'pincode');
      if (pincode.isNotEmpty) {
        locationItems.add(_DetailItem('Pincode', pincode, Icons.pin_drop_outlined));
      }
      
      final landmark = getValue(p, 'landmark');
      if (landmark.isNotEmpty) {
        locationItems.add(_DetailItem('Landmark', landmark, Icons.landscape_outlined));
      }
      
      final blockWing = p['block_wing'] != null ? p['block_wing'].toString() : '';
      if (blockWing.isNotEmpty) {
        locationItems.add(_DetailItem('Block/Wing', blockWing, Icons.domain_outlined));
      }
      
      final flatNo = p['flat_no'] != null ? p['flat_no'].toString() : '';
      if (flatNo.isNotEmpty) {
        locationItems.add(_DetailItem('Flat/Plot No.', flatNo, Icons.tag_rounded));
      }
      
      final address = getValue(p, 'address');
      if (address.isNotEmpty) {
        locationItems.add(_DetailItem('Address', address, Icons.home_outlined));
      }

      // 4. Key Details Items
      final List<_DetailItem> contactsItems = [];
      
      final contactName = getValue(p, 'owner_name');
      if (contactName.isNotEmpty) {
        contactsItems.add(_DetailItem('Contact Name', contactName, Icons.person_outline));
      }
      
      final ownership = getValue(p, 'ownership_type_name');
      if (ownership.isNotEmpty) {
        contactsItems.add(_DetailItem('Ownership', ownership, Icons.badge_outlined));
      }
      
      final brokerageType = getValue(p, 'brokerage_type_name');
      if (brokerageType.isNotEmpty) {
        contactsItems.add(_DetailItem('Brokerage Type', brokerageType, Icons.percent_rounded));
      }

      final depositVal = p['deposit'] != null ? double.tryParse(p['deposit'].toString()) : null;
      final depositStr = (depositVal != null && depositVal > 0) ? CRMCurrencyFormatter.format(depositVal) : "₹0";

      // Calculate Available From display fallback
      final availableFrom = getValue(p, 'available_from');
      String availableDisplay = 'Immediate';
      if (availableFrom.isNotEmpty) {
        availableDisplay = availableFrom;
      } else {
        final createdAtStr = getValue(p, 'created_at');
        if (createdAtStr.isNotEmpty) {
          try {
            final parsedDate = DateTime.tryParse(createdAtStr);
            if (parsedDate != null) {
              availableDisplay = DateFormat('dd-MM-yyyy').format(parsedDate);
            }
          } catch (_) {}
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p['title'] != null && p['title'].toString().isNotEmpty && p['title'].toString().toLowerCase() != "$config in $areaName".toLowerCase()) ...[
            Text(
              p['title'].toString(),
              style: CRMTypography.headline.copyWith(
                color: CRMColors.textOf(context),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: CRMSpacing.xxs),
            Text(
              "$config in $areaName",
              style: CRMTypography.bodyMedium.copyWith(
                color: CRMColors.textSecondaryOf(context),
                fontSize: 16,
              ),
            ),
          ] else ...[
            Text(
              "$config in $areaName",
              style: CRMTypography.headline.copyWith(
                color: CRMColors.textOf(context),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: CRMSpacing.xs),
          Text(
            price,
            style: CRMTypography.headline.copyWith(
              color: CRMColors.primary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (society.isNotEmpty) ...[
            const SizedBox(height: CRMSpacing.xxs),
            Text(society, style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context))),
          ],
          const SizedBox(height: CRMSpacing.m),
          
          CRMCard(
            child: Padding(
              padding: const EdgeInsets.all(CRMSpacing.m),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDetailColumn(Icons.bed_rounded, "Bedrooms", "${p['bedrooms'] ?? '-'}"),
                  _buildDetailColumn(Icons.square_foot_rounded, "Area", p['super_builtup_area'] != null ? "${p['super_builtup_area']} sqft" : "-"),
                  _buildDetailColumn(Icons.event_available_rounded, "Available From", availableDisplay),
                ],
              ),
            ),
          ),
          const SizedBox(height: CRMSpacing.l),

          if (listingType.toLowerCase() == 'rent') ...[
            Text("Pricing details", style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: CRMColors.textOf(context))),
            const SizedBox(height: CRMSpacing.s),
            Row(
              children: [
                _buildPriceTag("Deposit", depositStr),
                const SizedBox(width: CRMSpacing.m),
                _buildPriceTag("Maintenance", "$maintenanceStr/mo"),
              ],
            ),
            const SizedBox(height: CRMSpacing.l),
          ],

          // Render Basic Details Card
          if (basicItems.isNotEmpty) ...[
            _buildResponsiveDetailCard('Basic Details', basicItems),
            const SizedBox(height: CRMSpacing.l),
          ],

          // Render Specifications & Floor Details Card
          if (specsItems.isNotEmpty) ...[
            _buildResponsiveDetailCard('Specifications & Floor Details', specsItems),
            const SizedBox(height: CRMSpacing.l),
          ],

          // Render Location & Address Card
          if (locationItems.isNotEmpty) ...[
            _buildResponsiveDetailCard('Location & Address', locationItems),
            const SizedBox(height: CRMSpacing.l),
          ],

          // Render Key Details Card
          if (contactsItems.isNotEmpty) ...[
            _buildResponsiveDetailCard('Contacts & Key Management', contactsItems),
            const SizedBox(height: CRMSpacing.l),
          ],

          if (p['description'] != null && p['description'].toString().isNotEmpty) ...[
            Text("Description", style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: CRMColors.textOf(context))),
            const SizedBox(height: CRMSpacing.s),
            Text(
              p['description'],
              style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context)),
            ),
            const SizedBox(height: CRMSpacing.l),
          ],

          if (amenities.isNotEmpty) ...[
            Text("Amenities", style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: CRMColors.textOf(context))),
            const SizedBox(height: CRMSpacing.s),
            Wrap(
              spacing: CRMSpacing.s,
              runSpacing: CRMSpacing.s,
              children: amenities.map((am) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: CRMColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(CRMBorderRadius.round),
                    border: Border.all(color: CRMColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    am.toString(),
                    style: CRMTypography.captionBold.copyWith(color: CRMColors.primary),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: CRMSpacing.l),
          ],

          CRMCard(
            child: Padding(
              padding: const EdgeInsets.all(CRMSpacing.m),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: CRMColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      agentName.isNotEmpty ? agentName[0].toUpperCase() : 'A',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: CRMSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Need Help?", style: CRMTypography.caption.copyWith(color: CRMColors.textMuted)),
                        Text(agentName, style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: CRMColors.textOf(context))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      );
    }

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;

    return Scaffold(
      backgroundColor: CRMColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: CRMColors.backgroundOf(context),
        elevation: 0,
        title: Text(
          "Property Details ($code)",
          style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: CRMColors.textOf(context)),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: CRMColors.textOf(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: const EdgeInsets.all(CRMSpacing.m),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(CRMBorderRadius.l),
                      boxShadow: CRMShadows.medium,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(CRMBorderRadius.l),
                      child: buildImageSection(height: double.infinity),
                    ),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(CRMSpacing.l),
                          child: buildDetailsSection(),
                        ),
                      ),
                      if (agentMobile.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(CRMSpacing.m),
                          decoration: BoxDecoration(
                            color: CRMColors.cardBgOf(context),
                            border: Border(top: BorderSide(color: CRMColors.borderOf(context))),
                            boxShadow: CRMShadows.medium,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: CRMSpacing.s),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.button)),
                                    side: BorderSide(color: CRMColors.borderOf(context)),
                                  ),
                                  icon: const Icon(Icons.phone_rounded),
                                  label: const Text("Call Agent"),
                                  onPressed: () => _launchUrlHelper("tel:$agentMobile", "Call"),
                                ),
                              ),
                              const SizedBox(width: CRMSpacing.s),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _kWhatsAppGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: CRMSpacing.s),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.button)),
                                  ),
                                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                                  label: const Text("Schedule Visit"),
                                  onPressed: () {
                                    final text = Uri.encodeComponent("Hi, I would like to schedule a visit to see property $code from your shortlisted share.");
                                    _launchUrlHelper("https://wa.me/$agentMobile?text=$text", "Schedule");
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildImageSection(height: 300),
                  Padding(
                    padding: const EdgeInsets.all(CRMSpacing.m),
                    child: buildDetailsSection(),
                  ),
                ],
              ),
            ),
        bottomSheet: !isDesktop && agentMobile.isNotEmpty
            ? Container(
                padding: const EdgeInsets.all(CRMSpacing.m),
                decoration: BoxDecoration(
                  color: CRMColors.cardBgOf(context),
                  border: Border(top: BorderSide(color: CRMColors.borderOf(context))),
                  boxShadow: CRMShadows.medium,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: CRMSpacing.s),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.button)),
                          side: BorderSide(color: CRMColors.borderOf(context)),
                        ),
                        icon: const Icon(Icons.phone_rounded),
                        label: const Text("Call Agent"),
                        onPressed: () => _launchUrlHelper("tel:$agentMobile", "Call"),
                      ),
                    ),
                    const SizedBox(width: CRMSpacing.s),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kWhatsAppGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: CRMSpacing.s),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.button)),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: const Text("Schedule Visit"),
                        onPressed: () {
                          final text = Uri.encodeComponent("Hi, I would like to schedule a visit to see property $code from your shortlisted share.");
                          _launchUrlHelper("https://wa.me/$agentMobile?text=$text", "Schedule");
                        },
                      ),
                    ),
                  ],
                ),
              )
            : null,
      );
  }

  Widget _buildDetailColumn(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 24, color: CRMColors.primary),
        const SizedBox(height: CRMSpacing.xxs),
        Text(label, style: CRMTypography.caption.copyWith(color: CRMColors.textMuted)),
        Text(value, style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context))),
      ],
    );
  }

  Widget _buildPriceTag(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(CRMSpacing.s),
        decoration: BoxDecoration(
          color: CRMColors.backgroundOf(context),
          borderRadius: BorderRadius.circular(CRMBorderRadius.s),
          border: Border.all(color: CRMColors.borderOf(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: CRMTypography.caption.copyWith(color: CRMColors.textMuted)),
            const SizedBox(height: 2),
            Text(value, style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: CRMColors.textOf(context))),
          ],
        ),
      ),
    );
  }

  String _getParkingDisplay(int parkingVal) {
    if (parkingVal >= 11) {
      final optIndex = parkingVal ~/ 10;
      final slotVal = parkingVal % 10;
      String option = 'Basement 1';
      if (optIndex == 1) {
        option = 'Basement 1';
      } else if (optIndex == 2) {
        option = 'Basement 2';
      } else if (optIndex == 3) {
        option = 'Ground Floor';
      }
      return 'Allocated - $option (Slot $slotVal)';
    } else if (parkingVal == 1) {
      return 'Allocated - Basement 1';
    } else if (parkingVal == 2) {
      return 'Allocated - Ground Floor';
    } else if (parkingVal == 3) {
      return 'Allocated';
    } else {
      return 'Open';
    }
  }

  Widget _buildResponsiveDetailCard(String title, List<_DetailItem> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final int cols = constraints.maxWidth > 500 ? 2 : 1;
        final double itemWidth = cols == 2 ? (constraints.maxWidth - CRMSpacing.m) / 2 : constraints.maxWidth;

        return CRMCard(
          padding: const EdgeInsets.all(CRMSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: CRMTypography.bodyMedium.copyWith(color: CRMColors.primaryOf(context), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: CRMSpacing.s),
              Divider(color: CRMColors.borderOf(context).withOpacity(0.6), thickness: 0.5),
              const SizedBox(height: CRMSpacing.s),
              Wrap(
                spacing: CRMSpacing.m,
                runSpacing: CRMSpacing.s,
                children: items.map((item) {
                  return SizedBox(
                    width: itemWidth,
                    child: _buildDetailRow(item.label, item.value, item.icon),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: CRMColors.textSecondaryOf(context)),
          const SizedBox(width: 8),
          Text(
            label,
            style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondaryOf(context)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: CRMTypography.body.copyWith(color: CRMColors.textOf(context), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String? _getAvailableFromFormatted(Map<String, dynamic> p) {
    final statusNameRaw = (p['property_status_name'] ?? '').toString().toLowerCase();
    final statusId = (p['property_status_id'] ?? '').toString();
    final possessionDateStr = p['possession_date']?.toString();
    DateTime? possessionDate;
    if (possessionDateStr != null && possessionDateStr.isNotEmpty) {
      possessionDate = DateTime.tryParse(possessionDateStr);
    }
    
    // Calculate statusDisplayName
    String statusDisplayName = statusNameRaw;
    if (statusNameRaw.contains('to be available') || statusId == 'to_be_available') {
      if (possessionDate != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final avail = DateTime(possessionDate.year, possessionDate.month, possessionDate.day);
        if (today.isAfter(avail) || today.isAtSameMomentAs(avail)) {
          statusDisplayName = 'available';
        } else {
          final df = DateFormat('dd-MM-yyyy');
          statusDisplayName = 'to be available (${df.format(possessionDate)})';
        }
      } else {
        statusDisplayName = 'to be available';
      }
    }
    
    final isAvailableStatus = statusDisplayName.contains('available') || 
                              statusId == 'available' || 
                              statusId == 'to_be_available';
                              
    if (!isAvailableStatus) {
      return null;
    }
    
    if (possessionDate != null) {
      return DateFormat('MMMM d, yyyy').format(possessionDate);
    }
    
    return 'Immediate';
  }
}

class _DetailItem {
  final String label;
  final String value;
  final IconData icon;
  _DetailItem(this.label, this.value, this.icon);
}
