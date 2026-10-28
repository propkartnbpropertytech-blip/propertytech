import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/dashboard/repository/dashboard_repository.dart';

void main() {
  group('Step 8.5: DashboardRepository Method Interface Tests', () {
    late DashboardRepository repository;

    setUp(() {
      repository = DashboardRepository();
    });

    test('1. Repository exposes all authoritative KPI and drilldown methods', () {
      expect(repository.getDashboardKpis, isA<Function>());
      expect(repository.getInventoryBreakdown, isA<Function>());
      expect(repository.getInventoryProperties, isA<Function>());
      expect(repository.getLeadsBreakdown, isA<Function>());
      expect(repository.getLeadsList, isA<Function>());
      expect(repository.getNotInterestedLeads, isA<Function>());
      expect(repository.getTelecallersSummary, isA<Function>());
      expect(repository.getTelecallerDrilldown, isA<Function>());
      expect(repository.getTelecallerLeads, isA<Function>());
      expect(repository.getSiteVisitsList, isA<Function>());
      expect(repository.getDealWonList, isA<Function>());
      expect(repository.getSalesUserRequirements, isA<Function>());
      expect(repository.getLeadsAllocatedBreakdown, isA<Function>());
      expect(repository.getAssignedToSalesBreakdown, isA<Function>());
      expect(repository.getSalesUsersSummary, isA<Function>());
      expect(repository.getSalesUserDrilldown, isA<Function>());
      expect(repository.getLifecycleBreakdown, isA<Function>());
      expect(repository.getLifecycleLeads, isA<Function>());
      expect(repository.getLocalityIntelligence, isA<Function>());
      expect(repository.getKpiConfig, isA<Function>());
      expect(repository.updateKpiConfig, isA<Function>());
      expect(repository.getKpiRegistry, isA<Function>());
    });

    test('2. Repository exposes authoritative followup mutation methods', () {
      expect(repository.updateFollowup, isA<Function>());
      expect(repository.scheduleFollowup, isA<Function>());
    });
  });
}
