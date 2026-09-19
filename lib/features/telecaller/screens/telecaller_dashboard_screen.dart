import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/widgets/crm_page_header.dart';
import '../../dashboard/widgets/stat_card.dart';
import '../bloc/telecaller_dashboard_bloc.dart';
import '../widgets/telecaller_availability_toggle.dart';

class TelecallerDashboardScreen extends StatelessWidget {
  const TelecallerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TelecallerDashboardBloc()..add(TelecallerDashboardRequested()),
      child: const _TelecallerDashboardView(),
    );
  }
}

class _TelecallerDashboardView extends StatelessWidget {
  const _TelecallerDashboardView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TelecallerDashboardBloc, TelecallerDashboardState>(
      builder: (context, state) {
        final data = state.data;
        if (state.loading && data.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final next = data['nextLead'] as Map<String, dynamic>?;
        return RefreshIndicator(
          onRefresh: () async {
            context.read<TelecallerDashboardBloc>().add(TelecallerDashboardRequested());
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const CRMPageHeader(
                title: 'Telecaller Dashboard',
                benefit: 'Availability, workload, and next lead come from the server.',
              ),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(state.error!, style: const TextStyle(color: Colors.red)),
                ),
              Row(
                children: [
                  const TelecallerAvailabilityToggle(),
                  const SizedBox(width: 12),
                  Text(
                    data['heartbeatFresh'] == true
                        ? '• System Live: Eligible to receive fresh incoming leads.'
                        : '• Standby: Turn switch ACTIVE to start receiving leads.',
                    style: TextStyle(
                      color: data['heartbeatFresh'] == true ? const Color(0xFF059669) : const Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _clickableKpi(context, 'My assigned leads', '${data['assignedLeads'] ?? 0}', Icons.assignment_outlined, '/telecaller/leads'),
                  _clickableKpi(context, 'Uncontacted', '${data['uncontacted'] ?? 0}', Icons.mark_email_unread_outlined, '/telecaller/leads'),
                  _clickableKpi(context, 'Callbacks', '${data['callbackCount'] ?? 0}', Icons.event_repeat, '/telecaller/callbacks'),
                  _clickableKpi(context, "Today's callbacks", '${data['todaysCallbacks'] ?? 0}', Icons.today_outlined, '/telecaller/callbacks'),
                  _clickableKpi(context, 'CNR / Retries', '${data['cnrCount'] ?? 0}', Icons.phone_missed_outlined, '/telecaller/cnr'),
                  _clickableKpi(context, 'Picked up', '${data['pickedUp'] ?? 0}', Icons.call_received, '/telecaller/leads'),
                  _clickableKpi(context, 'Handed to Sales', '${data['handedToSales'] ?? 0}', Icons.handshake_outlined, '/telecaller/leads'),
                  _clickableKpi(
                    context,
                    'Workload',
                    '${data['currentWorkload'] ?? 0}/${data['maxCapacity'] ?? 0}',
                    Icons.speed,
                    '/telecaller/leads',
                  ),
                  _clickableKpi(context, 'Remaining Capacity', '${data['remainingCapacity'] ?? 0}', Icons.hourglass_bottom, '/telecaller/leads'),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                child: ListTile(
                  title: const Text('Next lead'),
                  subtitle: Text(
                    next == null
                        ? 'No actionable lead. Go ACTIVE to receive waiting-queue work.'
                        : _leadDisplayName(next),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/telecaller/leads'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _clickableKpi(BuildContext context, String title, String value, IconData icon, String route) {
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
            accentColor: CRMColors.primary,
            isCompact: true,
          ),
        ),
      ),
    );
  }

  static String _leadDisplayName(Map next) {
    dynamic raw = next['raw_json'];
    if (raw is String && raw.isNotEmpty) {
      try {
        raw = jsonDecode(raw);
      } catch (_) {}
    }
    if (raw is Map) {
      final candidates = [
        raw['full_name'],
        raw['Full Name'],
        raw['name'],
        raw['Name'],
        raw['client name'],
        raw['Client Name'],
        raw['customer_name'],
        next['customer_name'],
        next['name'],
      ];
      for (final c in candidates) {
        if (c != null && c.toString().trim().isNotEmpty) {
          return c.toString().trim();
        }
      }
    }
    final phone = (next['sanitized_phone'] ?? (raw is Map ? raw['phone_number'] : null))?.toString().trim();
    if (phone != null && phone.isNotEmpty) {
      return 'Lead ($phone)';
    }
    return 'Lead assigned';
  }
}
