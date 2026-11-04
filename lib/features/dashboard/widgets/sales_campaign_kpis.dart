import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../models/kpi_models.dart';

/// Campaign leads the Lead Allocation Engine assigned directly to salespersons, and the
/// Interested / Rejected outcomes those salespersons recorded on them, along with
/// Campaign Follow-ups and Site Visits Scheduled.
class SalesCampaignKpiData {
  final int allocatedTotal;
  final int allocatedListing;
  final int allocatedRequirement;
  final int interested;
  final int rejected;
  final int interestedListing;
  final int interestedRequirement;
  final int rejectedListing;
  final int rejectedRequirement;
  final int followupsTotal;
  final int followupsListing;
  final int followupsRequirement;
  final int siteVisitsScheduledTotal;
  final List<Map<String, dynamic>> propertyListingLeads;
  final List<Map<String, dynamic>> requirementLeads;
  final List<Map<String, dynamic>> propertyListingFollowups;
  final List<Map<String, dynamic>> requirementFollowups;
  final List<Map<String, dynamic>> siteVisitsScheduled;

  const SalesCampaignKpiData({
    this.allocatedTotal = 0,
    this.allocatedListing = 0,
    this.allocatedRequirement = 0,
    this.interested = 0,
    this.rejected = 0,
    this.interestedListing = 0,
    this.interestedRequirement = 0,
    this.rejectedListing = 0,
    this.rejectedRequirement = 0,
    this.followupsTotal = 0,
    this.followupsListing = 0,
    this.followupsRequirement = 0,
    this.siteVisitsScheduledTotal = 0,
    this.propertyListingLeads = const [],
    this.requirementLeads = const [],
    this.propertyListingFollowups = const [],
    this.requirementFollowups = const [],
    this.siteVisitsScheduled = const [],
  });

  static int _int(dynamic v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;

  static List<Map<String, dynamic>> _rows(dynamic v) => v is List
      ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : const [];

  factory SalesCampaignKpiData.fromJson(Map<String, dynamic> json) {
    final allocated = json['allocated'] is Map ? Map<String, dynamic>.from(json['allocated'] as Map) : const {};
    final outcomes = json['outcomes'] is Map ? Map<String, dynamic>.from(json['outcomes'] as Map) : const {};
    final plOutcomes = outcomes['propertyListing'] is Map ? Map<String, dynamic>.from(outcomes['propertyListing'] as Map) : const {};
    final reqOutcomes = outcomes['requirement'] is Map ? Map<String, dynamic>.from(outcomes['requirement'] as Map) : const {};
    final followups = json['followups'] is Map ? Map<String, dynamic>.from(json['followups'] as Map) : const {};
    final siteVisits = json['siteVisits'] is Map ? Map<String, dynamic>.from(json['siteVisits'] as Map) : const {};

    return SalesCampaignKpiData(
      allocatedTotal: _int(allocated['total']),
      allocatedListing: _int(allocated['propertyListing']),
      allocatedRequirement: _int(allocated['requirement']),
      interested: _int(outcomes['interested']),
      rejected: _int(outcomes['rejected']),
      interestedListing: _int(plOutcomes['interested']),
      interestedRequirement: _int(reqOutcomes['interested']),
      rejectedListing: _int(plOutcomes['rejected']),
      rejectedRequirement: _int(reqOutcomes['rejected']),
      followupsTotal: _int(followups['total']),
      followupsListing: _int(followups['propertyListing']),
      followupsRequirement: _int(followups['requirement']),
      siteVisitsScheduledTotal: _int(siteVisits['total']),
      propertyListingLeads: _rows(json['propertyListingLeads']),
      requirementLeads: _rows(json['requirementLeads']),
      propertyListingFollowups: _rows(json['propertyListingFollowups']),
      requirementFollowups: _rows(json['requirementFollowups']),
      siteVisitsScheduled: _rows(json['siteVisitsScheduled']),
    );
  }
}

class SalesCampaignKpiService {
  static Future<SalesCampaignKpiData> fetch(KpiFilterParams filters) async {
    try {
      final response = await ApiClient().get(
        '/sales/campaign-kpis',
        queryParameters: filters.toQueryParams(),
      );
      final body = response.data;
      if (body is Map && body['data'] is Map) {
        return SalesCampaignKpiData.fromJson(Map<String, dynamic>.from(body['data'] as Map));
      }
    } catch (_) {
      try {
        final response = await ApiClient().get(
          '/admin/sales-campaign-kpis',
          queryParameters: filters.toQueryParams(),
        );
        final body = response.data;
        if (body is Map && body['data'] is Map) {
          return SalesCampaignKpiData.fromJson(Map<String, dynamic>.from(body['data'] as Map));
        }
      } catch (e) {
        rethrow;
      }
    }
    return const SalesCampaignKpiData();
  }
}

enum _OutcomeFilter { all, interested, rejected, followups, siteVisits }

bool _isInterestedStatus(String status) {
  final s = status.trim().toLowerCase();
  return s == 'interested' || s == 'active' || s == 'live';
}

bool _isRejectedStatus(String status) {
  final s = status.trim().toLowerCase();
  if (s.contains('duplicate_purged')) return false;
  return s.startsWith('rejected') || s == 'not interested';
}

/// Drill-down for Campaign Leads KPIs:
/// - Auto Allocate Leads (All allocated, with Property Listing & Requirement tabs)
/// - Interested (Interested outcomes, with Property Listing & Requirement tabs)
/// - Rejected (Rejected outcomes, with Property Listing & Requirement tabs)
/// - Follow-Ups (Property Listing Follow-ups & Requirement Follow-ups tabs)
/// - Site Visit Sched (Scheduled client site visits)
class SalesCampaignLeadsDialog extends StatefulWidget {
  final KpiFilterParams filters;
  final _OutcomeFilter _initialOutcome;
  final String title;
  final SalesCampaignKpiData? initialData;

