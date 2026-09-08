import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../requirements/models/requirement_model.dart';
import '../../users/models/user_model.dart';
import '../../properties/models/property_model.dart';
import '../../../core/storage/isar_collections.dart';
import '../models/report_kpi_type.dart';
import '../models/report_date_range.dart';
import '../models/report_configuration.dart';
import '../models/report_data.dart';
import 'insight_generator.dart';

class ReportDataEngine {
  static ReportOverallData computeReport({
    required List<RequirementModel> allLeads,
    required List<UserModel> allUsers,
    required List<PropertyModel> allProperties,
    required List<FollowupLocal> allFollowups,
    required List<String> systemStatuses,
    required ReportConfiguration config,
  }) {
    // 1. Filter Leads by Date Range and Global Filters
    final filteredLeads = allLeads.where((lead) {
      // Date Range Filter
      if (!config.dateRange.contains(lead.createdAt)) {
        return false;
      }

      // Property Filter
      if (config.filters.propertyId != null && config.filters.propertyId!.isNotEmpty) {
        final propId = config.filters.propertyId!;
        final hasMatch = lead.rawShareSessions?.any((s) => s['property_id'] == propId) == true ||
            lead.rawSiteVisits?.any((v) => v['property_id'] == propId) == true;
        if (!hasMatch) return false;
      }

      // Lead Source Filter
      if (config.filters.leadSource != null && config.filters.leadSource!.isNotEmpty) {
        final src = _extractLeadSource(lead);
        if (src.toLowerCase() != config.filters.leadSource!.toLowerCase()) {
          return false;
        }
      }

      // Telecaller Filter
      if (config.filters.telecallerId != null && config.filters.telecallerId!.isNotEmpty) {
        final tId = config.filters.telecallerId!;
        final matches = lead.createdBy == tId ||
            lead.creatorName?.toLowerCase() == config.filters.telecallerName?.toLowerCase();
        if (!matches) return false;
      }

      // Sales User Filter
      if (config.filters.salesUserId != null && config.filters.salesUserId!.isNotEmpty) {
        final sId = config.filters.salesUserId!;
        final matches = lead.assignedTo == sId ||
            lead.assigneeName?.toLowerCase() == config.filters.salesUserName?.toLowerCase();
        if (!matches) return false;
      }

      // Lead Status Filter
      if (config.filters.leadStatus != null && config.filters.leadStatus!.isNotEmpty) {
        if (lead.status.toLowerCase() != config.filters.leadStatus!.toLowerCase()) {
          return false;
        }
      }

      // Lead Type Filter (e.g. Rent, Sale)
      if (config.filters.leadType != null && config.filters.leadType!.isNotEmpty) {
        final lt = (lead.listingTypeName ?? '').toLowerCase();
        final cat = lead.categoryName.toLowerCase();
        final target = config.filters.leadType!.toLowerCase();
        if (!lt.contains(target) && !cat.contains(target)) {
          return false;
        }
      }

      // Location Filter
      if (config.filters.locationId != null && config.filters.locationId!.isNotEmpty) {
        final locId = config.filters.locationId!;
        final inAreas = lead.areaIds.contains(locId);
        final locName = config.filters.locationName?.toLowerCase();
        final inNames = locName != null && lead.areaNames.any((a) => a.toLowerCase().contains(locName));
        if (!inAreas && !inNames) return false;
      }

      // Campaign Filter
      if (config.filters.campaign != null && config.filters.campaign!.isNotEmpty) {
        final cmp = config.filters.campaign!.toLowerCase();
        final notes = (lead.notes ?? '').toLowerCase();
        final remarks = (lead.remarks ?? '').toLowerCase();
        if (!notes.contains(cmp) && !remarks.contains(cmp)) {
          return false;
        }
      }

      return true;
    }).toList();

    // 2. Filter Followups by Date Range
    final filteredFollowups = allFollowups.where((f) {
      return config.dateRange.contains(f.createdAt) || config.dateRange.contains(f.followupDate);
    }).toList();

    // 3. Extract Active Telecallers and Sales Users
    final telecallers = allUsers.where((u) => u.roleName.toLowerCase() == 'telecaller').toList();
    final salesUsers = allUsers.where((u) => u.roleName.toLowerCase() == 'sales').toList();

    // 4. Compute 13 KPIs
    final totalLeadsCount = filteredLeads.length;

    // Contacted leads
    final contactedLeads = filteredLeads.where((l) => _isContacted(l)).toList();
    final contactedCount = contactedLeads.length;

    // Assigned to sales
    final assignedLeads = filteredLeads.where((l) => l.assignedTo != null && l.assignedTo!.isNotEmpty).toList();
    final assignedCount = assignedLeads.length;

    // Qualified leads
    final qualifiedLeads = filteredLeads.where((l) => _isQualified(l)).toList();
    final qualifiedCount = qualifiedLeads.length;

    // Site visits scheduled & done
    final visitsScheduledLeads = filteredLeads.where((l) => _isVisitScheduled(l)).toList();
    final visitsScheduledCount = visitsScheduledLeads.length;

    final visitsDoneLeads = filteredLeads.where((l) => _isVisitDone(l)).toList();
    final visitsDoneCount = visitsDoneLeads.length;

    // Won leads
    final wonLeads = filteredLeads.where((l) => _isWon(l)).toList();
    final wonCount = wonLeads.length;

    // Lost leads
    final lostLeads = filteredLeads.where((l) => _isLost(l)).toList();
    final lostCount = lostLeads.length;

    // Telecaller / Sales count involved in filtered leads
    final activeTelecallerIds = filteredLeads.map((l) => l.createdBy).whereType<String>().toSet();
    final activeTelecallerCount = activeTelecallerIds.isEmpty ? telecallers.length : activeTelecallerIds.length;

    final activeSalesIds = filteredLeads.map((l) => l.assignedTo).whereType<String>().toSet();
    final activeSalesCount = activeSalesIds.isEmpty ? salesUsers.length : activeSalesIds.length;

    // Calls
    final callAttemptedCount = filteredFollowups.length;
    final callPickedUpCount = filteredFollowups.where((f) => _isCallPickedUp(f)).length;
    final callOpenCount = filteredFollowups.where((f) => _isCallOpen(f)).length;

    // KPI Values map with meaningful denominators
    final Map<ReportKpiType, KpiValue> kpiValues = {
      ReportKpiType.totalLeads: KpiValue.create(
        count: totalLeadsCount,
        percentage: 100.0,
        denominatorLabel: '100% of Total Leads',
      ),
      ReportKpiType.telecallers: KpiValue.create(
        count: activeTelecallerCount,
        percentage: telecallers.isEmpty ? 100.0 : (activeTelecallerCount / telecallers.length * 100).clamp(0.0, 100.0),
        denominatorLabel: '% of ${telecallers.length} Telecallers',
      ),
      ReportKpiType.salesUsers: KpiValue.create(
        count: activeSalesCount,
        percentage: salesUsers.isEmpty ? 100.0 : (activeSalesCount / salesUsers.length * 100).clamp(0.0, 100.0),
        denominatorLabel: '% of ${salesUsers.length} Sales Users',
      ),
      ReportKpiType.leadsContacted: KpiValue.create(
        count: contactedCount,
        percentage: totalLeadsCount == 0 ? 0.0 : (contactedCount / totalLeadsCount * 100),
        denominatorLabel: '% of Total Leads ($totalLeadsCount)',
      ),
      ReportKpiType.leadsAssignedToSales: KpiValue.create(
        count: assignedCount,
        percentage: totalLeadsCount == 0 ? 0.0 : (assignedCount / totalLeadsCount * 100),
        denominatorLabel: '% of Total Leads ($totalLeadsCount)',
      ),
      ReportKpiType.leadQualificationRate: KpiValue.create(
        count: qualifiedCount,
        percentage: contactedCount == 0 ? 0.0 : (qualifiedCount / contactedCount * 100),
        denominatorLabel: '% of Contacted Leads ($contactedCount)',
      ),
      ReportKpiType.siteVisitsScheduled: KpiValue.create(
        count: visitsScheduledCount,
        percentage: qualifiedCount == 0 ? 0.0 : (visitsScheduledCount / qualifiedCount * 100),
        denominatorLabel: '% of Qualified Leads ($qualifiedCount)',
      ),
      ReportKpiType.siteVisitsDone: KpiValue.create(
        count: visitsDoneCount,
        percentage: visitsScheduledCount == 0 ? 0.0 : (visitsDoneCount / visitsScheduledCount * 100),
        denominatorLabel: '% of Scheduled Visits ($visitsScheduledCount)',
      ),
      ReportKpiType.convertedToWon: KpiValue.create(
        count: wonCount,
        percentage: (assignedCount > 0 ? (wonCount / assignedCount * 100) : (totalLeadsCount > 0 ? wonCount / totalLeadsCount * 100 : 0.0)),
        denominatorLabel: assignedCount > 0 ? '% of Assigned Leads ($assignedCount)' : '% of Total Leads ($totalLeadsCount)',
      ),
      ReportKpiType.callAttempted: KpiValue.create(
        count: callAttemptedCount,
        percentage: totalLeadsCount == 0 ? 0.0 : (callAttemptedCount / totalLeadsCount * 100),
        denominatorLabel: '% against Total Leads ($totalLeadsCount)',
      ),
      ReportKpiType.callPickedUp: KpiValue.create(
        count: callPickedUpCount,
        percentage: callAttemptedCount == 0 ? 0.0 : (callPickedUpCount / callAttemptedCount * 100),
        denominatorLabel: '% of Call Attempted ($callAttemptedCount)',
      ),
      ReportKpiType.callOpen: KpiValue.create(
        count: callOpenCount,
        percentage: callAttemptedCount == 0 ? 0.0 : (callOpenCount / callAttemptedCount * 100),
        denominatorLabel: '% of Call Attempted ($callAttemptedCount)',
      ),
      ReportKpiType.lostUnsuccessful: KpiValue.create(
        count: lostCount,
        percentage: totalLeadsCount == 0 ? 0.0 : (lostCount / totalLeadsCount * 100),
        denominatorLabel: '% of Total Leads ($totalLeadsCount)',
      ),
    };

    // 5. Dynamic Lead Status Pipeline
    final Set<String> gatheredStatuses = {};
    for (final l in allLeads) {
      if (l.status.trim().isNotEmpty) {
        gatheredStatuses.add(l.status.trim());
      }
    }
    gatheredStatuses.addAll(systemStatuses);
    if (gatheredStatuses.isEmpty) {
      gatheredStatuses.addAll([
        'New',
        'Not Started',
        'Follow-up',
        'Interested',
        'Site Visit',
        'Site Visit Done',
        'Negotiation',
        'Won',
        'Rejected',
      ]);
    }

    final orderedStatusList = _sortStatusesLogically(gatheredStatuses);

    final List<PipelineStageData> pipelineStages = [];
    for (final status in orderedStatusList) {
      final matchingLeads = filteredLeads.where((l) => l.status.toLowerCase() == status.toLowerCase()).toList();
      final pCount = matchingLeads.length;
      final pPercent = totalLeadsCount == 0 ? 0.0 : (pCount / totalLeadsCount * 100);
      pipelineStages.add(
        PipelineStageData(
          status: status,
          displayName: _formatStatusLabel(status),
          count: pCount,
          percentage: pPercent,
          color: _getStatusColor(status),
          leads: matchingLeads,
        ),
      );
    }

    // 6. Conversion Funnel Stages
    final List<FunnelStageData> funnelStages = [
      FunnelStageData(
        stageName: 'Total Leads',
        count: totalLeadsCount,
        stageConversionRate: 100.0,
        totalConversionRate: 100.0,
        color: const Color(0xFF14213D),
        leads: filteredLeads,
      ),
      FunnelStageData(
        stageName: 'Contacted',
        count: contactedCount,
        stageConversionRate: totalLeadsCount == 0 ? 0.0 : (contactedCount / totalLeadsCount * 100),
        totalConversionRate: totalLeadsCount == 0 ? 0.0 : (contactedCount / totalLeadsCount * 100),
        color: const Color(0xFF0284C7),
        leads: contactedLeads,
      ),
      FunnelStageData(
        stageName: 'Qualified',
        count: qualifiedCount,
        stageConversionRate: contactedCount == 0 ? 0.0 : (qualifiedCount / contactedCount * 100),
        totalConversionRate: totalLeadsCount == 0 ? 0.0 : (qualifiedCount / totalLeadsCount * 100),
        color: const Color(0xFF0D9488),
        leads: qualifiedLeads,
      ),
      FunnelStageData(
        stageName: 'Site Visit Scheduled',
        count: visitsScheduledCount,
        stageConversionRate: qualifiedCount == 0 ? 0.0 : (visitsScheduledCount / qualifiedCount * 100),
        totalConversionRate: totalLeadsCount == 0 ? 0.0 : (visitsScheduledCount / totalLeadsCount * 100),
        color: const Color(0xFF7C3AED),
        leads: visitsScheduledLeads,
      ),
      FunnelStageData(
        stageName: 'Site Visit Done',
        count: visitsDoneCount,
        stageConversionRate: visitsScheduledCount == 0 ? 0.0 : (visitsDoneCount / visitsScheduledCount * 100),
        totalConversionRate: totalLeadsCount == 0 ? 0.0 : (visitsDoneCount / totalLeadsCount * 100),
        color: const Color(0xFF9333EA),
        leads: visitsDoneLeads,
      ),
      FunnelStageData(
        stageName: 'Won',
        count: wonCount,
        stageConversionRate: visitsDoneCount == 0 ? 0.0 : (wonCount / visitsDoneCount * 100),
        totalConversionRate: totalLeadsCount == 0 ? 0.0 : (wonCount / totalLeadsCount * 100),
        color: const Color(0xFF16A34A),
        leads: wonLeads,
      ),
    ];

    // 7. Follow-up Analysis
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    final List<FollowupItemData> pendingItems = [];
    final List<FollowupItemData> dueTodayItems = [];
    final List<FollowupItemData> overdueItems = [];
    final List<FollowupItemData> upcomingItems = [];

    for (final f in filteredFollowups) {
      final isClosed = _isFollowupClosed(f.status);
      final item = FollowupItemData(
        id: f.id,
        leadName: f.clientName.isNotEmpty ? f.clientName : (f.requirementCustomerName ?? 'Client'),
        leadId: f.requirementId,
        clientMobile: f.mobile,
        assignedUserName: f.createdBy,
        followupDateTime: f.followupDate,
        lastActivity: f.notes,
        nextAction: f.status,
        leadStatus: f.status,
      );

      if (!isClosed) {
        pendingItems.add(item);
        if (f.followupDate.isBefore(todayStart)) {
          overdueItems.add(item);
        } else if (f.followupDate.isAfter(todayEnd)) {
          upcomingItems.add(item);
        } else {
          dueTodayItems.add(item);
        }
      }
    }

    // Also include leads that have nextFollowupDate
    for (final l in filteredLeads) {
      if (l.nextFollowupDate != null && l.nextFollowupDate!.isNotEmpty) {
        final dt = DateTime.tryParse(l.nextFollowupDate!);
        if (dt != null && !_isWon(l) && !_isLost(l)) {
          final item = FollowupItemData(
            id: 'req_f_${l.id}',
            leadName: l.clientName,
            leadId: l.id,
            clientMobile: l.clientMobile,
            assignedUserName: l.assigneeName ?? l.creatorName,
            followupDateTime: dt,
            lastActivity: l.remarks,
            nextAction: l.status,
            leadStatus: l.status,
          );
          if (!pendingItems.any((p) => p.leadId == l.id)) {
            pendingItems.add(item);
            if (dt.isBefore(todayStart)) {
              overdueItems.add(item);
            } else if (dt.isAfter(todayEnd)) {
              upcomingItems.add(item);
            } else {
              dueTodayItems.add(item);
            }
          }
        }
      }
    }

    final List<FollowupCategoryData> followupCategories = [
      FollowupCategoryData(
        categoryName: 'Pending Follow-ups',
        count: pendingItems.length,
        color: const Color(0xFF0284C7),
        items: pendingItems,
      ),
      FollowupCategoryData(
        categoryName: 'Due Today',
        count: dueTodayItems.length,
        color: const Color(0xFFD97706),
        items: dueTodayItems,
      ),
      FollowupCategoryData(
        categoryName: 'Overdue',
        count: overdueItems.length,
        color: const Color(0xFFDC2626),
        items: overdueItems,
      ),
      FollowupCategoryData(
        categoryName: 'Upcoming',
        count: upcomingItems.length,
        color: const Color(0xFF16A34A),
        items: upcomingItems,
      ),
    ];

    // 8. Team Ranking (Telecallers & Sales Users)
    final List<TeamMemberRanking> telecallerRankings = [];
    int tRank = 1;
    for (final u in telecallers) {
      final uLeads = filteredLeads.where((l) => l.createdBy == u.id || l.creatorName == u.fullName).toList();
      final uContacted = uLeads.where((l) => _isContacted(l)).length;
      final uQualified = uLeads.where((l) => _isQualified(l)).length;
      final uVisits = uLeads.where((l) => _isVisitScheduled(l) || _isVisitDone(l)).length;
      final uWon = uLeads.where((l) => _isWon(l)).length;
      final uConv = uLeads.isEmpty ? 0.0 : (uWon / uLeads.length * 100);

      telecallerRankings.add(
        TeamMemberRanking(
          rank: tRank++,
          userId: u.id,
          userName: u.fullName.isNotEmpty ? u.fullName : u.email,
          role: 'Telecaller',
          leadsCount: uLeads.length,
          contactedCount: uContacted,
          qualifiedCount: uQualified,
          siteVisitsCount: uVisits,
          wonCount: uWon,
          conversionRate: uConv,
        ),
      );
    }
    telecallerRankings.sort((a, b) => b.leadsCount.compareTo(a.leadsCount));
    for (int i = 0; i < telecallerRankings.length; i++) {
      telecallerRankings[i] = telecallerRankings[i].copyWith(rank: i + 1);
    }

    final List<TeamMemberRanking> salesRankings = [];
    int sRank = 1;
    for (final u in salesUsers) {
      final uLeads = filteredLeads.where((l) => l.assignedTo == u.id || l.assigneeName == u.fullName).toList();
      final uContacted = uLeads.where((l) => _isContacted(l)).length;
      final uQualified = uLeads.where((l) => _isQualified(l)).length;
      final uVisits = uLeads.where((l) => _isVisitScheduled(l) || _isVisitDone(l)).length;
      final uWon = uLeads.where((l) => _isWon(l)).length;
      final uConv = uLeads.isEmpty ? 0.0 : (uWon / uLeads.length * 100);

      salesRankings.add(
        TeamMemberRanking(
          rank: sRank++,
          userId: u.id,
          userName: u.fullName.isNotEmpty ? u.fullName : u.email,
          role: 'Sales',
          leadsCount: uLeads.length,
          contactedCount: uContacted,
          qualifiedCount: uQualified,
          siteVisitsCount: uVisits,
          wonCount: uWon,
          conversionRate: uConv,
        ),
      );
    }
    salesRankings.sort((a, b) => b.wonCount != a.wonCount ? b.wonCount.compareTo(a.wonCount) : b.leadsCount.compareTo(a.leadsCount));
    for (int i = 0; i < salesRankings.length; i++) {
      salesRankings[i] = salesRankings[i].copyWith(rank: i + 1);
    }

    // 9. Lead Source Analysis
    final Map<String, List<RequirementModel>> sourceGroups = {};
    for (final l in filteredLeads) {
      final s = _extractLeadSource(l);
      sourceGroups.putIfAbsent(s, () => []).add(l);
    }
    final List<LeadSourceData> leadSources = [];
    final sourcePalette = [
      const Color(0xFF2563EB),
      const Color(0xFF059669),
      const Color(0xFFD97706),
      const Color(0xFF7C3AED),
      const Color(0xFFDC2626),
      const Color(0xFF0D9488),
      const Color(0xFFEA580C),
      const Color(0xFF64748B),
    ];
    int colorIdx = 0;
    sourceGroups.forEach((src, leads) {
      final sCount = leads.length;
      final sPct = totalLeadsCount == 0 ? 0.0 : (sCount / totalLeadsCount * 100);
      leadSources.add(
        LeadSourceData(
          source: src,
          count: sCount,
          percentage: sPct,
          color: sourcePalette[colorIdx % sourcePalette.length],
          leads: leads,
        ),
      );
      colorIdx++;
    });
    leadSources.sort((a, b) => b.count.compareTo(a.count));

    // 10. Growth & Comparison
    final comparisonRange = _calculateComparisonRange(config);
    final previousLeads = allLeads.where((l) => comparisonRange.contains(l.createdAt)).toList();
    final previousFollowups = allFollowups.where((f) => comparisonRange.contains(f.createdAt)).toList();

    final List<GrowthComparisonItem> growthComparisonItems = [
      _buildComparisonItem(
        ReportKpiType.totalLeads,
        'Total Leads',
        totalLeadsCount,
        previousLeads.length,
      ),
      _buildComparisonItem(
        ReportKpiType.leadsContacted,
        'Leads Contacted',
        contactedCount,
        previousLeads.where((l) => _isContacted(l)).length,
      ),
      _buildComparisonItem(
        ReportKpiType.siteVisitsScheduled,
        'Site Visits Scheduled',
        visitsScheduledCount,
        previousLeads.where((l) => _isVisitScheduled(l)).length,
      ),
      _buildComparisonItem(
        ReportKpiType.convertedToWon,
        'Won Deals',
        wonCount,
        previousLeads.where((l) => _isWon(l)).length,
      ),
      _buildComparisonItem(
        ReportKpiType.callAttempted,
        'Calls Attempted',
        callAttemptedCount,
        previousFollowups.length,
      ),
    ];

    // 11. Trend Analysis Points
    final trendPoints = _generateTrendPoints(
      filteredLeads: filteredLeads,
      followups: filteredFollowups,
      metric: config.trendMetric,
      granularity: config.trendGranularity,
      dateRange: config.dateRange,
    );

    // 12. Business Insights
    final insights = InsightGenerator.generateInsights(
      totalLeads: totalLeadsCount,
      contactedCount: contactedCount,
      qualifiedCount: qualifiedCount,
      visitsDoneCount: visitsDoneCount,
      wonCount: wonCount,
      callAttemptedCount: callAttemptedCount,
      callPickedUpCount: callPickedUpCount,
      overdueFollowupsCount: overdueItems.length,
      salesRankings: salesRankings,
      telecallerRankings: telecallerRankings,
      previousLeadsCount: previousLeads.length,
    );

    return ReportOverallData(
      kpiValues: kpiValues,
      pipelineStages: pipelineStages,
      funnelStages: funnelStages,
      followupCategories: followupCategories,
      telecallerRankings: telecallerRankings,
      salesRankings: salesRankings,
      insights: insights,
      growthComparisonItems: growthComparisonItems,
      leadSources: leadSources,
      trendPoints: trendPoints,
      filteredLeads: filteredLeads,
      availableStatuses: orderedStatusList,
      availableSources: leadSources.map((s) => s.source).toList(),
      availableTelecallers: telecallers,
      availableSalesUsers: salesUsers,
      availableProperties: allProperties,
    );
  }

