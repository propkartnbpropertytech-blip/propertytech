import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/tokens/app_shadows.dart';
import '../../../core/design_system/tokens/app_motion.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/data_table.dart';
import '../../../core/design_system/widgets/drawers.dart';
import '../../../core/design_system/widgets/form/crm_multi_select_dropdown.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/models/user_model.dart';
import '../bloc/properties_bloc.dart';
import '../models/property_model.dart';
import '../repository/properties_repository.dart';
import 'add_edit_property_screen.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/budget_formatter.dart';

class PropertiesScreen extends StatefulWidget {
  final String? openPropertyId;
  const PropertiesScreen({super.key, this.openPropertyId});

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _highlightedPropertyId;
  String _activeTab = 'All';
  String _activeListingTab = 'Rent'; // 'Rent' or 'Only Re-Sale'
  String _activeCategoryTab = 'Residential';
  bool _hasAutoOpenedAdd = false;
  bool _hasAutoOpenedProp = false;
  String? _selectedCategory;
  final List<String> _selectedConfigurations = [];
  final List<String> _selectedAreas = [];
  String? _selectedListingType;
  bool? _selectedVerification;
  PropertyMetadataModel? _cachedMetadata;
  String? _selectedPriceSortOrRange;
  double? _minPrice;
  double? _maxPrice;
  int _currentPage = 0;
  int _pageSize = 10;
  bool _myAddedOnly = false;
  String? _selectedStatusFilter;
  bool _isMobileFiltersExpanded = false;

  static const _pageSizeOptions = [10, 25, 50];

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadProperties() {
    context.read<PropertiesBloc>().add(
          LoadPropertiesEvent(
            activeTab: _activeTab,
          ),
        );
  }

  Future<void> _launchWhatsApp(PropertyModel property) async {
    final authState = context.read<AuthBloc>().state;
    String userName = 'User';
    if (authState is Authenticated) {
      userName = authState.user.fullName;
    }

    final text = 'Hello,\n'
        'I am $userName from NB Prop Tech.\n'
        'Is your property still available?\n'
        'Thank you.';
    final url =
        'https://wa.me/${property.ownerMobile}?text=${Uri.encodeComponent(text)}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    }
  }

  bool _hasEditAccess(PropertyModel p, UserModel? currentUser) {
    if (currentUser == null) return false;
    if (currentUser.role == 'Super Admin') return true;
    if (p.createdBy == currentUser.id) return true;
    if (currentUser.role == 'Telecaller' && p.adminId != null && p.adminId == currentUser.adminId) return true;
    if (currentUser.role == 'Admin' && p.adminId == currentUser.id) return true;
    return false;
  }

