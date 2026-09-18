import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/theme/theme_manager.dart';
import '../../requirements/models/requirement_model.dart';
import '../../requirements/screens/add_edit_requirement_screen.dart';

class TelecallerLeadsTable extends StatefulWidget {
  final List<RequirementModel> leads;
  final List<String> availableStatuses;
  final List<String> availableSources;
  final String telecallerName;

  const TelecallerLeadsTable({
    super.key,
    required this.leads,
    required this.availableStatuses,
    required this.availableSources,
    required this.telecallerName,
  });

  @override
  State<TelecallerLeadsTable> createState() => _TelecallerLeadsTableState();
}

class _TelecallerLeadsTableState extends State<TelecallerLeadsTable> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _statusFilter;
  String? _sourceFilter;
  int _sortColumnIndex = 0;
  bool _sortAscending = false;
  int _page = 0;
  static const int _pageSize = 15;

  @override
  void didUpdateWidget(covariant TelecallerLeadsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.leads != widget.leads) {
      _page = 0;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _sourceOf(RequirementModel lead) {
    return lead.leadSourceDisplay ?? lead.leadSource ?? 'Website';
  }

  String _propertyOf(RequirementModel lead) {
    if (lead.rawShareSessions != null && lead.rawShareSessions!.isNotEmpty) {
      final first = lead.rawShareSessions!.first;
      final title = first['property_title'] ?? first['title'] ?? first['propertyTitle'];
      if (title != null && title.toString().trim().isNotEmpty) return title.toString();
    }
    final parts = <String>[
      if (lead.propertyTypeName.isNotEmpty) lead.propertyTypeName,
      if (lead.areaNames.isNotEmpty) lead.areaNames.first,
    ];
    return parts.isEmpty ? '—' : parts.join(' · ');
  }

  String _lastActivityOf(RequirementModel lead) {
    if (lead.remarks != null && lead.remarks!.trim().isNotEmpty) return lead.remarks!.trim();
    if (lead.notes != null && lead.notes!.trim().isNotEmpty) return lead.notes!.trim();
    return '—';
  }

  List<RequirementModel> get _filtered {
    var list = widget.leads.where((lead) {
      if (_statusFilter != null && lead.status.toLowerCase() != _statusFilter!.toLowerCase()) {
        return false;
      }
      if (_sourceFilter != null && _sourceOf(lead).toLowerCase() != _sourceFilter!.toLowerCase()) {
        return false;
      }
      if (_query.trim().isNotEmpty) {
        final q = _query.trim().toLowerCase();
        final haystack = [
          lead.clientName,
          lead.clientMobile,
          lead.status,
          _sourceOf(lead),
          _propertyOf(lead),
          lead.assigneeName ?? '',
        ].join(' ').toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      return true;
    }).toList();

    list.sort((a, b) {
      Comparable valA;
      Comparable valB;
      switch (_sortColumnIndex) {
        case 1:
          valA = a.status;
          valB = b.status;
          break;
        case 2:
          valA = _propertyOf(a);
          valB = _propertyOf(b);
          break;
        case 3:
          valA = _sourceOf(a);
          valB = _sourceOf(b);
          break;
        case 4:
          valA = a.createdAt;
          valB = b.createdAt;
          break;
        case 5:
          valA = a.nextFollowupDate ?? '';
          valB = b.nextFollowupDate ?? '';
          break;
        default:
          valA = a.clientName;
          valB = b.clientName;
      }
      return _sortAscending ? valA.compareTo(valB) : valB.compareTo(valA);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = CRMColors.primary;
    final filtered = _filtered;
    final pageCount = (filtered.length / _pageSize).ceil().clamp(1, 9999);
    if (_page >= pageCount) _page = pageCount - 1;
    final start = _page * _pageSize;
    final pageItems = filtered.skip(start).take(_pageSize).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.list_alt_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Leads',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.2),
                  ),
                ],
              ),
              if (widget.telecallerName.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.telecallerName,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: primaryColor),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${filtered.length} of ${widget.leads.length}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 240,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search leads...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 16),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (val) => setState(() {
                    _query = val;
                    _page = 0;
                  }),
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  initialValue: _statusFilter,
                  isDense: true,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text('All statuses')),
                    ...widget.availableStatuses.map(
                      (s) => DropdownMenuItem<String>(value: s, child: Text(s)),
                    ),
                  ],
                  onChanged: (val) => setState(() {
                    _statusFilter = val;
                    _page = 0;
                  }),
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  initialValue: _sourceFilter,
                  isDense: true,
                  decoration: InputDecoration(
                    labelText: 'Source',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text('All sources')),
                    ...widget.availableSources.map(
                      (s) => DropdownMenuItem<String>(value: s, child: Text(s)),
                    ),
                  ],
                  onChanged: (val) => setState(() {
                    _sourceFilter = val;
                    _page = 0;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (pageItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  'No leads match the current search and filters.',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                sortColumnIndex: _sortColumnIndex,
                sortAscending: _sortAscending,
                columnSpacing: 18,
                headingRowHeight: 40,
                dataRowMinHeight: 46,
                dataRowMaxHeight: 52,
                columns: [
                  DataColumn(label: const Text('Lead', style: TextStyle(fontWeight: FontWeight.bold)), onSort: _onSort),
                  DataColumn(label: const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)), onSort: _onSort),
                  DataColumn(label: const Text('Project / Property', style: TextStyle(fontWeight: FontWeight.bold)), onSort: _onSort),
                  DataColumn(label: const Text('Lead Source', style: TextStyle(fontWeight: FontWeight.bold)), onSort: _onSort),
                  DataColumn(label: const Text('Created', style: TextStyle(fontWeight: FontWeight.bold)), onSort: _onSort),
                  DataColumn(label: const Text('Next Follow-up', style: TextStyle(fontWeight: FontWeight.bold)), onSort: _onSort),
                  const DataColumn(label: Text('Sales User', style: TextStyle(fontWeight: FontWeight.bold))),
                  const DataColumn(label: Text('Last Activity', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: pageItems.map((lead) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          lead.clientName,
                          style: TextStyle(fontWeight: FontWeight.w600, color: primaryColor),
                        ),
                        onTap: () => _openLead(lead),
                      ),
                      DataCell(Text(lead.status)),
                      DataCell(Text(_propertyOf(lead))),
                      DataCell(Text(_sourceOf(lead))),
                      DataCell(Text(DateFormat('dd MMM yyyy').format(lead.createdAt))),
                      DataCell(
                        Text(
                          lead.nextFollowupDate != null && lead.nextFollowupDate!.isNotEmpty
                              ? DateFormat('dd MMM yyyy').format(
                                  DateTime.tryParse(lead.nextFollowupDate!) ?? lead.createdAt,
                                )
                              : '—',
                        ),
                      ),
                      DataCell(Text(lead.assigneeName ?? 'Unassigned')),
                      DataCell(
                        SizedBox(
                          width: 180,
                          child: Text(
                            _lastActivityOf(lead),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          if (filtered.length > _pageSize) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Page ${_page + 1} of $pageCount',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: _page > 0 ? () => setState(() => _page--) : null,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: _page < pageCount - 1 ? () => setState(() => _page++) : null,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _onSort(int index, bool ascending) {
    setState(() {
      _sortColumnIndex = index;
      _sortAscending = ascending;
    });
  }

  void _openLead(RequirementModel lead) {
    showDialog(
      context: context,
      builder: (dialogContext) => AddEditRequirementScreen(
        requirement: lead,
        onSaved: () {},
      ),
    );
  }
}