  // --- Helper Methods ---

  static String _extractLeadSource(RequirementModel lead) {
    if (lead.remarks != null && lead.remarks!.isNotEmpty) {
      final rem = lead.remarks!.toLowerCase();
      if (rem.contains('meta') || rem.contains('facebook') || rem.contains('fb')) return 'Facebook Ads';
      if (rem.contains('instagram') || rem.contains('insta')) return 'Instagram';
      if (rem.contains('99acres')) return '99Acres';
      if (rem.contains('magicbricks')) return 'MagicBricks';
      if (rem.contains('website') || rem.contains('web')) return 'Website';
      if (rem.contains('referral')) return 'Referral';
      if (rem.contains('whatsapp')) return 'WhatsApp';
    }
    if (lead.notes != null && lead.notes!.isNotEmpty) {
      final n = lead.notes!.toLowerCase();
      if (n.contains('meta') || n.contains('facebook')) return 'Facebook Ads';
      if (n.contains('99acres')) return '99Acres';
      if (n.contains('magicbricks')) return 'MagicBricks';
      if (n.contains('website')) return 'Website';
    }
    return 'Website'; // Default source category
  }

  static bool _isContacted(RequirementModel l) {
    final s = l.status.toLowerCase().replaceAll('-', '').replaceAll(' ', '');
    return s == 'contacted' ||
        s == 'interested' ||
        s == 'active' ||
        s == 'live' ||
        s.contains('sitevisit') ||
        s == 'negotiation' ||
        s.contains('won') ||
        s.contains('closed');
  }

