import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/dashboard/models/kpi_models.dart';

void main() {
  group('Step 8.5: KPI Model & DTO Serialization Tests', () {
    test('1. DashboardKpiCounts parses standard JSON payload correctly', () {
      final json = {
        'available_inventory': 42,
        'total_leads': 150,
        'all_available_inventory': 80,
        'all_total_leads': 300,
        'telecallers': 8,
        'leads_allocated': 35,
        'assigned_to_sales': 22,
        'site_visits_done': 14,
        'rejected_after_site_visit': 3,
        'deal_won': 9,
        'sales_users': 6,
        'not_interested': 12,
        'cnr': 5,
      };

      final counts = DashboardKpiCounts.fromJson(json);

      expect(counts.availableInventory, equals(42));
      expect(counts.totalLeads, equals(150));
      expect(counts.allAvailableInventory, equals(80));
      expect(counts.allTotalLeads, equals(300));
      expect(counts.telecallers, equals(8));
      expect(counts.leadsAllocated, equals(35));
      expect(counts.assignedToSales, equals(22));
      expect(counts.siteVisitsDone, equals(14));
      expect(counts.rejectedAfterSiteVisit, equals(3));
      expect(counts.dealWon, equals(9));
      expect(counts.salesUsers, equals(6));
      expect(counts.notInterested, equals(12));
      expect(counts.cnr, equals(5));
    });

    test('2. DashboardKpiCounts handles null, missing, or mismatched types safely', () {
      final json = <String, dynamic>{
        'available_inventory': null,
        'total_leads': 12.8, // Floating point coercion
        // Missing all_available_inventory
        'deal_won': 'not_a_number', // Invalid type
      };

      final counts = DashboardKpiCounts.fromJson(json);

      expect(counts.availableInventory, equals(0));
      expect(counts.totalLeads, equals(12));
      expect(counts.allAvailableInventory, equals(0));
      expect(counts.dealWon, equals(0));
    });

    test('3. DashboardKpisResponse deserializes envelope with config and date range', () {
      final json = {
        'counts': {
          'available_inventory': 25,
          'total_leads': 75,
          'deal_won': 5,
        },
        'config': [
          {
            'id': 'kpi_avail_inv',
            'kpi_key': 'available_inventory',
            'kpi_label': 'Available Inventory',
            'is_enabled': true,
            'display_order': 1,
          }
        ],
        'filters': {
          'businessType': 'Rent',
          'dateFilter': 'Weekly',
        },
        'dateRange': {
          'startDate': '2026-10-01',
          'endDate': '2026-10-08',
        },
        'dateRangeDisplay': 'Oct 1, 2026 - Oct 8, 2026',
      };

      final response = DashboardKpisResponse.fromJson(json);

      expect(response.counts.availableInventory, equals(25));
      expect(response.counts.totalLeads, equals(75));
      expect(response.counts.dealWon, equals(5));
      expect(response.config.length, equals(1));
      expect(response.config.first.kpiKey, equals('available_inventory'));
      expect(response.filters['businessType'], equals('Rent'));
      expect(response.dateRange?['startDate'], equals('2026-10-01'));
    });

    test('4. KpiConfigItem serializes and deserializes accurately', () {
      const item = KpiConfigItem(
        id: 'cfg_1',
        kpiKey: 'total_leads',
        kpiLabel: 'Total Leads',
        isEnabled: true,
        displayOrder: 2,
        icon: 'group_rounded',
      );

      final json = item.toJson();
      final fromJson = KpiConfigItem.fromJson(json);

      expect(fromJson.id, equals('cfg_1'));
      expect(fromJson.kpiKey, equals('total_leads'));
      expect(fromJson.kpiLabel, equals('Total Leads'));
      expect(fromJson.isEnabled, isTrue);
      expect(fromJson.displayOrder, equals(2));
      expect(fromJson.icon, equals('group_rounded'));
    });
  });
}
