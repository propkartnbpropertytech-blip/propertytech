import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/api/api_constants.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/design_system/widgets/crm_page_header.dart';
import '../../../../core/theme/theme_manager.dart';

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
  const SuperAdminMetricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    return BlocProvider(
      create: (_) => SuperAdminMetricsBloc()..add(SuperAdminMetricsRequested()),
      child: BlocBuilder<SuperAdminMetricsBloc, SuperAdminMetricsState>(
        builder: (context, state) {
          if (state.loading) return const Center(child: CircularProgressIndicator());
          final ingestion = Map<String, dynamic>.from(state.data['ingestion'] ?? {});
          final allocation = Map<String, dynamic>.from(state.data['allocation'] ?? {});
          final sales = Map<String, dynamic>.from(state.data['sales'] ?? {});
          final telecallers = List<dynamic>.from(state.data['telecallers'] ?? []);
          return ListView(
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
          );
        },
      ),
    );
  }
}
