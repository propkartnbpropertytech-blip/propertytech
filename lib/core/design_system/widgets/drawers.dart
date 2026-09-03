import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import '../tokens/app_shadows.dart';
import '../tokens/app_motion.dart';
import '../../../../features/properties/models/property_model.dart';
import '../../utils/budget_formatter.dart';
import 'cards.dart';
import 'buttons.dart';
import 'crm_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'crm_embedded_video_player.dart';
import '../../../../features/auth/bloc/auth_bloc.dart';
import '../../../../features/auth/models/user_model.dart' as auth_model;
import '../../../../features/users/repository/users_repository.dart';
import '../../../../features/users/models/user_model.dart';
import '../../../../features/properties/repository/properties_repository.dart';

void showCRMPropertyDrawer(BuildContext context, PropertyModel property) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Property Details barrier',
    barrierColor: CRMColors.overlayOf(context),
    transitionDuration: CRMMotion.dialog,
    pageBuilder: (context, anim1, anim2) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: BuildPropertyDetailWidget(property: property, showHeaderClose: true),
        ),
      );
    },
    transitionBuilder: (context, anim1, anim2, child) {
      return FadeTransition(
        opacity: anim1,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(anim1),
          child: child,
        ),
      );
    },
  );
}

class BuildPropertyDetailWidget extends StatefulWidget {
  final PropertyModel property;
  final bool showHeaderClose;

  const BuildPropertyDetailWidget({
    super.key,
    required this.property,
    this.showHeaderClose = true,
  });

  @override
  State<BuildPropertyDetailWidget> createState() => _BuildPropertyDetailWidgetState();
}

