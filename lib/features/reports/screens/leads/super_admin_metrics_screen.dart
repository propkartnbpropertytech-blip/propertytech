import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/api/api_constants.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/design_system/widgets/crm_page_header.dart';
import '../../../../core/theme/theme_manager.dart';
import '../../../../core/design_system/tokens/app_breakpoints.dart';
import '../../../../core/design_system/tokens/app_colors.dart';
import '../../../../core/design_system/mobile/mobile.dart';

abstract class SuperAdminMetricsEvent extends Equatable {
  const SuperAdminMetricsEvent();
  @override
  List<Object?> get props => [];
}

class SuperAdminMetricsRequested extends SuperAdminMetricsEvent {}

class SuperAdminMetricsState extends Equatable {
  final bool loading;
  final String? error;
  final Map<String, dynamic> data;
  const SuperAdminMetricsState({this.loading = false, this.error, this.data = const {}});
  @override
  List<Object?> get props => [loading, error, data];
}

class SuperAdminMetricsBloc extends Bloc<SuperAdminMetricsEvent, SuperAdminMetricsState> {
  SuperAdminMetricsBloc() : super(const SuperAdminMetricsState(loading: true)) {
    on<SuperAdminMetricsRequested>((event, emit) async {
      emit(const SuperAdminMetricsState(loading: true));
      try {
        final res = await DioClient.dio.get(ApiConstants.superAdminMetrics);
        emit(SuperAdminMetricsState(data: Map<String, dynamic>.from(res.data['data'] ?? {})));
      } catch (e) {
        emit(SuperAdminMetricsState(error: e.toString()));
      }
    });
  }
}

class SuperAdminMetricsScreen extends StatelessWidget {
  final SuperAdminMetricsBloc? bloc;
  const SuperAdminMetricsScreen({super.key, this.bloc});

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider<SuperAdminMetricsBloc>.value(
        value: bloc!,
        child: const _SuperAdminMetricsView(),
      );
    }
    return BlocProvider<SuperAdminMetricsBloc>(
      create: (_) => SuperAdminMetricsBloc()..add(SuperAdminMetricsRequested()),
      child: const _SuperAdminMetricsView(),
    );
  }
}