  static bool _isQualified(RequirementModel l) {
    final s = l.status.toLowerCase().replaceAll('-', '').replaceAll(' ', '');
    return s == 'interested' ||
        s == 'active' ||
        s == 'live' ||
        s.contains('sitevisit') ||
        s == 'negotiation' ||
        s.contains('won') ||
        s.contains('closed');
  }

  static bool _isVisitScheduled(RequirementModel l) {
    final s = l.status.toLowerCase().replaceAll('-', '').replaceAll(' ', '');
    if (s.contains('sitevisit')) return true;
    if (l.rawSiteVisits != null && l.rawSiteVisits!.isNotEmpty) {
      return l.rawSiteVisits!.any((v) => v['status'] == 'Scheduled' || v['status'] == 'Active');
    }
    return false;
  }

  static bool _isVisitDone(RequirementModel l) {
    final s = l.status.toLowerCase().replaceAll('-', '').replaceAll(' ', '');
    if (s == 'sitevisitdone' || s == 'negotiation' || s.contains('won') || s.contains('closed')) return true;
    if (l.rawSiteVisits != null && l.rawSiteVisits!.isNotEmpty) {
      return l.rawSiteVisits!.any((v) => v['status'] == 'Completed' || v['status'] == 'Done');
    }
    return false;
  }

