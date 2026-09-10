import 'package:flutter/material.dart';
import '../../requirements/models/requirement_model.dart';
import '../../users/models/user_model.dart';
import '../../properties/models/property_model.dart';
import '../../../core/storage/isar_collections.dart';
import 'report_kpi_type.dart';
import 'business_insight.dart';

class KpiValue {
  final int count;
  final double percentage;
  final String formattedCount;
  final String formattedPercentage;
  final String denominatorLabel;

  const KpiValue({
    required this.count,
    required this.percentage,
    required this.formattedCount,
    required this.formattedPercentage,
    required this.denominatorLabel,
  });

  factory KpiValue.create({
    required int count,
    required double percentage,
    required String denominatorLabel,
  }) {
    return KpiValue(
      count: count,
      percentage: percentage,
      formattedCount: count.toString(),
      formattedPercentage: '${percentage.toStringAsFixed(1)}%',
      denominatorLabel: denominatorLabel,
    );
  }
}

class PipelineStageData {
  final String status;
  final String displayName;
  final int count;
  final double percentage;
  final Color color;
  final List<RequirementModel> leads;

  const PipelineStageData({
    required this.status,
    required this.displayName,
    required this.count,
    required this.percentage,
    required this.color,
    required this.leads,
  });
}

class FunnelStageData {
  final String stageName;
  final int count;
  final double stageConversionRate; // vs previous stage
  final double totalConversionRate; // vs total leads
  final Color color;
  final List<RequirementModel> leads;

  const FunnelStageData({
    required this.stageName,
    required this.count,
    required this.stageConversionRate,
    required this.totalConversionRate,
    required this.color,
    required this.leads,
  });
}

class FollowupItemData {
  final String id;
  final String leadName;
  final String? leadId;
  final String? clientMobile;
  final String? assignedUserName;
  final DateTime followupDateTime;
  final String? lastActivity;
  final String nextAction;
  final String leadStatus;

  const FollowupItemData({
    required this.id,
    required this.leadName,
    this.leadId,
    this.clientMobile,
    this.assignedUserName,
    required this.followupDateTime,
    this.lastActivity,
    required this.nextAction,
    required this.leadStatus,
  });
}

class FollowupCategoryData {
  final String categoryName;
  final int count;
  final Color color;
  final List<FollowupItemData> items;

  const FollowupCategoryData({
    required this.categoryName,
    required this.count,
    required this.color,
    required this.items,
  });
}

class TeamMemberRanking {
  final int rank;
  final String userId;
  final String userName;
  final String role;
  final int leadsCount;
  final int contactedCount;
  final int qualifiedCount;
  final int siteVisitsCount;
  final int wonCount;
  final double conversionRate; // Won / Leads %

  const TeamMemberRanking({
    required this.rank,
    required this.userId,
    required this.userName,
    required this.role,
    required this.leadsCount,
    required this.contactedCount,
    required this.qualifiedCount,
    required this.siteVisitsCount,
    required this.wonCount,
    required this.conversionRate,
  });

  TeamMemberRanking copyWith({int? rank}) {
    return TeamMemberRanking(
      rank: rank ?? this.rank,
      userId: userId,
      userName: userName,
      role: role,
      leadsCount: leadsCount,
      contactedCount: contactedCount,
      qualifiedCount: qualifiedCount,
      siteVisitsCount: siteVisitsCount,
      wonCount: wonCount,
      conversionRate: conversionRate,
    );
  }
}

class GrowthComparisonItem {
  final ReportKpiType kpiType;
  final String metricName;
  final num currentCount;
  final num previousCount;
  final num difference;
  final double growthPercentage;
  final bool isPositive;

  const GrowthComparisonItem({
    required this.kpiType,
    required this.metricName,
    required this.currentCount,
    required this.previousCount,
    required this.difference,
    required this.growthPercentage,
    required this.isPositive,
  });
}

class LeadSourceData {
  final String source;
  final int count;
  final double percentage;
  final Color color;
  final List<RequirementModel> leads;

  const LeadSourceData({
    required this.source,
    required this.count,
    required this.percentage,
    required this.color,
    required this.leads,
  });
}

class TrendDataPoint {
  final DateTime date;
  final String label;
  final num value;

  const TrendDataPoint({
    required this.date,
    required this.label,
    required this.value,
  });
}

class ReportOverallData {
  final Map<ReportKpiType, KpiValue> kpiValues;
  final List<PipelineStageData> pipelineStages;
  final List<FunnelStageData> funnelStages;
  final List<FollowupCategoryData> followupCategories;
  final List<TeamMemberRanking> telecallerRankings;
  final List<TeamMemberRanking> salesRankings;
  final List<BusinessInsightItem> insights;
  final List<GrowthComparisonItem> growthComparisonItems;
  final List<LeadSourceData> leadSources;
  final List<TrendDataPoint> trendPoints;

  // Raw filtered datasets for drill-down inspection
  final List<RequirementModel> filteredLeads;
  final List<String> availableStatuses;
  final List<String> availableSources;
  final List<UserModel> availableTelecallers;
  final List<UserModel> availableSalesUsers;
  final List<PropertyModel> availableProperties;
  final List<RequirementModel> allLeads;
  final List<FollowupLocal> allFollowups;

  const ReportOverallData({
    required this.kpiValues,
    required this.pipelineStages,
    required this.funnelStages,
    required this.followupCategories,
    required this.telecallerRankings,
    required this.salesRankings,
    required this.insights,
    required this.growthComparisonItems,
    required this.leadSources,
    required this.trendPoints,
    required this.filteredLeads,
    required this.availableStatuses,
    required this.availableSources,
    required this.availableTelecallers,
    required this.availableSalesUsers,
    required this.availableProperties,
    this.allLeads = const [],
    this.allFollowups = const [],
  });

  bool get isEmpty => filteredLeads.isEmpty;
}

class UserPerformanceSummary {
  final String userId;
  final String userName;
  final String role; // 'Telecaller' or 'Sales'
  final String dateRangeLabel;
  final int leadsHandled;
  final int leadsContacted;
  final int qualifiedLeads;
  final int siteVisits;
  final int wonLeads;
  final double conversionPercentage;
  final int pendingFollowups;
  final int callAttempted;
  final int callPickedUp;
  final int callOpen;
  final int lostLeads;

  const UserPerformanceSummary({
    required this.userId,
    required this.userName,
    required this.role,
    required this.dateRangeLabel,
    required this.leadsHandled,
    required this.leadsContacted,
    required this.qualifiedLeads,
    required this.siteVisits,
    required this.wonLeads,
    required this.conversionPercentage,
    required this.pendingFollowups,
    required this.callAttempted,
    required this.callPickedUp,
    required this.callOpen,
    required this.lostLeads,
  });
}
