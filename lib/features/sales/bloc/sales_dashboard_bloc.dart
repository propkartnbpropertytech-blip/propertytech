import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_constants.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/widgets/crm_page_header.dart';
import '../../../core/security/role_guard.dart';
import '../../dashboard/widgets/stat_card.dart';
import '../../requirements/repository/requirements_repository.dart';
import '../../properties/repository/properties_repository.dart';
import '../../../core/design_system/widgets/drawers.dart';
import '../../../core/theme/theme_manager.dart';

// --- EVENTS ---
abstract class SalesDashboardEvent extends Equatable {
  const SalesDashboardEvent();
  @override
  List<Object?> get props => [];
}

class SalesDashboardRequested extends SalesDashboardEvent {}

class AddNoteRequested extends SalesDashboardEvent {
  final String content;
  const AddNoteRequested(this.content);
  @override
  List<Object?> get props => [content];
}

class ToggleNoteRequested extends SalesDashboardEvent {
  final String id;
  final bool isCompleted;
  const ToggleNoteRequested(this.id, this.isCompleted);
  @override
  List<Object?> get props => [id, isCompleted];
}

class DeleteNoteRequested extends SalesDashboardEvent {
  final String id;
  const DeleteNoteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

// --- STATE ---
class SalesDashboardState extends Equatable {
  final bool loading;
  final String? error;
  final Map<String, dynamic> data;
  const SalesDashboardState({this.loading = false, this.error, this.data = const {}});
  @override
  List<Object?> get props => [loading, error, data];
}

// --- BLOC ---
class SalesDashboardBloc extends Bloc<SalesDashboardEvent, SalesDashboardState> {
  SalesDashboardBloc() : super(const SalesDashboardState(loading: true)) {
    on<SalesDashboardRequested>((event, emit) async {
      emit(SalesDashboardState(loading: state.data.isEmpty, data: state.data));
      Map<String, dynamic> resData = {};
      try {
        final res = await DioClient.dio.get(ApiConstants.salesDashboardSummary);
        resData = Map<String, dynamic>.from(res.data['data'] ?? res.data ?? {});
      } catch (e) {
        // Safe fallback below
      }

      final rawFollowups = resData['followups'];
      final hasFollowups = rawFollowups is List && rawFollowups.isNotEmpty;
      if (!hasFollowups) {
        try {
          final reqs = await RequirementsRepository().getRequirements(refreshFromServer: false);
          final currentUser = RoleGuard.currentUser;
          final currentUserName = currentUser?.fullName.trim().toLowerCase() ?? '';

          final localFollowupList = <Map<String, dynamic>>[];
          for (final req in reqs) {
            final st = req.status.trim().toLowerCase();
            final isFollowup = st == 'follow-up' || st == 'followup' || st == 're-followup' || st == 'refollowup' || st == 'pending';
            if (!isFollowup) continue;

            if (currentUser != null && currentUser.role == 'Sales') {
              final isAssignedToUser = (req.assignedTo != null && (req.assignedTo == currentUser.id || (currentUserName.isNotEmpty && req.assignedTo!.trim().toLowerCase() == currentUserName))) ||
                  (req.assigneeName != null && currentUserName.isNotEmpty && req.assigneeName!.trim().toLowerCase() == currentUserName);
              final isUnassignedCreatedByUser = (req.assignedTo == null || req.assignedTo!.trim().isEmpty || req.assignedTo!.trim().toLowerCase() == 'unassigned') &&
                  (req.createdBy == currentUser.id || (req.creatorName != null && currentUserName.isNotEmpty && req.creatorName!.trim().toLowerCase() == currentUserName));
              if (!isAssignedToUser && !isUnassignedCreatedByUser) continue;
            }

            final dateStr = (req.nextFollowupDate != null && req.nextFollowupDate!.trim().isNotEmpty)
                ? req.nextFollowupDate!
                : req.createdAt.toIso8601String();

            localFollowupList.add({
              'id': 'fu_${req.id}',
              'followup_date': dateStr,
              'status': req.status,
              'remarks': req.remarks ?? 'Follow-up scheduled',
              'notes': req.remarks ?? 'Follow-up scheduled',
              'requirement_id': req.id,
              'requirement': {
                'id': req.id,
                'customer_name': req.clientName,
                'mobile': req.clientMobile,
                'status': req.status,
                'listing_type': {'name': req.listingTypeName ?? 'Rent'},
              },
            });
          }

          if (localFollowupList.isNotEmpty) {
            resData['followups'] = localFollowupList;
          }
        } catch (_) {}
      }

      emit(SalesDashboardState(data: resData));
    });

    on<AddNoteRequested>((event, emit) async {
      final currentNotes = List<dynamic>.from(state.data['notes'] ?? []);
      final tempNote = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'content': event.content,
        'is_completed': false,
        'created_at': DateTime.now().toIso8601String(),
      };
      final updatedData = Map<String, dynamic>.from(state.data);
      updatedData['notes'] = [tempNote, ...currentNotes];
      emit(SalesDashboardState(loading: false, data: updatedData));
      try {
        await DioClient.dio.post('/dashboard/notes', data: {'content': event.content});
        add(SalesDashboardRequested());
      } catch (e) {
        emit(SalesDashboardState(error: e.toString(), data: state.data));
      }
    });

    on<ToggleNoteRequested>((event, emit) async {
      final currentNotes = List<dynamic>.from(state.data['notes'] ?? []);
      final updatedNotes = currentNotes.map((n) {
        if (n is Map && (n['id'] ?? '').toString() == event.id) {
          final copy = Map<String, dynamic>.from(n);
          copy['is_completed'] = event.isCompleted;
          return copy;
        }
        return n;
      }).toList();
      final updatedData = Map<String, dynamic>.from(state.data);
      updatedData['notes'] = updatedNotes;
      emit(SalesDashboardState(loading: false, data: updatedData));
      try {
        await DioClient.dio.patch('/dashboard/notes/${event.id}', data: {'is_completed': event.isCompleted});
        add(SalesDashboardRequested());
      } catch (e) {
        emit(SalesDashboardState(error: e.toString(), data: state.data));
      }
    });

    on<DeleteNoteRequested>((event, emit) async {
      final currentNotes = List<dynamic>.from(state.data['notes'] ?? []);
      final updatedNotes = currentNotes.where((n) {
        return n is Map && (n['id'] ?? '').toString() != event.id;
      }).toList();
      final updatedData = Map<String, dynamic>.from(state.data);
      updatedData['notes'] = updatedNotes;
      emit(SalesDashboardState(loading: false, data: updatedData));
      try {
        await DioClient.dio.delete('/dashboard/notes/${event.id}');
        add(SalesDashboardRequested());
      } catch (e) {
        emit(SalesDashboardState(error: e.toString(), data: state.data));
      }
    });
  }
}

