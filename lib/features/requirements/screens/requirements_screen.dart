import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/theme/theme_manager.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/widgets/drawers.dart';
import '../../../core/design_system/widgets/form/crm_multi_select_dropdown.dart';
import '../bloc/requirements_bloc.dart';
import '../models/requirement_model.dart';
import '../repository/requirements_repository.dart';
import 'add_edit_requirement_screen.dart';
import '../../properties/repository/properties_repository.dart';
import '../../properties/services/properties_service.dart';
import '../../properties/models/property_model.dart';
import '../../../core/storage/local_repositories.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/tokens/app_motion.dart';
import '../../../core/design_system/tokens/app_shadows.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/crm_page_header.dart';
import '../../../core/design_system/widgets/data_table.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../dashboard/repository/dashboard_repository.dart';
import '../../dashboard/models/dashboard_summary.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/utils/budget_formatter.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/models/user_model.dart';
import '../../users/bloc/users_bloc.dart';
import '../../users/models/user_model.dart' as users_model;
import '../../../core/config/app_config.dart';
import 'package:collection/collection.dart';
import 'package:propkart/core/storage/repository_coordinator.dart';
import 'package:propkart/core/storage/model_mappers.dart';
import 'package:propkart/core/storage/isar_collections.dart';
import '../../../core/utils/file_downloader.dart';
import '../utils/property_share_pdf.dart';
import '../../../core/api/cloudinary_uploader.dart';

/// WhatsApp brand green — kept as a distinct constant for brand recognition.
const Color kWhatsAppGreen = Color(0xFF25D366);

class RequirementsScreen extends StatefulWidget {
  const RequirementsScreen({super.key});

  @override
  State<RequirementsScreen> createState() => _RequirementsScreenState();
}

