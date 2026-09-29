class SourceSummary {
  final int total;
  final int propertyListing;
  final int requirement;
  final int notInterested;
  final int rejected;

  const SourceSummary({
    required this.total,
    required this.propertyListing,
    required this.requirement,
    this.notInterested = 0,
    this.rejected = 0,
  });

  factory SourceSummary.fromJson(Map<String, dynamic> json) {
    return SourceSummary(
      total: json['total'] as int? ?? 0,
      propertyListing: json['property_listing'] as int? ?? 0,
      requirement: json['requirement'] as int? ?? 0,
      notInterested: json['not_interested'] as int? ?? 0,
      rejected: json['rejected'] as int? ?? 0,
    );
  }
}

class PropertyListingKpis {
  final int totalListingLeads;
  final int callOutcomes;
  final int followUps;
  final int cnr;
  final int callback;
  final int notInterested;
  final int archivedProperty;
  final int wrongLead;

  const PropertyListingKpis({
    required this.totalListingLeads,
    required this.callOutcomes,
    required this.followUps,
    required this.cnr,
    required this.callback,
    required this.notInterested,
    required this.archivedProperty,
    required this.wrongLead,
  });

  factory PropertyListingKpis.fromJson(Map<String, dynamic> json) {
    return PropertyListingKpis(
      totalListingLeads: json['total_listing_leads'] as int? ?? 0,
      callOutcomes: json['call_outcomes'] as int? ?? 0,
      followUps: json['follow_ups'] as int? ?? 0,
      cnr: json['cnr'] as int? ?? 0,
      callback: json['callback'] as int? ?? 0,
      notInterested: json['not_interested'] as int? ?? 0,
      archivedProperty: json['archived_property'] as int? ?? 0,
      wrongLead: json['wrong_lead'] as int? ?? 0,
    );
  }
}

class PropertyListingSummary {
  final int total;
  final Map<String, int> bySource;
  final PropertyListingKpis kpis;
  final Map<String, PropertyListingKpis> kpisBySource;

  const PropertyListingSummary({
    required this.total,
    required this.bySource,
    required this.kpis,
    this.kpisBySource = const {},
  });

  factory PropertyListingSummary.fromJson(Map<String, dynamic> json) {
    final rawBySource = json['by_source'] as Map<String, dynamic>? ?? {};
    final bySource = rawBySource.map((k, v) => MapEntry(k, v as int? ?? 0));
    final defaultKpis = PropertyListingKpis.fromJson(json['kpis'] as Map<String, dynamic>? ?? {});
    final rawKpisBySource = json['kpis_by_source'] as Map<String, dynamic>? ?? {};
    final kpisBySource = rawKpisBySource.map(
      (k, v) => MapEntry(k.toLowerCase(), PropertyListingKpis.fromJson(v as Map<String, dynamic>? ?? {})),
    );

    return PropertyListingSummary(
      total: json['total'] as int? ?? 0,
      bySource: bySource,
      kpis: defaultKpis,
      kpisBySource: kpisBySource,
    );
  }

  PropertyListingKpis getKpisForSource(String source) {
    final key = source.toLowerCase();
    if (key == 'all' || key == 'all sources') return kpisBySource['all'] ?? kpis;
    return kpisBySource[key] ?? kpis;
  }
}

class RequirementKpis {
  final int totalRequirementLeads;
  final int followUps;
  final int wrongLead;
  final int notInterested;
  final int archived;
  final int transferPickedUp;
  final int callback;
  final int cnr;

  const RequirementKpis({
    required this.totalRequirementLeads,
    required this.followUps,
    required this.wrongLead,
    required this.notInterested,
    required this.archived,
    required this.transferPickedUp,
    required this.callback,
    required this.cnr,
  });

  factory RequirementKpis.fromJson(Map<String, dynamic> json) {
    return RequirementKpis(
      totalRequirementLeads: json['total_requirement_leads'] as int? ?? 0,
      followUps: json['follow_ups'] as int? ?? 0,
      wrongLead: json['wrong_lead'] as int? ?? 0,
      notInterested: json['not_interested'] as int? ?? 0,
      archived: json['archived'] as int? ?? 0,
      transferPickedUp: json['transfer_picked_up'] as int? ?? 0,
      callback: json['callback'] as int? ?? 0,
      cnr: json['cnr'] as int? ?? 0,
    );
  }
}

