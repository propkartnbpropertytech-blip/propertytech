import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/dashboard/models/kpi_models.dart';
import 'package:propkart/features/dashboard/widgets/generic_kpi_drilldown_dialog.dart';

void main() {
  group('Dynamic KPI Builder & Drilldown Composer: Flutter Automated Test Suite', () {
    test('1. KpiRegistryItem and DrilldownConfig Model Serialization', () {
      final json = {
        'id': '11111111-2222-3333-4444-555555555555',
        'kpi_key': 'site_visits_done',
        'kpi_label': 'Site Visits Done',
        'why_do_we_have_it': 'Track completed property viewings',
        'data_source': 'site_visits',
        'entity_table': 'site_visits',
        'aggregation': 'COUNT',
        'primary_field': 'id',
        'is_clickable': true,
        'admin_visible': true,
        'telecaller_visible': false,
        'sales_visible': true,
        'is_system': true,
        'is_enabled': true,
        'lifecycle_status': 'active',
        'drilldown_config': {
          'layout': 'default',
          'components': [
            {
              'id': 'comp_sv_kpis',
              'type': 'kpi_group',
              'title': 'Site Visit Status Summary',
              'items': [
                {'label': 'Scheduled', 'status': 'SCHEDULED', 'aggregation': 'COUNT'},
                {'label': 'Completed', 'status': 'DONE', 'aggregation': 'COUNT', 'is_clickable': true, 'kpi_key': 'sub_sv_completed'}
              ]
            },
            {
              'id': 'comp_sv_chart',
              'type': 'chart',
              'title': 'Visit Status Distribution',
              'chart_type': 'donut',
              'dimension': 'status'
            },
            {
              'id': 'comp_sv_table',
              'type': 'table',
              'title': 'Site Visit Records',
              'columns': ['Customer', 'Property', 'Sales User', 'Visit Date', 'Status'],
              'data_source': 'site_visits'
            }
          ]
        }
      };

      final item = KpiRegistryItem.fromJson(json);
      expect(item.id, equals('11111111-2222-3333-4444-555555555555'));
      expect(item.kpiKey, equals('site_visits_done'));
      expect(item.kpiLabel, equals('Site Visits Done'));
      expect(item.whyDoWeHaveIt, equals('Track completed property viewings'));
      expect(item.adminVisible, isTrue);
      expect(item.telecallerVisible, isFalse);
      expect(item.salesVisible, isTrue);
      expect(item.isClickable, isTrue);
      expect(item.lifecycleStatus, equals('active'));

      final config = item.drilldownConfig;
      expect(config['layout'], equals('default'));
      final components = (config['components'] as List);
      expect(components.length, equals(3));
      expect(components[0]['type'], equals('kpi_group'));
      expect((components[0]['items'] as List).length, equals(2));
      expect(components[0]['items'][1]['kpi_key'], equals('sub_sv_completed'));
      expect(components[1]['type'], equals('chart'));
      expect(components[1]['chart_type'], equals('donut'));
      expect(components[2]['type'], equals('table'));
    });

    testWidgets('2. GenericKpiDrilldownDialog Renders Breadcrumbs & Header Correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GenericKpiDrilldownDialog(
              kpiKey: 'site_visits_done',
              kpiLabel: 'Site Visits Done',
              breadcrumbs: ['Dashboard', 'Operations'],
              initialFilters: {'dateFilter': 'Monthly', 'businessType': 'Rent'},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Verify breadcrumbs
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Operations'), findsOneWidget);
      expect(find.text('Site Visits Done'), findsOneWidget);

      // Verify header subtitle
      expect(find.text('Interactive drilldown analysis with automatic context inheritance.'), findsOneWidget);

      // Verify close button exists
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('3. Filter Inheritance and Date Dropdown Interaction in Dialog', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GenericKpiDrilldownDialog(
              kpiKey: 'available_inventory',
              kpiLabel: 'Available Inventory',
              breadcrumbs: ['Dashboard'],
              initialFilters: {'dateFilter': 'Weekly', 'businessType': 'Rent'},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Verify initial date filter value in UI
      expect(find.text('Weekly'), findsOneWidget);

      // Open date dropdown
      await tester.tap(find.text('Weekly'));
      await tester.pump(const Duration(milliseconds: 200));

      // Check dropdown options
      expect(find.text('Today').last, findsOneWidget);
      expect(find.text('Monthly').last, findsOneWidget);
      expect(find.text('Yearly').last, findsOneWidget);
    });

    test('4. Dynamic Dashboard Counts Evaluation in DashboardKpisResponse', () {
      final configs = [
        const KpiConfigItem(
          kpiKey: 'available_inventory',
          kpiLabel: 'Available Inventory',
          isEnabled: true,
          displayOrder: 1,
          pages: ['Admin Dashboard'],
          isSystem: true,
        ),
        const KpiConfigItem(
          kpiKey: 'custom_new_leads',
          kpiLabel: 'Custom New Leads',
          isEnabled: true,
          displayOrder: 2,
          pages: ['Admin Dashboard'],
          isSystem: false,
        ),
      ];

      final dashboardKpis = DashboardKpisResponse(
        config: configs,
        counts: const DashboardKpiCounts(availableInventory: 42),
        rawCounts: {
          'available_inventory': 42,
          'custom_new_leads': 15,
        },
      );

      expect(dashboardKpis.counts.availableInventory, equals(42));
      expect(dashboardKpis.getDynamicCount('custom_new_leads'), equals(15));
      expect(dashboardKpis.getDynamicCount('non_existent_kpi'), equals(0));
    });
  });
}
