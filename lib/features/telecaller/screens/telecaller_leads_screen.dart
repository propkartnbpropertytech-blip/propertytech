import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/design_system/widgets/crm_page_header.dart';
import '../../../core/design_system/widgets/app_status_snackbar.dart';
import '../../../core/api/dio_client.dart';
import '../data/telecaller_repository.dart';
import '../bloc/telecaller_leads_bloc.dart';

class TelecallerLeadsScreen extends StatelessWidget {
  const TelecallerLeadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TelecallerLeadsBloc()..add(TelecallerLeadsRequested()),
      child: const _TelecallerLeadsView(),
    );
  }
}

class _TelecallerLeadsView extends StatelessWidget {
  const _TelecallerLeadsView();

  static Map<String, dynamic> _parseRaw(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return {};
  }

  static String _name(Map lead) {
    final raw = _parseRaw(lead['raw_json']);
    final candidates = [
      raw['full_name'],
      raw['Full Name'],
      raw['name'],
      raw['Name'],
      raw['client name'],
      raw['Client Name'],
      raw['customer_name'],
      lead['customer_name'],
      lead['name'],
      lead['client_name'],
      lead['full_name'],
    ];
    for (final c in candidates) {
      if (c != null && c.toString().trim().isNotEmpty) {
        return c.toString().trim();
      }
    }
    final phone = (lead['sanitized_phone'] ?? raw['phone_number'] ?? raw['phone'] ?? raw['Number'])?.toString().trim();
    if (phone != null && phone.isNotEmpty) {
      return 'Lead ($phone)';
    }
    final campaign = (lead['campaign_name'] ?? raw['Campaign Name'] ?? raw['campaign_name'])?.toString().trim();
    if (campaign != null && campaign.isNotEmpty) {
      return 'Lead ($campaign)';
    }
    final id = (lead['id']?.toString() ?? '');
    return id.length > 8 ? 'Lead #${id.substring(0, 8)}' : 'Lead';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TelecallerLeadsBloc, TelecallerLeadsState>(
      listener: (context, state) {
        if (state.error != null) {
          AppStatusSnackBar.show(
            context,
            message: state.error!,
            isSuccess: false,
            duration: const Duration(seconds: 4),
          );
        } else if (state.info != null) {
          AppStatusSnackBar.show(
            context,
            message: state.info!,
            isSuccess: true,
            duration: const Duration(seconds: 3),
          );
        }
      },
      builder: (context, state) {
        if (state.loading && state.leads.isEmpty && state.oldUntouchedLeads.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return DefaultTabController(
          length: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: CRMPageHeader(
                        title: 'My Leads',
                        benefit: 'Only leads assigned to you. Ownership is enforced by the API.',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh Leads',
                      onPressed: () {
                        context.read<TelecallerLeadsBloc>().add(TelecallerLeadsRequested());
                      },
                    ),
                  ],
                ),
              ),
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).colorScheme.primary,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flash_on, size: 18),
                        const SizedBox(width: 8),
                        Text('Active Leads (${state.leads.length})'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history, size: 18),
                        const SizedBox(width: 8),
                        Text('Old Untouched Leads (${state.oldUntouchedLeads.length})'),
                      ],
                    ),
                  ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildLeadList(context, state.leads, isOldTab: false),
                    _buildLeadList(context, state.oldUntouchedLeads, isOldTab: true),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeadList(BuildContext context, List<dynamic> leads, {required bool isOldTab}) {
    if (leads.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOldTab ? Icons.archive_outlined : Icons.inbox_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                isOldTab
                    ? 'No assigned old untouched leads.'
                    : 'No active leads assigned to you.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: leads.length,
      itemBuilder: (context, index) {
        final lead = Map<String, dynamic>.from(leads[index] as Map);
        final leadName = _name(lead);
        final phone = (lead['sanitized_phone'] ?? '').toString();
        final campaign = (lead['campaign_name'] ?? '').toString();

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isOldTab ? Colors.amber.shade300 : const Color(0xFFE2E8F0),
              width: isOldTab ? 1.5 : 1.0,
            ),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            onTap: () => _showLeadDetailsDialog(context, lead, isOldTab: isOldTab),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: (isOldTab ? Colors.amber : Colors.blue).withValues(alpha: 0.15),
              child: Icon(
                isOldTab ? Icons.history : Icons.person_outline,
                color: isOldTab ? Colors.amber.shade900 : Colors.blue.shade700,
                size: 20,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    leadName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
                if (isOldTab)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade400),
                    ),
                    child: Text(
                      'Old Untouched',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Builder(
              builder: (context) {
                final allocStatus = (lead['allocation_status'] ?? '').toString();
                final rawAttempts = int.tryParse((lead['call_attempt_count'] ?? 0).toString()) ?? 0;
                final leadAttempts = (allocStatus == 'CNR' || allocStatus == 'CALLBACK') ? math.max(rawAttempts, 1) : rawAttempts;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Status: $allocStatus · Attempts: $leadAttempts'
                    '${phone.isNotEmpty ? " · $phone" : ""}'
                    '${campaign.isNotEmpty ? " · $campaign" : ""}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                );
              },
            ),
            trailing: Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showLeadDetailsDialog(context, lead, isOldTab: isOldTab),
                  icon: const Icon(Icons.info_outline, size: 15),
                  label: const Text('Details'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _handleStartCall(context, lead['id'].toString(), phone),
                  icon: const Icon(Icons.phone, size: 16),
                  label: const Text('Start call'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                ),
                OutlinedButton(
                  onPressed: () => _outcome(context, lead['id'].toString()),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                  child: const Text('Outcome'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLeadDetailsDialog(BuildContext context, Map<String, dynamic> lead, {required bool isOldTab}) {
    final raw = _parseRaw(lead['raw_json']);
    final leadName = _name(lead);
    final phone = (lead['sanitized_phone'] ?? raw['phone_number'] ?? raw['phone'] ?? raw['Number'] ?? '').toString().trim();
    final email = (lead['sanitized_email'] ?? raw['email'] ?? '').toString().trim();
    final campaign = (lead['campaign_name'] ?? raw['Campaign Name'] ?? raw['campaign_name'] ?? '').toString().trim();
    final adName = (lead['ad_name'] ?? raw['Ad Name'] ?? raw['ad_name'] ?? '').toString().trim();
    final formName = (raw['form_name'] ?? raw['Form Name'] ?? '').toString().trim();
    final status = (lead['allocation_status'] ?? 'ASSIGNED_TO_TELECALLER').toString();
    final rawAttempts = int.tryParse((lead['call_attempt_count'] ?? 0).toString()) ?? 0;
    final attempts = (status == 'CNR' || status == 'CALLBACK') ? math.max(rawAttempts, 1) : rawAttempts;
    final assignedAt = lead['telecaller_assigned_at']?.toString().split('.').first.replaceFirst('T', ' ') ?? '';
    final receivedAt = (lead['received_at'] ?? lead['created_at'])?.toString().split('.').first.replaceFirst('T', ' ') ?? '';

    // Extract dynamic questionnaire answers from raw_json
    final ignoredKeys = {
      'id', 'ad_id', 'form_id', 'adset_id', 'campaign_id', 'platform',
      'is_organic', 'lead_status', 'created_time', 'phone_number', 'full_name',
      'email', 'Ad Name', 'ad_name', 'Campaign Name', 'campaign_name', 'form_name',
      'Form Name', 'adset_name', 'city', 'City', 'Name', 'name', 'Status', 'status',
      'Remarks', 'Remarks ', 'Number', ''
    };

    final questionnaire = <MapEntry<String, String>>[];
    for (final entry in raw.entries) {
      final k = entry.key.toString().trim();
      final v = entry.value?.toString().trim() ?? '';
      if (!ignoredKeys.contains(k) && v.isNotEmpty) {
        var title = k.replaceAll('_', ' ').replaceAll('?', '').trim();
        if (title.isNotEmpty) {
          title = title.substring(0, 1).toUpperCase() + title.substring(1);
        }
        questionnaire.add(MapEntry(title, v));
      }
    }

    final city = (raw['city'] ?? raw['City'] ?? raw['where_is_your_property_located?'] ?? '').toString().trim();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        actionsPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: (isOldTab ? Colors.amber : Colors.blue).withValues(alpha: 0.15),
              child: Icon(
                isOldTab ? Icons.history : Icons.person,
                color: isOldTab ? Colors.amber.shade900 : Colors.blue.shade700,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    leadName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    'Lead ID: ${lead['id'] ?? ''}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isOldTab ? Colors.amber.shade100 : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isOldTab ? Colors.amber.shade400 : Colors.blue.shade300),
              ),
              child: Text(
                isOldTab ? 'Old Untouched' : 'Active Lead',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isOldTab ? Colors.amber.shade900 : Colors.blue.shade900,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                _sectionHeader('Contact Information'),
                _detailRow(Icons.person_outline, 'Customer Name', leadName),
                if (phone.isNotEmpty)
                  _detailRow(
                    Icons.phone_outlined,
                    'Phone Number',
                    phone,
                    action: TextButton.icon(
                      onPressed: () => _handleStartCall(context, lead['id'].toString(), phone),
                      icon: const Icon(Icons.call, size: 14),
                      label: const Text('Call'),
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    ),
                  ),
                if (email.isNotEmpty) _detailRow(Icons.email_outlined, 'Email', email),
                if (city.isNotEmpty) _detailRow(Icons.location_on_outlined, 'City / Location', city),

                const SizedBox(height: 14),
                _sectionHeader('Allocation & Status'),
                _detailRow(Icons.info_outline, 'Current Status', status),
                _detailRow(Icons.phone_forwarded, 'Call Attempts', attempts.toString()),
                if (assignedAt.isNotEmpty) _detailRow(Icons.assignment_ind_outlined, 'Assigned At', assignedAt),
                if (receivedAt.isNotEmpty) _detailRow(Icons.access_time, 'Received At', receivedAt),

                if (campaign.isNotEmpty || adName.isNotEmpty || formName.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _sectionHeader('Campaign Details'),
                  if (campaign.isNotEmpty) _detailRow(Icons.campaign_outlined, 'Campaign', campaign),
                  if (formName.isNotEmpty) _detailRow(Icons.description_outlined, 'Form Name', formName),
                  if (adName.isNotEmpty) _detailRow(Icons.ads_click, 'Ad Name', adName),
                ],

                if (questionnaire.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _sectionHeader('Form Enquiry & Requirements'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: questionnaire.map((q) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              q.key,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              q.value,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          if (phone.isNotEmpty)
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.pop(ctx);
                _handleStartCall(context, lead['id'].toString(), phone);
              },
              icon: const Icon(Icons.phone, size: 16),
              label: const Text('Start Call'),
            ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _outcome(context, lead['id'].toString());
            },
            icon: const Icon(Icons.check_circle_outline, size: 16),
            label: const Text('Record Outcome'),
          ),
        ],
      ),
    );
  }

  static Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF475569),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static Widget _detailRow(IconData icon, String label, String value, {Widget? action}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          ?action,
        ],
      ),
    );
  }

  Future<void> _outcome(BuildContext context, String leadId) async {
    final outcome = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('CNR'),
              onTap: () => Navigator.pop(ctx, 'CNR'),
            ),
            ListTile(
              title: const Text('Callback'),
              onTap: () => Navigator.pop(ctx, 'CALLBACK'),
            ),
            ListTile(
              title: const Text('Picked up'),
              onTap: () => Navigator.pop(ctx, 'PICKED_UP'),
            ),
          ],
        ),
      ),
    );
    if (outcome == null || !context.mounted) return;

    String? remarks;
    String? salesUserId;
    String? callbackAt;
    if (outcome == 'CALLBACK') {
      final when = DateTime.now().add(const Duration(hours: 1)).toUtc().toIso8601String();
      callbackAt = when;
      remarks = await _prompt(context, 'Callback remarks');
    } else if (outcome == 'PICKED_UP') {
      remarks = await _prompt(context, 'Mandatory key points');
      if (!context.mounted) return;
      if (remarks == null || remarks.trim().isEmpty) return;
      salesUserId = await _pickSalesUser(context);
      if (salesUserId == null) return;
    } else {
      remarks = await _prompt(context, 'CNR remarks (optional)');
    }

    if (!context.mounted) return;
    context.read<TelecallerLeadsBloc>().add(
          TelecallerOutcomeRequested(
            leadId: leadId,
            outcome: outcome,
            remarks: remarks,
            salesUserId: salesUserId,
            callbackAt: callbackAt,
          ),
        );
  }

  Future<void> _handleStartCall(BuildContext context, String leadId, String phone) async {
    try {
      await TelecallerRepository().startCall(leadId);
      if (!context.mounted) return;
      context.read<TelecallerLeadsBloc>().add(TelecallerLeadsRequested());
      if (phone.isNotEmpty) {
        final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
        final uri = Uri.parse('tel:$clean');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      }
      if (context.mounted) {
        AppStatusSnackBar.show(
          context,
          message: 'Call started and recorded on server.',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppStatusSnackBar.show(
          context,
          message: 'Could not start call: $e',
          isSuccess: false,
        );
      }
    }
  }

  Future<String?> _prompt(BuildContext context, String label) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: TextField(controller: controller, maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<String?> _pickSalesUser(BuildContext context) async {
    try {
      final res = await DioClient.dio.get('/telecaller/sales-users');
      final users = List<dynamic>.from(res.data['data'] ?? []);
      if (!context.mounted) return null;
      return await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Select Sales User'),
          children: [
            for (final u in users)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, (u as Map)['id'].toString()),
                child: Text(
                  u['full_name']?.toString() ?? u['email']?.toString() ?? 'Sales',
                ),
              ),
          ],
        ),
      );
    } catch (_) {
      if (!context.mounted) return null;
      return _prompt(context, 'Sales user ID');
    }
  }
}