class RequirementSummary {
  final int total;
  final Map<String, int> bySource;
  final RequirementKpis kpis;
  final Map<String, RequirementKpis> kpisBySource;

  const RequirementSummary({
    required this.total,
    required this.bySource,
    required this.kpis,
    this.kpisBySource = const {},
  });

  factory RequirementSummary.fromJson(Map<String, dynamic> json) {
    final rawBySource = json['by_source'] as Map<String, dynamic>? ?? {};
    final bySource = rawBySource.map((k, v) => MapEntry(k, v as int? ?? 0));
    final defaultKpis = RequirementKpis.fromJson(json['kpis'] as Map<String, dynamic>? ?? {});
    final rawKpisBySource = json['kpis_by_source'] as Map<String, dynamic>? ?? {};
    final kpisBySource = rawKpisBySource.map(
      (k, v) => MapEntry(k.toLowerCase(), RequirementKpis.fromJson(v as Map<String, dynamic>? ?? {})),
    );

    return RequirementSummary(
      total: json['total'] as int? ?? 0,
      bySource: bySource,
      kpis: defaultKpis,
      kpisBySource: kpisBySource,
    );
  }

  RequirementKpis getKpisForSource(String source) {
    final key = source.toLowerCase();
    if (key == 'all' || key == 'all sources') return kpisBySource['all'] ?? kpis;
    return kpisBySource[key] ?? kpis;
  }
}

class TelecallerSourceBreakdown {
  final int prop;
  final int req;
  final int total;

  const TelecallerSourceBreakdown({
    required this.prop,
    required this.req,
    required this.total,
  });

  factory TelecallerSourceBreakdown.fromJson(Map<String, dynamic> json) {
    return TelecallerSourceBreakdown(
      prop: json['prop'] as int? ?? 0,
      req: json['req'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
    );
  }
}

class TelecallerStatusCounts {
  final int cnr;
  final int callback;
  final int contacted;
  final int handedToSales;
  final int notInterested;

  const TelecallerStatusCounts({
    required this.cnr,
    required this.callback,
    required this.contacted,
    required this.handedToSales,
    required this.notInterested,
  });

  factory TelecallerStatusCounts.fromJson(Map<String, dynamic> json) {
    return TelecallerStatusCounts(
      cnr: json['cnr'] as int? ?? 0,
      callback: json['callback'] as int? ?? 0,
      contacted: json['contacted'] as int? ?? 0,
      handedToSales: json['handed_to_sales'] as int? ?? 0,
      notInterested: json['not_interested'] as int? ?? 0,
    );
  }
}

class TelecallerSummaryItem {
  final String id;
  final String name;
  final String email;
  final int totalLeads;
  final int propListingLeads;
  final int reqLeads;
  final Map<String, TelecallerSourceBreakdown> sources;
  final TelecallerStatusCounts statusCounts;

  const TelecallerSummaryItem({
    required this.id,
    required this.name,
    required this.email,
    required this.totalLeads,
    required this.propListingLeads,
    required this.reqLeads,
    required this.sources,
    required this.statusCounts,
  });