  static bool _isWon(RequirementModel l) {
    final s = l.status.toLowerCase();
    return s == 'won' || s == 'closed' || s.contains('won') || s.contains('closed');
  }

  static bool _isLost(RequirementModel l) {
    final s = l.status.toLowerCase();
    return s.startsWith('rejected') || s == 'lost' || s == 'dead' || s == 'suspended' || s == 'bin' || s == 'not interested';
  }

  static bool _isCallPickedUp(FollowupLocal f) {
    final s = f.status.toLowerCase();
    return s == 'completed' || s == 'done' || s == 'resolved' || s == 'interested' || s == 'connected';
  }

  static bool _isCallOpen(FollowupLocal f) {
    final s = f.status.toLowerCase();
    return s == 'pending' || s == 'open' || s == 'scheduled';
  }

  static bool _isFollowupClosed(String status) {
    final s = status.toLowerCase();
    return s == 'completed' || s == 'done' || s == 'resolved' || s == 'closed';
  }

  static List<String> _sortStatusesLogically(Set<String> statuses) {
    const order = [
      'New',
      'Not Started',
      'Follow-up',
      'Re-Followup',
      'Interested',
      'Site Visit',
      'Site Visit Sche.',
      'Site Visit Done',
      'Negotiation',
      'Won',
      'Rejected',
      'Dead',
      'Suspended',
      'Bin',
    ];

    final sorted = statuses.toList();
    sorted.sort((a, b) {
      final indexA = order.indexWhere((o) => o.toLowerCase() == a.toLowerCase());
      final indexB = order.indexWhere((o) => o.toLowerCase() == b.toLowerCase());
      final rankA = indexA >= 0 ? indexA : 99;
      final rankB = indexB >= 0 ? indexB : 99;
      return rankA.compareTo(rankB);
    });
    return sorted;
  }

