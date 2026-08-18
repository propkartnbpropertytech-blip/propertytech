import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import '../../security/role_guard.dart';
import '../../../../features/auth/bloc/auth_bloc.dart';
import '../../theme/theme_manager.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_blur.dart';
import '../tokens/app_shadows.dart';
import 'crm_brand_lockup.dart';
import '../../api/dio_client.dart';
import '../../utils/budget_formatter.dart';
import '../../network/sync_manager.dart';
import 'dart:async';
import '../../../core/storage/repository_coordinator.dart';
import '../../../features/properties/services/properties_service.dart';
import '../../../features/properties/models/property_model.dart';
import '../../navigation/mobile_system_back_handler.dart';

class CRMAppShell extends StatefulWidget {
  final Widget child;

  const CRMAppShell({super.key, required this.child});

  /// Session-scoped flag so entry settle runs once per app session.
  static bool _entrySettledThisSession = false;

  @override
  State<CRMAppShell> createState() => _CRMAppShellState();
}

class _CRMAppShellState extends State<CRMAppShell>
    with SingleTickerProviderStateMixin {
  bool _isSidebarExpanded = true;
  final TextEditingController _searchController = TextEditingController();
  late PersistentTabController _tabController;
  int _previousIndex = 0;
  final FocusNode _searchFocusNode = FocusNode();
  bool _isMobileSearchActive = false;
  late AnimationController _entryController;
  bool _notificationsPanelOpen = false;
  bool _isBottomBarVisible = true;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: Duration.zero,
      value: 1.0,
    );
    CRMAppShell._entrySettledThisSession = true;

    _tabController = PersistentTabController(initialIndex: 0);
    _tabController.addListener(() {
      final index = _tabController.index;
      if (index == 2) {
        // Reset controller to previous index, show bottom sheet
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _tabController.jumpToTab(_previousIndex);
        });
        _showQuickActionsBottomSheet();
      } else {
        final location = GoRouter.of(context).routerDelegate.currentConfiguration.last.matchedLocation;
        if (index != _previousIndex || location != _getTabRoutePath(index)) {
          _previousIndex = index;
          context.go(_getTabRoutePath(index));
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fetchNotifications();
      _notificationsTimer?.cancel();
      _notificationsTimer = Timer.periodic(const Duration(seconds: 45), (_) {
        if (mounted) _fetchNotifications();
      });
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchDebounce?.cancel();
    _notificationsTimer?.cancel();
    super.dispose();
  }
  OverlayEntry? _searchOverlayEntry;
  final LayerLink _searchLayerLink = LayerLink();
  List<dynamic> _propertySuggestions = [];
  List<dynamic> _requirementSuggestions = [];
  List<dynamic> _ownerSuggestions = [];
  List<dynamic> _builderSuggestions = [];
  List<dynamic> _clientSuggestions = [];
  bool _isSearching = false;
  Timer? _searchDebounce;
  List<dynamic> _notifications = [];
  int _unreadNotificationsCount = 0;
  bool _isLoadingNotifications = false;
  int _notificationsPage = 1;
  int _totalNotificationPages = 1;
  Timer? _notificationsTimer;

  int _getTabRouteIndex(String location) {
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/properties')) return 1;
    if (location.startsWith('/requirements')) return 3;
    if (location.startsWith('/profile')) return 4;
    return _tabController.index;
  }

  String _getTabRoutePath(int index) {
    switch (index) {
      case 0:
        return '/dashboard';
      case 1:
        return '/properties';
      case 3:
        return '/requirements';
      case 4:
        return '/profile';
      default:
        return '/dashboard';
    }
  }

  void _showQuickActionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: CRMColors.surfaceElevatedOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(CRMBorderRadius.sheet)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: CRMSpacing.l, horizontal: CRMSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quick Actions',
                      style: CRMTypography.sectionTitle.copyWith(
                        color: CRMColors.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: CRMColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: CRMSpacing.m),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: CRMColors.primary.withOpacity(0.12),
                    child: Icon(Icons.add_business_rounded, color: CRMColors.primary),
                  ),
                  title: Text(
                    'Add Property',
                    style: CRMTypography.bodyMedium.copyWith(
                      color: CRMColors.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'List a new commercial or residential property',
                    style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/properties?action=add');
                  },
                ),
                const Divider(height: CRMSpacing.m),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: CRMColors.primary.withOpacity(0.12),
                    child: Icon(Icons.add_task_rounded, color: CRMColors.primary),
                  ),
                  title: Text(
                    'Add Requirement',
                    style: CRMTypography.bodyMedium.copyWith(
                      color: CRMColors.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Add a new client listing requirement matching criteria',
                    style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/requirements?action=add');
                  },
                ),
                const SizedBox(height: CRMSpacing.s),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getRelativeTime(String isoString) {
    if (isoString.isEmpty) return '';
    try {
      final date = DateTime.parse(isoString).toLocal();
      final diff = DateTime.now().difference(date);
      if (diff.inSeconds < 60) {
        return 'Just now';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else {
        return '${diff.inDays}d ago';
      }
    } catch (_) {
      return '';
    }
  }

  Future<void> _fetchNotifications({bool loadMore = false}) async {
    if (_isLoadingNotifications) return;
    if (loadMore && _notificationsPage >= _totalNotificationPages) return;

    setState(() {
      _isLoadingNotifications = true;
      if (!loadMore) {
        _notificationsPage = 1;
      } else {
        _notificationsPage++;
      }
    });

    try {
      final response = await DioClient.dio.get(
        '/notifications',
        queryParameters: {'page': _notificationsPage, 'limit': 5},
      );
      final list = response.data['data']['notifications'] as List? ?? [];
      final pagination = response.data['data']['pagination'] ?? {};
      
      setState(() {
        if (loadMore) {
          _notifications.addAll(list);
        } else {
          _notifications = list;
        }
        _totalNotificationPages = pagination['totalPages'] ?? 1;
        _unreadNotificationsCount = pagination['totalItems'] ?? 0; // estimate unread count as total for now, or fetch unread count separately
        // Let's count actual unread items in our list for the badge to be precise
        _unreadNotificationsCount = _notifications.where((n) => n['is_read'] == false).length;
        _isLoadingNotifications = false;
      });
    } catch (_) {
      setState(() => _isLoadingNotifications = false);
    }
  }

  Future<void> _markNotificationRead(String id) async {
    try {
      await DioClient.dio.patch('/notifications/$id/read');
      _fetchNotifications();
    } catch (_) {}
  }

  Future<void> _markAllNotificationsRead() async {
    try {
      await DioClient.dio.patch('/notifications/read-all');
      _fetchNotifications();
    } catch (_) {}
  }

  Future<void> _deleteNotification(String id) async {
    try {
      await DioClient.dio.delete('/notifications/$id');
      _fetchNotifications();
    } catch (_) {}
  }

  void _onSearchChanged(String text) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (text.trim().isEmpty) {
        _hideSearchOverlay();
        return;
      }
      _performSearch(text.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);
    _showSearchOverlay();
    try {
      final queryLower = query.toLowerCase();
      final queryNormalized = queryLower.replaceAll(' ', '');

      final authState = context.read<AuthBloc>().state;
      String? currentUserRole;
      if (authState is Authenticated) {
        currentUserRole = authState.user.role;
      }
      final bool isUserAdminOrSuperAdmin = currentUserRole == 'Admin' || currentUserRole == 'Super Admin';

      // 1. Active Properties
      final props = await RepositoryCoordinator().propertyLocal.getProperties();
      final matchedProps = props.where((p) {
        final code = (p.propertyCode ?? '').toLowerCase();
        final name = (p.title ?? '').toLowerCase();
        final ownerName = (p.ownerName ?? '').toLowerCase();
        final ownerMobile = (p.ownerMobile ?? '').toLowerCase();
        final area = (p.areaName ?? '').toLowerCase();
        final bhk = (p.configurationName ?? '').toLowerCase();
        final bhkNormalized = bhk.replaceAll(' ', '');
        final date = p.createdAt.toString().toLowerCase();
        final status = (p.propertyStatusName ?? '').toLowerCase();
        final superBuiltup = (p.superBuiltupArea?.toString() ?? '').toLowerCase();
        final type = (p.propertyTypeName ?? '').toLowerCase();
        final category = (p.categoryName ?? '').toLowerCase();
        final remarks = (p.remarks ?? '').toLowerCase();
        final description = (p.description ?? '').toLowerCase();
        final salesman = (p.createdByName ?? '').toLowerCase();

        final matchesGeneral = code.contains(queryLower) ||
            name.contains(queryLower) ||
            ownerName.contains(queryLower) ||
            ownerMobile.contains(queryLower) ||
            area.contains(queryLower) ||
            bhk.contains(queryLower) ||
            (bhkNormalized.isNotEmpty && bhkNormalized.contains(queryNormalized)) ||
            date.contains(queryLower) ||
            status.contains(queryLower) ||
            superBuiltup.contains(queryLower) ||
            type.contains(queryLower) ||
            category.contains(queryLower) ||
            remarks.contains(queryLower) ||
            description.contains(queryLower);

        final matchesSalesman = isUserAdminOrSuperAdmin && salesman.contains(queryLower);

        return matchesGeneral || matchesSalesman;
      }).map((p) => {
        'id': p.id,
        'title': p.title,
        'property_code': p.propertyCode,
        'price': p.price,
        'is_recycle_bin': false,
      }).toList();

      // 1b. Recycle Bin / Deleted Properties
      List<Map<String, dynamic>> matchedBinProps = [];
      try {
        final binRes = await PropertiesService().getBinProperties();
        final binData = binRes['data'] as Map<String, dynamic>? ?? {};
        final binList = binData['properties'] as List? ?? [];
        final binProps = binList.map((p) => PropertyModel.fromJson(p)).toList();

        matchedBinProps = binProps.where((p) {
          final code = (p.propertyCode ?? '').toLowerCase();
          final name = (p.title ?? '').toLowerCase();
          final ownerName = (p.ownerName ?? '').toLowerCase();
          final ownerMobile = (p.ownerMobile ?? '').toLowerCase();
          final area = (p.areaName ?? '').toLowerCase();
          final bhk = (p.configurationName ?? '').toLowerCase();
          final bhkNormalized = bhk.replaceAll(' ', '');
          final date = p.createdAt.toString().toLowerCase();
          final status = (p.propertyStatusName ?? '').toLowerCase();
          final superBuiltup = (p.superBuiltupArea?.toString() ?? '').toLowerCase();
          final type = (p.propertyTypeName ?? '').toLowerCase();
          final category = (p.categoryName ?? '').toLowerCase();
          final remarks = (p.remarks ?? '').toLowerCase();
          final description = (p.description ?? '').toLowerCase();
          final salesman = (p.createdByName ?? '').toLowerCase();

          final matchesGeneral = code.contains(queryLower) ||
              name.contains(queryLower) ||
              ownerName.contains(queryLower) ||
              ownerMobile.contains(queryLower) ||
              area.contains(queryLower) ||
              bhk.contains(queryLower) ||
              (bhkNormalized.isNotEmpty && bhkNormalized.contains(queryNormalized)) ||
              date.contains(queryLower) ||
              status.contains(queryLower) ||
              superBuiltup.contains(queryLower) ||
              type.contains(queryLower) ||
              category.contains(queryLower) ||
              remarks.contains(queryLower) ||
              description.contains(queryLower);

          final matchesSalesman = isUserAdminOrSuperAdmin && salesman.contains(queryLower);

          return matchesGeneral || matchesSalesman;
        }).map((p) => {
          'id': p.id,
          'title': '[In Recycle Bin] ${p.title}',
          'property_code': p.propertyCode,
          'price': p.price,
          'is_recycle_bin': true,
        }).toList();
      } catch (_) {
        // fail silently if bin fetch fails
      }

      final allMatchedProps = [...matchedProps, ...matchedBinProps];

      // 2. Requirements
      final reqs = await RepositoryCoordinator().requirementLocal.getRequirements();
      final matchedReqs = reqs.where((r) {
        final name = (r.clientName ?? '').toLowerCase();
        final mobile = (r.clientMobile ?? '').toLowerCase();
        final remarks = (r.remarks ?? '').toLowerCase();
        final type = (r.propertyTypeName ?? '').toLowerCase();
        final config = (r.configurationName ?? '').toLowerCase();
        final configNormalized = config.replaceAll(' ', '');
        final category = (r.categoryName ?? '').toLowerCase();
        final matchesArea = r.areaNames.any((name) => name.toLowerCase().contains(queryLower));
        final salesmanCreator = (r.creatorName ?? '').toLowerCase();
        final salesmanAssignee = (r.assigneeName ?? '').toLowerCase();

        final matchesGeneral = name.contains(queryLower) ||
            mobile.contains(queryLower) ||
            remarks.contains(queryLower) ||
            type.contains(queryLower) ||
            config.contains(queryLower) ||
            (configNormalized.isNotEmpty && configNormalized.contains(queryNormalized)) ||
            category.contains(queryLower) ||
            matchesArea;

        final matchesSalesman = isUserAdminOrSuperAdmin &&
            (salesmanCreator.contains(queryLower) || salesmanAssignee.contains(queryLower));

        return matchesGeneral || matchesSalesman;
      }).map((r) => {
        'id': r.id,
        'customer_name': r.clientName,
        'mobile': r.clientMobile,
      }).toList();

      // 3. Owners
      final owners = await RepositoryCoordinator().ownerLocal.getOwners();
      final matchedOwners = owners.where((o) =>
        (o.name ?? '').toLowerCase().contains(queryLower) ||
        (o.mobile ?? '').contains(queryLower) ||
        (o.email?.toLowerCase().contains(queryLower) ?? false)
      ).map((o) => {
        'id': o.id,
        'name': o.name,
        'mobile': o.mobile,
      }).toList();

      // 4. Builders
      final builders = await RepositoryCoordinator().builderLocal.getBuilders();
      final matchedBuilders = builders.where((b) =>
        (b.companyName ?? '').toLowerCase().contains(queryLower) ||
        (b.contactPerson ?? '').toLowerCase().contains(queryLower) ||
        (b.mobile ?? '').contains(queryLower) ||
        (b.email ?? '').toLowerCase().contains(queryLower) ||
        (b.remarks?.toLowerCase().contains(queryLower) ?? false)
      ).map((b) => {
        'id': b.id,
        'company_name': b.companyName,
        'contact_person': b.contactPerson,
        'mobile': b.mobile,
      }).toList();

      // 5. Clients
      final clients = await RepositoryCoordinator().clientLocal.getClients();
      final matchedClients = clients.where((c) =>
        (c.name ?? '').toLowerCase().contains(queryLower) ||
        (c.mobile ?? '').contains(queryLower) ||
        (c.email ?? '').toLowerCase().contains(queryLower) ||
        (c.remarks?.toLowerCase().contains(queryLower) ?? false)
      ).map((c) => {
        'id': c.id,
        'name': c.name,
        'mobile': c.mobile,
      }).toList();

      setState(() {
        _propertySuggestions = allMatchedProps;
        _requirementSuggestions = matchedReqs;
        _ownerSuggestions = matchedOwners;
        _builderSuggestions = matchedBuilders;
        _clientSuggestions = matchedClients;
        _isSearching = false;
      });
      _searchOverlayEntry?.markNeedsBuild();
    } catch (e) {
      setState(() => _isSearching = false);
      _searchOverlayEntry?.markNeedsBuild();
    }
  }

  void _showSearchOverlay() {
    if (_searchOverlayEntry != null) return;
    _searchOverlayEntry = OverlayEntry(
      builder: (context) {
        final double screenWidth = MediaQuery.of(context).size.width;
        final double screenHeight = MediaQuery.of(context).size.height;
        final double topPadding = MediaQuery.of(context).padding.top;
        final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
        
        final bool isMobile = screenWidth < 600;

        final double availableHeight = screenHeight - (70 + topPadding + 16) - keyboardHeight;
        final double calculatedMaxHeight = availableHeight > 100 
            ? (availableHeight < 400 ? availableHeight : 400) 
            : 100;

        final Widget cardContent = Material(
          elevation: 8,
          shadowColor: CRMColors.shadow,
          borderRadius: BorderRadius.circular(CRMBorderRadius.input),
          color: CRMColors.cardBgOf(context),
          child: Container(
            constraints: BoxConstraints(maxHeight: calculatedMaxHeight),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(CRMBorderRadius.input),
              border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.6), width: 0.5),
            ),
            child: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(CRMSpacing.m),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : (_propertySuggestions.isEmpty &&
                        _requirementSuggestions.isEmpty &&
                        _ownerSuggestions.isEmpty &&
                        _builderSuggestions.isEmpty &&
                        _clientSuggestions.isEmpty)
                    ? Padding(
                        padding: const EdgeInsets.all(CRMSpacing.m),
                        child: Text(
                          'No suggestions found.',
                          style: TextStyle(color: CRMColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: CRMSpacing.s),
                        children: [
                          if (_propertySuggestions.isNotEmpty) ...[
                            _buildSuggestionSectionHeader('Properties'),
                            ..._propertySuggestions.map((p) => _buildSuggestionTile(
                                  icon: Icons.business_rounded,
                                  title: p['title'] ?? '',
                                  subtitle: p['is_recycle_bin'] == true
                                      ? 'Code: ${p['property_code']} • ₹${BudgetFormatter.format((p['price'] as num?)?.toDouble() ?? 0.0)} • [In Recycle Bin]'
                                      : 'Code: ${p['property_code']} • ₹${BudgetFormatter.format((p['price'] as num?)?.toDouble() ?? 0.0)}',
                                  onTap: () {
                                    _hideSearchOverlay();
                                    if (p['is_recycle_bin'] == true) {
                                      context.go('/bin');
                                    } else {
                                      context.go('/properties?openId=${p['id']}&t=${DateTime.now().millisecondsSinceEpoch}');
                                    }
                                  },
                                )),
                          ],
                          if (_requirementSuggestions.isNotEmpty) ...[
                            _buildSuggestionSectionHeader('Requirements'),
                            ..._requirementSuggestions.map((r) => _buildSuggestionTile(
                                  icon: Icons.person_search_rounded,
                                  title: r['customer_name'] ?? '',
                                  subtitle: 'Mobile: ${r['mobile']}',
                                  onTap: () {
                                    _hideSearchOverlay();
                                    context.go('/requirements');
                                  },
                                )),
                          ],
                          if (_ownerSuggestions.isNotEmpty) ...[
                            _buildSuggestionSectionHeader('Owners'),
                            ..._ownerSuggestions.map((o) => _buildSuggestionTile(
                                  icon: Icons.person_rounded,
                                  title: o['name'] ?? '',
                                  subtitle: 'Mobile: ${o['mobile']}',
                                  onTap: () {
                                    _hideSearchOverlay();
                                    context.go('/owners');
                                  },
                                )),
                          ],
                          if (_builderSuggestions.isNotEmpty) ...[
                            _buildSuggestionSectionHeader('Builders'),
                            ..._builderSuggestions.map((b) => _buildSuggestionTile(
                                  icon: Icons.construction_rounded,
                                  title: b['company_name'] ?? '',
                                  subtitle: 'Contact: ${b['contact_person']} • Mobile: ${b['mobile']}',
                                  onTap: () {
                                    _hideSearchOverlay();
                                    context.go('/builders');
                                  },
                                )),
                          ],
                          if (_clientSuggestions.isNotEmpty) ...[
                            _buildSuggestionSectionHeader('Clients'),
                            ..._clientSuggestions.map((c) => _buildSuggestionTile(
                                  icon: Icons.people_alt_rounded,
                                  title: c['name'] ?? '',
                                  subtitle: 'Mobile: ${c['mobile']}',
                                  onTap: () {
                                    _hideSearchOverlay();
                                    context.go('/clients');
                                  },
                                )),
                          ],
                        ],
                      ),
          ),
        );

        if (isMobile) {
          return Positioned(
            left: 16,
            right: 16,
            top: 70 + topPadding + 8,
            child: cardContent,
          );
        }

        return Positioned(
          width: 400,
          child: CompositedTransformFollower(
            link: _searchLayerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 8),
            child: cardContent,
          ),
        );
      },
    );
    Overlay.of(context).insert(_searchOverlayEntry!);
  }

  void _hideSearchOverlay() {
    _searchOverlayEntry?.remove();
    _searchOverlayEntry = null;
  }

  Widget _buildSuggestionSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: CRMSpacing.xs),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: CRMColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSuggestionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: CRMColors.textSecondary, size: 20),
      title: Text(title, style: TextStyle(color: CRMColors.textOf(context), fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: CRMColors.textSecondary, fontSize: 11)),
      onTap: onTap,
      dense: true,
    );
  }

  void _handleLogout() {
    try {
      if (Scaffold.of(context).isDrawerOpen) {
        Navigator.of(context).pop();
      }
    } catch (_) {}
    RoleGuard.currentUser = null;
    context.read<AuthBloc>().add(LogoutRequested());
    if (mounted) {
      context.go('/get-started');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Depend on InheritedTheme from MaterialApp (updated via ThemeManager in main.dart).
    // Avoid a second ListenableBuilder here — it was double-rebuilding the whole shell
    // on every Rent/Re-Sale toggle.
    Theme.of(context);
    final userState = context.select<AuthBloc, AuthState>((bloc) => bloc.state);
    final location = GoRouterState.of(context).matchedLocation;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;
    final isTablet = size.width >= 768 && size.width < 1024;
    final isDesktop = size.width >= 1024;

    final targetIndex = _getTabRouteIndex(location);
    if (_tabController.index != targetIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_tabController.index != targetIndex) {
          _tabController.jumpToTab(targetIndex);
          _previousIndex = targetIndex;
        }
      });
    }

    final showSidebar = isDesktop || isTablet;
    final sidebarWidth = _isSidebarExpanded ? 260.0 : 78.0;

    final entryCurved = CurvedAnimation(
      parent: _entryController,
      curve: CRMMotion.emphasized,
    );

    return MobileSystemBackHandler(
      onBeforeBack: () async {
        if (_searchOverlayEntry != null || _isMobileSearchActive) {
          _hideSearchOverlay();
          if (_isMobileSearchActive && mounted) {
            setState(() => _isMobileSearchActive = false);
          }
          return true;
        }
        if (_notificationsPanelOpen) {
          setState(() => _notificationsPanelOpen = false);
          return true;
        }
        return false;
      },
      child: Stack(
          children: [
            FadeTransition(
              opacity: entryCurved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.012),
                  end: Offset.zero,
                ).animate(entryCurved),
                child: Scaffold(
                  backgroundColor: CRMColors.backgroundOf(context),
                  extendBody: isMobile,
                  drawer: isMobile
                      ? Drawer(
                          backgroundColor: CRMColors.sidebarBgOf(context),
                          child: _buildSidebarContent(
                            location,
                            userState,
                            isMobile: true,
                          ),
                        )
                      : null,
                  bottomNavigationBar: isMobile
                      ? AnimatedSlide(
                          offset: _isBottomBarVisible ? Offset.zero : const Offset(0, 1.5),
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: IgnorePointer(
                            ignoring: !_isBottomBarVisible,
                            child: CustomBottomNavBar(
                              selectedIndex: targetIndex,
                              onItemSelected: (index) {
                                if (index == 2) {
                                  _showQuickActionsBottomSheet();
                                  return;
                                }
                                final path = _getTabRoutePath(index);
                                if (GoRouterState.of(context).matchedLocation !=
                                    path) {
                                  context.go(path);
                                }
                              },
                            ),
                          ),
                        )
                      : null,
              body: Row(
                children: [
                  if (showSidebar)
                    AnimatedContainer(
                      duration: CRMMotion.medium,
                      curve: CRMMotion.easeInOut,
                      width: sidebarWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          color: CRMColors.sidebarBgOf(context),
                          border: Border(
                            right: BorderSide(
                              color: CRMColors.sidebarBorder,
                              width: 0.5,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? 0.22
                                    : 0.06,
                              ),
                              blurRadius: 24,
                              offset: const Offset(4, 0),
                            ),
                          ],
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return _buildSidebarContent(
                              location,
                              userState,
                              sidebarWidth: constraints.maxWidth,
                            );
                          },
                        ),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        isMobile
                            ? SafeArea(
                                bottom: false,
                                child: _buildTopBar(context, isMobile),
                              )
                            : _buildTopBar(context, isMobile),
                        Expanded(
                          child: isMobile
                              ? NotificationListener<ScrollNotification>(
                                  onNotification: (scrollNotification) {
                                    if (scrollNotification is ScrollUpdateNotification) {
                                      if (scrollNotification.metrics.axis == Axis.vertical) {
                                        final pixels = scrollNotification.metrics.pixels;
                                        final scrollDelta = scrollNotification.scrollDelta;
                                        if (pixels <= 10) {
                                          if (!_isBottomBarVisible) {
                                            setState(() {
                                              _isBottomBarVisible = true;
                                            });
                                          }
                                        } else if (scrollDelta != null && scrollDelta.abs() > 4) {
                                          if (scrollDelta > 0) {
                                            if (_isBottomBarVisible) {
                                              setState(() {
                                                _isBottomBarVisible = false;
                                              });
                                            }
                                          } else if (scrollDelta < 0) {
                                            if (!_isBottomBarVisible) {
                                              setState(() {
                                                _isBottomBarVisible = true;
                                              });
                                            }
                                          }
                                        }
                                      }
                                    }
                                    return false;
                                  },
                                  child: MediaQuery(
                                    data: MediaQuery.of(context).copyWith(
                                      padding: MediaQuery.of(context).padding.copyWith(
                                        bottom: MediaQuery.of(context)
                                                .padding
                                                .bottom +
                                            76,
                                      ),
                                    ),
                                    child: widget.child,
                                  ),
                                )
                              : widget.child,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_notificationsPanelOpen) _buildNotificationsPanel(context),
        ValueListenableBuilder<bool>(
          valueListenable: SyncManager().isSyncing,
          builder: (context, isSyncing, _) {
            if (!isSyncing) return const SizedBox.shrink();
            return Container(
              color: CRMColors.overlayOf(context),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: CRMColors.surfaceElevatedOf(context),
                    borderRadius: BorderRadius.circular(CRMBorderRadius.l),
                    border: Border.all(
                      color: CRMColors.primaryOf(context).withOpacity(0.3),
                      width: 0.5,
                    ),
                    boxShadow: CRMShadows.modal,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: CRMColors.primaryOf(context),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Updating lookup lists...',
                        style: CRMTypography.body.copyWith(
                          color: CRMColors.textOf(context),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Synchronizing database metadata...',
                        style: CRMTypography.body.copyWith(
                          color: CRMColors.textSecondaryOf(context),
                          fontSize: 14,
                          decoration: TextDecoration.none,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isMobile) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Mobile: skip BackdropFilter (expensive continuous GPU blur on every frame).
    // Desktop: keep a lighter blur for the glass bar look.
    final useBlur = !isMobile && !reduceMotion;
    final sigma = useBlur ? CRMBlur.navigationFor(isDark).clamp(0.0, 8.0) : 0.0;
    final barRadius = BorderRadius.circular(CRMBorderRadius.liquidBar);
    final horizontalPad = isMobile ? 10.0 : 14.0;

    Widget bar = Container(
              height: isMobile ? 58 : 62,
              decoration: BoxDecoration(
                borderRadius: barRadius,
                color: isMobile
                    ? CRMColors.surfaceElevatedOf(context).withValues(alpha: isDark ? 0.96 : 0.97)
                    : null,
                gradient: isMobile
                    ? null
                    : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    CRMColors.glassOf(context),
                    CRMColors.glassOf(context).withValues(alpha: isDark ? 0.45 : 0.55),
                  ],
                ),
                border: Border.all(
                  color: (isDark ? Colors.white : CRMColors.primaryOf(context))
                      .withValues(alpha: isDark ? 0.12 : 0.14),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 14),
              child: Stack(
                children: [
                  if (isMobile) ...[
                    // Layer 1: Normal Top Bar Content
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      top: _isMobileSearchActive ? -58.0 : 0.0,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _isMobileSearchActive ? 0.0 : 1.0,
                        child: Row(
                          children: [
                            Builder(
                              builder: (context) => IconButton(
                                icon: Icon(
                                  Icons.menu_rounded,
                                  color: CRMColors.textSecondaryOf(context),
                                ),
                                onPressed: () => Scaffold.of(context).openDrawer(),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: CRMBrandLockup(
                                  expanded: true,
                                  compact: true,
                                  wordmarkColor: CRMColors.textOf(context),
                                  markSize: 24,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.search_rounded,
                                color: CRMColors.textSecondaryOf(context),
                              ),
                              onPressed: () {
                                setState(() {
                                  _isMobileSearchActive = true;
                                });
                                Future.delayed(
                                  const Duration(milliseconds: 50),
                                  () {
                                    _searchFocusNode.requestFocus();
                                  },
                                );
                              },
                            ),
                            _buildNotificationButton(context),
                          ],
                        ),
                      ),
                    ),
                    // Layer 2: Search Bar Content
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      top: _isMobileSearchActive ? 0.0 : -58.0,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _isMobileSearchActive ? 1.0 : 0.0,
                        child: Center(
                          child: Row(
                            children: [
                              Expanded(
                                child: CompositedTransformTarget(
                                  link: _searchLayerLink,
                                  child: Focus(
                                    onFocusChange: (hasFocus) {
                                      if (!hasFocus) {
                                        Future.delayed(
                                          const Duration(milliseconds: 200),
                                          () {
                                            _hideSearchOverlay();
                                            if (mounted) {
                                              setState(() {
                                                _isMobileSearchActive = false;
                                              });
                                            }
                                          },
                                        );
                                      }
                                    },
                                    child: TextField(
                                      controller: _searchController,
                                      focusNode: _searchFocusNode,
                                      style: CRMTypography.body.copyWith(
                                        color: CRMColors.textOf(context),
                                        fontSize: 14,
                                      ),
                                      onChanged: _onSearchChanged,
                                      autofocus: false,
                                      decoration: InputDecoration(
                                        hintText: 'Search...',
                                        hintStyle: CRMTypography.body.copyWith(
                                          color: CRMColors.textMutedOf(context),
                                          fontSize: 14,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.search_rounded,
                                          color: CRMColors.textMutedOf(context),
                                          size: 18,
                                        ),
                                        suffixIcon: IconButton(
                                          icon: const Icon(
                                            Icons.close_rounded,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                            _hideSearchOverlay();
                                            _searchFocusNode.unfocus();
                                            setState(() {
                                              _isMobileSearchActive = false;
                                            });
                                          },
                                        ),
                                        filled: true,
                                        fillColor: CRMColors.groupedBackground.withValues(alpha: 0.55),
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(CRMBorderRadius.round),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(CRMBorderRadius.round),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(CRMBorderRadius.round),
                                          borderSide: BorderSide(
                                            color: CRMColors.primaryOf(context).withValues(alpha: 0.35),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          width: 44,
                          child: IconButton(
                            icon: Icon(
                              _isSidebarExpanded
                                  ? Icons.menu_open_rounded
                                  : Icons.menu_rounded,
                              color: CRMColors.textSecondaryOf(context),
                            ),
                            onPressed: () {
                              setState(() {
                                _isSidebarExpanded = !_isSidebarExpanded;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              width: 380,
                              child: CompositedTransformTarget(
                                link: _searchLayerLink,
                                child: Focus(
                                  onFocusChange: (hasFocus) {
                                    if (!hasFocus) {
                                      Future.delayed(
                                        const Duration(milliseconds: 200),
                                        () {
                                          _hideSearchOverlay();
                                        },
                                      );
                                    }
                                  },
                                  child: TextField(
                                    controller: _searchController,
                                    focusNode: _searchFocusNode,
                                    style: CRMTypography.body.copyWith(
                                      color: CRMColors.textOf(context),
                                      fontSize: 14,
                                    ),
                                    onChanged: _onSearchChanged,
                                    decoration: InputDecoration(
                                      hintText: 'Search PropKart...',
                                      hintStyle: CRMTypography.body.copyWith(
                                        color: CRMColors.textMutedOf(context),
                                        fontSize: 14,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search_rounded,
                                        color: CRMColors.textMutedOf(context),
                                        size: 18,
                                      ),
                                      filled: true,
                                      fillColor: CRMColors.groupedBackground.withValues(alpha: 0.55),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(CRMBorderRadius.round),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(CRMBorderRadius.round),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(CRMBorderRadius.round),
                                        borderSide: BorderSide(
                                          color: CRMColors.primaryOf(context).withValues(alpha: 0.35),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const LiveClockWidget(),
                        const SizedBox(width: 8),
                        _buildNotificationButton(context),
                        const SizedBox(width: 8),
                        _buildQuickActionsButton(context),
                        const SizedBox(width: 8),
                        _buildThemeToggleButton(context),
                      ],
                    ),
                  ],
                ],
              ),
    );

    if (useBlur) {
      bar = ClipRRect(
        borderRadius: barRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: bar,
        ),
      );
    } else {
      bar = ClipRRect(
        borderRadius: barRadius,
        child: bar,
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPad, 8, horizontalPad, 6),
      child: RepaintBoundary(child: bar),
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    return Badge(
      label: Text('$_unreadNotificationsCount'),
      isLabelVisible: _unreadNotificationsCount > 0,
      backgroundColor: CRMColors.primaryOf(context),
      offset: const Offset(-2, 2),
      child: IconButton(
        tooltip: 'Notifications',
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        icon: AnimatedScale(
          scale: _unreadNotificationsCount > 0 ? 1.05 : 1.0,
          duration: CRMMotion.fast,
          child: Icon(
            _unreadNotificationsCount > 0
                ? Icons.notifications_active_rounded
                : Icons.notifications_none_rounded,
            color: _unreadNotificationsCount > 0
                ? CRMColors.primaryOf(context)
                : CRMColors.textSecondaryOf(context),
            size: 22,
          ),
        ),
        onPressed: () {
          setState(() => _notificationsPanelOpen = true);
          _fetchNotifications();
        },
      ),
    );
  }

  Widget _buildNotificationsPanel(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sigma = MediaQuery.disableAnimationsOf(context)
        ? CRMBlur.reduced
        : CRMBlur.notificationPanel;
    final unread = _notifications.where((n) => n['is_read'] == false).toList();
    final read = _notifications.where((n) => n['is_read'] == true).toList();

    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _notificationsPanelOpen = false),
        child: Container(
          color: CRMColors.overlayOf(context),
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {},
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 1, end: 0),
              duration: CRMMotion.sheet,
              curve: CRMMotion.emphasized,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(320 * value, 0),
                  child: child,
                );
              },
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(20),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: MediaQuery.of(context).size.width < 420
                          ? MediaQuery.of(context).size.width * 0.92
                          : 380,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: CRMColors.glassOf(context),
                        border: Border(
                          left: BorderSide(
                            color: CRMColors.primaryOf(context)
                                .withValues(alpha: 0.25),
                          ),
                        ),
                        boxShadow: CRMShadows.floating,
                      ),
                      child: SafeArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Notifications',
                                          style: CRMTypography.sectionTitle
                                              .copyWith(
                                            color: CRMColors.textOf(context),
                                          ),
                                        ),
                                        Text(
                                          'Stay ahead of deals, visits, and team updates',
                                          style: CRMTypography.benefit.copyWith(
                                            color: CRMColors
                                                .textSecondaryOf(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_unreadNotificationsCount > 0)
                                    TextButton(
                                      onPressed: _markAllNotificationsRead,
                                      child: Text(
                                        'Mark all',
                                        style: CRMTypography.captionBold
                                            .copyWith(
                                          color: CRMColors.primaryOf(context),
                                        ),
                                      ),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded),
                                    onPressed: () => setState(
                                      () => _notificationsPanelOpen = false,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Divider(
                              height: 1,
                              color: CRMColors.borderOf(context)
                                  .withValues(alpha: 0.5),
                            ),
                            Expanded(
                              child: _isLoadingNotifications &&
                                      _notifications.isEmpty
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : _notifications.isEmpty
                                      ? _buildNotificationsEmpty(context, isDark)
                                      : ListView(
                                          padding: const EdgeInsets.all(12),
                                          children: [
                                            if (unread.isNotEmpty) ...[
                                              _notifSectionLabel('New'),
                                              ...unread.map(
                                                (n) => _buildNotificationTile(n),
                                              ),
                                            ],
                                            if (read.isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              _notifSectionLabel('Earlier'),
                                              ...read.map(
                                                (n) => _buildNotificationTile(n),
                                              ),
                                            ],
                                            if (_notificationsPage <
                                                _totalNotificationPages)
                                              TextButton(
                                                onPressed: () =>
                                                    _fetchNotifications(
                                                  loadMore: true,
                                                ),
                                                child: Text(
                                                  'Load more',
                                                  style: CRMTypography
                                                      .captionBold
                                                      .copyWith(
                                                    color: CRMColors
                                                        .primaryOf(context),
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _notifSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Text(
        label.toUpperCase(),
        style: CRMTypography.captionBold.copyWith(
          color: CRMColors.primaryOf(context),
          letterSpacing: 1.1,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildNotificationsEmpty(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: CRMColors.primaryOf(context).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 36,
                color: CRMColors.primaryOf(context),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You\'re all caught up',
              style: CRMTypography.cardTitle.copyWith(
                color: CRMColors.textOf(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'New property alerts, visit reminders, and deal updates will appear here.',
              textAlign: TextAlign.center,
              style: CRMTypography.benefit.copyWith(
                color: CRMColors.textSecondaryOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(dynamic n) {
    final isRead = n['is_read'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isRead
            ? CRMColors.cardBgOf(context).withValues(alpha: 0.5)
            : CRMColors.primaryOf(context).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRead
              ? CRMColors.borderOf(context).withValues(alpha: 0.4)
              : CRMColors.primaryOf(context).withValues(alpha: 0.25),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Icon(
          isRead
              ? Icons.notifications_none_rounded
              : Icons.notifications_active_rounded,
          color: isRead
              ? CRMColors.textMutedOf(context)
              : CRMColors.primaryOf(context),
        ),
        title: Text(
          n['title'] ?? '',
          style: CRMTypography.captionBold.copyWith(
            color: CRMColors.textOf(context),
            fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              n['message'] ?? '',
              style: CRMTypography.caption.copyWith(
                color: CRMColors.textSecondaryOf(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getRelativeTime(n['created_at'] ?? ''),
              style: CRMTypography.footnote.copyWith(
                color: CRMColors.textMutedOf(context),
                fontSize: 10,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
          color: CRMColors.danger,
          onPressed: () => _deleteNotification(n['id']),
        ),
        onTap: () {
          if (!isRead) _markNotificationRead(n['id']);
        },
      ),
    );
  }

  Widget _buildQuickActionsButton(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.add_circle_outline_rounded, color: CRMColors.primary),
      tooltip: 'Quick Actions',
      onSelected: (value) {
        if (value == 'property') {
          context.go('/properties?action=add');
        } else if (value == 'requirement') {
          context.go('/requirements?action=add');
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(
          value: 'property',
          child: Row(
            children: [
              Icon(Icons.add_business_rounded, color: CRMColors.primary, size: 20),
              const SizedBox(width: CRMSpacing.s),
              Text('Add Property', style: TextStyle(color: CRMColors.textOf(context))),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'requirement',
          child: Row(
            children: [
              Icon(Icons.add_task_rounded, color: CRMColors.primary, size: 20),
              const SizedBox(width: CRMSpacing.s),
              Text('Add Requirement', style: TextStyle(color: CRMColors.textOf(context))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeToggleButton(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    return IconButton(
      icon: Icon(
        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
        color: isDark ? CRMColors.warning : CRMColors.textSecondary,
      ),
      tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
      onPressed: () {
        ThemeManager().toggleTheme();
      },
    );
  }

  Widget _buildSidebarContent(String currentPath, AuthState userState, {bool isMobile = false, double? sidebarWidth}) {
    String userRole = '';
    String userFullName = '';
    String? userProfilePhoto;
    
    if (userState is Authenticated) {
      userRole = userState.user.role;
      userFullName = userState.user.fullName;
      userProfilePhoto = userState.user.profilePhoto;
    }

    final isExpanded = isMobile || (sidebarWidth == null ? _isSidebarExpanded : sidebarWidth > 200.0);
    final displayRole = isExpanded ? userRole : '';
    final displayFullName = isExpanded ? userFullName : '';

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: CRMSpacing.l,
              horizontal: isExpanded ? CRMSpacing.l : CRMSpacing.xs,
            ),
            child: Align(
              alignment: isExpanded ? Alignment.centerLeft : Alignment.center,
              child: CRMBrandLockup(
                expanded: isExpanded,
                compact: false,
                markSize: isExpanded ? 38 : 32,
                wordmarkColor: CRMColors.sidebarText,
              ),
            ),
          ),
          Divider(color: CRMColors.sidebarBorder, height: 1, thickness: 0.5),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                vertical: CRMSpacing.m,
                horizontal: isExpanded ? CRMSpacing.s : CRMSpacing.xxs,
              ),
              children: [
                _buildSidebarItem(Icons.dashboard_rounded, 'Dashboard', '/dashboard', currentPath, isMobile, isExpanded),
                _buildSidebarItem(Icons.home_work_rounded, 'Properties', '/properties', currentPath, isMobile, isExpanded),
                _buildSidebarItem(Icons.assignment_rounded, 'Leads', '/requirements', currentPath, isMobile, isExpanded),
                if (userRole == 'Admin' || userRole == 'Super Admin')
                  _buildSidebarItem(Icons.people_outline_rounded, 'Employees', '/users', currentPath, isMobile, isExpanded),
                _buildSidebarItem(Icons.folder_open_rounded, 'Library', '/library', currentPath, isMobile, isExpanded),
                _buildSidebarItem(Icons.settings_rounded, 'Settings', '/settings', currentPath, isMobile, isExpanded),
                _buildSidebarItem(Icons.delete_sweep_rounded, 'Recycle Bin', '/bin', currentPath, isMobile, isExpanded),
              ],
            ),
          ),
          Divider(color: CRMColors.sidebarBorder, height: 1, thickness: 0.5),
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: CRMSpacing.m,
              horizontal: isExpanded ? CRMSpacing.m : CRMSpacing.xs,
            ),
            child: Row(
              mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    final currentRoute = GoRouterState.of(context).uri.toString();
                    if (currentRoute != '/profile') {
                      context.go('/profile');
                    }
                  },
                  child: CircleAvatar(
                    backgroundColor: CRMColors.primary.withValues(alpha: 0.18),
                    backgroundImage: (userProfilePhoto != null && userProfilePhoto!.isNotEmpty)
                        ? ResizeImage(
                            NetworkImage(userProfilePhoto!),
                            width: (40 * MediaQuery.devicePixelRatioOf(context)).round(),
                            height: (40 * MediaQuery.devicePixelRatioOf(context)).round(),
                          )
                        : null,
                    child: (userProfilePhoto != null && userProfilePhoto!.isNotEmpty)
                        ? null
                        : Icon(Icons.person_outline_rounded, color: CRMColors.primary),
                  ),
                ),
                if (isExpanded) ...[
                  const SizedBox(width: CRMSpacing.m),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        final currentRoute = GoRouterState.of(context).uri.toString();
                        if (currentRoute != '/profile') {
                          context.go('/profile');
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayFullName,
                            style: CRMTypography.captionBold.copyWith(color: CRMColors.sidebarText),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            displayRole,
                            style: CRMTypography.caption.copyWith(color: CRMColors.sidebarTextSecondary, fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Logout',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.logout_rounded, color: CRMColors.danger, size: 20),
                    onPressed: _handleLogout,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildSidebarItem(
    IconData icon,
    String label,
    String route,
    String currentPath,
    bool isMobile,
    bool isExpanded,
  ) {
    return _SidebarItem(
      icon: icon,
      label: label,
      route: route,
      currentPath: currentPath,
      isMobile: isMobile,
      isSidebarExpanded: isExpanded,
      onTap: () {
        if (isMobile) {
          Navigator.pop(context);
        }
        if (currentPath != route) {
          context.go(route);
        }
      },
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentPath;
  final bool isMobile;
  final bool isSidebarExpanded;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentPath,
    required this.isMobile,
    required this.isSidebarExpanded,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  bool _isRouteActive(String currentPath, String route) {
    // For the Library sidebar item (/library), also highlight when on sub-routes
    if (route == '/library') {
      return currentPath == '/library' ||
          currentPath.startsWith('/rental-library') ||
          currentPath.startsWith('/resale-library') ||
          currentPath.startsWith('/service-agent-library');
    }
    return currentPath.startsWith(route);
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = _isRouteActive(widget.currentPath, widget.route);
    final isExpanded = widget.isSidebarExpanded || widget.isMobile;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: EdgeInsets.symmetric(
              horizontal: isExpanded ? CRMSpacing.m : CRMSpacing.xs,
              vertical: CRMSpacing.s,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? CRMColors.primary.withValues(alpha: 0.14)
                  : (_isHovered
                      ? CRMColors.primary.withValues(alpha: 0.06)
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? CRMColors.primary.withValues(alpha: 0.32)
                    : (_isHovered
                        ? CRMColors.primary.withValues(alpha: 0.12)
                        : Colors.transparent),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: _isHovered ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    widget.icon,
                    color: isSelected
                        ? CRMColors.primary
                        : CRMColors.sidebarTextSecondary,
                    size: 20,
                  ),
                ),
                if (isExpanded) ...[
                  const SizedBox(width: CRMSpacing.m),
                  Expanded(
                    child: AnimatedPadding(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.only(left: _isHovered ? 4.0 : 0.0),
                      child: Text(
                        widget.label,
                        style: CRMTypography.bodyMedium.copyWith(
                          color: isSelected
                              ? CRMColors.primary
                              : CRMColors.sidebarText,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: CRMColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: CRMColors.primary.withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class PubSubDivider extends PopupMenuEntry<Never> {
  const PubSubDivider({super.key});
  @override
  double get height => 1;
  @override
  bool represents(void value) => false;
  @override
  State<PubSubDivider> createState() => _PubSubDividerState();
}
class _PubSubDividerState extends State<PubSubDivider> {
  @override
  Widget build(BuildContext context) => const Divider(height: 1, thickness: 1);
}

class LiveClockWidget extends StatefulWidget {
  const LiveClockWidget({super.key});

  @override
  State<LiveClockWidget> createState() => _LiveClockWidgetState();
}

class _LiveClockWidgetState extends State<LiveClockWidget> {
  Timer? _timer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    // Minute-level updates are enough for HH:MM display and avoid 1Hz shell churn.
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    int hour = dt.hour % 12;
    if (hour == 0) hour = 12;
    final minStr = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minStr $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = _formatTime(_currentTime);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: CRMColors.primaryOf(context).withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(CRMBorderRadius.round),
          border: Border.all(
            color: CRMColors.primaryOf(context).withValues(alpha: 0.28),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: CRMColors.primaryOf(context),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formattedTime,
              style: CRMTypography.clockDisplay.copyWith(
                color: CRMColors.textOf(context),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xE6121A2A)
                      : const Color(0xF2FFFFFF),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildNavItem(
                      context: context,
                      index: 0,
                      iconOutline: Icons.dashboard_outlined,
                      iconFilled: Icons.dashboard_rounded,
                      label: 'Dashboard',
                    ),
                    _buildNavItem(
                      context: context,
                      index: 1,
                      iconOutline: Icons.home_work_outlined,
                      iconFilled: Icons.home_work_rounded,
                      label: 'Properties',
                    ),
                    _buildNavItem(
                      context: context,
                      index: 3,
                      iconOutline: Icons.assignment_outlined,
                      iconFilled: Icons.assignment_rounded,
                      label: 'Requirements',
                    ),
                    _buildNavItem(
                      context: context,
                      index: 4,
                      iconOutline: Icons.person_outline_rounded,
                      iconFilled: Icons.person_rounded,
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onItemSelected(2),
                customBorder: const CircleBorder(),
                child: Ink(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: CRMColors.gradientPrimary,
                    ),
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData iconOutline,
    required IconData iconFilled,
    required String label,
  }) {
    final bool isSelected = selectedIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = CRMColors.primaryOf(context);
    final inactiveColor = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onItemSelected(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : const Color(0xFFE8E8E8))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isSelected ? iconFilled : iconOutline,
                color: isSelected ? activeColor : inactiveColor,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? CRMColors.textOf(context)
                    : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
