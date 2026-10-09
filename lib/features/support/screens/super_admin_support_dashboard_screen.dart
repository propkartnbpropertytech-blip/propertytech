import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme_manager.dart';
import '../models/support_issue_model.dart';
import '../services/support_service.dart';
import '../widgets/issue_details_drawer.dart';

class SuperAdminSupportDashboardScreen extends StatefulWidget {
  const SuperAdminSupportDashboardScreen({super.key});

  @override
  State<SuperAdminSupportDashboardScreen> createState() => _SuperAdminSupportDashboardScreenState();
}

class _SuperAdminSupportDashboardScreenState extends State<SuperAdminSupportDashboardScreen> {
  bool _isLoading = true;
  List<SupportIssue> _issues = [];
  SupportStats _stats = const SupportStats(total: 0, open: 0, inProgress: 0, waitingForUser: 0, resolved: 0, closed: 0);

  String _roleFilter = 'All';
  String _statusFilter = 'All';
  String _priorityFilter = 'All';
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

    final statsData = await SupportService.instance.fetchStats();
    final issuesData = await SupportService.instance.fetchIssues(
      status: _statusFilter,
      priority: _priorityFilter,
      role: _roleFilter,
      search: _searchQuery,
      page: 1,
      limit: 100,
    );

    if (mounted) {
      setState(() {
        _stats = statsData;
        _issues = (issuesData['issues'] as List<SupportIssue>?) ?? [];
        _isLoading = false;
      });
    }
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
      case 'waiting for user':
        return const Color(0xFF8B5CF6);
      case 'resolved':
        return const Color(0xFF10B981);
      case 'closed':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF64748B);
    }
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

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Super Admin Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                        : [const Color(0xFF4F46E5).withValues(alpha: 0.1), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF3730A3) : const Color(0xFFC7D2FE)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Super Admin Issue Management Desk',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Review, reassign, update status, and reply to support issues submitted across Admin, Telecaller, and Sales roles.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _loadData(),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Refresh Inbox'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // KPI Cards Row
              Row(
                children: [
                  _buildKpiCard('Total System Issues', _stats.total.toString(), Icons.all_inbox_rounded, const Color(0xFF4F46E5), isDark),
                  const SizedBox(width: 12),
                  _buildKpiCard('Open Needs Review', _stats.open.toString(), Icons.error_outline_rounded, const Color(0xFF3B82F6), isDark),
                  const SizedBox(width: 12),
                  _buildKpiCard('In Progress', _stats.inProgress.toString(), Icons.pending_actions_rounded, const Color(0xFFF59E0B), isDark),
                  const SizedBox(width: 12),
                  _buildKpiCard('Resolved', _stats.resolved.toString(), Icons.check_circle_outline_rounded, const Color(0xFF10B981), isDark),
                ],
              ),
              const SizedBox(height: 16),

              // Filter Controls Toolbar
              Row(
                children: [
                  // Role Filter Tabs
                  Expanded(
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'All', label: Text('All Roles')),
                        ButtonSegment(value: 'Admin', label: Text('Admin')),
                        ButtonSegment(value: 'Telecaller', label: Text('Telecaller')),
                        ButtonSegment(value: 'Sales', label: Text('Sales')),
                      ],
                      selected: {_roleFilter},
                      onSelectionChanged: (val) {
                        setState(() => _roleFilter = val.first);
                        _loadData();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

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
                        items: const ['All', 'Open', 'In Progress', 'Waiting for User', 'Resolved', 'Closed']
                            .map((s) => DropdownMenuItem(value: s, child: Text('Status: $s', style: const TextStyle(fontSize: 12))))
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
                  const SizedBox(width: 8),

                  // Priority Filter Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _priorityFilter,
                        isDense: true,
                        items: const ['All', 'Low', 'Medium', 'High', 'Critical']
                            .map((p) => DropdownMenuItem(value: p, child: Text('Priority: $p', style: const TextStyle(fontSize: 12))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _priorityFilter = val);
                            _loadData();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search Bar
              TextField(
                controller: _searchController,
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: 'Search by Ticket #, Reporter Name, Page, Function, or Keyword...',
                  hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  isDense: true,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                ),
                onChanged: (val) {
                  _searchQuery = val;
                  _loadData();
                },
              ),
              const SizedBox(height: 16),

              // Super Admin Issues Data Table
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _issues.isEmpty
                        ? const Center(child: Text('No support issues matching current filter.'))
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

                                          // Reporter Info
                                          Expanded(
                                            flex: 2,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  issue.reporterName,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                  ),
                                                ),
                                                Text(
                                                  issue.reporterRole,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Page & Function
                                          Expanded(
                                            flex: 3,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${issue.pageName} -> ${issue.functionName}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12.5,
                                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                  ),
                                                ),
                                                Text(
                                                  issue.issueType,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Priority
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
                                              issue.status,
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

  Widget _buildKpiCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
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
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