  const SalesCampaignLeadsDialog._(
    this.filters,
    this._initialOutcome,
    this.title, {
    this.initialData,
  });

  static Future<void> showAllocated(
    BuildContext context, {
    required KpiFilterParams filters,
    SalesCampaignKpiData? initialData,
  }) {
    return _show(context, filters, _OutcomeFilter.all, 'Auto Allocate Leads to Sales', initialData: initialData);
  }

  static Future<void> showInterested(
    BuildContext context, {
    required KpiFilterParams filters,
    SalesCampaignKpiData? initialData,
  }) {
    return _show(context, filters, _OutcomeFilter.interested, 'Interested Campaign Leads', initialData: initialData);
  }

  static Future<void> showRejected(
    BuildContext context, {
    required KpiFilterParams filters,
    SalesCampaignKpiData? initialData,
  }) {
    return _show(context, filters, _OutcomeFilter.rejected, 'Rejected Campaign Leads', initialData: initialData);
  }

  static Future<void> showFollowups(
    BuildContext context, {
    required KpiFilterParams filters,
    SalesCampaignKpiData? initialData,
  }) {
    return _show(context, filters, _OutcomeFilter.followups, 'Campaign Leads Follow-ups', initialData: initialData);
  }

  static Future<void> showSiteVisitsScheduled(
    BuildContext context, {
    required KpiFilterParams filters,
    SalesCampaignKpiData? initialData,
  }) {
    return _show(context, filters, _OutcomeFilter.siteVisits, 'Site Visit Scheduled', initialData: initialData);
  }

  static Future<void> showOutcomes(
    BuildContext context, {
    required KpiFilterParams filters,
    SalesCampaignKpiData? initialData,
  }) {
    return _show(context, filters, _OutcomeFilter.interested, 'Sales Lead Outcomes', initialData: initialData);
  }

  static Future<void> _show(
    BuildContext context,
    KpiFilterParams filters,
    _OutcomeFilter outcome,
    String title, {
    SalesCampaignKpiData? initialData,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => SalesCampaignLeadsDialog._(
        filters,
        outcome,
        title,
        initialData: initialData,
      ),
    );
  }

