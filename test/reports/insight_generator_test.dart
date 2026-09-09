import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/reports/models/business_insight.dart';
import 'package:propkart/features/reports/models/report_data.dart';
import 'package:propkart/features/reports/services/insight_generator.dart';

void main() {
  group('InsightGenerator Tests', () {
    test('Generates danger/warning insight when overdue followups exist', () {
      final insights = InsightGenerator.generateInsights(
        totalLeads: 10,
        contactedCount: 8,
        qualifiedCount: 6,
        visitsDoneCount: 4,
        wonCount: 2,
        callAttemptedCount: 10,
        callPickedUpCount: 7,
        overdueFollowupsCount: 6, // > 5 => danger
        salesRankings: [],
        telecallerRankings: [],
        previousLeadsCount: 10,
      );

      final overdue = insights.firstWhere((i) => i.id == 'insight_overdue_followups');
      expect(overdue.severity, InsightSeverity.danger);
      expect(overdue.category, InsightCategory.followups);
      expect(overdue.metricValue, '6 Overdue');
    });

    test('Generates positive growth insight when volume surges > 10%', () {
      final insights = InsightGenerator.generateInsights(
        totalLeads: 15,
        contactedCount: 10,
        qualifiedCount: 8,
        visitsDoneCount: 5,
        wonCount: 3,
        callAttemptedCount: 10,
        callPickedUpCount: 8,
        overdueFollowupsCount: 0,
        salesRankings: [],
        telecallerRankings: [],
        previousLeadsCount: 10, // +50% growth
      );

      final volumeInsight = insights.firstWhere((i) => i.id == 'insight_volume_trend');
      expect(volumeInsight.severity, InsightSeverity.success);
      expect(volumeInsight.title.contains('+50.0%'), true);
    });

    test('Generates healthy deal conversion insight when closing rate >= 15%', () {
      final insights = InsightGenerator.generateInsights(
        totalLeads: 20,
        contactedCount: 15,
        qualifiedCount: 10,
        visitsDoneCount: 8,
        wonCount: 4, // 4 / 20 = 20%
        callAttemptedCount: 10,
        callPickedUpCount: 8,
        overdueFollowupsCount: 0,
        salesRankings: [],
        telecallerRankings: [],
        previousLeadsCount: 20,
      );

      final convInsight = insights.firstWhere((i) => i.id == 'insight_conversion_strong');
      expect(convInsight.severity, InsightSeverity.success);
      expect(convInsight.category, InsightCategory.conversion);
    });

    test('Generates top sales closer insight when rankings provided', () {
      final insights = InsightGenerator.generateInsights(
        totalLeads: 20,
        contactedCount: 15,
        qualifiedCount: 10,
        visitsDoneCount: 8,
        wonCount: 4,
        callAttemptedCount: 10,
        callPickedUpCount: 8,
        overdueFollowupsCount: 0,
        salesRankings: [
          const TeamMemberRanking(
            rank: 1,
            userId: 'sales_bob',
            userName: 'Bob Champion',
            role: 'Sales',
            leadsCount: 12,
            contactedCount: 12,
            qualifiedCount: 10,
            siteVisitsCount: 6,
            wonCount: 4,
            conversionRate: 33.3,
          ),
        ],
        telecallerRankings: [],
        previousLeadsCount: 20,
      );

      final topSales = insights.firstWhere((i) => i.id == 'insight_top_sales');
      expect(topSales.title, 'Top Sales Closer: Bob Champion');
      expect(topSales.severity, InsightSeverity.success);
    });
  });
}
