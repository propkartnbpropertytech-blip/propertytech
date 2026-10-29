import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/api/dio_client.dart';

class BrokerManagementScreen extends StatefulWidget {
  const BrokerManagementScreen({super.key});

  @override
  State<BrokerManagementScreen> createState() => _BrokerManagementScreenState();
}

class _BrokerManagementScreenState extends State<BrokerManagementScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _organizations = [];
  List<dynamic> _plans = [];
  List<dynamic> _allControls = [];
  List<dynamic> _onboardRequests = [];
  List<dynamic> _supportContacts = [];
  int _selectedTabIndex = 0; // 0 = Workspaces, 1 = Website Requests, 2 = Support Hotlines
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orgsFuture = DioClient.dio.get('/subscriptions/organizations');
      final plansFuture = DioClient.dio.get('/subscriptions/plans').catchError((e) {
        debugPrint('Error loading plans: $e');
        return Response(requestOptions: RequestOptions(path: '/subscriptions/plans'), statusCode: 500);
      });
      final controlsFuture = DioClient.dio.get('/permissions/controls').catchError((e) {
        debugPrint('Error loading controls: $e');
        return Response(requestOptions: RequestOptions(path: '/permissions/controls'), statusCode: 500);
      });
      final requestsFuture = DioClient.dio.get('/subscriptions/requests').catchError((e) {
        debugPrint('Error loading onboarding requests: $e');
        return Response(requestOptions: RequestOptions(path: '/subscriptions/requests'), statusCode: 500);
      });
      final contactsFuture = DioClient.dio.get('/subscriptions/support-contacts').catchError((e) {
        debugPrint('Error loading support contacts: $e');
        return Response(requestOptions: RequestOptions(path: '/subscriptions/support-contacts'), statusCode: 500);
      });

      final results = await Future.wait([orgsFuture, plansFuture, controlsFuture, requestsFuture, contactsFuture]);

      final orgsRes = results[0];
      final plansRes = results[1];
      final controlsRes = results[2];
      final requestsRes = results[3];
      final contactsRes = results[4];

      setState(() {
        if (orgsRes.statusCode == 200 && orgsRes.data != null) {
          _organizations = orgsRes.data['data'] as List<dynamic>? ?? [];
        }
        if (plansRes.statusCode == 200 && plansRes.data != null) {
          _plans = plansRes.data['data'] as List<dynamic>? ?? [];
        }
        if (controlsRes.statusCode == 200 && controlsRes.data != null) {
          _allControls = controlsRes.data['data'] as List<dynamic>? ?? [];
        }
        if (requestsRes.statusCode == 200 && requestsRes.data != null) {
          _onboardRequests = requestsRes.data['data'] as List<dynamic>? ?? [];
        }
        if (contactsRes.statusCode == 200 && contactsRes.data != null) {
          _supportContacts = contactsRes.data['data'] as List<dynamic>? ?? [];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load broker workspaces: $e';
        _isLoading = false;
      });
    }
  }

  void _openOnboardWizard() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _BrokerOnboardWizardDialog(
        plans: _plans,
        allControls: _allControls,
        onSuccess: () {
          Navigator.of(ctx).pop();
          _loadData();
        },
      ),
    );
  }

  void _openSpecialAccessDialog(Map<String, dynamic> org) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _BrokerSpecialAccessDialog(
        organization: org,
        allControls: _allControls,
        onSaved: () {
          Navigator.of(ctx).pop();
          _loadData();
        },
      ),
    );
  }

  void _openChangePlanDialog(Map<String, dynamic> org) {
    showDialog(
      context: context,
      builder: (ctx) => _ChangePlanDialog(
        organization: org,
        plans: _plans,
        onSaved: () {
          Navigator.of(ctx).pop();
          _loadData();
        },
      ),
    );
  }

  void _openDeleteWorkspaceDialog(Map<String, dynamic> org) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DeleteBrokerWorkspaceDialog(
        organization: org,
        onDeleted: () {
          Navigator.of(ctx).pop();
          _loadData();
        },
      ),
    );
  }

  void _openResetPasswordDialog(Map<String, dynamic> org) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ResetBrokerPasswordDialog(
        organization: org,
        onSuccess: () {
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CRMColors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          _buildMetricsOverview(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorView()
                    : _selectedTabIndex == 0
                        ? _buildOrganizationsView()
                        : _selectedTabIndex == 1
                            ? _buildRequestsView()
                            : _buildSupportHotlinesView(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CRMSpacing.xl,
        vertical: CRMSpacing.l,
      ),
      decoration: BoxDecoration(
        color: CRMColors.cardBg,
        border: Border(bottom: BorderSide(color: CRMColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Broker Workspaces & Onboarding',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: CRMColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Provision fresh broker organizations with isolated data boundaries, assigned subscription plans, and custom special access.',
                  style: TextStyle(
                    fontSize: 13,
                    color: CRMColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: CRMSpacing.m),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Refresh'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: CRMColors.text,
                  side: BorderSide(color: CRMColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(width: CRMSpacing.m),
              ElevatedButton.icon(
                onPressed: _openOnboardWizard,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Onboard New Broker'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CRMColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final pendingCount = _onboardRequests.where((r) => r['status'] == 'PENDING').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.xl),
      decoration: BoxDecoration(
        color: CRMColors.cardBg,
        border: Border(bottom: BorderSide(color: CRMColors.border)),
      ),
      child: Row(
        children: [
          _buildTabButton(
            index: 0,
            title: 'Active Workspaces (${_organizations.length})',
            icon: Icons.business_rounded,
          ),
          const SizedBox(width: CRMSpacing.xl),
          _buildTabButton(
            index: 1,
            title: 'Website Inquiries / Requests (${_onboardRequests.length})',
            icon: Icons.language_rounded,
            badgeCount: pendingCount,
          ),
          const SizedBox(width: CRMSpacing.xl),
          _buildTabButton(
            index: 2,
            title: 'Support Hotlines & Numbers (${_supportContacts.length})',
            icon: Icons.headset_mic_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String title,
    required IconData icon,
    int? badgeCount,
  }) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? CRMColors.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? CRMColors.primary : CRMColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? CRMColors.primary : CRMColors.textSecondary,
              ),
            ),
            if (badgeCount != null && badgeCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber[700],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount PENDING',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsOverview() {
    if (_selectedTabIndex == 1) {
      final totalRequests = _onboardRequests.length;
      final pendingCount = _onboardRequests.where((r) => r['status'] == 'PENDING').length;
      final provisionedCount = _onboardRequests.where((r) => r['status'] == 'PROVISIONED').length;
      final deliveredEmails = _onboardRequests.where((r) => r['email_status'] == 'DELIVERED').length;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.xl, vertical: CRMSpacing.m),
        decoration: BoxDecoration(
          color: CRMColors.background,
          border: Border(bottom: BorderSide(color: CRMColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildMetricBadge('Total Requests', totalRequests.toString(), Icons.inbox_rounded, Colors.blue),
                    const SizedBox(width: CRMSpacing.m),
                    _buildMetricBadge('Pending Review', pendingCount.toString(), Icons.hourglass_top_rounded, Colors.amber),
                    const SizedBox(width: CRMSpacing.m),
                    _buildMetricBadge('Provisioned', provisionedCount.toString(), Icons.check_circle_rounded, Colors.green),
                    const SizedBox(width: CRMSpacing.m),
                    _buildMetricBadge('Ack Emails Delivered', deliveredEmails.toString(), Icons.mark_email_read_rounded, Colors.teal),
                  ],
                ),
              ),
            ),
            const SizedBox(width: CRMSpacing.m),
            SizedBox(
              width: 280,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search requests by broker, city, email...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedTabIndex == 2) {
      final totalHotlines = _supportContacts.length;
      final activeHotlines = _supportContacts.where((c) => c['is_active'] == true).length;
      final primaryContact = _supportContacts.firstWhere(
        (c) => c['is_primary'] == true,
        orElse: () => _supportContacts.isNotEmpty ? _supportContacts.first : null,
      );
      final primaryDisplay = primaryContact != null ? primaryContact['display_number']?.toString() ?? 'None' : 'None';

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.xl, vertical: CRMSpacing.m),
        decoration: BoxDecoration(
          color: CRMColors.background,
          border: Border(bottom: BorderSide(color: CRMColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildMetricBadge('Total Hotlines', totalHotlines.toString(), Icons.phone_in_talk_rounded, Colors.blue),
                    const SizedBox(width: CRMSpacing.m),
                    _buildMetricBadge('Active on Website', activeHotlines.toString(), Icons.check_circle_rounded, Colors.green),
                    const SizedBox(width: CRMSpacing.m),
                    _buildMetricBadge('Primary Number', primaryDisplay, Icons.star_rounded, Colors.amber),
                  ],
                ),
              ),
            ),
            const SizedBox(width: CRMSpacing.m),
            ElevatedButton.icon(
              onPressed: _openAddSupportContactDialog,
              icon: const Icon(Icons.add_call, size: 18),
              label: const Text('Add Support Hotline'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CRMColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }


    final totalBrokers = _organizations.length;
    final activeBrokers = _organizations.where((o) => o['is_active'] == true).length;
    final totalInventory = _organizations.fold<int>(0, (sum, o) => sum + (o['property_count'] as int? ?? 0));
    final totalLeads = _organizations.fold<int>(0, (sum, o) => sum + (o['lead_count'] as int? ?? 0));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.xl, vertical: CRMSpacing.m),
      decoration: BoxDecoration(
        color: CRMColors.background,
        border: Border(bottom: BorderSide(color: CRMColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildMetricBadge('Total Workspaces', totalBrokers.toString(), Icons.domain_rounded, Colors.blue),
                  const SizedBox(width: CRMSpacing.m),
                  _buildMetricBadge('Active Subscriptions', activeBrokers.toString(), Icons.verified_rounded, Colors.green),
                  const SizedBox(width: CRMSpacing.m),
                  _buildMetricBadge('Isolated Inventory', totalInventory.toString(), Icons.apartment_rounded, Colors.orange),
                  const SizedBox(width: CRMSpacing.m),
                  _buildMetricBadge('Isolated Leads', totalLeads.toString(), Icons.people_alt_rounded, Colors.purple),
                ],
              ),
            ),
          ),
          const SizedBox(width: CRMSpacing.m),
          SizedBox(
            width: 280,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search organization, email, name...',
                prefixIcon: const Icon(Icons.search, size: 18),
                border: const OutlineInputBorder(),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBadge(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: CRMColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CRMColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: CRMColors.textSecondary)),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: CRMColors.text)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red[400], size: 48),
          const SizedBox(height: CRMSpacing.m),
          Text(
            _errorMessage ?? 'An error occurred',
            style: TextStyle(color: CRMColors.text),
          ),
          const SizedBox(height: CRMSpacing.m),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizationsView() {
    final filtered = _organizations.where((org) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final orgName = (org['organization_name'] ?? '').toString().toLowerCase();
      final ownerName = (org['owner_name'] ?? '').toString().toLowerCase();
      final ownerEmail = (org['owner_email'] ?? '').toString().toLowerCase();
      return orgName.contains(query) || ownerName.contains(query) || ownerEmail.contains(query);
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.domain_disabled_rounded, size: 64, color: CRMColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No Broker Workspaces Found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CRMColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Click "+ Onboard New Broker" to provision a clean workspace for a broker.',
              style: TextStyle(color: CRMColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(CRMSpacing.xl),
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: CRMSpacing.m),
      itemBuilder: (context, index) {
        final org = filtered[index] as Map<String, dynamic>;
        return _buildOrganizationCard(org);
      },
    );
  }

  Widget _buildRequestsView() {
    final primaryContact = _supportContacts.firstWhere(
      (c) => c['is_primary'] == true,
      orElse: () => _supportContacts.isNotEmpty ? _supportContacts.first : null,
    );

    final filtered = _onboardRequests.where((req) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final fullName = (req['full_name'] ?? '').toString().toLowerCase();
      final brokerageName = (req['brokerage_name'] ?? '').toString().toLowerCase();
      final email = (req['email'] ?? '').toString().toLowerCase();
      final city = (req['city'] ?? '').toString().toLowerCase();
      final id = (req['id'] ?? '').toString().toLowerCase();
      return fullName.contains(q) || brokerageName.contains(q) || email.contains(q) || city.contains(q) || id.contains(q);
    }).toList();

    return Column(
      children: [
        if (primaryContact != null)
          Container(
            margin: const EdgeInsets.fromLTRB(CRMSpacing.xl, CRMSpacing.m, CRMSpacing.xl, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: CRMColors.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: CRMColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (primaryContact['is_active'] == true ? Colors.green : Colors.grey).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.headset_mic_rounded,
                    color: primaryContact['is_active'] == true ? Colors.green[700] : Colors.grey[600],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Website Support Helpline: ${primaryContact['display_number'] ?? primaryContact['phone_number']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (primaryContact['is_active'] == true ? Colors.green : Colors.grey).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              primaryContact['is_active'] == true ? 'LIVE ON SITE' : 'DISABLED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: primaryContact['is_active'] == true ? Colors.green[800] : Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Category: ${primaryContact['category']} • Hours: ${primaryContact['operating_hours']}',
                        style: TextStyle(fontSize: 11, color: CRMColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      primaryContact['is_active'] == true ? 'Active' : 'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: primaryContact['is_active'] == true ? Colors.green[700] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Switch.adaptive(
                      value: primaryContact['is_active'] == true,
                      activeTrackColor: Colors.green[600],
                      onChanged: (val) => _toggleSupportContactActive(primaryContact['id'].toString(), primaryContact['is_active'] == true),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => setState(() => _selectedTabIndex = 2),
                  icon: const Icon(Icons.tune_rounded, size: 16),
                  label: const Text('Manage Hotlines'),
                ),
              ],
            ),
          ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox_rounded, size: 64, color: CRMColors.textSecondary),
                      const SizedBox(height: 16),
                      Text(
                        'No Onboarding Inquiries Found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: CRMColors.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Brokers submitting requests from nbpropertytech.com will appear here for review and provisioning.',
                        style: TextStyle(color: CRMColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(CRMSpacing.xl),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: CRMSpacing.m),
                  itemBuilder: (context, index) {
                    final req = filtered[index] as Map<String, dynamic>;
                    return _buildRequestCard(req);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final id = (req['id'] ?? '').toString();
    final ref = id.length >= 8 ? id.substring(0, 8).toUpperCase() : id;
    final fullName = req['full_name'] ?? req['admin_name'] ?? 'Prospective Broker';
    final brokerageName = req['brokerage_name'] ?? req['organization_name'] ?? 'Unnamed Agency';
    final email = req['email'] ?? req['admin_email'] ?? '—';
    final mobile = req['mobile'] ?? req['admin_phone'] ?? '—';
    final city = req['city'] ?? '—';
    final planName = req['plan_name'] ?? req['selected_plan_name'] ?? 'Standard Tier';
    final price = req['price'] != null ? '₹${req['price']}/mo' : '';
    final status = (req['status'] ?? 'PENDING').toString().toUpperCase();
    final emailStatus = (req['email_status'] ?? 'QUEUED').toString().toUpperCase();
    final notes = req['notes'];
    final createdAt = req['created_at']?.toString().split('T')[0] ?? '';

    final isPending = status == 'PENDING';
    final isProvisioned = status == 'PROVISIONED';

    return Container(
      padding: const EdgeInsets.all(CRMSpacing.l),
      decoration: BoxDecoration(
        color: CRMColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPending ? Colors.amber.withValues(alpha: 0.5) : CRMColors.border,
          width: isPending ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPending ? Colors.amber.withValues(alpha: 0.12) : Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isProvisioned ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                  color: isPending ? Colors.amber[800] : Colors.green[700],
                  size: 26,
                ),
              ),
              const SizedBox(width: CRMSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            brokerageName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: CRMColors.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isPending ? Colors.amber.withValues(alpha: 0.15) : Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isPending ? Colors.amber[900] : Colors.green[800],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'REF: $ref',
                            style: TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                              color: CRMColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Applicant: $fullName • City: $city • Received: $createdAt',
                      style: TextStyle(fontSize: 12, color: CRMColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: CRMSpacing.m),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: emailStatus == 'DELIVERED' ? Colors.teal.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: emailStatus == 'DELIVERED' ? Colors.teal.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      emailStatus == 'DELIVERED' ? Icons.mark_email_read_rounded : Icons.mail_outline_rounded,
                      size: 14,
                      color: emailStatus == 'DELIVERED' ? Colors.teal[700] : Colors.grey[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      emailStatus == 'DELIVERED' ? 'Ack Sent' : emailStatus,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: emailStatus == 'DELIVERED' ? Colors.teal[800] : Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: CRMSpacing.m),
              if (isPending)
                ElevatedButton.icon(
                  onPressed: () => _openProvisionRequestDialog(req),
                  icon: const Icon(Icons.bolt_rounded, size: 16),
                  label: const Text('Approve & Provision'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CRMColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.check_rounded, size: 16, color: Colors.green),
                  label: const Text('Provisioned'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green[800],
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              const SizedBox(width: CRMSpacing.s),
              OutlinedButton.icon(
                onPressed: () => _confirmDeleteRequestDialog(req),
                icon: Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red[600]),
                label: Text('Delete', style: TextStyle(color: Colors.red[600])),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.m),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: CRMColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CRMColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.email_outlined, size: 14, color: CRMColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(email, style: TextStyle(fontSize: 12, color: CRMColors.text)),
                      const SizedBox(width: 16),
                      Icon(Icons.phone_outlined, size: 14, color: CRMColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(mobile, style: TextStyle(fontSize: 12, color: CRMColors.text)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: CRMColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Plan: $planName $price',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: CRMColors.primary),
                  ),
                ),
              ],
            ),
          ),
          if (notes != null && notes.toString().trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
              ),
              child: Text(
                'Notes: $notes',
                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.amber[900]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openProvisionRequestDialog(Map<String, dynamic> req) {
    final requestId = req['id'];
    final brokerageName = req['brokerage_name'] ?? 'Brokerage';
    final fullName = req['full_name'] ?? 'Broker';
    final email = req['email'] ?? '';
    final defaultPlanId = req['plan_id'] ?? (_plans.isNotEmpty ? _plans[0]['id'] : null);

    String? selectedPlanId = defaultPlanId?.toString();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: CRMColors.cardBg,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CRMColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.domain_verification_rounded, color: CRMColors.primary, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Text('Approve & Provision Workspace', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This will create a fresh, pristine 0-data workspace for this broker and automatically dispatch their welcome credentials dossier from broker-support@nbpropertytech.com.',
                      style: TextStyle(fontSize: 13, color: CRMColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CRMColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: CRMColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Brokerage: $brokerageName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('Lead Admin: $fullName ($email)', style: TextStyle(fontSize: 12, color: CRMColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text('City: ${req['city'] ?? '—'} • Phone: ${req['mobile'] ?? '—'}', style: TextStyle(fontSize: 12, color: CRMColors.textSecondary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Assign Subscription Plan:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedPlanId,
                      items: _plans.map<DropdownMenuItem<String>>((p) {
                        return DropdownMenuItem<String>(
                          value: p['id'].toString(),
                          child: Text('${p['name']} (₹${p['price']}/mo)'),
                        );
                      }).toList(),
                      onChanged: (val) => setDialogState(() => selectedPlanId = val),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);
                          try {
                            await DioClient.dio.post(
                              '/subscriptions/requests/$requestId/provision',
                              data: {
                                'planId': selectedPlanId,
                              },
                            );

                            if (ctx.mounted) {
                              Navigator.of(ctx).pop();
                            }

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Workspace provisioned for $brokerageName! Welcome email dispatched to $email.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _loadData();
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to provision: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CRMColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Confirm & Provision Workspace'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteRequestDialog(Map<String, dynamic> req) {
    final requestId = req['id'];
    final brokerageName = req['brokerage_name'] ?? 'Brokerage';
    final fullName = req['full_name'] ?? 'Broker';
    final email = req['email'] ?? '';
    final id = (req['id'] ?? '').toString();
    final ref = id.length >= 8 ? id.substring(0, 8).toUpperCase() : id;
    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: CRMColors.cardBg,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.warning_amber_rounded, color: Colors.red[600], size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text('Delete Onboarding Request?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Warning: This action cannot be undone. You are about to permanently delete this prospective broker inquiry from the system.',
                      style: TextStyle(fontSize: 13, color: Colors.red[700], fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CRMColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: CRMColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Brokerage: $brokerageName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('Applicant: $fullName ($email)', style: TextStyle(fontSize: 12, color: CRMColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text('Reference ID: $ref', style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: CRMColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setDialogState(() => isDeleting = true);
                          try {
                            await DioClient.dio.delete('/subscriptions/requests/$requestId');

                            if (ctx.mounted) {
                              Navigator.of(ctx).pop();
                            }

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Onboarding request for $brokerageName was permanently deleted.'),
                                  backgroundColor: Colors.red[700],
                                ),
                              );
                              _loadData();
                            }
                          } catch (e) {
                            setDialogState(() => isDeleting = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to delete request: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  icon: isDeleting
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.delete_forever_rounded, size: 16),
                  label: const Text('Delete Permanently'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSupportHotlinesView() {
    if (_supportContacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.phone_disabled_rounded, size: 64, color: CRMColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No Support Hotlines Configured',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CRMColors.text),
            ),
            const SizedBox(height: 8),
            Text(
              'Add dynamic phone numbers to display on nbpropertytech.com for prospective brokers.',
              style: TextStyle(color: CRMColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _openAddSupportContactDialog,
              icon: const Icon(Icons.add_call, size: 18),
              label: const Text('Add Support Hotline'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CRMColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(CRMSpacing.xl),
      itemCount: _supportContacts.length,
      separatorBuilder: (context, index) => const SizedBox(height: CRMSpacing.m),
      itemBuilder: (context, index) {
        final contact = _supportContacts[index] as Map<String, dynamic>;
        return _buildSupportContactCard(contact);
      },
    );
  }

  Widget _buildSupportContactCard(Map<String, dynamic> contact) {
    final id = (contact['id'] ?? '').toString();
    final label = contact['label'] ?? 'Support Hotline';
    final phoneNumber = contact['phone_number'] ?? '';
    final displayNumber = contact['display_number'] ?? phoneNumber;
    final category = (contact['category'] ?? 'GENERAL').toString().toUpperCase();
    final operatingHours = contact['operating_hours'] ?? 'Standard Operating Hours';
    final isActive = contact['is_active'] == true;
    final isPrimary = contact['is_primary'] == true;
    final notes = contact['notes'];

    return Container(
      padding: const EdgeInsets.all(CRMSpacing.l),
      decoration: BoxDecoration(
        color: CRMColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPrimary ? Colors.amber.withValues(alpha: 0.8) : CRMColors.border,
          width: isPrimary ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isActive
                      ? (isPrimary ? Colors.amber.withValues(alpha: 0.15) : CRMColors.primary.withValues(alpha: 0.1))
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPrimary ? Icons.star_rounded : Icons.headset_mic_rounded,
                  color: isActive ? (isPrimary ? Colors.amber[800] : CRMColors.primary) : Colors.grey,
                  size: 26,
                ),
              ),
              const SizedBox(width: CRMSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: CRMColors.text,
                          ),
                        ),
                        if (isPrimary) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded, size: 12, color: Colors.amber[800]),
                                const SizedBox(width: 4),
                                Text(
                                  'PRIMARY NUMBER ON WEBSITE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.amber[900],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          displayNumber,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: CRMColors.text,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: CRMColors.background,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: CRMColors.border),
                          ),
                          child: Text(
                            'Dial: $phoneNumber',
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: CRMColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: CRMSpacing.m),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isActive ? 'LIVE ON SITE' : 'DISABLED',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isActive ? Colors.green[700] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isActive ? 'Visible to brokers' : 'Hidden from site',
                        style: TextStyle(fontSize: 10, color: CRMColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Switch.adaptive(
                    value: isActive,
                    activeTrackColor: Colors.green[600],
                    onChanged: (val) => _toggleSupportContactActive(id, isActive),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.m),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: CRMColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CRMColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue[800]),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.schedule_rounded, size: 14, color: CRMColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        operatingHours,
                        style: TextStyle(fontSize: 12, color: CRMColors.textSecondary),
                      ),
                      if (notes != null && notes.toString().isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.info_outline_rounded, size: 14, color: CRMColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            notes.toString(),
                            style: TextStyle(fontSize: 12, color: CRMColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: CRMSpacing.m),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isPrimary)
                      OutlinedButton.icon(
                        onPressed: () => _setSupportContactPrimary(id),
                        icon: const Icon(Icons.star_border_rounded, size: 15),
                        label: const Text('Set as Primary'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.amber[900],
                          side: BorderSide(color: Colors.amber.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    const SizedBox(width: CRMSpacing.s),
                    OutlinedButton.icon(
                      onPressed: () => _openEditSupportContactDialog(contact),
                      icon: const Icon(Icons.edit_rounded, size: 15),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CRMColors.text,
                        side: BorderSide(color: CRMColors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: CRMSpacing.s),
                    OutlinedButton.icon(
                      onPressed: () => _confirmDeleteSupportContactDialog(contact),
                      icon: Icon(Icons.delete_outline_rounded, size: 15, color: Colors.red[600]),
                      label: Text('Delete', style: TextStyle(color: Colors.red[600])),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSupportContactActive(String id, bool currentActive) async {
    try {
      final newStatus = !currentActive;
      await DioClient.dio.put('/subscriptions/support-contacts/$id', data: {
        'is_active': newStatus,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus ? 'Support hotline is now LIVE on nbpropertytech.com' : 'Support hotline is now DISABLED.'),
            backgroundColor: newStatus ? Colors.green : Colors.grey[800],
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update hotline status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _setSupportContactPrimary(String id) async {
    try {
      await DioClient.dio.put('/subscriptions/support-contacts/$id', data: {
        'is_primary': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Primary support hotline set for nbpropertytech.com!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set primary hotline: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openAddSupportContactDialog() {
    final labelCtrl = TextEditingController(text: 'Broker Support & Onboarding Desk');
    final phoneCtrl = TextEditingController(text: '+919876543210');
    final displayCtrl = TextEditingController(text: '+91 98765 43210');
    final hoursCtrl = TextEditingController(text: 'Mon - Sat, 9:00 AM - 8:00 PM IST');
    final notesCtrl = TextEditingController();
    String category = 'ONBOARDING';
    bool isActive = true;
    bool isPrimary = _supportContacts.isEmpty;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: CRMColors.cardBg,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CRMColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.add_call, color: CRMColors.primary, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Text('Add Support Hotline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This contact number will be dynamically fetched and displayed on nbpropertytech.com without requiring any code deployment.',
                        style: TextStyle(fontSize: 13, color: CRMColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: labelCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Hotline Label *',
                          hintText: 'e.g. Broker Onboarding Desk',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: phoneCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Dial Number (E.164) *',
                                hintText: '+919876543210',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (val) {
                                if (displayCtrl.text.isEmpty || displayCtrl.text == phoneCtrl.text) {
                                  displayCtrl.text = val;
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: displayCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Formatted Display *',
                                hintText: '+91 98765 43210',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: category,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: const [
                                DropdownMenuItem(value: 'ONBOARDING', child: Text('Onboarding Desk')),
                                DropdownMenuItem(value: 'SALES', child: Text('Sales Hotline')),
                                DropdownMenuItem(value: 'GENERAL', child: Text('General Support')),
                                DropdownMenuItem(value: 'TECHNICAL', child: Text('Technical Help')),
                                DropdownMenuItem(value: 'WHATSAPP', child: Text('WhatsApp Desk')),
                              ],
                              onChanged: (v) {
                                if (v != null) setDialogState(() => category = v);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: hoursCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Operating Hours',
                                hintText: 'Mon - Sat, 9:00 AM - 8:00 PM IST',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Internal Notes (Optional)',
                          hintText: 'e.g. Routed to direct support executive mobile',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Live on Website', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              subtitle: const Text('Brokers will see this number immediately', style: TextStyle(fontSize: 11)),
                              value: isActive,
                              activeTrackColor: Colors.green[600],
                              onChanged: (v) => setDialogState(() => isActive = v),
                            ),
                          ),
                          Expanded(
                            child: SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Set as Primary', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              subtitle: const Text('Show in top header navigation & hero', style: TextStyle(fontSize: 11)),
                              value: isPrimary,
                              activeTrackColor: Colors.amber[700],
                              onChanged: (v) => setDialogState(() => isPrimary = v),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (labelCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill all required fields.')),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);
                          try {
                            await DioClient.dio.post(
                              '/subscriptions/support-contacts',
                              data: {
                                'label': labelCtrl.text.trim(),
                                'phoneNumber': phoneCtrl.text.trim(),
                                'displayNumber': displayCtrl.text.trim().isNotEmpty ? displayCtrl.text.trim() : phoneCtrl.text.trim(),
                                'category': category,
                                'operatingHours': hoursCtrl.text.trim(),
                                'isActive': isActive,
                                'isPrimary': isPrimary,
                                'notes': notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                              },
                            );

                            if (ctx.mounted) Navigator.of(ctx).pop();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Support hotline created successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _loadData();
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to create hotline: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CRMColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Create Hotline'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openEditSupportContactDialog(Map<String, dynamic> contact) {
    final id = (contact['id'] ?? '').toString();
    final labelCtrl = TextEditingController(text: contact['label'] ?? '');
    final phoneCtrl = TextEditingController(text: contact['phone_number'] ?? '');
    final displayCtrl = TextEditingController(text: contact['display_number'] ?? '');
    final hoursCtrl = TextEditingController(text: contact['operating_hours'] ?? '');
    final notesCtrl = TextEditingController(text: contact['notes'] ?? '');
    String category = (contact['category'] ?? 'ONBOARDING').toString().toUpperCase();
    bool isActive = contact['is_active'] == true;
    bool isPrimary = contact['is_primary'] == true;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: CRMColors.cardBg,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CRMColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.edit_rounded, color: CRMColors.primary, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Text('Edit Support Hotline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Updates here are reflected instantly on nbpropertytech.com in real time.',
                        style: TextStyle(fontSize: 13, color: CRMColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: labelCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Hotline Label *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: phoneCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Dial Number (E.164) *',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: displayCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Formatted Display *',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: ['ONBOARDING', 'SALES', 'GENERAL', 'TECHNICAL', 'WHATSAPP'].contains(category) ? category : 'GENERAL',
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: const [
                                DropdownMenuItem(value: 'ONBOARDING', child: Text('Onboarding Desk')),
                                DropdownMenuItem(value: 'SALES', child: Text('Sales Hotline')),
                                DropdownMenuItem(value: 'GENERAL', child: Text('General Support')),
                                DropdownMenuItem(value: 'TECHNICAL', child: Text('Technical Help')),
                                DropdownMenuItem(value: 'WHATSAPP', child: Text('WhatsApp Desk')),
                              ],
                              onChanged: (v) {
                                if (v != null) setDialogState(() => category = v);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: hoursCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Operating Hours',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Internal Notes',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Live on Website', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              value: isActive,
                              activeTrackColor: Colors.green[600],
                              onChanged: (v) => setDialogState(() => isActive = v),
                            ),
                          ),
                          Expanded(
                            child: SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Set as Primary', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              value: isPrimary,
                              activeTrackColor: Colors.amber[700],
                              onChanged: (v) => setDialogState(() => isPrimary = v),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (labelCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill all required fields.')),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);
                          try {
                            await DioClient.dio.put(
                              '/subscriptions/support-contacts/$id',
                              data: {
                                'label': labelCtrl.text.trim(),
                                'phoneNumber': phoneCtrl.text.trim(),
                                'displayNumber': displayCtrl.text.trim().isNotEmpty ? displayCtrl.text.trim() : phoneCtrl.text.trim(),
                                'category': category,
                                'operatingHours': hoursCtrl.text.trim(),
                                'isActive': isActive,
                                'isPrimary': isPrimary,
                                'notes': notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                              },
                            );

                            if (ctx.mounted) Navigator.of(ctx).pop();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Support hotline updated successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _loadData();
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to update hotline: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CRMColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteSupportContactDialog(Map<String, dynamic> contact) {
    final id = contact['id'];
    final label = contact['label'] ?? 'Hotline';
    final displayNumber = contact['display_number'] ?? contact['phone_number'] ?? '';
    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: CRMColors.cardBg,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.warning_amber_rounded, color: Colors.red[600], size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text('Delete Support Hotline?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Are you sure you want to delete this support number? It will be immediately removed from the platform and website.',
                      style: TextStyle(fontSize: 13, color: Colors.red[700], fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CRMColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: CRMColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hotline: $label', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('Number: $displayNumber', style: TextStyle(fontSize: 12, color: CRMColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setDialogState(() => isDeleting = true);
                          try {
                            await DioClient.dio.delete('/subscriptions/support-contacts/$id');

                            if (ctx.mounted) Navigator.of(ctx).pop();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Hotline "$label" was deleted.'),
                                  backgroundColor: Colors.red[700],
                                ),
                              );
                              _loadData();
                            }
                          } catch (e) {
                            setDialogState(() => isDeleting = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to delete hotline: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                  icon: isDeleting
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.delete_forever_rounded, size: 16),
                  label: const Text('Delete Hotline'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildOrganizationCard(Map<String, dynamic> org) {
    final orgName = org['organization_name'] ?? 'Unnamed Workspace';
    final ownerName = org['owner_name'] ?? 'No Owner Linked';
    final ownerEmail = org['owner_email'] ?? '—';
    final ownerMobile = org['owner_mobile'] ?? '—';
    final planName = org['plan_name'] ?? 'Custom / Unassigned';
    final isActive = org['is_active'] == true;
    final userCount = org['user_count'] ?? 0;
    final propertyCount = org['property_count'] ?? 0;
    final leadCount = org['lead_count'] ?? 0;
    final extraProvisionsCount = org['extra_provisions_count'] ?? 0;
    final orgId = (org['organization_id'] ?? '').toString();
    final isRootOrg = orgId == 'c88ed9f1-5261-4e5f-8a34-e9fade752c70' || 
                      orgName.toString().toLowerCase().trim() == 'nb prop tech' ||
                      orgName.toString().toLowerCase().trim() == 'local dev org';

    Color planColor = CRMColors.primary;
    if (planName.toString().toLowerCase().contains('silver')) planColor = const Color(0xFF94A3B8);
    if (planName.toString().toLowerCase().contains('gold')) planColor = const Color(0xFFF59E0B);
    if (planName.toString().toLowerCase().contains('platinum')) planColor = const Color(0xFF6366F1);

    return Container(
      padding: const EdgeInsets.all(CRMSpacing.l),
      decoration: BoxDecoration(
        color: CRMColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CRMColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Organization Icon & Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CRMColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.business_rounded, color: CRMColors.primary, size: 28),
          ),
          const SizedBox(width: CRMSpacing.l),

          // Workspace & Owner details
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        orgName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: CRMColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isActive ? 'ACTIVE' : 'INACTIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isActive ? Colors.green[700] : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_outline_rounded, size: 14, color: CRMColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          ownerName,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: CRMColors.text),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.email_outlined, size: 14, color: CRMColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          ownerEmail,
                          style: TextStyle(fontSize: 12, color: CRMColors.textSecondary),
                        ),
                      ],
                    ),
                    if (ownerMobile != '—')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone_outlined, size: 14, color: CRMColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            ownerMobile,
                            style: TextStyle(fontSize: 12, color: CRMColors.textSecondary),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Plan Badge
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: planColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: planColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium_rounded, size: 14, color: planColor),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          planName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: planColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                if (extraProvisionsCount > 0)
                  Text(
                    '+ $extraProvisionsCount Special Provisions Granted',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple[600],
                    ),
                  )
                else
                  Text(
                    'Standard Plan Entitlements',
                    style: TextStyle(fontSize: 11, color: CRMColors.textSecondary),
                  ),
              ],
            ),
          ),

          // Data Isolation Metric Badges
          Expanded(
            flex: 2,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  _buildDataIsolationPill('Users', userCount.toString(), Icons.people_outline),
                  const SizedBox(width: 8),
                  _buildDataIsolationPill('Props', propertyCount.toString(), Icons.apartment_outlined),
                  const SizedBox(width: 8),
                  _buildDataIsolationPill('Leads', leadCount.toString(), Icons.filter_alt_outlined),
                ],
              ),
            ),
          ),

          // Actions
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => _openSpecialAccessDialog(org),
                icon: const Icon(Icons.verified_user_outlined, size: 14),
                label: const Text('Special Access'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.deepPurple,
                  side: const BorderSide(color: Colors.deepPurple),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              OutlinedButton(
                onPressed: () => _openChangePlanDialog(org),
                style: OutlinedButton.styleFrom(
                  foregroundColor: CRMColors.text,
                  side: BorderSide(color: CRMColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: const Text('Change Plan'),
              ),
              OutlinedButton.icon(
                onPressed: () => _openResetPasswordDialog(org),
                icon: const Icon(Icons.lock_reset_rounded, size: 14),
                label: const Text('Reset Pass'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: CRMColors.textSecondary,
                  side: BorderSide(color: CRMColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                  textStyle: const TextStyle(fontSize: 11),
                ),
              ),
              if (!isRootOrg)
                OutlinedButton.icon(
                  onPressed: () => _openDeleteWorkspaceDialog(org),
                  icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.red),
                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataIsolationPill(String label, String count, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CRMColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: CRMColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: CRMColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            '$count $label',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: CRMColors.text),
          ),
        ],
      ),
    );
  }
}

class _BrokerOnboardWizardDialog extends StatefulWidget {
  final List<dynamic> plans;
  final List<dynamic> allControls;
  final VoidCallback onSuccess;

  const _BrokerOnboardWizardDialog({
    required this.plans,
    required this.allControls,
    required this.onSuccess,
  });

  @override
  State<_BrokerOnboardWizardDialog> createState() => _BrokerOnboardWizardDialogState();
}

class _BrokerOnboardWizardDialogState extends State<_BrokerOnboardWizardDialog> {
  final _formKey = GlobalKey<FormState>();
  final _orgNameController = TextEditingController();
  final _brokerNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController(text: 'PropKart@2026');
  final _notesController = TextEditingController();

  String? _selectedPlanId;
  final Map<String, bool> _extraProvisionsMap = {};
  bool _isProvisioning = false;
  String _controlsFilter = '';
  bool _obscurePassword = false;

  @override
  void initState() {
    super.initState();
    if (widget.plans.isNotEmpty) {
      _selectedPlanId = widget.plans[0]['id'];
    }
  }

  @override
  void dispose() {
    _orgNameController.dispose();
    _brokerNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleProvision() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProvisioning = true);

    final orgName = _orgNameController.text.trim();
    final brokerName = _brokerNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim().isNotEmpty
        ? _passwordController.text.trim()
        : 'PropKart@2026';

    try {
      final payload = {
        'organizationName': orgName,
        'brokerName': brokerName,
        'email': email,
        'mobile': _mobileController.text.trim(),
        'password': password,
        'planId': _selectedPlanId,
        'extraProvisionsMap': _extraProvisionsMap,
        'notes': _notesController.text.trim(),
      };

      final res = await DioClient.dio.post('/subscriptions/onboard', data: payload);

      if (res.statusCode == 201) {
        if (mounted) {
          _showCredentialsDialog(context, orgName, brokerName, email, password);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Onboarding failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isProvisioning = false);
    }
  }

  void _showCredentialsDialog(
    BuildContext context,
    String orgName,
    String brokerName,
    String email,
    String password,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
            const SizedBox(width: 10),
            const Text('Workspace Provisioned!'),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Broker workspace "$orgName" has been created. Save and provide these credentials to the broker administrator to log in:',
                style: TextStyle(fontSize: 13, color: CRMColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: CRMColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: CRMColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text('Broker: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Expanded(child: SelectableText(brokerName, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Login Email: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Expanded(child: SelectableText(email, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Password: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Expanded(
                          child: SelectableText(
                            password,
                            style: const TextStyle(fontSize: 13, color: Colors.deepPurple, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy Credentials'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: 'Broker: $brokerName\nEmail: $email\nPassword: $password'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Credentials copied to clipboard!'), backgroundColor: Colors.green),
              );
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: CRMColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onSuccess();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: CRMColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 880,
        height: 720,
        padding: const EdgeInsets.all(CRMSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: CRMColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.rocket_launch_rounded, color: CRMColors.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '1-Click Broker Workspace Onboarding',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: CRMColors.text,
                                ),
                              ),
                              Text(
                                'Creates fresh tenant workspace starting at 0 data with assigned plan & custom provisions.',
                                style: TextStyle(fontSize: 12, color: CRMColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: CRMSpacing.m),
              Divider(color: CRMColors.border),
              const SizedBox(height: CRMSpacing.m),

              // Form Body
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: Firm, Broker Info & Plan Selection
                    SizedBox(
                      width: 360,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Broker Workspace Profile',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: CRMColors.text,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _orgNameController,
                              decoration: const InputDecoration(
                                labelText: 'Organization / Brokerage Name *',
                                hintText: 'e.g. Apex Realty Partners',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _brokerNameController,
                              decoration: const InputDecoration(
                                labelText: 'Broker Owner Full Name *',
                                hintText: 'e.g. Rajesh Sharma',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Primary Email *',
                                hintText: 'broker@realty.com',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _mobileController,
                                    decoration: const InputDecoration(
                                      labelText: 'Mobile Number',
                                      hintText: '+91 9876543210',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    enableSuggestions: false,
                                    autocorrect: false,
                                    keyboardType: TextInputType.visiblePassword,
                                    decoration: InputDecoration(
                                      labelText: 'Initial Password',
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                          size: 18,
                                        ),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Select Subscription Tier',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: CRMColors.text,
                              ),
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              value: _selectedPlanId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Assigned Plan Tier *',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: widget.plans.map<DropdownMenuItem<String>>((p) {
                                final pName = p['name'] ?? 'Plan';
                                final pPrice = p['price'] ?? 0;
                                final pCycle = p['billing_cycle'] ?? 'monthly';
                                return DropdownMenuItem<String>(
                                  value: p['id'].toString(),
                                  child: Text('$pName (₹$pPrice / $pCycle)'),
                                );
                              }).toList(),
                              onChanged: (v) => setState(() => _selectedPlanId = v),
                              validator: (v) => v == null ? 'Please select a plan' : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _notesController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Onboarding Notes',
                                hintText: 'Any special arrangements or SLA terms...',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: CRMSpacing.l),
                    VerticalDivider(color: CRMColors.border),
                    const SizedBox(width: CRMSpacing.l),

                    // Right: Extra Provisions / Special Access Checklist
                    Expanded(
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
                                      'Special Access & Extra Provisions',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: CRMColors.text,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Grant specific features beyond the standard plan for this broker.',
                                      style: TextStyle(fontSize: 11, color: CRMColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_extraProvisionsMap.values.where((v) => v).length} Special Granted',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Search features to grant extra access...',
                              prefixIcon: const Icon(Icons.search, size: 18),
                              border: const OutlineInputBorder(),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onChanged: (v) => setState(() => _controlsFilter = v),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: ListView.builder(
                              itemCount: widget.allControls.length,
                              itemBuilder: (context, idx) {
                                final ctrl = widget.allControls[idx];
                                final key = ctrl['control_key'].toString();
                                final title = ctrl['title']?.toString() ?? key;
                                final mod = ctrl['module']?.toString() ?? '';

                                if (_controlsFilter.isNotEmpty &&
                                    !title.toLowerCase().contains(_controlsFilter.toLowerCase()) &&
                                    !key.toLowerCase().contains(_controlsFilter.toLowerCase()) &&
                                    !mod.toLowerCase().contains(_controlsFilter.toLowerCase())) {
                                  return const SizedBox.shrink();
                                }

                                final isGranted = _extraProvisionsMap[key] == true;

                                return CheckboxListTile(
                                  value: isGranted,
                                  dense: true,
                                  title: Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: CRMColors.text,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '[$mod] $key',
                                    style: TextStyle(fontSize: 11, color: CRMColors.textSecondary),
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _extraProvisionsMap[key] = true;
                                      } else {
                                        _extraProvisionsMap.remove(key);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: CRMSpacing.m),
              Divider(color: CRMColors.border),
              const SizedBox(height: CRMSpacing.m),

              // Bottom Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isProvisioning ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: CRMSpacing.m),
                  ElevatedButton(
                    onPressed: _isProvisioning ? null : _handleProvision,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CRMColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: _isProvisioning
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Provision Fresh Workspace'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrokerSpecialAccessDialog extends StatefulWidget {
  final Map<String, dynamic> organization;
  final List<dynamic> allControls;
  final VoidCallback onSaved;

  const _BrokerSpecialAccessDialog({
    required this.organization,
    required this.allControls,
    required this.onSaved,
  });

  @override
  State<_BrokerSpecialAccessDialog> createState() => _BrokerSpecialAccessDialogState();
}

class _BrokerSpecialAccessDialogState extends State<_BrokerSpecialAccessDialog> {
  bool _isLoading = true;
  bool _isSaving = false;
  final Map<String, bool> _entitlementsMap = {};
  String _searchFilter = '';

  @override
  void initState() {
    super.initState();
    _loadEntitlements();
  }

  Future<void> _loadEntitlements() async {
    final orgId = widget.organization['organization_id'];
    try {
      final res = await DioClient.dio.get('/subscriptions/organizations/$orgId/entitlements');
      if (res.statusCode == 200 && res.data != null) {
        final list = res.data['data'] as List<dynamic>? ?? [];
        for (final item in list) {
          _entitlementsMap[item['control_key'].toString()] = item['is_enabled'] == true;
        }
      }
    } catch (e) {
      debugPrint('[BrokerSpecialAccess] Error loading entitlements: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSave() async {
    final orgId = widget.organization['organization_id'];
    setState(() => _isSaving = true);
    try {
      await DioClient.dio.put(
        '/subscriptions/organizations/$orgId/entitlements',
        data: {
          'provisionsMap': _entitlementsMap,
          'reason': 'Special access updated from Super Admin Console',
        },
      );
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update special access: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgName = widget.organization['organization_name'] ?? 'Workspace';

    return Dialog(
      backgroundColor: CRMColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 650,
        height: 600,
        padding: const EdgeInsets.all(CRMSpacing.xl),
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
                        'Special Access & Extra Provisions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: CRMColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Workspace: $orgName',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.deepPurple,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: CRMSpacing.m),
            Divider(color: CRMColors.border),
            const SizedBox(height: CRMSpacing.s),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search controls...',
                prefixIcon: const Icon(Icons.search, size: 18),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _searchFilter = v),
            ),
            const SizedBox(height: CRMSpacing.m),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: widget.allControls.length,
                      itemBuilder: (context, idx) {
                        final ctrl = widget.allControls[idx];
                        final key = ctrl['control_key'].toString();
                        final title = ctrl['title']?.toString() ?? key;
                        final mod = ctrl['module']?.toString() ?? '';

                        if (_searchFilter.isNotEmpty &&
                            !title.toLowerCase().contains(_searchFilter.toLowerCase()) &&
                            !key.toLowerCase().contains(_searchFilter.toLowerCase()) &&
                            !mod.toLowerCase().contains(_searchFilter.toLowerCase())) {
                          return const SizedBox.shrink();
                        }

                        final isEnabled = _entitlementsMap[key] == true;

                        return CheckboxListTile(
                          value: isEnabled,
                          dense: true,
                          title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: CRMColors.text)),
                          subtitle: Text('[$mod] $key', style: TextStyle(fontSize: 11, color: CRMColors.textSecondary)),
                          onChanged: (val) {
                            setState(() {
                              _entitlementsMap[key] = val == true;
                            });
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: CRMSpacing.m),
            Divider(color: CRMColors.border),
            const SizedBox(height: CRMSpacing.m),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: CRMSpacing.m),
                ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Provisions'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangePlanDialog extends StatefulWidget {
  final Map<String, dynamic> organization;
  final List<dynamic> plans;
  final VoidCallback onSaved;

  const _ChangePlanDialog({
    required this.organization,
    required this.plans,
    required this.onSaved,
  });

  @override
  State<_ChangePlanDialog> createState() => _ChangePlanDialogState();
}

class _ChangePlanDialogState extends State<_ChangePlanDialog> {
  String? _selectedPlanId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedPlanId = widget.organization['plan_id']?.toString();
    if (_selectedPlanId == null && widget.plans.isNotEmpty) {
      _selectedPlanId = widget.plans[0]['id'].toString();
    }
  }

  Future<void> _handleSave() async {
    final orgId = widget.organization['organization_id'];
    setState(() => _isSaving = true);
    try {
      await DioClient.dio.put(
        '/subscriptions/organizations/$orgId/plan',
        data: {'planId': _selectedPlanId},
      );
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update subscription plan: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgName = widget.organization['organization_name'] ?? 'Workspace';

    return AlertDialog(
      backgroundColor: CRMColors.cardBg,
      title: Text('Change Subscription Plan', style: TextStyle(color: CRMColors.text)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Workspace: $orgName', style: TextStyle(color: CRMColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPlanId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Select New Plan',
                border: OutlineInputBorder(),
              ),
              items: widget.plans.map<DropdownMenuItem<String>>((p) {
                final pName = p['name'] ?? 'Plan';
                final pPrice = p['price'] ?? 0;
                final pCycle = p['billing_cycle'] ?? 'monthly';
                return DropdownMenuItem<String>(
                  value: p['id'].toString(),
                  child: Text('$pName (₹$pPrice / $pCycle)'),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedPlanId = v),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          style: ElevatedButton.styleFrom(backgroundColor: CRMColors.primary, foregroundColor: Colors.white),
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Update Plan'),
        ),
      ],
    );
  }
}

class _DeleteBrokerWorkspaceDialog extends StatefulWidget {
  final Map<String, dynamic> organization;
  final VoidCallback onDeleted;

  const _DeleteBrokerWorkspaceDialog({
    required this.organization,
    required this.onDeleted,
  });

  @override
  State<_DeleteBrokerWorkspaceDialog> createState() => _DeleteBrokerWorkspaceDialogState();
}

class _DeleteBrokerWorkspaceDialogState extends State<_DeleteBrokerWorkspaceDialog> {
  final _confirmationController = TextEditingController();
  bool _isDeleting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete() async {
    final orgId = widget.organization['organization_id'];
    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      final res = await DioClient.dio.delete('/subscriptions/organizations/$orgId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.data['message'] ?? 'Broker workspace deleted successfully.'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
      widget.onDeleted();
    } catch (e) {
      if (!mounted) return;
      String errStr = e.toString();
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          errStr = data['message'].toString();
        } else if (e.message != null && e.message!.isNotEmpty) {
          errStr = e.message!;
        }
      }
      setState(() {
        _isDeleting = false;
        _errorMessage = 'Failed to delete workspace: $errStr';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgName = widget.organization['organization_name'] ?? 'Workspace';
    final ownerName = widget.organization['owner_name'] ?? 'Owner';
    final ownerEmail = widget.organization['owner_email'] ?? '—';
    final canDelete = _confirmationController.text.trim() == orgName.toString().trim();

    return Dialog(
      backgroundColor: CRMColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(CRMSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Danger Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delete Broker Workspace',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: CRMColors.text),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Irreversible action with permanent data removal',
                        style: TextStyle(fontSize: 12, color: CRMColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: CRMSpacing.m),
            Divider(color: CRMColors.border),
            const SizedBox(height: CRMSpacing.m),

            // Warning Notice Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You are about to delete workspace "$orgName":',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.red),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '• Primary administrator ($ownerName - $ownerEmail) will be deleted.\n'
                    '• All isolated listings, leads, properties, and special access entitlements will be destroyed.\n'
                    '• Active subscription entitlements for this tenant will be cancelled.',
                    style: TextStyle(fontSize: 12, color: Colors.red[900], height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: CRMSpacing.l),

            // Type to confirm
            Text(
              'Please type "$orgName" to confirm deletion:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CRMColors.text),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmationController,
              decoration: InputDecoration(
                hintText: orgName,
                border: const OutlineInputBorder(),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (_) => setState(() {}),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(_errorMessage!, style: const TextStyle(fontSize: 12, color: Colors.red)),
            ],

            const SizedBox(height: CRMSpacing.l),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: CRMSpacing.m),
                ElevatedButton(
                  onPressed: (!_isDeleting && canDelete) ? _handleDelete : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.red.withValues(alpha: 0.3),
                    disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                  ),
                  child: _isDeleting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Delete Workspace Permanently'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResetBrokerPasswordDialog extends StatefulWidget {
  final Map<String, dynamic> organization;
  final VoidCallback onSuccess;

  const _ResetBrokerPasswordDialog({
    required this.organization,
    required this.onSuccess,
  });

  @override
  State<_ResetBrokerPasswordDialog> createState() => _ResetBrokerPasswordDialogState();
}

class _ResetBrokerPasswordDialogState extends State<_ResetBrokerPasswordDialog> {
  final _passwordController = TextEditingController(text: 'PropKart@2026');
  bool _obscurePassword = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    final newPass = _passwordController.text.trim();
    if (newPass.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    final orgId = widget.organization['organization_id'];
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await DioClient.dio.post(
        '/subscriptions/organizations/$orgId/reset-password',
        data: {'password': newPass},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password updated for ${widget.organization['owner_name']}!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Copy Password',
              textColor: Colors.white,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: newPass));
              },
            ),
          ),
        );
      }
      widget.onSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = 'Failed to reset password: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgName = widget.organization['organization_name'] ?? 'Workspace';
    final ownerName = widget.organization['owner_name'] ?? 'Owner';
    final ownerEmail = widget.organization['owner_email'] ?? '—';

    return Dialog(
      backgroundColor: CRMColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(CRMSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: CRMColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.lock_reset_rounded, color: CRMColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reset Broker Password',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: CRMColors.text),
                      ),
                      Text(
                        '$ownerName ($ownerEmail) • $orgName',
                        style: TextStyle(fontSize: 12, color: CRMColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: CRMSpacing.m),
            Divider(color: CRMColors.border),
            const SizedBox(height: CRMSpacing.m),
            Text(
              'Set New Password',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CRMColors.text),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: 'Enter new password',
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 18),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(_errorMessage!, style: const TextStyle(fontSize: 12, color: Colors.red)),
            ],
            const SizedBox(height: CRMSpacing.l),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: CRMSpacing.m),
                ElevatedButton(
                  onPressed: _isSaving ? null : _handleReset,
                  style: ElevatedButton.styleFrom(backgroundColor: CRMColors.primary, foregroundColor: Colors.white),
                  child: _isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save New Password'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