  @override
  State<SalesCampaignLeadsDialog> createState() => _SalesCampaignLeadsDialogState();
}

class _SalesCampaignLeadsDialogState extends State<SalesCampaignLeadsDialog> {
  SalesCampaignKpiData? _data;
  String? _error;
  bool _loading = false;
  late _OutcomeFilter _outcome = widget._initialOutcome;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _data = widget.initialData;
      _loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await SalesCampaignKpiService.fetch(widget.filters);
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load campaign leads data. Please try again.';
        _loading = false;
      });
    }
  }

  String _listingStatus(Map<String, dynamic> lead) =>
      (lead['status'] ?? lead['salesListingStatus'] ?? 'None').toString();

  String _requirementStatus(Map<String, dynamic> lead) =>
      (lead['requirementStatus'] ?? lead['status'] ?? '').toString();

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> rows, String Function(Map<String, dynamic>) status) {
    switch (_outcome) {
      case _OutcomeFilter.interested:
        return rows.where((r) => _isInterestedStatus(status(r))).toList();
      case _OutcomeFilter.rejected:
        return rows.where((r) => _isRejectedStatus(status(r))).toList();
      case _OutcomeFilter.all:
      default:
        return rows;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final data = _data;

    // Follow-ups view
    if (_outcome == _OutcomeFilter.followups) {
      final plFollowups = data?.propertyListingFollowups ?? const [];
      final reqFollowups = data?.requirementFollowups ?? const [];

      return Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: size.width < 600 ? 8 : 32, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1180, maxHeight: size.height * 0.88),
          child: DefaultTabController(
            length: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, [
                  TextButton.icon(
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('Open Campaign Follow-ups'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.go('/my-campaign-leads?tab=Follow-ups');
                    },
                  ),
                ]),
                TabBar(
                  labelColor: CRMColors.primaryOf(context),
                  unselectedLabelColor: CRMColors.textSecondaryOf(context),
                  indicatorColor: CRMColors.primaryOf(context),
                  tabs: [
                    Tab(text: 'Property Listing Leads (${plFollowups.length})'),
                    Tab(text: 'Requirement Leads (${reqFollowups.length})'),
                  ],
                ),
                Flexible(
                  child: _loading
                      ? const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()))
                      : _error != null
                          ? _buildErrorView()
                          : TabBarView(
                              children: [
                                _LeadTable(
                                  rows: plFollowups,
                                  emptyText: 'No pending follow-ups for Property Listing leads.',
                                  columns: const ['Client Name', 'Phone', 'Follow-up Date', 'Remarks', 'Status'],
                                  cells: (f) => [
                                    _text(f['customer_name']),
                                    _text(f['phone']),
                                    _date(f['followup_date']),
                                    _text(f['remarks']),
                                    _text(f['status']),
                                  ],
                                  statusColumn: 4,
                                ),
                                _LeadTable(
                                  rows: reqFollowups,
                                  emptyText: 'No pending follow-ups for Requirement leads.',
                                  columns: const ['Client Name', 'Phone', 'Follow-up Date', 'Remarks', 'Status'],
                                  cells: (f) => [
                                    _text(f['customer_name']),
                                    _text(f['phone']),
                                    _date(f['followup_date']),
                                    _text(f['remarks']),
                                    _text(f['status']),
                                  ],
                                  statusColumn: 4,
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

    // Site Visits view
    if (_outcome == _OutcomeFilter.siteVisits) {
      final visits = data?.siteVisitsScheduled ?? const [];

      return Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: size.width < 600 ? 8 : 32, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1180, maxHeight: size.height * 0.88),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, [
                TextButton.icon(
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('View Scheduled'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go('/requirements?tab=follow-ups&subTab=site-visits');
                  },
                ),
              ]),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Scheduled Site Visits (${visits.length})',
                  style: CRMTypography.headline,
                ),
              ),
              Flexible(
                child: _loading
                    ? const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()))
                    : _error != null
                        ? _buildErrorView()
                        : _LeadTable(
                            rows: visits,
                            emptyText: 'No site visits currently scheduled.',
                            columns: const ['Client Name', 'Mobile', 'Property Code / Title', 'Visit Date & Time', 'Status', 'Remarks'],
                            cells: (v) => [
                              _text(v['customer_name']),
                              _text(v['mobile']),
                              '${_text(v['property_code'])} ${_text(v['property_title'])}'.trim(),
                              _date(v['visit_date'] ?? v['scheduled_at']),
                              _text(v['status']),
                              _text(v['remarks']),
                            ],
                            statusColumn: 4,
                          ),
              ),
            ],
          ),
        ),
      );
    }

    // Standard Lead Allocated / Interested / Rejected view with Property Listing & Requirement tabs
    final listing = data == null ? const <Map<String, dynamic>>[] : _filtered(data.propertyListingLeads, _listingStatus);
    final requirement = data == null ? const <Map<String, dynamic>>[] : _filtered(data.requirementLeads, _requirementStatus);

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: size.width < 600 ? 8 : 32, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 1180, maxHeight: size.height * 0.88),
        child: DefaultTabController(
          length: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              if (data != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _outcomeChip('All allocated', _OutcomeFilter.all, data.allocatedTotal),
                      _outcomeChip('Interested', _OutcomeFilter.interested, data.interested),
                      _outcomeChip('Rejected', _OutcomeFilter.rejected, data.rejected),
                    ],
                  ),
                ),
              TabBar(
                labelColor: CRMColors.primaryOf(context),
                unselectedLabelColor: CRMColors.textSecondaryOf(context),
                indicatorColor: CRMColors.primaryOf(context),
                tabs: [
                  Tab(text: 'Property Listing Leads (${listing.length})'),
                  Tab(text: 'Requirement Leads (${requirement.length})'),
                ],
              ),
              Flexible(
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _error != null
                        ? _buildErrorView()
                        : TabBarView(
                            children: [
                              _LeadTable(
                                rows: listing,
                                emptyText: 'No Property Listing leads match this view.',
                                columns: const [
                                  'Salesperson', 'Client Name', 'Phone', 'Source', 'Status', 'Allocated On',
                                  'Property Type', 'Expected Rent', 'Property Location', 'City', 'Campaign Name',
                                ],
                                cells: (lead) => [
                                  _text(lead['assignedToName']),
                                  _text(lead['clientName']),
                                  _text(lead['phone']),
                                  _text(lead['source']),
                                  _listingStatus(lead),
                                  _date(lead['allocatedAt'] ?? lead['receivedOn']),
                                  _text(lead['propertyType']),
                                  _text(lead['expectedRent']),
                                  _text(lead['propertyLocation']),
                                  _text(lead['city']),
                                  _text(lead['campaignName']),
                                ],
                                statusColumn: 4,
                              ),
                              _LeadTable(
                                rows: requirement,
                                emptyText: 'No Requirement leads match this view.',
                                columns: const [
                                  'Salesperson', 'Client Name', 'Phone', 'Source', 'Status', 'Allocated On',
                                  'Configuration', 'Budget', 'Category', 'Business',
                                ],
                                cells: (lead) => [
                                  _text(lead['assignedToName']),
                                  _text(lead['clientName']),
                                  _text(lead['phone']),
                                  _text(lead['source']),
                                  _requirementStatus(lead),
                                  _date(lead['allocatedAt'] ?? lead['receivedOn']),
                                  _text(lead['config']),
                                  _text(lead['budget']),
                                  _text(lead['category']),
                                  _text(lead['listingMode']),
                                ],
                                statusColumn: 4,
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

  Widget _buildHeader(BuildContext context, [List<Widget> extraActions = const []]) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 4),
      child: Row(
        children: [
          Expanded(child: Text(widget.title, style: CRMTypography.title)),
          ...extraActions,
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
          ),
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(_error ?? 'Unknown error', style: CRMTypography.body.copyWith(color: CRMColors.danger)),
      ),
    );
  }

  Widget _outcomeChip(String label, _OutcomeFilter value, int count) {
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: _outcome == value,
      onSelected: (_) => setState(() => _outcome = value),
    );
  }

  static String _text(dynamic v) {
    final s = (v ?? '').toString().trim();
    return s.isEmpty || s == 'null' ? '—' : s;
  }

  static String _date(dynamic v) {
    final parsed = DateTime.tryParse((v ?? '').toString());
    if (parsed == null) return '—';
    return DateFormat('dd MMM yy, h:mm a').format(parsed.toLocal());
  }
}