class _BuildPropertyDetailWidgetState extends State<BuildPropertyDetailWidget> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _overviewKey = GlobalKey();
  final GlobalKey _detailsKey = GlobalKey();
  final GlobalKey _amenitiesKey = GlobalKey();
  final GlobalKey _investKey = GlobalKey();
  final GlobalKey _similarKey = GlobalKey();

  bool _isAgreedToContact = true;
  bool _hasClickedContact = false;
  bool _isShortlisted = false;

  bool _isMobileRevealed = false;
  String? _salesPersonMobile;
  bool _isLoadingSalesPersonMobile = true;

  @override
  void initState() {
    super.initState();
    _fetchSalesPersonMobile();
  }

  Future<void> _fetchSalesPersonMobile() async {
    try {
      final users = await UsersRepository().getUsers();
      final targetId = widget.property.adminId ?? widget.property.createdBy;
      final targetName = widget.property.createdByName.toLowerCase().trim();

      final matchedUser = users.firstWhere(
        (u) =>
            u.id == targetId ||
            (targetName.isNotEmpty &&
                u.fullName.toLowerCase().trim() == targetName) ||
            (u.adminId == targetId),
        orElse: () => users.firstWhere(
          (u) =>
              targetName.isNotEmpty &&
              u.fullName.toLowerCase().trim().contains(targetName),
          orElse: () => const UserModel(
            id: '',
            roleId: '',
            roleName: '',
            fullName: '',
            email: '',
            isActive: true,
          ),
        ),
      );

      if (mounted) {
        setState(() {
          if (matchedUser.mobile != null && matchedUser.mobile!.isNotEmpty) {
            _salesPersonMobile = matchedUser.mobile;
          } else {
            _salesPersonMobile = null;
          }
          _isLoadingSalesPersonMobile = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingSalesPersonMobile = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildSectionNavBar(BuildContext context) {
    final navItems = [
      {'label': 'OVERVIEW', 'key': _overviewKey},
      {'label': 'DETAILS', 'key': _detailsKey},
      {'label': 'FURNISHINGS & AMENITIES', 'key': _amenitiesKey},
      {'label': 'INVESTMENT OPTIONS', 'key': _investKey},
      {'label': 'SIMILAR PROPERTIES', 'key': _similarKey},
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: CRMColors.cardBgOf(context),
        border: Border(bottom: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.5))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: navItems.map((item) {
            final label = item['label'] as String;
            final key = item['key'] as GlobalKey;
            return Padding(
              padding: const EdgeInsets.only(right: 20),
              child: InkWell(
                onTap: () => _scrollToSection(key),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text(
                    label,
                    style: CRMTypography.captionBold.copyWith(
                      color: CRMColors.primaryOf(context),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRightContactSellerCard(BuildContext context, PropertyModel property, auth_model.UserModel? currentUser) {
    final sellerName = property.createdByName.isNotEmpty
        ? property.createdByName
        : (property.ownerName.isNotEmpty ? property.ownerName : 'NB PROPERTYTECH');
    final initials = sellerName.isNotEmpty ? sellerName.substring(0, 2).toUpperCase() : 'NP';

    final displayMobile = _salesPersonMobile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Banner Badge (matching Image 5 top banner)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9E6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFFD56B)),
          ),
          child: Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Color(0xFFD97706), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Great choice! Nice neighborhood around',
                  style: CRMTypography.captionBold.copyWith(color: const Color(0xFF92400E), fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: CRMSpacing.m),

        // Main Contact Sales Person Card
        CRMCard(
          padding: const EdgeInsets.all(CRMSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contact Sales Person',
                style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context), fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: CRMSpacing.m),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC107),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: CRMTypography.bodyMedium.copyWith(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                sellerName,
                                style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: CRMColors.textOf(context)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, size: 18),
                          ],
                        ),
                        Text(
                          'Propkart Expert Pro',
                          style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context), fontSize: 11),
                        ),
                        const SizedBox(height: 6),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _isMobileRevealed
                              ? InkWell(
                                  key: const ValueKey('revealed_mobile'),
                                  onTap: () async {
                                    if (displayMobile != null && displayMobile.isNotEmpty) {
                                      final cleanMobile = displayMobile.replaceAll(RegExp(r'\D'), '');
                                      if (cleanMobile.isNotEmpty) {
                                        final telUri = Uri.parse('tel:$cleanMobile');
                                        try {
                                          if (await canLaunchUrl(telUri)) {
                                            await launchUrl(telUri);
                                          }
                                        } catch (_) {}
                                      }
                                    }
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.phone_rounded, size: 12, color: CRMColors.primaryOf(context)),
                                      const SizedBox(width: 4),
                                      Text(
                                        displayMobile ?? 'No Mobile Added',
                                        style: CRMTypography.captionBold.copyWith(
                                          color: CRMColors.primaryOf(context),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : InkWell(
                                  key: const ValueKey('unrevealed_mobile'),
                                  onTap: () => setState(() => _isMobileRevealed = true),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: CRMColors.primaryOf(context).withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: CRMColors.primaryOf(context).withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.visibility_outlined,
                                          size: 12,
                                          color: CRMColors.primaryOf(context),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'View Mobile Number',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: CRMColors.primaryOf(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: CRMSpacing.m),
              Text(
                'Hi ${currentUser?.fullName ?? "NB PROPERTYTECH PRIVATE LIMITED"}!',
                style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: CRMColors.textOf(context)),
              ),
              GestureDetector(
                onTap: () {
                  setState(() => _isAgreedToContact = !_isAgreedToContact);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Edit details',
                    style: CRMTypography.captionBold.copyWith(color: CRMColors.primaryOf(context), fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: CRMSpacing.m),
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _isAgreedToContact,
                      onChanged: (val) => setState(() => _isAgreedToContact = val ?? false),
                      activeColor: CRMColors.primaryOf(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'I agree to be contacted by Propkart and agents via WhatsApp, SMS, phone, email etc',
                      style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context), fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: CRMSpacing.m),
              CRMButton(
                label: _hasClickedContact ? 'Contacted' : 'Contact Sales Person',
                width: double.infinity,
                height: 44,
                variant: _hasClickedContact ? CRMButtonVariant.secondary : CRMButtonVariant.primary,
                onPressed: () async {
                  setState(() {
                    _hasClickedContact = true;
                    _isMobileRevealed = true;
                  });
                  final targetMobile = displayMobile ?? '';
                  final cleanMobile = targetMobile.replaceAll(RegExp(r'\D'), '');
                  if (cleanMobile.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No mobile number registered for this sales person.'),
                      ),
                    );
                    return;
                  }
                  final targetNum = cleanMobile.length == 10
                      ? '91$cleanMobile'
                      : (cleanMobile.startsWith('91') ? cleanMobile : '91$cleanMobile');
                  final msgText = Uri.encodeComponent(
                    'Hi $sellerName, I am interested in property ${property.propertyCode} - ${property.title}',
                  );
                  final waUrlStr = 'https://wa.me/$targetNum?text=$msgText';
                  final waApiUrlStr = 'https://api.whatsapp.com/send?phone=$targetNum&text=$msgText';

                  final uri = Uri.parse(waUrlStr);
                  final apiUri = Uri.parse(waApiUrlStr);

                  try {
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else if (await canLaunchUrl(apiUri)) {
                      await launchUrl(apiUri, mode: LaunchMode.externalApplication);
                    } else {
                      await launchUrl(uri, mode: LaunchMode.platformDefault);
                    }
                  } catch (e) {
                    try {
                      await launchUrl(apiUri, mode: LaunchMode.externalApplication);
                    } catch (_) {}
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Contacting Sales Person $sellerName ($targetMobile)...',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFF25D366),
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: CRMSpacing.l),
              Divider(color: CRMColors.borderOf(context).withOpacity(0.5)),
              const SizedBox(height: CRMSpacing.s),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Still deciding?',
                          style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context)),
                        ),
                        Text(
                          'Shortlist this property for now & easily come back to it later.',
                          style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isShortlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: _isShortlisted ? CRMColors.danger : CRMColors.textSecondaryOf(context),
                    ),
                    onPressed: () {
                      setState(() => _isShortlisted = !_isShortlisted);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_isShortlisted ? 'Property added to Shortlist!' : 'Removed from Shortlist.'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: CRMSpacing.m),

        // Bottom Share & Feedback Buttons (Matching Image 5)
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: Icon(Icons.share_outlined, size: 16, color: CRMColors.primaryOf(context)),
                label: Text('Share', style: CRMTypography.captionBold.copyWith(color: CRMColors.primaryOf(context))),
                onPressed: () {
                  final url = '${Uri.base.origin}/properties/${property.id}';
                  Clipboard.setData(ClipboardData(text: url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Property link copied to clipboard!'),
                      backgroundColor: CRMColors.success,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: CRMSpacing.m),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: Icon(Icons.outlined_flag_rounded, size: 16, color: CRMColors.textSecondaryOf(context)),
                label: Text('Feedback', style: CRMTypography.captionBold.copyWith(color: CRMColors.textSecondaryOf(context))),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feedback submitted!')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final showHeaderClose = widget.showHeaderClose;
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isDesktop = screenWidth >= 900;
    final isMobile = screenWidth < 768;

    final authState = context.read<AuthBloc>().state;
    bool isUserAdminOrSuperAdmin = false;
    auth_model.UserModel? currentUser;
    if (authState is Authenticated) {
      currentUser = authState.user;
      final role = currentUser.role;
      isUserAdminOrSuperAdmin = role == 'Admin' || role == 'Super Admin';
    }

    final List<PropertyDetailItem> basicItems = [];
    if (_isValidValue(property.listingTypeName)) {
      basicItems.add(PropertyDetailItem('Listing Type', property.listingTypeName, Icons.sell_outlined));
    }
    if (_isValidValue(property.categoryName)) {
      basicItems.add(PropertyDetailItem('Category', property.categoryName, Icons.category_outlined));
    }
    if (_isValidValue(property.propertyTypeName)) {
      basicItems.add(PropertyDetailItem('Property Type', property.propertyTypeName, Icons.home_work_outlined));
    }
    if (_isValidValue(property.configurationName)) {
      basicItems.add(PropertyDetailItem('Configuration', property.configurationName!, Icons.grid_view_rounded));
    }
    if (_isValidValue(property.statusDisplayName)) {
      basicItems.add(PropertyDetailItem('Status', property.statusDisplayName, Icons.info_outline_rounded));
    }
    basicItems.add(PropertyDetailItem('Price', '₹${BudgetFormatter.format(property.price)}', Icons.payments_outlined));
    final isRent = property.listingTypeName.toLowerCase() == 'rent';
    if (isRent && property.deposit > 0) {
      basicItems.add(PropertyDetailItem('Deposit', '₹${BudgetFormatter.format(property.deposit)}', Icons.account_balance_wallet_outlined));
    }
    if (property.maintenance > 0) {
      basicItems.add(PropertyDetailItem('Maintenance', '₹${BudgetFormatter.format(property.maintenance)}/mo', Icons.build_circle_outlined));
    }

    if (isUserAdminOrSuperAdmin && _isValidValue(property.createdByName)) {
      final showCreator = currentUser?.role == 'Super Admin' ||
          (currentUser?.role == 'Admin' && (property.createdBy == currentUser?.id || property.adminId == currentUser?.id));
      if (showCreator) {
        basicItems.add(PropertyDetailItem('Created By', property.createdByName, Icons.person_outline_rounded));
      }
    }
    basicItems.add(PropertyDetailItem('Created At', DateFormat('dd-MM-yyyy').format(property.createdAt), Icons.calendar_today_outlined));
    final remarksVal = _isValidValue(property.remarks) ? property.remarks! : '--';
    basicItems.add(PropertyDetailItem('Internal Remark', remarksVal, Icons.note_alt_outlined));

    final List<PropertyDetailItem> specsItems = [];
    if (property.bedrooms > 0) {
      specsItems.add(PropertyDetailItem('Bedrooms', '${property.bedrooms}', Icons.king_bed_outlined));
    }
    if (property.bathrooms > 0) {
      specsItems.add(PropertyDetailItem('Bathrooms', '${property.bathrooms}', Icons.bathtub_outlined));
    }
    if (property.balconies > 0) {
      specsItems.add(PropertyDetailItem('Balconies', '${property.balconies}', Icons.balcony_outlined));
    }
    if (property.floorNo != null || property.totalFloor != null) {
      String floorStr = '';
      if (property.floorNo != null && property.totalFloor != null) {
        floorStr = '${property.floorNo} / ${property.totalFloor}';
      } else if (property.floorNo != null) {
        floorStr = '${property.floorNo}';
      } else {
        floorStr = 'Total Floors: ${property.totalFloor}';
      }
      specsItems.add(PropertyDetailItem('Floor', floorStr, Icons.layers_outlined));
    }
    if (property.ageOfProperty != null && property.ageOfProperty! > 0) {
      final ageVal = property.ageOfProperty!;
      String ageDisplay;
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
      specsItems.add(PropertyDetailItem('Property Age', ageDisplay, Icons.hourglass_empty_rounded));
    }
    if (property.superBuiltupArea != null && property.superBuiltupArea! > 0) {
      specsItems.add(PropertyDetailItem('Super Built-up Area', '${property.superBuiltupArea!.toStringAsFixed(0)} Sq. Ft.', Icons.square_foot_outlined));
    }
    final carpetVal = (property.carpetArea != null && property.carpetArea! > 0)
        ? '${property.carpetArea!.toStringAsFixed(0)} Sq. Ft.'
        : '--';
    specsItems.add(PropertyDetailItem('Carpet Area Size', carpetVal, Icons.aspect_ratio_rounded));

    final plotVal = (property.plotArea != null && property.plotArea! > 0)
        ? '${property.plotArea!.toStringAsFixed(0)} Sq. Yds.'
        : '--';
    specsItems.add(PropertyDetailItem('Plot Area Size', plotVal, Icons.terrain_outlined));

    if (_isValidValue(property.furnishingTypeName)) {
      specsItems.add(PropertyDetailItem('Furnishing', property.furnishingTypeName!, Icons.chair_outlined));
    }

    final facingVal = _isValidValue(property.facingTypeName) ? property.facingTypeName! : '--';
    specsItems.add(PropertyDetailItem('Facing', facingVal, Icons.compass_calibration_outlined));

    final availFrom = property.availableFromFormatted;
    if (availFrom != null) {
      specsItems.add(PropertyDetailItem('Available From', availFrom, Icons.event_available_rounded));
    } else {
      specsItems.add(PropertyDetailItem('Available From', 'Not Available', Icons.event_busy_rounded));
    }
    if (property.parking > 0) {
      specsItems.add(PropertyDetailItem('Parking', _getParkingDisplay(property.parking), Icons.local_parking_rounded));
    }

    final List<PropertyDetailItem> locationItems = [];
    if (_isValidValue(property.cityName)) {
      locationItems.add(PropertyDetailItem('City', property.cityName, Icons.location_city_outlined));
    }
    if (_isValidValue(property.areaName)) {
      locationItems.add(PropertyDetailItem('Area', property.areaName, Icons.map_outlined));
    }
    if (_isValidValue(property.pincode)) {
      locationItems.add(PropertyDetailItem('Pincode', property.pincode, Icons.pin_drop_outlined));
    }
    if (_isValidValue(property.landmark)) {
      locationItems.add(PropertyDetailItem('Landmark', property.landmark!, Icons.landscape_outlined));
    }
    final blockWingVal = _isValidValue(property.blockWing) ? property.blockWing! : '--';
    locationItems.add(PropertyDetailItem('Block / Wing', blockWingVal, Icons.domain_outlined));

    final flatNoVal = _isValidValue(property.flatNo) ? property.flatNo! : '--';
    locationItems.add(PropertyDetailItem('Flat Number', flatNoVal, Icons.tag_rounded));

    if (_isValidValue(property.address)) {
      locationItems.add(PropertyDetailItem('Address', property.address, Icons.home_outlined));
    }
    if (property.latitude != null && property.longitude != null) {
      locationItems.add(PropertyDetailItem('Coordinates', '${property.latitude!.toStringAsFixed(5)}, ${property.longitude!.toStringAsFixed(5)}', Icons.my_location_outlined));
    }

    final List<PropertyDetailItem> contactsItems = [];
    if (_isValidValue(property.ownershipTypeName)) {
      contactsItems.add(PropertyDetailItem('Ownership', property.ownershipTypeName!, Icons.badge_outlined));
    }
    if (_isValidValue(property.ownerName)) {
      contactsItems.add(PropertyDetailItem('Owner Name', property.ownerName, Icons.assignment_ind_outlined));
    }
    if (_isValidValue(property.ownerMobile)) {
      contactsItems.add(PropertyDetailItem('Owner Mobile', property.ownerMobile, Icons.phone_outlined));
    }
    final referVal = _isValidValue(property.brokerName) ? property.brokerName! : '--';
    contactsItems.add(PropertyDetailItem('Refer Name / Key Collect', referVal, Icons.vpn_key_outlined));

    final brokerageVal = _isValidValue(property.brokerageTypeName) ? property.brokerageTypeName! : '--';
    contactsItems.add(PropertyDetailItem('Brokerage Confirmation', brokerageVal, Icons.percent_rounded));

    return Container(
      width: screenWidth,
      height: double.infinity,
      decoration: BoxDecoration(
        color: CRMColors.backgroundOf(context),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dynamic Property Header (PR Code, Title & Close Button)
            Container(
              color: CRMColors.cardBgOf(context),
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(CRMSpacing.m),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            property.propertyCode,
                            style: CRMTypography.sectionTitle.copyWith(color: CRMColors.primaryOf(context), fontWeight: FontWeight.bold),
                          ),
                          Text(
                            property.title,
                            style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondaryOf(context)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (showHeaderClose)
                      CRMButton(
                        label: 'Close',
                        variant: CRMButtonVariant.danger,
                        height: 40,
                        onPressed: () => Navigator.pop(context),
                      ),
                  ],
                ),
              ),
            ),
            Divider(color: CRMColors.borderOf(context).withOpacity(0.6), height: 1, thickness: 0.5),

            // Sticky Touchable Section Navigation Bar (Matching Image 1)
            _buildSectionNavBar(context),

            // Main Details Body (Full-width outer SingleChildScrollView!)
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(CRMSpacing.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // FULL-WIDTH Property Images Slider at Top (Matching Image 3)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Property Images',
                            style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context)),
                          ),
                          const SizedBox(height: CRMSpacing.s),
                          CRMImageSlider(images: property.images, videos: property.videos),
                        ],
                      ),
                      const SizedBox(height: CRMSpacing.l),

                      // 2-Column Section Layout Below Images
                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // LEFT COLUMN: All Details Sections Stacked 1-by-1 (72% width)
                            Expanded(
                              flex: 72,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  KeyedSubtree(key: _overviewKey, child: _buildOverviewCard(context, property)),
                                  const SizedBox(height: CRMSpacing.m),
                                  KeyedSubtree(key: _detailsKey, child: _buildResponsiveDetailCard(context, 'Basic Details', basicItems)),
                                  const SizedBox(height: CRMSpacing.m),
                                  _buildResponsiveDetailCard(context, 'Specifications & Floor Details', specsItems),
                                  const SizedBox(height: CRMSpacing.m),
                                  _buildResponsiveDetailCard(context, 'Location & Address', locationItems),
                                  const SizedBox(height: CRMSpacing.m),
                                  _buildDescriptionRemarksCard(context, property),
                                  const SizedBox(height: CRMSpacing.m),
                                  KeyedSubtree(key: _amenitiesKey, child: _buildAmenitiesCard(context, property.amenities)),
                                  const SizedBox(height: CRMSpacing.m),
                                  _buildResponsiveDetailCard(context, 'Contacts & Key Management', contactsItems),
                                  const SizedBox(height: CRMSpacing.m),
                                  KeyedSubtree(key: _investKey, child: _buildInvestmentOptionsCard(context, property)),
                                  const SizedBox(height: CRMSpacing.m),
                                  KeyedSubtree(key: _similarKey, child: _buildSimilarPropertiesSection(context, property)),
                                ],
                              ),
                            ),
                            const SizedBox(width: CRMSpacing.l),

                            // RIGHT COLUMN: STICKY Contact Seller Card (28% width)
                            Expanded(
                              flex: 28,
                              child: AnimatedBuilder(
                                animation: _scrollController,
                                builder: (context, child) {
                                  final double scrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
                                  final double stickyOffset = (scrollOffset - 430.0).clamp(0.0, 4000.0);
                                  return Transform.translate(
                                    offset: Offset(0, stickyOffset),
                                    child: child,
                                  );
                                },
                                child: _buildRightContactSellerCard(context, property, currentUser),
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            KeyedSubtree(key: _overviewKey, child: _buildOverviewCard(context, property)),
                            const SizedBox(height: CRMSpacing.m),
                            KeyedSubtree(key: _detailsKey, child: _buildResponsiveDetailCard(context, 'Basic Details', basicItems)),
                            const SizedBox(height: CRMSpacing.m),
                            _buildResponsiveDetailCard(context, 'Specifications & Floor Details', specsItems),
                            const SizedBox(height: CRMSpacing.m),
                            _buildResponsiveDetailCard(context, 'Location & Address', locationItems),
                            const SizedBox(height: CRMSpacing.m),
                            _buildDescriptionRemarksCard(context, property),
                            const SizedBox(height: CRMSpacing.m),
                            KeyedSubtree(key: _amenitiesKey, child: _buildAmenitiesCard(context, property.amenities)),
                            const SizedBox(height: CRMSpacing.m),
                            _buildResponsiveDetailCard(context, 'Contacts & Key Management', contactsItems),
                            const SizedBox(height: CRMSpacing.m),
                            KeyedSubtree(key: _investKey, child: _buildInvestmentOptionsCard(context, property)),
                            const SizedBox(height: CRMSpacing.m),
                            KeyedSubtree(key: _similarKey, child: _buildSimilarPropertiesSection(context, property)),
                            const SizedBox(height: CRMSpacing.l),
                            _buildRightContactSellerCard(context, property, currentUser),
                          ],
                        ),
                    ],
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

