import 'package:flutter/material.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/widgets/form/crm_image_picker.dart';
import '../../../core/security/role_guard.dart';
import '../../../core/theme/theme_manager.dart';
import '../models/support_issue_model.dart';
import '../services/support_service.dart';

class CreateIssueModal extends StatefulWidget {
  final List<SupportCatalogPage> catalog;
  final VoidCallback onSubmitted;
  final String? initialPageKey;

  const CreateIssueModal({
    super.key,
    required this.catalog,
    required this.onSubmitted,
    this.initialPageKey,
  });

  @override
  State<CreateIssueModal> createState() => _CreateIssueModalState();
}

class _CreateIssueModalState extends State<CreateIssueModal> {
  int _currentStep = 0;

  List<SupportCatalogPage> _catalogPages = [];
  SupportCatalogPage? _selectedPage;
  SupportCatalogFunction? _selectedFunction;
  String _issueType = 'Function not working';
  String _priority = 'Medium';
  final TextEditingController _descriptionController = TextEditingController();
  final List<String> _uploadedImages = [];

  bool _isSubmitting = false;
  String? _errorMessage;
  SupportIssue? _submittedIssue;

  final List<String> _issueTypes = const [
    'Function not working',
    'Incorrect data or count',
    'Data not saving or updating',
    'Error message or unexpected behavior',
    'Slow performance',
    'UI or display issue',
    'Access or permission issue',
    'Other',
  ];

  final List<String> _priorities = const ['Low', 'Medium', 'High', 'Critical'];

  @override
  void initState() {
    super.initState();
    _initCatalogPages();
  }

