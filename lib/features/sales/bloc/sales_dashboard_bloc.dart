import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/widgets/crm_page_header.dart';
import '../../../core/utils/budget_formatter.dart';
import '../../dashboard/widgets/stat_card.dart';

abstract class SalesDashboardEvent extends Equatable {
  const SalesDashboardEvent();
  @override
  List<Object?> get props => [];
}

class SalesDashboardRequested extends SalesDashboardEvent {}

class SalesDashboardState extends Equatable {
  final bool loading;
  final String? error;
  final Map<String, dynamic> data;
  const SalesDashboardState({this.loading = false, this.error, this.data = const {}});
  @override
  List<Object?> get props => [loading, error, data];
}

class SalesDashboardBloc extends Bloc<SalesDashboardEvent, SalesDashboardState> {
  SalesDashboardBloc() : super(const SalesDashboardState(loading: true)) {
    on<SalesDashboardRequested>((event, emit) async {
      emit(const SalesDashboardState(loading: true));
      try {
        final res = await DioClient.dio.get(ApiConstants.salesDashboardSummary);
        emit(SalesDashboardState(data: Map<String, dynamic>.from(res.data['data'] ?? {})));
      } catch (e) {
        emit(SalesDashboardState(error: e.toString()));
      }
    });
  }
}

class SalesDashboardScreen extends StatelessWidget {
  const SalesDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SalesDashboardBloc()..add(SalesDashboardRequested()),
      child: const _SalesDashboardView(),
    );
  }
}

class _SalesDashboardView extends StatelessWidget {
  const _SalesDashboardView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesDashboardBloc, SalesDashboardState>(
      builder: (context, state) {
        if (state.loading && state.data.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final d = state.data;
        final recentLeads = List<dynamic>.from(d['recentLeads'] ?? []);
        final recentProps = List<dynamic>.from(d['recentProperties'] ?? []);

        return RefreshIndicator(
          onRefresh: () async {
            context.read<SalesDashboardBloc>().add(SalesDashboardRequested());
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const CRMPageHeader(
                title: 'Sales Dashboard',
                benefit: 'Direct access to your assigned leads and complete company inventory.',
              ),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(state.error!, style: const TextStyle(color: Colors.red)),
                ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _kpi(
                    context,
                    title: 'Assigned Leads',
                    value: '${d['assignedLeads'] ?? d['leadsAssignedToMe'] ?? 0}',
                    icon: Icons.assignment_ind_rounded,
                    route: '/requirements?group=assigned',
                  ),
                  _kpi(
                    context,
                    title: 'New Leads',
                    value: '${d['newLeads'] ?? 0}',
                    icon: Icons.fiber_new_rounded,
                    route: '/requirements?tab=leads&group=assigned',
                  ),
                  _kpi(
                    context,
                    title: 'Follow-ups Due',
                    value: '${d['followups'] ?? 0}',
                    icon: Icons.event_note_rounded,
                    route: '/requirements?tab=follow-ups',
                  ),
                  _kpi(
                    context,
                    title: 'Site Visits',
                    value: '${d['siteVisits'] ?? 0}',
                    icon: Icons.place_outlined,
                    route: '/requirements?tab=follow-ups&subTab=site-visits',
                  ),
                  _kpi(
                    context,
                    title: 'Available Properties',
                    value: '${d['availableProperties'] ?? recentProps.length}',
                    icon: Icons.home_work_outlined,
                    route: '/properties',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.home_work_outlined, size: 18),
                    label: const Text('Browse Open Inventory'),
                    onPressed: () => context.go('/properties'),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.assignment_outlined, size: 18),
                    label: const Text('My Leads & Follow-ups'),
                    onPressed: () => context.go('/requirements'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recent Assigned Leads Panel
                  Expanded(
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Recent Assigned Leads',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                TextButton(
                                  onPressed: () => context.go('/requirements'),
                                  child: const Text('View All'),
                                ),
                              ],
                            ),
                            const Divider(),
                            if (recentLeads.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No leads assigned yet.'),
                              ),
                            for (final l in recentLeads)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFEFF6FF),
                                  child: Icon(Icons.person, color: CRMColors.primary, size: 18),
                                ),
                                title: Text(
                                  (l as Map)['customer_name']?.toString() ?? 'Lead',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text('${l['mobile'] ?? ''} · ${l['status'] ?? 'New'}'),
                                trailing: const Icon(Icons.chevron_right, size: 18),
                                onTap: () => context.go('/requirements'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Open Inventory Properties Panel
                  Expanded(
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Available Inventory',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Open to all sales agents',
                                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () => context.go('/properties'),
                                  child: const Text('View All'),
                                ),
                              ],
                            ),
                            const Divider(),
                            if (recentProps.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No properties in inventory yet.'),
                              ),
                            for (final p in recentProps)
                              _buildPropertyTile(context, p as Map),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildPropertyTile(BuildContext context, Map p) {
    final title = (p['title']?.toString().trim().isNotEmpty == true)
        ? p['title'].toString()
        : (p['property_code']?.toString() ?? 'Property');

    final rawPrice = double.tryParse(p['price']?.toString() ?? '0') ?? 0.0;
    final formattedPrice = rawPrice > 0 ? '₹${BudgetFormatter.format(rawPrice)}' : 'Price on Request';
    final address = p['address']?.toString() ?? '';

    final imagesList = (p['images'] is List) ? List<dynamic>.from(p['images']) : [];
    final firstImg = imagesList.isNotEmpty ? imagesList.first.toString().trim() : '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      dense: true,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 52,
          height: 52,
          child: firstImg.isNotEmpty && (firstImg.startsWith('http://') || firstImg.startsWith('https://'))
              ? Image.network(
                  firstImg,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _propertyPlaceholder(),
                )
              : _propertyPlaceholder(),
        ),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
      ),
      subtitle: Row(
        children: [
          Text(
            formattedPrice,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF059669), fontSize: 12),
          ),
          if (address.isNotEmpty) ...[
            const SizedBox(width: 6),
            const Text('·', style: TextStyle(color: Color(0xFF94A3B8))),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
              ),
            ),
          ],
        ],
      ),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () => context.go('/properties'),
    );
  }

  static Widget _propertyPlaceholder() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Icon(Icons.apartment_rounded, color: Color(0xFF94A3B8), size: 22),
      ),
    );
  }

  static Widget _kpi(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required String route,
  }) {
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
}