  factory TelecallerSummaryItem.fromJson(Map<String, dynamic> json) {
    final rawSources = json['sources'] as Map<String, dynamic>? ?? {};
    final sources = rawSources.map(
      (k, v) => MapEntry(k, TelecallerSourceBreakdown.fromJson(v as Map<String, dynamic>? ?? {})),
    );

    return TelecallerSummaryItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      totalLeads: json['total_leads'] as int? ?? 0,
      propListingLeads: json['prop_listing_leads'] as int? ?? 0,
      reqLeads: json['req_leads'] as int? ?? 0,
      sources: sources,
      statusCounts: TelecallerStatusCounts.fromJson(json['status_counts'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class TelecallerListSummary {
  final int totalCount;
  final List<TelecallerSummaryItem> list;

  const TelecallerListSummary({
    required this.totalCount,
    required this.list,
  });

  factory TelecallerListSummary.fromJson(Map<String, dynamic> json) {
    final rawList = json['list'] as List<dynamic>? ?? [];
    return TelecallerListSummary(
      totalCount: json['total_count'] as int? ?? 0,
      list: rawList.map((e) => TelecallerSummaryItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

// -------------------------------------------------------------
// NEW CAMPAIGN KPI MODELS
// -------------------------------------------------------------

class SourcePropReqBreakdown {
  final int total;
  final int propertyListing;
  final int requirement;

  const SourcePropReqBreakdown({
    required this.total,
    this.propertyListing = 0,
    this.requirement = 0,
  });

  factory SourcePropReqBreakdown.fromJson(Map<String, dynamic> json) {
    return SourcePropReqBreakdown(
      total: json['total'] as int? ?? 0,
      propertyListing: json['property_listing'] as int? ?? 0,
      requirement: json['requirement'] as int? ?? 0,
    );
  }
}

class NewOpenLeadsSummary {
  final int total;
  final Map<String, SourcePropReqBreakdown> bySource;

  const NewOpenLeadsSummary({
    required this.total,
    required this.bySource,
  });

  factory NewOpenLeadsSummary.fromJson(Map<String, dynamic> json) {
    final rawBySource = json['by_source'] as Map<String, dynamic>? ?? {};
    final bySource = rawBySource.map(
      (k, v) => MapEntry(k, SourcePropReqBreakdown.fromJson(v as Map<String, dynamic>? ?? {})),
    );
    return NewOpenLeadsSummary(
      total: json['total'] as int? ?? 0,
      bySource: bySource,
    );
  }
}

class CnrLeadsSummary {
  final int total;
  final Map<String, SourcePropReqBreakdown> bySource;

  const CnrLeadsSummary({
    required this.total,
    required this.bySource,
  });

  factory CnrLeadsSummary.fromJson(Map<String, dynamic> json) {
    final rawBySource = json['by_source'] as Map<String, dynamic>? ?? {};
    final bySource = rawBySource.map(
      (k, v) => MapEntry(k, SourcePropReqBreakdown.fromJson(v as Map<String, dynamic>? ?? {})),
    );
    return CnrLeadsSummary(
      total: json['total'] as int? ?? 0,
      bySource: bySource,
    );
  }
}

class CallbackLeadsSummary {
  final int total;
  final Map<String, SourcePropReqBreakdown> bySource;

  const CallbackLeadsSummary({
    required this.total,
    required this.bySource,
  });

  factory CallbackLeadsSummary.fromJson(Map<String, dynamic> json) {
    final rawBySource = json['by_source'] as Map<String, dynamic>? ?? {};
    final bySource = rawBySource.map(
      (k, v) => MapEntry(k, SourcePropReqBreakdown.fromJson(v as Map<String, dynamic>? ?? {})),
    );
    return CallbackLeadsSummary(
      total: json['total'] as int? ?? 0,
      bySource: bySource,
    );
  }
}

class SourceCountBreakdown {
  final int total;
  final Map<String, int> bySource;

  const SourceCountBreakdown({
    required this.total,
    required this.bySource,
  });

  factory SourceCountBreakdown.fromJson(Map<String, dynamic> json) {
    final rawBySource = json['by_source'] as Map<String, dynamic>? ?? {};
    final bySource = rawBySource.map((k, v) => MapEntry(k, v as int? ?? 0));
    return SourceCountBreakdown(
      total: json['total'] as int? ?? 0,
      bySource: bySource,
    );
  }
}

class TelecallerSalesAssignmentItem {
  final String telecallerId;
  final String telecallerName;
  final int count;

  const TelecallerSalesAssignmentItem({
    required this.telecallerId,
    required this.telecallerName,
    required this.count,
  });

  factory TelecallerSalesAssignmentItem.fromJson(Map<String, dynamic> json) {
    return TelecallerSalesAssignmentItem(
      telecallerId: json['telecaller_id'] as String? ?? 'unassigned',
      telecallerName: json['telecaller_name'] as String? ?? 'Direct / Unassigned',
      count: json['count'] as int? ?? 0,
    );
  }
}

class AssignedToSalesSummary {
  final int total;
  final List<TelecallerSalesAssignmentItem> byTelecaller;

  const AssignedToSalesSummary({
    required this.total,
    required this.byTelecaller,
  });

  factory AssignedToSalesSummary.fromJson(Map<String, dynamic> json) {
    final rawList = json['by_telecaller'] as List<dynamic>? ?? [];
    return AssignedToSalesSummary(
      total: json['total'] as int? ?? 0,
      byTelecaller: rawList.map((e) => TelecallerSalesAssignmentItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class LeadsPageKpisSummary {
  final int notStarted;
  final int callAttempted;
  final int callAttemptedPickedUp;
  final int callAttemptedOpen;
  final int followUps;
  final int reFollowUps;
  final int interested;
  final int siteVisitScheduled;
  final int siteVisitDone;
  final int negotiation;
  final int rejectedLeads;

  const LeadsPageKpisSummary({
    this.notStarted = 0,
    this.callAttempted = 0,
    this.callAttemptedPickedUp = 0,
    this.callAttemptedOpen = 0,
    this.followUps = 0,
    this.reFollowUps = 0,
    this.interested = 0,
    this.siteVisitScheduled = 0,
    this.siteVisitDone = 0,
    this.negotiation = 0,
    this.rejectedLeads = 0,
  });

  factory LeadsPageKpisSummary.fromJson(Map<String, dynamic> json) {
    return LeadsPageKpisSummary(
      notStarted: json['not_started'] as int? ?? 0,
      callAttempted: json['call_attempted'] as int? ?? 0,
      callAttemptedPickedUp: json['call_attempted_picked_up'] as int? ?? 0,
      callAttemptedOpen: json['call_attempted_open'] as int? ?? 0,
      followUps: json['follow_ups'] as int? ?? 0,
      reFollowUps: json['re_follow_ups'] as int? ?? 0,
      interested: json['interested'] as int? ?? 0,
      siteVisitScheduled: json['site_visit_scheduled'] as int? ?? 0,
      siteVisitDone: json['site_visit_done'] as int? ?? 0,
      negotiation: json['negotiation'] as int? ?? 0,
      rejectedLeads: json['rejected_leads'] as int? ?? 0,
    );
  }
}

class BusinessInsightSummary {
  final int totalLeads;
  final Map<String, SourceSummary> sources;
  final PropertyListingSummary propertyListingLeads;
  final RequirementSummary requirementLeads;
  final TelecallerListSummary telecallers;
  final NewOpenLeadsSummary newOpenLeads;
  final CnrLeadsSummary cnrLeads;
  final CallbackLeadsSummary callbackLeads;
  final SourceCountBreakdown followupLeads;
  final SourceCountBreakdown notInterestedLeads;
  final AssignedToSalesSummary assignedToSalesPickedUp;
  final LeadsPageKpisSummary leadsPageKpis;

  const BusinessInsightSummary({
    required this.totalLeads,
    required this.sources,
    required this.propertyListingLeads,
    required this.requirementLeads,
    required this.telecallers,
    this.newOpenLeads = const NewOpenLeadsSummary(total: 0, bySource: {}),
    this.cnrLeads = const CnrLeadsSummary(total: 0, bySource: {}),
    this.callbackLeads = const CallbackLeadsSummary(total: 0, bySource: {}),
    this.followupLeads = const SourceCountBreakdown(total: 0, bySource: {}),
    this.notInterestedLeads = const SourceCountBreakdown(total: 0, bySource: {}),
    this.assignedToSalesPickedUp = const AssignedToSalesSummary(total: 0, byTelecaller: []),
    this.leadsPageKpis = const LeadsPageKpisSummary(),
  });

  const BusinessInsightSummary.empty()
      : totalLeads = 0,
        sources = const {},
        propertyListingLeads = const PropertyListingSummary(
          total: 0,
          bySource: {},
          kpis: PropertyListingKpis(
            totalListingLeads: 0,
            callOutcomes: 0,
            followUps: 0,
            cnr: 0,
            callback: 0,
            notInterested: 0,
            archivedProperty: 0,
            wrongLead: 0,
          ),
        ),
        requirementLeads = const RequirementSummary(
          total: 0,
          bySource: {},
          kpis: RequirementKpis(
            totalRequirementLeads: 0,
            followUps: 0,
            wrongLead: 0,
            notInterested: 0,
            archived: 0,
            transferPickedUp: 0,
            callback: 0,
            cnr: 0,
          ),
        ),
        telecallers = const TelecallerListSummary(totalCount: 0, list: []),
        newOpenLeads = const NewOpenLeadsSummary(total: 0, bySource: {}),
        cnrLeads = const CnrLeadsSummary(total: 0, bySource: {}),
        callbackLeads = const CallbackLeadsSummary(total: 0, bySource: {}),
        followupLeads = const SourceCountBreakdown(total: 0, bySource: {}),
        notInterestedLeads = const SourceCountBreakdown(total: 0, bySource: {}),
        assignedToSalesPickedUp = const AssignedToSalesSummary(total: 0, byTelecaller: []),
        leadsPageKpis = const LeadsPageKpisSummary();

  factory BusinessInsightSummary.fromJson(Map<String, dynamic> json) {
    final rawSources = json['sources'] as Map<String, dynamic>? ?? {};
    final sources = rawSources.map(
      (k, v) => MapEntry(k, SourceSummary.fromJson(v as Map<String, dynamic>? ?? {})),
    );

    return BusinessInsightSummary(
      totalLeads: json['total_leads'] as int? ?? 0,
      sources: sources,
      propertyListingLeads: PropertyListingSummary.fromJson(json['property_listing_leads'] as Map<String, dynamic>? ?? {}),
      requirementLeads: RequirementSummary.fromJson(json['requirement_leads'] as Map<String, dynamic>? ?? {}),
      telecallers: TelecallerListSummary.fromJson(json['telecallers'] as Map<String, dynamic>? ?? {}),
      newOpenLeads: NewOpenLeadsSummary.fromJson(json['new_open_leads'] as Map<String, dynamic>? ?? {}),
      cnrLeads: CnrLeadsSummary.fromJson(json['cnr_leads'] as Map<String, dynamic>? ?? {}),
      callbackLeads: CallbackLeadsSummary.fromJson(json['callback_leads'] as Map<String, dynamic>? ?? {}),
      followupLeads: SourceCountBreakdown.fromJson(json['followup_leads'] as Map<String, dynamic>? ?? {}),
      notInterestedLeads: SourceCountBreakdown.fromJson(json['not_interested_leads'] as Map<String, dynamic>? ?? {}),
      assignedToSalesPickedUp: AssignedToSalesSummary.fromJson(json['assigned_to_sales_picked_up'] as Map<String, dynamic>? ?? {}),
      leadsPageKpis: LeadsPageKpisSummary.fromJson(json['leads_page_kpis'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class BusinessInsightLead {
  final String id;
  final String customerName;
  final String phone;
  final String email;
  final String source;
  final String leadType;
  final String stage;
  final String allocationStatus;
  final String callDisposition;
  final String? rejectionReason;
  final String? telecallerName;
  final String? salespersonName;
  final String? cnrRemark;
  final String? callbackRemark;
  final String? followupRemark;
  final String? notInterestedRemark;
  final String? assignmentRemark;
  final String? salespersonWorkflowStatus;
  final DateTime? salesAssignedAt;
  final DateTime? telecallerAssignedAt;
  final DateTime? createdAt;

  const BusinessInsightLead({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.email,
    required this.source,
    required this.leadType,
    required this.stage,
    required this.allocationStatus,
    required this.callDisposition,
    this.rejectionReason,
    this.telecallerName,
    this.salespersonName,
    this.cnrRemark,
    this.callbackRemark,
    this.followupRemark,
    this.notInterestedRemark,
    this.assignmentRemark,
    this.salespersonWorkflowStatus,
    this.salesAssignedAt,
    this.telecallerAssignedAt,
    this.createdAt,
  });

  factory BusinessInsightLead.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      try {
        return DateTime.parse(val.toString());
      } catch (_) {
        return null;
      }
    }

    return BusinessInsightLead(
      id: json['id'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? 'Lead',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      source: json['source'] as String? ?? '',
      leadType: json['lead_type'] as String? ?? '',
      stage: json['stage'] as String? ?? 'NEW',
      allocationStatus: json['allocation_status'] as String? ?? 'UNASSIGNED',
      callDisposition: json['call_disposition'] as String? ?? 'NOT_ATTEMPTED',
      rejectionReason: json['rejection_reason'] as String?,
      telecallerName: json['telecaller_name'] as String?,
      salespersonName: json['salesperson_name'] as String?,
      cnrRemark: json['cnr_remark'] as String?,
      callbackRemark: json['callback_remark'] as String?,
      followupRemark: json['followup_remark'] as String?,
      notInterestedRemark: json['not_interested_remark'] as String?,
      assignmentRemark: json['assignment_remark'] as String?,
      salespersonWorkflowStatus: json['salesperson_workflow_status'] as String?,
      salesAssignedAt: parseDate(json['sales_assigned_at']),
      telecallerAssignedAt: parseDate(json['telecaller_assigned_at']),
      createdAt: parseDate(json['created_at']),
    );
  }
}