class _RequirementsScreenState extends State<RequirementsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _wonSearchController = TextEditingController();
  String? _wonCategoryId;
  String? _wonPropertyTypeId;
  final List<String> _wonConfigurationIds = [];
  final List<String> _selectedConfigIds = [];
  String? _selectedCategoryId;
  String _selectedStatus = "All";
  String _selectedReadiness = "All";
  String get _activeListingTab => ThemeManager().isRentMode ? 'Rent' : 'Re-Sale';
  set _activeListingTab(String value) {
    ThemeManager().setRentMode(value == 'Rent');
  }
  String _activeMainTab = "Requirements"; // "Requirements" or "Follow-ups"
  DateTime? _reqFollowupDateFilter = DateTime.now();
  int _currentPage = 1;
  int _requirementsPerPage = 10;
  int _currentFollowupPage = 1;
  int _followupsPerPage = 10;
  final PropertiesRepository _propertiesRepository = PropertiesRepository();
  List<PropertyModel>? _propertiesForMatches;
  PropertyMetadataModel? _metadata;
  bool _isLoadingMetadata = true;
  bool _hasAutoOpenedAdd = false;
  bool _isMobileFiltersExpanded = false;

  @override
  void initState() {
    super.initState();
    // Metadata load triggers the first fetch once listing types are available.
    // Avoid a duplicate empty fetch before metadata arrives.
    _loadMetadata();
    context.read<UsersBloc>().add(const FetchUsers());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final action = GoRouterState.of(context).uri.queryParameters['action'];
        if (action == 'add' && !_hasAutoOpenedAdd) {
          _hasAutoOpenedAdd = true;
          _showAddEditDialog();
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _wonSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadPropertiesForMatches() async {
    try {
      final properties = await _propertiesRepository.getProperties();
      if (mounted) {
        setState(() {
          _propertiesForMatches = properties;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadMetadata() async {
    _loadPropertiesForMatches();
    try {
      final meta = await _propertiesRepository.getPropertyMetadata();
      if (!mounted) return;
      setState(() {
        _metadata = meta;
        _isLoadingMetadata = false;
      });
      _triggerFetch();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMetadata = false;
      });
      _triggerFetch();
    }
  }

  void _triggerFetch() {
    String? listingTypeId;
    if (_metadata != null && _metadata!.listingTypes.isNotEmpty) {
      try {
        final matched = _metadata!.listingTypes.firstWhere(
          (lt) => lt.name.toLowerCase().contains(_activeListingTab == 'Rent' ? 'rent' : 'sale'),
        );
        listingTypeId = matched.id;
      } catch (_) {}
    }

    final selectedCat = _metadata?.categories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => LookupItem(id: '', name: ''),
    );
    final catName = selectedCat?.name.toLowerCase() ?? '';
    final isPropertyTypeFilter = catName.contains('commercial') ||
        catName.contains('land') ||
        catName.contains('plot') ||
        catName.contains('industrial');

    String? configId;
    String? propTypeId;
    if (_activeMainTab != 'My Won') {
      if (isPropertyTypeFilter) {
        propTypeId = _selectedConfigIds.isNotEmpty ? _selectedConfigIds.first : null;
      } else {
        configId = _selectedConfigIds.isNotEmpty ? _selectedConfigIds.first : null;
      }
    }

    // My Won must load all pipeline statuses (filter Won client-side).
    // Using the Requirements tab status filter here hid Won rows after updates.
    final statusForFetch = _activeMainTab == 'My Won' ? 'All' : _selectedStatus;

    context.read<RequirementsBloc>().add(
      FetchRequirementsEvent(
        search: null,
        configurationId: configId,
        propertyTypeId: propTypeId,
        status: statusForFetch,
        listingTypeId: listingTypeId,
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedConfigIds.clear();
      _selectedCategoryId = null;
      _selectedStatus = "All";
      _selectedReadiness = "All";
      _activeListingTab = "Rent";
      _currentPage = 1;
    });
    _triggerFetch();
  }

  void _showAddEditDialog([RequirementModel? req]) {
    showDialog(
      context: context,
      builder: (dialogContext) => AddEditRequirementScreen(
        requirement: req,
        onSaved: () {
          _triggerFetch();
        },
      ),
    );
  }

  void _showDeleteConfirmDialog(RequirementModel req) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: CRMColors.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.m)),
          title: Text("Delete Requirement", style: CRMTypography.sectionTitle.copyWith(color: CRMColors.text)),
          content: Text(
            "Are you sure you want to delete the requirement for ${req.clientName}?",
            style: CRMTypography.body.copyWith(color: CRMColors.textSecondary),
          ),
          actions: [
            CRMButton(
              label: "Cancel",
              variant: CRMButtonVariant.outline,
              onPressed: () => Navigator.pop(dialogContext),
            ),
            const SizedBox(width: CRMSpacing.xs),
            CRMButton(
              label: "Delete",
              variant: CRMButtonVariant.danger,
              onPressed: () async {
                if (req.status == 'Won' || req.status == 'Closed') {
                  await _revertWonPropertiesToAvailable(req);
                }
                if (dialogContext.mounted) {
                  context.read<RequirementsBloc>().add(DeleteRequirementEvent(req.id));
                  Navigator.pop(dialogContext);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showMatchesDrawer(RequirementModel req) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _CRMPropertyMatchesDrawer(requirement: req);
      },
    );
  }

  bool _isValidStatusTransition(String currentStatus, String newStatus) {
    return true;
  }

  Future<void> _revertWonPropertiesToAvailable(RequirementModel req) async {
    try {
      final propertiesRepository = PropertiesRepository();
      final propertiesService = PropertiesService();
      final properties = await propertiesRepository.getProperties();

      const availableStatusId = '09521e45-e731-4517-8129-1866f0991ee8';

      for (final p in properties) {
        final currentStatus = (p.propertyStatusName ?? '').toLowerCase();
        final isRentedOrSold = currentStatus.contains('rented') || currentStatus.contains('sold');

        if (isRentedOrSold) {
          final clientName = await PropertyDealClientStore.getClientName(p.id, property: p);
          if (clientName != null &&
              clientName.trim().toLowerCase() == req.clientName.trim().toLowerCase()) {
            try {
              await propertiesService.updateProperty(p.id, {
                'property_status_id': availableStatusId,
              });
              await PropertyDealClientStore.removeClientName(p.id);
            } catch (e) {
              debugPrint("Error reverting property status to available: $e");
            }
          }
        }
      }

      RepositoryCoordinator().refreshProperties();
    } catch (e) {
      debugPrint("Error in _revertWonPropertiesToAvailable: $e");
    }
  }

  void _changeStatus(RequirementModel req, String newStatus) async {
    final authState = context.read<AuthBloc>().state;
    final currentUser = authState is Authenticated ? authState.user : null;
    if (_isLeadTransferredAway(req, currentUser)) return;
    if (newStatus == req.status) return;

    if (req.status == 'Won' && newStatus != 'Won') {
      await _revertWonPropertiesToAvailable(req);
    }

    if (!_isValidStatusTransition(req.status, newStatus)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Cannot skip pipeline stages from '${req.status}' to '$newStatus'."),
          backgroundColor: CRMColors.warning,
        ),
      );
      return;
    }

    if (newStatus == 'Follow-up') {
      showDialog(
        context: context,
        builder: (dialogContext) => RequirementStepperDialog(
          requirement: req,
          initialStep: 1,
          updateStatusOnSave: true,
          onSaved: () {
            _triggerFetch();
          },
        ),
      );
    } else if (newStatus == 'Site Visit') {
      showDialog(
        context: context,
        builder: (dialogContext) => RequirementStepperDialog(
          requirement: req,
          initialStep: 1,
          updateStatusOnSave: true,
          isSiteVisit: true,
          onSaved: () {
            _triggerFetch();
          },
        ),
      );
    } else if (newStatus == 'Won') {
      showDialog(
        context: context,
        builder: (dialogContext) => RequirementWinPropertySelectionDialog(
          requirement: req,
          onConfirmed: (List<PropertyModel> selectedProperties) async {
            context.read<RequirementsBloc>().add(
              UpdateRequirementEvent(req.copyWith(status: 'Won')),
            );

            final selectedIds = selectedProperties.map((p) => p.id).toList();
            await PropertyDealClientStore.setWonRequirementProperties(req.id, selectedIds);

            final propertiesService = PropertiesService();
            for (final p in selectedProperties) {
              await PropertyDealClientStore.setClientName(p.id, req.clientName);

              final listingType = p.listingTypeName.toLowerCase();
              final isRent = listingType.contains('rent') ||
                  (LookupLocalRepository.getLookupNameSync(p.listingTypeId)?.toLowerCase().contains('rent') ?? false) ||
                  p.listingTypeId == '1c1ccfc1-d318-4b66-9a43-c551532d1802';

              final targetStatusId = isRent
                  ? '7c1d9611-8cad-4058-a9fa-3d68b8adb6f6' // Rented Out
                  : '33fa8cf3-910d-4f0b-9142-8862974311ab'; // Sold Out

              try {
                await propertiesService.updateProperty(p.id, {
                  'property_status_id': targetStatusId,
                });
              } catch (e) {
                debugPrint("Error updating property status on win: $e");
              }
            }

            RepositoryCoordinator().refreshProperties();
            _triggerFetch();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Requirement marked as Won and property status updated!'),
                  backgroundColor: CRMColors.success,
                ),
              );
            }
          },
        ),
      );
    } else {
      context.read<RequirementsBloc>().add(
        UpdateRequirementEvent(req.copyWith(status: newStatus)),
      );
    }
  }

  void _showAddAnotherRequirementDialog(RequirementModel existing) {
    final prefilled = RequirementModel(
      id: '',
      clientName: existing.clientName,
      clientMobile: existing.clientMobile,
      categoryId: '',
      categoryName: '',
      propertyTypeId: '',
      propertyTypeName: '',
      minBudget: 0,
      maxBudget: 0,
      areaIds: [],
      areaNames: [],
      status: 'Not Started',
      createdAt: DateTime.now(),
    );
    showDialog(
      context: context,
      builder: (dialogContext) => AddEditRequirementScreen(
        requirement: prefilled,
        onSaved: () {
          _triggerFetch();
        },
      ),
    );
  }

  void _shareRequirement(RequirementModel req) {
    final String shareText = "Customer: ${req.clientName}\n"
        "Requirement Code: ${req.requirementCode}\n"
        "Specs: ${req.propertyTypeName} (${req.configurationName ?? 'N/A'})\n"
        "Budget: ${BudgetFormatter.format(req.minBudget)} - ${BudgetFormatter.format(req.maxBudget)}\n"
        "Target Areas: ${req.areaNames.join(', ')}";
        
    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Requirement details copied to clipboard!"),
        backgroundColor: CRMColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocListener<RequirementsBloc, RequirementsState>(
        listener: (context, state) {
          if (state is RequirementsSuccess) {
            final msg = _activeMainTab == 'My Won'
                ? '${state.message} (My Won only shows Won items.)'
                : state.message;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg),
                backgroundColor: CRMColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            _triggerFetch();
          } else if (state is RequirementsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error: ${state.message}"),
                backgroundColor: CRMColors.danger,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(CRMSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              _buildPageHeader(),
              const SizedBox(height: CRMSpacing.m),

              // Main View Tabs (Requirements vs Follow-ups vs My Won)
              Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: CRMColors.cardBg,
                  borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                  border: Border.all(color: CRMColors.border),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMainViewTabButton('Requirements'),
                      const SizedBox(width: 4),
                      _buildMainViewTabButton('Follow-ups'),
                      const SizedBox(width: 4),
                      _buildMainViewTabButton('My Won'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: CRMSpacing.l),

              if (_activeMainTab == 'Requirements') ...[
                // Filters & Search Card
                LayoutBuilder(
                  builder: (context, constraints) {
                    final bool isMobile = constraints.maxWidth < 600;
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
                                    child: _buildSearchAndFiltersCard(),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      );
                    } else {
                      return _buildSearchAndFiltersCard();
                    }
                  },
                ),
                const SizedBox(height: CRMSpacing.l),

                // Data Table
                _buildRequirementsTable(),
              ] else if (_activeMainTab == 'My Won') ...[
                _buildMyWonFiltersAndTable(),
              ] else ...[
                // Follow-ups View
                _buildFollowupsView(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    final listingToggle = Align(
      alignment: Alignment.centerLeft,
      child: Container(
        height: 44,
        width: 240,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: CRMColors.backgroundOf(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: CRMColors.borderOf(context).withValues(alpha: 0.6), width: 1.0),
        ),
        child: Row(
          children: [
            Expanded(child: _buildListingTabButton('Rent')),
            const SizedBox(width: 4),
            Expanded(child: _buildListingTabButton('Re-Sale')),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CRMPageHeader(
          eyebrow: '',
          title: 'Leads Tracker',
          benefit:
              'Capture buyer demand and run listing matches that convert faster',
          trailing: CRMButton(
            label: 'Add Requirement',
            prefixIcon: Icons.add_rounded,
            onPressed: () => _showAddEditDialog(),
          ),
        ),
        const SizedBox(height: CRMSpacing.s),
        listingToggle,
      ],
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
          color: _isMobileFiltersExpanded ? CRMColors.primary : CRMColors.cardBgOf(context),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: _isMobileFiltersExpanded ? CRMColors.primary : CRMColors.borderOf(context).withOpacity(0.6),
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

  Widget _buildSearchAndFiltersCard() {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    String configDropdownLabel = 'Configuration';
    final selectedCat = _metadata?.categories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => LookupItem(id: '', name: ''),
    );
    final catName = selectedCat?.name.toLowerCase() ?? '';
    List<LookupItem> specLookupItems = [];

    if (catName.contains('commercial')) {
      configDropdownLabel = 'Property Type';
      
      var filtered = _metadata?.types.where((t) => t.categoryId == _selectedCategoryId).toList() ?? [];
      if (filtered.isEmpty && _metadata != null) {
        filtered = _metadata!.types.where((t) {
          final n = t.name.toLowerCase();
          return n.contains('office') || n.contains('shop') || n.contains('showroom') || n.contains('commercial');
        }).toList();
      }
      if (filtered.isEmpty && _metadata != null) {
        filtered = _metadata!.types;
      }
      specLookupItems = filtered;
    } else if (catName.contains('land') || catName.contains('plot')) {
      configDropdownLabel = 'Property Type';
      
      var filtered = _metadata?.types.where((t) => t.categoryId == _selectedCategoryId).toList() ?? [];
      if (filtered.isEmpty && _metadata != null) {
        filtered = _metadata!.types.where((t) {
          final n = t.name.toLowerCase();
          return n.contains('plot') || n.contains('land');
        }).toList();
      }
      if (filtered.isEmpty && _metadata != null) {
        filtered = _metadata!.types;
      }
      specLookupItems = filtered;
    } else if (catName.contains('industrial')) {
      configDropdownLabel = 'Property Type';
      
      var filtered = _metadata?.types.where((t) => t.categoryId == _selectedCategoryId).toList() ?? [];
      if (filtered.isEmpty && _metadata != null) {
        filtered = _metadata!.types.where((t) {
          final n = t.name.toLowerCase();
          return n.contains('warehouse') || n.contains('shed') || n.contains('industrial');
        }).toList();
      }
      if (filtered.isEmpty && _metadata != null) {
        filtered = _metadata!.types;
      }
      specLookupItems = filtered;
    } else {
      configDropdownLabel = 'Configuration';
      
      var filtered = _metadata?.configurations.where((c) => _selectedCategoryId == null || c.categoryId == _selectedCategoryId).toList() ?? [];
      if (filtered.isEmpty && _metadata != null) {
        filtered = _metadata!.configurations;
      }
      specLookupItems = filtered;
    }

    return CRMCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: CRMTypography.body.copyWith(color: CRMColors.text),
                  decoration: InputDecoration(
                    hintText: 'Search by client name, mobile, specs, remarks...',
                    hintStyle: CRMTypography.body.copyWith(color: CRMColors.textMuted),
                    prefixIcon: Icon(Icons.search_rounded, color: CRMColors.textMuted),
                    filled: true,
                    fillColor: CRMColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                      borderSide: BorderSide(color: CRMColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                      borderSide: BorderSide(color: CRMColors.border),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: CRMSpacing.s),
              CRMButton(label: "Search", onPressed: _triggerFetch),
            ],
          ),
          const SizedBox(height: CRMSpacing.m),
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDropdownFilter<String?>(
                      label: 'Category',
                      value: _selectedCategoryId,
                      items: [
                        const DropdownMenuItem(value: null, child: Text("All Categories")),
                        ...?_metadata?.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                      ],
                      isMobile: isMobile,
                      onChanged: (val) {
                        setState(() {
                          _selectedCategoryId = val;
                          _selectedConfigIds.clear();
                        });
                        _triggerFetch();
                      },
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    CRMMultiSelectDropdown(
                      label: configDropdownLabel,
                      selectedIds: _selectedConfigIds,
                      items: specLookupItems,
                      onChanged: (vals) {
                        setState(() {});
                        _triggerFetch();
                      },
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    _buildDropdownFilter(
                      label: 'Status',
                      value: _selectedStatus,
                      items: const [
                        DropdownMenuItem(value: "All", child: Text("All")),
                        DropdownMenuItem(value: "Not Started", child: Text("Not Started")),
                        DropdownMenuItem(value: "Follow-up", child: Text("Follow-up")),
                        DropdownMenuItem(value: "Interested", child: Text("Interested")),
                        DropdownMenuItem(value: "Site Visit", child: Text("Site Visit Sche.")),
                        DropdownMenuItem(value: "Site Visit Done", child: Text("Site Visit Done")),
                        DropdownMenuItem(value: "Negotiation", child: Text("Negotiation")),
                        DropdownMenuItem(value: "Won", child: Text("Won")),
                        DropdownMenuItem(value: "Bin", child: Text("Bin")),
                        DropdownMenuItem(value: "Not Interested", child: Text("Not Interested")),
                      ],
                      isMobile: isMobile,
                      onChanged: (val) {
                        setState(() => _selectedStatus = val ?? "All");
                        _triggerFetch();
                      },
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    CRMButton(
                      label: "Clear Filters",
                      variant: CRMButtonVariant.outline,
                      onPressed: _clearFilters,
                    ),
                  ],
                )
              : Wrap(
                  spacing: CRMSpacing.m,
                  runSpacing: CRMSpacing.s,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildDropdownFilter<String?>(
                      label: 'Category',
                      value: _selectedCategoryId,
                      items: [
                        const DropdownMenuItem(value: null, child: Text("All Categories")),
                        ...?_metadata?.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                      ],
                      isMobile: isMobile,
                      onChanged: (val) {
                        setState(() {
                          _selectedCategoryId = val;
                          _selectedConfigIds.clear();
                        });
                        _triggerFetch();
                      },
                    ),
                    SizedBox(
                      width: isMobile ? double.infinity : 200,
                      child: CRMMultiSelectDropdown(
                        label: configDropdownLabel,
                        selectedIds: _selectedConfigIds,
                        items: specLookupItems,
                        onChanged: (vals) {
                          setState(() {});
                          _triggerFetch();
                        },
                      ),
                    ),
                    _buildDropdownFilter(
                      label: 'Status',
                      value: _selectedStatus,
                      items: const [
                        DropdownMenuItem(value: "All", child: Text("All")),
                        DropdownMenuItem(value: "Not Started", child: Text("Not Started")),
                        DropdownMenuItem(value: "Follow-up", child: Text("Follow-up")),
                        DropdownMenuItem(value: "Interested", child: Text("Interested")),
                        DropdownMenuItem(value: "Site Visit", child: Text("Site Visit Sche.")),
                        DropdownMenuItem(value: "Site Visit Done", child: Text("Site Visit Done")),
                        DropdownMenuItem(value: "Negotiation", child: Text("Negotiation")),
                        DropdownMenuItem(value: "Won", child: Text("Won")),
                        DropdownMenuItem(value: "Bin", child: Text("Bin")),
                        DropdownMenuItem(value: "Not Interested", child: Text("Not Interested")),
                      ],
                      isMobile: isMobile,
                      onChanged: (val) {
                        setState(() => _selectedStatus = val ?? "All");
                        _triggerFetch();
                      },
                    ),
                    CRMButton(
                      label: "Clear Filters",
                      variant: CRMButtonVariant.outline,
                      onPressed: _clearFilters,
                    ),
                  ],
                ),
          ],
        ),
      );
  }

  Widget _buildListingTabButton(String label) {
    final isSelected = _activeListingTab == label;
    final accent =
        label == 'Rent' ? CRMColors.rentAccent : CRMColors.resaleAccent;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeListingTab = label;
          _currentPage = 1;
        });
        _triggerFetch();
      },
      child: AnimatedContainer(
        duration: CRMMotion.fast,
        curve: CRMMotion.easeInOut,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: CRMSpacing.xs),
        decoration: BoxDecoration(
          color: isSelected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: CRMTypography.bodyMedium.copyWith(
            color: isSelected
                ? (label == 'Re-Sale' && CRMColors.isDark ? const Color(0xFF111827) : Colors.white)
                : CRMColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownFilter<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    bool isMobile = false,
  }) {
    final bool hasValue = value == null || items.any((item) => item.value == value);
    final T? safeValue = hasValue ? value : null;

    return SizedBox(
      width: isMobile ? double.infinity : 200,
      height: isMobile ? 54 : 48,
      child: DropdownButtonFormField<T>(
        value: safeValue,
        isExpanded: true,
        dropdownColor: CRMColors.cardBgOf(context),
        style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
          contentPadding: EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: isMobile ? 12 : 8),
          filled: true,
          fillColor: CRMColors.backgroundOf(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CRMBorderRadius.s),
            borderSide: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.6)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CRMBorderRadius.s),
            borderSide: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CRMBorderRadius.s),
            borderSide: BorderSide(color: CRMColors.primaryOf(context), width: 1.5),
          ),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  String _getSalesmanName(RequirementModel req, UserModel? currentUser) {
    if (req.creatorName != null && req.creatorName!.isNotEmpty) {
      return req.creatorName!;
    }
    if (req.assigneeName != null && req.assigneeName!.isNotEmpty) {
      return req.assigneeName!;
    }
    
    if (currentUser != null && req.adminId == currentUser.id) {
      return currentUser.fullName;
    }
    
    try {
      final usersState = context.read<UsersBloc>().state;
      if (usersState is UsersLoaded) {
        final match = usersState.users.firstWhere(
          (u) => u.id == req.adminId,
          orElse: () => const users_model.UserModel(id: '', roleId: '', roleName: '', fullName: '', email: '', isActive: false),
        );
        if (match.fullName.isNotEmpty) {
          return match.fullName;
        }
      }
    } catch (_) {}
    return 'N/A';
  }

  Widget _buildCustomTooltip({
    required String message,
    required Widget child,
    required bool isRent,
    double maxWidth = 340.0,
  }) {
    return Tooltip(
      richMessage: WidgetSpan(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: CRMColors.isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (isRent ? CRMColors.info : CRMColors.primary).withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSpecsConfigCell(RequirementModel req) {
    final configStr = (req.configurationName != null && req.configurationName!.isNotEmpty)
        ? req.configurationName!
        : '-';
    final specsText = '${req.propertyTypeName} ($configStr)';
    final listingLabel = getListingTypeLabel(req);
    final isRent = listingLabel == 'Rent';

    final tooltipMessage = 'Property Type(s): ${req.propertyTypeName}\nConfiguration(s): $configStr\nListing Type: $listingLabel';

    return _buildCustomTooltip(
      message: tooltipMessage,
      isRent: isRent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 135),
            child: Text(
              specsText,
              style: CRMTypography.body.copyWith(color: CRMColors.text),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.xxs, vertical: 2),
            decoration: BoxDecoration(
              color: (isRent ? CRMColors.info : CRMColors.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(CRMBorderRadius.xs),
            ),
            child: Text(
              listingLabel,
              style: CRMTypography.captionBold.copyWith(
                fontSize: 10,
                color: isRent ? CRMColors.info : CRMColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetAreasCell(RequirementModel req) {
    final areasText = req.areaNames.isNotEmpty ? req.areaNames.join(', ') : 'Any Area';
    final listingLabel = getListingTypeLabel(req);
    final isRent = listingLabel == 'Rent';

    final tooltipMessage = 'Target Area(s):\n$areasText';

    return SizedBox(
      width: 125,
      child: _buildCustomTooltip(
        message: tooltipMessage,
        isRent: isRent,
        child: Text(
          areasText,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: CRMTypography.body.copyWith(color: CRMColors.textSecondary),
        ),
      ),
    );
  }

  static bool _isRequirementPropertyMatch(PropertyModel p, RequirementModel req) {
    // 1. Status Match
    final statusName = p.propertyStatusName.toLowerCase();
    final statusActive = statusName == 'available' || statusName.contains('available') || statusName.isEmpty;
    if (!statusActive) return false;

    // 2. Listing Type Match (Rent vs Re-Sale)
    final reqListing = (req.listingTypeName ?? '').toLowerCase();
    final propListing = (p.listingTypeName).toLowerCase();
    bool listingTypeMatch = true;
    if (reqListing.isNotEmpty && propListing.isNotEmpty) {
      final isReqRent = reqListing.contains('rent');
      final isPropRent = propListing.contains('rent');
      listingTypeMatch = (isReqRent == isPropRent);
    } else if (req.listingTypeId != null && req.listingTypeId!.isNotEmpty && p.listingTypeId.isNotEmpty) {
      listingTypeMatch = (p.listingTypeId == req.listingTypeId);
    }
    if (!listingTypeMatch) return false;

    // 3. Category Match
    if (req.categoryId.isNotEmpty && p.categoryId.isNotEmpty) {
      if (p.categoryId != req.categoryId) return false;
    }

    // 4. Property Type Match (Supports multiple selected property types)
    if (req.propertyTypeIds.isNotEmpty) {
      bool typeMatch = req.propertyTypeIds.contains(p.propertyTypeId);
      if (!typeMatch && req.propertyTypeName.isNotEmpty && p.propertyTypeName.isNotEmpty) {
        final pTypeName = p.propertyTypeName.toLowerCase();
        typeMatch = req.propertyTypeName.toLowerCase().split(',').any((t) {
          final trimmed = t.trim();
          return trimmed.isNotEmpty && (pTypeName.contains(trimmed) || trimmed.contains(pTypeName));
        });
      }
      if (!typeMatch) return false;
    } else if (req.propertyTypeId.isNotEmpty && p.propertyTypeId.isNotEmpty) {
      if (p.propertyTypeId != req.propertyTypeId) {
        final pTypeName = p.propertyTypeName.toLowerCase();
        final reqTypeName = req.propertyTypeName.toLowerCase();
        if (!reqTypeName.contains(pTypeName) && !pTypeName.contains(reqTypeName)) return false;
      }
    }

    // 5. Configuration Match (Supports multiple selected configurations e.g. 2 BHK, 3 BHK, 4 BHK)
    if (req.configurationIds.isNotEmpty) {
      bool configMatch = p.configurationId != null && req.configurationIds.contains(p.configurationId);
      if (!configMatch && req.configurationName != null && req.configurationName!.isNotEmpty && p.configurationName != null && p.configurationName!.isNotEmpty) {
        final pConfigName = p.configurationName!.toLowerCase();
        configMatch = req.configurationName!.toLowerCase().split(',').any((c) {
          final trimmed = c.trim();
          return trimmed.isNotEmpty && (pConfigName.contains(trimmed) || trimmed.contains(pConfigName));
        });
      }
      if (!configMatch) return false;
    } else if (req.configurationId != null && req.configurationId!.isNotEmpty) {
      if (p.configurationId != null && p.configurationId!.isNotEmpty && p.configurationId != req.configurationId) {
        final pConfigName = (p.configurationName ?? '').toLowerCase();
        final reqConfigName = (req.configurationName ?? '').toLowerCase();
        if (pConfigName.isNotEmpty && reqConfigName.isNotEmpty) {
          if (!reqConfigName.contains(pConfigName) && !pConfigName.contains(reqConfigName)) {
            return false;
          }
        }
      }
    }

    // 6. Target Area Match (Matches if property is in ANY ONE of the target areas)
    if (req.areaIds.isNotEmpty) {
      bool areaMatch = req.areaIds.contains(p.areaId);
      if (!areaMatch && req.areaNames.isNotEmpty && p.areaName.isNotEmpty) {
        final pArea = p.areaName.trim().toLowerCase();
        areaMatch = req.areaNames.any((aName) {
          final trimmed = aName.trim().toLowerCase();
          return trimmed.isNotEmpty && (trimmed == pArea || pArea.contains(trimmed) || trimmed.contains(pArea));
        });
      }
      if (!areaMatch) return false;
    }

    // 7. Budget Range Match
    if (req.maxBudget > 0) {
      final minB = req.minBudget > 0 ? req.minBudget : 0.0;
      final maxB = req.maxBudget;
      if (p.price < minB || p.price > maxB) {
        return false;
      }
    }

    return true;
  }

  static Future<bool> _isRequirementPropertyMatchAsync(PropertyModel p, RequirementModel req) async {
    final isWonReq = req.status.toLowerCase() == 'won' || req.status.toLowerCase() == 'closed';

    if (isWonReq) {
      final wonPropertyIds = await PropertyDealClientStore.getWonPropertyIds(req.id);
      if (wonPropertyIds.isNotEmpty) {
        return wonPropertyIds.contains(p.id);
      }

      final clientName = await PropertyDealClientStore.getClientName(p.id, property: p);
      if (clientName != null && clientName.trim().toLowerCase() == req.clientName.trim().toLowerCase()) {
        return true;
      }
      return false;
    }

    return _isRequirementPropertyMatch(p, req);
  }

  Widget _buildAssignToDropdown(RequirementModel req) {
    return BlocBuilder<UsersBloc, UsersState>(
      builder: (context, state) {
        if (state is UsersLoaded) {
          String? currentAssignedTo;
          if (req.assignedTo != null && req.assignedTo!.isNotEmpty) {
            currentAssignedTo = req.assignedTo;
          } else if (req.assignedTo == null && req.createdBy != null && req.createdBy!.isNotEmpty) {
            final creatorUser = state.users.firstWhereOrNull((u) => u.id == req.createdBy);
            if (creatorUser != null) {
              final role = creatorUser.roleName.toLowerCase();
              final isCreatorAdminOrTelecaller = role == 'admin' || role == 'super admin' || role == 'telecaller';
              if (!isCreatorAdminOrTelecaller) {
                currentAssignedTo = req.createdBy;
              }
            } else if (req.creatorName != null && req.creatorName!.isNotEmpty) {
              final creatorMatch = state.users.firstWhereOrNull((u) => u.fullName.toLowerCase() == req.creatorName!.toLowerCase());
              if (creatorMatch != null) {
                final role = creatorMatch.roleName.toLowerCase();
                final isCreatorAdminOrTelecaller = role == 'admin' || role == 'super admin' || role == 'telecaller';
                if (!isCreatorAdminOrTelecaller) {
                  currentAssignedTo = creatorMatch.id;
                }
              }
            }
          }

          final salesmen = state.users.where((u) {
            final role = u.roleName.toLowerCase();
            final isSales = role.contains('sales') || role.contains('executive') || role.contains('telecaller') || role == 'employee';
            final isAssigned = currentAssignedTo != null && u.id == currentAssignedTo;
            return isSales || isAssigned;
          }).toList();

          final bool hasValue = currentAssignedTo != null && salesmen.any((u) => u.id == currentAssignedTo);
          final dropdownValue = hasValue ? currentAssignedTo : null;
          return DropdownButton<String?>(
            value: dropdownValue,
            hint: Text(
              'Assign to',
              style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondaryOf(context)),
            ),
            underline: Container(),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(
                  'Unassigned',
                  style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondaryOf(context)),
                ),
              ),
              ...salesmen.map((u) {
                return DropdownMenuItem<String?>(
                  value: u.id,
                  child: Text(
                    u.fullName,
                    style: CRMTypography.bodyMedium.copyWith(
                      color: CRMColors.textOf(context),
                      fontWeight: u.id == currentAssignedTo ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }),
            ],
            onChanged: (String? newSalesmanId) {
              String? newSalesmanName;
              if (newSalesmanId != null) {
                final u = salesmen.firstWhere((s) => s.id == newSalesmanId);
                newSalesmanName = u.fullName;
              }
              
              context.read<RequirementsBloc>().add(
                UpdateRequirementEvent(
                  req.copyWith(
                    assignedTo: newSalesmanId ?? '',
                    assigneeName: newSalesmanName ?? '',
                  ),
                ),
              );
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(newSalesmanName != null 
                      ? 'Lead assigned to $newSalesmanName successfully.'
                      : 'Lead unassigned successfully.'),
                  backgroundColor: CRMColors.success,
                ),
              );
            },
            icon: Icon(Icons.arrow_drop_down, color: CRMColors.textSecondaryOf(context), size: 18),
            dropdownColor: CRMColors.cardBgOf(context),
          );
        }
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      },
    );
  }

  Widget _buildMobileAssignToDropdown(RequirementModel req) {
    return BlocBuilder<UsersBloc, UsersState>(
      builder: (context, state) {
        if (state is UsersLoaded) {
          String? currentAssignedTo;
          if (req.assignedTo != null && req.assignedTo!.isNotEmpty) {
            currentAssignedTo = req.assignedTo;
          } else if (req.assignedTo == null && req.createdBy != null && req.createdBy!.isNotEmpty) {
            final creatorUser = state.users.firstWhereOrNull((u) => u.id == req.createdBy);
            if (creatorUser != null) {
              final role = creatorUser.roleName.toLowerCase();
              final isCreatorAdminOrTelecaller = role == 'admin' || role == 'super admin' || role == 'telecaller';
              if (!isCreatorAdminOrTelecaller) {
                currentAssignedTo = req.createdBy;
              }
            } else if (req.creatorName != null && req.creatorName!.isNotEmpty) {
              final creatorMatch = state.users.firstWhereOrNull((u) => u.fullName.toLowerCase() == req.creatorName!.toLowerCase());
              if (creatorMatch != null) {
                final role = creatorMatch.roleName.toLowerCase();
                final isCreatorAdminOrTelecaller = role == 'admin' || role == 'super admin' || role == 'telecaller';
                if (!isCreatorAdminOrTelecaller) {
                  currentAssignedTo = creatorMatch.id;
                }
              }
            }
          }

          final salesmen = state.users.where((u) {
            final role = u.roleName.toLowerCase();
            final isSales = role.contains('sales') || role.contains('executive') || role.contains('telecaller') || role == 'employee';
            final isAssigned = currentAssignedTo != null && u.id == currentAssignedTo;
            return isSales || isAssigned;
          }).toList();

          final bool hasValue = currentAssignedTo != null && salesmen.any((u) => u.id == currentAssignedTo);
          final dropdownValue = hasValue ? currentAssignedTo : null;
          return DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: dropdownValue,
              isDense: true,
              isExpanded: true,
              hint: Text(
                'Assign to',
                style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context), fontSize: 11),
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    'Unassigned',
                    style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context), fontSize: 11),
                  ),
                ),
                ...salesmen.map((u) {
                  return DropdownMenuItem<String?>(
                    value: u.id,
                    child: Text(
                      u.fullName,
                      style: CRMTypography.captionBold.copyWith(
                        color: CRMColors.textOf(context),
                        fontWeight: u.id == currentAssignedTo ? FontWeight.bold : FontWeight.normal,
                        fontSize: 11,
                      ),
                    ),
                  );
                }),
              ],
              onChanged: (String? newSalesmanId) {
                String? newSalesmanName;
                if (newSalesmanId != null) {
                  final u = salesmen.firstWhere((s) => s.id == newSalesmanId);
                  newSalesmanName = u.fullName;
                }
                
                context.read<RequirementsBloc>().add(
                  UpdateRequirementEvent(
                    req.copyWith(
                      assignedTo: newSalesmanId ?? '',
                      assigneeName: newSalesmanName ?? '',
                    ),
                  ),
                );
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(newSalesmanName != null 
                        ? 'Lead assigned to $newSalesmanName successfully.'
                        : 'Lead unassigned successfully.'),
                    backgroundColor: CRMColors.success,
                  ),
                );
              },
              icon: Icon(Icons.arrow_drop_down, color: CRMColors.textSecondaryOf(context), size: 14),
              dropdownColor: CRMColors.cardBgOf(context),
            ),
          );
        }
        return const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      },
    );
  }

  bool _hasEditAccess(RequirementModel r, UserModel? currentUser) {
    if (currentUser == null) return false;
    if (currentUser.role == 'Super Admin') return true;
    if (currentUser.role == 'Admin') {
      return r.createdBy == currentUser.id || r.adminId == currentUser.id;
    }
    if (currentUser.role == 'Telecaller') {
      return r.createdBy == currentUser.id || r.adminId == currentUser.adminId;
    }
    if (currentUser.role == 'Sales') {
      if (_isLeadTransferredAway(r, currentUser)) return false;
      return r.createdBy == currentUser.id || r.assignedTo == currentUser.id;
    }
    return false;
  }

  bool _isLeadTransferredAway(RequirementModel r, UserModel? currentUser) {
    if (currentUser == null || currentUser.role != 'Sales') return false;
    final assigned = r.assignedTo;
    if (assigned == null || assigned.isEmpty) return false;
    return r.createdBy == currentUser.id && assigned != currentUser.id;
  }

  bool _salesCanViewRequirement(RequirementModel r, UserModel currentUser) {
    final isCreator = r.createdBy == currentUser.id;
    final isAssignee = r.assignedTo != null &&
        r.assignedTo!.isNotEmpty &&
        r.assignedTo == currentUser.id;
    return isCreator || isAssignee;
  }

  Widget _buildSalesAssignToLabel(RequirementModel req, UserModel? currentUser) {
    final assignee = req.assigneeName?.trim() ?? '';
    final creator = req.creatorName?.trim() ?? '';
    final isReceivedTransfer = currentUser != null &&
        req.assignedTo != null &&
        req.assignedTo!.isNotEmpty &&
        req.assignedTo == currentUser.id &&
        req.createdBy != null &&
        req.createdBy != currentUser.id;

    if (_isLeadTransferredAway(req, currentUser)) {
      return Text(
        assignee.isNotEmpty ? 'Transferred to $assignee' : 'Transferred to another salesperson',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: CRMTypography.captionBold.copyWith(
          color: CRMColors.warning,
        ),
      );
    }

    if (isReceivedTransfer) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            assignee.isNotEmpty ? assignee : (currentUser.fullName),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CRMTypography.bodyMedium.copyWith(
              color: CRMColors.textOf(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (creator.isNotEmpty)
            Text(
              'From $creator',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CRMTypography.caption.copyWith(
                color: CRMColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      );
    }

    final String effectiveName = assignee.isNotEmpty
        ? assignee
        : (creator.isNotEmpty ? creator : 'Unassigned');

    return Text(
      effectiveName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: CRMTypography.bodyMedium.copyWith(
        color: CRMColors.textOf(context),
      ),
    );
  }

  Widget _buildStatusControl(RequirementModel req, UserModel? currentUser, {bool compact = false}) {
    if (_isLeadTransferredAway(req, currentUser)) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? CRMSpacing.s : CRMSpacing.s,
          vertical: compact ? CRMSpacing.xxs : CRMSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: CRMColors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(CRMBorderRadius.round),
          border: Border.all(color: CRMColors.warning.withValues(alpha: 0.35)),
        ),
        child: Text(
          'Leads Transfer',
          style: CRMTypography.captionBold.copyWith(
            color: CRMColors.warning,
            fontSize: compact ? 11 : 12,
          ),
        ),
      );
    }

    final statusColor = compact ? _getStatusColor(req.status) : CRMColors.primary;
    return PopupMenuButton<String>(
      tooltip: 'Change Status',
      onSelected: (String newStatus) => _changeStatus(req, newStatus),
      itemBuilder: (BuildContext context) => const [
        PopupMenuItem<String>(value: 'Not Started', child: Text('Not Started')),
        PopupMenuItem<String>(value: 'Follow-up', child: Text('Follow-up')),
        PopupMenuItem<String>(value: 'Interested', child: Text('Interested')),
        PopupMenuItem<String>(value: 'Site Visit', child: Text('Site Visit Sche.')),
        PopupMenuItem<String>(value: 'Site Visit Done', child: Text('Site Visit Done')),
        PopupMenuItem<String>(value: 'Negotiation', child: Text('Negotiation')),
        PopupMenuItem<String>(value: 'Won', child: Text('Won')),
        PopupMenuItem<String>(value: 'Bin', child: Text('Bin')),
        PopupMenuItem<String>(value: 'Not Interested', child: Text('Not Interested')),
      ],
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.s, vertical: CRMSpacing.xxs),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(CRMBorderRadius.round),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayStatusLabel(req.status),
                style: CRMTypography.captionBold.copyWith(
                  color: statusColor,
                  fontSize: compact ? 11 : 12,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.arrow_drop_down_rounded, size: 16, color: statusColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementsTable() {
    final authState = context.read<AuthBloc>().state;
    UserModel? currentUser;
    if (authState is Authenticated) {
      currentUser = authState.user;
    }

    return BlocBuilder<RequirementsBloc, RequirementsState>(
      buildWhen: (previous, current) =>
          current is RequirementsLoaded ||
          current is RequirementsLoading ||
          current is RequirementsInitial ||
          current is RequirementsError,
      builder: (context, state) {
        final isLoading = state is RequirementsLoading || state is RequirementsInitial;
        List<RequirementModel> requirements = [];

        if (state is RequirementsLoaded) {
          final query = _searchController.text.trim().toLowerCase();
          requirements = state.requirements.where((r) {
            if (currentUser != null && currentUser.role == 'Sales') {
              if (!_salesCanViewRequirement(r, currentUser)) {
                return false;
              }
            }

            final matchesListingType = getListingTypeLabel(r) == _activeListingTab;
            final matchesCategory = _selectedCategoryId == null || r.categoryId == _selectedCategoryId;
            final matchesSpec = _selectedConfigIds.isEmpty ||
                _selectedConfigIds.contains(r.configurationId) ||
                _selectedConfigIds.contains(r.propertyTypeId);
            
            // Map legacy status strings to new pipeline statuses for backward compatibility
            String mappedStatus = r.status;
            if (mappedStatus == 'Active' || mappedStatus == 'Live') mappedStatus = 'Interested';
            if (mappedStatus == 'Closed' || mappedStatus == 'Won') mappedStatus = 'Won';
            if (mappedStatus == 'Suspended' || mappedStatus == 'Dead') mappedStatus = 'Not Interested';

            // Exclude Won requirements from the active Requirements view
            if (mappedStatus == 'Won') return false;

            final matchesStatus = _selectedStatus == "All" ||
                r.status == _selectedStatus ||
                mappedStatus == _selectedStatus;

            bool matchesSearch = true;
            if (query.isNotEmpty) {
              final clientName = r.clientName.toLowerCase();
              final clientMobile = r.clientMobile.toLowerCase();
              final specs = '${r.propertyTypeName} ${r.configurationName ?? ""} ${r.listingTypeName ?? ""} ${r.categoryName ?? ""}'.toLowerCase();
              final remarks = (r.remarks ?? '').toLowerCase();
              final areas = r.areaNames.join(' ').toLowerCase();
              
              bool matchesSalesman = false;
              if (currentUser != null && (currentUser.role == 'Admin' || currentUser.role == 'Super Admin' || currentUser.role == 'Telecaller')) {
                final creator = (r.creatorName ?? '').toLowerCase();
                final assignee = (r.assigneeName ?? '').toLowerCase();
                matchesSalesman = creator.contains(query) || assignee.contains(query);
              }

              matchesSearch = clientName.contains(query) ||
                  clientMobile.contains(query) ||
                  specs.contains(query) ||
                  remarks.contains(query) ||
                  areas.contains(query) ||
                  matchesSalesman;
            }

            return matchesListingType && matchesCategory && matchesSpec && matchesStatus && matchesSearch;
          }).toList();
          
          // Sort by recently updated/created (descending)
          requirements.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }

        final totalCount = requirements.length;
        final totalPages = (totalCount / _requirementsPerPage).ceil();
        final currentPage = _currentPage.clamp(1, totalPages > 0 ? totalPages : 1);

        final startIndex = (currentPage - 1) * _requirementsPerPage;
        final endIndex = (startIndex + _requirementsPerPage).clamp(0, totalCount);

        final pageItems = (startIndex < totalCount)
            ? requirements.sublist(startIndex, endIndex)
            : <RequirementModel>[];

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;

            if (isMobile) {
              return _buildRequirementCards(pageItems, isLoading, currentUser, currentPage, totalPages, totalCount);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CRMDataTable(
                  isLoading: isLoading,
                  emptyTitle: 'No Requirements Found',
                  emptyDescription: 'Try adjusting filters or create a new requirement pipeline.',
                  dataRowMinHeight: 56.0,
                  dataRowMaxHeight: 72.0,
                  columnSpacing: 10.0,
                  horizontalMargin: 12.0,
                  columns: [
                    const DataColumn(label: Text('Client')),
                    if (currentUser != null && (currentUser.role == 'Super Admin' || currentUser.role == 'Admin' || currentUser.role == 'Telecaller'))
                      const DataColumn(label: Text('Added By')),
                    const DataColumn(label: Text('Assign to')),
                    const DataColumn(label: Text('Specs / Config')),
                    const DataColumn(label: Text('Budget Range')),
                    const DataColumn(label: Text('Target Area(s)')),
                    const DataColumn(label: Text('Status')),
                    const DataColumn(label: Text('Matches')),
                    const DataColumn(label: Text('Actions')),
                  ],
                  rows: pageItems.map((req) {
                    final qualityColor = req.requirementQuality == 'High'
                        ? CRMColors.success
                        : req.requirementQuality == 'Medium'
                            ? CRMColors.warning
                            : CRMColors.danger;

                    return DataRow(
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 135,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () => _showRequirementDetailDrawer(req),
                                  child: Text(
                                    req.clientName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: CRMTypography.bodyMedium.copyWith(
                                      color: CRMColors.primary,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  req.clientMobile,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
                                ),
                                if (req.nextFollowupDate != null) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.alarm_rounded, size: 12, color: CRMColors.warning),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat('dd/MM/yyyy').format(DateTime.parse(req.nextFollowupDate!)),
                                        style: CRMTypography.captionBold.copyWith(color: CRMColors.warning, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (currentUser != null && (currentUser.role == 'Super Admin' || currentUser.role == 'Admin' || currentUser.role == 'Telecaller'))
                          DataCell(
                            Text(
                              _getSalesmanName(req, currentUser),
                              style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        DataCell(
                          currentUser != null && (currentUser.role == 'Super Admin' || currentUser.role == 'Admin' || currentUser.role == 'Telecaller')
                              ? _buildAssignToDropdown(req)
                              : _buildSalesAssignToLabel(req, currentUser),
                        ),
                        DataCell(_buildSpecsConfigCell(req)),
                        DataCell(
                          Text(
                            '${BudgetFormatter.format(req.minBudget)} - ${BudgetFormatter.format(req.maxBudget)}',
                            style: CRMTypography.bodyMedium.copyWith(color: CRMColors.primary),
                          ),
                        ),
                        DataCell(_buildTargetAreasCell(req)),
                        DataCell(
                          _buildStatusControl(req, currentUser),
                        ),

                        DataCell(
                          _RunMatchesButtonWithBadge(
                            requirement: req,
                            onPressed: () => _showMatchesDrawer(req),
                            properties: _propertiesForMatches,
                          ),
                        ),
                        DataCell(
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded),
                            tooltip: 'More Actions',
                            onSelected: (action) {
                              if (action == 'add_another') {
                                _showAddAnotherRequirementDialog(req);
                              } else if (action == 'share') {
                                _showSharePropertiesDialog(req);
                              } else if (action == 'view_details') {
                                _showRequirementDetailDrawer(req);
                              } else if (action == 'edit') {
                                _showAddEditDialog(req);
                              } else if (action == 'delete') {
                                _showDeleteConfirmDialog(req);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'view_details',
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('View Details'),
                                  ],
                                ),
                              ),
                              if (!_isLeadTransferredAway(req, currentUser))
                              const PopupMenuItem(
                                value: 'add_another',
                                child: Row(
                                  children: [
                                    Icon(Icons.add_circle_outline_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Add Another'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'share',
                                child: Row(
                                  children: [
                                    Icon(Icons.share_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Share Properties'),
                                  ],
                                ),
                              ),
                              if (_hasEditAccess(req, currentUser)) ...[
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, size: 18),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline_rounded, size: 18, color: CRMColors.danger),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: CRMColors.danger)),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: CRMSpacing.m),
                _buildPagination(totalCount, totalPages, currentPage),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPagination(int totalItems, int totalPages, int currentPage) {
    final from = totalItems == 0 ? 0 : (currentPage - 1) * _requirementsPerPage + 1;
    final to = (currentPage * _requirementsPerPage).clamp(0, totalItems);
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
          value: _requirementsPerPage,
          underline: const SizedBox.shrink(),
          items: const [
            DropdownMenuItem(value: 10, child: Text('10')),
            DropdownMenuItem(value: 25, child: Text('25')),
            DropdownMenuItem(value: 50, child: Text('50')),
          ],
          onChanged: (val) {
            if (val == null) return;
            setState(() {
              _requirementsPerPage = val;
              _currentPage = 1;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed:
              currentPage > 1 ? () => setState(() => _currentPage--) : null,
        ),
        Text(
          '$currentPage / $totalPages',
          style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context)),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: currentPage < totalPages
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

  Widget _buildFollowupsPagination(int totalItems, int totalPages, int currentPage) {
    final from = totalItems == 0 ? 0 : (currentPage - 1) * _followupsPerPage + 1;
    final to = (currentPage * _followupsPerPage).clamp(0, totalItems);
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
          value: _followupsPerPage,
          underline: const SizedBox.shrink(),
          items: const [
            DropdownMenuItem(value: 10, child: Text('10')),
            DropdownMenuItem(value: 25, child: Text('25')),
            DropdownMenuItem(value: 50, child: Text('50')),
          ],
          onChanged: (val) {
            if (val == null) return;
            setState(() {
              _followupsPerPage = val;
              _currentFollowupPage = 1;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed:
              currentPage > 1 ? () => setState(() => _currentFollowupPage--) : null,
        ),
        Text(
          '$currentPage / $totalPages',
          style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context)),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: currentPage < totalPages
              ? () => setState(() => _currentFollowupPage++)
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

  Widget _buildRequirementCards(
    List<RequirementModel> requirements,
    bool isLoading,
    UserModel? currentUser,
    int currentPage,
    int totalPages,
    int totalCount,
  ) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(CRMSpacing.m),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (requirements.isEmpty) {
      return CRMCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: CRMSpacing.xl),
          child: Column(
            children: [
              Icon(Icons.folder_open_rounded, size: 48, color: CRMColors.textMuted),
              const SizedBox(height: CRMSpacing.s),
              Text('No Requirements Found', style: CRMTypography.cardTitle.copyWith(color: CRMColors.text)),
              const SizedBox(height: CRMSpacing.xxs),
              Text(
                'Try adjusting filters or create a new requirement pipeline.',
                style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ...requirements.map((req) {
          final isMobile = MediaQuery.of(context).size.width < 600;
          final budget = '₹${BudgetFormatter.format(req.minBudget)} - ₹${BudgetFormatter.format(req.maxBudget)}';
          final readinessColor = req.matchingReadiness == 'Ready'
              ? CRMColors.success
              : req.matchingReadiness == 'Needs Information'
                  ? CRMColors.warning
                  : CRMColors.danger;

          final qualityColor = req.requirementQuality == 'High'
              ? CRMColors.success
              : req.requirementQuality == 'Medium'
                  ? CRMColors.warning
                  : CRMColors.danger;

          return Container(
            margin: const EdgeInsets.only(bottom: CRMSpacing.m),
            decoration: BoxDecoration(
              color: CRMColors.cardBgOf(context),
              borderRadius: BorderRadius.circular(CRMBorderRadius.m),
              border: Border.all(color: CRMColors.borderOf(context), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Client header with status, Added by & Assign to block
                Padding(
                  padding: const EdgeInsets.all(CRMSpacing.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: CRMColors.primary.withValues(alpha: 0.1),
                            child: Text(
                              req.clientName.isNotEmpty ? req.clientName[0].toUpperCase() : '?',
                              style: CRMTypography.bodyMedium.copyWith(
                                color: CRMColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: CRMSpacing.s),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () => _showRequirementDetailDrawer(req),
                                  child: Text(
                                    req.clientName,
                                    style: CRMTypography.bodyMedium.copyWith(
                                      color: CRMColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.phone_outlined, size: 12, color: CRMColors.textSecondaryOf(context)),
                                    const SizedBox(width: 4),
                                    Text(
                                      req.clientMobile,
                                      style: CRMTypography.caption.copyWith(
                                        color: CRMColors.textSecondaryOf(context),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      req.requirementCode,
                                      style: CRMTypography.captionBold.copyWith(
                                        color: CRMColors.primary,
                                        fontSize: 11,
                                      ),
                                    ),
                                    if (req.nextFollowupDate != null) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: CRMColors.warning.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(CRMBorderRadius.xs),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.alarm_rounded, size: 10, color: CRMColors.warning),
                                            const SizedBox(width: 2),
                                            Text(
                                              DateFormat('dd/MM/yyyy').format(DateTime.parse(req.nextFollowupDate!)),
                                              style: CRMTypography.captionBold.copyWith(color: CRMColors.warning, fontSize: 9),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Status dropdown back on the top right!
                          _buildStatusControl(req, currentUser, compact: true),
                        ],
                      ),
                      const SizedBox(height: CRMSpacing.m),
                      
                      // Added by & Assign to block
                      Container(
                        padding: const EdgeInsets.all(CRMSpacing.s),
                        decoration: BoxDecoration(
                          color: CRMColors.backgroundOf(context).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                          border: Border.all(
                            color: CRMColors.borderOf(context).withValues(alpha: 0.5),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Added By
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Added by',
                                    style: CRMTypography.caption.copyWith(
                                      color: CRMColors.textSecondaryOf(context),
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.person_add_alt_1_outlined, size: 12, color: CRMColors.textMuted),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          req.creatorName ?? 'System',
                                          style: CRMTypography.captionBold.copyWith(
                                            color: CRMColors.textOf(context),
                                            fontSize: 11,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 24,
                              color: CRMColors.borderOf(context).withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: CRMSpacing.s),
                            // Assign To
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Assign to',
                                    style: CRMTypography.caption.copyWith(
                                      color: CRMColors.textSecondaryOf(context),
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  if (currentUser != null && (currentUser.role == 'Super Admin' || currentUser.role == 'Admin' || currentUser.role == 'Telecaller'))
                                    _buildMobileAssignToDropdown(req)
                                  else
                                    Row(
                                      children: [
                                        Icon(
                                          _isLeadTransferredAway(req, currentUser)
                                              ? Icons.swap_horiz_rounded
                                              : Icons.person_outline_rounded,
                                          size: 12,
                                          color: _isLeadTransferredAway(req, currentUser)
                                              ? CRMColors.warning
                                              : CRMColors.textMuted,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: _buildSalesAssignToLabel(req, currentUser),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(color: CRMColors.borderOf(context), height: 1),

                // Details grid
                Padding(
                  padding: const EdgeInsets.all(CRMSpacing.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildDetailChip(Icons.sell_outlined, 'Listing Type', getListingTypeLabel(req), isMobile: isMobile)),
                          const SizedBox(width: CRMSpacing.m),
                          Expanded(child: _buildDetailChip(Icons.apartment_rounded, 'Type', '${req.propertyTypeName} (${req.configurationName ?? "-"})', isMobile: isMobile)),
                        ],
                      ),
                      const SizedBox(height: CRMSpacing.s),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildDetailChip(Icons.currency_rupee_rounded, 'Budget', budget, isMobile: isMobile)),
                          const SizedBox(width: CRMSpacing.m),
                          Expanded(child: _buildDetailChip(Icons.location_on_rounded, 'Area', req.areaNames.join(', '), isMobile: isMobile)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Action buttons
                Divider(color: CRMColors.borderOf(context), height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: CRMSpacing.s),
                  child: Row(
                    children: [
                      _RunMatchesButtonWithBadge(
                        requirement: req,
                        onPressed: () => _showMatchesDrawer(req),
                        properties: _propertiesForMatches,
                        isMobileIconOnly: true,
                      ),
                      const SizedBox(width: 8),
                      if (!_isLeadTransferredAway(req, currentUser))
                        _buildActionButton(
                          icon: Icons.add_circle_outline_rounded,
                          color: CRMColors.primary,
                          onPressed: () => _showAddAnotherRequirementDialog(req),
                          tooltip: 'Add Another Requirement',
                        ),
                      if (!_isLeadTransferredAway(req, currentUser))
                        const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.share_rounded,
                        color: CRMColors.info,
                        onPressed: () => _showSharePropertiesDialog(req),
                        tooltip: 'Share Properties',
                      ),
                      if (_hasEditAccess(req, currentUser)) ...[
                        const SizedBox(width: 8),
                        _buildActionButton(
                          icon: Icons.edit_outlined,
                          color: CRMColors.primary,
                          onPressed: () => _showAddEditDialog(req),
                          tooltip: 'Edit',
                        ),
                        const SizedBox(width: 8),
                        _buildActionButton(
                          icon: Icons.delete_outline_rounded,
                          color: CRMColors.danger,
                          onPressed: () => _showDeleteConfirmDialog(req),
                          tooltip: 'Delete',
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: CRMSpacing.s),
        _buildPagination(totalCount, totalPages, currentPage),
      ],
    );
  }

  Widget _buildDetailChip(IconData icon, String label, String value, {bool isMobile = false}) {
    return Container(
      constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 160),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: CRMColors.textMuted),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: CRMTypography.caption.copyWith(color: CRMColors.textMuted, fontSize: 10)),
                Text(
                  value,
                  style: CRMTypography.captionBold.copyWith(color: CRMColors.text),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Won':
        return CRMColors.success;
      case 'Follow-up':
        return CRMColors.warning;
      case 'Interested':
      case 'Active':
      case 'Live':
        return CRMColors.info;
      case 'Site Visit':
      case 'Site Visit Done':
        return Colors.purple;
      case 'Negotiation':
        return Colors.orange;
      case 'Bin':
      case 'Not Interested':
      case 'Dead':
      case 'Suspended':
        return CRMColors.danger;
      case 'Not Started':
      default:
        return CRMColors.primary;
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, color: color, size: 16),
        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
        style: IconButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.zero,
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildMainViewTabButton(String label) {
    final isSelected = _activeMainTab == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeMainTab = label;
        });
        // My Won needs an unfiltered status fetch so Won rows are present.
        if (label == 'My Won' || label == 'Requirements') {
          _triggerFetch();
        }
      },
      child: AnimatedContainer(
        duration: CRMMotion.fast,
        curve: CRMMotion.easeInOut,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: CRMSpacing.xs),
        decoration: BoxDecoration(
          color: isSelected ? CRMColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(CRMBorderRadius.s),
        ),
        child: Text(
          label,
          style: CRMTypography.bodyMedium.copyWith(
            color: isSelected ? Colors.white : CRMColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildFollowupsView() {
    final dateStr = _reqFollowupDateFilter != null
        ? DateFormat('dd/MM/yyyy').format(_reqFollowupDateFilter!)
        : 'All Dates';

    return CRMCard(
      title: 'Follow-ups Management',
      subtitle: 'Scheduled client communications and appointments',
      headerAction: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dateStr,
            style: CRMTypography.captionBold.copyWith(color: CRMColors.primary),
          ),
          IconButton(
            icon: Icon(Icons.calendar_today_rounded, color: CRMColors.primary, size: 18),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _reqFollowupDateFilter ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() {
                  _reqFollowupDateFilter = picked;
                });
              }
            },
            tooltip: 'Filter by Date',
          ),
          if (_reqFollowupDateFilter != null)
            IconButton(
              icon: Icon(Icons.clear_rounded, color: CRMColors.textMuted, size: 18),
              onPressed: () {
                setState(() {
                  _reqFollowupDateFilter = null;
                });
              },
              tooltip: 'Show All Dates',
            ),
        ],
      ),
      child: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          DashboardRepository().getDashboardData(),
          RepositoryCoordinator().requirementLocal.getRequirements(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final dashboardData = snapshot.data?[0] as DashboardData?;
          final localReqs = snapshot.data?[1] as List<RequirementLocal>? ?? [];

          final followups = dashboardData?.followups ?? [];
          final filtered = followups.where((f) {
            // Filter by date
            if (_reqFollowupDateFilter != null) {
              final parsed = DateTime.tryParse(f.followupDate);
              if (parsed == null) return false;
              final matchesDate = parsed.year == _reqFollowupDateFilter!.year &&
                  parsed.month == _reqFollowupDateFilter!.month &&
                  parsed.day == _reqFollowupDateFilter!.day;
              if (!matchesDate) return false;
            }

            // Filter by Rent/Re-Sale listing type tab
            final req = localReqs.firstWhereOrNull((r) => r.id == f.requirementId);
            if (req == null) return false;

            final isRentTab = _activeListingTab == 'Rent';
            final reqIsRent = req.listingTypeName?.toLowerCase().contains('rent') ?? false;
            return isRentTab == reqIsRent;
          }).toList();

          final totalCount = filtered.length;
          final totalPages = (totalCount / _followupsPerPage).ceil();
          final currentPage = _currentFollowupPage.clamp(1, totalPages > 0 ? totalPages : 1);

          final startIndex = (currentPage - 1) * _followupsPerPage;
          final endIndex = (startIndex + _followupsPerPage).clamp(0, totalCount);

          final pageItems = (startIndex < totalCount)
              ? filtered.sublist(startIndex, endIndex)
              : <DashboardFollowup>[];

          if (pageItems.isEmpty && currentPage > 1) {
            // Safe fall-back if page boundaries changed
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _currentFollowupPage = 1;
                });
              }
            });
          }

          if (filtered.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  _reqFollowupDateFilter != null ? 'No follow-ups for $dateStr.' : 'No follow-ups found.',
                  style: TextStyle(color: CRMColors.textSecondaryOf(context)),
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CRMDataTable(
                showDecoration: false,
                columns: const [
                  DataColumn(label: Text('Client Name')),
                  DataColumn(label: Text('Mobile')),
                  DataColumn(label: Text('Scheduled Date')),
                  DataColumn(label: Text('Remarks / Agenda')),
                ],
                rows: pageItems.map((f) {
                  return DataRow(
                    cells: [
                      DataCell(
                        GestureDetector(
                          onTap: () {
                            final reqLocal = localReqs.firstWhereOrNull((r) => r.id == f.requirementId);
                            if (reqLocal != null) {
                              _showRequirementDetailDrawer(reqLocal.toModel());
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Associated requirement details not found.')),
                              );
                            }
                          },
                          child: Text(
                            f.clientName,
                            style: CRMTypography.bodyMedium.copyWith(
                              color: CRMColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(f.mobile)),
                      DataCell(Builder(
                        builder: (_) {
                          final parsed = DateTime.tryParse(f.followupDate);
                          final displayDate = parsed != null
                              ? DateFormat('dd/MM/yyyy hh:mm a').format(parsed)
                              : f.followupDate;
                          return Text(displayDate, style: TextStyle(color: CRMColors.primary, fontWeight: FontWeight.w600));
                        },
                      )),
                      DataCell(Text(f.notes ?? '-')),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: CRMSpacing.m),
              _buildFollowupsPagination(totalCount, totalPages, currentPage),
            ],
          );
        },
      ),
    );
  }

  void _showSharePropertiesDialog(RequirementModel req) {
    showDialog(
      context: context,
      builder: (context) {
        List<PropertyModel> matchedProps = [];
        List<String> selectedPropIds = [];
        bool isInitLoading = true;
        bool isGeneratingLink = false;
        bool isSharingPdf = false;
        String? error;
        String? generatedLink;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> loadMatches() async {
              try {
                final properties = await PropertiesRepository().getProperties();
                final List<PropertyModel> matches = [];
                for (final p in properties) {
                  if (await _isRequirementPropertyMatchAsync(p, req)) {
                    matches.add(p);
                  }
                }

                setDialogState(() {
                  matchedProps = matches;
                  isInitLoading = false;
                });
              } catch (e) {
                setDialogState(() {
                  error = "Failed to load matching properties.";
                  isInitLoading = false;
                });
              }
            }

            if (isInitLoading && error == null && generatedLink == null) {
              loadMatches();
            }

            if (generatedLink != null) {
              return AlertDialog(
                backgroundColor: CRMColors.cardBgOf(context),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.m)),
                title: Text("Share Link Created", style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context))),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(CRMSpacing.s),
                      decoration: BoxDecoration(
                        color: CRMColors.backgroundOf(context),
                        borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                        border: Border.all(color: CRMColors.borderOf(context)),
                      ),
                      child: SelectableText(
                        generatedLink!,
                        style: CRMTypography.caption.copyWith(color: CRMColors.primary),
                      ),
                    ),
                    const SizedBox(height: CRMSpacing.m),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: const Text("Copy"),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: generatedLink!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Link copied to clipboard!")),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: CRMSpacing.s),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: kWhatsAppGreen, foregroundColor: Colors.white),
                            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                            label: const Text("WhatsApp"),
                            onPressed: () async {
                              final text = Uri.encodeComponent("Hello, here is the curated list of properties matching your requirements: $generatedLink");
                              final url = "https://wa.me/?text=$text";
                              final uri = Uri.parse(url);
                              if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.share_rounded, size: 16),
                      label: const Text("Share"),
                      onPressed: () async {
                        try {
                          await Share.share(generatedLink!);
                        } catch (e) {
                          await Clipboard.setData(ClipboardData(text: generatedLink!));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Link copied to clipboard!")),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  ),
                ],
              );
            }

            return Stack(
              children: [
                AlertDialog(
                  backgroundColor: CRMColors.cardBgOf(context),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.m)),
                  title: Text("Share Matching Properties", style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context))),
                  content: isInitLoading
                      ? const SizedBox(
                          height: 150,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : error != null
                          ? Text(error!, style: const TextStyle(color: CRMColors.danger))
                          : matchedProps.isEmpty
                              ? const Text("No matching properties found for this requirement.")
                              : SizedBox(
                                  width: 400,
                                  height: 300,
                                  child: ListView.builder(
                                    itemCount: matchedProps.length,
                                    itemBuilder: (context, idx) {
                                      final p = matchedProps[idx];
                                      final isSelected = selectedPropIds.contains(p.id);
                                      final bhk = p.configurationName ?? "${p.bedrooms} BHK";
                                      final price = '₹${BudgetFormatter.format(p.price)}';
                                      final title = "$bhk in ${p.areaName} - $price (${p.propertyCode})";

                                      return CheckboxListTile(
                                        title: Text(title, style: CRMTypography.body.copyWith(color: CRMColors.textOf(context))),
                                        value: isSelected,
                                        activeColor: CRMColors.primary,
                                        onChanged: (isGeneratingLink || isSharingPdf) ? null : (val) {
                                          setDialogState(() {
                                            if (val == true) {
                                              selectedPropIds.add(p.id);
                                            } else {
                                              selectedPropIds.remove(p.id);
                                            }
                                          });
                                        },
                                      );
                                    },
                                  ),
                                ),
                  actionsAlignment: MainAxisAlignment.spaceBetween,
                  actions: [
                    TextButton(
                      onPressed: (isGeneratingLink || isSharingPdf) ? null : () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    if (!isInitLoading && error == null && matchedProps.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton(
                            onPressed: selectedPropIds.isEmpty || isGeneratingLink || isSharingPdf
                                ? null
                                : () async {
                                    setDialogState(() => isSharingPdf = true);
                                    try {
                                      final selected = matchedProps
                                          .where((p) => selectedPropIds.contains(p.id))
                                          .toList();
                                      final bytes = await PropertySharePdf.build(selected);
                                      final fileName = selected.length == 1
                                          ? PropertySharePdf.fileName(selected.first)
                                          : 'Selected_Properties_Details.pdf';
                                      
                                      await FileDownloader.download(bytes, fileName);
                                      
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              selected.length == 1
                                                  ? 'Property PDF ready to share.'
                                                  : 'Selected properties PDF ready to share.',
                                            ),
                                          ),
                                        );
                                      }

                                      final phone = req.clientMobile;
                                      final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
                                      String formattedPhone = cleanPhone;
                                      if (cleanPhone.length == 10) {
                                        formattedPhone = '91$cleanPhone';
                                      }

                                      // Try launching native WhatsApp scheme first to open desktop/mobile app directly
                                      final nativeUrl = "whatsapp://send?phone=$formattedPhone";
                                      final nativeUri = Uri.parse(nativeUrl);
                                      
                                      if (await canLaunchUrl(nativeUri)) {
                                        await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
                                      } else {
                                        // Fallback to WhatsApp Web directly, which bypasses the landing page
                                        final webUrl = "https://web.whatsapp.com/send?phone=$formattedPhone";
                                        final webUri = Uri.parse(webUrl);
                                        if (await canLaunchUrl(webUri)) {
                                          await launchUrl(webUri, mode: LaunchMode.externalApplication);
                                        } else {
                                          // Last resort fallback
                                          final fallbackUrl = "https://wa.me/$formattedPhone";
                                          final fallbackUri = Uri.parse(fallbackUrl);
                                          if (await canLaunchUrl(fallbackUri)) {
                                            await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
                                          }
                                        }
                                      }
                                    } catch (e) {
                                      debugPrint('Share PDF failed: $e');
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Failed to create property PDF.'),
                                            backgroundColor: CRMColors.danger,
                                          ),
                                        );
                                      }
                                    } finally {
                                      if (context.mounted) {
                                        setDialogState(() => isSharingPdf = false);
                                      }
                                    }
                                  },
                            child: const Text("Share PDF"),
                          ),
                          const SizedBox(width: CRMSpacing.s),
                          ElevatedButton(
                            onPressed: selectedPropIds.isEmpty || isGeneratingLink || isSharingPdf
                                ? null
                                : () async {
                                    setDialogState(() => isGeneratingLink = true);
                                    try {
                                      final response = await DioClient.dio.post(
                                        '/share-sessions',
                                        data: {
                                          'requirement_id': req.id,
                                          'property_ids': selectedPropIds,
                                          'expiry_days': 7
                                        },
                                      );
                                      if (response.data != null && response.data['success'] == true) {
                                        final sessionId = response.data['data']['session']['id'];
                                        final authState = context.read<AuthBloc>().state;
                                        String? currentAgentName;
                                        String? currentAgentMobile;
                                        if (authState is Authenticated) {
                                          currentAgentName = authState.user.fullName;
                                          currentAgentMobile = authState.user.mobile;
                                        }

                                        setDialogState(() {
                                          var link = "${AppConfig.publicShareBaseUrl}/$sessionId";
                                          final queryParams = <String>[];
                                          if (currentAgentName != null && currentAgentName.isNotEmpty) {
                                            queryParams.add("agentName=${Uri.encodeComponent(currentAgentName)}");
                                          }
                                          if (currentAgentMobile != null && currentAgentMobile.isNotEmpty) {
                                            queryParams.add("agentMobile=${Uri.encodeComponent(currentAgentMobile)}");
                                          }
                                          if (queryParams.isNotEmpty) {
                                            link += "?${queryParams.join('&')}";
                                          }
                                          generatedLink = link;
                                          isGeneratingLink = false;
                                        });
                                      } else {
                                        setDialogState(() {
                                          error = "Failed to generate link.";
                                          isGeneratingLink = false;
                                        });
                                      }
                                    } catch (e) {
                                      setDialogState(() {
                                        error = "Failed to generate link.";
                                        isGeneratingLink = false;
                                      });
                                    }
                                  },
                            child: const Text("Generate Link"),
                          ),
                        ],
                      ),
                  ],
                ),
                if (isGeneratingLink || isSharingPdf)
                  Positioned.fill(
                    child: Container(
                      color: CRMColors.overlayOf(context),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: CRMSpacing.s),
                            Text(
                              isSharingPdf ? 'Preparing property PDF(s)...' : 'Generating link...',
                              style: CRMTypography.caption.copyWith(color: CRMColors.textOf(context)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRequirementDetailDrawer(RequirementModel req) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return _CRMRequirementDetailDrawer(requirement: req);
      },
    );
  }



  Widget _buildMyWonFiltersAndTable() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 700;

    final selectedCat = _metadata?.categories.firstWhereOrNull((c) => c.id == _wonCategoryId);
    final isResidential = selectedCat?.name.toLowerCase().contains('residential') ?? false;

    // Filtered types and configs for My Won
    final filteredTypes = _metadata != null
        ? _metadata!.types.where((t) => t.categoryId == _wonCategoryId).toList()
        : <LookupItem>[];

    final filteredConfigs = _metadata != null
        ? _metadata!.configurations.where((c) {
            final configName = c.name.toLowerCase();
            if (isResidential) {
              return !configName.contains('office') &&
                  !configName.contains('shop') &&
                  !configName.contains('showroom') &&
                  !configName.contains('plot') &&
                  !configName.contains('warehouse') &&
                  !configName.contains('shed') &&
                  !configName.contains('industrial');
            }
            return false;
          }).toList()
        : <LookupItem>[];

    final filterCard = CRMCard(
      child: Padding(
        padding: const EdgeInsets.all(CRMSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _wonSearchController,
                    decoration: InputDecoration(
                      hintText: 'Search by client name, mobile, specs, remarks...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      contentPadding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: 8),
                      filled: true,
                      fillColor: CRMColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                        borderSide: BorderSide(color: CRMColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                        borderSide: BorderSide(color: CRMColors.border),
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: CRMSpacing.s),
                CRMButton(
                  label: "Search",
                  onPressed: () {
                    setState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: CRMSpacing.m),

            // Category dropdown filter and dependent configuration/type filters
            Wrap(
              spacing: CRMSpacing.m,
              runSpacing: CRMSpacing.s,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Category dropdown filter
                _buildDropdownFilter<String?>(
                  label: 'Category',
                  value: _wonCategoryId,
                  items: [
                    const DropdownMenuItem(value: null, child: Text("All Categories")),
                    ...?_metadata?.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  ],
                  isMobile: isMobile,
                  onChanged: (val) {
                    setState(() {
                      _wonCategoryId = val;
                      _wonPropertyTypeId = null;
                      _wonConfigurationIds.clear();
                      _currentPage = 1;
                    });
                  },
                ),

                // Category-dependent configuration or property type filters
                if (_wonCategoryId != null) ...[
                  if (isResidential)
                    SizedBox(
                      width: isMobile ? double.infinity : 200,
                      child: CRMMultiSelectDropdown(
                        label: 'Configuration',
                        selectedIds: _wonConfigurationIds,
                        items: filteredConfigs,
                        onChanged: (vals) {
                          setState(() {
                            _currentPage = 1;
                          });
                        },
                      ),
                    )
                  else
                    SizedBox(
                      width: isMobile ? double.infinity : 200,
                      child: _buildDropdownFilter<String?>(
                        label: 'Property Type',
                        value: _wonPropertyTypeId,
                        items: [
                          const DropdownMenuItem(value: null, child: Text("All Types")),
                          ...filteredTypes.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))),
                        ],
                        isMobile: isMobile,
                        onChanged: (val) {
                          setState(() {
                            _wonPropertyTypeId = val;
                            _currentPage = 1;
                          });
                        },
                      ),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );

    final table = BlocBuilder<RequirementsBloc, RequirementsState>(
      builder: (context, state) {
        final authState = context.read<AuthBloc>().state;
        UserModel? currentUser;
        if (authState is Authenticated) {
          currentUser = authState.user;
        }

        final isLoading = state is RequirementsLoading || state is RequirementsInitial;
        List<RequirementModel> requirements = [];

        if (state is RequirementsLoaded) {
          requirements = state.requirements.where((r) {
            if (currentUser != null && currentUser.role == 'Sales') {
              if (!_salesCanViewRequirement(r, currentUser)) {
                return false;
              }
            }

            final matchesListingType = getListingTypeLabel(r) == _activeListingTab;
            
            // Category filter
            final matchesCategory = _wonCategoryId == null || r.categoryId == _wonCategoryId;

            // Property Type filter
            final matchesPropertyType = _wonPropertyTypeId == null || r.propertyTypeId == _wonPropertyTypeId;

            // Configuration filter
            final matchesConfig = _wonConfigurationIds.isEmpty || _wonConfigurationIds.contains(r.configurationId);

            // Search query filter
            bool matchesSearch = true;
            final query = _wonSearchController.text.trim().toLowerCase();
            if (query.isNotEmpty) {
              final name = r.clientName.toLowerCase();
              final mobile = r.clientMobile.toLowerCase();
              final specs = '${r.propertyTypeName} ${r.configurationName ?? ""} ${r.listingTypeName ?? ""} ${r.categoryName ?? ""}'.toLowerCase();
              final remarks = (r.remarks ?? '').toLowerCase();
              final areas = r.areaNames.join(' ').toLowerCase();
              
              bool matchesSalesman = false;
              if (currentUser != null && (currentUser.role == 'Admin' || currentUser.role == 'Super Admin' || currentUser.role == 'Telecaller')) {
                final creator = (r.creatorName ?? '').toLowerCase();
                final assignee = (r.assigneeName ?? '').toLowerCase();
                matchesSalesman = creator.contains(query) || assignee.contains(query);
              }

              matchesSearch = name.contains(query) ||
                  mobile.contains(query) ||
                  specs.contains(query) ||
                  remarks.contains(query) ||
                  areas.contains(query) ||
                  matchesSalesman;
            }

            // Strictly filter for Won status
            String mappedStatus = r.status;
            if (mappedStatus == 'Closed' || mappedStatus == 'Won') mappedStatus = 'Won';
            
            final matchesStatus = mappedStatus == 'Won';

            return matchesListingType && matchesStatus && matchesCategory && matchesPropertyType && matchesConfig && matchesSearch;
          }).toList();
          
          requirements.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }

        final totalCount = requirements.length;
        final totalPages = (totalCount / _requirementsPerPage).ceil();
        final currentPage = _currentPage.clamp(1, totalPages > 0 ? totalPages : 1);
        final startIndex = (currentPage - 1) * _requirementsPerPage;
        final endIndex = (startIndex + _requirementsPerPage).clamp(0, totalCount);
        final pageItems = (startIndex < totalCount) ? requirements.sublist(startIndex, endIndex) : <RequirementModel>[];

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobileLayout = constraints.maxWidth < 700;

            if (isMobileLayout) {
              return _buildRequirementCards(pageItems, isLoading, currentUser, currentPage, totalPages, totalCount);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CRMDataTable(
                  isLoading: isLoading,
                  emptyTitle: 'No Won Requirements',
                  emptyDescription: 'Requirements marked as "Won" will appear here.',
                  dataRowMinHeight: 56.0,
                  dataRowMaxHeight: 72.0,
                  columnSpacing: 10.0,
                  horizontalMargin: 12.0,
                  columns: [
                    const DataColumn(label: Text('Client')),
                    if (currentUser != null && (currentUser.role == 'Super Admin' || currentUser.role == 'Admin' || currentUser.role == 'Telecaller'))
                      const DataColumn(label: Text('Added By')),
                    const DataColumn(label: Text('Assign to')),
                    const DataColumn(label: Text('Specs / Config')),
                    const DataColumn(label: Text('Budget Range')),
                    const DataColumn(label: Text('Target Area(s)')),
                    const DataColumn(label: Text('Status')),
                    const DataColumn(label: Text('Matches')),
                    const DataColumn(label: Text('Actions')),
                  ],
                  rows: pageItems.map((req) {
                    return DataRow(
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 135,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () => _showRequirementDetailDrawer(req),
                                  child: Text(
                                    req.clientName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: CRMTypography.bodyMedium.copyWith(
                                      color: CRMColors.primary,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  req.clientMobile,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (currentUser != null && (currentUser.role == 'Super Admin' || currentUser.role == 'Admin' || currentUser.role == 'Telecaller'))
                          DataCell(
                            Text(
                              _getSalesmanName(req, currentUser),
                              style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        DataCell(
                          currentUser != null && (currentUser.role == 'Super Admin' || currentUser.role == 'Admin' || currentUser.role == 'Telecaller')
                              ? _buildAssignToDropdown(req)
                              : _buildSalesAssignToLabel(req, currentUser),
                        ),
                        DataCell(_buildSpecsConfigCell(req)),
                        DataCell(
                          Text(
                            '${BudgetFormatter.format(req.minBudget)} - ${BudgetFormatter.format(req.maxBudget)}',
                            style: CRMTypography.bodyMedium.copyWith(color: CRMColors.primary),
                          ),
                        ),
                        DataCell(_buildTargetAreasCell(req)),
                        DataCell(
                          _buildStatusControl(req, currentUser),
                        ),

                        DataCell(
                          _RunMatchesButtonWithBadge(
                            requirement: req,
                            onPressed: () => _showMatchesDrawer(req),
                            properties: _propertiesForMatches,
                          ),
                        ),
                        DataCell(
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded),
                            tooltip: 'More Actions',
                            onSelected: (action) {
                              if (action == 'add_another') {
                                _showAddAnotherRequirementDialog(req);
                              } else if (action == 'share') {
                                _showSharePropertiesDialog(req);
                              } else if (action == 'view_details') {
                                _showRequirementDetailDrawer(req);
                              } else if (action == 'edit') {
                                _showAddEditDialog(req);
                              } else if (action == 'delete') {
                                _showDeleteConfirmDialog(req);
                              } else if (action == 'upload_doc') {
                                final isRent = req.listingTypeName?.toLowerCase().contains('rent') ?? false;
                                context.go(
                                  isRent ? '/rental-library' : '/resale-library',
                                  extra: {
                                    'autoOpenUpload': true,
                                    'clientName': req.clientName,
                                  },
                                );
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'view_details',
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('View Details'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'upload_doc',
                                child: Row(
                                  children: [
                                    Icon(Icons.upload_file_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Upload Document'),
                                  ],
                                ),
                              ),
                              if (_hasEditAccess(req, currentUser)) ...[
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, size: 18),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline_rounded, size: 18, color: CRMColors.danger),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: CRMColors.danger)),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: CRMSpacing.m),
                _buildPagination(totalCount, totalPages, currentPage),
              ],
            );
          },
        );
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        filterCard,
        const SizedBox(height: CRMSpacing.l),
        table,
      ],
    );
  }
}

class RequirementStepperDialog extends StatefulWidget {
  final RequirementModel requirement;
  final int initialStep;
  final VoidCallback onSaved;
  final bool updateStatusOnSave;
  final bool isSiteVisit;

  const RequirementStepperDialog({
    super.key,
    required this.requirement,
    this.initialStep = 1,
    required this.onSaved,
    this.updateStatusOnSave = false,
    this.isSiteVisit = false,
  });

  @override
  State<RequirementStepperDialog> createState() => _RequirementStepperDialogState();
}

class _RequirementStepperDialogState extends State<RequirementStepperDialog> {
  late int _currentStep;
  DateTime _followupDate = DateTime.now();
  TimeOfDay _followupTime = TimeOfDay.now();
  final TextEditingController _remarksController = TextEditingController();
  bool _isSavingFollowup = false;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _saveFollowup() async {
    final remarks = _remarksController.text.trim();
    if (remarks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter ${widget.isSiteVisit ? "site visit" : "followup"} remarks.')),
      );
      return;
    }

    setState(() => _isSavingFollowup = true);
    try {
      final scheduledDateTime = DateTime(
        _followupDate.year,
        _followupDate.month,
        _followupDate.day,
        _followupTime.hour,
        _followupTime.minute,
      );

      if (widget.isSiteVisit) {
        await DioClient.dio.post('/site-visits', data: {
          'requirement_id': widget.requirement.id,
          'visit_date': scheduledDateTime.toUtc().toIso8601String(),
          'remarks': remarks,
        });

        if (widget.updateStatusOnSave) {
          final RequirementsRepository requirementsRepository = RequirementsRepository();
          await requirementsRepository.updateRequirement(
            widget.requirement.copyWith(status: 'Site Visit'),
          );
        }
      } else {
        await DioClient.dio.post('/followups', data: {
          'client_name': widget.requirement.clientName,
          'mobile': widget.requirement.clientMobile,
          'notes': remarks,
          'followup_date': scheduledDateTime.toUtc().toIso8601String(),
          'requirement_id': widget.requirement.id,
        });

        if (widget.updateStatusOnSave) {
          final RequirementsRepository requirementsRepository = RequirementsRepository();
          await requirementsRepository.updateRequirement(
            widget.requirement.copyWith(status: 'Follow-up'),
          );
        }
      }

      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isSiteVisit ? 'Site visit scheduled successfully!' : 'Followup added successfully!'),
            backgroundColor: CRMColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingFollowup = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isSiteVisit ? 'Failed to schedule site visit: $e' : 'Failed to add followup: $e'),
            backgroundColor: CRMColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Dialog(
      backgroundColor: CRMColors.cardBgOf(context),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.l)),
      child: Container(
        width: isMobile ? double.infinity : 700,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(CRMSpacing.m),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.isSiteVisit ? 'Update Requirement & Add Site Visit' : 'Update Requirement & Add Followup',
                      style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Stepper Content
            Expanded(
              child: Stepper(
                type: StepperType.horizontal,
                currentStep: _currentStep,
                onStepTapped: (step) => setState(() => _currentStep = step),
                controlsBuilder: (context, details) => const SizedBox.shrink(),
                steps: [
                  Step(
                    title: const Text('Edit Details'),
                    isActive: _currentStep == 0,
                    state: _currentStep == 0 ? StepState.editing : StepState.complete,
                    content: SizedBox(
                      height: 500,
                      child: AddEditRequirementScreen(
                        requirement: widget.requirement,
                        isInline: true,
                        onSaved: () {
                          widget.onSaved();
                          setState(() => _currentStep = 1);
                        },
                      ),
                    ),
                  ),
                  Step(
                    title: Text(widget.isSiteVisit ? 'Add Site Visit' : 'Add Followup'),
                    isActive: _currentStep == 1,
                    state: _currentStep == 1 ? StepState.editing : StepState.indexed,
                    content: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: CRMSpacing.m),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Client: ${widget.requirement.clientName} (${widget.requirement.clientMobile})',
                              style: CRMTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: CRMColors.primary,
                              ),
                            ),
                            const SizedBox(height: CRMSpacing.m),
                            // Date & Time pickers row
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _followupDate,
                                        firstDate: DateTime.now().subtract(const Duration(days: 1)),
                                        lastDate: DateTime(2030),
                                      );
                                      if (picked != null) {
                                        setState(() => _followupDate = picked);
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: widget.isSiteVisit ? 'Site Visit Date *' : 'Followup Date *',
                                        prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                                      ),
                                      child: Text(DateFormat('dd/MM/yyyy').format(_followupDate)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: CRMSpacing.m),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final picked = await showTimePicker(
                                        context: context,
                                        initialTime: _followupTime,
                                      );
                                      if (picked != null) {
                                        setState(() => _followupTime = picked);
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: widget.isSiteVisit ? 'Site Visit Time *' : 'Followup Time *',
                                        prefixIcon: const Icon(Icons.access_time_rounded, size: 18),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                                      ),
                                      child: Text(_followupTime.format(context)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: CRMSpacing.m),
                            // Remarks textfield
                            TextField(
                              controller: _remarksController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: widget.isSiteVisit ? 'Site Visit Remarks *' : 'Followup Remarks *',
                                hintText: widget.isSiteVisit
                                    ? 'Enter location, property code, meeting notes...'
                                    : 'Enter call summary, next meeting notes or client feedback...',
                                alignLabelWithHint: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                              ),
                            ),
                            const SizedBox(height: CRMSpacing.l),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: CRMSpacing.m),
                                CRMButton(
                                  label: _isSavingFollowup
                                      ? 'Saving...'
                                      : (widget.isSiteVisit ? 'Save Site Visit' : 'Save Followup'),
                                  onPressed: _isSavingFollowup ? null : _saveFollowup,
                                ),
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
          ],
        ),
      ),
    );
  }
}

class _RunMatchesButtonWithBadge extends StatefulWidget {
  final RequirementModel requirement;
  final VoidCallback onPressed;
  final List<PropertyModel>? properties;
  final bool isMobileIconOnly;

  const _RunMatchesButtonWithBadge({
    required this.requirement,
    required this.onPressed,
    this.properties,
    this.isMobileIconOnly = false,
  });

  @override
  State<_RunMatchesButtonWithBadge> createState() => _RunMatchesButtonWithBadgeState();
}

class _RunMatchesButtonWithBadgeState extends State<_RunMatchesButtonWithBadge> {
  int? _matchCount;

  @override
  void initState() {
    super.initState();
    _computeCount();
  }

  @override
  void didUpdateWidget(covariant _RunMatchesButtonWithBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.requirement != widget.requirement || oldWidget.properties != widget.properties) {
      _computeCount();
    }
  }

  Future<void> _computeCount() async {
    List<PropertyModel> props = widget.properties ?? [];
    if (props.isEmpty) {
      try {
        props = await PropertiesRepository().getProperties();
      } catch (_) {}
    }

    int count = 0;
    for (final p in props) {
      if (await _RequirementsScreenState._isRequirementPropertyMatchAsync(p, widget.requirement)) {
        count++;
      }
    }

    if (mounted) {
      setState(() {
        _matchCount = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget button;
    if (widget.isMobileIconOnly) {
      button = Tooltip(
        message: 'Matches',
        child: IconButton(
          icon: const Icon(Icons.bolt_rounded, color: CRMColors.warning, size: 16),
          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          style: IconButton.styleFrom(
            backgroundColor: CRMColors.warning.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.zero,
          ),
          onPressed: widget.onPressed,
        ),
      );
    } else {
      button = CRMButton(
        label: "Run Matches",
        prefixIcon: Icons.bolt_rounded,
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.s),
        onPressed: widget.onPressed,
      );
    }

    if (_matchCount == null) {
      return button;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        Positioned(
          top: widget.isMobileIconOnly ? -4 : -6,
          right: widget.isMobileIconOnly ? -4 : -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
            decoration: BoxDecoration(
              color: _matchCount! > 0 ? const Color(0xFFEF4444) : const Color(0xFF6B7280),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$_matchCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CRMPropertyMatchesDrawer extends StatefulWidget {
  final RequirementModel requirement;

  const _CRMPropertyMatchesDrawer({required this.requirement});

  @override
  State<_CRMPropertyMatchesDrawer> createState() => _CRMPropertyMatchesDrawerState();
}

class _CRMPropertyMatchesDrawerState extends State<_CRMPropertyMatchesDrawer> {
  final PropertiesRepository _propertiesRepository = PropertiesRepository();
  bool _isLoading = true;
  List<PropertyModel> _matchedProperties = [];
  bool _includePhotos = true;

  Future<void> _shareProperty(PropertyModel p) async {
    final BHK = p.configurationName ?? "${p.bedrooms} BHK";
    final size = p.superBuiltupArea != null ? "${p.superBuiltupArea} sq ft" : "${p.plotArea ?? '-'} sq ft";
    final price = '₹${BudgetFormatter.format(p.price)}';
    
    final isWonReq = widget.requirement.status.toLowerCase() == 'won' || widget.requirement.status.toLowerCase() == 'closed';
    final headerMsg = isWonReq
        ? "Dear ${widget.requirement.clientName},\n\nHere are the details of the property selected for your finalized deal:\n\n"
        : "Dear Customer,\n\nWe found a property matching your requirements.\n\n";

    final message = "$headerMsg"
        "Reference ID: ${p.propertyCode}\n\n"
        "📍 Location: ${p.areaName}\n\n"
        "🏠 Configuration: $BHK\n\n"
        "📐 Size: $size\n\n"
        "💰 Price: $price\n\n"
        "📞 For more details, please contact NB Prop Tech.";

    if (_includePhotos && p.images != null && p.images!.isNotEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final directory = await getTemporaryDirectory();
        final List<XFile> xFiles = [];
        final limit = p.images!.length > 3 ? 3 : p.images!.length;
        for (int i = 0; i < limit; i++) {
          final imgUrl = p.images![i];
          final ext = imgUrl.split('.').last.split('?').first;
          final filePath = '${directory.path}/share_${p.propertyCode}_$i.$ext';
          await DioClient.dio.download(imgUrl, filePath);
          xFiles.add(XFile(filePath));
        }
        
        Navigator.pop(context);
        
        await Share.shareXFiles(xFiles, text: message);
        await _logShareAction(p, true);
      } catch (e) {
        Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to download images: $e')),
          );
        }
      }
    } else {
      final phone = widget.requirement.clientMobile;
      final url = 'https://wa.me/$phone?text=${Uri.encodeComponent(message)}';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        await _logShareAction(p, false);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch WhatsApp')),
          );
        }
      }
    }
  }

  Future<void> _logShareAction(PropertyModel p, bool isPhotoIncluded) async {
    try {
      await DioClient.dio.post('/audit/share', data: {
        'recordId': p.id,
        'clientMobile': widget.requirement.clientMobile,
        'requirementId': widget.requirement.id,
        'isPhotoIncluded': isPhotoIncluded,
      });
    } catch (e) {
      print("Failed to log share action: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAndFilterMatches();
  }

  Future<bool> _isRequirementPropertyMatchAsync(PropertyModel p, RequirementModel req) async {
    return _RequirementsScreenState._isRequirementPropertyMatchAsync(p, req);
  }

  Future<void> _loadAndFilterMatches() async {
    try {
      final properties = await _propertiesRepository.getProperties();
      final req = widget.requirement;

      final List<PropertyModel> matches = [];
      for (final p in properties) {
        if (await _isRequirementPropertyMatchAsync(p, req)) {
          matches.add(p);
        }
      }

      setState(() {
        _matchedProperties = matches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWonReq = widget.requirement.status.toLowerCase() == 'won' || widget.requirement.status.toLowerCase() == 'closed';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: CRMColors.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(CRMBorderRadius.l)),
      ),
      padding: const EdgeInsets.all(CRMSpacing.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(color: CRMColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: CRMSpacing.m),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isWonReq ? "Selected Deal Property" : "Matching System Listings", style: CRMTypography.sectionTitle),
              IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: CRMSpacing.xs),
          Text(
            isWonReq
                ? "Property selected and finalized for client deal: ${widget.requirement.clientName}"
                : "Showing properties that match criteria: ${widget.requirement.configurationName ?? '-'} ${widget.requirement.propertyTypeName} in ${widget.requirement.areaNames.isNotEmpty ? widget.requirement.areaNames.join(', ') : 'Any Area'}",
            style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: CRMSpacing.s),
          if (isWonReq)
            Container(
              margin: const EdgeInsets.only(bottom: CRMSpacing.s, top: CRMSpacing.xs),
              padding: const EdgeInsets.all(CRMSpacing.m),
              decoration: BoxDecoration(
                color: CRMColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                border: Border.all(color: CRMColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events_rounded, color: CRMColors.success, size: 24),
                  const SizedBox(width: CRMSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Finalized Property for ${widget.requirement.clientName}',
                          style: CRMTypography.bodyMedium.copyWith(color: CRMColors.success, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'This is the property selected and assigned when winning this client deal.',
                          style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Text(
            "Include Property Photos and Videos",
            style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
          ),
          const Divider(height: CRMSpacing.m),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_matchedProperties.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Column(
                children: [
                  Icon(Icons.search_off_rounded, size: 48, color: CRMColors.textMuted),
                  const SizedBox(height: CRMSpacing.s),
                  Text("No Active Matches Found", style: CRMTypography.cardTitle),
                  const SizedBox(height: 4),
                  Text("No database properties currently fit these filters.", style: CRMTypography.body.copyWith(color: CRMColors.textSecondary)),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _matchedProperties.length,
                itemBuilder: (context, index) {
                  final p = _matchedProperties[index];
                  return Card(
                    color: CRMColors.background,
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: CRMSpacing.s),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                      side: BorderSide(color: CRMColors.border),
                    ),
                    child: ListTile(
                      onTap: () => _openPropertyDetails(context, p),
                      contentPadding: const EdgeInsets.all(CRMSpacing.m),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              children: [
                                Text(p.title, style: CRMTypography.bodyMedium),
                                if (isWonReq) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: CRMColors.success.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: CRMColors.success.withValues(alpha: 0.4)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.check_circle_rounded, size: 12, color: CRMColors.success),
                                        const SizedBox(width: 4),
                                        Text('Won Deal Property', style: CRMTypography.caption.copyWith(color: CRMColors.success, fontWeight: FontWeight.bold, fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                  if (p.propertyStatusName.toLowerCase() == 'available')
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: CRMColors.info.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: CRMColors.info.withValues(alpha: 0.4)),
                                      ),
                                      child: Text(
                                        'Available',
                                        style: CRMTypography.caption.copyWith(color: CRMColors.info, fontWeight: FontWeight.bold, fontSize: 10),
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            '₹${BudgetFormatter.format(p.price)}',
                            style: CRMTypography.bodyMedium.copyWith(color: CRMColors.primary),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isWonReq && p.propertyStatusName.toLowerCase() == 'available')
                            Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: CRMColors.info.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: CRMColors.info.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.info_outline_rounded, size: 14, color: CRMColors.info),
                                    const SizedBox(width: 6),
                                    Text(
                                      'This property is currently Available',
                                      style: CRMTypography.caption.copyWith(
                                        color: CRMColors.info,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded, size: 14, color: CRMColors.textSecondary),
                              const SizedBox(width: 4),
                              Text('${p.areaName}, ${p.cityName}', style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.square_foot_rounded, size: 14, color: CRMColors.textSecondary),
                              const SizedBox(width: 4),
                              Text('${p.superBuiltupArea ?? "-"} sq ft', style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary)),
                              const SizedBox(width: CRMSpacing.m),
                              Icon(Icons.phone_iphone_rounded, size: 14, color: CRMColors.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${p.ownerName} (${p.ownerMobile})',
                                  style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            alignment: WrapAlignment.end,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  foregroundColor: CRMColors.primary,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.share_rounded, size: 14),
                                label: const Text('Share', style: TextStyle(fontSize: 11)),
                                onPressed: () => _shareProperty(p),
                              ),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  foregroundColor: CRMColors.success,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.phone_rounded, size: 14),
                                label: const Text('Call', style: TextStyle(fontSize: 11)),
                                onPressed: () async {
                                  final url = Uri.parse('tel:${p.ownerMobile}');
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url);
                                  }
                                },
                              ),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  foregroundColor: CRMColors.textSecondary,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.copy_rounded, size: 14),
                                label: const Text('Copy', style: TextStyle(fontSize: 11)),
                                onPressed: () {
                                  final BHK = p.configurationName ?? "${p.bedrooms} BHK";
                                  final size = p.superBuiltupArea != null ? "${p.superBuiltupArea} sq ft" : "${p.plotArea ?? '-'} sq ft";
                                  final price = '₹${BudgetFormatter.format(p.price)}';
                                  final message = "Dear Customer,\n\n"
                                      "We found a property matching your requirements.\n\n"
                                      "Reference ID: ${p.propertyCode}\n\n"
                                      "📍 Location: ${p.areaName}\n\n"
                                      "🏠 Configuration: $BHK\n\n"
                                      "📐 Size: $size\n\n"
                                      "💰 Price: $price\n\n"
                                      "📞 For more details, please contact NB Prop Tech.";
                                  Clipboard.setData(ClipboardData(text: message));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Copied to clipboard')),
                                  );
                                },
                              ),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.xs),
                                  foregroundColor: CRMColors.info,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.directions_rounded, size: 14),
                                label: const Text('Route', style: TextStyle(fontSize: 11)),
                                onPressed: () async {
                                  final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(p.title + ", " + p.areaName)}');
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url, mode: LaunchMode.externalApplication);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _openPropertyDetails(BuildContext context, PropertyModel p) {
    showCRMPropertyDrawer(context, p);
  }
}

String displayStatusLabel(String status) {
  if (status == 'Live' || status == 'Active') return 'Interested';
  if (status == 'Dead' || status == 'Suspended') return 'Not Interested';
  return status;
}

String getListingTypeLabel(RequirementModel r) {
  final name = r.listingTypeName ?? '';
  final id = r.listingTypeId ?? '';
  final combined = '$name $id'.toLowerCase();
  if (combined.contains('rent')) {
    return 'Rent';
  } else if (combined.contains('sale') || combined.contains('resale')) {
    return 'Re-Sale';
  }
  return 'Rent';
}

class _CRMRequirementDetailDrawer extends StatefulWidget {
  final RequirementModel requirement;

  const _CRMRequirementDetailDrawer({required this.requirement});

  @override
  State<_CRMRequirementDetailDrawer> createState() => _CRMRequirementDetailDrawerState();
}

class _CRMRequirementDetailDrawerState extends State<_CRMRequirementDetailDrawer> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _sessions = [];
  List<LookupItem> _furnishings = [];
  List<LookupItem> _facings = [];

  // Summary fields
  int _totalSessions = 0;
  int _totalPropertiesShared = 0;
  int _totalViews = 0;
  String _lastViewed = "Never";

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    try {
      final metadata = await PropertiesRepository().getPropertyMetadata();
      setState(() {
        _furnishings = metadata.furnishings;
        _facings = metadata.facings;
      });
    } catch (_) {}
  }

  Future<void> _loadHistory() async {
    try {
      final response = await DioClient.dio.get('/share-sessions/requirement/${widget.requirement.id}');
      if (response.data != null && response.data['success'] == true) {
        final list = response.data['data']['history'] ?? [];
        
        int totalProps = 0;
        int views = 0;
        DateTime? latestView;

        for (var s in list) {
          totalProps += (s['total_properties'] as num? ?? 0).toInt();
          views += (s['view_count'] as num? ?? 0).toInt();
          if (s['last_viewed'] != null) {
            final dt = DateTime.parse(s['last_viewed'].toString());
            if (latestView == null || dt.isAfter(latestView)) {
              latestView = dt;
            }
          }
        }

        String lastViewStr = "Never";
        if (latestView != null) {
          final now = DateTime.now();
          final diff = now.difference(latestView);
          if (diff.inMinutes < 60) {
            lastViewStr = "${diff.inMinutes}m ago";
          } else if (diff.inHours < 24) {
            lastViewStr = "${diff.inHours}h ago";
          } else {
            lastViewStr = DateFormat('dd MMM yyyy').format(latestView);
          }
        }

        setState(() {
          _sessions = list;
          _totalSessions = list.length;
          _totalPropertiesShared = totalProps;
          _totalViews = views;
          _lastViewed = lastViewStr;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Failed to load share history.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Failed to load share history.";
        _isLoading = false;
      });
    }
  }

  Future<void> _revokeSession(String sessionId) async {
    try {
      final response = await DioClient.dio.post('/share-sessions/$sessionId/revoke');
      if (response.data != null && response.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Share link revoked successfully.")),
        );
        _loadHistory();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to revoke share link.")),
      );
    }
  }

  @override
  Widget _buildShareHistoryTable() {
    final req = widget.requirement;
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(child: Text(_error!, style: const TextStyle(color: CRMColors.danger)))
            : _sessions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.share_rounded, size: 48, color: CRMColors.textMuted),
                        const SizedBox(height: CRMSpacing.s),
                        Text("No share sessions generated yet.", style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context))),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: CRMDataTable(
                      columns: const [
                        DataColumn(label: Text("Session")),
                        DataColumn(label: Text("Date")),
                        DataColumn(label: Text("Shared By")),
                        DataColumn(label: Text("Properties")),
                        DataColumn(label: Text("Views")),
                        DataColumn(label: Text("Status")),
                        DataColumn(label: Text("Actions")),
                      ],
                      rows: _sessions.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final s = entry.value;
                        final dateStr = s['created_at'] != null 
                            ? DateFormat('dd-MM-yyyy').format(DateTime.parse(s['created_at'].toString()))
                            : '-';
                        final agentName = s['agent']?['full_name']?.toString() ?? '-';
                        final status = s['status'] ?? 'Active';
                        final agentMobile = s['agent']?['mobile']?.toString() ?? '';
                        var link = "${AppConfig.publicShareBaseUrl}/${s['id']}";
                        final queryParams = <String>[];
                        if (agentName != '-' && agentName.isNotEmpty) {
                          queryParams.add("agentName=${Uri.encodeComponent(agentName)}");
                        }
                        if (agentMobile.isNotEmpty) {
                          queryParams.add("agentMobile=${Uri.encodeComponent(agentMobile)}");
                        }
                        if (queryParams.isNotEmpty) {
                          link += "?${queryParams.join('&')}";
                        }

                        return DataRow(
                          cells: [
                            DataCell(Text("Share #${_sessions.length - idx}", style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textOf(context)))),
                            DataCell(Text(dateStr, style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)))),
                            DataCell(Text(agentName, style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)))),
                            DataCell(Text("${s['total_properties'] ?? 0}", style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)))),
                            DataCell(Text("${s['view_count'] ?? 0}", style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.xs, vertical: CRMSpacing.xxs),
                                decoration: BoxDecoration(
                                  color: (status == 'Active'
                                      ? CRMColors.success
                                      : status == 'Expired'
                                          ? CRMColors.warning
                                          : CRMColors.danger)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(CRMBorderRadius.xs),
                                ),
                                child: Text(
                                  status,
                                  style: CRMTypography.captionBold.copyWith(
                                    fontSize: 11,
                                    color: status == 'Active'
                                        ? CRMColors.success
                                        : status == 'Expired'
                                            ? CRMColors.warning
                                            : CRMColors.danger,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.copy_rounded, size: 16),
                                    tooltip: "Copy Link",
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: link));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Link copied to clipboard!")),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                                    tooltip: "Open Link",
                                    onPressed: () async {
                                      final uri = Uri.parse(link);
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                                      }
                                    },
                                  ),
                                  if (agentMobile.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: kWhatsAppGreen),
                                      tooltip: "Re-share via WhatsApp",
                                      onPressed: () async {
                                        final text = Uri.encodeComponent("Hello, here is your shortlisted property collection: $link");
                                        final url = "https://wa.me/?text=$text";
                                        final uri = Uri.parse(url);
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                                        }
                                      },
                                    ),
                                  if (status == 'Active')
                                    IconButton(
                                      icon: const Icon(Icons.block_rounded, size: 16, color: CRMColors.danger),
                                      tooltip: "Revoke Link",
                                      onPressed: () => _revokeSession(s['id']),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
  }

  Widget build(BuildContext context) {
    final req = widget.requirement;
    final furnishingNames = req.furnishingIds.map((id) {
      final match = _furnishings.firstWhere(
        (f) => f.id == id,
        orElse: () => LookupItem(id: id, name: id),
      );
      return match.name;
    }).toList();
    final furnishingName = furnishingNames.isNotEmpty ? furnishingNames.join(', ') : '';

    final facingNames = req.facingIds.map((id) {
      final match = _facings.firstWhere(
        (f) => f.id == id,
        orElse: () => LookupItem(id: id, name: id),
      );
      return match.name;
    }).toList();
    final facingName = facingNames.isNotEmpty ? facingNames.join(', ') : '';
    final budget = '₹${BudgetFormatter.format(req.minBudget)} - ₹${BudgetFormatter.format(req.maxBudget)}';
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final isMobile = width < 768;
    final isDesktop = width >= 950;

    final double dialogWidth = isMobile ? width * 0.95 : width * 0.85;
    final double dialogHeight = isMobile ? height * 0.95 : height * 0.85;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: dialogWidth.clamp(320.0, 1100.0),
          height: dialogHeight.clamp(480.0, 800.0),
          decoration: BoxDecoration(
            color: CRMColors.cardBgOf(context),
            borderRadius: BorderRadius.circular(CRMBorderRadius.l),
            boxShadow: CRMShadows.large,
          ),
          padding: const EdgeInsets.all(CRMSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "Requirement Details & Share History",
                      style: CRMTypography.sectionTitle.copyWith(
                        color: CRMColors.textOf(context),
                        fontSize: isMobile ? 16 : 20,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: CRMSpacing.m),

            Expanded(
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left column: Info card & summary metrics
                        Expanded(
                          flex: 2,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                CRMCard(
                                  child: Padding(
                                    padding: const EdgeInsets.all(CRMSpacing.m),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          req.clientName,
                                          style: CRMTypography.sectionTitle.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: CRMColors.textOf(context),
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: CRMSpacing.xs),
                                        Text(
                                          req.clientMobile,
                                          style: CRMTypography.body.copyWith(
                                            color: CRMColors.textSecondaryOf(context),
                                          ),
                                        ),
                                        const Divider(height: 24),
                                        _buildDetailRow("Code", req.requirementCode, Icons.qr_code_rounded),
                                        _buildDetailRow("Listing Type", getListingTypeLabel(req), Icons.sell_outlined),
                                        _buildChipDetailRow(
                                          "Specs",
                                          Icons.business_rounded,
                                          _requirementSpecTags(req),
                                        ),
                                        _buildDetailRow("Budget", budget, Icons.account_balance_wallet_rounded),
                                        _buildChipDetailRow(
                                          "Target Areas",
                                          Icons.location_on_rounded,
                                          req.areaNames,
                                          emptyLabel: "Any Area",
                                        ),
                                        if (furnishingName.isNotEmpty)
                                          _buildDetailRow("Furnishing", furnishingName, Icons.chair_rounded),
                                        if (facingName.isNotEmpty)
                                          _buildDetailRow("Facing", facingName, Icons.explore_rounded),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: CRMSpacing.l),
                                if (!_isLoading && _error == null) ...[
                                  Row(
                                    children: [
                                      _buildSummaryMetric("Share Sessions", "$_totalSessions"),
                                      const SizedBox(width: CRMSpacing.m),
                                      _buildSummaryMetric("Properties Shared", "$_totalPropertiesShared"),
                                    ],
                                  ),
                                  const SizedBox(height: CRMSpacing.m),
                                  Row(
                                    children: [
                                      _buildSummaryMetric("Total Views", "$_totalViews"),
                                      const SizedBox(width: CRMSpacing.m),
                                      _buildSummaryMetric("Last Viewed", _lastViewed),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: CRMSpacing.l),
                        // Right column: Share History Table
                        Expanded(
                          flex: 3,
                          child: _buildShareHistoryTable(),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                CRMCard(
                                  child: Padding(
                                    padding: const EdgeInsets.all(CRMSpacing.m),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          req.clientName,
                                          style: CRMTypography.sectionTitle.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: CRMColors.textOf(context),
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: CRMSpacing.xs),
                                        Text(
                                          req.clientMobile,
                                          style: CRMTypography.body.copyWith(
                                            color: CRMColors.textSecondaryOf(context),
                                          ),
                                        ),
                                        const Divider(height: 24),
                                        _buildDetailRow("Code", req.requirementCode, Icons.qr_code_rounded),
                                        _buildDetailRow("Listing Type", getListingTypeLabel(req), Icons.sell_outlined),
                                        _buildChipDetailRow(
                                          "Specs",
                                          Icons.business_rounded,
                                          _requirementSpecTags(req),
                                        ),
                                        _buildDetailRow("Budget", budget, Icons.account_balance_wallet_rounded),
                                        _buildChipDetailRow(
                                          "Target Areas",
                                          Icons.location_on_rounded,
                                          req.areaNames,
                                          emptyLabel: "Any Area",
                                        ),
                                        if (furnishingName.isNotEmpty)
                                          _buildDetailRow("Furnishing", furnishingName, Icons.chair_rounded),
                                        if (facingName.isNotEmpty)
                                          _buildDetailRow("Facing", facingName, Icons.explore_rounded),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: CRMSpacing.l),
                                if (!_isLoading && _error == null) ...[
                                  Row(
                                    children: [
                                      _buildSummaryMetric("Share Sessions", "$_totalSessions"),
                                      const SizedBox(width: CRMSpacing.m),
                                      _buildSummaryMetric("Properties Shared", "$_totalPropertiesShared"),
                                    ],
                                  ),
                                  const SizedBox(height: CRMSpacing.m),
                                  Row(
                                    children: [
                                      _buildSummaryMetric("Total Views", "$_totalViews"),
                                      const SizedBox(width: CRMSpacing.m),
                                      _buildSummaryMetric("Last Viewed", _lastViewed),
                                    ],
                                  ),
                                  const SizedBox(height: CRMSpacing.l),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: CRMSpacing.m),
                        Expanded(
                          child: _buildShareHistoryTable(),
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

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: CRMColors.textSecondaryOf(context)),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(label, style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondaryOf(context))),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: CRMTypography.bodyMedium.copyWith(
                color: CRMColors.textOf(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _requirementSpecTags(RequirementModel req) {
    final tags = <String>[];
    final seen = <String>{};

    void addTag(String raw) {
      final value = raw.trim();
      if (value.isEmpty || value == '-') return;
      final key = value.toLowerCase();
      if (seen.add(key)) tags.add(value);
    }

    for (final part in req.propertyTypeName.split(',')) {
      addTag(part);
    }
    for (final part in (req.configurationName ?? '').split(',')) {
      addTag(part);
    }
    return tags;
  }

  Widget _buildChipDetailRow(
    String label,
    IconData icon,
    List<String> values, {
    String emptyLabel = '-',
  }) {
    final tags = values.map((v) => v.trim()).where((v) => v.isNotEmpty).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 16, color: CRMColors.textSecondaryOf(context)),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                label,
                style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondaryOf(context)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: tags.isEmpty
                ? Text(
                    emptyLabel,
                    style: CRMTypography.bodyMedium.copyWith(
                      color: CRMColors.textOf(context),
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: tags
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: CRMColors.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(CRMBorderRadius.round),
                              border: Border.all(
                                color: CRMColors.primary.withValues(alpha: 0.22),
                              ),
                            ),
                            child: Text(
                              tag,
                              style: CRMTypography.captionBold.copyWith(
                                color: CRMColors.primary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoLabel(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: CRMSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: CRMTypography.caption.copyWith(color: CRMColors.textMuted)),
          const SizedBox(height: 2),
          Text(value, style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textOf(context), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric(String label, String value) {
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
            Text(label, style: CRMTypography.caption.copyWith(color: CRMColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(value, style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: CRMColors.textOf(context))),
          ],
        ),
      ),
    );
  }
}

class RequirementWinPropertySelectionDialog extends StatefulWidget {
  final RequirementModel requirement;
  final Function(List<PropertyModel> selectedProperties) onConfirmed;

  const RequirementWinPropertySelectionDialog({
    super.key,
    required this.requirement,
    required this.onConfirmed,
  });

  @override
  State<RequirementWinPropertySelectionDialog> createState() =>
      _RequirementWinPropertySelectionDialogState();
}

class _RequirementWinPropertySelectionDialogState
    extends State<RequirementWinPropertySelectionDialog> {
  final PropertiesRepository _propertiesRepository = PropertiesRepository();
  bool _isLoading = true;
  List<PropertyModel> _allProperties = [];
  List<PropertyModel> _filteredProperties = [];
  final Set<String> _selectedPropertyIds = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProperties();
    _searchController.addListener(_filterProperties);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isRequirementPropertyMatch(PropertyModel p, RequirementModel req) {
    final statusName = p.propertyStatusName.toLowerCase();
    final statusActive = statusName == 'available' || statusName.contains('available') || statusName.isEmpty;
    if (!statusActive) return false;

    final reqListing = (req.listingTypeName ?? '').toLowerCase();
    final propListing = (p.listingTypeName).toLowerCase();
    bool listingTypeMatch = true;
    if (reqListing.isNotEmpty && propListing.isNotEmpty) {
      final isReqRent = reqListing.contains('rent');
      final isPropRent = propListing.contains('rent');
      listingTypeMatch = (isReqRent == isPropRent);
    } else if (req.listingTypeId != null && req.listingTypeId!.isNotEmpty && p.listingTypeId.isNotEmpty) {
      listingTypeMatch = (p.listingTypeId == req.listingTypeId);
    }
    if (!listingTypeMatch) return false;

    if (req.categoryId.isNotEmpty && p.categoryId.isNotEmpty) {
      if (p.categoryId != req.categoryId) return false;
    }

    if (req.propertyTypeIds.isNotEmpty) {
      bool typeMatch = req.propertyTypeIds.contains(p.propertyTypeId);
      if (!typeMatch && req.propertyTypeName.isNotEmpty && p.propertyTypeName.isNotEmpty) {
        final pTypeName = p.propertyTypeName.toLowerCase();
        typeMatch = req.propertyTypeName.toLowerCase().split(',').any((t) {
          final trimmed = t.trim();
          return trimmed.isNotEmpty && (pTypeName.contains(trimmed) || trimmed.contains(pTypeName));
        });
      }
      if (!typeMatch) return false;
    } else if (req.propertyTypeId.isNotEmpty && p.propertyTypeId.isNotEmpty) {
      if (p.propertyTypeId != req.propertyTypeId) {
        final pTypeName = p.propertyTypeName.toLowerCase();
        final reqTypeName = req.propertyTypeName.toLowerCase();
        if (!reqTypeName.contains(pTypeName) && !pTypeName.contains(reqTypeName)) return false;
      }
    }

    if (req.configurationIds.isNotEmpty) {
      bool configMatch = p.configurationId != null && req.configurationIds.contains(p.configurationId);
      if (!configMatch && req.configurationName != null && req.configurationName!.isNotEmpty && p.configurationName != null && p.configurationName!.isNotEmpty) {
        final pConfigName = p.configurationName!.toLowerCase();
        configMatch = req.configurationName!.toLowerCase().split(',').any((c) {
          final trimmed = c.trim();
          return trimmed.isNotEmpty && (pConfigName.contains(trimmed) || trimmed.contains(pConfigName));
        });
      }
      if (!configMatch) return false;
    } else if (req.configurationId != null && req.configurationId!.isNotEmpty) {
      if (p.configurationId != null && p.configurationId!.isNotEmpty && p.configurationId != req.configurationId) {
        final pConfigName = (p.configurationName ?? '').toLowerCase();
        final reqConfigName = (req.configurationName ?? '').toLowerCase();
        if (pConfigName.isNotEmpty && reqConfigName.isNotEmpty) {
          if (!reqConfigName.contains(pConfigName) && !pConfigName.contains(reqConfigName)) {
            return false;
          }
        }
      }
    }

    if (req.areaIds.isNotEmpty) {
      bool areaMatch = req.areaIds.contains(p.areaId);
      if (!areaMatch && req.areaNames.isNotEmpty && p.areaName.isNotEmpty) {
        final pArea = p.areaName.trim().toLowerCase();
        areaMatch = req.areaNames.any((aName) {
          final trimmed = aName.trim().toLowerCase();
          return trimmed.isNotEmpty && (trimmed == pArea || pArea.contains(trimmed) || trimmed.contains(pArea));
        });
      }
      if (!areaMatch) return false;
    }

    if (req.maxBudget > 0) {
      final minB = req.minBudget > 0 ? req.minBudget : 0.0;
      final maxB = req.maxBudget;
      if (p.price < minB || p.price > maxB) {
        return false;
      }
    }

    return true;
  }

  Future<void> _loadProperties() async {
    try {
      final properties = await _propertiesRepository.getProperties();
      final req = widget.requirement;

      final matches = properties.where((p) => _isRequirementPropertyMatch(p, req)).toList();

      setState(() {
        _allProperties = matches;
        _filteredProperties = matches;
        if (matches.isNotEmpty) {
          _selectedPropertyIds.add(matches.first.id);
        }
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _filterProperties() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredProperties = _allProperties);
      return;
    }

    setState(() {
      _filteredProperties = _allProperties.where((p) {
        final code = p.propertyCode.toLowerCase();
        final title = (p.title ?? '').toLowerCase();
        final owner = p.ownerName.toLowerCase();
        final area = p.areaName.toLowerCase();
        return code.contains(query) || title.contains(query) || owner.contains(query) || area.contains(query);
      }).toList();
    });
  }

  void _showConfirmWinDialog() {
    final selectedProps = _allProperties.where((p) => _selectedPropertyIds.contains(p.id)).toList();
    if (selectedProps.isEmpty) return;

    final hasRent = selectedProps.any((p) =>
        p.listingTypeName.toLowerCase().contains('rent') ||
        (LookupLocalRepository.getLookupNameSync(p.listingTypeId)?.toLowerCase().contains('rent') ?? false) ||
        p.listingTypeId == '1c1ccfc1-d318-4b66-9a43-c551532d1802');

    final hasResale = selectedProps.any((p) =>
        !p.listingTypeName.toLowerCase().contains('rent') &&
        !(LookupLocalRepository.getLookupNameSync(p.listingTypeId)?.toLowerCase().contains('rent') ?? false) &&
        p.listingTypeId != '1c1ccfc1-d318-4b66-9a43-c551532d1802');

    String actionWord;
    if (hasRent && hasResale) {
      actionWord = "Rented out / Sold out";
    } else if (hasRent) {
      actionWord = "Rented out";
    } else {
      actionWord = "Sold out";
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: CRMColors.cardBgOf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.m)),
        title: Text("Confirm Win", style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context))),
        content: Text(
          "Are you sure this requirement is $actionWord?",
          style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context)),
        ),
        actions: [
          CRMButton(
            label: "Cancel",
            variant: CRMButtonVariant.outline,
            onPressed: () => Navigator.pop(dialogContext),
          ),
          const SizedBox(width: CRMSpacing.xs),
          CRMButton(
            label: "Yes",
            variant: CRMButtonVariant.primary,
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
              widget.onConfirmed(selectedProps);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    return Dialog(
      backgroundColor: CRMColors.cardBgOf(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.l)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: isMobile ? 24 : 40,
      ),
      child: Container(
        width: isMobile ? double.infinity : 680,
        height: 600,
        padding: const EdgeInsets.all(CRMSpacing.l),
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
                        "Select Deal Property",
                        style: CRMTypography.sectionTitle.copyWith(
                          color: CRMColors.textOf(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Select property deal matches for ${widget.requirement.clientName}",
                        style: CRMTypography.caption.copyWith(
                          color: CRMColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: CRMSpacing.m),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search property code, title, owner, area...",
                prefixIcon: const Icon(Icons.search_rounded),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: CRMColors.backgroundOf(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                  borderSide: BorderSide(color: CRMColors.borderOf(context)),
                ),
              ),
            ),
            const SizedBox(height: CRMSpacing.m),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredProperties.isEmpty
                      ? Center(
                          child: Text(
                            "No matching properties found in client's budget range and specs.",
                            style: CRMTypography.body.copyWith(
                              color: CRMColors.textSecondaryOf(context),
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _filteredProperties.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final p = _filteredProperties[index];
                            final isChecked = _selectedPropertyIds.contains(p.id);
                            final isRent = p.listingTypeName.toLowerCase().contains('rent') ||
                                (LookupLocalRepository.getLookupNameSync(p.listingTypeId)?.toLowerCase().contains('rent') ?? false) ||
                                p.listingTypeId == '1c1ccfc1-d318-4b66-9a43-c551532d1802';

                            return CheckboxListTile(
                              value: isChecked,
                              activeColor: CRMColors.primaryOf(context),
                              onChanged: (bool? val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedPropertyIds.add(p.id);
                                  } else {
                                    _selectedPropertyIds.remove(p.id);
                                  }
                                });
                              },
                              title: Row(
                                children: [
                                  Text(
                                    p.propertyCode,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      p.title.isNotEmpty ? p.title : "Property",
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (isRent ? CRMColors.success : CRMColors.primaryOf(context))
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isRent ? "Rent" : "Re-sale",
                                      style: TextStyle(
                                        color: isRent ? CRMColors.success : CRMColors.primaryOf(context),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  "${p.ownerName} • ${p.areaName} • ₹${BudgetFormatter.format(p.price)}",
                                  style: TextStyle(
                                    color: CRMColors.textSecondaryOf(context),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: CRMSpacing.m),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CRMButton(
                  label: "Cancel",
                  variant: CRMButtonVariant.outline,
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: CRMSpacing.s),
                CRMButton(
                  label: "Done (${_selectedPropertyIds.length})",
                  variant: CRMButtonVariant.primary,
                  onPressed: _selectedPropertyIds.isNotEmpty ? _showConfirmWinDialog : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PropertyDealClientStore {
  static const String _prefix = 'deal_client_name_';
  static const String _reqPrefix = 'won_req_properties_';
  static final Map<String, String> _memoryCache = {};
  static final Map<String, List<String>> _reqMemoryCache = {};

  static Future<void> setClientName(String propertyId, String clientName) async {
    _memoryCache[propertyId] = clientName;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefix$propertyId', clientName);
    } catch (_) {}
  }

  static Future<void> setWonRequirementProperties(String requirementId, List<String> propertyIds) async {
    _reqMemoryCache[requirementId] = propertyIds;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('$_reqPrefix$requirementId', propertyIds);
    } catch (_) {}
  }

  static Future<List<String>> getWonPropertyIds(String requirementId) async {
    if (_reqMemoryCache.containsKey(requirementId)) {
      return _reqMemoryCache[requirementId]!;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('$_reqPrefix$requirementId');
      if (list != null) {
        _reqMemoryCache[requirementId] = list;
        return list;
      }
    } catch (_) {}
    return [];
  }

  static String? getMemoryClientName(String propertyId) {
    return _memoryCache[propertyId];
  }

  static Future<String?> getClientName(String propertyId, {PropertyModel? property}) async {
    if (_memoryCache.containsKey(propertyId)) {
      return _memoryCache[propertyId];
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('$_prefix$propertyId');
      if (savedName != null && savedName.isNotEmpty) {
        _memoryCache[propertyId] = savedName;
        return savedName;
      }
    } catch (_) {}
    return null;
  }

  static Future<void> removeClientName(String propertyId) async {
    _memoryCache.remove(propertyId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefix$propertyId');
    } catch (_) {}
  }

  static Future<void> removeWonRequirementProperties(String requirementId) async {
    _reqMemoryCache.remove(requirementId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_reqPrefix$requirementId');
    } catch (_) {}
  }
}