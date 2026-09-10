import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/requirements/models/requirement_model.dart';
import 'package:propkart/features/users/models/user_model.dart';
import 'package:propkart/features/properties/models/property_model.dart';
import 'package:propkart/core/storage/isar_collections.dart';
import 'package:propkart/features/reports/models/report_kpi_type.dart';
import 'package:propkart/features/reports/models/report_date_range.dart';
import 'package:propkart/features/reports/models/report_configuration.dart';
import 'package:propkart/features/reports/services/report_data_engine.dart';

void main() {
  group('ReportDataEngine Tests', () {
    late DateTime now;
    late List<UserModel> sampleUsers;
    late List<PropertyModel> sampleProperties;
    late List<RequirementModel> sampleLeads;
    late List<FollowupLocal> sampleFollowups;
    late List<String> systemStatuses;
    late ReportConfiguration defaultConfig;

    setUp(() {
      now = DateTime.now();

      sampleUsers = [
        const UserModel(
          id: 'tele_1',
          roleId: 'role_tele',
          roleName: 'Telecaller',
          fullName: 'Alice Telecaller',
          email: 'alice@example.com',
          isActive: true,
        ),
        const UserModel(
          id: 'sales_1',
          roleId: 'role_sales',
          roleName: 'Sales',
          fullName: 'Bob Sales',
          email: 'bob@example.com',
          isActive: true,
        ),
      ];

      sampleProperties = [
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

      sampleLeads = [
        RequirementModel(
          id: 'lead_1',
          clientName: 'Charlie Client',
          clientMobile: '9876543210',
          categoryId: 'cat_res',
          categoryName: 'Residential',
          propertyTypeId: 'type_apt',
          propertyTypeName: 'Apartment',
          minBudget: 5000000.0,
          maxBudget: 5000000.0,
          areaIds: const ['area_pra'],
          areaNames: const ['Prahlad Nagar'],
          status: 'deal closed',
          assignedTo: 'sales_1',
          assigneeName: 'Bob Sales',
          creatorName: 'Alice Telecaller',
          createdBy: 'tele_1',
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        RequirementModel(
          id: 'lead_2',
          clientName: 'David Client',
          clientMobile: '9876543211',
          categoryId: 'cat_res',
          categoryName: 'Residential',
          propertyTypeId: 'type_villa',
          propertyTypeName: 'Villa',
          minBudget: 3000000.0,
          maxBudget: 3000000.0,
          areaIds: const ['area_pra'],
          areaNames: const ['Prahlad Nagar'],
          status: 'site visit',
          assignedTo: 'sales_1',
          assigneeName: 'Bob Sales',
          creatorName: 'Alice Telecaller',
          createdBy: 'tele_1',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
        RequirementModel(
          id: 'lead_3',
          clientName: 'Eve Client',
          clientMobile: '9876543212',
          categoryId: 'cat_res',
          categoryName: 'Residential',
          propertyTypeId: 'type_apt',
          propertyTypeName: 'Apartment',
          minBudget: 4000000.0,
          maxBudget: 4000000.0,
          areaIds: const ['area_pra'],
          areaNames: const ['Prahlad Nagar'],
          status: 'contacted',
          assignedTo: 'sales_1',
          assigneeName: 'Bob Sales',
          creatorName: 'Alice Telecaller',
          createdBy: 'tele_1',
          createdAt: now.subtract(const Duration(days: 3)),
        ),
        RequirementModel(
          id: 'lead_4',
          clientName: 'Frank Client',
          clientMobile: '9876543213',
          categoryId: 'cat_res',
          categoryName: 'Residential',
          propertyTypeId: 'type_plot',
          propertyTypeName: 'Plot',
          minBudget: 2000000.0,
          maxBudget: 2000000.0,
          areaIds: const ['area_pra'],
          areaNames: const ['Prahlad Nagar'],
          status: 'lost',
          assignedTo: null,
          createdAt: now.subtract(const Duration(days: 4)),
        ),
        RequirementModel(
          id: 'lead_5',
          clientName: 'Grace Client',
          clientMobile: '9876543214',
          categoryId: 'cat_res',
          categoryName: 'Residential',
          propertyTypeId: 'type_apt',
          propertyTypeName: 'Apartment',
          minBudget: 6000000.0,
          maxBudget: 6000000.0,
          areaIds: const ['area_pra'],
          areaNames: const ['Prahlad Nagar'],
          status: 'negotiation',
          assignedTo: 'sales_1',
          assigneeName: 'Bob Sales',
          creatorName: 'Alice Telecaller',
          createdBy: 'tele_1',
          createdAt: now.subtract(const Duration(days: 15)), // Outside 7-day range
        ),
      ];

      sampleFollowups = [
        FollowupLocal()
          ..id = 'f_1'
          ..clientName = 'Charlie Client'
          ..mobile = '9876543210'
          ..createdBy = 'sales_1'
          ..followupDate = now.add(const Duration(hours: 4))
          ..createdAt = now
          ..status = 'pending',
        FollowupLocal()
          ..id = 'f_2'
          ..clientName = 'David Client'
          ..mobile = '9876543211'
          ..createdBy = 'sales_1'
          ..followupDate = now.subtract(const Duration(days: 1))
          ..createdAt = now.subtract(const Duration(days: 2))
          ..status = 'pending',
        FollowupLocal()
          ..id = 'f_3'
          ..clientName = 'Eve Client'
          ..mobile = '9876543212'
          ..createdBy = 'sales_1'
          ..followupDate = now.add(const Duration(days: 3))
          ..createdAt = now
          ..status = 'pending',
      ];

      systemStatuses = [
        'new lead',
        'contacted',
        'site visit',
        'negotiation',
        'deal closed',
        'lost',
      ];

      defaultConfig = ReportConfiguration.initial().copyWith(
        dateRange: ReportDateRange(
          periodType: ReportPeriodType.monthly,
          subOption: ReportSubPeriodOption.current,
          startDate: now.subtract(const Duration(days: 30)),
          endDate: now.add(const Duration(days: 1)),
        ),
      );
    });

    test('All 13 KPIs compute correct counts and percentages with accurate denominators', () {
      final report = ReportDataEngine.computeReport(
        allLeads: sampleLeads,
        allUsers: sampleUsers,
        allProperties: sampleProperties,
        allFollowups: sampleFollowups,
        systemStatuses: systemStatuses,
        config: defaultConfig,
      );

      expect(report.kpiValues.length, 13);

      // 1. Total Leads: 5 leads
      final totalLeads = report.kpiValues[ReportKpiType.totalLeads]!;
      expect(totalLeads.count, 5);
      expect(totalLeads.percentage, 100.0);

      // 2. Telecallers: 1 telecaller
      final telecallers = report.kpiValues[ReportKpiType.telecallers]!;
      expect(telecallers.count, 1);

      // 3. Sales Users: 1 sales user
      final salesUsers = report.kpiValues[ReportKpiType.salesUsers]!;
      expect(salesUsers.count, 1);

      // 4. Leads Contacted: Charlie, David, Eve, Grace = 4
      final contactedLeads = report.kpiValues[ReportKpiType.leadsContacted]!;
      expect(contactedLeads.count, 4);
      expect(contactedLeads.percentage, 80.0); // 4 / 5 * 100

      // 5. Leads Assigned to Sales: 4 leads assigned to sales_1
      final assigned = report.kpiValues[ReportKpiType.leadsAssignedToSales]!;
      expect(assigned.count, 4);
      expect(assigned.percentage, 80.0);

      // 6. Lead Qualification Rate: 3 qualified / 4 contacted = 75.0%
      final qualRate = report.kpiValues[ReportKpiType.leadQualificationRate]!;
      expect(qualRate.count, 3);
      expect(qualRate.percentage, 75.0);

      // 7. Site Visits Done: 2 visits done
      final siteVisits = report.kpiValues[ReportKpiType.siteVisitsDone]!;
      expect(siteVisits.count, 2);

      // 8. Converted to Won: Charlie = 1 / 4 assigned = 25.0%
      final won = report.kpiValues[ReportKpiType.convertedToWon]!;
      expect(won.count, 1);
      expect(won.percentage, 25.0); // 1 / 4 * 100

      // 9. Lost / Unsuccessful: Frank = 1 / 5 total = 20.0%
      final lost = report.kpiValues[ReportKpiType.lostUnsuccessful]!;
      expect(lost.count, 1);
      expect(lost.percentage, 20.0); // 1 / 5 * 100
    });

    test('Dynamic Lead Status Pipeline discovers all statuses with counts and percentages', () {
      final report = ReportDataEngine.computeReport(
        allLeads: sampleLeads,
        allUsers: sampleUsers,
        allProperties: sampleProperties,
        allFollowups: sampleFollowups,
        systemStatuses: systemStatuses,
        config: defaultConfig,
      );

      expect(report.pipelineStages.isNotEmpty, true);

      final dealClosedStage = report.pipelineStages.firstWhere((s) => s.status.toLowerCase() == 'deal closed');
      expect(dealClosedStage.count, 1);
      expect(dealClosedStage.percentage, 20.0);

      final lostStage = report.pipelineStages.firstWhere((s) => s.status.toLowerCase() == 'lost');
      expect(lostStage.count, 1);
      expect(lostStage.percentage, 20.0);
    });

    test('Conversion Funnel computes progression stages with step-to-step ratios', () {
      final report = ReportDataEngine.computeReport(
        allLeads: sampleLeads,
        allUsers: sampleUsers,
        allProperties: sampleProperties,
        allFollowups: sampleFollowups,
        systemStatuses: systemStatuses,
        config: defaultConfig,
      );

      expect(report.funnelStages.length, 6);
      expect(report.funnelStages[0].stageName, 'Total Leads');
      expect(report.funnelStages[0].count, 5);
      expect(report.funnelStages[0].totalConversionRate, 100.0);

      expect(report.funnelStages[1].stageName, 'Contacted');
      expect(report.funnelStages[1].count, 4);

      expect(report.funnelStages.last.stageName, 'Won');
      expect(report.funnelStages.last.count, 1);
    });

    test('Follow-up Analysis categorizes into Overdue, Today, Upcoming, and Pending', () {
      final report = ReportDataEngine.computeReport(
        allLeads: sampleLeads,
        allUsers: sampleUsers,
        allProperties: sampleProperties,
        allFollowups: sampleFollowups,
        systemStatuses: systemStatuses,
        config: defaultConfig,
      );

      expect(report.followupCategories.length, 4);

      final overdue = report.followupCategories.firstWhere((c) => c.categoryName.toLowerCase().contains('overdue'));
      expect(overdue.items.length, 1); // f_2 is yesterday

      final today = report.followupCategories.firstWhere((c) => c.categoryName.toLowerCase().contains('today'));
      expect(today.items.length, 1); // f_1 is in 4 hours today

      final upcoming = report.followupCategories.firstWhere((c) => c.categoryName.toLowerCase().contains('upcoming'));
      expect(upcoming.items.length, 1); // f_3 is in 3 days
    });

    test('Team Ranking separates Telecallers and Sales Users and sorts correctly', () {
      final report = ReportDataEngine.computeReport(
        allLeads: sampleLeads,
        allUsers: sampleUsers,
        allProperties: sampleProperties,
        allFollowups: sampleFollowups,
        systemStatuses: systemStatuses,
        config: defaultConfig,
      );

      expect(report.telecallerRankings.length, 1);
      expect(report.telecallerRankings.first.userName, 'Alice Telecaller');
      expect(report.telecallerRankings.first.leadsCount, 4);

      expect(report.salesRankings.length, 1);
      expect(report.salesRankings.first.userName, 'Bob Sales');
      expect(report.salesRankings.first.leadsCount, 4);
      expect(report.salesRankings.first.wonCount, 1);
    });

    test('Date Filter correctly excludes leads outside range', () {
      final weeklyConfig = defaultConfig.copyWith(
        dateRange: ReportDateRange(
          periodType: ReportPeriodType.weekly,
          subOption: ReportSubPeriodOption.current,
          startDate: now.subtract(const Duration(days: 7)),
          endDate: now.add(const Duration(days: 1)),
        ),
      );

      final report = ReportDataEngine.computeReport(
        allLeads: sampleLeads,
        allUsers: sampleUsers,
        allProperties: sampleProperties,
        allFollowups: sampleFollowups,
        systemStatuses: systemStatuses,
        config: weeklyConfig,
      );

      // Grace was created 15 days ago, so only 4 leads in range
      expect(report.filteredLeads.length, 4);
      expect(report.kpiValues[ReportKpiType.totalLeads]!.count, 4);
    });

    group('Growth & Comparison Mode Tests', () {
      test('Growth & Comparison returns empty when master toggle is OFF', () {
        final offConfig = defaultConfig.copyWith(showGrowthComparison: false);
        final report = ReportDataEngine.computeReport(
          allLeads: sampleLeads,
          allUsers: sampleUsers,
          allProperties: sampleProperties,
          allFollowups: sampleFollowups,
          systemStatuses: systemStatuses,
          config: offConfig,
        );

        expect(report.growthComparisonItems, isEmpty);
      });

      test('Growth & Comparison Previous Day mode computes comparison against previous day', () {
        final dayConfig = defaultConfig.copyWith(
          showGrowthComparison: true,
          comparisonPeriod: GrowthComparisonPeriod.previousDay,
          dateRange: ReportDateRange(
            periodType: ReportPeriodType.today,
            startDate: DateTime(now.year, now.month, now.day, 0, 0, 0),
            endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
          ),
        );

        final report = ReportDataEngine.computeReport(
          allLeads: sampleLeads,
          allUsers: sampleUsers,
          allProperties: sampleProperties,
          allFollowups: sampleFollowups,
          systemStatuses: systemStatuses,
          config: dayConfig,
        );

        expect(report.growthComparisonItems, isNotEmpty);
        final totalLeadsItem = report.growthComparisonItems.firstWhere((i) => i.kpiType == ReportKpiType.totalLeads);
        expect(totalLeadsItem.metricName, 'Total Leads');
        expect(totalLeadsItem.currentCount, isA<num>());
        expect(totalLeadsItem.previousCount, isA<num>());
        expect(totalLeadsItem.difference, totalLeadsItem.currentCount - totalLeadsItem.previousCount);
      });

      test('Growth & Comparison Previous Week mode computes comparison against previous week', () {
        final weekConfig = defaultConfig.copyWith(
          showGrowthComparison: true,
          comparisonPeriod: GrowthComparisonPeriod.previousWeek,
          dateRange: ReportDateRange(
            periodType: ReportPeriodType.weekly,
            startDate: now.subtract(const Duration(days: 7)),
            endDate: now,
          ),
        );

        final report = ReportDataEngine.computeReport(
          allLeads: sampleLeads,
          allUsers: sampleUsers,
          allProperties: sampleProperties,
          allFollowups: sampleFollowups,
          systemStatuses: systemStatuses,
          config: weekConfig,
        );

        expect(report.growthComparisonItems, isNotEmpty);
        expect(report.growthComparisonItems.any((i) => i.kpiType == ReportKpiType.totalLeads), isTrue);
      });

      test('Growth & Comparison Previous Month mode computes calendar month comparison', () {
        final monthConfig = defaultConfig.copyWith(
          showGrowthComparison: true,
          comparisonPeriod: GrowthComparisonPeriod.previousMonth,
          dateRange: ReportDateRange(
            periodType: ReportPeriodType.monthly,
            startDate: DateTime(now.year, now.month, 1),
            endDate: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
          ),
        );

        final report = ReportDataEngine.computeReport(
          allLeads: sampleLeads,
          allUsers: sampleUsers,
          allProperties: sampleProperties,
          allFollowups: sampleFollowups,
          systemStatuses: systemStatuses,
          config: monthConfig,
        );

        expect(report.growthComparisonItems, isNotEmpty);
      });

      test('Growth & Comparison Previous Year mode computes calendar year comparison', () {
        final yearConfig = defaultConfig.copyWith(
          showGrowthComparison: true,
          comparisonPeriod: GrowthComparisonPeriod.previousYear,
          dateRange: ReportDateRange(
            periodType: ReportPeriodType.yearly,
            startDate: DateTime(now.year, 1, 1),
            endDate: DateTime(now.year, 12, 31, 23, 59, 59),
          ),
        );

        final report = ReportDataEngine.computeReport(
          allLeads: sampleLeads,
          allUsers: sampleUsers,
          allProperties: sampleProperties,
          allFollowups: sampleFollowups,
          systemStatuses: systemStatuses,
          config: yearConfig,
        );

        expect(report.growthComparisonItems, isNotEmpty);
      });

      test('Growth & Comparison Custom Period mode respects independent custom dates', () {
        final customConfig = defaultConfig.copyWith(
          showGrowthComparison: true,
          comparisonPeriod: GrowthComparisonPeriod.customPeriod,
          customComparisonStart: now.subtract(const Duration(days: 30)),
          customComparisonEnd: now.subtract(const Duration(days: 20)),
          dateRange: ReportDateRange(
            periodType: ReportPeriodType.customRange,
            startDate: now.subtract(const Duration(days: 10)),
            endDate: now,
          ),
        );

        final report = ReportDataEngine.computeReport(
          allLeads: sampleLeads,
          allUsers: sampleUsers,
          allProperties: sampleProperties,
          allFollowups: sampleFollowups,
          systemStatuses: systemStatuses,
          config: customConfig,
        );

        expect(report.growthComparisonItems, isNotEmpty);
      });

      test('Growth calculation handles zero previous value with positive current as 100%', () {
        // Only 1 lead today, 0 leads in custom comparison range
        final customConfig = defaultConfig.copyWith(
          showGrowthComparison: true,
          comparisonPeriod: GrowthComparisonPeriod.customPeriod,
          customComparisonStart: DateTime(2020, 1, 1),
          customComparisonEnd: DateTime(2020, 1, 2),
        );

        final report = ReportDataEngine.computeReport(
          allLeads: sampleLeads,
          allUsers: sampleUsers,
          allProperties: sampleProperties,
          allFollowups: sampleFollowups,
          systemStatuses: systemStatuses,
          config: customConfig,
        );

        final totalLeadsItem = report.growthComparisonItems.firstWhere((i) => i.kpiType == ReportKpiType.totalLeads);
        expect(totalLeadsItem.previousCount, 0);
        expect(totalLeadsItem.currentCount, greaterThan(0));
        expect(totalLeadsItem.growthPercentage, 100.0);
        expect(totalLeadsItem.isPositive, isTrue);
      });
    });

    group('User Drill-Down Performance Summary Tests', () {
      test('computeUserPerformanceSummary calculates 13 metrics for Telecaller', () {
        final summary = ReportDataEngine.computeUserPerformanceSummary(
          userId: 'tele_1',
          userName: 'Alice Telecaller',
          role: 'Telecaller',
          config: defaultConfig,
          allLeads: sampleLeads,
          allFollowups: sampleFollowups,
        );

        expect(summary.userId, 'tele_1');
        expect(summary.userName, 'Alice Telecaller');
        expect(summary.role, 'Telecaller');
        expect(summary.leadsHandled, 4);
        expect(summary.leadsContacted, 4);
        expect(summary.qualifiedLeads, 3);
        expect(summary.siteVisits, 3);
        expect(summary.wonLeads, 1);
        expect(summary.conversionPercentage, 25.0); // 1 / 4 * 100
        expect(summary.lostLeads, 0);
        expect(summary.callAttempted, 0);
        expect(summary.dateRangeLabel, isNotEmpty);
      });

      test('computeUserPerformanceSummary calculates 13 metrics for Sales User', () {
        final summary = ReportDataEngine.computeUserPerformanceSummary(
          userId: 'sales_1',
          userName: 'Bob Sales',
          role: 'Sales',
          config: defaultConfig,
          allLeads: sampleLeads,
          allFollowups: sampleFollowups,
        );

        expect(summary.userId, 'sales_1');
        expect(summary.userName, 'Bob Sales');
        expect(summary.role, 'Sales');
        expect(summary.leadsHandled, 4);
        expect(summary.wonLeads, 1);
        expect(summary.conversionPercentage, 25.0);
        expect(summary.callAttempted, 3);
      });
    });

    group('Lead Status Change Options & Filter Matching Tests', () {
      test('Dynamic pipeline discovers Call Attempted and Rejected variants with proper ordering', () {
        final callAttemptedLeads = [
          RequirementModel(
            id: 'call_1',
            clientName: 'Call Lead 1',
            clientMobile: '9111111111',
            categoryId: 'cat_res',
            categoryName: 'Residential',
            propertyTypeId: 'type_apt',
            propertyTypeName: 'Apartment',
            minBudget: 1000000.0,
            maxBudget: 2000000.0,
            areaIds: const ['area_1'],
            areaNames: const ['Area 1'],
            status: 'Call Attempted (Picked Up)',
            assignedTo: 'sales_1',
            createdAt: now.subtract(const Duration(days: 1)),
          ),
          RequirementModel(
            id: 'call_2',
            clientName: 'Call Lead 2',
            clientMobile: '9222222222',
            categoryId: 'cat_res',
            categoryName: 'Residential',
            propertyTypeId: 'type_apt',
            propertyTypeName: 'Apartment',
            minBudget: 1000000.0,
            maxBudget: 2000000.0,
            areaIds: const ['area_1'],
            areaNames: const ['Area 1'],
            status: 'Call Attempted (Open)',
            assignedTo: 'sales_1',
            createdAt: now.subtract(const Duration(days: 1)),
          ),
          RequirementModel(
            id: 'rej_1',
            clientName: 'Rejected Lead',
            clientMobile: '9333333333',
            categoryId: 'cat_res',
            categoryName: 'Residential',
            propertyTypeId: 'type_apt',
            propertyTypeName: 'Apartment',
            minBudget: 1000000.0,
            maxBudget: 2000000.0,
            areaIds: const ['area_1'],
            areaNames: const ['Area 1'],
            status: 'Rejected (Budget Mismatch)',
            assignedTo: 'sales_1',
            createdAt: now.subtract(const Duration(days: 1)),
          ),
        ];

        final report = ReportDataEngine.computeReport(
          allLeads: callAttemptedLeads,
          allUsers: sampleUsers,
          allProperties: sampleProperties,
          allFollowups: sampleFollowups,
          systemStatuses: systemStatuses,
          config: defaultConfig,
        );

        // Picked Up lead counts as contacted
        final contactedKpi = report.kpiValues[ReportKpiType.leadsContacted]!;
        expect(contactedKpi.count, 1);

        // Discovered pipeline stages contain new statuses
        final statusNames = report.pipelineStages.map((s) => s.status).toList();
        expect(statusNames.contains('Call Attempted (Picked Up)'), isTrue);
        expect(statusNames.contains('Call Attempted (Open)'), isTrue);
        expect(statusNames.contains('Rejected (Budget Mismatch)'), isTrue);

        // Formatted display names
        final pickedUpStage = report.pipelineStages.firstWhere((s) => s.status == 'Call Attempted (Picked Up)');
        expect(pickedUpStage.displayName, 'Call Picked Up');

        // Status filter matching group and specific sub-option
        final groupFilterConfig = defaultConfig.copyWith(
          filters: defaultConfig.filters.copyWith(leadStatus: 'Call Attempted'),
        );
        final groupFilteredReport = ReportDataEngine.computeReport(
          allLeads: callAttemptedLeads,
          allUsers: sampleUsers,
          allProperties: sampleProperties,
          allFollowups: sampleFollowups,
          systemStatuses: systemStatuses,
          config: groupFilterConfig,
        );
        // Group filter 'Call Attempted' matches both Picked Up and Open
        expect(groupFilteredReport.filteredLeads.length, 2);

        final specificFilterConfig = defaultConfig.copyWith(
          filters: defaultConfig.filters.copyWith(leadStatus: 'Call Attempted (Picked Up)'),
        );
        final specificFilteredReport = ReportDataEngine.computeReport(
          allLeads: callAttemptedLeads,
          allUsers: sampleUsers,
          allProperties: sampleProperties,
          allFollowups: sampleFollowups,
          systemStatuses: systemStatuses,
          config: specificFilterConfig,
        );
        expect(specificFilteredReport.filteredLeads.length, 1);

        // Group filter 'Rejected' matches 'Rejected (Budget Mismatch)'
        final rejFilterConfig = defaultConfig.copyWith(
          filters: defaultConfig.filters.copyWith(leadStatus: 'Rejected'),
        );
        final rejFilteredReport = ReportDataEngine.computeReport(
          allLeads: callAttemptedLeads,
          allUsers: sampleUsers,
          allProperties: sampleProperties,
          allFollowups: sampleFollowups,
          systemStatuses: systemStatuses,
          config: rejFilterConfig,
        );
        expect(rejFilteredReport.filteredLeads.length, 1);
      });
    });
  });
}