class CRMImageSlider extends StatefulWidget {
  final List<String> images;
  final List<String> videos;
  const CRMImageSlider({super.key, required this.images, required this.videos});

  @override
  State<CRMImageSlider> createState() => _CRMImageSliderState();
}

class _CRMImageSliderState extends State<CRMImageSlider> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Timer? _carouselTimer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _carouselTimer?.cancel();
    if (widget.images.length > 1) {
      _carouselTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (_pageController.hasClients) {
          final nextPage = (_currentIndex + 1) % widget.images.length;
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    final totalCount = images.length;
    final hasVideo = widget.videos.isNotEmpty;

    if (totalCount == 0) {
      if (hasVideo) {
        return CRMVideoSlider(videos: widget.videos);
      }
      return Container(
        height: 240,
        width: double.infinity,
        decoration: BoxDecoration(
          color: CRMColors.cardBgOf(context),
          borderRadius: BorderRadius.circular(CRMBorderRadius.card),
          border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.6), width: 0.5),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_outlined, color: CRMColors.textMutedOf(context), size: 48),
              const SizedBox(height: CRMSpacing.s),
              Text(
                'No Images Uploaded',
                style: CRMTypography.caption.copyWith(color: CRMColors.textMutedOf(context)),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = width > 768 ? 380.0 : 260.0;
        final double spacing = 8.0;
        final bool isDesktop = width > 768;

        if (hasVideo) {
          if (isDesktop) {
            // Side-by-Side: Left is auto-sliding image, Right is video player
            final halfWidth = (width - spacing) / 2;
            return SizedBox(
              width: width,
              height: height,
              child: Row(
                children: [
                  SizedBox(
                    width: halfWidth,
                    height: height,
                    child: _buildMainImageSlider(context, height, totalCount),
                  ),
                  SizedBox(width: spacing),
                  SizedBox(
                    width: halfWidth,
                    height: height,
                    child: CRMVideoSlider(videos: widget.videos),
                  ),
                ],
              ),
            );
          } else {
            // Mobile: Stacked: Top is auto-sliding image, Bottom is video player
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMainImageSlider(context, height, totalCount),
                SizedBox(height: spacing * 2),
                Text(
                  'Property Video',
                  style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context)),
                ),
                const SizedBox(height: CRMSpacing.s),
                CRMVideoSlider(videos: widget.videos),
              ],
            );
          }
        }

        // NO VIDEO: Fall back to original dynamic image grids (Desktop only, Mobile is single main slider)
        if (!isDesktop) {
          return _buildMainImageSlider(context, height, totalCount);
        }

        if (totalCount == 1) {
          return _buildMainImageSlider(context, height, totalCount);
        } else if (totalCount == 2) {
          final halfWidth = (width - spacing) / 2;
          return SizedBox(
            width: width,
            height: height,
            child: Row(
              children: [
                SizedBox(
                  width: halfWidth,
                  height: height,
                  child: _buildMainImageSlider(context, height, totalCount),
                ),
                SizedBox(width: spacing),
                SizedBox(
                  width: halfWidth,
                  height: height,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(CRMBorderRadius.card),
                    child: _buildGalleryTile(context, images[1], 1),
                  ),
                ),
              ],
            ),
          );
        } else if (totalCount == 3) {
          final leftWidth = (width - spacing) * 0.65;
          final rightWidth = (width - spacing) * 0.35;
          final rightHeight = (height - spacing) / 2;
          return SizedBox(
            width: width,
            height: height,
            child: Row(
              children: [
                SizedBox(
                  width: leftWidth,
                  height: height,
                  child: _buildMainImageSlider(context, height, totalCount),
                ),
                SizedBox(width: spacing),
                SizedBox(
                  width: rightWidth,
                  height: height,
                  child: Column(
                    children: [
                      SizedBox(
                        width: rightWidth,
                        height: rightHeight,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(CRMBorderRadius.card),
                          child: _buildGalleryTile(context, images[1], 1),
                        ),
                      ),
                      SizedBox(height: spacing),
                      SizedBox(
                        width: rightWidth,
                        height: rightHeight,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(CRMBorderRadius.card),
                          child: _buildGalleryTile(context, images[2], 2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else if (totalCount == 4) {
          final leftWidth = (width - spacing) * 0.6;
          final rightWidth = (width - spacing) * 0.4;
          final rightHeight = (height - (spacing * 2)) / 3;
          return SizedBox(
            width: width,
            height: height,
            child: Row(
              children: [
                SizedBox(
                  width: leftWidth,
                  height: height,
                  child: _buildMainImageSlider(context, height, totalCount),
                ),
                SizedBox(width: spacing),
                SizedBox(
                  width: rightWidth,
                  height: height,
                  child: Column(
                    children: [
                      SizedBox(
                        width: rightWidth,
                        height: rightHeight,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(CRMBorderRadius.card),
                          child: _buildGalleryTile(context, images[1], 1),
                        ),
                      ),
                      SizedBox(height: spacing),
                      SizedBox(
                        width: rightWidth,
                        height: rightHeight,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(CRMBorderRadius.card),
                          child: _buildGalleryTile(context, images[2], 2),
                        ),
                      ),
                      SizedBox(height: spacing),
                      SizedBox(
                        width: rightWidth,
                        height: rightHeight,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(CRMBorderRadius.card),
                          child: _buildGalleryTile(context, images[3], 3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          final leftWidth = (width - spacing) * 0.55;
          final rightWidth = (width - spacing) * 0.45;
          final rightTileWidth = (rightWidth - spacing) / 2;
          final rightTileHeight = (height - spacing) / 2;

          return SizedBox(
            width: width,
            height: height,
            child: Row(
              children: [
                SizedBox(
                  width: leftWidth,
                  height: height,
                  child: _buildMainImageSlider(context, height, totalCount),
                ),
                SizedBox(width: spacing),
                SizedBox(
                  width: rightWidth,
                  height: height,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: rightTileWidth,
                            height: rightTileHeight,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(CRMBorderRadius.card),
                              child: _buildGalleryTile(context, images[1], 1),
                            ),
                          ),
                          SizedBox(width: spacing),
                          SizedBox(
                            width: rightTileWidth,
                            height: rightTileHeight,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(CRMBorderRadius.card),
                              child: _buildGalleryTile(context, images[2], 2),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing),
                      Row(
                        children: [
                          SizedBox(
                            width: rightTileWidth,
                            height: rightTileHeight,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(CRMBorderRadius.card),
                              child: _buildGalleryTile(context, images[3], 3),
                            ),
                          ),
                          SizedBox(width: spacing),
                          SizedBox(
                            width: rightTileWidth,
                            height: rightTileHeight,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(CRMBorderRadius.card),
                              child: _buildGalleryTile(
                                context,
                                images[4],
                                4,
                                showOverlay: totalCount > 5,
                                overlayText: '+${totalCount - 5}',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildMainImageSlider(BuildContext context, double height, int totalCount) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(CRMBorderRadius.card),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierColor: Colors.black.withOpacity(0.9),
                      builder: (context) => CRMImageZoomViewer(
                        images: widget.images,
                        initialIndex: index,
                      ),
                    );
                  },
                  child: CrmNetworkImage(
                    url: widget.images[index],
                    fit: BoxFit.cover,
                    placeholder: (context) => const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.0),
                      ),
                    ),
                    error: (context) => Container(
                      color: CRMColors.cardBgOf(context),
                      child: const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 32),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    barrierColor: Colors.black.withOpacity(0.9),
                    builder: (context) => CRMImageZoomViewer(
                      images: widget.images,
                      initialIndex: _currentIndex,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24, width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_library_outlined, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'View All $totalCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryTile(
    BuildContext context,
    String url,
    int index, {
    bool showOverlay = false,
    String? overlayText,
  }) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          barrierColor: Colors.black.withOpacity(0.9),
          builder: (context) => CRMImageZoomViewer(
            images: widget.images,
            initialIndex: index,
          ),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          CrmNetworkImage(
            url: url,
            fit: BoxFit.cover,
            placeholder: (context) => const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.0),
              ),
            ),
            error: (context) => Container(
              color: CRMColors.cardBgOf(context),
              child: Icon(Icons.broken_image_outlined,
                  color: CRMColors.textMutedOf(context), size: 32),
            ),
          ),
          if (showOverlay && overlayText != null) ...[
            Container(
              color: Colors.black.withOpacity(0.55),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      overlayText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Photos',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CRMImageZoomViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const CRMImageZoomViewer({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<CRMImageZoomViewer> createState() => _CRMImageZoomViewerState();
}

class _CRMImageZoomViewerState extends State<CRMImageZoomViewer> {
  late PageController _pageController;
  late ScrollController _thumbScrollController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _thumbScrollController = ScrollController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToThumbnail(_currentIndex);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _thumbScrollController.dispose();
    super.dispose();
  }

  void _scrollToThumbnail(int index) {
    if (_thumbScrollController.hasClients) {
      final double targetOffset = index * 68.0 - (MediaQuery.sizeOf(context).width / 2) + 34.0;
      final double maxScroll = _thumbScrollController.position.maxScrollExtent;
      final double minScroll = _thumbScrollController.position.minScrollExtent;
      _thumbScrollController.animateTo(
        targetOffset.clamp(minScroll, maxScroll),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isDesktop = size.width > 600;

    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Main Image Viewer
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.images.length,
                onPageChanged: (idx) {
                  setState(() {
                    _currentIndex = idx;
                  });
                  _scrollToThumbnail(idx);
                },
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: CrmNetworkImage(
                        url: widget.images[index],
                        fit: BoxFit.contain,
                        placeholder: (context) => const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                        error: (context) => const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white60,
                          size: 64,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Header: Indicator and Close Button
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Left Arrow Control (Desktop)
          if (isDesktop && _currentIndex > 0)
            Positioned(
              left: 24,
              top: 0,
              bottom: 0,
              child: Center(
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  radius: 22,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
              ),
            ),

          // Right Arrow Control (Desktop)
          if (isDesktop && _currentIndex < widget.images.length - 1)
            Positioned(
              right: 24,
              top: 0,
              bottom: 0,
              child: Center(
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  radius: 22,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
              ),
            ),

          // Bottom Thumbnail Navigator
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 56,
                    child: ListView.builder(
                      controller: _thumbScrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: widget.images.length,
                      itemBuilder: (context, index) {
                        final isSelected = index == _currentIndex;
                        return GestureDetector(
                          onTap: () {
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            width: 56,
                            height: 56,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.white24,
                                width: isSelected ? 2.5 : 1.0,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: CrmNetworkImage(
                                url: widget.images[index],
                                fit: BoxFit.cover,
                                placeholder: (context) => Container(color: Colors.white10),
                                error: (context) => Container(
                                  color: Colors.white10,
                                  child: const Icon(Icons.image, color: Colors.white30, size: 16),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PropertyDetailItem {
  final String label;
  final String value;
  final IconData icon;

  PropertyDetailItem(this.label, this.value, this.icon);
}

bool _isValidValue(String? value) {
  if (value == null) return false;
  final val = value.trim();
  if (val.isEmpty || val.toLowerCase() == 'n/a' || val.toLowerCase() == 'none' || val.toLowerCase() == 'null' || val.toLowerCase() == 'pending verification') {
    return false;
  }
  return true;
}

Widget _buildResponsiveDetailCard(BuildContext context, String title, List<PropertyDetailItem> items) {
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
                  child: _buildDetailRow(context, item.label, item.value, item.icon),
                );
              }).toList(),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildDetailRow(BuildContext context, String label, String value, IconData icon) {
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

Widget _buildDescriptionRemarksCard(BuildContext context, PropertyModel p) {
  final hasDesc = _isValidValue(p.description);
  final hasRemarks = _isValidValue(p.remarks);

  if (!hasDesc && !hasRemarks) return const SizedBox.shrink();

  return CRMCard(
    padding: const EdgeInsets.all(CRMSpacing.m),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description & Remarks',
          style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context), fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: CRMSpacing.s),
        Divider(color: CRMColors.borderOf(context).withOpacity(0.6), thickness: 0.5),
        const SizedBox(height: CRMSpacing.s),
        if (hasDesc) ...[
          _buildTextSection(context, 'Description', p.description!),
          const SizedBox(height: CRMSpacing.m),
        ],
        if (hasRemarks) ...[
          _buildTextSection(context, 'Operational CRM Remarks', p.remarks!),
        ],
      ],
    ),
  );
}

Widget _buildAmenitiesCard(BuildContext context, List<String> amenities) {
  if (amenities.isEmpty) return const SizedBox.shrink();

  return CRMCard(
    padding: const EdgeInsets.all(CRMSpacing.m),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amenities',
          style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context), fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: CRMSpacing.s),
        Divider(color: CRMColors.borderOf(context).withOpacity(0.6), thickness: 0.5),
        const SizedBox(height: CRMSpacing.m),
        _buildAmenitiesSection(context, 'Furnishings & Features', amenities),
      ],
    ),
  );
}

Widget _buildDescriptionCard(BuildContext context, PropertyModel p) {
  final hasDesc = _isValidValue(p.description);
  final hasRemarks = _isValidValue(p.remarks);
  final hasAmenities = p.amenities.isNotEmpty;

  if (!hasDesc && !hasRemarks && !hasAmenities) return const SizedBox.shrink();

  return CRMCard(
    padding: const EdgeInsets.all(CRMSpacing.m),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description & Remarks',
          style: CRMTypography.bodyMedium.copyWith(color: CRMColors.primaryOf(context), fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: CRMSpacing.s),
        Divider(color: CRMColors.borderOf(context).withOpacity(0.6), thickness: 0.5),
        const SizedBox(height: CRMSpacing.s),
        if (hasDesc) ...[
          _buildTextSection(context, 'Description', p.description!),
          const SizedBox(height: CRMSpacing.m),
        ],
        if (hasRemarks) ...[
          _buildTextSection(context, 'Operational CRM Remarks', p.remarks!),
          const SizedBox(height: CRMSpacing.m),
        ],
        if (hasAmenities) ...[
          _buildAmenitiesSection(context, 'Amenities', p.amenities),
        ],
      ],
    ),
  );
}

Widget _buildTextSection(BuildContext context, String label, String content) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: CRMTypography.captionBold.copyWith(color: CRMColors.textSecondaryOf(context)),
      ),
      const SizedBox(height: CRMSpacing.xs),
      Text(
        content,
        style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
      ),
    ],
  );
}

Widget _buildOverviewCard(BuildContext context, PropertyModel p) {
  final areaStr = p.superBuiltupArea != null && p.superBuiltupArea! > 0
      ? '${p.superBuiltupArea!.toStringAsFixed(0)} sq.ft'
      : (p.carpetArea != null && p.carpetArea! > 0 ? '${p.carpetArea!.toStringAsFixed(0)} sq.ft' : 'N/A');

  final floorStr = p.floorNo != null
      ? '${p.floorNo} of ${p.totalFloor ?? '-'}'
      : (p.totalFloor != null ? 'Total ${p.totalFloor}' : 'N/A');

  return CRMCard(
    padding: const EdgeInsets.all(CRMSpacing.m),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context), fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: CRMSpacing.m),
        Wrap(
          spacing: 20,
          runSpacing: 16,
          children: [
            _buildOverviewTile(context, 'Project / Title', p.title.isNotEmpty ? p.title : p.propertyCode, Icons.business_rounded),
            _buildOverviewTile(context, 'Security Deposit', p.deposit > 0 ? '₹${BudgetFormatter.format(p.deposit)}' : 'N/A', Icons.account_balance_wallet_outlined),
            _buildOverviewTile(context, 'Built Up Area', areaStr, Icons.square_foot_outlined),
            _buildOverviewTile(context, 'Furnishing', p.furnishingTypeName ?? 'Unfurnished', Icons.chair_outlined),
            _buildOverviewTile(context, 'Bathrooms', p.bathrooms > 0 ? '${p.bathrooms}' : 'N/A', Icons.bathtub_outlined),
            _buildOverviewTile(context, 'Balcony', p.balconies > 0 ? '${p.balconies}' : 'N/A', Icons.balcony_outlined),
            _buildOverviewTile(context, 'Available From', p.availableFromFormatted ?? 'Available Now', Icons.event_available_rounded),
            _buildOverviewTile(context, 'Floor Number', floorStr, Icons.layers_outlined),
            _buildOverviewTile(context, 'Age of Property', p.ageOfProperty != null ? '${p.ageOfProperty} years' : 'N/A', Icons.hourglass_empty_rounded),
            _buildOverviewTile(context, 'Parking Info', p.parking > 0 ? _getParkingDisplay(p.parking) : 'None', Icons.local_parking_rounded),
          ],
        ),
      ],
    ),
  );
}

Widget _buildOverviewTile(BuildContext context, String label, String value, IconData icon) {
  return SizedBox(
    width: 200,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context), fontSize: 11),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(icon, size: 14, color: CRMColors.primaryOf(context)),
            const SizedBox(width: 4),
            Expanded(
              child: Tooltip(
                message: value,
                child: Text(
                  value,
                  style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: CRMColors.textOf(context), fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

IconData _getAmenityIcon(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('ac') || lower.contains('air condition')) return Icons.ac_unit_rounded;
  if (lower.contains('tv') || lower.contains('television')) return Icons.tv_rounded;
  if (lower.contains('geyser') || lower.contains('water heater')) return Icons.water_drop_rounded;
  if (lower.contains('gym') || lower.contains('fitness')) return Icons.fitness_center_rounded;
  if (lower.contains('lift') || lower.contains('elevator')) return Icons.elevator_rounded;
  if (lower.contains('power') || lower.contains('backup') || lower.contains('generator')) return Icons.battery_charging_full_rounded;
  if (lower.contains('intercom') || lower.contains('phone')) return Icons.phone_in_talk_rounded;
  if (lower.contains('pool') || lower.contains('swim')) return Icons.pool_rounded;
  if (lower.contains('security') || lower.contains('cctv') || lower.contains('guard')) return Icons.security_rounded;
  if (lower.contains('gas') || lower.contains('pipeline')) return Icons.local_gas_station_rounded;
  if (lower.contains('park') || lower.contains('garden')) return Icons.park_rounded;
  if (lower.contains('wifi') || lower.contains('internet')) return Icons.wifi_rounded;
  if (lower.contains('club')) return Icons.meeting_room_rounded;
  if (lower.contains('play') || lower.contains('kid')) return Icons.sports_esports_rounded;
  return Icons.check_circle_outline_rounded;
}

Widget _buildAmenitiesSection(BuildContext context, String label, List<String> amenities) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: CRMTypography.captionBold.copyWith(color: CRMColors.textSecondaryOf(context)),
      ),
      const SizedBox(height: CRMSpacing.s),
      Wrap(
        spacing: CRMSpacing.s,
        runSpacing: CRMSpacing.s,
        children: amenities.map((am) {
          final icon = _getAmenityIcon(am);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: CRMColors.cardBgOf(context),
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.6)),
              boxShadow: CRMShadows.small,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: CRMColors.primaryOf(context)),
                const SizedBox(width: 8),
                Text(
                  am,
                  style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textOf(context), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    ],
  );
}

Widget _buildInvestmentOptionsCard(BuildContext context, PropertyModel p) {
  return _InvestmentOptionsSectionWidget(property: p);
}

class _InvestmentOptionsSectionWidget extends StatefulWidget {
  final PropertyModel property;

  const _InvestmentOptionsSectionWidget({required this.property});

  @override
  State<_InvestmentOptionsSectionWidget> createState() => _InvestmentOptionsSectionWidgetState();
}

class _InvestmentOptionsSectionWidgetState extends State<_InvestmentOptionsSectionWidget> {
  late String _selectedTab;

  @override
  void initState() {
    super.initState();
    final catName = widget.property.categoryName.toLowerCase();
    if (catName.contains('resident') || catName.contains('apartment') || catName.contains('flat') || catName.contains('villa') || catName.contains('bhk')) {
      _selectedTab = 'Residential';
    } else if (catName.contains('industrial') || catName.contains('factory') || catName.contains('warehouse')) {
      _selectedTab = 'Industrial';
    } else if (catName.contains('land') || catName.contains('plot')) {
      _selectedTab = 'Land & Plot';
    } else {
      _selectedTab = 'Commercial';
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.property;
    final loc = p.areaName.isNotEmpty ? p.areaName : (p.cityName.isNotEmpty ? p.cityName : 'this Area');
    final listing = p.listingTypeName.isNotEmpty ? p.listingTypeName : 'Rent';

    final Map<String, List<Map<String, dynamic>>> categoryOptions = {
      'Residential': [
        {'title': '2 BHK Flat for $listing', 'subtitle': 'In $loc', 'icon': Icons.apartment_rounded, 'keyword': '2 BHK'},
        {'title': '3 BHK Flat for $listing', 'subtitle': 'In $loc', 'icon': Icons.home_work_rounded, 'keyword': '3 BHK'},
        {'title': 'Villas for $listing', 'subtitle': 'In $loc', 'icon': Icons.house_rounded, 'keyword': 'Villa'},
        {'title': 'Penthouses for $listing', 'subtitle': 'In $loc', 'icon': Icons.other_houses_rounded, 'keyword': 'Penthouse'},
      ],
      'Commercial': [
        {'title': 'Commercial for $listing', 'subtitle': 'In $loc', 'icon': Icons.storefront_rounded, 'keyword': 'Commercial'},
        {'title': 'Offices for $listing', 'subtitle': 'In $loc', 'icon': Icons.business_center_rounded, 'keyword': 'Office'},
        {'title': 'Shops for $listing', 'subtitle': 'In $loc', 'icon': Icons.shopping_bag_rounded, 'keyword': 'Shop'},
        {'title': 'Showrooms for $listing', 'subtitle': 'In $loc', 'icon': Icons.domain_rounded, 'keyword': 'Showroom'},
      ],
      'Industrial': [
        {'title': 'Industrial Shed for $listing', 'subtitle': 'In $loc', 'icon': Icons.precision_manufacturing_rounded, 'keyword': 'Industrial'},
        {'title': 'Warehouses for $listing', 'subtitle': 'In $loc', 'icon': Icons.warehouse_rounded, 'keyword': 'Warehouse'},
        {'title': 'Factories for $listing', 'subtitle': 'In $loc', 'icon': Icons.factory_rounded, 'keyword': 'Factory'},
      ],
      'Land & Plot': [
        {'title': 'Residential Plots for $listing', 'subtitle': 'In $loc', 'icon': Icons.landscape_rounded, 'keyword': 'Plot'},
        {'title': 'Commercial Land for $listing', 'subtitle': 'In $loc', 'icon': Icons.terrain_rounded, 'keyword': 'Land'},
        {'title': 'Agricultural Land for $listing', 'subtitle': 'In $loc', 'icon': Icons.grass_rounded, 'keyword': 'Agricultural'},
      ],
    };

    final currentOptions = categoryOptions[_selectedTab] ?? categoryOptions['Commercial']!;

    return CRMCard(
      padding: const EdgeInsets.all(CRMSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Looking for Options to Invest in $loc',
                  style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textOf(context), fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.m),

          // Category Selector Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Residential', 'Commercial', 'Industrial', 'Land & Plot'].map((cat) {
                final isSelected = _selectedTab == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTab = cat;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? CRMColors.primaryOf(context)
                            : CRMColors.primaryOf(context).withOpacity(0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? CRMColors.primaryOf(context)
                              : CRMColors.primaryOf(context).withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? Colors.white : CRMColors.textOf(context),
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: CRMSpacing.m),

          // Option Cards Horizontal List
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: currentOptions.map((opt) {
                final keyword = opt['keyword'] as String;
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        final String searchTerm = '$keyword $loc';
                        String bhkParam = '';
                        if (keyword.contains('2 BHK')) {
                          bhkParam = '&bhk=2';
                        } else if (keyword.contains('3 BHK')) {
                          bhkParam = '&bhk=3';
                        } else if (keyword.contains('4 BHK')) {
                          bhkParam = '&bhk=4';
                        }

                        final String path = '/search?search=${Uri.encodeComponent(searchTerm)}&listingType=${Uri.encodeComponent(listing)}&categoryTab=${Uri.encodeComponent(_selectedTab)}$bhkParam';
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                        if (kIsWeb) {
                          final currentOrigin = Uri.base.origin;
                          final fullUrl = '$currentOrigin/#$path';
                          launchUrl(Uri.parse(fullUrl), webOnlyWindowName: '_blank');
                        } else {
                          context.go(path);
                        }
                      },
                      borderRadius: BorderRadius.circular(CRMBorderRadius.card),
                      child: Container(
                        width: 195,
                        margin: const EdgeInsets.only(right: CRMSpacing.m),
                        padding: const EdgeInsets.all(CRMSpacing.m),
                        decoration: BoxDecoration(
                          color: CRMColors.primaryOf(context).withOpacity(0.04),
                          borderRadius: BorderRadius.circular(CRMBorderRadius.card),
                          border: Border.all(color: CRMColors.primaryOf(context).withOpacity(0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: CRMColors.primaryOf(context).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(opt['icon'] as IconData, size: 20, color: CRMColors.primaryOf(context)),
                            ),
                            const SizedBox(height: CRMSpacing.s),
                            Text(
                              opt['title'] as String,
                              style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              opt['subtitle'] as String,
                              style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context), fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildSimilarPropertiesSection(BuildContext context, PropertyModel currentProp) {
  final bhkStr = currentProp.bedrooms > 0 ? '${currentProp.bedrooms} BHK ' : '';
  final locationStr = currentProp.areaName.isNotEmpty
      ? currentProp.areaName
      : (currentProp.cityName.isNotEmpty ? currentProp.cityName : 'this Area');

  return CRMCard(
    padding: const EdgeInsets.all(CRMSpacing.m),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Similar ${bhkStr}Properties in $locationStr',
                    style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context), fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Suggested properties based on location, configuration & price',
                    style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: CRMSpacing.m),
        FutureBuilder<List<PropertyModel>>(
          future: PropertiesRepository().getProperties(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final allProps = snapshot.data ?? [];
            final similar = allProps.where((p) {
              if (p.id == currentProp.id) return false;
              // Strict BHK match: if current property is a 2 BHK, strictly require p.bedrooms == 2
              if (currentProp.bedrooms > 0) {
                if (p.bedrooms != currentProp.bedrooms) return false;
              } else {
                if (currentProp.propertyTypeId.isNotEmpty && p.propertyTypeId.isNotEmpty) {
                  if (p.propertyTypeId != currentProp.propertyTypeId) return false;
                } else if (currentProp.categoryId.isNotEmpty && p.categoryId.isNotEmpty) {
                  if (p.categoryId != currentProp.categoryId) return false;
                }
              }

              if (currentProp.listingTypeName.isNotEmpty && p.listingTypeName.isNotEmpty) {
                if (p.listingTypeName.toLowerCase() != currentProp.listingTypeName.toLowerCase()) {
                  return false;
                }
              }

              final bool matchesArea = currentProp.areaId.isNotEmpty && p.areaId == currentProp.areaId;
              final bool matchesCity = currentProp.cityId.isNotEmpty && p.cityId == currentProp.cityId;
              return matchesArea || matchesCity;
            }).take(8).toList();

            if (similar.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(CRMSpacing.l),
                decoration: BoxDecoration(
                  color: CRMColors.backgroundOf(context),
                  borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                  border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.5)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_off_rounded, color: CRMColors.textMutedOf(context), size: 36),
                    const SizedBox(height: CRMSpacing.s),
                    Text(
                      'No similar property suggestions available for this location.',
                      style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondaryOf(context)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: similar.map((p) {
                  final String imgUrl = p.images.isNotEmpty ? p.images.first : '';
                  final String titleBhk = p.bedrooms > 0 ? '${p.bedrooms} BHK ${p.propertyTypeName}' : p.propertyTypeName;
                  final String areaText = '${p.superBuiltupArea?.toStringAsFixed(0) ?? p.carpetArea?.toStringAsFixed(0) ?? "-"} sq.ft';
                  final String furnishedText = p.furnishingTypeName ?? 'Unfurnished';

                  return Container(
                    width: 230,
                    margin: const EdgeInsets.only(right: CRMSpacing.m),
                    decoration: BoxDecoration(
                      color: CRMColors.cardBgOf(context),
                      borderRadius: BorderRadius.circular(CRMBorderRadius.card),
                      border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.7)),
                      boxShadow: CRMShadows.small,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(CRMBorderRadius.card),
                      onTap: () {
                        showCRMPropertyDrawer(context, p);
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(CRMBorderRadius.card)),
                            child: Stack(
                              children: [
                                Container(
                                  height: 125,
                                  width: double.infinity,
                                  color: Colors.grey.shade200,
                                  child: imgUrl.isNotEmpty
                                      ? CrmNetworkImage(url: imgUrl, fit: BoxFit.cover)
                                      : Center(
                                          child: Icon(Icons.home_work_outlined, size: 36, color: Colors.grey.shade400),
                                        ),
                                ),
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: CRMColors.success,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.check_circle_rounded, size: 10, color: Colors.white),
                                        const SizedBox(width: 3),
                                        Text(
                                          'Verified',
                                          style: CRMTypography.captionBold.copyWith(color: Colors.white, fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(CRMSpacing.s),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '₹${BudgetFormatter.format(p.price)}',
                                  style: CRMTypography.sectionTitle.copyWith(
                                    color: CRMColors.textOf(context),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  titleBhk,
                                  style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${p.areaName}, ${p.cityName}',
                                  style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context), fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: CRMSpacing.xs),
                                Row(
                                  children: [
                                    Text(
                                      furnishedText,
                                      style: TextStyle(color: CRMColors.textSecondaryOf(context), fontSize: 10, fontWeight: FontWeight.w600),
                                    ),
                                    const Text(' • ', style: TextStyle(fontSize: 10)),
                                    Text(
                                      areaText,
                                      style: TextStyle(color: CRMColors.textSecondaryOf(context), fontSize: 10, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: CRMSpacing.s),
                                CRMButton(
                                  label: 'Contact',
                                  height: 32,
                                  onPressed: () {
                                    showCRMPropertyDrawer(context, p);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
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
  } else {
    return 'Open';
  }
}

class CRMVideoSlider extends StatefulWidget {
  final List<String> videos;
  const CRMVideoSlider({super.key, required this.videos});

  @override
  State<CRMVideoSlider> createState() => _CRMVideoSliderState();
}

class _CRMVideoSliderState extends State<CRMVideoSlider> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videos.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double containerWidth = width > 720 ? 720 : width;

        return Center(
          child: SizedBox(
            width: containerWidth,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(CRMBorderRadius.card),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: widget.videos.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return Container(
                          color: Colors.black,
                          child: CRMEmbeddedVideoPlayer(videoUrl: widget.videos[index]),
                        );
                      },
                    ),
                    if (_currentIndex > 0)
                      Positioned(
                        left: 16,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                              onPressed: () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    if (_currentIndex < widget.videos.length - 1)
                      Positioned(
                        right: 16,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                              onPressed: () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    if (widget.videos.length > 1) ...[
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(widget.videos.length, (index) {
                            return Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentIndex == index ? Colors.white : Colors.white54,
                              ),
                            );
                          }),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_currentIndex + 1}/${widget.videos.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
