import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_shadows.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/drawers.dart';
import '../../../core/design_system/widgets/crm_network_image.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/models/user_model.dart';
import '../bloc/properties_bloc.dart';
import '../models/property_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PropertySearchScreen extends StatefulWidget {
  final String? initialSearch;
  final String? initialListingType;
  final String? initialCategoryTab;
  final String? initialBhk;

  const PropertySearchScreen({
    super.key,
    this.initialSearch,
    this.initialListingType,
    this.initialCategoryTab,
    this.initialBhk,
  });

  @override
  State<PropertySearchScreen> createState() => _PropertySearchScreenState();
}

class _PropertySearchScreenState extends State<PropertySearchScreen> {
  late final TextEditingController _searchController;
  late String _activeListingTab;
  late String _activeCategoryTab;
  String? _activeBhkFilter;
  String? _selectedPriceSort;
  final Set<String> _shortlistedPropertyIds = {};

  String _getInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'PA';
    final parts = clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String _getUpdatedTimeText(PropertyModel p) {
    final date = p.createdAt;
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return 'Updated just now';
      }
      return 'Updated ${diff.inHours} ${diff.inHours == 1 ? "hour" : "hours"} ago';
    } else if (diff.inDays == 1) {
      return 'Updated 1 day ago';
    } else if (diff.inDays < 30) {
      return 'Updated ${diff.inDays} days ago';
    } else {
      return 'Updated ${DateFormat('dd MMM yyyy').format(date)}';
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearch ?? '');
    _activeListingTab = (widget.initialListingType != null && widget.initialListingType!.toLowerCase() == 're-sale') ? 'Re-Sale' : 'Rent';
    _activeCategoryTab = widget.initialCategoryTab ?? 'Residential';
    if (widget.initialBhk != null && widget.initialBhk!.isNotEmpty) {
      if (widget.initialBhk == '5') {
        _activeBhkFilter = '5+ BHK';
      } else {
        _activeBhkFilter = '${widget.initialBhk} BHK';
      }
    }
    _loadShortlistedIds();
    context.read<PropertiesBloc>().add(LoadPropertiesEvent(activeTab: 'All'));
  }

  Future<void> _loadShortlistedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('shortlisted_properties') ?? [];
      if (mounted) {
        setState(() {
          _shortlistedPropertyIds.clear();
          _shortlistedPropertyIds.addAll(list);
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleShortlist(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = (prefs.getStringList('shortlisted_properties') ?? []).toSet();
      final isCurrentlyShortlisted = list.contains(id);
      if (isCurrentlyShortlisted) {
        list.remove(id);
      } else {
        list.add(id);
      }
      await prefs.setStringList('shortlisted_properties', list.toList());
      if (mounted) {
        setState(() {
          _shortlistedPropertyIds.clear();
          _shortlistedPropertyIds.addAll(list);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!isCurrentlyShortlisted ? 'Added to Shortlist (♥)' : 'Removed from Shortlist'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final currentUser = authState is Authenticated ? authState.user : null;

    return Scaffold(
      backgroundColor: CRMColors.backgroundOf(context),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          MediaQuery.of(context).size.width < 600 ? 110 : 64,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: CRMColors.cardBgOf(context),
            border: Border(bottom: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.5))),
            boxShadow: CRMShadows.small,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.l, vertical: 6),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;

                  final logoWidget = InkWell(
                    onTap: () {
                      if (kIsWeb) {
                        context.go('/dashboard');
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: CRMColors.primaryOf(context).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.home_work_rounded, color: CRMColors.primaryOf(context), size: 22),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'PropKart',
                          style: TextStyle(
                            color: CRMColors.primaryOf(context),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  );

                  final searchBoxWidget = Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: CRMColors.backgroundOf(context),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.6)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Icon(Icons.search_rounded, color: CRMColors.textMutedOf(context), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(color: CRMColors.textOf(context), fontSize: 13.5),
                            decoration: InputDecoration(
                              hintText: 'Search city, locality, project or property type...',
                              hintStyle: TextStyle(color: CRMColors.textMutedOf(context), fontSize: 13),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onSubmitted: (_) => setState(() {}),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                              });
                            },
                          ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CRMColors.primaryOf(context),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                          ),
                          onPressed: () => setState(() {}),
                          child: const Text('Search', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  );

                  final shortlistWidget = Tooltip(
                    message: _activeCategoryTab == 'Shortlisted' ? 'Show All Properties' : 'View Shortlisted Properties',
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (_activeCategoryTab == 'Shortlisted') {
                            _activeCategoryTab = 'Residential';
                          } else {
                            _activeCategoryTab = 'Shortlisted';
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _activeCategoryTab == 'Shortlisted'
                                  ? Colors.red.withOpacity(0.15)
                                  : CRMColors.backgroundOf(context),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _activeCategoryTab == 'Shortlisted'
                                    ? Colors.red
                                    : CRMColors.borderOf(context).withOpacity(0.6),
                              ),
                            ),
                            child: Icon(
                              _shortlistedPropertyIds.isNotEmpty ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: _shortlistedPropertyIds.isNotEmpty ? Colors.red : CRMColors.textMutedOf(context),
                              size: 20,
                            ),
                          ),
                          if (_shortlistedPropertyIds.isNotEmpty)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Text(
                                  '${_shortlistedPropertyIds.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );

                  if (isMobile) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            logoWidget,
                            shortlistWidget,
                          ],
                        ),
                        const SizedBox(height: 8),
                        searchBoxWidget,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      logoWidget,
                      const SizedBox(width: 24),
                      Expanded(child: searchBoxWidget),
                      const SizedBox(width: 10),
                      shortlistWidget,
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
      body: BlocBuilder<PropertiesBloc, PropertiesState>(
        builder: (context, state) {
          if (state is PropertiesLoading || state is PropertiesInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          List<PropertyModel> allProps = [];
          PropertyMetadataModel? metadata;
          if (state is PropertiesLoaded) {
            allProps = state.properties;
            metadata = state.metadata;
          }

          // Auto-sync search query with active BHK filter chip if explicit BHK is typed
          final searchText = _searchController.text.trim();
          if (searchText.isNotEmpty) {
            final bhkMatch = RegExp(r'(\d+\+?)\s*-?\s*BHK', caseSensitive: false).firstMatch(searchText);
            if (bhkMatch != null) {
              final bhkVal = bhkMatch.group(1)!;
              final extractedFilter = bhkVal == '5' ? '5+ BHK' : '$bhkVal BHK';
              if (_activeBhkFilter != extractedFilter) {
                _activeBhkFilter = extractedFilter;
              }
            }
          }

          // Filtering
          final filteredProps = allProps.where((p) {
            // Listing Type filter
            final ltName = p.listingTypeName.toLowerCase();
            final matchesListing = _activeCategoryTab == 'Shortlisted'
                ? true
                : (_activeListingTab == 'Rent'
                    ? ltName.contains('rent')
                    : (ltName.contains('sale') || ltName.contains('resale') || !ltName.contains('rent')));

            // Category Tab filter
            final cat = p.categoryName.toLowerCase();
            bool matchesCategoryTab = false;
            if (_activeCategoryTab == 'Shortlisted') {
              matchesCategoryTab = _shortlistedPropertyIds.contains(p.id);
            } else if (_activeCategoryTab == 'All') {
              matchesCategoryTab = true;
            } else if (_activeCategoryTab == 'Residential') {
              matchesCategoryTab = cat.contains('resident') ||
                  cat.contains('apartment') ||
                  cat.contains('flat') ||
                  cat.contains('villa') ||
                  cat.contains('house') ||
                  cat.contains('bhk') ||
                  (!cat.contains('commercial') && !cat.contains('industrial') && !cat.contains('land') && !cat.contains('plot'));
            } else if (_activeCategoryTab == 'Commercial') {
              matchesCategoryTab = cat.contains('commercial') || cat.contains('office') || cat.contains('shop') || cat.contains('showroom') || cat.contains('retail');
            } else if (_activeCategoryTab == 'Industrial') {
              matchesCategoryTab = cat.contains('industrial') || cat.contains('factory') || cat.contains('warehouse') || cat.contains('shed');
            } else if (_activeCategoryTab == 'Land & Plot') {
              matchesCategoryTab = cat.contains('land') || cat.contains('plot');
            } else if (_activeCategoryTab == 'No Images') {
              matchesCategoryTab = p.images.isEmpty;
            }

            // BHK filter
            bool matchesBhk = true;
            if (_activeBhkFilter != null && _activeBhkFilter != 'All BHK') {
              final titleLower = p.title.toLowerCase();
              final descLower = (p.description ?? '').toLowerCase();
              final configName = (p.configurationName ?? '').toLowerCase();
              final pTypeName = p.propertyTypeName.toLowerCase();

              if (_activeBhkFilter == '1 BHK') {
                matchesBhk = p.bedrooms == 1 ||
                    configName.contains('1') ||
                    titleLower.contains('1 bhk') || titleLower.contains('1bhk') ||
                    descLower.contains('1 bhk') || descLower.contains('1bhk') ||
                    pTypeName.contains('1 bhk') || pTypeName.contains('1bhk');
              } else if (_activeBhkFilter == '2 BHK') {
                matchesBhk = p.bedrooms == 2 ||
                    configName.contains('2') ||
                    titleLower.contains('2 bhk') || titleLower.contains('2bhk') ||
                    descLower.contains('2 bhk') || descLower.contains('2bhk') ||
                    pTypeName.contains('2 bhk') || pTypeName.contains('2bhk');
              } else if (_activeBhkFilter == '3 BHK') {
                matchesBhk = p.bedrooms == 3 ||
                    configName.contains('3') ||
                    titleLower.contains('3 bhk') || titleLower.contains('3bhk') ||
                    descLower.contains('3 bhk') || descLower.contains('3bhk') ||
                    pTypeName.contains('3 bhk') || pTypeName.contains('3bhk');
              } else if (_activeBhkFilter == '4 BHK') {
                matchesBhk = p.bedrooms == 4 ||
                    configName.contains('4') ||
                    titleLower.contains('4 bhk') || titleLower.contains('4bhk') ||
                    descLower.contains('4 bhk') || descLower.contains('4bhk') ||
                    pTypeName.contains('4 bhk') || pTypeName.contains('4bhk');
              } else if (_activeBhkFilter == '5+ BHK') {
                matchesBhk = p.bedrooms >= 5 ||
                    configName.contains('5') ||
                    titleLower.contains('5 bhk') || titleLower.contains('5bhk') ||
                    descLower.contains('5 bhk') || descLower.contains('5bhk') ||
                    pTypeName.contains('5 bhk') || pTypeName.contains('5bhk');
              }
            }

            // Search query filter (strips explicit BHK terms to match location/type/title/address cleanly)
            bool matchesSearch = true;
            if (searchText.isNotEmpty) {
              final cleanQuery = searchText.replaceAll(RegExp(r'(\d+\+?)\s*-?\s*bhk', caseSensitive: false), '').trim();
              if (cleanQuery.isNotEmpty) {
                final words = cleanQuery.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
                matchesSearch = words.every((word) {
                  final w = word.toLowerCase();
                  return p.propertyCode.toLowerCase().contains(w) ||
                      p.title.toLowerCase().contains(w) ||
                      p.areaName.toLowerCase().contains(w) ||
                      p.cityName.toLowerCase().contains(w) ||
                      p.address.toLowerCase().contains(w) ||
                      (p.landmark?.toLowerCase().contains(w) ?? false) ||
                      (p.description?.toLowerCase().contains(w) ?? false) ||
                      p.categoryName.toLowerCase().contains(w) ||
                      p.propertyTypeName.toLowerCase().contains(w) ||
                      (p.configurationName?.toLowerCase().contains(w) ?? false) ||
                      (p.furnishingTypeName?.toLowerCase().contains(w) ?? false) ||
                      (p.remarks?.toLowerCase().contains(w) ?? false);
                });
              }
            }

            return matchesListing && matchesCategoryTab && matchesBhk && matchesSearch;
          }).toList();

          // Sorting
          if (_selectedPriceSort == 'l2h') {
            filteredProps.sort((a, b) => a.price.compareTo(b.price));
          } else if (_selectedPriceSort == 'h2l') {
            filteredProps.sort((a, b) => b.price.compareTo(a.price));
          } else {
            filteredProps.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          }

          final rawLoc = _searchController.text.trim().isNotEmpty
              ? _searchController.text.trim()
              : 'Ahmedabad';
          final cleanLoc = rawLoc.replaceAll(RegExp(r'\b\d+\s*BHK\b', caseSensitive: false), '').trim();
          final locationText = cleanLoc.isNotEmpty ? cleanLoc : rawLoc;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : CRMSpacing.l,
                  vertical: CRMSpacing.m,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    // Small Breadcrumb Routing Text (Page-wise route in small letters)
                    Text(
                      'Home / Ahmedabad / $_activeCategoryTab Property for $_activeListingTab in $locationText',
                      style: TextStyle(
                        color: CRMColors.textMutedOf(context),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Rent / Re-Sale Tabs + Category Tabs + BHK Chips Row
                    _buildFiltersControlBar(),
                    const SizedBox(height: 16),

                    // Context Results Sub-Header Bar (Image 3 style)
                    _buildResultsContextBar(filteredProps.length, locationText),
                    const SizedBox(height: 16),

                    // Property Cards List
                    if (filteredProps.isEmpty)
                      CRMCard(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.location_city_outlined, size: 48, color: CRMColors.primaryOf(context).withOpacity(0.4)),
                              const SizedBox(height: 12),
                              Text(
                                'No Properties Available in $locationText',
                                style: TextStyle(color: CRMColors.textOf(context), fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Try clearing your search terms or selecting a different bedroom configuration.',
                                style: TextStyle(color: CRMColors.textSecondaryOf(context), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        children: filteredProps.map((p) {
                          return _buildHousingCard(p, currentUser, metadata);
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  ),
);
}

  Widget _buildFiltersControlBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CRMColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Tabs & Categories in smooth horizontal scrollable row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                // Rent / Re-Sale Toggle Tabs
                Container(
                  height: 34,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: CRMColors.backgroundOf(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.6)),
                  ),
                  child: Row(
                    children: [
                      _buildTabChoice('Rent', _activeListingTab == 'Rent', () {
                        setState(() {
                          _activeListingTab = 'Rent';
                        });
                      }),
                      _buildTabChoice('Re-Sale', _activeListingTab == 'Re-Sale', () {
                        setState(() {
                          _activeListingTab = 'Re-Sale';
                        });
                      }),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Category Chips (Custom pill chips to prevent checkmark truncation)
                ...['Residential', 'Commercial', 'Industrial', 'Land & Plot', 'No Images', 'All'].map((cat) {
                  final isSelected = _activeCategoryTab == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _activeCategoryTab = cat;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? CRMColors.primaryOf(context) : CRMColors.primaryOf(context).withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? CRMColors.primaryOf(context) : CRMColors.primaryOf(context).withOpacity(0.2),
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
                }),
              ],
            ),
          ),

          // BHK Selector Chips (Shown for Residential or All)
          if (_activeCategoryTab == 'Residential' || _activeCategoryTab == 'All') ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: ['All BHK', '1 BHK', '2 BHK', '3 BHK', '4 BHK', '5+ BHK'].map((bhk) {
                  final isSelected = (_activeBhkFilter == bhk) || (_activeBhkFilter == null && bhk == 'All BHK');
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _activeBhkFilter = bhk == 'All BHK' ? null : bhk;
                          if (_searchController.text.isNotEmpty) {
                            final oldText = _searchController.text;
                            final cleanText = oldText.replaceAll(RegExp(r'\b\d+\+?\s*BHK\b', caseSensitive: false), '').replaceAll(RegExp(r'\s+'), ' ').trim();
                            if (_activeBhkFilter != null) {
                              _searchController.text = cleanText.isNotEmpty ? '$cleanText $_activeBhkFilter' : _activeBhkFilter!;
                            } else {
                              _searchController.text = cleanText;
                            }
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected ? CRMColors.primaryOf(context) : CRMColors.primaryOf(context).withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? CRMColors.primaryOf(context) : CRMColors.primaryOf(context).withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          bhk,
                          style: TextStyle(
                            color: isSelected ? Colors.white : CRMColors.textOf(context),
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabChoice(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? CRMColors.primaryOf(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : CRMColors.textOf(context),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildResultsContextBar(int totalCount, String locationText) {
    final categoryLabel = _activeCategoryTab == 'All' ? '' : '$_activeCategoryTab ';
    final bhkLabel = _activeBhkFilter != null ? '$_activeBhkFilter ' : '';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing 1 - $totalCount of $totalCount',
                    style: TextStyle(color: CRMColors.textSecondaryOf(context), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Row(
                    children: [
                      Text('Sort by: ', style: TextStyle(color: CRMColors.textSecondaryOf(context), fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: CRMColors.cardBgOf(context),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.6)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _selectedPriceSort,
                            isDense: true,
                            style: TextStyle(color: CRMColors.textOf(context), fontSize: 12, fontWeight: FontWeight.w600),
                            items: const [
                              DropdownMenuItem(value: null, child: Text('Relevance')),
                              DropdownMenuItem(value: 'l2h', child: Text('Price: Low to High')),
                              DropdownMenuItem(value: 'h2l', child: Text('Price: High to Low')),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedPriceSort = val;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '$bhkLabel${categoryLabel}Property for $_activeListingTab in $locationText',
                style: TextStyle(color: CRMColors.textOf(context), fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Showing 1 - $totalCount of $totalCount',
                    style: TextStyle(color: CRMColors.textSecondaryOf(context), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$bhkLabel${categoryLabel}Property for $_activeListingTab in $locationText',
                    style: TextStyle(color: CRMColors.textOf(context), fontSize: 16.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text('Sort by: ', style: TextStyle(color: CRMColors.textSecondaryOf(context), fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: CRMColors.cardBgOf(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.6)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedPriceSort,
                      isDense: true,
                      style: TextStyle(color: CRMColors.textOf(context), fontSize: 12.5, fontWeight: FontWeight.w600),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Relevance')),
                        DropdownMenuItem(value: 'l2h', child: Text('Price: Low to High')),
                        DropdownMenuItem(value: 'h2l', child: Text('Price: High to Low')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedPriceSort = val;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildHousingCard(PropertyModel p, UserModel? currentUser, PropertyMetadataModel? metadata) {
    final catNameLower = p.categoryName.toLowerCase();
    final propTypeNameLower = p.propertyTypeName.toLowerCase();
    final isCommercialOrLand = catNameLower.contains('commercial') ||
        catNameLower.contains('industrial') ||
        catNameLower.contains('land') ||
        catNameLower.contains('plot') ||
        propTypeNameLower.contains('office') ||
        propTypeNameLower.contains('showroom') ||
        propTypeNameLower.contains('shop') ||
        propTypeNameLower.contains('warehouse') ||
        propTypeNameLower.contains('factory');

    final bhkText = isCommercialOrLand
        ? (p.propertyTypeName.isNotEmpty ? p.propertyTypeName : p.categoryName)
        : (p.configurationName ?? "${p.bedrooms} BHK");
    final isRent = p.listingTypeName.toLowerCase().contains('rent');
    final priceStr = p.price >= 100000
        ? '₹ ${(p.price / 100000).toStringAsFixed(2)} L'
        : '₹ ${p.price.toStringAsFixed(0)}';
    final priceLabel = isRent ? '$priceStr /month' : priceStr;

    final locationFull = [
      if (p.areaName.isNotEmpty) p.areaName,
      if (p.cityName.isNotEmpty && !p.areaName.contains(p.cityName)) p.cityName,
    ].join(', ');

    final hasImages = p.images.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: CRMCard(
        padding: EdgeInsets.zero,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 650;

            Widget imageSection = Container(
              width: isNarrow ? double.infinity : 280,
              height: isNarrow ? 210 : 200,
              decoration: BoxDecoration(
                color: CRMColors.backgroundOf(context),
                borderRadius: isNarrow
                    ? const BorderRadius.vertical(top: Radius.circular(12))
                    : const BorderRadius.horizontal(left: Radius.circular(12)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImages)
                    _PropertyImageSlider(
                        images: p.images,
                        onTap: () async {
                          await showCRMPropertyDrawer(context, p);
                          _loadShortlistedIds();
                        })
                  else
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.apartment_rounded, size: 40, color: CRMColors.primaryOf(context).withOpacity(0.3)),
                          const SizedBox(height: 4),
                          Text('NO PHOTOS', style: TextStyle(color: CRMColors.textMutedOf(context), fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),

                  // Verified Badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: CRMColors.success,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 12, color: Colors.white),
                          SizedBox(width: 3),
                          Text('Verified', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),

                  // Photo Count Badge (1/8)
                  if (hasImages)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '1/${p.images.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            );

            final ownerDisplayName = p.ownerName.isNotEmpty
                ? p.ownerName
                : (p.createdByName.isNotEmpty ? p.createdByName : "PROPKART ADMIN");
            final initialsPrefix = _getInitials(ownerDisplayName);
            final isShortlisted = _shortlistedPropertyIds.contains(p.id);

            Widget detailsSection = Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Owner / Agent Header Pill
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: CRMColors.primaryOf(context).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$initialsPrefix ${ownerDisplayName.toUpperCase()}',
                              style: TextStyle(color: CRMColors.primaryOf(context), fontSize: 10.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text('ID: ${p.propertyCode}', style: TextStyle(color: CRMColors.textMutedOf(context), fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Property Title
                      Text(
                        'Ready to use $bhkText ${p.listingTypeName} in $locationFull',
                        style: TextStyle(color: CRMColors.textOf(context), fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),

                      // Key Metrics Row (Price, Available Date, Area, Floor) - Only show available fields!
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(priceLabel, style: TextStyle(color: CRMColors.textOf(context), fontSize: 17, fontWeight: FontWeight.bold)),
                              Text(isRent ? 'Monthly rent' : 'Total Price', style: TextStyle(color: CRMColors.textMutedOf(context), fontSize: 10.5)),
                            ],
                          ),
                          if (p.possessionDate != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(DateFormat('dd/MM/yyyy').format(p.possessionDate!), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                Text('Available From', style: TextStyle(color: CRMColors.textMutedOf(context), fontSize: 10.5)),
                              ],
                            ),
                          if ((p.superBuiltupArea != null && p.superBuiltupArea! > 0) || (p.carpetArea != null && p.carpetArea! > 0))
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (p.superBuiltupArea != null && p.superBuiltupArea! > 0)
                                      ? '${p.superBuiltupArea!.toStringAsFixed(0)} Sq.Ft'
                                      : '${p.carpetArea!.toStringAsFixed(0)} Sq.Ft',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  (p.superBuiltupArea != null && p.superBuiltupArea! > 0) ? 'Built Up Area' : 'Carpet Area',
                                  style: TextStyle(color: CRMColors.textMutedOf(context), fontSize: 10.5),
                                ),
                              ],
                            ),
                          if ((p.floorNo != null && p.floorNo! > 0) || p.bedrooms > 0 || (p.configurationName != null && p.configurationName!.isNotEmpty))
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (p.floorNo != null && p.floorNo! > 0)
                                      ? ((p.totalFloor != null && p.totalFloor! > 0) ? '${p.floorNo}th / ${p.totalFloor} Flr' : 'Floor ${p.floorNo}')
                                      : (p.configurationName ?? bhkText),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  (p.floorNo != null && p.floorNo! > 0) ? 'Floor / BHK' : 'Config',
                                  style: TextStyle(color: CRMColors.textMutedOf(context), fontSize: 10.5),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Key Amenities Chips - Only show if non-empty
                      if (p.amenities.isNotEmpty)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Amenities: ', style: TextStyle(color: CRMColors.textMutedOf(context), fontSize: 11.5, fontWeight: FontWeight.w500)),
                            Expanded(
                              child: Text(
                                p.amenities.join(' • '),
                                style: TextStyle(color: CRMColors.textOf(context), fontSize: 11.5, fontWeight: FontWeight.w500),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Bottom Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _getUpdatedTimeText(p),
                        style: TextStyle(color: CRMColors.textMutedOf(context), fontSize: 11),
                      ),
                      Row(
                        children: [
                          Container(
                            height: 36,
                            width: 36,
                            decoration: BoxDecoration(
                              color: CRMColors.backgroundOf(context),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isShortlisted
                                    ? Colors.red.withOpacity(0.5)
                                    : CRMColors.borderOf(context).withOpacity(0.6),
                              ),
                            ),
                            child: IconButton(
                              icon: Icon(
                                isShortlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                size: 18,
                                color: isShortlisted ? Colors.red : CRMColors.textMutedOf(context),
                              ),
                              padding: EdgeInsets.zero,
                              onPressed: () => _toggleShortlist(p.id),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CRMColors.primaryOf(context),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            ),
                            onPressed: () async {
                              await showCRMPropertyDrawer(context, p);
                              _loadShortlistedIds();
                            },
                            child: const Text('Contact / View', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  imageSection,
                  detailsSection,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                imageSection,
                Expanded(child: detailsSection),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PropertyImageSlider extends StatelessWidget {
  final List<String> images;
  final VoidCallback onTap;

  const _PropertyImageSlider({required this.images, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();
    return GestureDetector(
      onTap: onTap,
      child: CrmNetworkImage(
        url: images.first,
        fit: BoxFit.cover,
      ),
    );
  }
}
