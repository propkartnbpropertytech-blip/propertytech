import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/requirements/models/requirement_model.dart';
import 'package:propkart/features/reports/models/business_insight.dart';
import 'package:propkart/features/reports/models/report_configuration.dart';
import 'package:propkart/features/reports/models/report_data.dart';
import 'package:propkart/features/reports/models/report_date_range.dart';
import 'package:propkart/features/reports/models/report_filter_state.dart';
import 'package:propkart/features/reports/models/report_kpi_type.dart';
import 'package:propkart/features/reports/services/report_export_service.dart';

void main() {
  group('ReportExportService Compliance Tests', () {
    late DateTime now;
    late ReportOverallData sampleReportData;
    late ReportConfiguration sampleConfig;

    setUp(() {
      now = DateTime(2026, 7, 15, 12, 0, 0);

      final lead1 = RequirementModel(
        id: 'lead_1',
        clientName: 'Rahul Sharma',
        clientMobile: '9876543210',
        categoryId: 'cat_res',
        categoryName: 'Residential',
        propertyTypeId: 'type_apt',
        propertyTypeName: 'Apartment',
        minBudget: 5000000.0,
        maxBudget: 6000000.0,
        areaIds: const ['area_1'],
        areaNames: const ['Bodakdev'],
        status: 'Won',
        assignedTo: 'user_sales_1',
        assigneeName: 'Sanjay Patel',
        creatorName: 'Priya Shah',
        createdBy: 'user_tele_1',
        createdAt: now.subtract(const Duration(days: 2)),
      );

      final lead2 = RequirementModel(
        id: 'lead_2',
        clientName: 'Amit Verma',
        clientMobile: '9876543211',
        categoryId: 'cat_res',
        categoryName: 'Residential',
        propertyTypeId: 'type_villa',
        propertyTypeName: 'Villa',
        minBudget: 8000000.0,
        maxBudget: 9000000.0,
        areaIds: const ['area_2'],
        areaNames: const ['Satellite'],
        status: 'Site Visit',
        assignedTo: 'user_sales_1',
        assigneeName: 'Sanjay Patel',
        creatorName: 'Priya Shah',
        createdBy: 'user_tele_1',
        createdAt: now.subtract(const Duration(days: 1)),
      );

      final kpiMap = <ReportKpiType, KpiValue>{
        ReportKpiType.totalLeads: KpiValue.create(count: 2, percentage: 100.0, denominatorLabel: '100% of Total Leads'),
        ReportKpiType.leadsContacted: KpiValue.create(count: 2, percentage: 100.0, denominatorLabel: '% of Total Leads (2)'),
        ReportKpiType.leadsAssignedToSales: KpiValue.create(count: 2, percentage: 100.0, denominatorLabel: '% of Total Leads (2)'),
        ReportKpiType.leadQualificationRate: KpiValue.create(count: 2, percentage: 100.0, denominatorLabel: '% of Contacted Leads (2)'),
        ReportKpiType.siteVisitsScheduled: KpiValue.create(count: 2, percentage: 100.0, denominatorLabel: '% of Qualified Leads (2)'),
        ReportKpiType.siteVisitsDone: KpiValue.create(count: 1, percentage: 50.0, denominatorLabel: '% of Scheduled Visits (2)'),
        ReportKpiType.convertedToWon: KpiValue.create(count: 1, percentage: 50.0, denominatorLabel: '% of Assigned Leads (2)'),
        ReportKpiType.callAttempted: KpiValue.create(count: 5, percentage: 100.0, denominatorLabel: 'Total Attempts'),
        ReportKpiType.callPickedUp: KpiValue.create(count: 4, percentage: 80.0, denominatorLabel: '% of Call Attempted (5)'),
        ReportKpiType.callOpen: KpiValue.create(count: 1, percentage: 20.0, denominatorLabel: '% of Call Attempted (5)'),
        ReportKpiType.lostUnsuccessful: KpiValue.create(count: 0, percentage: 0.0, denominatorLabel: '% of Total Leads (2)'),
        ReportKpiType.telecallers: KpiValue.create(count: 1, percentage: 100.0, denominatorLabel: '% of 1 Telecallers'),
        ReportKpiType.salesUsers: KpiValue.create(count: 1, percentage: 100.0, denominatorLabel: '% of 1 Sales Users'),
      };

      sampleReportData = ReportOverallData(
        kpiValues: kpiMap,
        pipelineStages: [
          PipelineStageData(
            status: 'Won',
            displayName: 'Deal Won',
            count: 1,
            percentage: 50.0,
            color: const Color(0xFF16A34A),
            leads: [lead1],
          ),
          PipelineStageData(
            status: 'Site Visit',
            displayName: 'Visit Scheduled',
            count: 1,
            percentage: 50.0,
            color: const Color(0xFF7C3AED),
            leads: [lead2],
          ),
        ],
        funnelStages: [
          FunnelStageData(
            stageName: 'Total Leads',
            count: 2,
            stageConversionRate: 100.0,
            totalConversionRate: 100.0,
            color: const Color(0xFF14213D),
            leads: [lead1, lead2],
          ),
          FunnelStageData(
            stageName: 'Won',
            count: 1,
            stageConversionRate: 50.0,
            totalConversionRate: 50.0,
            color: const Color(0xFF16A34A),
            leads: [lead1],
          ),
        ],
        followupCategories: [
          FollowupCategoryData(
            categoryName: 'Due Today',
            count: 1,
            color: const Color(0xFFD97706),
            items: [
              FollowupItemData(
                id: 'f_1',
                leadName: 'Amit Verma',
                leadId: 'lead_2',
                clientMobile: '9876543211',
                assignedUserName: 'Sanjay Patel',
                followupDateTime: now,
                nextAction: 'Call Client',
                leadStatus: 'Site Visit',
              ),
            ],
          ),
        ],
        telecallerRankings: const [
          TeamMemberRanking(
            rank: 1,
            userId: 'user_tele_1',
            userName: 'Priya Shah',
            role: 'Telecaller',
            leadsCount: 2,
            contactedCount: 2,
            qualifiedCount: 2,
            siteVisitsCount: 2,
            wonCount: 1,
            conversionRate: 50.0,
          ),
        ],
        salesRankings: const [
          TeamMemberRanking(
            rank: 1,
            userId: 'user_sales_1',
            userName: 'Sanjay Patel',
            role: 'Sales',
            leadsCount: 2,
            contactedCount: 2,
            qualifiedCount: 2,
            siteVisitsCount: 2,
            wonCount: 1,
            conversionRate: 50.0,
          ),
        ],
        insights: const [
          BusinessInsightItem(
            id: 'ins_1',
            title: 'High Conversion in Residential',
            description: '50% conversion recorded in residential apartments.',
            category: InsightCategory.conversion,
            severity: InsightSeverity.success,
          ),
        ],
        growthComparisonItems: const [
          GrowthComparisonItem(
            kpiType: ReportKpiType.totalLeads,
            metricName: 'Total Leads',
            currentCount: 2,
            previousCount: 1,
            difference: 1,
            growthPercentage: 100.0,
            isPositive: true,
          ),
          GrowthComparisonItem(
            kpiType: ReportKpiType.convertedToWon,
            metricName: 'Won Leads',
            currentCount: 1,
            previousCount: 1,
            difference: 0,
            growthPercentage: 0.0,
            isPositive: true,
          ),
        ],
        leadSources: [
          LeadSourceData(
            source: 'Facebook Ads',
            count: 2,
            percentage: 100.0,
            color: const Color(0xFF2563EB),
            leads: [lead1, lead2],
          ),
        ],
        trendPoints: const [],
        filteredLeads: [lead1, lead2],
        availableStatuses: const ['Won', 'Site Visit'],
        availableSources: const ['Facebook Ads'],
        availableTelecallers: const [],
        availableSalesUsers: const [],
        availableProperties: const [],
      );

      sampleConfig = ReportConfiguration(
        dateRange: ReportDateRange(
          periodType: ReportPeriodType.monthly,
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 7, 31, 23, 59, 59),
        ),
        filters: const ReportFilterState(),
        kpiConfigs: ReportConfiguration.initial().kpiConfigs,
        showLeadStatusPipeline: true,
        showConversionFunnel: true,
        showFollowupAnalysis: true,
        showTeamRanking: true,
        showBusinessInsights: true,
        showGrowthComparison: true,
        showLeadSourceAnalysis: true,
        showTrendAnalysis: false,
        comparisonPeriod: GrowthComparisonPeriod.previousMonth,
      );
    });

    test('buildExcelDocument generates genuine Excel workbook with structured sheets', () {
      final excel = ReportExportService.buildExcelDocument(
        reportData: sampleReportData,
        config: sampleConfig,
      );

      // Verify workbook was created
      expect(excel, isNotNull);
      final sheets = excel.sheets.keys.toList();

      // Check required structured sheets exist
      expect(sheets.contains('Summary'), isTrue);
      expect(sheets.contains('KPIs'), isTrue);
      expect(sheets.contains('Lead Status'), isTrue);
      expect(sheets.contains('Conversion Funnel'), isTrue);
      expect(sheets.contains('Follow-ups'), isTrue);
      expect(sheets.contains('Team Ranking'), isTrue);
      expect(sheets.contains('Lead Sources'), isTrue);
      expect(sheets.contains('Growth & Comparison'), isTrue);
      expect(sheets.contains('Lead Details'), isTrue);

      // Verify Summary sheet content
      final summarySheet = excel['Summary'];
      expect(summarySheet.rows.isNotEmpty, isTrue);

      // Verify KPIs sheet contains rows
      final kpiSheet = excel['KPIs'];
      expect(kpiSheet.rows.length, greaterThan(1)); // Header + KPI rows

      // Verify Growth & Comparison sheet has comparison headers and rows
      final growthSheet = excel['Growth & Comparison'];
      expect(growthSheet.rows.length, greaterThan(2)); // Title + header + metric rows

      // Verify Team Ranking sheet has sales & telecaller rankings
      final teamSheet = excel['Team Ranking'];
      expect(teamSheet.rows.length, greaterThan(3));

      // Verify Lead Details sheet has row for each filtered lead
      final detailsSheet = excel['Lead Details'];
      expect(detailsSheet.rows.length, 3); // Header + 2 leads

      // Verify save produces non-empty bytes
      final bytes = excel.save();
      expect(bytes, isNotNull);
      expect(bytes!.isNotEmpty, isTrue);
    });

    test('buildExcelDocument respects section visibility toggles', () {
      final minimalConfig = sampleConfig.copyWith(
        showLeadStatusPipeline: false,
        showConversionFunnel: false,
        showFollowupAnalysis: false,
        showTeamRanking: false,
        showGrowthComparison: false,
        showLeadSourceAnalysis: false,
      );

      final excel = ReportExportService.buildExcelDocument(
        reportData: sampleReportData,
        config: minimalConfig,
      );

      final sheets = excel.sheets.keys.toList();
      expect(sheets.contains('Summary'), isTrue);
      expect(sheets.contains('KPIs'), isTrue);
      expect(sheets.contains('Lead Details'), isTrue);

      // Disabled sections should NOT have sheets
      expect(sheets.contains('Lead Status'), isFalse);
      expect(sheets.contains('Conversion Funnel'), isFalse);
      expect(sheets.contains('Follow-ups'), isFalse);
      expect(sheets.contains('Team Ranking'), isFalse);
      expect(sheets.contains('Growth & Comparison'), isFalse);
      expect(sheets.contains('Lead Sources'), isFalse);
    });

    test('generateCsvContent produces complete structured CSV respecting filters and toggles', () {
      final csvString = ReportExportService.generateCsvContent(
        reportData: sampleReportData,
        config: sampleConfig,
      );

      expect(csvString, isNotEmpty);
      expect(csvString.contains('PropKart CRM - Overall Business Insight Report'), isTrue);
      expect(csvString.contains('=== KEY PERFORMANCE INDICATORS ==='), isTrue);
      expect(csvString.contains('=== LEAD STATUS PIPELINE ==='), isTrue);
      expect(csvString.contains('=== CONVERSION FUNNEL ==='), isTrue);
      expect(csvString.contains('=== SALES TEAM RANKINGS ==='), isTrue);
      expect(csvString.contains('=== TELECALLER TEAM RANKINGS ==='), isTrue);
      expect(csvString.contains('=== GROWTH & COMPARISON'), isTrue);
      expect(csvString.contains('=== LEAD SOURCES ANALYSIS ==='), isTrue);
      expect(csvString.contains('=== FILTERED LEADS LIST ==='), isTrue);
      expect(csvString.contains('Rahul Sharma'), isTrue);
      expect(csvString.contains('Amit Verma'), isTrue);
    });

    test('buildPdfDocument compiles multi-page document without errors', () async {
      final pdf = ReportExportService.buildPdfDocument(
        reportData: sampleReportData,
        config: sampleConfig,
      );

      expect(pdf, isNotNull);
      final pdfBytes = await pdf.save();
      expect(pdfBytes.isNotEmpty, isTrue);
    });
  });
}
