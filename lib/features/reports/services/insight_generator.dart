import '../models/business_insight.dart';
import '../models/report_data.dart';

class InsightGenerator {
  static List<BusinessInsightItem> generateInsights({
    required int totalLeads,
    required int contactedCount,
    required int qualifiedCount,
    required int visitsDoneCount,
    required int wonCount,
    required int callAttemptedCount,
    required int callPickedUpCount,
    required int overdueFollowupsCount,
    required List<TeamMemberRanking> salesRankings,
    required List<TeamMemberRanking> telecallerRankings,
    required int previousLeadsCount,
  }) {
    final List<BusinessInsightItem> insights = [];

    // 1. Overdue followups alert
    if (overdueFollowupsCount > 0) {
      insights.add(
        BusinessInsightItem(
          id: 'insight_overdue_followups',
          title: '$overdueFollowupsCount Overdue Follow-ups',
          description: 'Client follow-ups are past due date and require immediate outreach to avoid lead drop-off.',
          category: InsightCategory.followups,
          severity: overdueFollowupsCount > 5 ? InsightSeverity.danger : InsightSeverity.warning,
          metricValue: '$overdueFollowupsCount Overdue',
          actionText: 'Review Overdue',
        ),
      );
    }

    // 2. Volume growth insight
    if (previousLeadsCount > 0 && totalLeads > 0) {
      final diff = totalLeads - previousLeadsCount;
      final pct = (diff / previousLeadsCount * 100);
      if (pct.abs() >= 10) {
        final isGrowth = pct > 0;
        insights.add(
          BusinessInsightItem(
            id: 'insight_volume_trend',
            title: isGrowth ? 'Lead Volume Surged +${pct.toStringAsFixed(1)}%' : 'Lead Volume Declined ${pct.toStringAsFixed(1)}%',
            description: isGrowth
                ? 'Acquisition momentum is strong with $totalLeads total leads compared to $previousLeadsCount previously.'
                : 'Inbound leads decreased to $totalLeads vs $previousLeadsCount in the comparison period.',
            category: InsightCategory.volume,
            severity: isGrowth ? InsightSeverity.success : InsightSeverity.warning,
            metricValue: '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%',
          ),
        );
      }
    }

    // 3. Call connectivity insight
    if (callAttemptedCount >= 5) {
      final pickupRate = (callPickedUpCount / callAttemptedCount * 100);
      if (pickupRate < 35) {
        insights.add(
          BusinessInsightItem(
            id: 'insight_call_pickup_drop',
            title: 'Low Call Pickup Rate (${pickupRate.toStringAsFixed(1)}%)',
            description: 'Only $callPickedUpCount out of $callAttemptedCount calls were answered. Consider optimizing call scheduling times or follow-up channels.',
            category: InsightCategory.calls,
            severity: InsightSeverity.warning,
            metricValue: '${pickupRate.toStringAsFixed(1)}%',
          ),
        );
      } else if (pickupRate >= 65) {
        insights.add(
          BusinessInsightItem(
            id: 'insight_call_pickup_high',
            title: 'High Call Responsiveness (${pickupRate.toStringAsFixed(1)}%)',
            description: 'Telecallers successfully connected with $callPickedUpCount clients out of $callAttemptedCount attempts.',
            category: InsightCategory.calls,
            severity: InsightSeverity.success,
            metricValue: '${pickupRate.toStringAsFixed(1)}%',
          ),
        );
      }
    }

    // 4. Site visit & won deal conversion
    if (totalLeads >= 5 && wonCount > 0) {
      final convRate = (wonCount / totalLeads * 100);
      if (convRate >= 15) {
        insights.add(
          BusinessInsightItem(
            id: 'insight_conversion_strong',
            title: 'Healthy Deal Conversion (${convRate.toStringAsFixed(1)}%)',
            description: 'The sales team has successfully closed $wonCount won deals out of $totalLeads active leads.',
            category: InsightCategory.conversion,
            severity: InsightSeverity.success,
            metricValue: '${convRate.toStringAsFixed(1)}%',
          ),
        );
      }
    }

    // 5. Top performing Sales Rep
    if (salesRankings.isNotEmpty && salesRankings.first.wonCount > 0) {
      final topSales = salesRankings.first;
      insights.add(
        BusinessInsightItem(
          id: 'insight_top_sales',
          title: 'Top Sales Closer: ${topSales.userName}',
          description: '${topSales.userName} leads the team with ${topSales.wonCount} won deals and a ${topSales.conversionRate.toStringAsFixed(1)}% conversion rate.',
          category: InsightCategory.team,
          severity: InsightSeverity.success,
          metricValue: '${topSales.wonCount} Deals Won',
        ),
      );
    }

    // 6. Top performing Telecaller
    if (telecallerRankings.isNotEmpty && telecallerRankings.first.leadsCount >= 5) {
      final topTelecaller = telecallerRankings.first;
      insights.add(
        BusinessInsightItem(
          id: 'insight_top_telecaller',
          title: 'Top Outbound Producer: ${topTelecaller.userName}',
          description: '${topTelecaller.userName} generated ${topTelecaller.leadsCount} qualified requirements in this reporting period.',
          category: InsightCategory.team,
          severity: InsightSeverity.info,
          metricValue: '${topTelecaller.leadsCount} Leads',
        ),
      );
    }

    return insights;
  }
}