class _LeadTable extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final List<String> columns;
  final List<String> Function(Map<String, dynamic>) cells;
  final int statusColumn;
  final String emptyText;

  const _LeadTable({
    required this.rows,
    required this.columns,
    required this.cells,
    required this.statusColumn,
    required this.emptyText,
  });

  Color _statusColor(String status) {
    if (_isInterestedStatus(status)) return CRMColors.success;
    if (_isRejectedStatus(status)) return CRMColors.danger;
    return const Color(0xFF2563EB);
  }

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(emptyText, style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context))),
        ),
      );
    }

    if (MediaQuery.sizeOf(context).width < 700) {
      return ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: rows.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final values = cells(rows[index]);
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CRMColors.cardBgOf(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: CRMColors.borderOf(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < columns.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(columns[i], style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context))),
                        ),
                        Expanded(
                          child: Text(
                            values[i],
                            style: CRMTypography.caption.copyWith(
                              fontWeight: i == statusColumn ? FontWeight.w700 : FontWeight.w500,
                              color: i == statusColumn ? _statusColor(values[i]) : CRMColors.textOf(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 40,
          dataRowMinHeight: 40,
          dataRowMaxHeight: 56,
          columnSpacing: 20,
          headingTextStyle: CRMTypography.captionBold.copyWith(color: CRMColors.textSecondaryOf(context)),
          columns: [
            const DataColumn(label: Text('#')),
            for (final c in columns) DataColumn(label: Text(c)),
          ],
          rows: [
            for (var index = 0; index < rows.length; index++)
              DataRow(
                cells: [
                  DataCell(Text('${index + 1}')),
                  for (final entry in cells(rows[index]).asMap().entries)
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(
                          entry.value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: entry.key == statusColumn
                              ? CRMTypography.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: _statusColor(entry.value),
                                )
                              : CRMTypography.caption,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
