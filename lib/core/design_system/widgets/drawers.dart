import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';
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

class BuildPropertyDetailWidget extends StatelessWidget {
  final PropertyModel property;
  final bool showHeaderClose;

  const BuildPropertyDetailWidget({
    super.key,
    required this.property,
    this.showHeaderClose = true,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
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
    if (property.carpetArea != null && property.carpetArea! > 0) {
      specsItems.add(PropertyDetailItem('Carpet Area', '${property.carpetArea!.toStringAsFixed(0)} Sq. Ft.', Icons.aspect_ratio_rounded));
    }
    if (property.plotArea != null && property.plotArea! > 0) {
      specsItems.add(PropertyDetailItem('Plot Area', '${property.plotArea!.toStringAsFixed(0)} Sq. Yds.', Icons.terrain_outlined));
    }
    if (_isValidValue(property.furnishingTypeName)) {
      specsItems.add(PropertyDetailItem('Furnishing', property.furnishingTypeName!, Icons.chair_outlined));
    }
    if (_isValidValue(property.facingTypeName)) {
      specsItems.add(PropertyDetailItem('Facing', property.facingTypeName!, Icons.compass_calibration_outlined));
    }
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
    if (_isValidValue(property.blockWing)) {
      locationItems.add(PropertyDetailItem('Block/Wing', property.blockWing!, Icons.domain_outlined));
    }
    if (_isValidValue(property.flatNo)) {
      locationItems.add(PropertyDetailItem('Flat/Plot No.', property.flatNo!, Icons.tag_rounded));
    }
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
    if (_isValidValue(property.brokerName)) {
      contactsItems.add(PropertyDetailItem('Refer / Key Collect', property.brokerName!, Icons.vpn_key_outlined));
    }
    if (_isValidValue(property.brokerageTypeName)) {
      contactsItems.add(PropertyDetailItem('Brokerage Type', property.brokerageTypeName!, Icons.percent_rounded));
    }

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
            // Header (Full-width wrapper)
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
            
            // Details Body (Full screen width)
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(CRMSpacing.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      
                      // Responsive Dynamic details Cards
                      if (isMobile) ...[
                        _buildResponsiveDetailCard(context, 'Basic Details', basicItems),
                        const SizedBox(height: CRMSpacing.m),
                        _buildResponsiveDetailCard(context, 'Specifications & Floor Details', specsItems),
                        const SizedBox(height: CRMSpacing.m),
                        _buildResponsiveDetailCard(context, 'Location & Address', locationItems),
                        const SizedBox(height: CRMSpacing.m),
                        _buildResponsiveDetailCard(context, 'Contacts & Key Management', contactsItems),
                      ] else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  _buildResponsiveDetailCard(context, 'Basic Details', basicItems),
                                  const SizedBox(height: CRMSpacing.m),
                                  _buildResponsiveDetailCard(context, 'Location & Address', locationItems),
                                ],
                              ),
                            ),
                            const SizedBox(width: CRMSpacing.m),
                            Expanded(
                              child: Column(
                                children: [
                                  _buildResponsiveDetailCard(context, 'Specifications & Floor Details', specsItems),
                                  const SizedBox(height: CRMSpacing.m),
                                  _buildResponsiveDetailCard(context, 'Contacts & Key Management', contactsItems),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: CRMSpacing.m),
                      
                      // Description, CRM Remarks & Amenities (only rendered if filled)
                      _buildDescriptionCard(context, property),
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

  Widget _buildVideoSection(BuildContext context, List<String> videos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Property Video',
          style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context)),
        ),
        const SizedBox(height: CRMSpacing.s),
        ...videos.map((url) => Padding(
          padding: const EdgeInsets.only(bottom: CRMSpacing.m),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                child: CRMEmbeddedVideoPlayer(videoUrl: url),
              ),
            ),
          ),
        )).toList(),
      ],
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

Widget _buildAmenitiesSection(BuildContext context, String label, List<String> amenities) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: CRMTypography.captionBold.copyWith(color: CRMColors.textSecondaryOf(context)),
      ),
      const SizedBox(height: CRMSpacing.xs),
      Wrap(
        spacing: CRMSpacing.s,
        runSpacing: CRMSpacing.xs,
        children: amenities.map((am) {
          return Chip(
            label: Text(
              am,
              style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textOf(context)),
            ),
            backgroundColor: CRMColors.primaryOf(context).withOpacity(0.08),
            side: BorderSide(color: CRMColors.primaryOf(context).withOpacity(0.2)),
            padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.s, vertical: 0),
          );
        }).toList(),
      ),
    ],
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