// --- SCREEN ENTRY ---
class SalesDashboardScreen extends StatelessWidget {
  const SalesDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SalesDashboardBloc()..add(SalesDashboardRequested()),
      child: const _SalesDashboardView(),
    );
  }
}

// --- MAIN VIEW WIDGET ---
class _SalesDashboardView extends StatefulWidget {
  const _SalesDashboardView();

  @override
  State<_SalesDashboardView> createState() => _SalesDashboardViewState();
}

class _SalesDashboardViewState extends State<_SalesDashboardView> {
  bool _isRentMode = true;
  String _mainScheduledTab = 'Follow-ups';
  String _subScheduledTab = 'Due';

  // Pagination states matching Telecaller UI
  int _followupsPage = 1;
  static const int _followupsPerPage = 5;

  int _transferredPage = 1;
  static const int _transferredPerPage = 10;

  int _propertiesPage = 1;
  static const int _propertiesPerPage = 10;
  String _propertyPriceSort = 'none';
  final Set<String> _selectedPropertyAreas = <String>{};

  int _notesPage = 1;
  static const int _notesPerPage = 5;

  int _activityPage = 1;
  static const int _activityPerPage = 10;

  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isRentMode = ThemeManager().isRentMode;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  bool _matchesMode(dynamic item) {
    if (item is! Map) return true;
    final req = item['requirement'] as Map? ?? {};
    final listingType = req['listing_type'] ??
        item['listing_type'] ??
        item['listingType'] ??
        item['listing_type_name'] ??
        req['listing_type_name'];
    final name = (listingType is Map ? listingType['name'] : listingType?.toString()) ?? '';
    if (name.isEmpty) return true;
    final lower = name.toLowerCase();
    return _isRentMode
        ? lower.contains('rent')
        : (lower.contains('sale') || lower.contains('resale') || lower.contains('buy'));
  }

  void _launchPhoneCall(String? mobile) async {
    if (mobile == null || mobile.trim().isEmpty) return;
    final Uri uri = Uri.parse('tel:${mobile.trim()}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchWhatsAppMessage(String? mobile) async {
    if (mobile == null || mobile.trim().isEmpty) return;
    final cleanMobile = mobile.replaceAll(RegExp(r'\D'), '');
    final Uri uri = Uri.parse('https://wa.me/$cleanMobile');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = RoleGuard.currentUser?.fullName ?? 'Sales Agent';
    final isWide = MediaQuery.of(context).size.width >= 1050;

    return BlocBuilder<SalesDashboardBloc, SalesDashboardState>(
      builder: (context, state) {
        final d = state.data;
        if (state.loading && d.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // Metrics filtered by Rent vs Re-Sale Mode
        final availableCount = _isRentMode
            ? (d['rentalAvailableProperties'] ?? d['availableProperties'] ?? 0)
            : (d['resaleAvailableProperties'] ?? d['availableProperties'] ?? 0);

        final siteVisitsDoneCount = _isRentMode
            ? (d['rentalSiteVisitsDone'] ?? d['siteVisitsDone'] ?? 0)
            : (d['resaleSiteVisitsDone'] ?? d['siteVisitsDone'] ?? 0);

        final activeLeadsCount = _isRentMode
            ? (d['rentalActiveLeads'] ?? d['activeLeads'] ?? 0)
            : (d['resaleActiveLeads'] ?? d['activeLeads'] ?? 0);

        final dealsWonCount = _isRentMode
            ? (d['rentalDealsWon'] ?? d['dealsWon'] ?? 0)
            : (d['resaleDealsWon'] ?? d['dealsWon'] ?? 0);

        final assignedLeadsCount = _isRentMode
            ? (d['rentalAssignedLeads'] ?? d['assignedLeads'] ?? d['leadsAssignedToMe'] ?? 0)
            : (d['resaleAssignedLeads'] ?? d['assignedLeads'] ?? d['leadsAssignedToMe'] ?? 0);

        final newLeadsCount = _isRentMode
            ? (d['rentalNewLeads'] ?? d['newLeads'] ?? 0)
            : (d['resaleNewLeads'] ?? d['newLeads'] ?? 0);

        List<dynamic> safeList(dynamic raw) {
          if (raw is List) return List<dynamic>.from(raw);
          return <dynamic>[];
        }

        final rawFollowups = d['followups'];
        final rawSiteVisits = d['siteVisits'];
        final allFollowups = (rawFollowups is List) ? List<dynamic>.from(rawFollowups) : safeList(d['followupsList']);
        final allSiteVisits = (rawSiteVisits is List) ? List<dynamic>.from(rawSiteVisits) : [];

        final followupsCatMap = (d['followupsCategorized'] is Map) ? Map<String, dynamic>.from(d['followupsCategorized']) : <String, dynamic>{};
        final siteVisitsCatMap = (d['siteVisitsCategorized'] is Map) ? Map<String, dynamic>.from(d['siteVisitsCategorized']) : <String, dynamic>{};

        final modeFollowupsForCount = allFollowups.where(_matchesMode).toList();
        final modeFollowupsCatForCount = _categorizeItems(modeFollowupsForCount, 'followup_date');

        final activeFollowupsCount = _isRentMode
            ? (d['rentalActiveFollowups'] ?? ((modeFollowupsCatForCount['today']?.length ?? 0) + (modeFollowupsCatForCount['future']?.length ?? 0)))
            : (d['resaleActiveFollowups'] ?? ((modeFollowupsCatForCount['today']?.length ?? 0) + (modeFollowupsCatForCount['future']?.length ?? 0)));

        final dueFollowupsCount = _isRentMode
            ? (d['rentalDueFollowups'] ?? (modeFollowupsCatForCount['due'] ?? []).length)
            : (d['resaleDueFollowups'] ?? (modeFollowupsCatForCount['due'] ?? []).length);

        // Lists
        final recentLeads = safeList(d['recentLeads']);
        final notes = safeList(d['notes']);
        final activityLogs = safeList(d['activityLogs']);

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _followupsPage = 1;
              _transferredPage = 1;
              _notesPage = 1;
              _activityPage = 1;
            });
            context.read<SalesDashboardBloc>().add(SalesDashboardRequested());
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            children: [
              // Page Header with Title & Rent/Re-Sale Mode Toggle Switch
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CRMPageHeader(
                      title: 'Welcome, $userName 👋',
                      benefit: 'Direct access to your assigned leads, active follow-ups, and open inventory.',
                    ),
                  ),
                  _buildRentResaleToggle(),
                ],
              ),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(state.error!, style: const TextStyle(color: Colors.red)),
                ),

