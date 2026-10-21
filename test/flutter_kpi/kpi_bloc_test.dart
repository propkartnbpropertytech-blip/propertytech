import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/dashboard/bloc/dashboard_bloc.dart';
import 'package:propkart/features/dashboard/models/dashboard_summary.dart';
import 'package:propkart/features/dashboard/models/kpi_models.dart';
import 'package:propkart/features/dashboard/repository/dashboard_repository.dart';

class _FakeDashboardRepository extends DashboardRepository {
  int kpiFetchCount = 0;
  KpiFilterParams? lastParams;

  @override
  Future<DashboardData> getDashboardData({
    bool backgroundRefresh = true,
    bool forceRefresh = false,
  }) async {
    return DashboardData.fromJson({});
  }

  @override
  Future<DashboardKpisResponse> getDashboardKpis(KpiFilterParams params) async {
    kpiFetchCount++;
    lastParams = params;
    return DashboardKpisResponse(
      counts: const DashboardKpiCounts(
        availableInventory: 50,
        totalLeads: 120,
        dealWon: 12,
      ),
      filters: params.toQueryParams(),
    );
  }
}

void main() {
  group('Step 8.5: DashboardBloc State Transition & Zero-Flicker Tests', () {
    late _FakeDashboardRepository fakeRepository;
    late DashboardBloc bloc;

    setUp(() {
      fakeRepository = _FakeDashboardRepository();
      bloc = DashboardBloc(dashboardRepository: fakeRepository);
    });

    tearDown(() {
      bloc.close();
    });

    test('1. LoadDashboard transitions from Initial -> Loading -> Loaded with authoritative KPIs', () async {
      expect(bloc.state, isA<DashboardInitial>());

      bloc.add(const LoadDashboard());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<DashboardLoading>(),
          isA<DashboardLoadedState>().having(
            (s) => s.kpis?.counts.availableInventory,
            'availableInventory',
            equals(50),
          ),
        ]),
      );

      expect(fakeRepository.kpiFetchCount, equals(1));
    });

    test('2. LoadDashboardKpis updates isKpiLoading without resetting existing dashboard data', () async {
      // First load to reach DashboardLoadedState
      bloc.add(const LoadDashboard());
      await bloc.stream.firstWhere((s) => s is DashboardLoadedState);

      const newFilters = KpiFilterParams(
        businessType: 'Both',
        dateFilter: 'Monthly',
      );

      // Trigger filter change
      bloc.add(const LoadDashboardKpis(filters: newFilters));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          // 1. Soft loading: retains existing data & counts with isKpiLoading = true (zero flickering)
          isA<DashboardLoadedState>()
              .having((s) => s.isKpiLoading, 'isKpiLoading', isTrue)
              .having((s) => s.kpiFilters.businessType, 'businessType', equals('Both')),
          // 2. Fresh counts: isKpiLoading = false
          isA<DashboardLoadedState>()
              .having((s) => s.isKpiLoading, 'isKpiLoading', isFalse)
              .having((s) => s.kpis?.counts.totalLeads, 'totalLeads', equals(120)),
        ]),
      );

      expect(fakeRepository.lastParams?.businessType, equals('Both'));
      expect(fakeRepository.lastParams?.dateFilter, equals('Monthly'));
    });
  });
}
