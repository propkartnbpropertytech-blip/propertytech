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
  });
}