  Widget _buildMobilePropertyCard(PropertyModel p, UserModel? currentUser,
      Set<String> bookmarkedIds, PropertyMetadataModel? metadata) {
    final isMine = _hasEditAccess(p, currentUser);
    final isHighlighted = p.id == _highlightedPropertyId;

    return AnimatedContainer(
      duration: CRMMotion.medium,
      curve: CRMMotion.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CRMBorderRadius.card + 2),
        border: Border.all(
          color: isHighlighted ? CRMColors.primaryOf(context) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: isHighlighted ? CRMShadows.primaryGlow : null,
      ),
      padding: const EdgeInsets.all(2),
      child: CRMCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(CRMBorderRadius.card),
          onTap: () => _openPropertyDetails(context, p),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(CRMBorderRadius.card),
                    ),
                    child: p.images.isNotEmpty
                        ? _MobilePropertyImageCarousel(
                            images: p.images,
                            onTap: () => _openPropertyDetails(context, p),
                          )
                        : GestureDetector(
                            onTap: () => _openPropertyDetails(context, p),
                            child: Container(
                              height: 160,
                              width: double.infinity,
                              color: CRMColors.skeletonBase,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_not_supported_outlined,
                                      size: 40,
                                      color: CRMColors.textMutedOf(context),
                                    ),
                                    const SizedBox(height: CRMSpacing.xs),
                                    Text(
                                      'No Image Available',
                                      style: CRMTypography.caption.copyWith(
                                        color: CRMColors.textMutedOf(context),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(CRMBorderRadius.xs),
                          ),
                          child: Text(
                            p.propertyCode,
                            style: CRMTypography.captionBold.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B8B7B),
                            borderRadius: BorderRadius.circular(CRMBorderRadius.xs),
                          ),
                          child: Text(
                            p.listingTypeName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (p.statusDisplayName.isNotEmpty)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: p.isStatusAvailable ? CRMColors.success : CRMColors.warning,
                          borderRadius: BorderRadius.circular(CRMBorderRadius.xs),
                        ),
                        child: Text(
                          p.statusDisplayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(CRMSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            p.title,
                            style: CRMTypography.cardTitle.copyWith(
                              color: CRMColors.textOf(context),
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          CRMCurrencyFormatter.formatShort(p.price),
                          style: CRMTypography.cardTitle.copyWith(
                            color: CRMColors.primaryOf(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: CRMSpacing.xs),
                    Row(
                      children: [
                        Icon(_getPropertyBhkOrAreaIcon(p),
                            size: 14, color: CRMColors.textSecondaryOf(context)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${_getPropertyBhkOrAreaValue(p)} in ${p.areaName}, ${p.cityName}',
                            style: CRMTypography.caption.copyWith(
                              color: CRMColors.textSecondaryOf(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    const SizedBox(height: CRMSpacing.s),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded,
                            size: 14, color: CRMColors.textSecondaryOf(context)),
                        const SizedBox(width: 4),
                        Text(
                          'Owner: ',
                          style: CRMTypography.caption
                              .copyWith(color: CRMColors.textSecondaryOf(context)),
                        ),
                        Expanded(
                          child: Text(
                            '${p.ownerName} (${p.ownerMobile})',
                            style: CRMTypography.captionBold.copyWith(
                              color: CRMColors.textOf(context),
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: CRMSpacing.xs),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 14, color: CRMColors.textSecondaryOf(context)),
                        const SizedBox(width: 4),
                        Text(
                          'Created: ${DateFormat('dd-MM-yyyy').format(p.createdAt)}',
                          style: CRMTypography.caption
                              .copyWith(color: CRMColors.textSecondaryOf(context)),
                        ),
                      ],
                    ),
                    const SizedBox(height: CRMSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          p.availableFromFormatted != null 
                              ? Icons.check_box_outlined 
                              : Icons.event_busy_rounded,
                          size: 14,
                          color: p.availableFromFormatted != null 
                              ? CRMColors.success 
                              : CRMColors.textSecondaryOf(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          p.availableFromFormatted != null 
                              ? 'Available: ${p.availableFromFormatted}' 
                              : 'Not Available',
                          style: CRMTypography.caption.copyWith(
                            color: p.availableFromFormatted != null 
                                ? CRMColors.success 
                                : CRMColors.textSecondaryOf(context),
                            fontWeight: p.availableFromFormatted != null 
                                ? FontWeight.bold 
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isMine && _activeTab != 'My Deleted') ...[
                          IconButton(
                            icon: Icon(Icons.edit_outlined,
                                color: const Color(0xFF6B8B7B), size: 18),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF6B8B7B).withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () {
                              if (metadata != null) {
                                _showAddEditPropertyDialog(context, metadata, p);
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded,
                                color: CRMColors.danger, size: 18),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            style: IconButton.styleFrom(
                              backgroundColor: CRMColors.danger.withOpacity(0.08),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () {
                              context.read<PropertiesBloc>().add(
                                    DeletePropertyEvent(p.id, activeTab: _activeTab),
                                  );
                            },
                          ),
                          const SizedBox(width: 8),
                        ] else if (isMine && _activeTab == 'My Deleted') ...[
                          IconButton(
                            icon: Icon(Icons.restore_rounded,
                                color: CRMColors.success, size: 18),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            style: IconButton.styleFrom(
                              backgroundColor: CRMColors.success.withOpacity(0.08),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () {
                              context.read<PropertiesBloc>().add(
                                    RestorePropertyEvent(p.id, activeTab: _activeTab),
                                  );
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (p.ownerMobile.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline_rounded,
                                color: Colors.green, size: 18),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.green.withOpacity(0.08),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () => _launchWhatsApp(p),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String? currentUserId;
    UserModel? currentUser;
    if (authState is Authenticated) {
      currentUserId = authState.user.id;
      currentUser = authState.user;
    }
    final bool isUserAdminOrSuperAdmin = currentUser != null &&
        (currentUser.role?.toLowerCase() == 'admin' || currentUser.role?.toLowerCase() == 'super admin' || currentUser.role?.toLowerCase() == 'telecaller');
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocConsumer<PropertiesBloc, PropertiesState>(
        listener: (context, state) {
          if (state is PropertiesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message),
                  backgroundColor: CRMColors.danger),
            );
          } else if (state is PropertyCreatedState) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _openPropertyDetails(context, state.property);
              if (_scrollController.hasClients) {
                _scrollController.animateTo(0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut);
              }
              setState(() {
                _highlightedPropertyId = state.property.id;
              });
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  setState(() {
                    _highlightedPropertyId = null;
                  });
                }
              });
            });
          }
        },
        builder: (context, state) {
          final isLoading =
              state is PropertiesLoading || state is PropertiesInitial;
          List<PropertyModel> properties = [];
          PropertyMetadataModel? metadata;
          Set<String> bookmarkedIds = {};

          if (state is PropertiesLoaded) {
            properties = state.properties.where((p) {
              final ltName = p.listingTypeName.toLowerCase();
              final matchesListing = _activeListingTab == 'Rent'
                  ? ltName.contains('rent')
                  : (ltName.contains('sale') ||
                      ltName.contains('resale') ||
                      !ltName.contains('rent'));

              final matchesCategory = _selectedCategory == null ||
                  p.categoryId == _selectedCategory;

              final matchesCategoryTab = _matchesActiveCategory(p);

              final matchesConfig = _selectedConfigurations.isEmpty ||
                  _selectedConfigurations.contains(p.configurationId);

              final matchesArea = _selectedAreas.isEmpty ||
                  _selectedAreas.contains(p.areaId);

              bool matchesPrice = true;
              if (_selectedPriceSortOrRange == 'custom') {
                if (_minPrice != null && p.price < _minPrice!) {
                  matchesPrice = false;
                }
                if (_maxPrice != null && p.price > _maxPrice!) {
                  matchesPrice = false;
                }
              }

              bool matchesSearch = true;
              if (_searchController.text.trim().isNotEmpty) {
                final query = _searchController.text.trim().toLowerCase();
                matchesSearch = p.propertyCode.toLowerCase().contains(query) ||
                    p.title.toLowerCase().contains(query) ||
                    (p.description?.toLowerCase().contains(query) ?? false) ||
                    p.ownerName.toLowerCase().contains(query) ||
                    p.ownerMobile.toLowerCase().contains(query) ||
                    p.areaName.toLowerCase().contains(query) ||
                    p.cityName.toLowerCase().contains(query) ||
                    p.categoryName.toLowerCase().contains(query) ||
                    (p.configurationName?.toLowerCase().contains(query) ?? false) ||
                    p.propertyTypeName.toLowerCase().contains(query) ||
                    (isUserAdminOrSuperAdmin &&
                     (currentUser?.role == 'Super Admin' ||
                      (currentUser?.role == 'Admin' && (p.createdBy == currentUser?.id || p.adminId == currentUser?.id)) ||
                      (currentUser?.role == 'Telecaller' && (p.createdBy == currentUser?.id || p.adminId == currentUser?.adminId))) &&
                     p.createdByName.toLowerCase().contains(query));
              }

              final matchesMyAdded = !_myAddedOnly || (p.createdBy == currentUserId);
              final matchesStatus = _selectedStatusFilter == null ||
                  (p.propertyStatusName ?? '').toLowerCase() == _selectedStatusFilter!.toLowerCase();

              final cat = p.categoryName.toLowerCase();
              bool matchesTabCategory = false;
              if (_activeCategoryTab == 'Residential') {
                matchesTabCategory = cat.contains('resident') ||
                    cat.contains('apartment') ||
                    cat.contains('flat') ||
                    cat.contains('villa') ||
                    cat.contains('house') ||
                    cat.contains('bhk') ||
                    (!cat.contains('commercial') &&
                        !cat.contains('industrial') &&
                        !cat.contains('land') &&
                        !cat.contains('plot'));
              } else if (_activeCategoryTab == 'Commercial') {
                matchesTabCategory = cat.contains('commercial') ||
                    cat.contains('office') ||
                    cat.contains('shop') ||
                    cat.contains('showroom') ||
                    cat.contains('retail');
              } else if (_activeCategoryTab == 'Industrial') {
                matchesTabCategory = cat.contains('industrial') ||
                    cat.contains('factory') ||
                    cat.contains('warehouse') ||
                    cat.contains('shed');
              } else if (_activeCategoryTab == 'Land & Plot') {
                matchesTabCategory = cat.contains('land') || cat.contains('plot');
              }

              return matchesListing &&
                  matchesCategory &&
                  matchesTabCategory &&
                  matchesConfig &&
                  matchesArea &&
                  matchesSearch &&
                  matchesPrice &&
                  matchesMyAdded &&
                  matchesStatus &&
                  matchesCategoryTab;
            }).toList();

            // Default sorting: Newest first (latest property appears first)
            properties.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            // Price Sorting (Low to High / High to Low)
            if (_selectedPriceSortOrRange == 'l2h') {
              properties.sort((a, b) => a.price.compareTo(b.price));
            } else if (_selectedPriceSortOrRange == 'h2l') {
              properties.sort((a, b) => b.price.compareTo(a.price));
            }

            metadata = state.metadata;
            _cachedMetadata = state.metadata;
            bookmarkedIds = state.bookmarkedIds;

            final action =
                GoRouterState.of(context).uri.queryParameters['action'];
            if (action == 'add' &&
                !_hasAutoOpenedAdd &&
                state.metadata != null) {
              _hasAutoOpenedAdd = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showAddEditPropertyDialog(context, state.metadata!);
              });
            }

            final openId = widget.openPropertyId ??
                GoRouterState.of(context).uri.queryParameters['openId'];
            if (openId != null && !_hasAutoOpenedProp) {
              _hasAutoOpenedProp = true;
              PropertyModel? matched;
              for (final item in properties) {
                if (item.id == openId) {
                  matched = item;
                  break;
                }
              }
              if (matched != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _openPropertyDetails(context, matched!);
                });
              } else {
                PropertiesRepository().getPropertyById(openId).then((p) {
                  if (p != null && mounted) {
                    _openPropertyDetails(context, p);
                  }
                });
              }
            }
          }

          final totalPages =
              properties.isEmpty ? 1 : (properties.length / _pageSize).ceil();
          final safePage = _currentPage.clamp(0, totalPages - 1);
          final pageStart = safePage * _pageSize;
          final pageEnd = (pageStart + _pageSize).clamp(0, properties.length);
          final pagedProperties = properties.isEmpty
              ? properties
              : properties.sublist(pageStart, pageEnd);

          return SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: CRMSpacing.m,
              vertical: CRMSpacing.l,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Responsive Page Header
                _buildPageHeader(_cachedMetadata),
                const SizedBox(height: CRMSpacing.m),

                // Rent vs Re-Sale Toggle Tabs
                Wrap(
                  spacing: CRMSpacing.s,
                  runSpacing: CRMSpacing.s,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      height: 44,
                      width: screenWidth < 600 ? 200 : 240,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: CRMColors.backgroundOf(context),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.6), width: 1.0),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                              child: _buildPropertyListingTabButton('Rent')),
                          const SizedBox(width: 4),
                          Expanded(
                              child: _buildPropertyListingTabButton('Re-Sale')),
                        ],
                      ),
                    ),
                    _buildMyAddedToggle(),
                  ],
                ),
                const SizedBox(height: CRMSpacing.l),

                // 2. Statistics Row (Overflow Fixed Layout)
                _buildStatisticsRow(state is PropertiesLoaded ? state.properties : const []),
                const SizedBox(height: CRMSpacing.l),

                // 3. Search & 4. Advanced Filters
                _buildSearchAndFilters(_cachedMetadata),
                const SizedBox(height: CRMSpacing.l),

                // 5. Action Toolbar (Responsive choice chips)
                _buildActionToolbar(),
                const SizedBox(height: CRMSpacing.m),

                // 6. Property Table (Desktop) / Property Cards (Mobile) & 7. Pagination
                if (screenWidth < 768) ...[
                  if (isLoading)
                    const Center(
                        child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator()))
                  else if (pagedProperties.isEmpty)
                    CRMCard(
                      child: Padding(
                        padding: const EdgeInsets.all(CRMSpacing.xl),
                        child: Column(
                          children: [
                            Text('No Properties Found',
                                style: CRMTypography.sectionTitle
                                    .copyWith(color: CRMColors.textOf(context))),
                            const SizedBox(height: CRMSpacing.s),
                            Text('No records match your active search terms.',
                                style: CRMTypography.body
                                    .copyWith(color: CRMColors.textSecondaryOf(context))),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      children: pagedProperties.map((p) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: CRMSpacing.m),
                          child: _buildMobilePropertyCard(
                              p, currentUser, bookmarkedIds, metadata),
                        );
                      }).toList(),
                    ),
                ] else ...[
                  CRMDataTable(
                    isLoading: isLoading,
                    emptyTitle: 'No Properties Found',
                    emptyDescription:
                        'No records match your active search terms.',
                    showCheckboxColumn: false,
                    dataRowMinHeight: 72.0,
                    dataRowMaxHeight: 80.0,
                    columns: [
                      const DataColumn(label: Text('Code')),
                      if (isUserAdminOrSuperAdmin)
                        const DataColumn(label: Text('Added By')),
                      const DataColumn(label: Text('Property Name')),
                      const DataColumn(label: Text('Owner')),
                      const DataColumn(label: Text('Area')),
                      DataColumn(label: Text(_getBhkColumnHeader(metadata))),
                      const DataColumn(label: Text('Price')),
                      const DataColumn(label: Text('Date')),
                      const DataColumn(label: Text('Status')),
                      const DataColumn(label: Text('Photos')),
                      const DataColumn(label: Text('Actions')),
                    ],
                    rows: pagedProperties.map((p) {
                      final isMine = _hasEditAccess(p, currentUser);
                      final isBookmarked = bookmarkedIds.contains(p.id);
                      return DataRow(
                        color:
                            WidgetStateProperty.resolveWith<Color?>((states) {
                          if (p.id == _highlightedPropertyId) {
                            return CRMColors.primaryOf(context).withOpacity(0.08);
                          }
                          return null;
                        }),
                        onSelectChanged: (_) =>
                            _openPropertyDetails(context, p),
                        cells: [
                          DataCell(Text(p.propertyCode,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold))),
                          if (isUserAdminOrSuperAdmin)
                            DataCell(Text(
                              (currentUser?.role == 'Super Admin' ||
                                      (currentUser?.role == 'Admin' && (p.createdBy == currentUser?.id || p.adminId == currentUser?.id)) ||
                                      (currentUser?.role == 'Telecaller' && (p.createdBy == currentUser?.id || p.adminId == currentUser?.adminId)))
                                  ? p.createdByName
                                  : '-',
                            )),
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(p.title ?? 'No Title', maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      p.availableFromFormatted != null 
                                          ? Icons.event_available_rounded 
                                          : Icons.event_busy_rounded,
                                      size: 12,
                                      color: p.availableFromFormatted != null 
                                          ? CRMColors.success 
                                          : CRMColors.textSecondaryOf(context),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      p.availableFromFormatted != null 
                                          ? 'Available: ${p.availableFromFormatted}' 
                                          : 'Not Available',
                                      style: TextStyle(
                                        color: p.availableFromFormatted != null 
                                            ? CRMColors.success 
                                            : CRMColors.textSecondaryOf(context),
                                        fontSize: 10.5,
                                        fontWeight: p.availableFromFormatted != null 
                                            ? FontWeight.bold 
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(p.ownerName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  Text(p.ownerMobile,
                                      style: TextStyle(
                                          color: CRMColors.textMutedOf(context),
                                          fontSize: 11)),
                                ],
                              ),
                            ),
                          ),
                          DataCell(Text(p.areaName)),
                          DataCell(Text(_getPropertyBhkOrAreaValue(p))),
                          DataCell(Text(CRMCurrencyFormatter.formatShort(p.price),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600))),
                          DataCell(Text(
                              DateFormat('dd-MM-yyyy').format(p.createdAt))),
                          DataCell(
                            PopupMenuButton<String>(
                              tooltip: 'Change Status',
                              onSelected: (String statusName) async {
                                if (statusName == 'To Be Available') {
                                  final DateTime? pickedDate =
                                      await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now()
                                        .add(const Duration(days: 1)),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now()
                                        .add(const Duration(days: 365 * 5)),
                                    helpText: 'Select Available Date',
                                  );
                                  if (pickedDate == null) return;

                                  LookupItem? targetLookup;
                                  if (metadata != null) {
                                    for (final s in metadata.statuses) {
                                      if (s.name
                                          .toLowerCase()
                                          .contains('to be available')) {
                                        targetLookup = s;
                                        break;
                                      }
                                    }
                                  }
                                  final statusId = targetLookup?.id ??
                                      '05a73434-e99b-425b-99b2-1825d529ac35';
                                  if (context.mounted) {
                                    context.read<PropertiesBloc>().add(
                                          UpdatePropertyEvent(
                                            p.id,
                                            {
                                              'property_status_id': statusId,
                                              'possession_date': pickedDate
                                                  .toIso8601String()
                                                  .substring(0, 10),
                                            },
                                            activeTab: _activeTab,
                                          ),
                                        );
                                  }
                                  return;
                                }

                                LookupItem? targetLookup;
                                if (metadata != null) {
                                  for (final s in metadata.statuses) {
                                    if (s.name
                                            .toLowerCase()
                                            .replaceAll(' ', '') ==
                                        statusName
                                            .toLowerCase()
                                            .replaceAll(' ', '')) {
                                      targetLookup = s;
                                      break;
                                    }
                                  }
                                }
                                final statusId = targetLookup?.id ?? statusName;
                                context.read<PropertiesBloc>().add(
                                      UpdatePropertyEvent(
                                        p.id,
                                        {'property_status_id': statusId},
                                        activeTab: _activeTab,
                                      ),
                                    );
                              },
                              itemBuilder: (BuildContext context) {
                                final isRent = p.listingTypeName
                                    .toLowerCase()
                                    .contains('rent');
                                return <PopupMenuEntry<String>>[
                                  const PopupMenuItem<String>(
                                    value: 'Available',
                                    child: Text('Available'),
                                  ),
                                  if (isRent) ...[
                                    const PopupMenuItem<String>(
                                      value: 'Rented Out',
                                      child: Text('Rented Out'),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'To Be Available',
                                      child: Text('To Be Available'),
                                    ),
                                  ] else ...[
                                    const PopupMenuItem<String>(
                                      value: 'Sold Out',
                                      child: Text('Sold Out'),
                                    ),
                                  ],
                                ];
                              },
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: p.isStatusAvailable
                                        ? CRMColors.success
                                            .withValues(alpha: 0.12)
                                        : CRMColors.warning
                                            .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(
                                        CRMBorderRadius.xs),
                                    border: Border.all(
                                      color: (p.isStatusAvailable
                                              ? CRMColors.success
                                              : CRMColors.warning)
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          p.statusDisplayName,
                                          style: TextStyle(
                                            color: p.isStatusAvailable
                                                ? CRMColors.success
                                                : CRMColors.warning,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Icon(
                                          Icons.arrow_drop_down_rounded,
                                          size: 16,
                                          color: p.isStatusAvailable
                                              ? CRMColors.success
                                              : CRMColors.warning,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Builder(
                              builder: (context) {
                                final hasImages = p.images.isNotEmpty;
                                return InkWell(
                                  onTap: hasImages
                                      ? () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => CRMImageZoomViewer(
                                              images: p.images,
                                              initialIndex: 0,
                                            ),
                                          );
                                        }
                                      : null,
                                  borderRadius:
                                      BorderRadius.circular(CRMBorderRadius.xs),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: CRMColors.backgroundOf(context),
                                      borderRadius: BorderRadius.circular(
                                          CRMBorderRadius.xs),
                                      border: Border.all(
                                        color: hasImages
                                            ? CRMColors.primaryOf(context).withOpacity(0.3)
                                            : CRMColors.borderOf(context).withOpacity(0.6),
                                        width: 0.5,
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: hasImages
                                        ? Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              _buildPropertyThumbnail(
                                                  p.images.first),
                                              if (p.images.length > 1)
                                                Positioned(
                                                  right: 0,
                                                  bottom: 0,
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 3,
                                                        vertical: 1),
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Color(0xB3000000),
                                                      borderRadius:
                                                          BorderRadius.only(
                                                              topLeft: Radius
                                                                  .circular(4)),
                                                    ),
                                                    child: Text(
                                                      '+${p.images.length - 1}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          )
                                        : Icon(
                                            Icons.image_not_supported_outlined,
                                            size: 18,
                                            color:
                                                CRMColors.textMutedOf(context),
                                          ),
                                  ),
                                );
                              },
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isMine) ...[
                                  IconButton(
                                    icon: Icon(Icons.edit_outlined,
                                        color: CRMColors.primaryOf(context), size: 18),
                                    onPressed: () {
                                      if (metadata != null) {
                                        _showAddEditPropertyDialog(
                                            context, metadata!, p);
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline_rounded,
                                        color: CRMColors.danger, size: 18),
                                    onPressed: () {
                                      context.read<PropertiesBloc>().add(
                                            DeletePropertyEvent(p.id,
                                                activeTab: _activeTab),
                                          );
                                    },
                                  ),
                                ],
                                IconButton(
                                  icon: Icon(Icons.chat_bubble_outline_rounded,
                                      color: CRMColors.success, size: 18),
                                  onPressed: () => _launchWhatsApp(p),
                                  tooltip: 'Contact on WhatsApp',
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
                if (properties.isNotEmpty) ...[
                  const SizedBox(height: CRMSpacing.m),
                  _buildPagination(properties.length, totalPages, safePage),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageHeader(PropertyMetadataModel? metadata) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    Widget leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Workspace',
            style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context))),
        Text(
          'Available Inventory',
          style: CRMTypography.pageTitle.copyWith(
            color: CRMColors.textOf(context),
            fontSize: isMobile ? 20 : 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );

    Widget rightColumn = CRMButton(
      label: 'Add Property',
      prefixIcon: Icons.add_circle_outline_rounded,
      onPressed: () {
        if (metadata == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Metadata lookups loading, please try again.')),
          );
          return;
        }
        _showAddEditPropertyDialog(context, metadata!);
      },
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          leftColumn,
          const SizedBox(height: CRMSpacing.m),
          rightColumn,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: leftColumn),
        const SizedBox(width: CRMSpacing.m),
        rightColumn,
      ],
    );
  }

  Widget _buildStatisticsRow(List<PropertyModel> properties) {
    final filteredByMyAdded = properties.where((p) {
      if (!_myAddedOnly) return true;
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        return p.createdBy == authState.user.id;
      }
      return false;
    }).toList();

    final filteredByStatus = filteredByMyAdded.where((p) {
      return _selectedStatusFilter == null ||
          (p.propertyStatusName ?? '').toLowerCase() == _selectedStatusFilter!.toLowerCase();
    }).toList();

    final filteredByListingTab = filteredByStatus.where((p) {
      final ltName = p.listingTypeName.toLowerCase();
      if (_activeListingTab == 'Rent') {
        return ltName.contains('rent');
      } else {
        return ltName.contains('sale') ||
            ltName.contains('resale') ||
            !ltName.contains('rent');
      }
    }).toList();

    final filteredByListingAndCategory = filteredByListingTab.where(_matchesActiveCategory).toList();
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    final double cardWidth = isMobile
        ? (screenWidth - (CRMSpacing.m * 2) - CRMSpacing.m).clamp(0.0, double.infinity) / 2
        : 180.0;
    final double chartCardWidth = isMobile
        ? (screenWidth - (CRMSpacing.m * 2))
        : 260.0;
    final double cardHeight = isMobile ? 105.0 : 120.0;

    final List<Widget> widgets = [];
    Widget? mobileKpiCard;
    String mobileChartTitle = '';
    List<ChartSector> mobileSectors = [];

    if (_activeCategoryTab == 'Residential') {
      final statusCount = filteredByListingAndCategory.length;
      final kpi = CRMKPICard(
        title: '${_selectedStatusFilter ?? "All Status"} listings',
        value: '$statusCount',
        icon: Icons.bolt_rounded,
        iconColor: CRMColors.primaryOf(context),
      );
      widgets.add(SizedBox(
        width: cardWidth,
        height: cardHeight,
        child: kpi,
      ));
      mobileKpiCard = kpi;
      mobileChartTitle = 'BHK Distribution';

      final List<ChartSector> bhkSectors = [];
      final colors = [
        CRMColors.info,
        CRMColors.success,
        CRMColors.warning,
        CRMColors.danger,
        CRMColors.primaryOf(context),
      ];
      for (int bhk = 1; bhk <= 5; bhk++) {
        final count = filteredByListingAndCategory
            .where((p) =>
                ((p.configurationName != null &&
                        p.configurationName!.toLowerCase().startsWith('$bhk bhk')) ||
                    (p.configurationName == null && p.bedrooms == bhk)))
            .length;
        if (count > 0) {
          bhkSectors.add(ChartSector(
            label: '$bhk BHK',
            value: count.toDouble(),
            color: colors[(bhk - 1) % colors.length],
          ));
        }
      }
      widgets.add(SizedBox(
        width: chartCardWidth,
        height: cardHeight,
        child: CRMChartCard(
          title: 'BHK Distribution',
          sectors: bhkSectors,
        ),
      ));
      mobileSectors = bhkSectors;
    } else if (_activeCategoryTab == 'Commercial') {
      final statusCount = filteredByListingAndCategory.length;
      final kpi = CRMKPICard(
        title: 'Commercial (${_selectedStatusFilter ?? "All Status"})',
        value: '$statusCount',
        icon: Icons.business_center_outlined,
        iconColor: CRMColors.primaryOf(context),
      );
      widgets.add(SizedBox(
        width: cardWidth,
        height: cardHeight,
        child: kpi,
      ));
      mobileKpiCard = kpi;
      mobileChartTitle = 'Property Types';

      final Map<String, int> typeCounts = {};
      for (final p in filteredByListingAndCategory) {
        final typeName = p.propertyTypeName;
        if (typeName.isNotEmpty && typeName != 'N/A') {
          typeCounts[typeName] = (typeCounts[typeName] ?? 0) + 1;
        }
      }
      final List<ChartSector> typeSectors = [];
      final typeColors = [
        CRMColors.primaryOf(context),
        CRMColors.info,
        CRMColors.success,
        CRMColors.warning,
        CRMColors.danger,
      ];
      int index = 0;
      typeCounts.forEach((name, count) {
        if (count > 0) {
          typeSectors.add(ChartSector(
            label: name,
            value: count.toDouble(),
            color: typeColors[index % typeColors.length],
          ));
          index++;
        }
      });
      widgets.add(SizedBox(
        width: chartCardWidth,
        height: cardHeight,
        child: CRMChartCard(
          title: 'Property Types',
          sectors: typeSectors,
        ),
      ));
      mobileSectors = typeSectors;
    } else if (_activeCategoryTab == 'Industrial') {
      final statusCount = filteredByListingAndCategory.length;
      final kpi = CRMKPICard(
        title: 'Industrial (${_selectedStatusFilter ?? "All Status"})',
        value: '$statusCount',
        icon: Icons.factory_outlined,
        iconColor: CRMColors.primaryOf(context),
      );
      widgets.add(SizedBox(
        width: cardWidth,
        height: cardHeight,
        child: kpi,
      ));
      mobileKpiCard = kpi;
      mobileChartTitle = 'Industrial Subcategories';

      final warehouses = filteredByListingAndCategory.where((p) => p.categoryName.toLowerCase().contains('warehouse') || p.title.toLowerCase().contains('warehouse') || (p.description != null && p.description!.toLowerCase().contains('warehouse'))).toList();
      final factories = filteredByListingAndCategory.where((p) => p.categoryName.toLowerCase().contains('factory') || p.categoryName.toLowerCase().contains('industrial') || p.title.toLowerCase().contains('factory') || (p.description != null && p.description!.toLowerCase().contains('factory'))).toList();
      final otherCount = statusCount - (warehouses.length + factories.length);

      final indSectors = <ChartSector>[];
      if (warehouses.isNotEmpty) {
        indSectors.add(ChartSector(label: 'Warehouses', value: warehouses.length.toDouble(), color: CRMColors.warning));
      }
      if (factories.isNotEmpty) {
        indSectors.add(ChartSector(label: 'Factories', value: factories.length.toDouble(), color: CRMColors.danger));
      }
      if (otherCount > 0) {
        indSectors.add(ChartSector(label: 'Sheds & Yards', value: otherCount.toDouble(), color: CRMColors.info));
      }

      widgets.add(SizedBox(
        width: chartCardWidth,
        height: cardHeight,
        child: CRMChartCard(
          title: 'Industrial Subcategories',
          sectors: indSectors,
        ),
      ));
      mobileSectors = indSectors;
    } else if (_activeCategoryTab == 'Land & Plot') {
      final statusCount = filteredByListingAndCategory.length;
      final kpi = CRMKPICard(
        title: 'Land & Plots (${_selectedStatusFilter ?? "All Status"})',
        value: '$statusCount',
        icon: Icons.landscape_outlined,
        iconColor: CRMColors.primaryOf(context),
      );
      widgets.add(SizedBox(
        width: cardWidth,
        height: cardHeight,
        child: kpi,
      ));
      mobileKpiCard = kpi;
      mobileChartTitle = 'Zoning & Land Usage';

      final resPlots = filteredByListingAndCategory.where((p) => p.title.toLowerCase().contains('resident') || (p.description != null && p.description!.toLowerCase().contains('resident'))).toList();
      final comLand = filteredByListingAndCategory.where((p) => p.title.toLowerCase().contains('commercial') || (p.description != null && p.description!.toLowerCase().contains('commercial'))).toList();
      final otherLand = statusCount - (resPlots.length + comLand.length);

      final landSectors = <ChartSector>[];
      if (resPlots.isNotEmpty) {
        landSectors.add(ChartSector(label: 'Residential Plots', value: resPlots.length.toDouble(), color: CRMColors.success));
      }
      if (comLand.isNotEmpty) {
        landSectors.add(ChartSector(label: 'Commercial Land', value: comLand.length.toDouble(), color: CRMColors.info));
      }
      if (otherLand > 0) {
        landSectors.add(ChartSector(label: 'Other Land', value: otherLand.toDouble(), color: CRMColors.warning));
      }

      widgets.add(SizedBox(
        width: chartCardWidth,
        height: cardHeight,
        child: CRMChartCard(
          title: 'Zoning & Land Usage',
          sectors: landSectors,
        ),
      ));
      mobileSectors = landSectors;
    }

    final categories = ['Residential', 'Commercial', 'Industrial', 'Land & Plot'];
    final categorySelector = Container(
      margin: const EdgeInsets.only(bottom: CRMSpacing.m),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: categories.map((cat) {
            final isSelected = _activeCategoryTab == cat;
            return Padding(
              padding: const EdgeInsets.only(right: CRMSpacing.s),
              child: ChoiceChip(
                label: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected ? Colors.white : CRMColors.textSecondaryOf(context),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                selected: isSelected,
                selectedColor: const Color(0xFF64826F),
                backgroundColor: CRMColors.backgroundOf(context).withOpacity(0.5),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _activeCategoryTab = cat;
                      _currentPage = 0;
                    });
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );

    if (isMobile && mobileKpiCard != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: CRMSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            categorySelector,
            _MobileStatisticsSection(
              kpiCard: mobileKpiCard,
              chartTitle: mobileChartTitle,
              sectors: mobileSectors,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CRMSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          categorySelector,
          Wrap(
            spacing: CRMSpacing.m,
            runSpacing: CRMSpacing.m,
            children: widgets,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFiltersCard(PropertyMetadataModel? metadata) {
    final categories = metadata != null ? metadata.categories : <LookupItem>[];
    final areas = metadata != null ? metadata.areas.cast<LookupItem>().toList() : <LookupItem>[];
    final listingTypes =
        metadata != null ? metadata.listingTypes : <LookupItem>[];

    return CRMCard(
      title: 'Search Filter',
      child: Padding(
        padding: const EdgeInsets.only(top: CRMSpacing.s),
        child: Column(
          children: [
            // Search Input Row
            LayoutBuilder(
              builder: (context, searchConstraints) {
                final isCompactSearch = searchConstraints.maxWidth < 500;

                final searchField = TextField(
                  controller: _searchController,
                  style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
                  decoration: InputDecoration(
                    hintText: 'Search property code, title, owner mobile...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: CRMColors.backgroundOf(context),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                        borderSide: BorderSide.none),
                  ),
                  onChanged: (_) => _loadProperties(),
                );

                final searchButton = CRMButton(
                  label: 'Search',
                  onPressed: _loadProperties,
                );

                if (isCompactSearch) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      searchField,
                      const SizedBox(height: CRMSpacing.s),
                      searchButton,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: searchField),
                    const SizedBox(width: CRMSpacing.s),
                    searchButton,
                  ],
                );
              },
            ),
            const SizedBox(height: CRMSpacing.m),

            LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                double targetWidth;

                if (width >= 900) {
                  targetWidth = (width - (CRMSpacing.m * 4)) / 5;
                } else if (width >= 600) {
                  targetWidth = (width - CRMSpacing.m) / 2;
                } else {
                  targetWidth = width;
                }

                final List<LookupItem> configurations = [];
                if (metadata != null) {
                  if (_selectedCategory == null) {
                    configurations.addAll(metadata.configurations);
                  } else {
                    final cat = categories.firstWhere(
                      (cat) => cat.id == _selectedCategory,
                      orElse: () => LookupItem(id: '', name: ''),
                    );
                    final catName = cat.name.toLowerCase();

                    if (catName.contains('commercial')) {
                      final matches = <LookupItem>[];
                      matches.addAll(metadata.configurations.where((c) {
                        final name = c.name.toLowerCase();
                        return name.contains('office') || name.contains('shop') || name.contains('showroom');
                      }));
                      matches.addAll(metadata.types.where((t) {
                        final name = t.name.toLowerCase();
                        return name.contains('office') || name.contains('shop') || name.contains('showroom');
                      }));
                      for (final m in matches) {
                        if (!configurations.any((c) => c.name.toLowerCase() == m.name.toLowerCase())) {
                          configurations.add(m);
                        }
                      }
                    } else if (catName.contains('land') || catName.contains('plot')) {
                      final matches = <LookupItem>[];
                      matches.addAll(metadata.configurations.where((c) {
                        return c.name.toLowerCase().contains('plot');
                      }));
                      matches.addAll(metadata.types.where((t) {
                        return t.name.toLowerCase().contains('plot');
                      }));
                      for (final m in matches) {
                        if (!configurations.any((c) => c.name.toLowerCase() == m.name.toLowerCase())) {
                          configurations.add(m);
                        }
                      }
                    } else if (catName.contains('industrial')) {
                      final matches = <LookupItem>[];
                      matches.addAll(metadata.configurations.where((c) {
                        final name = c.name.toLowerCase();
                        return name.contains('warehouse') || name.contains('shed') || name.contains('industrial');
                      }));
                      matches.addAll(metadata.types.where((t) {
                        final name = t.name.toLowerCase();
                        return name.contains('warehouse') || name.contains('shed') || name.contains('industrial');
                      }));
                      for (final m in matches) {
                        if (!configurations.any((c) => c.name.toLowerCase() == m.name.toLowerCase())) {
                          configurations.add(m);
                        }
                      }
                    } else if (catName.contains('residential')) {
                      final matches = metadata.configurations.where((c) {
                        final name = c.name.toLowerCase();
                        return !name.contains('office') &&
                            !name.contains('shop') &&
                            !name.contains('showroom') &&
                            !name.contains('plot') &&
                            !name.contains('warehouse') &&
                            !name.contains('shed') &&
                            !name.contains('industrial');
                      }).toList();
                      for (final m in matches) {
                        if (!configurations.any((c) => c.name.toLowerCase() == m.name.toLowerCase())) {
                          configurations.add(m);
                        }
                      }
                    } else {
                      configurations.addAll(metadata.configurations.where((c) => c.categoryId == _selectedCategory));
                    }
                  }
                }

                final bool isWide = width >= 800;
                final isRent = _activeListingTab == 'Rent';
                final statusItems = isRent
                    ? ['Available', 'Rented Out', 'To Be Available']
                    : ['Available', 'Sold Out'];

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          label: 'Status',
                          value: _selectedStatusFilter,
                          items: statusItems
                              .map((val) => DropdownMenuItem<String>(
                                  value: val, child: Text(val)))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedStatusFilter = val;
                              _currentPage = 0;
                            });
                            _loadProperties();
                          },
                          width: double.infinity,
                        ),
                      ),
                      const SizedBox(width: CRMSpacing.m),
                      Expanded(
                        child: CRMMultiSelectDropdown(
                          label: (() {
                            if (_selectedCategory != null) {
                              final cat = categories.firstWhere(
                                (c) => c.id == _selectedCategory,
                                orElse: () => LookupItem(id: '', name: ''),
                              );
                              final catName = cat.name.toLowerCase();
                              if (catName.contains('commercial') ||
                                  catName.contains('industrial') ||
                                  catName.contains('land') ||
                                  catName.contains('plot')) {
                                return 'Property Type';
                              }
                            }
                            return 'Configuration';
                          })(),
                          selectedIds: _selectedConfigurations,
                          items: configurations,
                          onChanged: (vals) {
                            setState(() {
                              _currentPage = 0;
                            });
                            _loadProperties();
                          },
                        ),
                      ),
                      const SizedBox(width: CRMSpacing.m),
                      Expanded(
                        child: CRMMultiSelectDropdown(
                          label: 'Area',
                          selectedIds: _selectedAreas,
                          items: areas,
                          onChanged: (vals) {
                            setState(() {
                              _currentPage = 0;
                            });
                            _loadProperties();
                          },
                        ),
                      ),
                      const SizedBox(width: CRMSpacing.m),
                      Expanded(
                        child: _buildDropdown(
                          label: 'Price Range',
                          value: _selectedPriceSortOrRange,
                          items: [
                            const DropdownMenuItem<String>(
                              value: 'l2h',
                              child: Text('Low to High'),
                            ),
                            const DropdownMenuItem<String>(
                              value: 'h2l',
                              child: Text('High to Low'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'custom',
                              child: Text(
                                _minPrice != null || _maxPrice != null
                                    ? 'Custom: ₹${_minPrice != null ? BudgetFormatter.format(_minPrice!) : '0'} - ₹${_maxPrice != null ? BudgetFormatter.format(_maxPrice!) : 'Max'}'
                                    : 'Custom Range...',
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val == 'custom') {
                              _showCustomPriceRangeDialog();
                            } else {
                              setState(() {
                                _selectedPriceSortOrRange = val;
                                _minPrice = null;
                                _maxPrice = null;
                                _currentPage = 0;
                              });
                              _loadProperties();
                            }
                          },
                          width: double.infinity,
                        ),
                      ),
                      const SizedBox(width: CRMSpacing.m),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: CRMButton(
                            label: 'Clear Filters',
                            variant: CRMButtonVariant.outline,
                            onPressed: _clearFilters,
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  final double columnWidth = width < 500 ? width : (width - CRMSpacing.m) / 2;
                  return Wrap(
                    spacing: CRMSpacing.m,
                    runSpacing: CRMSpacing.m,
                    children: [
                      _buildDropdown(
                        label: 'Status',
                        value: _selectedStatusFilter,
                        items: statusItems
                            .map((val) => DropdownMenuItem<String>(
                                value: val, child: Text(val)))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedStatusFilter = val;
                            _currentPage = 0;
                          });
                          _loadProperties();
                        },
                        width: columnWidth,
                      ),
                      SizedBox(
                        width: columnWidth,
                        child: CRMMultiSelectDropdown(
                          label: (() {
                            if (_selectedCategory != null) {
                              final cat = categories.firstWhere(
                                (c) => c.id == _selectedCategory,
                                orElse: () => LookupItem(id: '', name: ''),
                              );
                              final catName = cat.name.toLowerCase();
                              if (catName.contains('commercial') ||
                                  catName.contains('industrial') ||
                                  catName.contains('land') ||
                                  catName.contains('plot')) {
                                return 'Property Type';
                              }
                            }
                            return 'Configuration';
                          })(),
                          selectedIds: _selectedConfigurations,
                          items: configurations,
                          onChanged: (vals) {
                            setState(() {
                              _currentPage = 0;
                            });
                            _loadProperties();
                          },
                        ),
                      ),
                      SizedBox(
                        width: columnWidth,
                        child: CRMMultiSelectDropdown(
                          label: 'Area',
                          selectedIds: _selectedAreas,
                          items: areas,
                          onChanged: (vals) {
                            setState(() {
                              _currentPage = 0;
                            });
                            _loadProperties();
                          },
                        ),
                      ),
                      _buildDropdown(
                        label: 'Price Range',
                        value: _selectedPriceSortOrRange,
                        items: [
                          const DropdownMenuItem<String>(
                            value: 'l2h',
                            child: Text('Low to High'),
                          ),
                          const DropdownMenuItem<String>(
                            value: 'h2l',
                            child: Text('High to Low'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'custom',
                            child: Text(
                              _minPrice != null || _maxPrice != null
                                  ? 'Custom: ₹${_minPrice != null ? BudgetFormatter.format(_minPrice!) : '0'} - ₹${_maxPrice != null ? BudgetFormatter.format(_maxPrice!) : 'Max'}'
                                  : 'Custom Range...',
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val == 'custom') {
                            _showCustomPriceRangeDialog();
                          } else {
                            setState(() {
                              _selectedPriceSortOrRange = val;
                              _minPrice = null;
                              _maxPrice = null;
                              _currentPage = 0;
                            });
                            _loadProperties();
                          }
                        },
                        width: columnWidth,
                      ),
                      SizedBox(
                        width: columnWidth,
                        height: 48,
                        child: CRMButton(
                          label: 'Clear Filters',
                          variant: CRMButtonVariant.outline,
                          onPressed: _clearFilters,
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileFilterButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isMobileFiltersExpanded = !_isMobileFiltersExpanded;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: 12),
        decoration: BoxDecoration(
          color: _isMobileFiltersExpanded ? const Color(0xFF64826F) : CRMColors.cardBgOf(context),
          borderRadius: BorderRadius.circular(CRMBorderRadius.card),
          border: Border.all(
            color: _isMobileFiltersExpanded ? const Color(0xFF64826F) : CRMColors.borderOf(context).withOpacity(0.6),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.3)
                  : const Color(0xFF64748B).withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_rounded,
              size: 18,
              color: _isMobileFiltersExpanded ? Colors.white : CRMColors.primaryOf(context),
            ),
            const SizedBox(width: CRMSpacing.s),
            Text(
              _isMobileFiltersExpanded ? "Hide Filters" : "Show Search Filters",
              style: CRMTypography.bodyMedium.copyWith(
                color: _isMobileFiltersExpanded ? Colors.white : CRMColors.textOf(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(PropertyMetadataModel? metadata) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMobileFilterButton(),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isMobileFiltersExpanded
                ? Padding(
                    padding: const EdgeInsets.only(top: CRMSpacing.m),
                    child: _buildSearchFiltersCard(metadata),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      );
    }

    return _buildSearchFiltersCard(metadata);
  }

  Widget _buildPropertyListingTabButton(String label) {
    final isSelected = _activeListingTab == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeListingTab = label;
          _currentPage = 0;
          _selectedStatusFilter = null;
        });
      },
      child: AnimatedContainer(
        duration: CRMMotion.fast,
        curve: CRMMotion.easeOut,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF64826F) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMyAddedToggle() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _myAddedOnly = !_myAddedOnly;
        });
      },
      child: AnimatedContainer(
        duration: CRMMotion.fast,
        curve: CRMMotion.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: 10),
        decoration: BoxDecoration(
          color: _myAddedOnly ? const Color(0xFF64826F) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _myAddedOnly ? const Color(0xFF64826F) : CRMColors.borderOf(context).withOpacity(0.6),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _myAddedOnly ? Icons.check_circle_rounded : Icons.person_outline_rounded,
              size: 16,
              color: _myAddedOnly ? Colors.white : CRMColors.textSecondaryOf(context),
            ),
            const SizedBox(width: CRMSpacing.xs),
            Text(
              "My Added",
              style: CRMTypography.bodyMedium.copyWith(
                color: _myAddedOnly ? Colors.white : CRMColors.textSecondaryOf(context),
                fontWeight: _myAddedOnly ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(List<LookupItem> categories) {
    return Container(
      width: 180,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m),
      decoration: BoxDecoration(
        color: CRMColors.backgroundOf(context),
        borderRadius: BorderRadius.circular(CRMBorderRadius.s),
        border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.6), width: 1.0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedCategory,
          hint: Text(
            'All Category',
            style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondaryOf(context)),
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(
                'All Category',
                style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textOf(context)),
              ),
            ),
            ...categories.map((c) {
              return DropdownMenuItem<String?>(
                value: c.id,
                child: Text(
                  c.name,
                  style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textOf(context)),
                ),
              );
            }),
          ],
          onChanged: (String? val) {
            setState(() {
              _selectedCategory = val;
              _selectedConfigurations.clear();
              _currentPage = 0;
            });
            _loadProperties();
          },
          icon: Icon(Icons.arrow_drop_down, color: CRMColors.textSecondaryOf(context)),
          dropdownColor: CRMColors.cardBgOf(context),
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = null;
      _selectedConfigurations.clear();
      _selectedAreas.clear();
      _selectedListingType = null;
      _selectedVerification = null;
      _activeListingTab = 'Rent';
      _selectedPriceSortOrRange = null;
      _minPrice = null;
      _maxPrice = null;
      _currentPage = 0;
      _myAddedOnly = false;
      _selectedStatusFilter = null;
    });
    _loadProperties();
  }

  Future<void> _showCustomPriceRangeDialog() async {
    final previousSelection = _selectedPriceSortOrRange;
    final minController = TextEditingController(
      text: _minPrice != null ? _minPrice!.toStringAsFixed(0) : '',
    );
    final maxController = TextEditingController(
      text: _maxPrice != null ? _maxPrice!.toStringAsFixed(0) : '',
    );

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String? getMinHelperText() {
              if (minController.text.trim().isEmpty) return null;
              final parsed = BudgetFormatter.parse(minController.text);
              if (parsed <= 0) return null;
              return 'Formatted: ₹${BudgetFormatter.format(parsed)}';
            }

            String? getMaxHelperText() {
              if (maxController.text.trim().isEmpty) return null;
              final parsed = BudgetFormatter.parse(maxController.text);
              if (parsed <= 0) return null;
              return 'Formatted: ₹${BudgetFormatter.format(parsed)}';
            }

            return AlertDialog(
              title: const Text('Custom Price Range'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: minController,
                    keyboardType: TextInputType.text,
                    onChanged: (val) {
                      setDialogState(() {});
                    },
                    decoration: InputDecoration(
                      labelText: 'Min Price (e.g. 50000 or 50k)',
                      prefixText: '₹',
                      helperText: getMinHelperText(),
                      helperStyle: TextStyle(
                        color: CRMColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: CRMSpacing.m),
                  TextField(
                    controller: maxController,
                    keyboardType: TextInputType.text,
                    onChanged: (val) {
                      setDialogState(() {});
                    },
                    decoration: InputDecoration(
                      labelText: 'Max Price (e.g. 150000 or 1.5L)',
                      prefixText: '₹',
                      helperText: getMaxHelperText(),
                      helperStyle: TextStyle(
                        color: CRMColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _selectedPriceSortOrRange = (previousSelection == 'custom' && (_minPrice != null || _maxPrice != null))
                          ? 'custom'
                          : (previousSelection == 'custom' ? null : previousSelection);
                    });
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final minVal = BudgetFormatter.parse(minController.text);
                    final maxVal = BudgetFormatter.parse(maxController.text);
                    setState(() {
                      _minPrice = minVal > 0 ? minVal : null;
                      _maxPrice = maxVal > 0 ? maxVal : null;
                      _selectedPriceSortOrRange = (_minPrice != null || _maxPrice != null) ? 'custom' : null;
                      _currentPage = 0;
                    });
                    _loadProperties();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildVerificationDropdown(double width) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<bool?>(
        value: _selectedVerification,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Verification',
          filled: true,
          fillColor: CRMColors.backgroundOf(context),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: CRMSpacing.m, vertical: CRMSpacing.s),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              borderSide: BorderSide.none),
        ),
        items: const [
          DropdownMenuItem<bool?>(
              value: null,
              child: Text('All Verification', overflow: TextOverflow.ellipsis)),
          DropdownMenuItem<bool?>(
              value: true,
              child: Text('Verified', overflow: TextOverflow.ellipsis)),
          DropdownMenuItem<bool?>(
              value: false,
              child: Text('Unverified', overflow: TextOverflow.ellipsis)),
        ],
        onChanged: (val) {
          setState(() {
            _selectedVerification = val;
            _currentPage = 0;
          });
          _loadProperties();
        },
      ),
    );
  }

  Widget _buildPagination(int totalItems, int totalPages, int currentPage) {
    final from = currentPage * _pageSize + 1;
    final to = ((currentPage + 1) * _pageSize).clamp(0, totalItems);
    final double screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 500;

    final infoText = Text(
      'Showing $from–$to of $totalItems',
      style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
    );

    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Rows:',
            style:
                CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context))),
        const SizedBox(width: CRMSpacing.xs),
        DropdownButton<int>(
          value: _pageSize,
          underline: const SizedBox.shrink(),
          items: _pageSizeOptions
              .map(
                  (size) => DropdownMenuItem(value: size, child: Text('$size')))
              .toList(),
          onChanged: (val) {
            if (val == null) return;
            setState(() {
              _pageSize = val;
              _currentPage = 0;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed:
              currentPage > 0 ? () => setState(() => _currentPage--) : null,
        ),
        Text(
          '${currentPage + 1} / $totalPages',
          style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context)),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: currentPage < totalPages - 1
              ? () => setState(() => _currentPage++)
              : null,
        ),
      ],
    );

    if (isMobile) {
      return Column(
        children: [
          infoText,
          const SizedBox(height: CRMSpacing.s),
          controls,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        infoText,
        controls,
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required double width,
  }) {
    final bool hasValue =
        value == null || items.any((item) => item.value == value);
    final String? safeValue = hasValue ? value : null;

    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        value: safeValue,
        isExpanded: true,
        dropdownColor: CRMColors.cardBgOf(context),
        style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
          filled: true,
          fillColor: CRMColors.backgroundOf(context),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: CRMSpacing.m, vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              borderSide: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.6))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              borderSide: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.6))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              borderSide: BorderSide(color: CRMColors.primaryOf(context), width: 1.5)),
        ),
        items: [
          DropdownMenuItem<String>(
              value: null,
              child: Text('All $label', overflow: TextOverflow.ellipsis)),
          ...items,
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionToolbar() {
    final refreshButton = IconButton(
      icon: Icon(Icons.refresh_rounded, color: CRMColors.textSecondaryOf(context)),
      onPressed: _loadProperties,
    );

    return Align(
      alignment: Alignment.centerRight,
      child: refreshButton,
    );
  }

  void _showAddEditPropertyDialog(
      BuildContext context, PropertyMetadataModel metadata,
      [PropertyModel? property]) {
    final propertiesBloc = context.read<PropertiesBloc>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12.0 : 40.0,
          vertical: isMobile ? 16.0 : 24.0,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: CRMColors.cardBgOf(dialogContext),
            borderRadius: BorderRadius.circular(CRMBorderRadius.dialog),
            boxShadow: CRMShadows.modal,
          ),
          width: isMobile ? screenWidth - 24 : screenWidth * 0.95,
          height: MediaQuery.of(context).size.height * 0.95,
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 750),
          clipBehavior: Clip.antiAlias,
          child: BlocProvider.value(
            value: propertiesBloc,
            child: AddEditPropertyScreen(
              metadata: metadata,
              property: property,
              activeTab: _activeTab,
              activeListingTab: _activeListingTab,
            ),
          ),
        ),
      ),
    );
  }

  void _openPropertyDetails(BuildContext context, PropertyModel p) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    if (kIsWeb && !isMobile) {
      final String url = '${Uri.base.origin}/properties/${p.id}';
      launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
    } else {
      showCRMPropertyDrawer(context, p);
    }
  }

  String _getBhkColumnHeader(PropertyMetadataModel? metadata) {
    if (_selectedCategory == null || metadata == null) {
      return 'BHK';
    }
    final selectedCat = metadata.categories.firstWhere(
      (c) => c.id == _selectedCategory,
      orElse: () => LookupItem(id: '', name: ''),
    );
    final name = selectedCat.name.toLowerCase();
    if (name.contains('commercial') || name.contains('industrial')) {
      return 'Super Built-up Area';
    } else if (name.contains('land') || name.contains('plot')) {
      return 'Plot Area';
    }
    return 'BHK';
  }

  bool _matchesActiveCategory(PropertyModel p) {
    final cat = p.categoryName.toLowerCase();
    if (_activeCategoryTab == 'Residential') {
      return cat.contains('resident') ||
          cat.contains('apartment') ||
          cat.contains('flat') ||
          cat.contains('villa') ||
          cat.contains('house') ||
          cat.contains('bhk') ||
          (!cat.contains('commercial') &&
              !cat.contains('industrial') &&
              !cat.contains('land') &&
              !cat.contains('plot'));
    } else if (_activeCategoryTab == 'Commercial') {
      return cat.contains('commercial') ||
          cat.contains('office') ||
          cat.contains('shop') ||
          cat.contains('showroom') ||
          cat.contains('retail');
    } else if (_activeCategoryTab == 'Industrial') {
      return cat.contains('industrial') ||
          cat.contains('factory') ||
          cat.contains('warehouse') ||
          cat.contains('shed');
    } else if (_activeCategoryTab == 'Land & Plot') {
      return cat.contains('land') || cat.contains('plot');
    }
    return false;
  }

  String _getPropertyBhkOrAreaValue(PropertyModel p) {
    final catName = p.categoryName.toLowerCase();
    if (catName.contains('commercial') || catName.contains('industrial')) {
      return p.superBuiltupArea != null && p.superBuiltupArea! > 0
          ? '${p.superBuiltupArea!.toStringAsFixed(0)} Sq.Ft'
          : 'N/A';
    } else if (catName.contains('land') || catName.contains('plot')) {
      return p.plotArea != null && p.plotArea! > 0
          ? '${p.plotArea!.toStringAsFixed(0)} Sq.Ft'
          : 'N/A';
    }
    if (p.configurationName != null && p.configurationName!.trim().isNotEmpty) {
      return p.configurationName!;
    }
    return '${p.bedrooms} BHK';
  }

  IconData _getPropertyBhkOrAreaIcon(PropertyModel p) {
    final catName = p.categoryName.toLowerCase();
    if (catName.contains('commercial') || catName.contains('industrial')) {
      return Icons.business_center_outlined;
    } else if (catName.contains('land') || catName.contains('plot')) {
      return Icons.landscape_outlined;
    }
    return Icons.king_bed_outlined;
  }

  Widget _buildPropertyThumbnail(String url) {
    if (url.startsWith('data:image') || url.contains('base64')) {
      try {
        final base64Str = url.split(',').last;
        return Image.memory(base64Decode(base64Str), fit: BoxFit.cover);
      } catch (_) {}
    }
    if (kIsWeb) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image_outlined, size: 16),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => const Center(
        child: SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
      ),
      errorWidget: (context, url, error) =>
          const Icon(Icons.broken_image_outlined, size: 16),
    );
  }
}