class _SuperAdminMetricsView extends StatelessWidget {
  const _SuperAdminMetricsView();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < CRMBreakpoints.tablet;
    return BlocBuilder<SuperAdminMetricsBloc, SuperAdminMetricsState>(
      builder: (context, state) {
        if (isMobile) {
          return _buildMobile(context, state);
        }
        return _buildDesktop(context, state);
      },
    );
  }

  Widget _buildDesktop(BuildContext context, SuperAdminMetricsState state) {
    final isDark = ThemeManager().isDarkMode;
    if (state.loading) return const Center(child: CircularProgressIndicator());
    final ingestion = Map<String, dynamic>.from(state.data['ingestion'] ?? {});
    final allocation = Map<String, dynamic>.from(state.data['allocation'] ?? {});
    final sales = Map<String, dynamic>.from(state.data['sales'] ?? {});
    final telecallers = List<dynamic>.from(state.data['telecallers'] ?? []);
    return Scaffold(
      backgroundColor: CRMColors.backgroundOf(context),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const CRMPageHeader(
            title: 'Allocation & Team Metrics',
            benefit: 'Backend-calculated ingestion, allocation, Telecaller, and Sales metrics.',
          ),
        if (state.error != null)
          Text(state.error!, style: const TextStyle(color: Colors.red)),
        Text(
          'Ingestion · total ${ingestion['totalLeads'] ?? 0} · today ${ingestion['leadsReceivedToday'] ?? 0}',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        const SizedBox(height: 8),
        Text(
          'Allocation · allocated ${allocation['allocatedLeads'] ?? 0} · waiting ${allocation['waitingLeads'] ?? 0} · success ${allocation['allocationSuccessRate'] ?? '-'}%',
        ),
        const SizedBox(height: 8),
        Text(
          'Sales · handed ${sales['leadsReceivedFromTelecallers'] ?? 0} · active ${sales['activeLeads'] ?? 0} · visits ${sales['siteVisits'] ?? 0} · properties ${sales['propertiesAdded'] ?? 0}',
        ),
        const SizedBox(height: 16),
        const Text('Telecallers', style: TextStyle(fontWeight: FontWeight.bold)),
        for (final raw in telecallers)
          ListTile(
            title: Text((raw as Map)['name']?.toString() ?? 'Telecaller'),
            subtitle: Text(
              '${raw['status']} · load ${raw['currentWorkload']}/${raw['maxCapacity']} · CNR ${raw['cnr']} · transfers ${raw['salesTransfers']}',
            ),
          ),
      ],
    ),
  );
}

  Widget _buildMobile(BuildContext context, SuperAdminMetricsState state) {
    if (state.loading) {
      return MobileScreenScaffold(
        title: 'Super Admin Metrics',
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (state.error != null) {
      return MobileScreenScaffold(
        title: 'Super Admin Metrics',
        body: MobileErrorState(
          title: 'Failed to load metrics',
          message: state.error ?? 'Unable to retrieve super-admin telemetry metrics.',
          onRetry: () {
            context.read<SuperAdminMetricsBloc>().add(SuperAdminMetricsRequested());
          },
        ),
      );
    }

    if (state.data.isEmpty) {
      return const MobileScreenScaffold(
        title: 'Super Admin Metrics',
        body: MobileEmptyState(
          title: 'No Metrics Available',
          description: 'No super-admin metrics data recorded yet.',
          icon: Icons.analytics_outlined,
        ),
      );
    }

    final ingestion = Map<String, dynamic>.from(state.data['ingestion'] ?? {});
    final allocation = Map<String, dynamic>.from(state.data['allocation'] ?? {});
    final sales = Map<String, dynamic>.from(state.data['sales'] ?? {});
    final telecallers = List<dynamic>.from(state.data['telecallers'] ?? []);

    return MobileScreenScaffold(
      title: 'Super Admin Metrics',
      scrollable: false,
      onRefresh: () async {
        context.read<SuperAdminMetricsBloc>().add(SuperAdminMetricsRequested());
      },
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Subtitle benefit banner
          Text(
            'Backend-calculated ingestion, allocation, Telecaller, and Sales metrics.',
            style: TextStyle(
              fontSize: 12.5,
              color: CRMColors.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 16),

          // 1. Ingestion Section
          const MobileSectionHeader(title: 'Lead Ingestion'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Total Leads',
                  value: '${ingestion['totalLeads'] ?? 0}',
                  icon: Icons.all_inbox_rounded,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  label: 'Today',
                  value: '${ingestion['leadsReceivedToday'] ?? 0}',
                  icon: Icons.today_rounded,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. Allocation Section
          const MobileSectionHeader(title: 'Allocation Performance'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Allocated',
                  value: '${allocation['allocatedLeads'] ?? 0}',
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  label: 'Waiting',
                  value: '${allocation['waitingLeads'] ?? 0}',
                  icon: Icons.hourglass_top_rounded,
                  color: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  label: 'Success Rate',
                  value: '${allocation['allocationSuccessRate'] ?? '-'}%',
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF06B6D4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3. Sales Section
          const MobileSectionHeader(title: 'Sales Operations'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Handed to Sales',
                  value: '${sales['leadsReceivedFromTelecallers'] ?? 0}',
                  icon: Icons.forward_to_inbox_rounded,
                  color: const Color(0xFFEC4899),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  label: 'Active Leads',
                  value: '${sales['activeLeads'] ?? 0}',
                  icon: Icons.person_outline_rounded,
                  color: const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Site Visits',
                  value: '${sales['siteVisits'] ?? 0}',
                  icon: Icons.location_on_outlined,
                  color: const Color(0xFF14B8A6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  label: 'Properties Added',
                  value: '${sales['propertiesAdded'] ?? 0}',
                  icon: Icons.apartment_rounded,
                  color: const Color(0xFFE11D48),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 4. Telecallers Team
          MobileSectionHeader(
            title: 'Telecaller Performance (${telecallers.length})',
          ),
          const SizedBox(height: 8),
          if (telecallers.isEmpty)
            const MobileEmptyState(
              icon: Icons.headset_mic_outlined,
              title: 'No Telecallers Found',
              description: 'No telecaller workload records available at this time.',
            )
          else
            for (final raw in telecallers)
              _MobileTelecallerCard(data: raw as Map),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: CRMColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CRMColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: CRMColors.textOf(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileTelecallerCard extends StatelessWidget {
  final Map data;

  const _MobileTelecallerCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data['name']?.toString() ?? 'Telecaller';
    final status = data['status']?.toString() ?? 'UNKNOWN';
    final load = '${data['currentWorkload'] ?? 0}/${data['maxCapacity'] ?? 0}';
    final cnr = '${data['cnr'] ?? 0}';
    final transfers = '${data['salesTransfers'] ?? 0}';

    Color statusColor;
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        statusColor = const Color(0xFF10B981);
        break;
      case 'BREAK':
        statusColor = const Color(0xFFF59E0B);
        break;
      default:
        statusColor = const Color(0xFF94A3B8);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CRMColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CRMColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: statusColor.withValues(alpha: 0.15),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'T',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: CRMColors.textOf(context),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _badge(context, 'Load: $load', Icons.work_outline_rounded),
              _badge(context, 'CNR: $cnr', Icons.phone_missed_rounded),
              _badge(context, 'Transfers: $transfers', Icons.swap_horiz_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(BuildContext context, String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CRMColors.borderOf(context).withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: CRMColors.textSecondaryOf(context)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: CRMColors.textSecondaryOf(context),
            ),
          ),
        ],
      ),
    );
  }
}

