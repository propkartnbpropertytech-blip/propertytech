import '../models/business_insight.dart';
import '../models/report_data.dart';
import '../models/report_kpi_type.dart';

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

  /// Telecaller-specific insights. Skips team-ranking signals and requires
  /// enough data before emitting a finding.
  static List<BusinessInsightItem> generateTelecallerInsights({
    required String telecallerName,
    required int assignedCount,
    required int contactedCount,
    required int qualifiedCount,
    required int visitsScheduledCount,
    required int visitsDoneCount,
    required int wonCount,
    required int lostCount,
    required int callAttemptedCount,
    required int callPickedUpCount,
    required int callOpenCount,
    required int overdueFollowupsCount,
    required List<GrowthComparisonItem> growthItems,
  }) {
    final List<BusinessInsightItem> insights = [];

    GrowthComparisonItem? itemFor(ReportKpiType type) {
      final matches = growthItems.where((g) => g.kpiType == type);
      return matches.isEmpty ? null : matches.first;
    }

    void addGrowthInsight({
      required ReportKpiType type,
      required String increasedTitle,
      required String decreasedTitle,
      required InsightCategory category,
      required String Function(GrowthComparisonItem item) description,
    }) {
      final item = itemFor(type);
      if (item == null) return;
      if (item.previousCount == 0 && item.currentCount == 0) return;
      if (item.growthPercentage.abs() < 10) return;
      final increased = item.isPositive && item.difference > 0;
      insights.add(
        BusinessInsightItem(
          id: 'tele_insight_${type.name}',
          title: increased ? increasedTitle : decreasedTitle,
          description: description(item),
          category: category,
          severity: increased ? InsightSeverity.success : InsightSeverity.warning,
          metricValue: '${item.growthPercentage >= 0 ? '+' : ''}${item.growthPercentage.toStringAsFixed(1)}%',
        ),
      );
    }

    if (overdueFollowupsCount > 0) {
      insights.add(
        BusinessInsightItem(
          id: 'tele_insight_overdue_followups',
          title: '$overdueFollowupsCount Overdue Follow-ups',
          description: '$telecallerName has $overdueFollowupsCount overdue follow-up${overdueFollowupsCount == 1 ? '' : 's'} that need immediate outreach.',
          category: InsightCategory.followups,
          severity: overdueFollowupsCount > 5 ? InsightSeverity.danger : InsightSeverity.warning,
          metricValue: '$overdueFollowupsCount Overdue',
        ),
      );
    }

    if (callAttemptedCount >= 5 && callOpenCount > 0) {
      final openRate = callOpenCount / callAttemptedCount * 100;
      if (openRate >= 40) {
        insights.add(
          BusinessInsightItem(
            id: 'tele_insight_open_calls',
            title: 'Large Number of Open Calls (${openRate.toStringAsFixed(1)}%)',
            description: '$callOpenCount of $callAttemptedCount call attempts for $telecallerName remain open / not connected.',
            category: InsightCategory.calls,
            severity: InsightSeverity.warning,
            metricValue: '$callOpenCount Open',
          ),
        );
      }
    }

    if (callAttemptedCount >= 5) {
      final pickupRate = callPickedUpCount / callAttemptedCount * 100;
      if (pickupRate < 35) {
        insights.add(
          BusinessInsightItem(
            id: 'tele_insight_call_pickup_drop',
            title: 'Low Call Pickup Rate (${pickupRate.toStringAsFixed(1)}%)',
            description: '$telecallerName connected $callPickedUpCount of $callAttemptedCount attempted calls.',
            category: InsightCategory.calls,
            severity: InsightSeverity.warning,
            metricValue: '${pickupRate.toStringAsFixed(1)}%',
          ),
        );
      } else if (pickupRate >= 65) {
        insights.add(
          BusinessInsightItem(
            id: 'tele_insight_call_pickup_high',
            title: 'Call Pickup Rate Increased (${pickupRate.toStringAsFixed(1)}%)',
            description: '$telecallerName successfully connected with $callPickedUpCount of $callAttemptedCount call attempts.',
            category: InsightCategory.calls,
            severity: InsightSeverity.success,
            metricValue: '${pickupRate.toStringAsFixed(1)}%',
          ),
        );
      }
    }

    addGrowthInsight(
      type: ReportKpiType.callPickedUp,
      increasedTitle: 'Call pickup rate increased',
      decreasedTitle: 'Call pickup rate decreased',
      category: InsightCategory.calls,
      description: (item) =>
          '$telecallerName recorded ${item.currentCount} picked-up calls vs ${item.previousCount} in the comparison period.',
    );

    if (contactedCount >= 5) {
      final qualRate = qualifiedCount / contactedCount * 100;
      if (qualRate < 20) {
        insights.add(
          BusinessInsightItem(
            id: 'tele_insight_qualification_low',
            title: 'Qualification rate decreased (${qualRate.toStringAsFixed(1)}%)',
            description: '$telecallerName qualified $qualifiedCount of $contactedCount contacted leads.',
            category: InsightCategory.conversion,
            severity: InsightSeverity.warning,
            metricValue: '${qualRate.toStringAsFixed(1)}%',
          ),
        );
      }
    }

    addGrowthInsight(
      type: ReportKpiType.leadQualificationRate,
      increasedTitle: 'Qualification rate increased',
      decreasedTitle: 'Qualification rate decreased',
      category: InsightCategory.conversion,
      description: (item) =>
          '$telecallerName qualified ${item.currentCount} leads vs ${item.previousCount} previously.',
    );

    addGrowthInsight(
      type: ReportKpiType.siteVisitsDone,
      increasedTitle: 'Site visits increased',
      decreasedTitle: 'Site visits decreased',
      category: InsightCategory.visits,
      description: (item) =>
          '$telecallerName completed ${item.currentCount} site visits vs ${item.previousCount} in the comparison period.',
    );

    addGrowthInsight(
      type: ReportKpiType.convertedToWon,
      increasedTitle: 'Won conversion increased',
      decreasedTitle: 'Won conversion decreased',
      category: InsightCategory.conversion,
      description: (item) =>
          '$telecallerName closed ${item.currentCount} won leads vs ${item.previousCount} previously.',
    );

    addGrowthInsight(
      type: ReportKpiType.totalLeads,
      increasedTitle: 'Assigned lead volume increased',
      decreasedTitle: 'Assigned lead volume decreased',
      category: InsightCategory.volume,
      description: (item) =>
          '$telecallerName handled ${item.currentCount} assigned leads vs ${item.previousCount} in the comparison period.',
    );

    if (assignedCount >= 5 && lostCount > 0) {
      final lostRate = lostCount / assignedCount * 100;
      if (lostRate >= 25) {
        insights.add(
          BusinessInsightItem(
            id: 'tele_insight_lost_rate',
            title: 'High Lost Rate (${lostRate.toStringAsFixed(1)}%)',
            description: '$telecallerName has $lostCount unsuccessful leads out of $assignedCount assigned.',
            category: InsightCategory.conversion,
            severity: InsightSeverity.warning,
            metricValue: '${lostRate.toStringAsFixed(1)}%',
          ),
        );
      }
    }

    return insights;
  }
}