  void _initCatalogPages() {
    final baseList = widget.catalog.isNotEmpty ? widget.catalog : _fallbackCatalog;
    final userRole = (RoleGuard.currentUser?.role ?? '').toLowerCase();
    final isTelecaller = RoleGuard.isTelecaller(userRole) || userRole == 'telecaller';
    final isSales = RoleGuard.isSales(userRole) || userRole == 'sales' || userRole == 'salesperson';
    final isSuperAdmin = RoleGuard.isSuperAdmin(userRole);
    final isAdmin = RoleGuard.isAdmin(userRole) || userRole == 'admin' || isSuperAdmin;

    final filtered = baseList.where((page) {
      if (isSuperAdmin) return true;

      final key = page.pageKey;

      if (isTelecaller) {
        // Telecaller only sees pages accessible to Telecaller
        const telecallerAllowed = {
          '/dashboard',
          '/properties',
          '/telecaller/leads',
          '/campaign/leads',
          '/telecaller/callbacks',
          '/telecaller/cnr',
          '/requirements',
          '/library',
          '/messages',
          '/profile',
        };
        return telecallerAllowed.contains(key);
      }

      if (isSales) {
        // Salesperson only sees pages accessible to Salesperson
        const salesAllowed = {
          '/dashboard',
          '/properties',
          '/requirements',
          '/library',
          '/messages',
          '/profile',
        };
        return salesAllowed.contains(key);
      }

      if (isAdmin) {
        // Admin sees all operational pages, except Super Admin only audit logs
        if (key == '/settings/audit-logs') return isSuperAdmin;
        return true;
      }

      return page.allowedRoles.any((r) => r.toLowerCase() == userRole);
    }).map((page) {
      // Enforce function-level role permissions
      var fns = page.functions;
      if (!isAdmin) {
        fns = fns.where((fn) {
          final k = fn.key.toLowerCase();
          if (k == 'inspection_mode') return false;
          if (k == 'reassign_lead' || k == 'export_data') return false;
          if (k == 'bulk_assignment' || k == 'spreadsheet_upload') return false;
          if (k == 'archive_property') return false;
          return true;
        }).toList();
      }

      String customName = page.pageName;
      if (isTelecaller && page.pageKey == '/requirements') {
        customName = 'All Leads (Track)';
      } else if (isSales && page.pageKey == '/dashboard') {
        customName = 'Sales Dashboard';
      }

      return SupportCatalogPage(
        id: page.id,
        pageKey: page.pageKey,
        pageName: customName,
        category: page.category,
        description: page.description,
        allowedRoles: page.allowedRoles,
        functions: fns,
      );
    }).toList();

    // Deduplicate by pageKey so DropdownMenuItem never has duplicates
    final seen = <String>{};
    final unique = <SupportCatalogPage>[];
    for (final p in filtered) {
      if (seen.add(p.pageKey)) {
        unique.add(p);
      }
    }
    _catalogPages = unique;

    if (_catalogPages.isNotEmpty) {
      if (widget.initialPageKey != null && widget.initialPageKey!.isNotEmpty) {
        final match = _catalogPages.firstWhere(
          (p) => p.pageKey == widget.initialPageKey,
          orElse: () => _catalogPages.first,
        );
        _selectedPage = match;
      } else {
        _selectedPage = _catalogPages.first;
      }
      if (_selectedPage != null && _selectedPage!.functions.isNotEmpty) {
        _selectedFunction = _selectedPage!.functions.first;
      }
    } else {
      _selectedPage = null;
      _selectedFunction = null;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _onPageChanged(SupportCatalogPage? page) {
    setState(() {
      _selectedPage = page;
      if (page != null && page.functions.isNotEmpty) {
        _selectedFunction = page.functions.first;
      } else {
        _selectedFunction = null;
      }
    });
  }

  Future<void> _submitTicket() async {
    if (_selectedPage == null || _selectedFunction == null) {
      setState(() => _errorMessage = 'Please select a page and function.');
      return;
    }
    final desc = _descriptionController.text.trim();
    if (desc.length < 5) {
      setState(() => _errorMessage = 'Please provide a description (at least 5 characters).');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final attachments = _uploadedImages.map((url) {
        final uriParts = url.split('/').last.split('?').first;
        return {
          'file_name': uriParts.isNotEmpty ? uriParts : 'Issue Screenshot',
          'file_path': url,
          'file_type': 'image',
        };
      }).toList();

      final issue = await SupportService.instance.createIssue(
        pageKey: _selectedPage!.pageKey,
        pageName: _selectedPage!.pageName,
        functionKey: _selectedFunction!.key,
        functionName: _selectedFunction!.name,
        issueType: _issueType,
        priority: _priority,
        description: desc,
        attachments: attachments,
      );

      setState(() {
        _submittedIssue = issue;
        _isSubmitting = false;
        _currentStep = 4; // Success step
      });

      widget.onSubmitted();
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = ThemeManager().primaryColor;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 620,
        constraints: const BoxConstraints(maxHeight: 720),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.help_outline_rounded, color: primaryColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report an Issue / Support Request',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Step ${_currentStep + 1} of 5 — Select details and submit',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Step Indicator Progress Bar
            Row(
              children: List.generate(5, (index) {
                final isActive = index <= _currentStep;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isActive ? primaryColor : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: CRMColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CRMColors.danger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: CRMColors.danger, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 12.5, color: CRMColors.danger, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

            // Step Content Body
            Expanded(
              child: SingleChildScrollView(
                child: _buildStepBody(isDark, primaryColor),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Navigation Buttons Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0 && _currentStep < 4)
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _currentStep--),
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const Text('Previous'),
                  )
                else
                  const SizedBox.shrink(),
                Row(
                  children: [
                    if (_currentStep < 4)
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    const SizedBox(width: 10),
                    if (_currentStep < 3)
                      ElevatedButton.icon(
                        onPressed: () {
                          if (_currentStep == 0 && _selectedPage == null) {
                            setState(() => _errorMessage = 'Please select a page.');
                            return;
                          }
                          if (_currentStep == 1 && _selectedFunction == null) {
                            setState(() => _errorMessage = 'Please select a function.');
                            return;
                          }
                          setState(() {
                            _errorMessage = null;
                            _currentStep++;
                          });
                        },
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: const Text('Next Step'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      )
                    else if (_currentStep == 3)
                      ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitTicket,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.send_rounded, size: 16),
                        label: Text(_isSubmitting ? 'Submitting...' : 'Submit Support Ticket'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Done / Close'),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBody(bool isDark, Color primaryColor) {
    switch (_currentStep) {
      case 0:
        return _buildStep1PageSelection(isDark, primaryColor);
      case 1:
        return _buildStep2FunctionSelection(isDark, primaryColor);
      case 2:
        return _buildStep3IssueTypeSelection(isDark, primaryColor);
      case 3:
        return _buildStep4DescriptionAndAttachments(isDark, primaryColor);
      case 4:
        return _buildStep5SuccessConfirmation(isDark, primaryColor);
      default:
        return const SizedBox.shrink();
    }
  }


  List<SupportCatalogPage> get _fallbackCatalog {
    return const [
      SupportCatalogPage(
        id: 'cat-1',
        pageKey: '/dashboard',
        pageName: 'Executive Dashboard',
        category: 'Overview & KPIs',
        description: 'Main dashboard with summary KPIs, recent leads, and quick actions',
        allowedRoles: ['Admin', 'Telecaller', 'Sales', 'Super Admin'],
        functions: [
          SupportCatalogFunction(key: 'kpi_cards', name: 'KPI Summary Cards (Total Leads, Interested, Site Visits, Closed)'),
          SupportCatalogFunction(key: 'recent_activity', name: 'Recent Inquiries & Activity Feed'),
          SupportCatalogFunction(key: 'date_filter', name: 'Date Range & Role Filter'),
          SupportCatalogFunction(key: 'quick_actions', name: 'Quick Action Shortcuts (+ Plus Icon)'),
          SupportCatalogFunction(key: 'kpi_drilldown', name: 'KPI Drilldown Dialogs'),
        ],
      ),
      SupportCatalogPage(
        id: 'cat-2',
        pageKey: '/properties',
        pageName: 'Properties Inventory',
        category: 'Inventory',
        description: 'Complete real estate listings directory for sale and rent',
        allowedRoles: ['Admin', 'Telecaller', 'Sales', 'Super Admin'],
        functions: [
          SupportCatalogFunction(key: 'search_bar', name: 'Search & BHK / Price / Location Filters'),
          SupportCatalogFunction(key: 'property_cards', name: 'Property Cards & Grid/Table View'),
          SupportCatalogFunction(key: 'add_property', name: 'Add New Property Listing Form'),
          SupportCatalogFunction(key: 'edit_property', name: 'Edit / Update Property Details'),
          SupportCatalogFunction(key: 'share_property', name: 'Share Property (WhatsApp / PDF Link Generation)'),
          SupportCatalogFunction(key: 'matching_requirements', name: 'Matching Buyer Requirements Drawer'),
          SupportCatalogFunction(key: 'archive_property', name: 'Archive / Move to Bin'),
        ],
      ),
      SupportCatalogPage(
        id: 'cat-3',
        pageKey: '/requirements',
        pageName: 'Leads & Buyer Requirements',
        category: 'Leads Pipeline',
        description: 'Buyer & tenant inquiries pipeline and matchmaking table',
        allowedRoles: ['Admin', 'Telecaller', 'Sales', 'Super Admin'],
        functions: [
          SupportCatalogFunction(key: 'tabs_navigation', name: 'Category Tabs (All, Property Listings, Not Interested, Followups)'),
          SupportCatalogFunction(key: 'search_filter', name: 'Search & Status / Budget Filters'),
          SupportCatalogFunction(key: 'add_lead', name: 'Add New Lead / Requirement Form'),
          SupportCatalogFunction(key: 'change_status', name: 'Change Lead Status (Interested, Callback, Closed)'),
          SupportCatalogFunction(key: 'schedule_callback', name: 'Schedule Callback Date & Time'),
          SupportCatalogFunction(key: 'reassign_lead', name: 'Lead Re-assignment to Agent'),
          SupportCatalogFunction(key: 'export_data', name: 'Export Requirements Data to Excel/CSV'),
        ],
      ),
      SupportCatalogPage(
        id: 'cat-4',
        pageKey: '/telecaller/leads',
        pageName: 'Telecaller Calling Leads',
        category: 'Telecaller Desk',
        description: 'Allocated calling queue for signed-in Telecaller',
        allowedRoles: ['Telecaller', 'Admin', 'Super Admin'],
        functions: [
          SupportCatalogFunction(key: 'calling_queue', name: 'Allocated Calling Leads Table'),
          SupportCatalogFunction(key: 'record_outcome', name: 'Record Call Outcome (Interested, Callback, CNR, Wrong Lead)'),
          SupportCatalogFunction(key: 'disposition_sheet', name: 'Call Disposition Sheet & Remarks'),
          SupportCatalogFunction(key: 'transfer_lead', name: 'Transfer Lead to Salesperson / Peer'),
          SupportCatalogFunction(key: 'status_toggle', name: 'Telecaller Availability Toggle (Available / On Call / Break)'),
        ],
      ),
      SupportCatalogPage(
        id: 'cat-5',
        pageKey: '/telecaller/callbacks',
        pageName: 'Telecaller Callbacks & Reminders',
        category: 'Telecaller Desk',
        description: 'Scheduled callbacks and follow-up calendar desk',
        allowedRoles: ['Telecaller', 'Admin', 'Super Admin'],
        functions: [
          SupportCatalogFunction(key: 'callbacks_list', name: 'Scheduled Callbacks List'),
          SupportCatalogFunction(key: 'reschedule_time', name: 'Reschedule Callback Time'),
          SupportCatalogFunction(key: 'mark_complete', name: 'Mark Callback Completed'),
          SupportCatalogFunction(key: 'date_filters', name: 'Filter Callbacks by Date (Today, Missed, Upcoming)'),
        ],
      ),
      SupportCatalogPage(
        id: 'cat-6',
        pageKey: '/telecaller/cnr',
        pageName: 'Telecaller CNR / Retry Desk',
        category: 'Telecaller Desk',
        description: 'Queue for leads where calls could not be connected',
        allowedRoles: ['Telecaller', 'Admin', 'Super Admin'],
        functions: [
          SupportCatalogFunction(key: 'cnr_queue', name: 'CNR Leads List'),
          SupportCatalogFunction(key: 'retry_call', name: 'Retry Call Action & Log Outcome'),
          SupportCatalogFunction(key: 'move_not_interested', name: 'Move to Not Interested / Archive'),
        ],
      ),
      SupportCatalogPage(
        id: 'cat-7',
        pageKey: '/admin/lead-allocation',
        pageName: 'Lead Allocation Monitor',
        category: 'Admin & Operations',
        description: 'Live lead distribution monitor and telecaller shift tracker',
        allowedRoles: ['Admin', 'Super Admin'],
        functions: [
          SupportCatalogFunction(key: 'live_monitor_table', name: 'Live Telecaller Allocation Table'),
          SupportCatalogFunction(key: 'manual_reallocation', name: 'Manual Lead Re-allocation & Batch Transfer'),
          SupportCatalogFunction(key: 'attendance_tracker', name: 'Telecaller Shift & Attendance Tracker'),
          SupportCatalogFunction(key: 'distribution_rules', name: 'Lead Redistribution Rules & Capacity Gauge'),
        ],
      ),
      SupportCatalogPage(
        id: 'cat-8',
        pageKey: '/campaign/leads',
        pageName: 'Campaign & Webhook Ingestion',
        category: 'Integrations & Campaigns',
        description: 'Meta Ads and portal webhook ingestion inbox table',
        allowedRoles: ['Admin', 'Telecaller', 'Super Admin'],
        functions: [
          SupportCatalogFunction(key: 'webhook_inbox', name: 'Webhook Ingestion Inbox Table'),
          SupportCatalogFunction(key: 'bulk_assignment', name: 'Single & Bulk Lead Assignment'),
          SupportCatalogFunction(key: 'spreadsheet_upload', name: 'Spreadsheet / CSV File Upload & Field Mapping'),
          SupportCatalogFunction(key: 'deduplication', name: 'Lead Deduplication & Quality Filter'),
          SupportCatalogFunction(key: 'export_campaign_leads', name: 'Export Campaign Leads Data'),
        ],
      ),
      SupportCatalogPage(
        id: 'cat-9',
        pageKey: '/campaign/connections',
        pageName: 'Campaign Connections & API Integrations',
        category: 'Integrations & Campaigns',
        description: 'Meta Ads Page connection and Housing.com portal API setup',
        allowedRoles: ['Admin', 'Super Admin'],
        functions: [
          SupportCatalogFunction(key: 'meta_connection', name: 'Connect Meta Ads Page & Webhook Secret'),
          SupportCatalogFunction(key: 'housing_connector', name: 'Housing.com API Key & Connector Setup'),
          SupportCatalogFunction(key: 'integration_health', name: 'Integration Health Diagnostics & Logs'),
        ],
      ),
      SupportCatalogPage(
        id: 'cat-10',
        pageKey: '/users',
        pageName: 'Team & Staff Management',
        category: 'Administration',
        description: 'Employee roster, role permissions, and agent account management',
        allowedRoles: ['Admin', 'Super Admin'],
        functions: [
          SupportCatalogFunction(key: 'employee_table', name: 'Employee Directory List & Role Filters'),
          SupportCatalogFunction(key: 'create_user', name: 'Create New Employee Account'),
          SupportCatalogFunction(key: 'edit_user', name: 'Edit Profile, Role, & Shift Status'),
          SupportCatalogFunction(key: 'password_reset', name: 'Password Reset & Account Lockout Control'),
        ],
      ),
      SupportCatalogPage(
        id: 'cat-11',
        pageKey: '/reports',
        pageName: 'Reports & Analytics',
        category: 'Analytics',
        description: 'Business intelligence dashboard, telecaller reports, and sales leaderboard',
        allowedRoles: ['Admin', 'Super Admin'],
        functions: [
          SupportCatalogFunction(key: 'business_insight', name: 'Overall Business Intelligence Charts'),
          SupportCatalogFunction(key: 'telecaller_report', name: 'Telecaller Performance Metrics & Call Attempts'),
          SupportCatalogFunction(key: 'sales_report', name: 'Sales Leaderboard & Closed Deal Analytics'),
          SupportCatalogFunction(key: 'lead_metrics', name: 'Lead Source Metrics & Conversion Rate'),
          SupportCatalogFunction(key: 'export_reports', name: 'Export Comprehensive PDF / Excel Reports'),
        ],
      ),
      SupportCatalogPage(
        id: 'cat-12',
        pageKey: '/library',
        pageName: 'Document Library',
        category: 'Resources',
        description: 'Agreement templates, deed documents, and service provider contact directory',
        allowedRoles: ['Admin', 'Telecaller', 'Sales', 'Super Admin'],
        functions: [
          SupportCatalogFunction(key: 'rental_agreements', name: 'Rental Agreement Templates & Download'),
          SupportCatalogFunction(key: 'resale_agreements', name: 'Resale Deed & Contract Templates'),
          SupportCatalogFunction(key: 'service_agents', name: 'Service Agent Directory & Provider Contacts'),
        ],
      ),
      SupportCatalogPage(
        id: 'cat-13',
        pageKey: '/settings',
        pageName: 'Settings & Administration',
        category: 'System Settings',
        description: 'System audit logs, location mappings, and KPI rulebook config',
        allowedRoles: ['Admin', 'Super Admin'],
        functions: [
          SupportCatalogFunction(key: 'system_config', name: 'General System Settings'),
          SupportCatalogFunction(key: 'audit_logs', name: 'System Security Audit Logs (/settings/audit-logs)'),
          SupportCatalogFunction(key: 'location_config', name: 'Locality & Area Mapping Config'),
          SupportCatalogFunction(key: 'kpi_config', name: 'KPI Rulebook Engine Config'),
        ],
      ),
      SupportCatalogPage(
        id: 'cat-14',
        pageKey: '/messages',
        pageName: 'Team Messages & Messenger',
        category: 'Communication',
        description: 'Direct messaging and group discussions with team members',
        allowedRoles: ['Admin', 'Telecaller', 'Sales', 'Super Admin'],
        functions: [
          SupportCatalogFunction(key: 'chat_inbox', name: 'Team Conversations Inbox List'),
          SupportCatalogFunction(key: 'send_message', name: 'Send Message & Attachment'),
          SupportCatalogFunction(key: 'inspection_mode', name: 'Admin Inspection Mode'),
        ],
      ),
      SupportCatalogPage(
        id: 'cat-15',
        pageKey: '/profile',
        pageName: 'User Profile & Security',
        category: 'User Preferences',
        description: 'Personal profile, role badges, and security settings',
        allowedRoles: ['Admin', 'Telecaller', 'Sales', 'Super Admin'],
        functions: [
          SupportCatalogFunction(key: 'profile_info', name: 'View Account Info & Role Badges'),
          SupportCatalogFunction(key: 'change_password', name: 'Change Password Form'),
        ],
      ),
    ];
  }

  Widget _buildStep1PageSelection(bool isDark, Color primaryColor) {
    final selectedKey = _catalogPages.any((p) => p.pageKey == _selectedPage?.pageKey)
        ? _selectedPage?.pageKey
        : (_catalogPages.isNotEmpty ? _catalogPages.first.pageKey : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 1: Select Affected Page',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Select the specific page where you experienced an issue. Only pages authorized for your role are listed.',
          style: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedKey,
              isExpanded: true,
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              items: _catalogPages.map((page) {
                return DropdownMenuItem<String>(
                  value: page.pageKey,
                  child: Row(
                    children: [
                      Icon(Icons.article_outlined, size: 18, color: primaryColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          page.pageName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          page.category,
                          style: TextStyle(fontSize: 10, color: primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (key) {
                if (key == null) return;
                final match = _catalogPages.firstWhere(
                  (p) => p.pageKey == key,
                  orElse: () => _catalogPages.first,
                );
                _onPageChanged(match);
              },
            ),
          ),
        ),
        if (_selectedPage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: primaryColor, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedPage!.description.isNotEmpty
                        ? _selectedPage!.description
                        : 'Page Route: ${_selectedPage!.pageKey}',
                    style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),

        // Optional Screenshot & Image Upload (Moved to Step 1 of the form)
        _buildAttachmentSection(isDark, primaryColor),
      ],
    );
  }

  Widget _buildStep2FunctionSelection(bool isDark, Color primaryColor) {
    final functions = _selectedPage?.functions ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 2: Select Specific Function in "${_selectedPage?.pageName ?? 'Selected Page'}"',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose the exact button, tab, filter, form, or feature that failed or gave incorrect data.',
          style: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),
        if (functions.isEmpty)
          const Text('No specific subfunctions defined for this page.')
        else
          Column(
            children: functions.map((fn) {
              final isSelected = _selectedFunction?.key == fn.key;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor.withValues(alpha: 0.08)
                      : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? primaryColor
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: RadioListTile<SupportCatalogFunction>(
                  title: Text(
                    fn.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  value: fn,
                  groupValue: _selectedFunction,
                  activeColor: primaryColor,
                  onChanged: (val) {
                    setState(() => _selectedFunction = val);
                  },
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildStep3IssueTypeSelection(bool isDark, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 3: Select Issue Category',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Help us route your issue quickly by choosing the closest issue type.',
          style: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _issueTypes.map((type) {
            final isSelected = _issueType == type;
            return ChoiceChip(
              label: Text(type),
              selected: isSelected,
              selectedColor: primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              onSelected: (selected) {
                if (selected) setState(() => _issueType = type);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep4DescriptionAndAttachments(bool isDark, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 4: Priority & Detailed Description',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Describe the problem clearly. Mention any error message, unexpected count, or missing button.',
          style: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),

        // Priority Selection
        Row(
          children: [
            const Text('Priority Level:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(width: 14),
            Expanded(
              child: SegmentedButton<String>(
                segments: _priorities
                    .map((p) => ButtonSegment<String>(value: p, label: Text(p)))
                    .toList(),
                selected: {_priority},
                onSelectionChanged: (val) {
                  setState(() => _priority = val.first);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Description TextField
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: 'Provide detailed steps to reproduce the issue...',
            hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentSection(bool isDark, Color primaryColor) {
    return CRMImagePicker(
      imageUrls: _uploadedImages,
      onImageAdded: (url) {
        setState(() {
          _uploadedImages.add(url);
        });
      },
      onImageRemoved: (index) {
        setState(() {
          _uploadedImages.removeAt(index);
        });
      },
      onImageReplaced: (index, url) {
        setState(() {
          _uploadedImages[index] = url;
        });
      },
      onImagesReordered: (newUrls) {
        setState(() {
          _uploadedImages.clear();
          _uploadedImages.addAll(newUrls);
        });
      },
      maxImages: 3,
      uploadEndpoint: '/properties/upload-media',
    );
  }

  Widget _buildStep5SuccessConfirmation(bool isDark, Color primaryColor) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: CRMColors.success,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 16),
        const Text(
          'Support Ticket Created Successfully!',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Ticket ID: ${_submittedIssue?.ticketNumber ?? "SUP-1001"}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryColor),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Your issue has been logged and assigned for resolution. You can track updates and replies directly from your Support page.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
