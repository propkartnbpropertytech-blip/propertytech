import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/reports/models/report_kpi_type.dart';
import 'package:propkart/features/reports/models/report_configuration.dart';
import 'package:propkart/features/reports/models/business_insight_summary.dart';
import 'package:propkart/features/reports/services/report_data_engine.dart';

void main() {
  group('Site Visit Done KPI Tests', () {
    test('ReportKpiType.siteVisitsDone properties match design specifications', () {
      expect(ReportKpiType.siteVisitsDone.displayName, 'Site Visit Done');
      expect(ReportKpiType.siteVisitsDone.icon, Icons.location_on_rounded);
      expect(ReportKpiType.siteVisitsDone.defaultColor, const Color(0xFFEC4899));
      expect(ReportKpiType.siteVisitsDone.denominatorExplanation, '% of Total Leads');
    });

    test('ReportConfiguration campaignKpiTypes includes siteVisitsDone', () {
      expect(ReportConfiguration.campaignKpiTypes.contains(ReportKpiType.siteVisitsDone), isTrue);
      
      final config = ReportConfiguration.initial();
      final enabledTypes = config.enabledCampaignKpis.map((k) => k.type).toList();
      expect(enabledTypes.contains(ReportKpiType.siteVisitsDone), isTrue);
    });

    test('BusinessInsightSummary parses site_visit_done correctly', () {
      final json = {
        'total_leads': 100,
        'site_visit_done': 15,
        'leads_page_kpis': {
          'site_visit_done': 15,
        },
      };

      final summary = BusinessInsightSummary.fromJson(json);
      expect(summary.siteVisitDone, 15);
      expect(summary.leadsPageKpis.siteVisitDone, 15);
    });

    test('ReportDataEngine computes siteVisitsDone KPI with dynamic count and % of Total Leads', () {
      final config = ReportConfiguration.initial();
      final summary = BusinessInsightSummary.fromJson({
        'total_leads': 150,
        'site_visit_done': 15,
        'leads_page_kpis': {
          'site_visit_done': 15,
        },
      });

      final report = ReportDataEngine.computeReport(
        allLeads: [],
        allUsers: [],
        allProperties: [],
        allFollowups: [],
        systemStatuses: [],
        config: config,
        insightSummary: summary,
      );

      final kpi = report.kpiValues[ReportKpiType.siteVisitsDone];
      expect(kpi, isNotNull);
      expect(kpi!.count, 15);
      expect(kpi.percentage, 10.0); // 15 / 150 * 100 = 10%
      expect(kpi.denominatorLabel, '% of Total Leads (150)');
    });
  });
}