  static String _formatStatusLabel(String status) {
    if (status == 'Won') return 'Deal Won';
    if (status == 'Site Visit' || status == 'Site Visit Sche.') return 'Visit Scheduled';
    if (status == 'Site Visit Done') return 'Visit Completed';
    return status;
  }

  static Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.startsWith('won')) return const Color(0xFF16A34A);
    if (s.startsWith('reject') || s == 'dead' || s == 'bin' || s == 'suspended' || s == 'lost') {
      return const Color(0xFFDC2626);
    }
    if (s.contains('visit')) return const Color(0xFF9333EA);
    if (s.contains('negotiation')) return const Color(0xFFEA580C);
    if (s.contains('follow')) return const Color(0xFFD97706);
    if (s == 'interested' || s == 'active' || s == 'live') return const Color(0xFF0284C7);
    return const Color(0xFF64748B);
  }

  static ReportDateRange _calculateComparisonRange(ReportConfiguration config) {
    final currentDuration = config.dateRange.endDate.difference(config.dateRange.startDate);
    switch (config.comparisonPeriod) {
      case GrowthComparisonPeriod.previousDay:
        final s = config.dateRange.startDate.subtract(const Duration(days: 1));
        final e = config.dateRange.endDate.subtract(const Duration(days: 1));
        return ReportDateRange.custom(start: s, end: e);
      case GrowthComparisonPeriod.previousWeek:
        final s = config.dateRange.startDate.subtract(const Duration(days: 7));
        final e = config.dateRange.endDate.subtract(const Duration(days: 7));
        return ReportDateRange.custom(start: s, end: e);
      case GrowthComparisonPeriod.previousMonth:
        final s = DateTime(config.dateRange.startDate.year, config.dateRange.startDate.month - 1, config.dateRange.startDate.day);
        final e = s.add(currentDuration);
        return ReportDateRange.custom(start: s, end: e);
      case GrowthComparisonPeriod.previousYear:
        final s = DateTime(config.dateRange.startDate.year - 1, config.dateRange.startDate.month, config.dateRange.startDate.day);
        final e = s.add(currentDuration);
        return ReportDateRange.custom(start: s, end: e);
      case GrowthComparisonPeriod.customPeriod:
        if (config.customComparisonStart != null && config.customComparisonEnd != null) {
          return ReportDateRange.custom(
            start: config.customComparisonStart!,
            end: config.customComparisonEnd!,
          );
        }
        final s = config.dateRange.startDate.subtract(currentDuration);
        final e = config.dateRange.startDate.subtract(const Duration(seconds: 1));
        return ReportDateRange.custom(start: s, end: e);
    }
  }

  static GrowthComparisonItem _buildComparisonItem(
    ReportKpiType kpiType,
    String name,
    num current,
    num previous,
  ) {
    final diff = current - previous;
    final growth = previous == 0 ? (current > 0 ? 100.0 : 0.0) : (diff / previous * 100);
    return GrowthComparisonItem(
      kpiType: kpiType,
      metricName: name,
      currentCount: current,
      previousCount: previous,
      difference: diff,
      growthPercentage: growth,
      isPositive: diff >= 0,
    );
  }

  static List<TrendDataPoint> _generateTrendPoints({
    required List<RequirementModel> filteredLeads,
    required List<FollowupLocal> followups,
    required ReportKpiType metric,
    required TrendGranularity granularity,
    required ReportDateRange dateRange,
  }) {
    final List<TrendDataPoint> points = [];
    final start = dateRange.startDate;
    final end = dateRange.endDate;

    DateTime cur = DateTime(start.year, start.month, start.day);
    while (cur.isBefore(end) || cur.isAtSameMomentAs(DateTime(end.year, end.month, end.day))) {
      DateTime next;
      String label;
      if (granularity == TrendGranularity.daily) {
        next = cur.add(const Duration(days: 1));
        label = DateFormat('d MMM').format(cur);
      } else if (granularity == TrendGranularity.weekly) {
        next = cur.add(const Duration(days: 7));
        label = 'Wk ${DateFormat('d MMM').format(cur)}';
      } else {
        next = DateTime(cur.year, cur.month + 1, 1);
        label = DateFormat('MMM yy').format(cur);
      }

      int val = 0;
      if (metric == ReportKpiType.callAttempted || metric == ReportKpiType.callPickedUp) {
        final curFollowups = followups.where((f) => f.createdAt.isAfter(cur) && f.createdAt.isBefore(next));
        if (metric == ReportKpiType.callAttempted) {
          val = curFollowups.length;
        } else {
          val = curFollowups.where((f) => _isCallPickedUp(f)).length;
        }
      } else {
        final curLeads = filteredLeads.where((l) => l.createdAt.isAfter(cur) && l.createdAt.isBefore(next));
        switch (metric) {
          case ReportKpiType.totalLeads:
            val = curLeads.length;
            break;
          case ReportKpiType.leadsContacted:
            val = curLeads.where((l) => _isContacted(l)).length;
            break;
          case ReportKpiType.leadQualificationRate:
            val = curLeads.where((l) => _isQualified(l)).length;
            break;
          case ReportKpiType.siteVisitsScheduled:
            val = curLeads.where((l) => _isVisitScheduled(l)).length;
            break;
          case ReportKpiType.siteVisitsDone:
            val = curLeads.where((l) => _isVisitDone(l)).length;
            break;
          case ReportKpiType.convertedToWon:
            val = curLeads.where((l) => _isWon(l)).length;
            break;
          case ReportKpiType.lostUnsuccessful:
            val = curLeads.where((l) => _isLost(l)).length;
            break;
          default:
            val = curLeads.length;
        }
      }

      points.add(TrendDataPoint(date: cur, label: label, value: val));
      cur = next;
    }

    return points;
  }
}
