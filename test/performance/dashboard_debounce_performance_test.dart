import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/dashboard/bloc/dashboard_bloc.dart';
import 'package:propkart/features/dashboard/models/dashboard_summary.dart';
import 'package:propkart/features/dashboard/models/kpi_models.dart';
import 'package:propkart/features/dashboard/repository/dashboard_repository.dart';
import 'package:propkart/features/dashboard/services/dashboard_service.dart';

class MockDashboardRepository extends DashboardRepository {
  int refreshCallCount = 0;

  @override
  Future<DashboardData> getDashboardData({
    bool backgroundRefresh = true,
    bool forceRefresh = false,
  }) async {
    refreshCallCount++;
    // Simulate async network/disk latency
    await Future.delayed(const Duration(milliseconds: 50));
    return DashboardData.fromJson({});
  }

  @override
  Future<DashboardKpisResponse> getDashboardKpis(KpiFilterParams params) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return const DashboardKpisResponse();
  }
}

class MockDashboardService extends DashboardService {
  @override
  Future<DashboardKpisResponse> getDashboardKpis(KpiFilterParams params) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return DashboardKpisResponse.fromJson({});
  }
}

void main() {
  group('Dashboard Debounce & Concurrency Performance (Step 7)', () {
    test('Consecutive concurrent RefreshDashboard calls are safely deduped', () async {
      final mockRepo = MockDashboardRepository();
      final mockService = MockDashboardService();
      final bloc = DashboardBloc(
        dashboardRepository: mockRepo,
        dashboardService: mockService,
      );

      // Emit initial loaded state
      bloc.emit(DashboardLoadedState(
        data: DashboardData.fromJson({}),
      ));

      // Trigger two RefreshDashboard events back-to-back while the first is in-flight
      bloc.add(RefreshDashboard());
      bloc.add(RefreshDashboard());

      await Future.delayed(const Duration(milliseconds: 300));

      // Verify that duplicate concurrent refresh did not cause parallel network storms
      expect(mockRepo.refreshCallCount, equals(1));

      await bloc.close();
    });
  });
}