class CRMChartCard extends StatefulWidget {
  final String title;
  final List<ChartSector> sectors;

  const CRMChartCard({
    Key? key,
    required this.title,
    required this.sectors,
  }) : super(key: key);

  @override
  State<CRMChartCard> createState() => _CRMChartCardState();
}

class _CRMChartCardState extends State<CRMChartCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sweepAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _sweepAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant CRMChartCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only re-animate when title changes or sector data actually changes
    bool sectorsChanged = oldWidget.title != widget.title ||
        oldWidget.sectors.length != widget.sectors.length;
    if (!sectorsChanged) {
      for (int i = 0; i < oldWidget.sectors.length; i++) {
        if (oldWidget.sectors[i].label != widget.sectors[i].label ||
            oldWidget.sectors[i].value != widget.sectors[i].value) {
          sectorsChanged = true;
          break;
        }
      }
    }
    if (sectorsChanged) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final titleColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    final sectorsToShow = widget.sectors.isNotEmpty
        ? widget.sectors
        : [ChartSector(label: 'No Listings', value: 1.0, color: Colors.grey.shade400)];

    final total = sectorsToShow.fold<double>(0, (s, e) => s + e.value);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [Colors.white, const Color(0xFFF8FAFC)],
        ),
        borderRadius: BorderRadius.circular(CRMBorderRadius.card),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : const Color(0xFF64748B).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.15)
                : const Color(0xFF64748B).withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? CRMSpacing.s : CRMSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 3,
                height: 12,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      CRMColors.primaryOf(context),
                      CRMColors.primaryOf(context).withOpacity(0.4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Row(
                  children: [
                    // 3D Donut Chart
                    SizedBox(
                      width: isMobile ? 56 : 72,
                      height: isMobile ? 56 : 72,
                      child: CustomPaint(
                        painter: DonutChart3DPainter(
                          sectors: sectorsToShow,
                          backgroundColor: bgColor,
                          animationValue: _sweepAnimation.value,
                          isDark: isDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Animated legend
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(sectorsToShow.length, (i) {
                            final s = sectorsToShow[i];
                            final pct = total > 0 ? s.value / total : 0.0;
                            // Stagger each legend item
                            final itemDelay = 0.4 + (i * 0.08);
                            final itemEnd = (itemDelay + 0.3).clamp(0.0, 1.0);
                            final itemProgress = Curves.easeOut.transform(
                              (((_controller.value - itemDelay) / (itemEnd - itemDelay))
                                  .clamp(0.0, 1.0)),
                            );

                            return Opacity(
                              opacity: itemProgress,
                              child: Transform.translate(
                                offset: Offset(8 * (1 - itemProgress), 0),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 1.5),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: s.color,
                                          borderRadius: BorderRadius.circular(2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: s.color.withOpacity(0.4),
                                              blurRadius: 3,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              s.label == 'No Listings'
                                                  ? 'No Listings'
                                                  : '${s.label}: ${s.value.toInt()}',
                                              style: TextStyle(
                                                fontSize: isMobile ? 9 : 10,
                                                color: titleColor.withOpacity(0.85),
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            // Animated progress bar
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(2),
                                              child: SizedBox(
                                                height: 3,
                                                child: Stack(
                                                  children: [
                                                    Container(
                                                      color: subtitleColor.withOpacity(0.1),
                                                    ),
                                                    FractionallySizedBox(
                                                      widthFactor: pct * _sweepAnimation.value,
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          gradient: LinearGradient(
                                                            colors: [
                                                              s.color,
                                                              s.color.withOpacity(0.6),
                                                            ],
                                                          ),
                                                          borderRadius: BorderRadius.circular(2),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class KPICardData {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String chartTitle;
  final List<ChartSector> sectors;

  KPICardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.chartTitle,
    required this.sectors,
  });
}

class ChartSector {
  final String label;
  final double value;
  final Color color;

  ChartSector({
    required this.label,
    required this.value,
    required this.color,
  });
}

class DonutChart3DPainter extends CustomPainter {
  final List<ChartSector> sectors;
  final Color backgroundColor;
  final double animationValue;
  final bool isDark;

  DonutChart3DPainter({
    required this.sectors,
    required this.backgroundColor,
    required this.animationValue,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double total = sectors.fold(0, (sum, s) => sum + s.value);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width < size.height ? size.width / 2 : size.height / 2) - 2;
    final strokeWidth = radius * 0.38;
    final outerRadius = radius;
    final innerRadius = radius - strokeWidth;

    // --- 3D Shadow / Depth layers ---
    for (int i = 3; i >= 1; i--) {
      final shadowPaint = Paint()
        ..color = (isDark ? Colors.black : const Color(0xFF94A3B8))
            .withOpacity(0.06 * i)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + (i * 1.5)
        ..isAntiAlias = true;
      final shadowOffset = Offset(0, i * 0.8);
      canvas.drawCircle(center + shadowOffset, outerRadius - strokeWidth / 2, shadowPaint);
    }

    // --- Draw animated sectors as thick arcs with gradient ---
    final animatedSweepTotal = 2 * math.pi * animationValue;
    double startAngle = -math.pi / 2;

    for (final sector in sectors) {
      final sweepAngle = (sector.value / total) * animatedSweepTotal;
      final midAngle = startAngle + sweepAngle / 2;

      // Gradient arc paint
      final arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt
        ..isAntiAlias = true;

      // Create a sweep gradient for the sector for a richer look
      final darkerColor = Color.lerp(sector.color, Colors.black, 0.25)!;
      final lighterColor = Color.lerp(sector.color, Colors.white, 0.2)!;
      arcPaint.shader = ui.Gradient.sweep(
        center,
        [lighterColor, sector.color, darkerColor, sector.color],
        [0.0, 0.3, 0.7, 1.0],
        TileMode.clamp,
        startAngle,
        startAngle + sweepAngle,
      );

      final arcRect = Rect.fromCircle(center: center, radius: outerRadius - strokeWidth / 2);
      canvas.drawArc(arcRect, startAngle, sweepAngle, false, arcPaint);

      // Draw percentage text for large sectors
      if (sweepAngle > 0.4 && animationValue > 0.5) {
        final textOpacity = ((animationValue - 0.5) * 2).clamp(0.0, 1.0);
        final textRadius = outerRadius - strokeWidth / 2;
        final textX = center.dx + textRadius * math.cos(midAngle);
        final textY = center.dy + textRadius * math.sin(midAngle);
        final percentage = (sector.value / total * 100).toStringAsFixed(0);

        final textPainter = TextPainter(
          text: TextSpan(
            text: '$percentage%',
            style: TextStyle(
              color: Colors.white.withOpacity(textOpacity),
              fontSize: (strokeWidth * 0.38).clamp(7.0, 11.0),
              fontWeight: FontWeight.w800,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(textX - textPainter.width / 2, textY - textPainter.height / 2),
        );
      }

      startAngle += sweepAngle;
    }

    // --- Inner circle (center hole) with subtle gradient for depth ---
    final innerGradient = ui.Gradient.radial(
      Offset(center.dx - innerRadius * 0.2, center.dy - innerRadius * 0.2),
      innerRadius,
      isDark
          ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
          : [Colors.white, const Color(0xFFF1F5F9)],
      [0.0, 1.0],
    );
    final innerPaint = Paint()
      ..shader = innerGradient
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(center, innerRadius - 1, innerPaint);

    // Subtle inner ring border
    final innerRingPaint = Paint()
      ..color = (isDark ? Colors.white : const Color(0xFF94A3B8)).withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..isAntiAlias = true;
    canvas.drawCircle(center, innerRadius - 1, innerRingPaint);

    // --- Glossy highlight overlay on top half ---
    final highlightRect = Rect.fromCircle(center: center, radius: outerRadius - strokeWidth / 2);
    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.4
      ..isAntiAlias = true
      ..shader = ui.Gradient.linear(
        Offset(center.dx, center.dy - outerRadius),
        center,
        [
          Colors.white.withOpacity(isDark ? 0.08 : 0.18),
          Colors.white.withOpacity(0.0),
        ],
      );
    canvas.drawArc(highlightRect, -math.pi, math.pi, false, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant DonutChart3DPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.sectors != sectors ||
        oldDelegate.isDark != isDark;
  }
}

class HoverChartTooltip extends StatefulWidget {
  final Widget child;
  final String title;
  final List<ChartSector> sectors;

  const HoverChartTooltip({
    Key? key,
    required this.child,
    required this.title,
    required this.sectors,
  }) : super(key: key);

  @override
  State<HoverChartTooltip> createState() => _HoverChartTooltipState();
}

class _HoverChartTooltipState extends State<HoverChartTooltip> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isHovered = false;

  void _showOverlay() {
    if (widget.sectors.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isHovered || _overlayEntry != null) return;
      _overlayEntry = OverlayEntry(
        builder: (context) {
          final theme = Theme.of(context);
          final bgColor = theme.brightness == Brightness.dark
              ? const Color(0xFF1E293B)
              : Colors.white;
          final borderColor = theme.brightness == Brightness.dark
              ? const Color(0xFF334155)
              : const Color(0xFFE2E8F0);
          final titleColor = theme.brightness == Brightness.dark
              ? const Color(0xFFF8FAFC)
              : const Color(0xFF1E293B);

          return Positioned(
            width: 320,
            height: 180,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, -190), // Show above the card
              child: MouseRegion(
                onEnter: (_) {
                  _isHovered = true;
                },
                onExit: (_) {
                  _isHovered = false;
                  _hideOverlay();
                },
                child: Material(
                  elevation: 12,
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  shadowColor: Colors.black.withOpacity(0.15),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Row(
                            children: [
                              SizedBox(
                                width: 110,
                                height: 110,
                                child: CustomPaint(
                                  painter: DonutChart3DPainter(
                                    sectors: widget.sectors,
                                    backgroundColor: bgColor,
                                    animationValue: 1.0,
                                    isDark: Theme.of(context).brightness == Brightness.dark,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: widget.sectors.map((s) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: s.color,
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '${s.label}: ${s.value.toInt()}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: titleColor.withOpacity(0.8),
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
      Overlay.of(context).insert(_overlayEntry!);
    });
  }

  void _hideOverlay() {
    // Wait briefly to make sure user didn't enter the overlay region
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      if (!_isHovered) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _overlayEntry?.remove();
          _overlayEntry = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) {
          _isHovered = true;
          _showOverlay();
        },
        onExit: (_) {
          _isHovered = false;
          _hideOverlay();
        },
        child: widget.child,
      ),
    );
  }
}

class _MobilePropertyImageCarousel extends StatefulWidget {
  final List<String> images;
  final VoidCallback onTap;

  const _MobilePropertyImageCarousel({
    Key? key,
    required this.images,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_MobilePropertyImageCarousel> createState() => _MobilePropertyImageCarouselState();
}

class _MobilePropertyImageCarouselState extends State<_MobilePropertyImageCarousel> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (widget.images.length <= 1) return;
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % widget.images.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildPropertyThumbnail(String url) {
    if (url.startsWith('data:image') || url.contains('base64')) {
      try {
        final base64Str = url.split(',').last;
        return Image.memory(base64Decode(base64Str), fit: BoxFit.cover);
      } catch (_) {}
    }
    if (kIsWeb) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: CRMColors.backgroundOf(context),
          child: const Icon(Icons.broken_image_outlined, size: 24, color: Colors.grey),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: CRMColors.backgroundOf(context),
        child: const Icon(Icons.broken_image_outlined, size: 24, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return const SizedBox.shrink();

    return Stack(
      alignment: Alignment.center,
      children: [
        // PageView
        GestureDetector(
          onTap: widget.onTap,
          child: Container(
            height: 160,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(CRMBorderRadius.card),
            ),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemCount: widget.images.length,
              itemBuilder: (context, index) {
                return _buildPropertyThumbnail(widget.images[index]);
              },
            ),
          ),
        ),
        // Navigation Buttons (only if there are multiple images)
        if (widget.images.length > 1) ...[
          // Left Arrow
          Positioned(
            left: 8,
            child: Material(
              color: Colors.black.withOpacity(0.4),
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () {
                  // Reset timer on manual action
                  _startTimer();
                  if (_pageController.hasClients) {
                    final prevPage = (_currentPage - 1 + widget.images.length) % widget.images.length;
                    _pageController.animateToPage(
                      prevPage,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
            ),
          ),
          // Right Arrow
          Positioned(
            right: 8,
            child: Material(
              color: Colors.black.withOpacity(0.4),
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () {
                  // Reset timer on manual action
                  _startTimer();
                  if (_pageController.hasClients) {
                    final nextPage = (_currentPage + 1) % widget.images.length;
                    _pageController.animateToPage(
                      nextPage,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
            ),
          ),
        ],
        // Indicator text (always shown)
        Positioned(
          bottom: 8,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_currentPage + 1}/${widget.images.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileStatisticsSection extends StatefulWidget {
  final Widget kpiCard;
  final String chartTitle;
  final List<ChartSector> sectors;

  const _MobileStatisticsSection({
    Key? key,
    required this.kpiCard,
    required this.chartTitle,
    required this.sectors,
  }) : super(key: key);

  @override
  State<_MobileStatisticsSection> createState() => _MobileStatisticsSectionState();
}

class _MobileStatisticsSectionState extends State<_MobileStatisticsSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double cardWidth = (screenWidth - (CRMSpacing.m * 2) - CRMSpacing.m).clamp(0.0, double.infinity) / 2;
    final double cardHeight = 105.0;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    final sectorsToShow = widget.sectors.isNotEmpty
        ? widget.sectors
        : [ChartSector(label: 'No Listings', value: 1.0, color: Colors.grey.shade400)];

    final total = sectorsToShow.fold<double>(0, (s, e) => s + e.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: widget.kpiCard,
            ),
            const SizedBox(width: CRMSpacing.m),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Container(
                width: cardWidth,
                height: cardHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [Colors.white, const Color(0xFFF8FAFC)],
                  ),
                  borderRadius: BorderRadius.circular(CRMBorderRadius.card),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withOpacity(0.3) : const Color(0xFF64748B).withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.s, vertical: CRMSpacing.xs),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: CustomPaint(
                        painter: DonutChart3DPainter(
                          sectors: sectorsToShow,
                          backgroundColor: bgColor,
                          animationValue: 1.0,
                          isDark: isDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.chartTitle,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          size: 14,
                          color: CRMColors.primaryOf(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isExpanded
              ? Container(
                  margin: const EdgeInsets.only(top: CRMSpacing.m),
                  padding: const EdgeInsets.all(CRMSpacing.m),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                          : [Colors.white, const Color(0xFFF8FAFC)],
                    ),
                    borderRadius: BorderRadius.circular(CRMBorderRadius.card),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withOpacity(0.2) : const Color(0xFF64748B).withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.chartTitle} Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: CRMSpacing.s),
                      Column(
                        children: List.generate(sectorsToShow.length, (i) {
                          final s = sectorsToShow[i];
                          final pct = total > 0 ? s.value / total : 0.0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: CRMSpacing.xs),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: s.color,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            s.label,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            '${s.value.toInt()}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(2),
                                        child: SizedBox(
                                          height: 3,
                                          child: LinearProgressIndicator(
                                            value: pct,
                                            backgroundColor: (isDark ? Colors.white10 : Colors.black12),
                                            valueColor: AlwaysStoppedAnimation<Color>(s.color),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