              // KPI Cards Grid (Identical to Telecaller StatCard Grid in Image 2)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _clickableKpi(
                    context,
                    'Available Inventory',
                    '$availableCount',
                    Icons.home_work_outlined,
                    '/properties',
                    accentColor: const Color(0xFF2563EB),
                  ),
                  _clickableKpi(
                    context,
                    'Site Visit Done',
                    '$siteVisitsDoneCount',
                    Icons.location_on_outlined,
                    '/requirements?tab=follow-ups&subTab=site-visits',
                    accentColor: const Color(0xFF059669),
                  ),
                  _clickableKpi(
                    context,
                    'Active Leads',
                    '$activeLeadsCount',
                    Icons.assignment_outlined,
                    '/requirements',
                    accentColor: const Color(0xFF8B5CF6),
                  ),
                  _clickableKpi(
                    context,
                    'Deals Won',
                    '$dealsWonCount',
                    Icons.emoji_events_outlined,
                    '/requirements?status=Won',
                    accentColor: const Color(0xFFF59E0B),
                  ),
                  _clickableKpi(
                    context,
                    'Assigned Leads',
                    '$assignedLeadsCount',
                    Icons.assignment_ind_rounded,
                    '/requirements?group=assigned',
                    accentColor: const Color(0xFF06B6D4),
                  ),
                  _clickableKpi(
                    context,
                    'New Leads',
                    '$newLeadsCount',
                    Icons.fiber_new_rounded,
                    '/requirements?status=New',
                    accentColor: const Color(0xFFEC4899),
                  ),
                  _clickableKpi(
                    context,
                    'Follow-ups Due',
                    '$dueFollowupsCount',
                    Icons.event_busy_rounded,
                    '/requirements?tab=follow-ups',
                    accentColor: const Color(0xFFEF4444),
                  ),
                  _clickableKpi(
                    context,
                    'Active Follow-ups\n(Today + Future)',
                    '$activeFollowupsCount',
                    Icons.event_note_rounded,
                    '/requirements?tab=follow-ups',
                    accentColor: const Color(0xFF6366F1),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (isWide) ...[
                // Row 1: My Scheduled on Left (flex 6), Personal Notes on Right (flex 4)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: _buildScheduledCard(context, allFollowups, allSiteVisits, followupsCatMap, siteVisitsCatMap),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 4,
                      child: _buildPersonalNotesCard(context, notes),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Row 2: Recent Properties Listed & Activity Logs on Left (flex 6), Recent Leads on Right (flex 4)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        children: [
                          _buildRecentPropertiesCard(context, safeList(d['recentProperties'])),
                          const SizedBox(height: 24),
                          _buildRecentActivityCard(context, activityLogs),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          _buildRecentLeadsCard(context, recentLeads),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                _buildScheduledCard(context, allFollowups, allSiteVisits, followupsCatMap, siteVisitsCatMap),
                const SizedBox(height: 24),
                _buildRecentPropertiesCard(context, safeList(d['recentProperties'])),
                const SizedBox(height: 24),
                _buildPersonalNotesCard(context, notes),
                const SizedBox(height: 24),
                _buildRecentLeadsCard(context, recentLeads),
                const SizedBox(height: 24),
                _buildRecentActivityCard(context, activityLogs),
              ],
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  // --- Rent / Re-Sale Mode Toggle Switch ---
  Widget _buildRentResaleToggle() {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _togglePill('Rent Mode', _isRentMode, () {
            setState(() {
              _isRentMode = true;
              _subScheduledTab = 'Due';
              _propertiesPage = 1;
              _followupsPage = 1;
              _transferredPage = 1;
              _propertyPriceSort = 'none';
              _selectedPropertyAreas.clear();
            });
            ThemeManager().setRentMode(true);
          }),
          _togglePill('Re-Sale Mode', !_isRentMode, () {
            setState(() {
              _isRentMode = false;
              _subScheduledTab = 'Due';
              _propertiesPage = 1;
              _followupsPage = 1;
              _transferredPage = 1;
              _propertyPriceSort = 'none';
              _selectedPropertyAreas.clear();
            });
            ThemeManager().setRentMode(false);
          }),
        ],
      ),
    );
  }

  Widget _togglePill(String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? CRMColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // --- WIDGET 1: MY SCHEDULED CARD WITH (My Follow-ups / My Site Visit Sched.) AND (Today's / Due / Future) ---
  Widget _buildScheduledCard(
    BuildContext context,
    List<dynamic> rawFollowups,
    List<dynamic> rawSiteVisits,
    Map<String, dynamic> followupsCatMap,
    Map<String, dynamic> siteVisitsCatMap,
  ) {
    final modeFollowups = rawFollowups.where(_matchesMode).toList();
    final modeSiteVisits = rawSiteVisits.where(_matchesMode).toList();

    final followupsCat = _categorizeItems(modeFollowups, 'followup_date');
    final siteVisitsCat = _categorizeItems(modeSiteVisits, 'visit_date');

    final isFollowups = _mainScheduledTab == 'Follow-ups';
    final activeCat = isFollowups ? followupsCat : siteVisitsCat;

    final currentSubKey = _subScheduledTab.toLowerCase();
    final currentItems = activeCat[currentSubKey] ?? [];

    final totalCount = isFollowups ? modeFollowups.length : modeSiteVisits.length;
    final totalPages = currentItems.isEmpty ? 1 : (currentItems.length / _followupsPerPage).ceil();
    final safeTotalPages = totalPages < 1 ? 1 : totalPages;
    final currentPage = _followupsPage.clamp(1, safeTotalPages);
    final startIndex = (currentPage - 1) * _followupsPerPage;
    final pagedItems = currentItems.skip(startIndex).take(_followupsPerPage).toList();

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.schedule_rounded, color: Color(0xFFD97706), size: 20),
                ),
                const SizedBox(width: 10),
                const Text('My Scheduled', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                  child: Text('$totalCount', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => context.go('/requirements?tab=follow-ups'),
                  icon: const Icon(Icons.open_in_new_rounded, size: 15),
                  label: const Text('View All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Main Tabs Row: [ My Follow-ups ] | [ My Site Visit Sched. ]
            Row(
              children: [
                _mainTabPill('My Follow-ups', isFollowups, () {
                  setState(() {
                    _mainScheduledTab = 'Follow-ups';
                    _followupsPage = 1;
                  });
                }),
                const SizedBox(width: 8),
                _mainTabPill('My Site Visit Sched.', !isFollowups, () {
                  setState(() {
                    _mainScheduledTab = 'Site Visits';
                    _followupsPage = 1;
                  });
                }),
              ],
            ),
            const SizedBox(height: 12),

            // Sub-Tabs Row: [ Today's (Count) ] | [ Due (Count) ] | [ Future (Count) ]
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _subTabPill("Today's", _subScheduledTab == 'Today', () {
                      setState(() {
                        _subScheduledTab = 'Today';
                        _followupsPage = 1;
                      });
                    }, count: (activeCat['today'] ?? []).length),
                  ),
                  Expanded(
                    child: _subTabPill('Due', _subScheduledTab == 'Due', () {
                      setState(() {
                        _subScheduledTab = 'Due';
                        _followupsPage = 1;
                      });
                    }, count: (activeCat['due'] ?? []).length),
                  ),
                  Expanded(
                    child: _subTabPill('Future', _subScheduledTab == 'Future', () {
                      setState(() {
                        _subScheduledTab = 'Future';
                        _followupsPage = 1;
                      });
                    }, count: (activeCat['future'] ?? []).length),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),

            if (pagedItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        isFollowups ? Icons.event_available_rounded : Icons.place_outlined,
                        size: 36,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No ${_subScheduledTab.toLowerCase()} ${isFollowups ? 'follow-ups' : 'site visits'} found.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pagedItems.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final item = pagedItems[i] as Map;
                  final req = item['requirement'] as Map? ?? {};
                  final prop = item['property'] as Map? ?? {};
                  final customerName = req['customer_name']?.toString() ?? 'Customer';
                  final mobile = req['mobile']?.toString() ?? '';
                  final propertyTitle = prop['title']?.toString() ?? prop['property_code']?.toString() ?? 'Property';

                  final dateStr = item['followup_date'] ?? item['visit_date'] ?? item['created_at'] ?? '';
                  DateTime? parsedDate;
                  if (dateStr.isNotEmpty) parsedDate = DateTime.tryParse(dateStr);

                  final remarks = item['remarks']?.toString() ?? item['notes']?.toString() ?? '';

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _subScheduledTab == 'Due'
                                ? const Color(0xFFFEE2E2)
                                : (_subScheduledTab == 'Today' ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isFollowups ? Icons.access_time_rounded : Icons.location_on_outlined,
                            color: _subScheduledTab == 'Due'
                                ? const Color(0xFFDC2626)
                                : (_subScheduledTab == 'Today' ? const Color(0xFFD97706) : const Color(0xFF059669)),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      customerName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: _subScheduledTab == 'Due'
                                          ? const Color(0xFFFEE2E2)
                                          : (_subScheduledTab == 'Today' ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5)),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _subScheduledTab.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: _subScheduledTab == 'Due'
                                            ? const Color(0xFFDC2626)
                                            : (_subScheduledTab == 'Today' ? const Color(0xFFD97706) : const Color(0xFF059669)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                                    child: Text(_isRentMode ? 'Rent' : 'Re-Sale', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${parsedDate != null ? DateFormat('EEE, d MMM • h:mm a').format(parsedDate) : 'Today'} · $propertyTitle',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                  if (mobile.isNotEmpty) ...[
                                    const SizedBox(width: 10),
                                    Icon(Icons.phone_outlined, size: 12, color: Colors.grey.shade500),
                                    const SizedBox(width: 4),
                                    Text(mobile, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                  ],
                                ],
                              ),
                              if (remarks.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  remarks,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (mobile.isNotEmpty) ...[
                              IconButton(
                                icon: const Icon(Icons.phone_forwarded, size: 18, color: Color(0xFF059669)),
                                tooltip: 'Call client',
                                onPressed: () => _launchPhoneCall(mobile),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chat_outlined, size: 18, color: Color(0xFF25D366)),
                                tooltip: 'WhatsApp',
                                onPressed: () => _launchWhatsAppMessage(mobile),
                              ),
                            ],
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                              onPressed: () => context.go('/requirements?tab=follow-ups'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (currentItems.length > _followupsPerPage) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing ${startIndex + 1}–${min(startIndex + _followupsPerPage, currentItems.length)} of ${currentItems.length} items',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: currentPage > 1 ? () => setState(() => _followupsPage = currentPage - 1) : null,
                          icon: const Icon(Icons.chevron_left, size: 16),
                          label: const Text('Previous', style: TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        Text('Page $currentPage of $safeTotalPages', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: currentPage < safeTotalPages ? () => setState(() => _followupsPage = currentPage + 1) : null,
                          icon: const Icon(Icons.chevron_right, size: 16),
                          label: const Text('Next', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _mainTabPill(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? CRMColors.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _subTabPill(String label, bool isSelected, VoidCallback onTap, {int? count}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? CRMColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Map<String, List<dynamic>> _categorizeItems(List<dynamic> items, String dateField) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    final todayList = <dynamic>[];
    final dueList = <dynamic>[];
    final futureList = <dynamic>[];

    for (final item in items) {
      if (item is! Map) continue;
      final dateStr = item[dateField] ?? item['created_at'] ?? '';
      if (dateStr == null || dateStr.toString().isEmpty) continue;
      final parsed = DateTime.tryParse(dateStr.toString());
      if (parsed == null) continue;

      final st = (item['status'] ?? '').toString().toLowerCase();
      final isDone = st == 'completed' || st == 'done' || st == 'closed' || st == 'resolved' || st == 'cancelled';

      if (parsed.isBefore(todayStart)) {
        if (!isDone) dueList.add(item);
      } else if (parsed.isAfter(todayEnd)) {
        futureList.add(item);
      } else {
        todayList.add(item);
      }
    }

    dueList.sort((a, b) {
      final aDate = DateTime.tryParse((a[dateField] ?? a['created_at'] ?? '').toString()) ?? DateTime(1970);
      final bDate = DateTime.tryParse((b[dateField] ?? b['created_at'] ?? '').toString()) ?? DateTime(1970);
      return bDate.compareTo(aDate);
    });

    todayList.sort((a, b) {
      final aDate = DateTime.tryParse((a[dateField] ?? a['created_at'] ?? '').toString()) ?? DateTime(1970);
      final bDate = DateTime.tryParse((b[dateField] ?? b['created_at'] ?? '').toString()) ?? DateTime(1970);
      return aDate.compareTo(bDate);
    });

    futureList.sort((a, b) {
      final aDate = DateTime.tryParse((a[dateField] ?? a['created_at'] ?? '').toString()) ?? DateTime(1970);
      final bDate = DateTime.tryParse((b[dateField] ?? b['created_at'] ?? '').toString()) ?? DateTime(1970);
      return aDate.compareTo(bDate);
    });

    return {
      'today': todayList,
      'due': dueList,
      'future': futureList,
    };
  }

  // --- WIDGET 2: RECENT ASSIGNED LEADS TABLE (Same as Telecaller Transferred Table Image 3) ---
  Widget _buildRecentLeadsCard(BuildContext context, List<dynamic> recentLeads) {
    final filteredLeads = recentLeads.where(_matchesMode).toList();
    final totalItems = filteredLeads.length;
    final totalPages = totalItems <= 0 ? 1 : (totalItems / _transferredPerPage).ceil();
    final safeTotalPages = totalPages < 1 ? 1 : totalPages;
    final currentPage = _transferredPage.clamp(1, safeTotalPages);
    final startIndex = (currentPage - 1) * _transferredPerPage;
    final pagedLeads = filteredLeads.skip(startIndex).take(_transferredPerPage).toList();

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.handshake_outlined, color: Color(0xFF059669), size: 20),
                ),
                const SizedBox(width: 10),
                const Text('Recent Leads Assigned', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(12)),
                  child: Text('$totalItems', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  onPressed: () => context.read<SalesDashboardBloc>().add(SalesDashboardRequested()),
                ),
              ],
            ),
            const Divider(height: 24),
            if (filteredLeads.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.assignment_turned_in_outlined, size: 36, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        _isRentMode ? 'No assigned rental leads yet.' : 'No assigned re-sale leads yet.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  horizontalMargin: 8,
                  columnSpacing: 18,
                  headingRowHeight: 40,
                  dataRowMinHeight: 48,
                  dataRowMaxHeight: 56,
                  headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                  columns: const [
                    DataColumn(label: Text('#')),
                    DataColumn(label: Text('Client Name')),
                    DataColumn(label: Text('Phone')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Created At')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: pagedLeads.asMap().entries.map((entry) {
                    final index = (currentPage - 1) * _transferredPerPage + entry.key + 1;
                    final lead = entry.value as Map;
                    final clientName = (lead['customer_name'] ?? 'Lead').toString();
                    final phone = (lead['mobile'] ?? '').toString();
                    final leadType = (lead['listing_type_name'] ?? 'Requirement').toString();
                    final status = (lead['status'] ?? 'New').toString();
                    final isUncontacted = lead['is_uncontacted'] == true;

                    String timeStr = '-';
                    if (lead['created_at'] != null) {
                      final dt = DateTime.tryParse(lead['created_at'].toString());
                      if (dt != null) timeStr = DateFormat('d MMM, h:mm a').format(dt.toLocal());
                    }

                    return DataRow(
                      cells: [
                        DataCell(Text('$index', style: const TextStyle(fontSize: 12, color: Colors.grey))),
                        DataCell(
                          Row(
                            children: [
                              Text(clientName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              if (isUncontacted) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(4)),
                                  child: const Text('⚠️ 24h', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                                ),
                              ],
                            ],
                          ),
                        ),
                        DataCell(Text(phone, style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: leadType.toLowerCase().contains('rent') ? const Color(0xFFFEF3C7) : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(leadType, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: leadType.toLowerCase().contains('rent') ? const Color(0xFFD97706) : const Color(0xFF2563EB))),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6)),
                            child: Text(status, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF059669))),
                          ),
                        ),
                        DataCell(Text(timeStr, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.phone, size: 16, color: Color(0xFF2563EB)),
                                onPressed: () => _launchPhoneCall(phone),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chat, size: 16, color: Color(0xFF10B981)),
                                onPressed: () => _launchWhatsAppMessage(phone),
                              ),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  minimumSize: const Size(0, 26),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                onPressed: () => context.go('/requirements'),
                                child: const Text('View', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing ${totalItems == 0 ? 0 : (currentPage - 1) * _transferredPerPage + 1}–${min(currentPage * _transferredPerPage, totalItems)} of $totalItems leads',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: currentPage > 1 ? () => setState(() => _transferredPage = currentPage - 1) : null,
                        icon: const Icon(Icons.chevron_left, size: 16),
                        label: const Text('Previous', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      Text('Page $currentPage of $safeTotalPages', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: currentPage < safeTotalPages ? () => setState(() => _transferredPage = currentPage + 1) : null,
                        icon: const Icon(Icons.chevron_right, size: 16),
                        label: const Text('Next', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- WIDGET 3: PERSONAL NOTES & TASKS CHECKLIST (Same as Telecaller UI Image 2 & 3) ---
  Widget _buildPersonalNotesCard(BuildContext context, List<dynamic> notes) {
    final activeCount = notes.where((n) => n['is_completed'] != true).length;
    final totalItems = notes.length;
    final totalPages = totalItems <= 0 ? 1 : (totalItems / _notesPerPage).ceil();
    final safeTotalPages = totalPages < 1 ? 1 : totalPages;
    final currentPage = _notesPage.clamp(1, safeTotalPages);
    final startIndex = (currentPage - 1) * _notesPerPage;
    final pagedNotes = notes.skip(startIndex).take(_notesPerPage).toList();

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.checklist_rtl_rounded, color: Color(0xFF8B5CF6), size: 20),
                ),
                const SizedBox(width: 10),
                const Text('Personal Notes & Tasks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(12)),
                  child: Text('$activeCount active', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    onSubmitted: (_) {
                      final text = _noteController.text.trim();
                      if (text.isNotEmpty) {
                        context.read<SalesDashboardBloc>().add(AddNoteRequested(text));
                        _noteController.clear();
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Add a personal note or reminder...',
                      hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final text = _noteController.text.trim();
                    if (text.isNotEmpty) {
                      context.read<SalesDashboardBloc>().add(AddNoteRequested(text));
                      _noteController.clear();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
            const Divider(height: 24),
            if (notes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: Text('No notes yet. Add your personal reminders above.', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500)),
                ),
              )
            else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pagedNotes.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final note = pagedNotes[i] as Map;
                  final id = (note['id'] ?? '').toString();
                  final isDone = note['is_completed'] == true;

                  DateTime? dt;
                  if (note['created_at'] != null) {
                    dt = DateTime.tryParse(note['created_at'].toString());
                  }
                  String timeSubtitle = '';
                  if (dt != null) {
                    timeSubtitle = DateFormat('EEE, d MMM • h:mm a').format(dt.toLocal());
                  }

                  return InkWell(
                    onTap: () {
                      context.read<SalesDashboardBloc>().add(ToggleNoteRequested(id, !isDone));
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: isDone,
                              activeColor: const Color(0xFF8B5CF6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (_) {
                                context.read<SalesDashboardBloc>().add(ToggleNoteRequested(id, !isDone));
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (note['content'] ?? '').toString(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDone ? Colors.grey.shade400 : const Color(0xFF1E293B),
                                    decoration: isDone ? TextDecoration.lineThrough : null,
                                    decorationColor: Colors.grey.shade400,
                                    decorationThickness: 2,
                                    fontWeight: isDone ? FontWeight.normal : FontWeight.w500,
                                  ),
                                ),
                                if (timeSubtitle.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    timeSubtitle,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: isDone ? Colors.grey.shade400 : const Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close_rounded, size: 16, color: Colors.grey.shade400),
                            onPressed: () {
                              context.read<SalesDashboardBloc>().add(DeleteNoteRequested(id));
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              if (totalItems > _notesPerPage) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing ${startIndex + 1}–${min(startIndex + _notesPerPage, totalItems)} of $totalItems notes',
                      style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                    ),
                    Row(
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: const Size(0, 28),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: currentPage > 1 ? () => setState(() => _notesPage = currentPage - 1) : null,
                          child: const Icon(Icons.chevron_left, size: 16),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('$currentPage / $safeTotalPages', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: const Size(0, 28),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: currentPage < safeTotalPages ? () => setState(() => _notesPage = currentPage + 1) : null,
                          child: const Icon(Icons.chevron_right, size: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // --- WIDGET 4: RECENT ACTIVITY & LOG FEED (Same as Telecaller Image 3) ---
  Widget _buildRecentActivityCard(BuildContext context, List<dynamic> activityLogs) {
    final totalItems = activityLogs.length;
    final totalPages = totalItems <= 0 ? 1 : (totalItems / _activityPerPage).ceil();
    final safeTotalPages = totalPages < 1 ? 1 : totalPages;
    final currentPage = _activityPage.clamp(1, safeTotalPages);
    final startIndex = (currentPage - 1) * _activityPerPage;
    final pagedLogs = activityLogs.skip(startIndex).take(_activityPerPage).toList();

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.history_rounded, color: Color(0xFF2563EB), size: 20),
                ),
                const SizedBox(width: 10),
                const Text('Recent Activity & Call Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const Spacer(),
                Text(
                  'Today: $totalItems',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const Divider(height: 24),
            if (activityLogs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.history_toggle_off_rounded, size: 36, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('No activity logged today.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              )
            else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pagedLogs.length,
                separatorBuilder: (context, index) => const Divider(height: 16),
                itemBuilder: (context, i) {
                  final log = Map<String, dynamic>.from(pagedLogs[i] as Map);
                  final action = (log['action'] ?? 'Activity').toString();
                  final description = (log['description'] ?? '').toString();
                  final user = (log['user_name'] ?? 'System').toString();

                  String timeStr = '-';
                  if (log['created_at'] != null) {
                    final dt = DateTime.tryParse(log['created_at'].toString());
                    if (dt != null) timeStr = DateFormat('h:mm a').format(dt.toLocal());
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(timeStr, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              user,
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                        child: Text(action, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '“$description”',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  );
                },
              ),
              if (totalItems > _activityPerPage) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing ${startIndex + 1}–${min(startIndex + _activityPerPage, totalItems)} of $totalItems activities',
                      style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                    ),
                    Row(
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: const Size(0, 28),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: currentPage > 1 ? () => setState(() => _activityPage = currentPage - 1) : null,
                          child: const Icon(Icons.chevron_left, size: 16),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('$currentPage / $safeTotalPages', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: const Size(0, 28),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: currentPage < safeTotalPages ? () => setState(() => _activityPage = currentPage + 1) : null,
                          child: const Icon(Icons.chevron_right, size: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // Helper widget matching Telecaller _clickableKpi
  Widget _clickableKpi(BuildContext context, String title, String value, IconData icon, String route, {Color? accentColor}) {
    return SizedBox(
      width: 220,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(route),
          borderRadius: BorderRadius.circular(12),
          child: StatCard(
            title: title,
            value: value,
            icon: icon,
            accentColor: accentColor ?? CRMColors.primary,
            isCompact: true,
          ),
        ),
      ),
    );
  }

  // --- NEW WIDGET: RECENT PROPERTIES LISTED (Exact bottom side of KPI cards grid) ---
  Widget _buildRecentPropertiesCard(BuildContext context, List<dynamic> properties) {
    final modeProps = properties.where(_matchesMode).toList();

    // Extract all distinct areas available in current mode properties for filter dialog
    final allDistinctAreas = modeProps
        .map((p) => (p is Map ? (p['area_name'] ?? p['area'] ?? '') : '').toString().trim())
        .map((a) => a.contains(',') ? a.split(',').first.trim() : a)
        .where((a) => a.isNotEmpty && a != '-')
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    // Filter by Area (Multi-select)
    var filteredProps = modeProps;
    if (_selectedPropertyAreas.isNotEmpty) {
      filteredProps = filteredProps.where((p) {
        if (p is! Map) return false;
        final a = (p['area_name'] ?? p['area'] ?? '').toString().trim().toLowerCase();
        return _selectedPropertyAreas.any((sel) => a.contains(sel.toLowerCase()));
      }).toList();
    }

    // Price Sorting (Radio buttons: Default/Newest First, High to Low, Low to High)
    if (_propertyPriceSort == 'high_to_low') {
      filteredProps.sort((a, b) {
        final aPrice = num.tryParse((a['price'] ?? 0).toString()) ?? 0;
        final bPrice = num.tryParse((b['price'] ?? 0).toString()) ?? 0;
        return bPrice.compareTo(aPrice);
      });
    } else if (_propertyPriceSort == 'low_to_high') {
      filteredProps.sort((a, b) {
        final aPrice = num.tryParse((a['price'] ?? 0).toString()) ?? 0;
        final bPrice = num.tryParse((b['price'] ?? 0).toString()) ?? 0;
        return aPrice.compareTo(bPrice);
      });
    } else {
      // Default Order — Newest First
      filteredProps.sort((a, b) {
        final aDate = DateTime.tryParse((a['created_at'] ?? a['createdAt'] ?? '').toString()) ?? DateTime(1970);
        final bDate = DateTime.tryParse((b['created_at'] ?? b['createdAt'] ?? '').toString()) ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });
    }

    final hasActiveFilters = _selectedPropertyAreas.isNotEmpty || _propertyPriceSort != 'none';
    final activeFilterCount = _selectedPropertyAreas.length + (_propertyPriceSort != 'none' ? 1 : 0);

    final totalItems = filteredProps.length;
    final totalPages = totalItems <= 0 ? 1 : (totalItems / _propertiesPerPage).ceil();
    final safeTotalPages = totalPages < 1 ? 1 : totalPages;
    final currentPage = _propertiesPage.clamp(1, safeTotalPages);
    final startIndex = (currentPage - 1) * _propertiesPerPage;
    final pagedProps = filteredProps.skip(startIndex).take(_propertiesPerPage).toList();

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.domain_rounded, color: Color(0xFF2563EB), size: 20),
                ),
                const SizedBox(width: 10),
                const Text('Recent Properties Listed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                  child: Text('$totalItems', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                ),
                const Spacer(),
                // Filter Button with active filter badge
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: BorderSide(color: hasActiveFilters ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1)),
                    backgroundColor: hasActiveFilters ? const Color(0xFFEFF6FF) : Colors.transparent,
                  ),
                  onPressed: () => _showPropertiesFilterDialog(context, allDistinctAreas),
                  icon: Icon(Icons.tune_rounded, size: 15, color: hasActiveFilters ? const Color(0xFF2563EB) : const Color(0xFF64748B)),
                  label: Text(
                    hasActiveFilters ? 'Filter ($activeFilterCount)' : 'Filter',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: hasActiveFilters ? FontWeight.bold : FontWeight.w600,
                      color: hasActiveFilters ? const Color(0xFF2563EB) : const Color(0xFF475569),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => context.go('/properties'),
                  icon: const Icon(Icons.open_in_new_rounded, size: 15),
                  label: const Text('View All Inventory', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            // Active Filter Chips
            if (hasActiveFilters) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (_propertyPriceSort == 'high_to_low')
                    Chip(
                      label: const Text('Price: High to Low', style: TextStyle(fontSize: 11)),
                      onDeleted: () => setState(() {
                        _propertyPriceSort = 'none';
                        _propertiesPage = 1;
                      }),
                      deleteIcon: const Icon(Icons.close_rounded, size: 14),
                    ),
                  if (_propertyPriceSort == 'low_to_high')
                    Chip(
                      label: const Text('Price: Low to High', style: TextStyle(fontSize: 11)),
                      onDeleted: () => setState(() {
                        _propertyPriceSort = 'none';
                        _propertiesPage = 1;
                      }),
                      deleteIcon: const Icon(Icons.close_rounded, size: 14),
                    ),
                  ..._selectedPropertyAreas.map((area) => Chip(
                    label: Text(area, style: const TextStyle(fontSize: 11)),
                    onDeleted: () => setState(() {
                      _selectedPropertyAreas.remove(area);
                      _propertiesPage = 1;
                    }),
                    deleteIcon: const Icon(Icons.close_rounded, size: 14),
                  )),
                  TextButton(
                    onPressed: () => setState(() {
                      _propertyPriceSort = 'none';
                      _selectedPropertyAreas.clear();
                      _propertiesPage = 1;
                    }),
                    child: const Text('Clear all', style: TextStyle(fontSize: 11, color: Colors.red)),
                  ),
                ],
              ),
            ],
            const Divider(height: 24),
            if (filteredProps.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.home_work_outlined, size: 36, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        hasActiveFilters
                            ? 'No properties found matching the selected filter criteria.'
                            : (_isRentMode
                                ? 'No rental properties listed in inventory yet.'
                                : 'No re-sale properties listed in inventory yet.'),
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                      if (hasActiveFilters) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => setState(() {
                            _propertyPriceSort = 'none';
                            _selectedPropertyAreas.clear();
                            _propertiesPage = 1;
                          }),
                          child: const Text('Reset filters', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else ...[
              LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  final propMaxWidth = ((availableWidth - 360) * 0.38).clamp(180.0, 260.0);
                  final areaMaxWidth = ((availableWidth - 360) * 0.28).clamp(110.0, 180.0);
                  final estimatedContentWidth = 24.0 + (60.0 + propMaxWidth) + 80.0 + 55.0 + areaMaxWidth + 60.0 + 16.0;

                  double colSpacing = 18.0;
                  if (availableWidth > estimatedContentWidth) {
                    final extra = availableWidth - estimatedContentWidth;
                    colSpacing = (extra / 5.0 + 18.0).clamp(18.0, 48.0);
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: availableWidth),
                      child: DataTable(
                        horizontalMargin: 8,
                        columnSpacing: colSpacing,
                        headingRowHeight: 40,
                        dataRowMinHeight: 56,
                        dataRowMaxHeight: 66,
                        headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                        columns: const [
                          DataColumn(label: Text('#')),
                          DataColumn(label: Text('Property')),
                          DataColumn(label: Text('Price')),
                          DataColumn(label: Text('Type')),
                          DataColumn(label: Text('Area')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: pagedProps.asMap().entries.map((entry) {
                          final index = (currentPage - 1) * _propertiesPerPage + entry.key + 1;
                          final prop = entry.value as Map;
                          final code = (prop['property_code'] ?? prop['code'] ?? 'PROP').toString();
                          final title = (prop['title'] ?? code).toString();
                          final priceVal = prop['price'];
                          final priceStr = _formatPropPrice(priceVal);

                          final listingType = (prop['listing_type'] ?? prop['listingType'] ?? 'Sale').toString();
                          final status = (prop['status'] ?? 'Available').toString();
                          final images = prop['images'] as List? ?? [];
                          final coverImg = images.isNotEmpty ? images.first.toString() : null;

                          String timeStr = '-';
                          final dateStr = prop['created_at'] ?? prop['createdAt'];
                          if (dateStr != null) {
                            final dt = DateTime.tryParse(dateStr.toString());
                            if (dt != null) timeStr = DateFormat('d MMM, h:mm a').format(dt.toLocal());
                          }

                          String areaStr = (prop['area_name'] ?? prop['area'] ?? '').toString().trim();
                          if (areaStr.contains(',')) {
                            areaStr = areaStr.split(',').first.trim();
                          }
                          if (areaStr.isEmpty) {
                            areaStr = '-';
                          }

                          final isRent = listingType.toLowerCase().contains('rent');

                          return DataRow(
                            cells: [
                              DataCell(Text('$index', style: const TextStyle(fontSize: 12, color: Colors.grey))),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // 1. Property Image: size 48x48 with status badge directly over it
                                    Stack(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(8),
                                            image: coverImg != null && coverImg.startsWith('http')
                                                ? DecorationImage(image: NetworkImage(coverImg), fit: BoxFit.cover)
                                                : null,
                                          ),
                                          child: coverImg == null || !coverImg.startsWith('http')
                                              ? const Icon(Icons.home_work_outlined, size: 22, color: Color(0xFF94A3B8))
                                              : null,
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: status.toLowerCase().contains('avail')
                                                  ? const Color(0xFF059669).withValues(alpha: 0.9)
                                                  : (status.toLowerCase().contains('sold') || status.toLowerCase().contains('rented')
                                                      ? const Color(0xFFDC2626).withValues(alpha: 0.9)
                                                      : const Color(0xFF334155).withValues(alpha: 0.9)),
                                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                                            ),
                                            child: Text(
                                              status,
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    // 2. Property Name (main text) + Date and PR Number (small secondary text directly below)
                                    ConstrainedBox(
                                      constraints: BoxConstraints(maxWidth: propMaxWidth),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            timeStr != '-' ? '$timeStr • $code' : code,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(Text(priceStr, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)))),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isRent ? const Color(0xFFEFF6FF) : const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    listingType,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isRent ? const Color(0xFF2563EB) : const Color(0xFFD97706),
                                    ),
                                  ),
                                ),
                              ),
                              // Area column displaying only Area / Location
                              DataCell(
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: areaMaxWidth),
                                  child: Text(
                                    areaStr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
                                  ),
                                ),
                              ),
                              // Actions column with View button
                              DataCell(
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    minimumSize: const Size(0, 28),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                  onPressed: () {
                                    final propId = (prop['id'] ?? '').toString();
                                    if (propId.isNotEmpty) {
                                      _openPropertyDetails(context, propId);
                                    }
                                  },
                                  child: const Text('View', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing ${totalItems == 0 ? 0 : (currentPage - 1) * _propertiesPerPage + 1}–${min(currentPage * _propertiesPerPage, totalItems)} of $totalItems ${_isRentMode ? 'rental ' : 're-sale '}properties',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: currentPage > 1 ? () => setState(() => _propertiesPage = currentPage - 1) : null,
                        icon: const Icon(Icons.chevron_left, size: 16),
                        label: const Text('Previous', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      Text('Page $currentPage of $safeTotalPages', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: currentPage < safeTotalPages ? () => setState(() => _propertiesPage = currentPage + 1) : null,
                        icon: const Icon(Icons.chevron_right, size: 16),
                        label: const Text('Next', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openPropertyDetails(BuildContext context, String propertyId) async {
    try {
      final p = await PropertiesRepository().getPropertyById(propertyId, refreshFromServer: true);
      if (!mounted || !context.mounted) return;
      if (p != null) {
        showCRMPropertyDrawer(context, p);
      } else {
        context.push('/properties/$propertyId');
      }
    } catch (_) {
      if (!mounted || !context.mounted) return;
      context.push('/properties/$propertyId');
    }
  }

  void _showPropertiesFilterDialog(BuildContext context, List<String> availableAreas) {
    String tempPriceSort = _propertyPriceSort;
    final Set<String> tempSelectedAreas = Set<String>.from(_selectedPropertyAreas);
    String areaSearchQuery = '';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredAreas = availableAreas.where((area) {
              if (areaSearchQuery.isEmpty) return true;
              return area.toLowerCase().contains(areaSearchQuery.toLowerCase());
            }).toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                    child: const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(width: 10),
                  const Text('Filter Recent Properties', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                ],
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Price Sorting (Radio buttons)
                      const Text('Price Sorting', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      const SizedBox(height: 6),
                      RadioListTile<String>(
                        title: const Text('Default Order — Newest First', style: TextStyle(fontSize: 13)),
                        value: 'none',
                        groupValue: tempPriceSort,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: const Color(0xFF2563EB),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => tempPriceSort = val);
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Price: High to Low', style: TextStyle(fontSize: 13)),
                        value: 'high_to_low',
                        groupValue: tempPriceSort,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: const Color(0xFF2563EB),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => tempPriceSort = val);
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Price: Low to High', style: TextStyle(fontSize: 13)),
                        value: 'low_to_high',
                        groupValue: tempPriceSort,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: const Color(0xFF2563EB),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => tempPriceSort = val);
                        },
                      ),
                      const Divider(height: 24),

                      // Section 2: Area Filter (Multi-select + Search)
                      Row(
                        children: [
                          const Text('Filter by Area', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          if (tempSelectedAreas.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                              child: Text('${tempSelectedAreas.length} selected', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search areas...',
                          hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                          prefixIcon: const Icon(Icons.search, size: 18),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                        ),
                        style: const TextStyle(fontSize: 13),
                        onChanged: (val) => setDialogState(() => areaSearchQuery = val.trim()),
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 180),
                        child: filteredAreas.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: Text('No matching areas found.', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500)),
                                ),
                              )
                            : Scrollbar(
                                thumbVisibility: true,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: filteredAreas.length,
                                  itemBuilder: (context, index) {
                                    final area = filteredAreas[index];
                                    final isChecked = tempSelectedAreas.contains(area);
                                    return CheckboxListTile(
                                      title: Text(area, style: const TextStyle(fontSize: 12.5)),
                                      value: isChecked,
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      activeColor: const Color(0xFF2563EB),
                                      controlAffinity: ListTileControlAffinity.leading,
                                      onChanged: (val) {
                                        setDialogState(() {
                                          if (val == true) {
                                            tempSelectedAreas.add(area);
                                          } else {
                                            tempSelectedAreas.remove(area);
                                          }
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      tempPriceSort = 'none';
                      tempSelectedAreas.clear();
                      areaSearchQuery = '';
                    });
                  },
                  child: const Text('Reset All', style: TextStyle(color: Colors.grey)),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: () {
                    setState(() {
                      _propertyPriceSort = tempPriceSort;
                      _selectedPropertyAreas.clear();
                      _selectedPropertyAreas.addAll(tempSelectedAreas);
                      _propertiesPage = 1;
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatPropPrice(dynamic amount) {
    if (amount == null) return 'N/A';
    final num val = num.tryParse(amount.toString()) ?? 0;
    if (val <= 0) return 'N/A';
    if (val >= 10000000) {
      return '₹${(val / 10000000).toStringAsFixed(2)} Cr';
    } else if (val >= 100000) {
      return '₹${(val / 100000).toStringAsFixed(2)} L';
    } else {
      return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(val);
    }
  }
}
