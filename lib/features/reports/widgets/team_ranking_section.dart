import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/theme/theme_manager.dart';
import '../models/report_data.dart';

class TeamRankingSection extends StatefulWidget {
  final List<TeamMemberRanking> telecallerRankings;
  final List<TeamMemberRanking> salesRankings;
  final void Function(TeamMemberRanking member)? onUserSelected;

  const TeamRankingSection({
    super.key,
    required this.telecallerRankings,
    required this.salesRankings,
    this.onUserSelected,
  });

  @override
  State<TeamRankingSection> createState() => _TeamRankingSectionState();
}

class _TeamRankingSectionState extends State<TeamRankingSection> {
  int _activeTab = 1; // 0 = Telecallers, 1 = Sales Users (Sales default)
  int _sortColumnIndex = 6; // default sort by Won Deals
  bool _sortAscending = false;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = CRMColors.primary;

    final rawList = _activeTab == 0 ? widget.telecallerRankings : widget.salesRankings;
    final sortedList = List<TeamMemberRanking>.from(rawList);

    sortedList.sort((a, b) {
      Comparable valA;
      Comparable valB;
      switch (_sortColumnIndex) {
        case 0:
          valA = a.rank;
          valB = b.rank;
          break;
        case 1:
          valA = a.userName;
          valB = b.userName;
          break;
        case 2:
          valA = a.leadsCount;
          valB = b.leadsCount;
          break;
        case 3:
          valA = a.contactedCount;
          valB = b.contactedCount;
          break;
        case 4:
          valA = a.qualifiedCount;
          valB = b.qualifiedCount;
          break;
        case 5:
          valA = a.siteVisitsCount;
          valB = b.siteVisitsCount;
          break;
        case 6:
          valA = a.wonCount;
          valB = b.wonCount;
          break;
        case 7:
          valA = a.conversionRate;
          valB = b.conversionRate;
          break;
        default:
          valA = a.rank;
          valB = b.rank;
      }
      return _sortAscending ? valA.compareTo(valB) : valB.compareTo(valA);
    });

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Tab Switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.military_tech_outlined, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Team Performance Ranking',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    _buildTabButton(
                      title: 'Sales Users',
                      isSelected: _activeTab == 1,
                      onTap: () => setState(() {
                        _activeTab = 1;
                        _sortColumnIndex = 6; // sort by won
                        _sortAscending = false;
                      }),
                    ),
                    const SizedBox(width: 4),
                    _buildTabButton(
                      title: 'Telecallers',
                      isSelected: _activeTab == 0,
                      onTap: () => setState(() {
                        _activeTab = 0;
                        _sortColumnIndex = 2; // sort by leads
                        _sortAscending = false;
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Interactive Sortable Ranking Table
          if (sortedList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text(
                  'No ${_activeTab == 0 ? 'Telecaller' : 'Sales'} activity recorded in this period.',
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
                columnSpacing: 24,
                headingRowHeight: 42,
                dataRowMinHeight: 46,
                dataRowMaxHeight: 52,
                columns: [
                  DataColumn(
                    label: const Text('Rank', style: TextStyle(fontWeight: FontWeight.bold)),
                    numeric: true,
                    onSort: (idx, asc) => _onSort(idx, asc),
                  ),
                  DataColumn(
                    label: const Text('User', style: TextStyle(fontWeight: FontWeight.bold)),
                    onSort: (idx, asc) => _onSort(idx, asc),
                  ),
                  DataColumn(
                    label: const Text('Leads', style: TextStyle(fontWeight: FontWeight.bold)),
                    numeric: true,
                    onSort: (idx, asc) => _onSort(idx, asc),
                  ),
                  DataColumn(
                    label: const Text('Contacted', style: TextStyle(fontWeight: FontWeight.bold)),
                    numeric: true,
                    onSort: (idx, asc) => _onSort(idx, asc),
                  ),
                  DataColumn(
                    label: const Text('Qualified', style: TextStyle(fontWeight: FontWeight.bold)),
                    numeric: true,
                    onSort: (idx, asc) => _onSort(idx, asc),
                  ),
                  DataColumn(
                    label: const Text('Site Visits', style: TextStyle(fontWeight: FontWeight.bold)),
                    numeric: true,
                    onSort: (idx, asc) => _onSort(idx, asc),
                  ),
                  DataColumn(
                    label: const Text('Won Deals', style: TextStyle(fontWeight: FontWeight.bold)),
                    numeric: true,
                    onSort: (idx, asc) => _onSort(idx, asc),
                  ),
                  DataColumn(
                    label: const Text('Conversion %', style: TextStyle(fontWeight: FontWeight.bold)),
                    numeric: true,
                    onSort: (idx, asc) => _onSort(idx, asc),
                  ),
                ],
                rows: sortedList.map((m) {
                  return DataRow(
                    cells: [
                      DataCell(
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: m.rank == 1
                              ? const Color(0xFFEAB308).withValues(alpha: 0.2)
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          child: Text(
                            '#${m.rank}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: m.rank == 1 ? const Color(0xFFCA8A04) : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        InkWell(
                          onTap: () {
                            if (widget.onUserSelected != null) {
                              widget.onUserSelected!(m);
                            } else {
                              final target = _activeTab == 0 ? '/reports/leads/telecaller' : '/reports/leads/sales';
                              context.go(target);
                            }
                          },
                          child: Text(
                            m.userName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(m.leadsCount.toString())),
                      DataCell(Text(m.contactedCount.toString())),
                      DataCell(Text(m.qualifiedCount.toString())),
                      DataCell(Text(m.siteVisitsCount.toString())),
                      DataCell(
                        Text(
                          m.wonCount.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: m.wonCount > 0 ? const Color(0xFF16A34A) : null,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${m.conversionRate.toStringAsFixed(1)}%',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = CRMColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? const Color(0xFF1E293B) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? primaryColor : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }
}
