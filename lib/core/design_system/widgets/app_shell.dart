import '../../../core/services/notification_center.dart';
import '../../../core/services/app_notifier_service.dart';
import '../../../core/services/platform_notifier/platform_notifier.dart';
import '../../../features/dashboard/repository/dashboard_repository.dart';
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
import '../tokens/app_shadows.dart';
import 'crm_brand_lockup.dart';
import 'package:dio/dio.dart';
import '../../api/dio_client.dart';
import '../../utils/budget_formatter.dart';
import '../../network/sync_manager.dart';
import 'dart:async';
import '../../../core/storage/repository_coordinator.dart';
import '../../../features/properties/services/properties_service.dart';
import '../../../features/properties/models/property_model.dart';
import '../../../features/properties/repository/properties_repository.dart';
import '../../navigation/mobile_system_back_handler.dart';
import '../../../../features/shell/widgets/sidebar.dart';
import '../../../../features/shell/widgets/top_bar.dart';
import '../../../../features/team_messages/services/team_messages_service.dart';

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
  double _sidebarWidth = 245.0;
  bool _isDraggingSidebar = false;
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
        final location = GoRouter.of(
          context,
        ).routerDelegate.currentConfiguration.last.matchedLocation;
        if (index != _previousIndex || location != _getTabRoutePath(index)) {
          _previousIndex = index;
          context.go(_getTabRoutePath(index));
        }
      }
    });

    _notifCenterSub = NotificationCenter.stream.listen((newNotif) {
      if ((newNotif['action'] ?? '').toString() == 'refresh' ||
          (newNotif['id'] ?? '').toString() == 'refresh') {
        return;
      }
      if (mounted) {
        setState(() {
          _notifications.insert(0, newNotif);
          _unreadNotificationsCount = _notifications
              .where((n) => n['is_read'] == false)
              .length;
        });

        if (newNotif['notifyToast'] == false) {
          return;
        }

        final notifId = (newNotif['id'] ?? '').toString();
        if (notifId.isNotEmpty && !_knownNotificationIds.contains(notifId)) {
          _knownNotificationIds.add(notifId);
          AppNotifierService.notify(
            title: newNotif['title'] ?? 'Notification',
            message: newNotif['message'] ?? '',
            type: newNotif['type'] ?? 'general',
            route: newNotif['route'],
            data: newNotif,
          );
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await AppNotifierService.init();
      String? userId;
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        userId = authState.user.id;
      }
      await NotificationCenter.init(userId: userId);
      await _fetchNotifications();
      _notificationsTimer?.cancel();
      _notificationsTimer = Timer.periodic(const Duration(seconds: 25), (
        _,
      ) async {
        if (mounted) {
          await _fetchNotifications();
          await AppNotifierService.checkAndTriggerWelcomeIfNewlyGranted();
        }
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
  final Set<String> _knownNotificationIds = {};
  bool _isFirstNotifFetch = true;
  int _unreadNotificationsCount = 0;
  int _unreadTeamMessagesCount = 0;
  bool _isLoadingNotifications = false;
  int _notificationsPage = 1;
  int _totalNotificationPages = 1;
  Timer? _notificationsTimer;
  StreamSubscription<Map<String, dynamic>>? _notifCenterSub;

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
    final themeManager = ThemeManager();
    final isDark = themeManager.isDarkMode;
    final primaryColor = themeManager.primaryColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CRMBorderRadius.sheet),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFF8FAFC)
                            : const Color(0xFF14213D),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF68738A),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add_home_work_rounded,
                      color: primaryColor,
                    ),
                  ),
                  title: Text(
                    'Add New Property',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF14213D),
                    ),
                  ),
                  subtitle: Text(
                    'Create a rental or re-sale listing',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF68738A),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/properties?action=add');
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person_add_rounded,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  title: Text(
                    'Add New Lead / Requirement',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF14213D),
                    ),
                  ),
                  subtitle: Text(
                    'Capture customer demand details',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF68738A),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/requirements?action=add');
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                  title: Text(
                    'Schedule Site Visit',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF14213D),
                    ),
                  ),
                  subtitle: Text(
                    'Book client inspection appointment',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF68738A),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/dashboard');
                  },
                ),
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
    if (!mounted) return;
    setState(() {
      _isLoadingNotifications = true;
      if (!loadMore) {
        _notificationsPage = 1;
      } else {
        _notificationsPage++;
      }
    });

    String? role;
    String? userId;
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      role = authState.user.role;
      userId = authState.user.id;
    }
    await NotificationCenter.init(userId: userId);

    List<dynamic> apiList = [];
    int apiTotalPages = 1;
    bool keepExistingList = false;
    try {
      final response = await DioClient.dio.get(
        '/notifications',
        queryParameters: {
          'page': _notificationsPage,
          'limit': 100,
          '_ts': DateTime.now().millisecondsSinceEpoch,
        },
        options: Options(
          headers: const {
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (response.statusCode == 304) {
        keepExistingList = true;
      } else {
        final raw = response.data;
        if (raw is List) {
          apiList = List<dynamic>.from(raw);
        } else if (raw is Map) {
          final dataNode = raw['data'] ?? raw;
          if (dataNode is List) {
            apiList = List<dynamic>.from(dataNode);
          } else if (dataNode is Map && dataNode['notifications'] is List) {
            apiList = List<dynamic>.from(dataNode['notifications'] as List);
          } else if (raw['notifications'] is List) {
            apiList = List<dynamic>.from(raw['notifications'] as List);
          }
          final pagination = dataNode is Map ? (dataNode['pagination'] ?? {}) : {};
          apiTotalPages = pagination['totalPages'] ?? 1;
        }
      }
    } catch (_) {
      keepExistingList = _notifications.isNotEmpty && !loadMore;
    }

    if (keepExistingList) {
      apiList = _notifications
          .where((n) => n is Map && !(n['id']?.toString() ?? '').startsWith('local_') && !(n['id']?.toString() ?? '').startsWith('due_'))
          .toList();
    }

    if (!loadMore) {
      try {
        final assignedRes = await DioClient.dio.get(
          '/notifications',
          queryParameters: {
            'page': 1,
            'limit': 50,
            'type': 'lead_assigned',
            '_ts': DateTime.now().millisecondsSinceEpoch,
          },
          options: Options(
            headers: const {
              'Cache-Control': 'no-cache',
              'Pragma': 'no-cache',
            },
            validateStatus: (status) => status != null && status < 500,
          ),
        );
        if (assignedRes.statusCode != null && assignedRes.statusCode! < 400) {
          List<dynamic> assignedList = [];
          final assignedRaw = assignedRes.data;
          if (assignedRaw is List) {
            assignedList = List<dynamic>.from(assignedRaw);
          } else if (assignedRaw is Map) {
            final dataNode = assignedRaw['data'] ?? assignedRaw;
            if (dataNode is List) {
              assignedList = List<dynamic>.from(dataNode);
            } else if (dataNode is Map && dataNode['notifications'] is List) {
              assignedList = List<dynamic>.from(dataNode['notifications'] as List);
            }
          }
          if (assignedList.isNotEmpty) {
            apiList = [...assignedList, ...apiList];
          }
        }
      } catch (_) {}
    }

    if (!loadMore) {
      await _checkOverdueFollowupsForBell(existingApi: apiList);
    }

    final isAdminOrSuperAdmin = role == 'Admin' || role == 'Super Admin';

    final currentPanel = _notifications.where((raw) {
      if (raw is! Map) return false;
      final id = (raw['id'] ?? '').toString();
      final action = (raw['action'] ?? '').toString();
      return id != 'refresh' && action != 'refresh';
    }).toList();
    final combined = [
      ...apiList,
      ...NotificationCenter.localNotifications,
      ...currentPanel,
    ];
    final uniqueNotifs = <dynamic>[];
    final seenIds = <String>{};
    final seenFingerprints = <String>{};
    for (final raw in combined) {
      if (raw is! Map) continue;
      final n = Map<String, dynamic>.from(raw);
      final payload = n['payload'] is Map ? Map<String, dynamic>.from(n['payload'] as Map) : <String, dynamic>{};
      n['type'] = (n['type'] ?? payload['type'] ?? '').toString();
      if ((n['type'] as String).isEmpty &&
          (n['title'] ?? '').toString().toLowerCase().contains('assigned')) {
        n['type'] = 'lead_assigned';
      }
      n['route'] = n['route'] ?? payload['route'];
      if ((n['route'] == null || n['route'].toString().isEmpty) && n['type'] == 'lead_assigned') {
        n['route'] = '/requirements?group=assigned';
      }
      final id = n['id']?.toString() ?? '';
      if (id == 'refresh' || (n['action'] ?? '').toString() == 'refresh') {
        continue;
      }
      final type = n['type'].toString().toLowerCase();
      final isRead = n['is_read'] == true || n['is_read'] == 'true' || n['is_read'] == 1;
      n['message'] = (n['message'] ?? '').toString().replaceAll(
        RegExp(r'\s*\(Sales Person:\s*System\)', caseSensitive: false),
        '',
      );

      if (!isAdminOrSuperAdmin &&
          (type == 'forgot_password' || type == 'password_reset')) {
        continue;
      }

      final fuId = (payload['followupId'] ?? '').toString();
      final titleLower = (n['title'] ?? '').toString().toLowerCase();
      final reqId = (payload['requirementId'] ?? '').toString();
      final propId = (payload['propertyId'] ?? '').toString();
      final isDueNotif = _isDueAlertNotif(type, titleLower);
      final clientKey = _dueClientKey(n, payload);
      String fingerprint;
      if (isDueNotif && clientKey.isNotEmpty) {
        fingerprint = 'dueclient|$clientKey';
      } else if (isDueNotif && fuId.isNotEmpty) {
        fingerprint = 'duefu|$fuId';
      } else if (fuId.isNotEmpty && isDueNotif) {
        fingerprint = 'duefu|$fuId';
      } else {
        fingerprint =
            '$type|$titleLower|${(n['message'] ?? '').toString().toLowerCase().replaceAll(RegExp(r'\s*\(sales person:[^)]*\)'), '')}';
      }
      if (!isDueNotif) {
        if (type.contains('assign')) {
          final audience = (payload['audience'] ?? '').toString();
          if (clientKey.isNotEmpty &&
              seenFingerprints.contains('assignedclient|$audience|$clientKey')) {
            continue;
          }
          fingerprint = reqId.isNotEmpty
              ? 'assigned|$reqId|$audience|$titleLower'
              : 'assignedclient|$audience|$clientKey|$titleLower';
        } else if (propId.isNotEmpty && (type.contains('property') || type.contains('created'))) {
          fingerprint = 'createdprop|$propId';
        } else if (reqId.isNotEmpty &&
            (type.contains('created') || type.contains('new_lead'))) {
          fingerprint = 'createdreq|$reqId';
        }
      }
      final isAssigned = type.contains('assign') || titleLower.contains('assigned');
      if (id.isNotEmpty && seenIds.contains(id)) {
        continue;
      }
      if (id.isNotEmpty && NotificationCenter.deletedIds.contains(id) && !isAssigned) {
        continue;
      }
      if (isAssigned) {
        final notifKey =
            '${n['title']}_${n['message']}'.replaceAll(' ', '').toLowerCase();
        if (NotificationCenter.deletedIds.contains(notifKey)) {
          continue;
        }
      }
      if (isDueNotif && fuId.isNotEmpty && seenFingerprints.contains('duefu|$fuId')) {
        continue;
      }
      if (isDueNotif && clientKey.isNotEmpty && seenFingerprints.contains('dueclient|$clientKey')) {
        continue;
      }
      if (seenFingerprints.contains(fingerprint)) {
        continue;
      }

      if (id.isNotEmpty) seenIds.add(id);
      if (isDueNotif && fuId.isNotEmpty) seenFingerprints.add('duefu|$fuId');
      if (isDueNotif && clientKey.isNotEmpty) seenFingerprints.add('dueclient|$clientKey');
      if (!isDueNotif && type.contains('assign') && clientKey.isNotEmpty) {
        seenFingerprints.add(
          'assignedclient|${payload['audience'] ?? ''}|$clientKey',
        );
      }
      seenFingerprints.add(fingerprint);
      n['is_read'] = isRead;
      uniqueNotifs.add(n);

      if (!_isFirstNotifFetch && !isRead && id.isNotEmpty && !_knownNotificationIds.contains(id)) {
        final alreadyLocalAssign = isAssigned &&
            NotificationCenter.localNotifications.any((l) {
              final lp = l['payload'] is Map
                  ? Map<String, dynamic>.from(l['payload'] as Map)
                  : <String, dynamic>{};
              final localClient =
                  (lp['clientName'] ?? '').toString().trim().toLowerCase();
              return (l['type'] ?? '').toString().toLowerCase().contains('assign') &&
                  localClient.isNotEmpty &&
                  localClient == clientKey;
            });
        if (!isDueNotif &&
            type != 'lead_created' &&
            type != 'property_created' &&
            !(isAssigned && alreadyLocalAssign)) {
          AppNotifierService.notify(
            title: n['title'] ?? 'Notification',
            message: n['message'] ?? '',
            type: n['type'] ?? 'general',
            route: n['route'],
            data: n,
          );
        }
      }
    }

    _knownNotificationIds.addAll(seenIds);
    _isFirstNotifFetch = false;

    int unreadMsgCount = 0;
    try {
      unreadMsgCount = await TeamMessagesService().getUnreadCount();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _notifications = uniqueNotifs;
        _totalNotificationPages = apiTotalPages;
        _unreadNotificationsCount = _notifications
            .where((n) => n['is_read'] == false)
            .length;
        _unreadTeamMessagesCount = unreadMsgCount;
        _isLoadingNotifications = false;
      });
    }
  }

  Future<void> _markNotificationRead(String id) async {
    try {
      if (id.startsWith('local_') || id.startsWith('due_')) {
        await NotificationCenter.markAsRead(id);
      } else {
        await DioClient.dio.patch('/notifications/$id/read');
      }
      _fetchNotifications();
    } catch (_) {}
  }

  Future<void> _markAllNotificationsRead() async {
    try {
      await NotificationCenter.markAllAsRead();
      await DioClient.dio.patch('/notifications/read-all');
      _fetchNotifications();
    } catch (_) {}
  }

  Future<void> _deleteNotification(String id) async {
    try {
      dynamic notif;
      try {
        notif = _notifications.firstWhere((n) => n['id']?.toString() == id);
      } catch (_) {}
      final title = notif?['title']?.toString();
      final message = notif?['message']?.toString();

      if (id.startsWith('local_') || id.startsWith('due_')) {
        await NotificationCenter.deleteNotification(
          id,
          title: title,
          message: message,
        );
      } else {
        await NotificationCenter.deleteNotification(
          id,
          title: title,
          message: message,
        );
        await DioClient.dio.delete('/notifications/$id');
      }
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

  int _levenshteinDistance(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s.codeUnitAt(i) == t.codeUnitAt(j)) ? 0 : 1;
        int subCost = v0[j] + cost;
        int insCost = v1[j] + 1;
        int delCost = v0[j + 1] + 1;
        v1[j + 1] = subCost < insCost
            ? (subCost < delCost ? subCost : delCost)
            : (insCost < delCost ? insCost : delCost);
      }
      for (int j = 0; j <= t.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v0[t.length];
  }

  bool _isFuzzyMatchToken(
      String token, List<String> fieldStrings, List<String> fieldWords) {
    if (token.isEmpty) return true;

    // 1. Direct substring match in any field string
    for (final fs in fieldStrings) {
      if (fs.contains(token)) return true;
      if (token.length >= 4 && fs.length >= 3 && token.contains(fs)) return true;
    }

    // 2. Word level matching (exact, prefix, or Levenshtein distance)
    for (final w in fieldWords) {
      if (w.isEmpty) continue;
      if (w == token || w.contains(token) || token.contains(w)) return true;

      if (token.length <= 3) {
        if (w.startsWith(token)) return true;
      } else if (token.length <= 6) {
        if (_levenshteinDistance(token, w) <= 1) return true;
      } else {
        if (_levenshteinDistance(token, w) <= 2) return true;
      }
    }
    return false;
  }

  void _addStr(List<String> list, dynamic val) {
    if (val != null) {
      final s = val.toString().trim().toLowerCase();
      if (s.isNotEmpty) list.add(s);
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);
    _showSearchOverlay();
    try {
      final authState = context.read<AuthBloc>().state;
      String? currentUserRole;
      if (authState is Authenticated) {
        currentUserRole = authState.user.role;
      }
      final bool isUserAdminOrSuperAdmin =
          currentUserRole == 'Admin' || currentUserRole == 'Super Admin';

      // Standardize query & aliases
      String queryNorm = query.toLowerCase().trim();
      queryNorm = queryNorm.replaceAll(RegExp(r'(\d+)\s*bhk'), r'$1 bhk');
      queryNorm = queryNorm.replaceAll(RegExp(r'\bresel(l)?\b'), 'resale');
      queryNorm = queryNorm.replaceAll(RegExp(r'\bre-sale\b'), 'resale');

      final queryTokens = queryNorm
          .split(RegExp(r'[\s,/\-]+'))
          .where((t) => t.isNotEmpty)
          .toList();

      // 1. Active Properties (with fallback to repository API if local is empty)
      List<dynamic> props = [];
      try {
        props = await RepositoryCoordinator().propertyLocal.getProperties();
      } catch (_) {}
      if (props.isEmpty) {
        try {
          props = await PropertiesRepository().getProperties();
        } catch (_) {}
      }

      final matchedProps = props
          .where((p) {
            final fieldStrings = <String>[];
            _addStr(fieldStrings, p.propertyCode);
            _addStr(fieldStrings, p.title);
            _addStr(fieldStrings, p.ownerName);
            _addStr(fieldStrings, p.ownerMobile);
            _addStr(fieldStrings, p.areaName);
            _addStr(fieldStrings, p.configurationName);
            _addStr(fieldStrings, p.createdAt);
            _addStr(fieldStrings, p.propertyStatusName);
            _addStr(fieldStrings, p.superBuiltupArea);
            _addStr(fieldStrings, p.propertyTypeName);
            _addStr(fieldStrings, p.categoryName);
            _addStr(fieldStrings, p.remarks);
            _addStr(fieldStrings, p.description);

            final configLower = p.configurationName?.toLowerCase() ?? '';
            if (configLower.isNotEmpty) {
              _addStr(fieldStrings, configLower.replaceAll(' ', ''));
              _addStr(fieldStrings, configLower.replaceAll(' ', '-'));
            }
            final categoryLower = p.categoryName?.toLowerCase() ?? '';
            if (categoryLower.contains('re-sale') || categoryLower.contains('resale')) {
              fieldStrings.add('resale');
              fieldStrings.add('re-sale');
              fieldStrings.add('resel');
            }

            if (isUserAdminOrSuperAdmin) {
              _addStr(fieldStrings, p.createdByName);
            }

            final fieldWords = fieldStrings
                .join(' ')
                .split(RegExp(r'[^a-zA-Z0-9]+'))
                .where((w) => w.isNotEmpty)
                .toList();

            return queryTokens.every(
              (token) => _isFuzzyMatchToken(token, fieldStrings, fieldWords),
            );
          })
          .map(
            (p) => {
              'id': p.id,
              'title': p.title,
              'property_code': p.propertyCode,
              'price': p.price,
              'is_recycle_bin': false,
            },
          )
          .toList();

      // 1b. Recycle Bin / Deleted Properties
      List<Map<String, dynamic>> matchedBinProps = [];
      try {
        final binRes = await PropertiesService().getBinProperties();
        final binData = binRes['data'] as Map<String, dynamic>? ?? {};
        final binList = binData['properties'] as List? ?? [];
        final binProps = binList.map((p) => PropertyModel.fromJson(p)).toList();

        matchedBinProps = binProps
            .where((p) {
              final fieldStrings = <String>[];
              _addStr(fieldStrings, p.propertyCode);
              _addStr(fieldStrings, p.title);
              _addStr(fieldStrings, p.ownerName);
              _addStr(fieldStrings, p.ownerMobile);
              _addStr(fieldStrings, p.areaName);
              _addStr(fieldStrings, p.configurationName);
              _addStr(fieldStrings, p.createdAt);
              _addStr(fieldStrings, p.propertyStatusName);
              _addStr(fieldStrings, p.superBuiltupArea);
              _addStr(fieldStrings, p.propertyTypeName);
              _addStr(fieldStrings, p.categoryName);
              _addStr(fieldStrings, p.remarks);
              _addStr(fieldStrings, p.description);

              final configLower = p.configurationName?.toLowerCase() ?? '';
              if (configLower.isNotEmpty) {
                _addStr(fieldStrings, configLower.replaceAll(' ', ''));
                _addStr(fieldStrings, configLower.replaceAll(' ', '-'));
              }
              final categoryLower = p.categoryName.toLowerCase();
              if (categoryLower.contains('re-sale') || categoryLower.contains('resale')) {
                fieldStrings.add('resale');
                fieldStrings.add('re-sale');
                fieldStrings.add('resel');
              }

              if (isUserAdminOrSuperAdmin) {
                _addStr(fieldStrings, p.createdByName);
              }

              final fieldWords = fieldStrings
                  .join(' ')
                  .split(RegExp(r'[^a-zA-Z0-9]+'))
                  .where((w) => w.isNotEmpty)
                  .toList();

              return queryTokens.every(
                (token) => _isFuzzyMatchToken(token, fieldStrings, fieldWords),
              );
            })
            .map(
              (p) => {
                'id': p.id,
                'title': '[In Recycle Bin] ${p.title}',
                'property_code': p.propertyCode,
                'price': p.price,
                'is_recycle_bin': true,
              },
            )
            .toList();
      } catch (_) {}

      final allMatchedProps = [...matchedProps, ...matchedBinProps].take(12).toList();

      // 2. Requirements / Leads
      final reqs = await RepositoryCoordinator().requirementLocal.getRequirements();
      final matchedReqs = reqs
          .where((r) {
            final fieldStrings = <String>[];
            _addStr(fieldStrings, r.clientName);
            _addStr(fieldStrings, r.clientMobile);
            _addStr(fieldStrings, r.remarks);
            _addStr(fieldStrings, r.propertyTypeName);
            _addStr(fieldStrings, r.configurationName);
            _addStr(fieldStrings, r.categoryName);
            for (final a in r.areaNames) {
              _addStr(fieldStrings, a);
            }
            if (isUserAdminOrSuperAdmin) {
              _addStr(fieldStrings, r.creatorName);
              _addStr(fieldStrings, r.assigneeName);
            }

            final fieldWords = fieldStrings
                .join(' ')
                .split(RegExp(r'[^a-zA-Z0-9]+'))
                .where((w) => w.isNotEmpty)
                .toList();

            return queryTokens.every(
              (token) => _isFuzzyMatchToken(token, fieldStrings, fieldWords),
            );
          })
          .map(
            (r) => {
              'id': r.id,
              'customer_name': r.clientName,
              'mobile': r.clientMobile,
            },
          )
          .take(12)
          .toList();

      // 3. Owners
      final owners = await RepositoryCoordinator().ownerLocal.getOwners();
      final matchedOwners = owners
          .where((o) {
            final fieldStrings = <String>[];
            _addStr(fieldStrings, o.name);
            _addStr(fieldStrings, o.mobile);
            _addStr(fieldStrings, o.email);

            final fieldWords = fieldStrings
                .join(' ')
                .split(RegExp(r'[^a-zA-Z0-9]+'))
                .where((w) => w.isNotEmpty)
                .toList();

            return queryTokens.every(
              (token) => _isFuzzyMatchToken(token, fieldStrings, fieldWords),
            );
          })
          .map((o) => {'id': o.id, 'name': o.name, 'mobile': o.mobile})
          .take(8)
          .toList();

      // 4. Builders
      final builders = await RepositoryCoordinator().builderLocal.getBuilders();
      final matchedBuilders = builders
          .where((b) {
            final fieldStrings = <String>[];
            _addStr(fieldStrings, b.companyName);
            _addStr(fieldStrings, b.contactPerson);
            _addStr(fieldStrings, b.mobile);
            _addStr(fieldStrings, b.email);
            _addStr(fieldStrings, b.remarks);

            final fieldWords = fieldStrings
                .join(' ')
                .split(RegExp(r'[^a-zA-Z0-9]+'))
                .where((w) => w.isNotEmpty)
                .toList();

            return queryTokens.every(
              (token) => _isFuzzyMatchToken(token, fieldStrings, fieldWords),
            );
          })
          .map(
            (b) => {
              'id': b.id,
              'company_name': b.companyName,
              'contact_person': b.contactPerson,
              'mobile': b.mobile,
            },
          )
          .take(8)
          .toList();

      // 5. Clients
      final clients = await RepositoryCoordinator().clientLocal.getClients();
      final matchedClients = clients
          .where((c) {
            final fieldStrings = <String>[];
            _addStr(fieldStrings, c.name);
            _addStr(fieldStrings, c.mobile);
            _addStr(fieldStrings, c.email);
            _addStr(fieldStrings, c.remarks);

            final fieldWords = fieldStrings
                .join(' ')
                .split(RegExp(r'[^a-zA-Z0-9]+'))
                .where((w) => w.isNotEmpty)
                .toList();

            return queryTokens.every(
              (token) => _isFuzzyMatchToken(token, fieldStrings, fieldWords),
            );
          })
          .map((c) => {'id': c.id, 'name': c.name, 'mobile': c.mobile})
          .take(8)
          .toList();

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

        final double availableHeight =
            screenHeight - (70 + topPadding + 16) - keyboardHeight;
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
              border: Border.all(
                color: CRMColors.borderOf(context).withOpacity(0.6),
                width: 0.5,
              ),
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
                        ..._propertySuggestions.map(
                          (p) => _buildSuggestionTile(
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
                                context.go(
                                  '/properties?openId=${p['id']}&t=${DateTime.now().millisecondsSinceEpoch}',
                                );
                              }
                            },
                          ),
                        ),
                      ],
                      if (_requirementSuggestions.isNotEmpty) ...[
                        _buildSuggestionSectionHeader('Leads'),
                        ..._requirementSuggestions.map(
                          (r) => _buildSuggestionTile(
                            icon: Icons.person_search_rounded,
                            title: r['customer_name'] ?? '',
                            subtitle: 'Mobile: ${r['mobile']}',
                            onTap: () {
                              _hideSearchOverlay();
                              context.go('/requirements');
                            },
                          ),
                        ),
                      ],
                      if (_ownerSuggestions.isNotEmpty) ...[
                        _buildSuggestionSectionHeader('Owners'),
                        ..._ownerSuggestions.map(
                          (o) => _buildSuggestionTile(
                            icon: Icons.person_rounded,
                            title: o['name'] ?? '',
                            subtitle: 'Mobile: ${o['mobile']}',
                            onTap: () {
                              _hideSearchOverlay();
                              context.go('/owners');
                            },
                          ),
                        ),
                      ],
                      if (_builderSuggestions.isNotEmpty) ...[
                        _buildSuggestionSectionHeader('Builders'),
                        ..._builderSuggestions.map(
                          (b) => _buildSuggestionTile(
                            icon: Icons.construction_rounded,
                            title: b['company_name'] ?? '',
                            subtitle:
                                'Contact: ${b['contact_person']} • Mobile: ${b['mobile']}',
                            onTap: () {
                              _hideSearchOverlay();
                              context.go('/builders');
                            },
                          ),
                        ),
                      ],
                      if (_clientSuggestions.isNotEmpty) ...[
                        _buildSuggestionSectionHeader('Clients'),
                        ..._clientSuggestions.map(
                          (c) => _buildSuggestionTile(
                            icon: Icons.people_alt_rounded,
                            title: c['name'] ?? '',
                            subtitle: 'Mobile: ${c['mobile']}',
                            onTap: () {
                              _hideSearchOverlay();
                              context.go('/clients');
                            },
                          ),
                        ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: CRMSpacing.m,
        vertical: CRMSpacing.xs,
      ),
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
      title: Text(
        title,
        style: TextStyle(
          color: CRMColors.textOf(context),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: CRMColors.textSecondary, fontSize: 11),
      ),
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

    String currentUserName = 'User';
    String currentUserEmail = '';
    String currentUserRole = 'Agent';
    if (userState is Authenticated) {
      if (userState.user.fullName.isNotEmpty) {
        currentUserName = userState.user.fullName;
      }
      if (userState.user.email.isNotEmpty) {
        currentUserEmail = userState.user.email;
      }
      if (userState.user.role.isNotEmpty) {
        currentUserRole = userState.user.role;
      }
    }

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
                extendBody: true,
                drawer: isMobile
                    ? Drawer(
                        width: size.width < 360
                            ? size.width * 0.88
                            : (size.width < 420 ? size.width * 0.82 : 304),
                        backgroundColor: ThemeManager().isDarkMode
                            ? const Color(0xFF0F172A)
                            : Colors.white,
                        child: ModernSidebar(
                          currentPath: location,
                          userName: currentUserName,
                          userEmail: currentUserEmail,
                          userRole: currentUserRole,
                          onItemTapped: () => Navigator.of(context).pop(),
                        ),
                      )
                    : null,
                body: Stack(
                  children: [
                    SizedBox(
                  width: size.width,
                  child: Row(
                  children: [
                    if (showSidebar) ...[
                      SizedBox(
                        width: _sidebarWidth,
                        child: ModernSidebar(
                          currentPath: location,
                          userName: currentUserName,
                          userEmail: currentUserEmail,
                          userRole: currentUserRole,
                          isCollapsed: _sidebarWidth < 150.0,
                          customWidth: _sidebarWidth,
                        ),
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.resizeColumn,
                        child: GestureDetector(
                          onDoubleTap: () {
                            setState(() {
                              if (_sidebarWidth > 150.0) {
                                _sidebarWidth = 70.0;
                                _isSidebarExpanded = false;
                              } else {
                                _sidebarWidth = 245.0;
                                _isSidebarExpanded = true;
                              }
                            });
                          },
                          onPanStart: (_) {
                            setState(() => _isDraggingSidebar = true);
                          },
                          onPanUpdate: (details) {
                            setState(() {
                              _sidebarWidth = (_sidebarWidth + details.delta.dx).clamp(70.0, 360.0);
                              _isSidebarExpanded = _sidebarWidth > 150.0;
                            });
                          },
                          onPanEnd: (_) {
                            setState(() => _isDraggingSidebar = false);
                          },
                          child: SidebarResizerDivider(isDragging: _isDraggingSidebar),
                        ),
                      ),
                    ],
                    Expanded(
                      child: Column(
                        children: [
                          Builder(
                            builder: (scaffoldContext) => ModernTopBar(
                              onToggleSidebar: () {
                                if (isMobile) {
                                  Scaffold.of(scaffoldContext).openDrawer();
                                } else {
                                  setState(() {
                                    if (_sidebarWidth > 150.0) {
                                      _sidebarWidth = 70.0;
                                      _isSidebarExpanded = false;
                                    } else {
                                      _sidebarWidth = 245.0;
                                      _isSidebarExpanded = true;
                                    }
                                  });
                                }
                              },
                              onLogout: _handleLogout,
                              userName: currentUserName,
                              userRole: currentUserRole,
                              searchController: _searchController,
                              searchFocusNode: _searchFocusNode,
                              searchLayerLink: _searchLayerLink,
                              onSearchChanged: _onSearchChanged,
                              onSearchSubmitted: (val) {
                                if (val.trim().isNotEmpty) {
                                  _performSearch(val.trim());
                                }
                              },
                              unreadNotifications: _unreadNotificationsCount,
                              unreadMessages: _unreadTeamMessagesCount,
                              onNotificationsTap: () {
                                setState(() {
                                  _notificationsPanelOpen = true;
                                });
                                _fetchNotifications();
                              },
                            ),
                          ),
                          Expanded(
                            child: isMobile
                                ? NotificationListener<ScrollNotification>(
                                    onNotification: (scrollNotification) {
                                      if (scrollNotification
                                          is ScrollUpdateNotification) {
                                        if (scrollNotification.metrics.axis ==
                                            Axis.vertical) {
                                          final pixels =
                                              scrollNotification.metrics.pixels;
                                          final scrollDelta =
                                              scrollNotification.scrollDelta;
                                          if (pixels <= 10) {
                                            if (!_isBottomBarVisible) {
                                              setState(() {
                                                _isBottomBarVisible = true;
                                              });
                                            }
                                          } else if (scrollDelta != null &&
                                              scrollDelta.abs() > 4) {
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
                                    child: widget.child,
                                  )
                                : widget.child,
                          ),
                        ],
                      ),
                    ),
                  ],
                  ),
                    ),
                    if (isMobile)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: AnimatedSlide(
                          offset: _isBottomBarVisible
                              ? Offset.zero
                              : const Offset(0, 1.5),
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: IgnorePointer(
                            ignoring: !_isBottomBarVisible,
                            child: Material(
                              type: MaterialType.transparency,
                              child: CustomBottomNavBar(
                                selectedIndex: targetIndex,
                                onItemSelected: (index) {
                                  if (index == 2) {
                                    _showQuickActionsBottomSheet();
                                    return;
                                  }
                                  final path = _getTabRoutePath(index);
                                  if (GoRouterState.of(context)
                                          .matchedLocation !=
                                      path) {
                                    context.go(path);
                                  }
                                },
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
    final barRadius = BorderRadius.circular(CRMBorderRadius.card);
    final horizontalPad = isMobile ? 10.0 : 14.0;

    Widget bar = Container(
      height: isMobile ? 56 : 60,
      decoration: BoxDecoration(
        borderRadius: isMobile
            ? barRadius
            : BorderRadius.circular(CRMBorderRadius.card),
        color: CRMColors.cardBgOf(context),
        border: Border.all(color: CRMColors.borderOf(context), width: 1.0),
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
                        Future.delayed(const Duration(milliseconds: 50), () {
                          _searchFocusNode.requestFocus();
                        });
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
                                fillColor: CRMColors.groupedBackground,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    CRMBorderRadius.round,
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    CRMBorderRadius.round,
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    CRMBorderRadius.round,
                                  ),
                                  borderSide: BorderSide(
                                    color: CRMColors.primaryOf(
                                      context,
                                    ).withValues(alpha: 0.35),
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
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
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
                              fillColor: CRMColors.groupedBackground,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  CRMBorderRadius.round,
                                ),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  CRMBorderRadius.round,
                                ),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  CRMBorderRadius.round,
                                ),
                                borderSide: BorderSide(
                                  color: CRMColors.primaryOf(
                                    context,
                                  ).withValues(alpha: 0.35),
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
                if (MediaQuery.sizeOf(context).width >= 1100) ...[
                  const LiveClockWidget(),
                  const SizedBox(width: 8),
                ],
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

    bar = ClipRRect(borderRadius: barRadius, child: bar);

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPad, 8, horizontalPad, 6),
      child: RepaintBoundary(child: bar),
    );
  }

  bool _isDueAlertNotif(String type, String title) {
    final titleLower = title.toLowerCase();
    if (titleLower.contains('follow-up scheduled') ||
        titleLower.contains('re-followup scheduled')) {
      return false;
    }
    return type == 'due_followup' ||
        type == 'site_visit' ||
        titleLower.contains('follow-up alert') ||
        titleLower.contains('overdue follow-up') ||
        titleLower.contains('site visit');
  }

  String _dueClientKey(Map n, Map payload) {
    final fromPayload = (payload['clientName'] ?? '').toString().trim().toLowerCase();
    if (fromPayload.isNotEmpty) return fromPayload;
    final msg = (n['message'] ?? '').toString();
    final quoted = RegExp(r'client\s+"([^"]+)"', caseSensitive: false).firstMatch(msg);
    if (quoted != null) {
      return quoted.group(1)!.trim().toLowerCase();
    }
    final dueMatch = RegExp(
      r'(?:follow-up|site visit) for (?:client\s+)?["“]?(.+?)["”]?(?:\s*\(| is | has |$)',
      caseSensitive: false,
    ).firstMatch(msg);
    return (dueMatch?.group(1) ?? '').trim().toLowerCase();
  }

  String _cleanPersonName(String? raw) {
    final v = (raw ?? '').trim();
    if (v.isEmpty) return '';
    final lower = v.toLowerCase();
    if (lower == 'system' ||
        lower == 'sales team' ||
        lower == 'team member' ||
        lower == 'propkart admin' ||
        lower == 'n/a' ||
        lower == 'sales person') {
      return '';
    }
    if (RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(v)) {
      return '';
    }
    return v;
  }

  String _salesPersonForFollowup(dynamic f, dynamic req, String? fallback) {
    String name = '';
    if (req != null) {
      try {
        name = _cleanPersonName(req.assigneeName);
      } catch (_) {}
    }
    if (name.isEmpty) name = _cleanPersonName(f?.creatorName);
    if (name.isEmpty && req != null) {
      try {
        name = _cleanPersonName(req.creatorName);
      } catch (_) {}
    }
    if (name.isEmpty) name = _cleanPersonName(fallback);
    return name;
  }

  Future<void> _emitDueFollowupNotification({
    required String id,
    required String title,
    required String message,
    required String type,
    required String route,
    Map<String, dynamic>? payload,
  }) async {
    final followupId = (payload?['followupId'] ?? '').toString();
    final clientName = (payload?['clientName'] ?? '').toString();
    if (NotificationCenter.containsId(id)) return;
    if (followupId.isNotEmpty && NotificationCenter.hasDueFollowup(followupId)) return;
    if (clientName.isNotEmpty && NotificationCenter.hasDueClientToday(clientName)) return;
    await NotificationCenter.addNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      route: route,
      payload: payload,
      notifyToast: false,
    );
  }

  bool _apiHasDueNotification(
    List<dynamic> existingApi, {
    String? followupId,
    String? clientName,
  }) {
    final fuId = (followupId ?? '').trim();
    final client = (clientName ?? '').trim().toLowerCase();
    for (final raw in existingApi) {
      if (raw is! Map) continue;
      final payload = raw['payload'] is Map
          ? Map<String, dynamic>.from(raw['payload'] as Map)
          : <String, dynamic>{};
      final type = (raw['type'] ?? payload['type'] ?? '').toString().toLowerCase();
      final title = (raw['title'] ?? '').toString().toLowerCase();
      if (!_isDueAlertNotif(type, title)) continue;
      if (fuId.isNotEmpty && (payload['followupId'] ?? '').toString() == fuId) {
        return true;
      }
      final payloadClient = _dueClientKey(raw, payload);
      if (client.isNotEmpty &&
          (payloadClient == client ||
              (raw['message'] ?? '').toString().toLowerCase().contains(client))) {
        return true;
      }
    }
    return false;
  }

  Future<void> _checkOverdueFollowupsForBell({List<dynamic> existingApi = const []}) async {
    try {
      final dashboardData = await DashboardRepository().getDashboardData(
        backgroundRefresh: false,
      );
      final followups = dashboardData.followups;
      final localReqs = await RepositoryCoordinator().requirementLocal
          .getRequirements();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final authState = context.read<AuthBloc>().state;
      String? role;
      String? currentUserId;
      String? currentUserName;
      if (authState is Authenticated) {
        role = authState.user.role;
        currentUserId = authState.user.id;
        currentUserName = authState.user.fullName;
      }
      final isAdmin = role == 'Admin' || role == 'Super Admin';
      final isTelecaller = role == 'Telecaller';
      final dueClientsThisPass = <String>{};

      for (final f in followups) {
        final parsed = DateTime.tryParse(f.followupDate);
        if (parsed == null) continue;
        final fDate = DateTime(parsed.year, parsed.month, parsed.day);

        dynamic req;
        try {
          req = localReqs.firstWhere((r) => r.id == f.requirementId);
        } catch (_) {}
        if (req != null) {
          final status = req.status ?? '';
          if (status != 'Follow-up' &&
              status != 'Re-Followup' &&
              status != 'Site Visit Scheduled') {
            await NotificationCenter.removeNotificationsForClient(f.clientName);
            continue;
          }
        }

        if (!isAdmin) {
          bool isMine = false;
          if (req != null && currentUserId != null) {
            try {
              final assignedId = (req.assignedTo ?? '').toString();
              if (assignedId.isNotEmpty && assignedId == currentUserId) {
                isMine = true;
              }
            } catch (_) {}
          }
          final creator = _cleanPersonName(f.creatorName);
          if (!isMine &&
              currentUserName != null &&
              currentUserName.isNotEmpty &&
              creator.isNotEmpty &&
              creator.toLowerCase() == currentUserName.trim().toLowerCase()) {
            isMine = true;
          }
          if (!isMine) {
            continue;
          }
          if (isTelecaller && creator.isEmpty) {
            continue;
          }
        }

        final isSiteVisit = req != null && req.status == 'Site Visit Scheduled';
        final isOverdue = fDate.isBefore(today);
        final isToday = fDate.isAtSameMomentAs(today);

        if (isOverdue || isToday) {
            final clientName = (f.clientName ?? '').toString().trim();
            if (clientName.isEmpty) continue;
            final clientKey = clientName.toLowerCase();
            if (dueClientsThisPass.contains(clientKey)) continue;
            final dueId =
                'due_${f.id}_${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
            if (NotificationCenter.containsId(dueId) ||
                NotificationCenter.hasDueFollowup(f.id) ||
                NotificationCenter.hasDueClientToday(clientName) ||
                _apiHasDueNotification(
                  existingApi,
                  followupId: f.id,
                  clientName: clientName,
                )) {
              dueClientsThisPass.add(clientKey);
              continue;
            }

            final salesPerson = _salesPersonForFollowup(
              f,
              req,
              isAdmin ? null : currentUserName,
            );

            String notifTitle;
            String notifMsg;
            String notifType;
            final reqId = (f.requirementId ?? req?.id ?? '').toString();
            final route = reqId.isNotEmpty
                ? '/requirements?openId=${Uri.encodeComponent(reqId)}&tab=follow-ups&subTab=Today'
                : '/requirements?tab=follow-ups&subTab=Today';

            if (isSiteVisit) {
              notifType = 'site_visit';
              if (isOverdue) {
                notifTitle = 'Overdue Site Visit';
                notifMsg = isAdmin && salesPerson.isNotEmpty
                    ? 'Site visit for $clientName (Sales Person: $salesPerson) is overdue! Please take action.'
                    : 'Site visit for $clientName is overdue! Please take action.';
              } else {
                notifTitle = "Today's Site Visit Scheduled";
                notifMsg = isAdmin && salesPerson.isNotEmpty
                    ? 'Site visit for $clientName (Sales Person: $salesPerson) is scheduled for today.'
                    : 'Site visit for $clientName is scheduled for today.';
              }
            } else {
              notifType = 'due_followup';
              if (isOverdue) {
                notifTitle = 'Overdue Follow-up Alert';
                notifMsg = isAdmin && salesPerson.isNotEmpty
                    ? 'Follow-up for $clientName (Sales Person: $salesPerson) is overdue! Please take action.'
                    : 'Follow-up for $clientName is overdue! Please take action immediately.';
              } else {
                notifTitle = "Today's Follow-up Alert";
                notifMsg = isAdmin && salesPerson.isNotEmpty
                    ? 'Follow-up for $clientName (Sales Person: $salesPerson) is scheduled for today.'
                    : 'Follow-up for $clientName is scheduled for today.';
              }
            }

            await _emitDueFollowupNotification(
              id: dueId,
              title: notifTitle,
              message: notifMsg,
              type: notifType,
              route: route,
              payload: {
                'followupId': f.id,
                'requirementId': reqId,
                'clientName': clientName,
                'assigneeName': salesPerson,
              },
            );
            dueClientsThisPass.add(clientKey);
        }
      }

      try {
        final campRes = await DioClient.dio.get(
          '/integrations/followups',
          queryParameters: const {'filter': 'all'},
        );
        final rawFollowups = campRes.data is Map
            ? (campRes.data['followups'] ?? campRes.data['data'])
            : null;
        if (rawFollowups is List) {
          for (final item in rawFollowups) {
            if (item is! Map) continue;
            final status = (item['status'] ?? 'Pending').toString();
            if (status.toLowerCase() != 'pending') continue;
            final scheduled = DateTime.tryParse(
              (item['scheduled_at'] ?? '').toString(),
            );
            if (scheduled == null) continue;
            final fDate = DateTime(scheduled.year, scheduled.month, scheduled.day);
            final isOverdue = fDate.isBefore(today);
            final isTodayDue = fDate.isAtSameMomentAs(today);
            if (!isOverdue && !isTodayDue) continue;

            final createdBy = (item['created_by'] ?? '').toString();
            if (!isAdmin &&
                (createdBy.isEmpty ||
                    currentUserId == null ||
                    createdBy != currentUserId)) {
              continue;
            }

            final clientName = (item['client_name'] ?? 'Campaign lead')
                .toString()
                .trim();
            final fuId = (item['id'] ?? '').toString();
            if (fuId.isEmpty) continue;
            final clientKey = clientName.toLowerCase();
            if (dueClientsThisPass.contains(clientKey)) continue;
            final dueId =
                'due_campaign_${fuId}_${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
            if (NotificationCenter.containsId(dueId) ||
                NotificationCenter.hasDueFollowup(fuId) ||
                NotificationCenter.hasDueClientToday(clientName) ||
                _apiHasDueNotification(
                  existingApi,
                  followupId: fuId,
                  clientName: clientName,
                )) {
              dueClientsThisPass.add(clientKey);
              continue;
            }

            await _emitDueFollowupNotification(
              id: dueId,
              title: isOverdue
                  ? 'Overdue Follow-up Alert'
                  : "Today's Follow-up Alert",
              message: isOverdue
                  ? 'Follow-up for $clientName is overdue! Please take action.'
                  : 'Follow-up for $clientName is scheduled for today.',
              type: 'due_followup',
              route: '/campaign/leads',
              payload: {
                'followupId': fuId,
                'campaignLeadId': (item['lead_id'] ?? '').toString(),
                'clientName': clientName,
              },
            );
            dueClientsThisPass.add(clientKey);
          }
        }
      } catch (_) {}
    } catch (_) {}
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
    final unread = _notifications.where((n) => n['is_read'] != true).toList();
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
              child: Material(
                color: CRMColors.cardBgOf(context),
                child: Container(
                  width: MediaQuery.of(context).size.width < 420
                      ? MediaQuery.of(context).size.width * 0.92
                      : 380,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: CRMColors.cardBgOf(context),
                    border: Border(
                      left: BorderSide(color: CRMColors.borderOf(context)),
                    ),
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
                                child: Text(
                                  'Notifications',
                                  style: CRMTypography.sectionTitle.copyWith(
                                    color: CRMColors.textOf(context),
                                  ),
                                ),
                              ),
                              if (_unreadNotificationsCount > 0)
                                TextButton(
                                  onPressed: _markAllNotificationsRead,
                                  child: Text(
                                    'Mark all',
                                    style: CRMTypography.captionBold.copyWith(
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
                        Divider(height: 1, color: CRMColors.borderOf(context)),
                        FutureBuilder<bool>(
                          future: PlatformNotifier.isPermissionGranted(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data == false) {
                              return Container(
                                margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: CRMColors.primaryOf(
                                    context,
                                  ).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: CRMColors.primaryOf(
                                      context,
                                    ).withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.notifications_active_outlined,
                                      size: 18,
                                      color: CRMColors.primaryOf(context),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Enable browser notifications for live alerts',
                                        style: CRMTypography.caption.copyWith(
                                          color: CRMColors.textOf(context),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () async {
                                        await AppNotifierService.requestPermission(
                                          forceWelcome: true,
                                        );
                                        if (mounted) setState(() {});
                                      },
                                      borderRadius: BorderRadius.circular(6),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        child: Text(
                                          'Allow',
                                          style: TextStyle(
                                            color: CRMColors.primaryOf(context),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        Expanded(
                          child:
                              _isLoadingNotifications && _notifications.isEmpty
                              ? const Center(child: CircularProgressIndicator())
                              : _notifications.isEmpty
                              ? _buildNotificationsEmpty(context)
                              : ListView(
                                  padding: const EdgeInsets.all(12),
                                  children: [
                                    if (unread.isNotEmpty) ...[
                                      _notifSectionLabel('New'),
                                      ...unread.map(_buildNotificationTile),
                                    ],
                                    if (read.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      _notifSectionLabel('Earlier'),
                                      ...read.map(_buildNotificationTile),
                                    ],
                                    if (_notificationsPage <
                                        _totalNotificationPages)
                                      TextButton(
                                        onPressed: () =>
                                            _fetchNotifications(loadMore: true),
                                        child: Text(
                                          'Load more',
                                          style: CRMTypography.captionBold
                                              .copyWith(
                                                color: CRMColors.primaryOf(
                                                  context,
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

  Widget _buildNotificationsEmpty(BuildContext context) {
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
              'No notifications',
              style: CRMTypography.cardTitle.copyWith(
                color: CRMColors.textOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(dynamic rawType) {
    final type = (rawType ?? '').toString().toLowerCase();
    if (type.contains('meta')) return const Color(0xFF10B981);
    if (type.contains('assign')) return const Color(0xFF3B82F6);
    if (type.contains('site_visit') || type.contains('visit')) return const Color(0xFF8B5CF6);
    if (type.contains('followup')) return const Color(0xFFF59E0B);
    if (type.contains('welcome')) return const Color(0xFF10B981);
    return CRMColors.primaryOf(context);
  }

  String _formatCategoryLabel(dynamic rawType) {
    final type = (rawType ?? '').toString().toLowerCase();
    if (type.contains('meta')) return 'META LEAD';
    if (type.contains('assign')) return 'LEAD ASSIGNED';
    if (type.contains('site_visit') || type.contains('visit')) return 'SITE VISIT';
    if (type.contains('property')) return 'PROPERTY ADDED';
    if (type.contains('created')) return 'LEAD ADDED';
    if (type.contains('new_lead')) return 'NEW LEAD';
    if (type.contains('followup')) return 'FOLLOW UP';
    if (type.contains('welcome')) return 'WELCOME';
    return type.toUpperCase();
  }

  Widget _buildNotificationTile(dynamic n) {
    final isRead = n['is_read'] == true;
    final payload = n['payload'] is Map
        ? Map<String, dynamic>.from(n['payload'] as Map)
        : <String, dynamic>{};
    String type = (n['type'] ?? payload['type'] ?? '').toString();
    if (type.isEmpty &&
        (n['title'] ?? '').toString().toLowerCase().contains('assigned')) {
      type = 'lead_assigned';
    }
    final badgeColor = _getCategoryColor(type);
    final assigner = _cleanPersonName(payload['assignerName']?.toString());
    final assignee = _cleanPersonName(payload['assigneeName']?.toString());
    final client = (payload['clientName'] ?? '').toString().trim();
    String message = (n['message'] ?? '').toString();
    final audience = (payload['audience'] ?? '').toString();
    if (type.toLowerCase() == 'lead_assigned' &&
        audience == 'assignee' &&
        assigner.isNotEmpty &&
        client.isNotEmpty) {
      message = '$assigner assigned client "$client" to you.';
    } else if (type.toLowerCase() == 'lead_assigned' &&
        audience == 'assigner' &&
        assignee.isNotEmpty &&
        client.isNotEmpty) {
      message = 'You assigned client "$client" to $assignee.';
    }
    message = message.replaceAll(
      RegExp(r'\s*\(Sales Person:\s*System\)', caseSensitive: false),
      '',
    );

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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: CRMColors.borderOf(context).withValues(alpha: 0.8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.all(3),
          child: Image.asset(
            'assets/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              isRead
                  ? Icons.notifications_none_rounded
                  : Icons.notifications_active_rounded,
              color: isRead
                  ? CRMColors.textMutedOf(context)
                  : CRMColors.primaryOf(context),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (type.isNotEmpty && type.toLowerCase() != 'general')
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatCategoryLabel(type),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            Text(
              n['title'] ?? '',
              style: CRMTypography.captionBold.copyWith(
                color: CRMColors.textOf(context),
                fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              message,
              style: CRMTypography.caption.copyWith(
                color: CRMColors.textSecondaryOf(context),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  _getRelativeTime(n['created_at'] ?? ''),
                  style: CRMTypography.footnote.copyWith(
                    color: CRMColors.textMutedOf(context),
                    fontSize: 10,
                  ),
                ),
                const Spacer(),
                Text(
                  'Tap to view →',
                  style: TextStyle(
                    color: CRMColors.primaryOf(context),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
          setState(() => _notificationsPanelOpen = false);
          AppNotifierService.handleNotificationTap(n);
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
              Icon(
                Icons.add_business_rounded,
                color: CRMColors.primary,
                size: 20,
              ),
              const SizedBox(width: CRMSpacing.s),
              Text(
                'Add Property',
                style: TextStyle(color: CRMColors.textOf(context)),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'requirement',
          child: Row(
            children: [
              Icon(Icons.add_task_rounded, color: CRMColors.primary, size: 20),
              const SizedBox(width: CRMSpacing.s),
              Text(
                'Add Requirement',
                style: TextStyle(color: CRMColors.textOf(context)),
              ),
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

  Widget _buildSidebarContent(
    String currentPath,
    AuthState userState, {
    bool isMobile = false,
    double? sidebarWidth,
  }) {
    String userRole = '';
    String userFullName = '';
    String? userProfilePhoto;

    if (userState is Authenticated) {
      userRole = userState.user.role;
      userFullName = userState.user.fullName;
      userProfilePhoto = userState.user.profilePhoto;
    }

    final isExpanded =
        isMobile ||
        (sidebarWidth == null ? _isSidebarExpanded : sidebarWidth > 200.0);
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
                _buildSidebarItem(
                  Icons.dashboard_rounded,
                  'Dashboard',
                  '/dashboard',
                  currentPath,
                  isMobile,
                  isExpanded,
                ),
                _buildSidebarItem(
                  Icons.home_work_rounded,
                  'Properties',
                  '/properties',
                  currentPath,
                  isMobile,
                  isExpanded,
                ),
                _buildSidebarItem(
                  Icons.assignment_rounded,
                  'Leads',
                  '/requirements',
                  currentPath,
                  isMobile,
                  isExpanded,
                ),
                if (userRole == 'Admin' || userRole == 'Super Admin') ...[
                  _buildSidebarItem(
                    Icons.people_outline_rounded,
                    'Employees',
                    '/users',
                    currentPath,
                    isMobile,
                    isExpanded,
                  ),
                  _buildSidebarTreeItem(
                    icon: Icons.campaign_rounded,
                    label: 'Campaign',
                    currentPath: currentPath,
                    isMobile: isMobile,
                    isExpanded: isExpanded,
                    subItems: const [
                      _SidebarSubItemData(
                        icon: Icons.hub_rounded,
                        label: 'Connections',
                        route: '/campaign/connections',
                      ),
                      _SidebarSubItemData(
                        icon: Icons.table_chart_rounded,
                        label: 'Campaign Leads',
                        route: '/campaign/leads',
                      ),
                    ],
                  ),
                ],
                _buildSidebarItem(
                  Icons.folder_open_rounded,
                  'Library',
                  '/library',
                  currentPath,
                  isMobile,
                  isExpanded,
                ),
                _buildSidebarItem(
                  Icons.settings_rounded,
                  'Settings',
                  '/settings',
                  currentPath,
                  isMobile,
                  isExpanded,
                ),
                _buildSidebarItem(
                  Icons.delete_sweep_rounded,
                  'Recycle Bin',
                  '/bin',
                  currentPath,
                  isMobile,
                  isExpanded,
                ),
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
              mainAxisAlignment: isExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    final currentRoute = GoRouterState.of(
                      context,
                    ).uri.toString();
                    if (currentRoute != '/profile') {
                      context.go('/profile');
                    }
                  },
                  child: CircleAvatar(
                    backgroundColor: CRMColors.primary.withValues(alpha: 0.18),
                    backgroundImage:
                        (userProfilePhoto != null &&
                            userProfilePhoto!.isNotEmpty)
                        ? ResizeImage(
                            NetworkImage(userProfilePhoto!),
                            width: (40 * MediaQuery.devicePixelRatioOf(context))
                                .round(),
                            height:
                                (40 * MediaQuery.devicePixelRatioOf(context))
                                    .round(),
                          )
                        : null,
                    child:
                        (userProfilePhoto != null &&
                            userProfilePhoto!.isNotEmpty)
                        ? null
                        : Icon(
                            Icons.person_outline_rounded,
                            color: CRMColors.primary,
                          ),
                  ),
                ),
                if (isExpanded) ...[
                  const SizedBox(width: CRMSpacing.m),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        final currentRoute = GoRouterState.of(
                          context,
                        ).uri.toString();
                        if (currentRoute != '/profile') {
                          context.go('/profile');
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayFullName,
                            style: CRMTypography.captionBold.copyWith(
                              color: CRMColors.sidebarText,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            displayRole,
                            style: CRMTypography.caption.copyWith(
                              color: CRMColors.sidebarTextSecondary,
                              fontSize: 10,
                            ),
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
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.logout_rounded,
                      color: CRMColors.danger,
                      size: 20,
                    ),
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

  Widget _buildSidebarTreeItem({
    required IconData icon,
    required String label,
    required String currentPath,
    required bool isMobile,
    required bool isExpanded,
    required List<_SidebarSubItemData> subItems,
  }) {
    return _SidebarTreeItem(
      icon: icon,
      label: label,
      currentPath: currentPath,
      isMobile: isMobile,
      isSidebarExpanded: isExpanded,
      subItems: subItems,
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
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            padding: EdgeInsets.symmetric(
              horizontal: isExpanded ? CRMSpacing.m : CRMSpacing.xs,
              vertical: CRMSpacing.s,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? (CRMColors.isDark
                        ? const Color(0xFF382A26)
                        : const Color(0xFFF3E4DE))
                  : (_isHovered
                        ? (CRMColors.isDark
                              ? const Color(0xFF262320)
                              : const Color(0xFFF4F4F3))
                        : Colors.transparent),
              borderRadius: BorderRadius.circular(CRMBorderRadius.button),
              border: Border.all(
                color: isSelected
                    ? (CRMColors.isDark
                          ? const Color(0xFF4A3530)
                          : const Color(0xFFE8CEC5))
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: isExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  color: isSelected
                      ? (CRMColors.isDark
                            ? const Color(0xFFE8A290)
                            : const Color(0xFF8F4E3E))
                      : CRMColors.sidebarTextSecondary,
                  size: 18,
                ),
                if (isExpanded) ...[
                  const SizedBox(width: CRMSpacing.m),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: CRMTypography.bodyMedium.copyWith(
                        color: isSelected
                            ? (CRMColors.isDark
                                  ? const Color(0xFFE8A290)
                                  : const Color(0xFF8F4E3E))
                            : CRMColors.sidebarText,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        fontSize: 13,
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
  }
}

class _SidebarSubItemData {
  final IconData icon;
  final String label;
  final String route;

  const _SidebarSubItemData({
    required this.icon,
    required this.label,
    required this.route,
  });
}

class _SidebarTreeItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String currentPath;
  final bool isMobile;
  final bool isSidebarExpanded;
  final List<_SidebarSubItemData> subItems;

  const _SidebarTreeItem({
    required this.icon,
    required this.label,
    required this.currentPath,
    required this.isMobile,
    required this.isSidebarExpanded,
    required this.subItems,
  });

  @override
  State<_SidebarTreeItem> createState() => _SidebarTreeItemState();
}

class _SidebarTreeItemState extends State<_SidebarTreeItem> {
  bool _isHovered = false;
  late bool _isOpen;

  @override
  void initState() {
    super.initState();
    _isOpen = _isAnyChildActive();
  }

  @override
  void didUpdateWidget(covariant _SidebarTreeItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isAnyChildActive() && !_isOpen) {
      _isOpen = true;
    }
  }

  bool _isAnyChildActive() {
    return widget.subItems.any(
          (item) => widget.currentPath.startsWith(item.route),
        ) ||
        widget.currentPath.startsWith('/campaign') ||
        widget.currentPath.startsWith('/integration');
  }

  @override
  Widget build(BuildContext context) {
    final isChildActive = _isAnyChildActive();
    final isExpanded = widget.isSidebarExpanded || widget.isMobile;

    if (!isExpanded) {
      // In compact sidebar rail mode, show PopupMenu on click
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
        child: PopupMenuButton<String>(
          tooltip: widget.label,
          offset: const Offset(48, 0),
          color: CRMColors.surfaceElevatedOf(context),
          onSelected: (route) {
            if (widget.isMobile) Navigator.pop(context);
            if (widget.currentPath != route) {
              context.go(route);
            }
          },
          itemBuilder: (ctx) => widget.subItems.map((item) {
            final isItemActive = widget.currentPath.startsWith(item.route);
            return PopupMenuItem<String>(
              value: item.route,
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 16,
                    color: isItemActive
                        ? CRMColors.primaryOf(context)
                        : CRMColors.textSecondaryOf(context),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontWeight: isItemActive
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isItemActive
                          ? CRMColors.primaryOf(context)
                          : CRMColors.textOf(context),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                horizontal: CRMSpacing.xs,
                vertical: CRMSpacing.s,
              ),
              decoration: BoxDecoration(
                color: isChildActive
                    ? (CRMColors.isDark
                          ? const Color(0xFF382A26)
                          : const Color(0xFFF3E4DE))
                    : (_isHovered
                          ? (CRMColors.isDark
                                ? const Color(0xFF262320)
                                : const Color(0xFFEAE4DC))
                          : Colors.transparent),
                borderRadius: BorderRadius.circular(CRMBorderRadius.button),
                border: Border.all(
                  color: isChildActive
                      ? (CRMColors.isDark
                            ? const Color(0xFF4A3530)
                            : const Color(0xFFE8CEC5))
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Icon(
                widget.icon,
                color: isChildActive
                    ? (CRMColors.isDark
                          ? const Color(0xFFE8A290)
                          : const Color(0xFF8F4E3E))
                    : CRMColors.sidebarTextSecondary,
                size: 18,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                setState(() => _isOpen = !_isOpen);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: CRMSpacing.m,
                  vertical: CRMSpacing.s,
                ),
                decoration: BoxDecoration(
                  color: isChildActive
                      ? (CRMColors.isDark
                            ? const Color(0xFF382A26)
                            : const Color(0xFFF3E4DE))
                      : (_isHovered
                            ? (CRMColors.isDark
                                  ? const Color(0xFF262320)
                                  : const Color(0xFFEAE4DC))
                            : Colors.transparent),
                  borderRadius: BorderRadius.circular(CRMBorderRadius.button),
                  border: Border.all(
                    color: isChildActive
                        ? (CRMColors.isDark
                              ? const Color(0xFF4A3530)
                              : const Color(0xFFE8CEC5))
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.icon,
                      color: isChildActive
                          ? (CRMColors.isDark
                                ? const Color(0xFFE8A290)
                                : const Color(0xFF8F4E3E))
                          : CRMColors.sidebarTextSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: CRMSpacing.m),
                    Expanded(
                      child: Text(
                        widget.label,
                        style: CRMTypography.bodyMedium.copyWith(
                          color: isChildActive
                              ? (CRMColors.isDark
                                    ? const Color(0xFFE8A290)
                                    : const Color(0xFF8F4E3E))
                              : CRMColors.sidebarText,
                          fontWeight: isChildActive
                              ? FontWeight.w600
                              : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isOpen ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 150),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: isChildActive
                            ? (CRMColors.isDark
                                  ? const Color(0xFFE8A290)
                                  : const Color(0xFF8F4E3E))
                            : CRMColors.sidebarTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Sub items tree
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(left: 14.0, top: 4.0, bottom: 4.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: CRMColors.sidebarBorder,
                      width: 1.0,
                    ),
                  ),
                ),
                padding: const EdgeInsets.only(left: 8.0),
                child: Column(
                  children: widget.subItems.map((item) {
                    final isSelected = widget.currentPath.startsWith(
                      item.route,
                    );
                    return _SidebarSubItemWidget(
                      icon: item.icon,
                      label: item.label,
                      isSelected: isSelected,
                      onTap: () {
                        if (widget.isMobile) Navigator.pop(context);
                        if (widget.currentPath != item.route) {
                          context.go(item.route);
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            crossFadeState: _isOpen
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 150),
          ),
        ],
      ),
    );
  }
}

class _SidebarSubItemWidget extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarSubItemWidget({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarSubItemWidget> createState() => _SidebarSubItemWidgetState();
}

class _SidebarSubItemWidgetState extends State<_SidebarSubItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? (CRMColors.isDark
                        ? const Color(0xFF382A26)
                        : const Color(0xFFF3E4DE))
                  : (_isHovered
                        ? (CRMColors.isDark
                              ? const Color(0xFF262320)
                              : const Color(0xFFEAE4DC))
                        : Colors.transparent),
              borderRadius: BorderRadius.circular(CRMBorderRadius.button),
              border: Border.all(
                color: widget.isSelected
                    ? (CRMColors.isDark
                          ? const Color(0xFF4A3530)
                          : const Color(0xFFE8CEC5))
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  size: 15,
                  color: widget.isSelected
                      ? (CRMColors.isDark
                            ? const Color(0xFFE8A290)
                            : const Color(0xFF8F4E3E))
                      : CRMColors.sidebarTextSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: widget.isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: widget.isSelected
                          ? (CRMColors.isDark
                                ? const Color(0xFFE8A290)
                                : const Color(0xFF8F4E3E))
                          : CRMColors.sidebarText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
          color: CRMColors.primaryOf(
            context,
          ).withValues(alpha: isDark ? 0.15 : 0.08),
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isNarrow = screenWidth < 360;
    return SafeArea(
      top: false,
      minimum: EdgeInsets.only(bottom: isNarrow ? 4 : 8),
      child: Padding(
        padding: EdgeInsets.fromLTRB(isNarrow ? 8 : 12, 0, isNarrow ? 8 : 12, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                height: 64,
                padding: EdgeInsets.symmetric(horizontal: isNarrow ? 2 : 6),
                decoration: BoxDecoration(
                  color: CRMColors.cardBgOf(context),
                  borderRadius: BorderRadius.circular(CRMBorderRadius.card),
                  border: Border.all(color: CRMColors.borderOf(context)),
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
                      label: 'Leads',
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
            SizedBox(width: isNarrow ? 6 : 10),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onItemSelected(2),
                customBorder: const CircleBorder(),
                child: Ink(
                  width: isNarrow ? 48 : 52,
                  height: isNarrow ? 48 : 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CRMColors.primaryOf(context),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
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
    final activeColor = CRMColors.primaryOf(context);
    final inactiveColor = CRMColors.textMutedOf(context);

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
                    ? activeColor.withValues(alpha: CRMColors.isDark ? 0.18 : 0.12)
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
                color: isSelected ? CRMColors.textOf(context) : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SidebarResizerDivider extends StatefulWidget {
  final bool isDragging;

  const SidebarResizerDivider({super.key, this.isDragging = false});

  @override
  State<SidebarResizerDivider> createState() => _SidebarResizerDividerState();
}

class _SidebarResizerDividerState extends State<SidebarResizerDivider> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = ThemeManager().primaryColor;
    final isActive = widget.isDragging || _isHovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: isActive ? 6.0 : 4.0,
        height: double.infinity,
        decoration: BoxDecoration(
          color: isActive
              ? primaryColor
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2)),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.35),
                    blurRadius: 4,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Center(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: isActive ? 1.0 : 0.0,
            child: Container(
              width: 2,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
