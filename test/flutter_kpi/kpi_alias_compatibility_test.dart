import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/dashboard/models/kpi_models.dart';

void main() {
  group('Step 8.5: KPI Bidirectional Alias Compatibility Tests', () {
    test('1. deal_won parses closed_deals and converted_clients aliases', () {
      final jsonA = {'closed_deals': 15};
      final countsA = DashboardKpiCounts.fromJson(jsonA);
      expect(countsA.dealWon, equals(15));
      expect(countsA.closedDeals, equals(15));
      expect(countsA.convertedClients, equals(15));

      final jsonB = {'converted_clients': 22};
      final countsB = DashboardKpiCounts.fromJson(jsonB);
      expect(countsB.dealWon, equals(22));
      expect(countsB.closedDeals, equals(22));
      expect(countsB.convertedClients, equals(22));

      final jsonCanonical = {'deal_won': 30};
      final countsCanonical = DashboardKpiCounts.fromJson(jsonCanonical);
      expect(countsCanonical.dealWon, equals(30));
    });

    test('2. leads_allocated parses new_leads_allocated and total_allocated aliases', () {
      final jsonA = {'new_leads_allocated': 40};
      final countsA = DashboardKpiCounts.fromJson(jsonA);
      expect(countsA.leadsAllocated, equals(40));
      expect(countsA.totalAllocated, equals(40));
      expect(countsA.newAllocated, equals(40));

      final jsonB = {'total_allocated': 55};
      final countsB = DashboardKpiCounts.fromJson(jsonB);
      expect(countsB.leadsAllocated, equals(55));
      expect(countsB.totalAllocated, equals(55));

      final jsonC = {'allocated_leads': 18};
      final countsC = DashboardKpiCounts.fromJson(jsonC);
      expect(countsC.leadsAllocated, equals(18));
    });

    test('3. all_available_inventory parses global_available_inventory and total_available_inventory', () {
      final jsonA = {'global_available_inventory': 95};
      final countsA = DashboardKpiCounts.fromJson(jsonA);
      expect(countsA.allAvailableInventory, equals(95));
      expect(countsA.globalAvailableInventory, equals(95));

      final jsonB = {'total_available_inventory': 110};
      final countsB = DashboardKpiCounts.fromJson(jsonB);
      expect(countsB.allAvailableInventory, equals(110));
      expect(countsB.globalAvailableInventory, equals(110));
    });

    test('4. all_total_leads parses global_total_leads and total_leads_all', () {
      final jsonA = {'global_total_leads': 250};
      final countsA = DashboardKpiCounts.fromJson(jsonA);
      expect(countsA.allTotalLeads, equals(250));
      expect(countsA.globalTotalLeads, equals(250));

      final jsonB = {'total_leads_all': 320};
      final countsB = DashboardKpiCounts.fromJson(jsonB);
      expect(countsB.allTotalLeads, equals(320));
      expect(countsB.globalTotalLeads, equals(320));
    });

    test('5. site_visits_done parses site_visits_done_req', () {
      final json = {'site_visits_done_req': 19};
      final counts = DashboardKpiCounts.fromJson(json);
      expect(counts.siteVisitsDone, equals(19));
    });
  });
}
