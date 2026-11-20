import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/security/admin_action_gate.dart';
import '../../../core/security/role_guard.dart';
import '../../../core/theme/theme_manager.dart';
import '../models/support_issue_model.dart';
import '../services/support_service.dart';
import '../widgets/create_issue_modal.dart';
import '../widgets/issue_details_drawer.dart';

class SupportScreen extends StatefulWidget {
  final String? initialPageKey;

  const SupportScreen({
    super.key,
    this.initialPageKey,
  });

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  bool _isLoading = true;
  List<SupportCatalogPage> _catalog = [];
  List<SupportIssue> _issues = [];
  SupportStats _stats = const SupportStats(total: 0, open: 0, inProgress: 0, waitingForUser: 0, resolved: 0, closed: 0);

  String _statusFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final catalogData = await SupportService.instance.fetchCatalog();
    final statsData = await SupportService.instance.fetchStats();
    final issuesData = await SupportService.instance.fetchIssues(
      status: _statusFilter,
      search: _searchQuery,
      page: 1,
      limit: 50,
    );

    if (mounted) {
      setState(() {
        _catalog = catalogData;
        _stats = statsData;
        _issues = (issuesData['issues'] as List<SupportIssue>?) ?? [];
        _isLoading = false;
      });

      if (widget.initialPageKey != null && widget.initialPageKey!.isNotEmpty && _catalog.isNotEmpty) {
        _openCreateIssueModal(initialPageKey: widget.initialPageKey);
      }
    }
  }

  void _openCreateIssueModal({String? initialPageKey}) {
    if (!RoleGuard.canAction('page.support.report_issue')) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CreateIssueModal(
        catalog: _catalog,
        initialPageKey: initialPageKey,
        onSubmitted: () {
          _loadData();
        },
      ),
    );
  }

  void _openIssueDetails(String issueId) {
    showDialog(
      context: context,
      builder: (ctx) => IssueDetailsDrawer(
        issueId: issueId,
        onUpdated: () => _loadData(),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return const Color(0xFF3B82F6);
      case 'in progress':
        return const Color(0xFFF59E0B);
      case 'complete':
      case 'resolved':
      case 'closed':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _normalizeStatus(String status) {
    final lower = status.trim().toLowerCase();
    if (lower == 'open') return 'Open';
    if (lower == 'in progress') return 'In Progress';
    if (lower == 'complete' || lower == 'resolved' || lower == 'closed') return 'Complete';
    return 'Open';
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return const Color(0xFFEF4444);
      case 'high':
        return const Color(0xFFF97316);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'low':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = ThemeManager().primaryColor;
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (isMobile) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderBanner(isDark, primaryColor, isMobile: true),
                const SizedBox(height: 12),
                _buildKpiSection(primaryColor, isDark, isMobile: true),
                const SizedBox(height: 12),
                _buildSearchFilterToolbar(isDark, isMobile: true),
                const SizedBox(height: 12),
                _isLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _issues.isEmpty
                        ? _buildEmptyState(isDark)
                        : Column(
                            children: _issues
                                .map((issue) => _buildMobileTicketCard(issue, primaryColor, isDark))
                                .toList(),
                          ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderBanner(isDark, primaryColor, isMobile: false),
              const SizedBox(height: 16),
              _buildKpiSection(primaryColor, isDark, isMobile: false),
              const SizedBox(height: 16),
              _buildSearchFilterToolbar(isDark, isMobile: false),
              const SizedBox(height: 16),

              // Table / Tickets List (Desktop)
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _issues.isEmpty
                        ? _buildEmptyState(isDark)
                        : Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: ListView.separated(
                                itemCount: _issues.length,
                                separatorBuilder: (ctx, index) => Divider(
                                  height: 1,
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                ),
                                itemBuilder: (ctx, index) {
                                  final issue = _issues[index];
                                  return _buildDesktopTicketRow(issue, primaryColor, isDark);
                                },
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(bool isDark, Color primaryColor, {required bool isMobile}) {
    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                : [primaryColor.withValues(alpha: 0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Support & Help Center',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Report issues for any page or function. Track resolution in real time.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AdminActionGate(
              actionKey: 'page.support.report_issue',
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openCreateIssueModal(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Report an Issue', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [primaryColor.withValues(alpha: 0.1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Role-Based Support & Help Center',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Report issues for any page or function in the software. Track resolution & replies in real time.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          AdminActionGate(
            actionKey: 'page.support.report_issue',
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: ElevatedButton.icon(
                onPressed: () => _openCreateIssueModal(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Report an Issue'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiSection(Color primaryColor, bool isDark, {required bool isMobile}) {
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              _buildKpiCard('Total Tickets', _stats.total.toString(), Icons.confirmation_number_outlined, primaryColor, isDark, isMobile: true),
              const SizedBox(width: 10),
              _buildKpiCard('Open', _stats.open.toString(), Icons.error_outline_rounded, const Color(0xFF3B82F6), isDark, isMobile: true),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildKpiCard('In Progress', _stats.inProgress.toString(), Icons.pending_actions_rounded, const Color(0xFFF59E0B), isDark, isMobile: true),
              const SizedBox(width: 10),
              _buildKpiCard('Complete', _stats.complete.toString(), Icons.check_circle_outline_rounded, const Color(0xFF10B981), isDark, isMobile: true),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        _buildKpiCard('Total Tickets', _stats.total.toString(), Icons.confirmation_number_outlined, primaryColor, isDark),
        const SizedBox(width: 12),
        _buildKpiCard('Open', _stats.open.toString(), Icons.error_outline_rounded, const Color(0xFF3B82F6), isDark),
        const SizedBox(width: 12),
        _buildKpiCard('In Progress', _stats.inProgress.toString(), Icons.pending_actions_rounded, const Color(0xFFF59E0B), isDark),
        const SizedBox(width: 12),
        _buildKpiCard('Complete', _stats.complete.toString(), Icons.check_circle_outline_rounded, const Color(0xFF10B981), isDark),
      ],
    );
  }

  Widget _buildSearchFilterToolbar(bool isDark, {required bool isMobile}) {
    return Row(
      children: [
        // Search Bar
        Expanded(
          child: TextField(
            controller: _searchController,
            style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: isMobile ? 'Search tickets...' : 'Search by Ticket #, Page, Function, or Issue Type...',
              hintStyle: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
            ),
            onChanged: (val) {
              _searchQuery = val;
              _loadData();
            },
          ),
        ),
        const SizedBox(width: 8),

        // Status Filter Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _statusFilter,
              isDense: true,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              items: const ['All', 'Open', 'In Progress', 'Complete']
                  .map((s) => DropdownMenuItem(value: s, child: Text(isMobile ? s : 'Status: $s', style: const TextStyle(fontSize: 12))))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _statusFilter = val);
                  _loadData();
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTicketRow(SupportIssue issue, Color primaryColor, bool isDark) {
    return InkWell(
      onTap: () => _openIssueDetails(issue.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Ticket Number
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                issue.ticketNumber,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: primaryColor),
              ),
            ),
            const SizedBox(width: 14),

            // Page & Function Info
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${issue.pageName} -> ${issue.functionName}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    issue.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            // Issue Type
            Expanded(
              flex: 2,
              child: Text(
                issue.issueType,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                ),
              ),
            ),

            // Priority Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _getPriorityColor(issue.priority).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                issue.priority,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _getPriorityColor(issue.priority),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(issue.status).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _normalizeStatus(issue.status),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(issue.status),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Date
            Text(
              DateFormat('MMM d, h:mm a').format(issue.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileTicketCard(SupportIssue issue, Color primaryColor, bool isDark) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _openIssueDetails(issue.id),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top line: Ticket #, Status, Priority
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      issue.ticketNumber,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: primaryColor),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getStatusColor(issue.status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _normalizeStatus(issue.status),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(issue.status),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(issue.priority).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      issue.priority,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: _getPriorityColor(issue.priority),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Title: Page -> Function
              Text(
                '${issue.pageName} -> ${issue.functionName}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (issue.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  issue.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
              const SizedBox(height: 8),

              // Bottom line: Category, Date, Chevron
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      issue.issueType,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('MMM d, h:mm a').format(issue.createdAt),
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color, bool isDark, {bool isMobile = false}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(isMobile ? 10 : 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: isMobile ? 18 : 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isMobile ? 10.5 : 11,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 48, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            'No support tickets reported yet.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Click "Report an Issue" above to submit a ticket for any page or function.',
            style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
