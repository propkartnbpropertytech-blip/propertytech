import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/storage/isar_collections.dart';
import 'package:propkart/features/properties/models/property_model.dart';
import 'package:propkart/features/reports/models/report_configuration.dart';
import 'package:propkart/features/reports/models/report_data.dart';
import 'package:propkart/features/reports/models/report_date_range.dart';
import 'package:propkart/features/reports/models/report_filter_state.dart';
import 'package:propkart/features/reports/models/report_kpi_type.dart';
import 'package:propkart/features/reports/services/insight_generator.dart';
import 'package:propkart/features/reports/services/report_data_engine.dart';
import 'package:propkart/features/reports/services/report_export_service.dart';
import 'package:propkart/features/reports/utils/telecaller_report_navigation.dart';
import 'package:propkart/features/reports/widgets/conversion_analysis_section.dart';
import 'package:propkart/features/requirements/models/requirement_model.dart';
import 'package:propkart/features/users/models/user_model.dart';

void main() {
  group('Telecaller Report', () {
    late DateTime now;
    late List<UserModel> users;
    late List<PropertyModel> properties;
    late List<RequirementModel> leads;
    late List<FollowupLocal> followups;
    late List<String> statuses;
    late ReportConfiguration config;

    setUp(() {
      now = DateTime(2026, 9, 17, 12);

      users = [
        const UserModel(
          id: 'tele_1',
          roleId: 'role_tele',
          roleName: 'Telecaller',
          fullName: 'Rahul Sharma',
          email: 'rahul@example.com',
          mobile: '9000000001',
          isActive: true,
        ),
        const UserModel(
          id: 'tele_2',
          roleId: 'role_tele',
          roleName: 'Telecaller',
          fullName: 'Priya Shah',
          email: 'priya@example.com',
          isActive: true,
        ),
        const UserModel(
          id: 'sales_1',
          roleId: 'role_sales',
          roleName: 'Sales',
          fullName: 'Sanjay Patel',
          email: 'sanjay@example.com',
          isActive: true,
        ),
      ];

      properties = [
        PropertyModel.fromJson({
          'id': 'prop_1',
          'property_code': 'PROP001',
          'title': 'Skyline Heights',
          'price': 5000000.0,
          'category_id': 'cat_res',
          'property_type_id': 'type_apt',
          'city_id': 'city_ahm',
          'area_id': 'area_pra',
          'owner_name': 'Owner One',
          'owner_mobile': '9999999999',
          'created_at': now.subtract(const Duration(days: 10)).toIso8601String(),
        }),
      ];

      RequirementModel lead({
        required String id,
        required String name,
        required String status,
        required String createdBy,
        String? creatorName,
        String? source,
        DateTime? createdAt,
        String? assignedTo,
        String? nextFollowup,
      }) {
        return RequirementModel(
          id: id,
          clientName: name,
          clientMobile: '98${id.hashCode.abs() % 100000000}',
          categoryId: 'cat_res',
          categoryName: 'Residential',
          propertyTypeId: 'type_apt',
          propertyTypeName: 'Apartment',
          minBudget: 4000000,
          maxBudget: 5000000,
          areaIds: const ['area_pra'],
          areaNames: const ['Prahlad Nagar'],
          status: status,
          assignedTo: assignedTo ?? 'sales_1',
          assigneeName: 'Sanjay Patel',
          creatorName: creatorName,
          createdBy: createdBy,
          createdAt: createdAt ?? now.subtract(const Duration(days: 2)),
          leadSource: source,
          nextFollowupDate: nextFollowup,
        );
      }

      leads = [
        lead(
          id: 'lead_assigned',
          name: 'Assigned Client',
          status: 'New',
          createdBy: 'tele_1',
          creatorName: 'Rahul Sharma',
          source: 'Website',
        ),
        lead(
          id: 'lead_contacted',
          name: 'Contacted Client',
          status: 'contacted',
          createdBy: 'tele_1',
          creatorName: 'Rahul Sharma',
          source: 'Facebook',
        ),
        lead(
          id: 'lead_qualified',
          name: 'Qualified Client',
          status: 'interested',
          createdBy: 'tele_1',
          creatorName: 'Rahul Sharma',
          source: 'Website',
        ),
        lead(
          id: 'lead_visit',
          name: 'Visit Client',
          status: 'site visit',
          createdBy: 'tele_1',
          creatorName: 'Rahul Sharma',
          source: 'Referral',
        ),
        lead(
          id: 'lead_won',
          name: 'Won Client',
          status: 'Won',
          createdBy: 'tele_1',
          creatorName: 'Rahul Sharma',
          source: 'Website',
        ),
        lead(
          id: 'lead_lost',
          name: 'Lost Client',
          status: 'lost',
          createdBy: 'tele_1',
          creatorName: 'Rahul Sharma',
          source: 'Portal',
        ),
        lead(
          id: 'lead_other',
          name: 'Priya Client',
          status: 'Won',
          createdBy: 'tele_2',
          creatorName: 'Priya Shah',
          source: 'Website',
        ),
        lead(
          id: 'lead_old',
          name: 'Old Client',
          status: 'contacted',
          createdBy: 'tele_1',
          creatorName: 'Rahul Sharma',
          source: 'Website',
          createdAt: now.subtract(const Duration(days: 60)),
        ),
      ];

      followups = [
        FollowupLocal()
          ..id = 'f_attempt'
          ..clientName = 'Contacted Client'
          ..mobile = '9800000001'
          ..createdBy = 'tele_1'
          ..requirementId = 'lead_contacted'
          ..followupDate = now.add(const Duration(hours: 2))
          ..createdAt = now.subtract(const Duration(hours: 3))
          ..status = 'connected',
        FollowupLocal()
          ..id = 'f_open'
          ..clientName = 'Assigned Client'
          ..mobile = '9800000002'
          ..createdBy = 'tele_1'
          ..requirementId = 'lead_assigned'
          ..followupDate = now.subtract(const Duration(days: 1))
          ..createdAt = now.subtract(const Duration(days: 1))
          ..status = 'open',
        FollowupLocal()
          ..id = 'f_pending'
          ..clientName = 'Qualified Client'
          ..mobile = '9800000003'
          ..createdBy = 'tele_1'
          ..requirementId = 'lead_qualified'
          ..followupDate = now.add(const Duration(days: 2))
          ..createdAt = now
          ..status = 'pending',
        FollowupLocal()
          ..id = 'f_other'
          ..clientName = 'Priya Client'
          ..mobile = '9800000004'
          ..createdBy = 'tele_2'
          ..requirementId = 'lead_other'
          ..followupDate = now
          ..createdAt = now
          ..status = 'connected',
      ];

      statuses = [
        'New',
        'contacted',
        'interested',
        'site visit',
        'Won',
        'lost',
      ];

      config = ReportConfiguration.initial().copyWith(
        dateRange: ReportDateRange(
          periodType: ReportPeriodType.monthly,
          subOption: ReportSubPeriodOption.current,
          startDate: DateTime(2026, 9, 1),
          endDate: DateTime(2026, 9, 30, 23, 59, 59),
        ),
      );
    });

    ReportOverallData rahulReport({ReportConfiguration? override}) {
      return ReportDataEngine.computeTelecallerReport(
        telecallerId: 'tele_1',
        telecallerName: 'Rahul Sharma',
        config: override ?? config,
        allLeads: leads,
        allUsers: users,
        allProperties: properties,
        allFollowups: followups,
        systemStatuses: statuses,
      );
    }

    test('navigation helper encodes selected telecaller without resetting path', () {
      final location = TelecallerReportNavigation.location(
        userId: 'tele_1',
        userName: 'Rahul Sharma',
      );
      expect(location, contains('/reports/leads/telecaller'));
      expect(location, contains('userId=tele_1'));
      expect(Uri.parse(location).queryParameters['userName'], 'Rahul Sharma');
    });

    test('direct selection and OBI drill-down retain the same telecaller subject', () {
      final fromObi = config.copyWith(
        subjectTelecallerId: 'tele_1',
        subjectTelecallerName: 'Rahul Sharma',
      );
      expect(fromObi.subjectTelecallerId, 'tele_1');
      expect(fromObi.dateRange.startDate, config.dateRange.startDate);

      final switched = fromObi.copyWith(
        subjectTelecallerId: 'tele_2',
        subjectTelecallerName: 'Priya Shah',
      );
      expect(switched.subjectTelecallerId, 'tele_2');
      expect(switched.dateRange, fromObi.dateRange);
      expect(switched.filters, fromObi.filters);
    });

    test('metrics are scoped to the selected telecaller only', () {
      final report = rahulReport();

      expect(report.kpiValues[ReportKpiType.totalLeads]?.count, 6);
      expect(report.kpiValues[ReportKpiType.leadsContacted]?.count, 4);
      expect(report.kpiValues[ReportKpiType.leadQualificationRate]?.count, 3);
      expect(report.kpiValues[ReportKpiType.siteVisitsScheduled]?.count, 1);
      expect(report.kpiValues[ReportKpiType.siteVisitsDone]?.count, 1);
      expect(report.kpiValues[ReportKpiType.convertedToWon]?.count, 1);
      expect(report.kpiValues[ReportKpiType.lostUnsuccessful]?.count, 1);
      expect(report.kpiValues[ReportKpiType.callAttempted]?.count, 3);
      expect(report.kpiValues[ReportKpiType.callPickedUp]?.count, 1);
      expect(report.kpiValues[ReportKpiType.callOpen]?.count, 2);

      expect(report.filteredLeads.every((l) => l.createdBy == 'tele_1'), isTrue);
      expect(report.filteredLeads.any((l) => l.id == 'lead_other'), isFalse);
      expect(report.followupCategories.first.count, greaterThan(0));
    });

    test('contacted and pickup percentages use existing business denominators', () {
      final report = rahulReport();
      final assigned = report.kpiValues[ReportKpiType.totalLeads]!.count;
      final contacted = report.kpiValues[ReportKpiType.leadsContacted]!;
      expect(contacted.percentage, closeTo(contacted.count / assigned * 100, 0.01));

      final attempted = report.kpiValues[ReportKpiType.callAttempted]!.count;
      final picked = report.kpiValues[ReportKpiType.callPickedUp]!;
      expect(picked.percentage, closeTo(picked.count / attempted * 100, 0.01));
    });

    test('date and source filters change the telecaller report', () {
      final weekly = rahulReport(
        override: config.copyWith(
          dateRange: ReportDateRange(
            periodType: ReportPeriodType.customRange,
            subOption: ReportSubPeriodOption.custom,
            startDate: now.subtract(const Duration(hours: 1)),
            endDate: now.add(const Duration(hours: 1)),
          ),
        ),
      );
      expect(weekly.kpiValues[ReportKpiType.totalLeads]?.count, 0);

      final websiteOnly = rahulReport(
        override: config.copyWith(
          filters: const ReportFilterState(leadSource: 'Website'),
        ),
      );
      expect(websiteOnly.filteredLeads.every((l) => (l.leadSource ?? '') == 'Website'), isTrue);
      expect(websiteOnly.kpiValues[ReportKpiType.totalLeads]?.count, 3);
    });

    test('conversion funnel uses assigned leads and telecaller-only stages', () {
      final report = rahulReport();
      expect(report.funnelStages.first.stageName, 'Assigned Leads');
      expect(report.funnelStages.first.count, 6);
      expect(report.funnelStages.last.stageName, 'Won');
      expect(report.funnelStages.last.count, 1);
    });

    test('lead status stages come from data and support drill-down leads', () {
      final report = rahulReport();
      expect(report.pipelineStages, isNotEmpty);
      expect(report.pipelineStages.every((s) => s.count > 0), isTrue);
      final won = report.pipelineStages.firstWhere((s) => s.status.toLowerCase() == 'won');
      expect(won.count, 1);
      expect(won.leads.single.id, 'lead_won');
    });

    test('comparison periods compute current vs previous for the telecaller', () {
      for (final period in [
        GrowthComparisonPeriod.previousDay,
        GrowthComparisonPeriod.previousWeek,
        GrowthComparisonPeriod.previousMonth,
        GrowthComparisonPeriod.previousYear,
        GrowthComparisonPeriod.customPeriod,
      ]) {
        final report = rahulReport(
          override: config.copyWith(
            comparisonPeriod: period,
            customComparisonStart: DateTime(2026, 8, 1),
            customComparisonEnd: DateTime(2026, 8, 31),
          ),
        );
        expect(report.growthComparisonItems, isNotEmpty);
        final assigned = report.growthComparisonItems.firstWhere(
          (i) => i.kpiType == ReportKpiType.totalLeads,
        );
        expect(assigned.metricName, 'Leads Assigned');
        expect(assigned.currentCount, 6);
      }
    });

    test('lead source performance includes qualified, visits, and won when data exists', () {
      final report = rahulReport();
      final website = report.leadSources.firstWhere((s) => s.source == 'Website');
      expect(website.count, 3);
      expect(website.qualifiedCount, greaterThan(0));
      expect(website.wonCount, 1);
    });

    test('conversion analysis rates are derived from the same KPI denominators', () {
      final report = rahulReport();
      final rates = ConversionAnalysisSection.ratesFrom(report);
      expect(rates.map((r) => r.label), containsAll([
        'Contact Rate',
        'Call Pickup Rate',
        'Qualification Rate',
        'Site Visit Scheduled Rate',
        'Site Visit Completion Rate',
        'Won Conversion Rate',
        'Lost Rate',
      ]));
      final contact = rates.firstWhere((r) => r.label == 'Contact Rate');
      expect(contact.percentage, report.kpiValues[ReportKpiType.leadsContacted]!.percentage);
    });

    test('telecaller insights skip team rankings and require sufficient data', () {
      final emptyInsights = InsightGenerator.generateTelecallerInsights(
        telecallerName: 'Rahul Sharma',
        assignedCount: 0,
        contactedCount: 0,
        qualifiedCount: 0,
        visitsScheduledCount: 0,
        visitsDoneCount: 0,
        wonCount: 0,
        lostCount: 0,
        callAttemptedCount: 0,
        callPickedUpCount: 0,
        callOpenCount: 0,
        overdueFollowupsCount: 0,
        growthItems: const [],
      );
      expect(emptyInsights, isEmpty);

      final report = rahulReport();
      expect(report.insights.any((i) => i.id == 'insight_top_sales'), isFalse);
      expect(report.insights.any((i) => i.id == 'insight_top_telecaller'), isFalse);
    });

    test('export PDF, Excel, CSV, and print payloads include the selected telecaller', () {
      final report = rahulReport();
      final exportConfig = config.copyWith(
        showTeamRanking: false,
        showGrowthComparison: true,
        filters: config.filters.copyWith(
          telecallerId: 'tele_1',
          telecallerName: 'Rahul Sharma',
        ),
      );

      final csv = ReportExportService.generateCsvContent(
        reportData: report,
        config: exportConfig,
        reportTitle: 'PropKart CRM - Telecaller Report',
        subjectLabel: 'Telecaller: Rahul Sharma',
      );
      expect(csv.contains('PropKart CRM - Telecaller Report'), isTrue);
      expect(csv.contains('Telecaller: Rahul Sharma'), isTrue);
      expect(csv.contains('Assigned Client'), isTrue);
      expect(csv.contains('Priya Client'), isFalse);

      final excel = ReportExportService.buildExcelDocument(
        reportData: report,
        config: exportConfig,
        reportTitle: 'PropKart CRM - Telecaller Report',
        subjectLabel: 'Telecaller: Rahul Sharma',
      );
      final bytes = excel.save();
      expect(bytes, isNotNull);
      expect(bytes!.isNotEmpty, isTrue);
      expect(excel['Summary'].rows.isNotEmpty, isTrue);
      expect(
        excel['Summary'].rows.first.map((c) => c?.value?.toString() ?? '').join(' '),
        contains('Telecaller Report'),
      );

      final pdf = ReportExportService.buildPdfDocument(
        reportData: report,
        config: exportConfig,
        reportTitle: 'PropKart CRM - Telecaller Report',
        subjectLabel: 'Telecaller: Rahul Sharma',
      );
      expect(pdf, isNotNull);
    });

    test('OBI telecaller filter does not leak other telecaller leads into the report', () {
      final priya = ReportDataEngine.computeTelecallerReport(
        telecallerId: 'tele_2',
        telecallerName: 'Priya Shah',
        config: config,
        allLeads: leads,
        allUsers: users,
        allProperties: properties,
        allFollowups: followups,
        systemStatuses: statuses,
      );
      expect(priya.kpiValues[ReportKpiType.totalLeads]?.count, 1);
      expect(priya.filteredLeads.single.id, 'lead_other');
      expect(priya.kpiValues[ReportKpiType.callAttempted]?.count, 1);
    });
  });
}
