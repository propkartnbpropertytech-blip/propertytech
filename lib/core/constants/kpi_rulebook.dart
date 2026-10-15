/// ============================================================================
/// PROPKART MASTER KPI GOVERNANCE RULEBOOK & FRONTEND REGISTRY
/// ============================================================================
/// 
/// ⚠️ CRITICAL GOVERNANCE MANDATE:
/// Before creating, modifying, or renaming any KPI Card, StatCard, Drilldown Dialog,
/// or Report Section in Flutter, you MUST consult and adhere to this Master Rulebook
/// and docs/KPIs.docx.
/// 
/// CANONICAL DATABASE ENUMS (Hostinger PostgreSQL Live Database):
/// 1. listing_types: ['RENT', 'RESALE'] (Case-insensitive ILIKE '%Rent%', ILIKE '%Sale%')
///    -> NEVER filter by 'Rental Property' or 'Re-sale'.
/// 
/// 2. property_status: ['Available', 'To Be Available', 'Rented Out', 'Sold Out']
///    -> NEVER filter by 'Rented' or 'Sold'.
/// 
/// 3. leads.lead_type: ['Property Listing', 'Requirement']
///    -> NEVER filter by 'Listing', 'Owner', or 'Tenant'.
/// 
/// 4. leads.stage: ['NEW', 'INTERESTED', 'SALES', 'SITE_VISIT', 'LISTED', 'WON', 'LOST', 'ARCHIVED']
///    -> NEVER filter by 'Assigned to Sales'.
/// 
/// 5. leads.allocation_status: ['ASSIGNED_TO_TELECALLER', 'CALLBACK', 'CNR', 'DIRECT_SALES', 'FOLLOWUP', 'HANDED_TO_SALES']
///    -> NEVER filter by 'Allocated'.
/// 
/// 6. requirements.status: ['Not Started', 'New', 'Assigned', 'Live', 'Call Attempted (Open)',
///                          'Follow-up', 'Re-Followup', 'Interested', 'Site Visit', 'Site Visit Done', 'Won']
///    -> NEVER filter by 'Active' (status = 'Active' does not exist in requirements).
/// 
/// 7. site_visits.status & outcome: ['COMPLETED', 'Pending'], outcome: ['INTERESTED', 'REJECTED_AFTER_VISIT', 'DEAL_WON']
/// ============================================================================

library;

class MasterKpiDefinition {
  final int id;
  final String key;
  final String name;
  final String screenLocation;
  final List<String> repeatingScreens;
  final String drilldownAction;
  final String databaseMapping;
  final String businessPurpose;

  const MasterKpiDefinition({
    required this.id,
    required this.key,
    required this.name,
    required this.screenLocation,
    required this.repeatingScreens,
    required this.drilldownAction,
    required this.databaseMapping,
    required this.businessPurpose,
  });
}

class MasterKpiRulebook {
  static const Map<String, MasterKpiDefinition> kpis = {
    // ── Admin Dashboard Headline & Operations (KPIs 1–13) ──
    'available_inventory': MasterKpiDefinition(
      id: 1,
      key: 'available_inventory',
      name: 'Available Inventory',
      screenLocation: 'Admin Dashboard',
      repeatingScreens: ['Properties Page', 'Reports Overview', 'Sales Dashboard'],
      drilldownAction: 'Inventory Drilldown Dialog (status = Available)',
      databaseMapping: "properties.property_status_id -> name = 'Available' AND deleted_at IS NULL",
      businessPurpose: 'Shows marketable properties ready for immediate tenant or buyer placement.',
    ),
    'total_leads': MasterKpiDefinition(
      id: 2,
      key: 'total_leads',
      name: 'Total Leads',
      screenLocation: 'Admin Dashboard',
      repeatingScreens: ['Reports Page (Campaign KPIs)', 'Leads Page'],
      drilldownAction: 'Leads Drilldown Dialog (active date filter)',
      databaseMapping: 'leads.id (COUNT WHERE deleted_at IS NULL)',
      businessPurpose: 'Measures total top-of-funnel customer volume across Meta, Housing, and Direct.',
    ),
    'telecallers': MasterKpiDefinition(
      id: 3,
      key: 'telecallers',
      name: 'Telecallers',
      screenLocation: 'Admin Dashboard',
      repeatingScreens: ['Reports Page', 'Telecaller Report Screen'],
      drilldownAction: 'Telecaller Performance Dialog',
      databaseMapping: "users.role_id -> name = 'Telecaller' AND is_active = true",
      businessPurpose: 'Tracks telecalling capacity and operational workforce handling intake calls.',
    ),
    'leads_allocated': MasterKpiDefinition(
      id: 4,
      key: 'leads_allocated',
      name: 'New Leads Allocated',
      screenLocation: 'Admin Dashboard',
      repeatingScreens: ['Telecaller Dashboard'],
      drilldownAction: 'Leads Allocated Dialog',
      databaseMapping: 'leads.assigned_telecaller_id IS NOT NULL AND (created_at >= from_date OR is_old = 0)',
      businessPurpose: 'Tracks fresh, first-time leads assigned to telecallers during the period.',
    ),
    'old_leads_allocated': MasterKpiDefinition(
      id: 5,
      key: 'old_leads_allocated',
      name: 'Old Leads Allocated',
      screenLocation: 'Admin Dashboard',
      repeatingScreens: ['Telecaller Dashboard'],
      drilldownAction: 'Leads Allocated Dialog',
      databaseMapping: 'leads.assigned_telecaller_id IS NOT NULL AND (created_at < from_date OR is_old = 1)',
      businessPurpose: 'Monitors recycled backlog and re-engaged historical leads distributed to telecallers.',
    ),
    'cnr': MasterKpiDefinition(
      id: 6,
      key: 'cnr',
      name: 'CNR (No Response)',
      screenLocation: 'Admin Dashboard',
      repeatingScreens: ['Telecaller Dashboard', 'Reports Page'],
      drilldownAction: 'Leads Drilldown Dialog (call_disposition = CNR)',
      databaseMapping: "leads.call_disposition = 'CNR' OR leads.allocation_status = 'CNR'",
      businessPurpose: 'Monitors unreached lead volume where client could not be contacted; prompts re-dial.',
    ),
    'not_interested': MasterKpiDefinition(
      id: 7,
      key: 'not_interested',
      name: 'Not Interested',
      screenLocation: 'Admin Dashboard',
      repeatingScreens: ['Telecaller Dashboard', 'Reports Page'],
      drilldownAction: 'Not Interested Drilldown Dialog',
      databaseMapping: "leads.call_disposition = 'NOT_INTERESTED' OR leads.stage = 'LOST'",
      businessPurpose: 'Monitors early campaign lead fallout and disqualification rates from ad sources.',
    ),
    'sales_users': MasterKpiDefinition(
      id: 8,
      key: 'sales_users',
      name: 'Sales Users',
      screenLocation: 'Admin Dashboard',
      repeatingScreens: ['Reports Page'],
      drilldownAction: 'Sales Team Lifecycle Modal',
      databaseMapping: "users.role_id -> name = 'Sales' AND is_active = true",
      businessPurpose: 'Tracks active closing executives and relationship managers available in the field.',
    ),
    'assigned_to_sales': MasterKpiDefinition(
      id: 9,
      key: 'assigned_to_sales',
      name: 'Assigned to Sales',
      screenLocation: 'Admin Dashboard',
      repeatingScreens: ['Telecaller Dashboard', 'Reports Page (Qualified Tab)'],
      drilldownAction: 'Assigned to Sales Dialog',
      databaseMapping: 'leads.assigned_to IS NOT NULL AND deleted_at IS NULL',
      businessPurpose: 'Evaluates lead qualification yield transferred from telecallers to field sales.',
    ),
    'site_visits_done': MasterKpiDefinition(
      id: 10,
      key: 'site_visits_done',
      name: 'Site Visits Done',
      screenLocation: 'Admin Dashboard',
      repeatingScreens: ['Sales Dashboard', 'Reports Page (Sales Pipeline)'],
      drilldownAction: 'Site Visits Modal',
      databaseMapping: "site_visits.status = 'COMPLETED' (Reports Sales Pipeline counts requirements status 'Site Visit Done')",
      businessPurpose: 'Tracks in-person physical property inspections conducted with prospective clients.',
    ),
    'site_visits_scheduled': MasterKpiDefinition(
      id: 11,
      key: 'site_visits_scheduled',
      name: 'Site Visits Scheduled',
      screenLocation: 'Sales Dashboard',
      repeatingScreens: ['Reports Page (CRM Pipeline)'],
      drilldownAction: 'Site Visits Scheduled Calendar & List',
      databaseMapping: "site_visits.status = 'Pending' AND visit_date >= CURRENT_DATE",
      businessPurpose: 'Forward-looking indicator of upcoming booked client walkthroughs.',
    ),
    'rejected_after_site_visit': MasterKpiDefinition(
      id: 12,
      key: 'rejected_after_site_visit',
      name: 'Rejected After Visit',
      screenLocation: 'Admin Dashboard',
      repeatingScreens: ['Sales Dashboard'],
      drilldownAction: 'Rejection Drilldown (outcome = REJECTED_AFTER_VISIT)',
      databaseMapping: "site_visits.outcome = 'REJECTED_AFTER_VISIT' OR (outcome IS NULL AND requirements.status ILIKE 'Rejected%')",
      businessPurpose: 'Measures visit fallout to identify mismatched client expectations or pricing gaps.',
    ),
    'deal_won': MasterKpiDefinition(
      id: 13,
      key: 'deal_won',
      name: 'Deal Won',
      screenLocation: 'Admin Dashboard',
      repeatingScreens: ['Sales Dashboard', 'Reports Page'],
      drilldownAction: 'Deal Won Dialog',
      databaseMapping: "requirements.status = 'Won' (Reports counts status IN ('Won','Deal Won','Closed'))",
      businessPurpose: 'Measures ultimate commercial conversion and revenue generation.',
    ),

    // ── Reports Page Inventory Sourcing (KPIs 14–20) ──
    'total_portfolio': MasterKpiDefinition(
      id: 14,
      key: 'total_portfolio',
      name: 'Total Portfolio',
      screenLocation: 'Reports Page (Inventory Sourcing)',
      repeatingScreens: ['Properties Page Total Header'],
      drilldownAction: 'Inventory Drilldown Dialog (all properties)',
      databaseMapping: 'properties.deleted_at IS NULL (joins status, listing_types, users, roles)',
      businessPurpose: 'Measures total property inventory assets managed by PropKart.',
    ),
    'properties_by_sales': MasterKpiDefinition(
      id: 15,
      key: 'properties_by_sales_available',
      name: 'Inventory Added by Sales',
      screenLocation: 'Reports Page (Inventory Sourcing)',
      repeatingScreens: ['None (Exclusive to Reports Sourcing)'],
      drilldownAction: 'Inventory Drilldown Dialog (Creator = Sales)',
      databaseMapping: "properties.created_by = users.id WHERE roles.name = 'Sales'. Headline displays Available count; Subtitle displays Total count.",
      businessPurpose: 'Measures property sourcing contribution directly onboarded by field sales reps.',
    ),
    'properties_by_telecaller': MasterKpiDefinition(
      id: 16,
      key: 'properties_by_telecaller_available',
      name: 'Inventory Added by Telecaller',
      screenLocation: 'Reports Page (Inventory Sourcing)',
      repeatingScreens: ['None (Exclusive to Reports Sourcing)'],
      drilldownAction: 'Inventory Drilldown Dialog (Creator = Telecaller)',
      databaseMapping: "properties.created_by = users.id WHERE roles.name IN ('Telecaller','Tele Caller'). Headline displays Available count; Subtitle displays Total count.",
      businessPurpose: 'Measures inventory sourced from inbound landlord calls handled by telecallers.',
    ),
    'properties_by_admin': MasterKpiDefinition(
      id: 17,
      key: 'properties_by_admin_available',
      name: 'Inventory Added by Admin',
      screenLocation: 'Reports Page (Inventory Sourcing)',
      repeatingScreens: ['None (Exclusive to Reports Sourcing)'],
      drilldownAction: 'Inventory Drilldown Dialog (Creator = Admin)',
      databaseMapping: "properties.created_by = users.id WHERE roles.name = 'Admin'. Headline displays Available count; Subtitle displays Total count.",
      businessPurpose: 'Measures property inventory onboarded directly by executive management.',
    ),
    'rental_properties': MasterKpiDefinition(
      id: 18,
      key: 'rental_count',
      name: 'Rental Properties',
      screenLocation: 'Reports Page (Inventory Sourcing)',
      repeatingScreens: ["Properties Page ('RENT' filter)"],
      drilldownAction: 'Inventory Drilldown Dialog (businessType = Rent)',
      databaseMapping: "properties.listing_type_id -> listing_types.name = 'RENT'",
      businessPurpose: 'Quantifies rental supply available to fulfill tenant requirements.',
    ),
    'resale_properties': MasterKpiDefinition(
      id: 19,
      key: 'resale_count',
      name: 'Re-sale Properties',
      screenLocation: 'Reports Page (Inventory Sourcing)',
      repeatingScreens: ["Properties Page ('RESALE' filter)"],
      drilldownAction: 'Inventory Drilldown Dialog (businessType = Re-sale)',
      databaseMapping: "properties.listing_type_id -> listing_types.name = 'RESALE'",
      businessPurpose: 'Quantifies residential & commercial sale inventory available for buyers.',
    ),
    'rented_sold_out': MasterKpiDefinition(
      id: 20,
      key: 'rented_sold_out',
      name: 'Rented / Sold Out',
      screenLocation: 'Reports Page (Inventory Sourcing)',
      repeatingScreens: ['Properties Page non-available status'],
      drilldownAction: 'Inventory Drilldown Dialog',
      databaseMapping: "properties.property_status_id -> property_status.name IN ('Rented Out', 'Sold Out'). Value is sum of rentedOutCount + soldOutCount.",
      businessPurpose: 'Evaluates inventory turnover, completed tenancies, and successfully sold units.',
    ),

    // ── Reports Page Manual / Direct Leads (KPIs 21–24) ──
    'manual_leads_total': MasterKpiDefinition(
      id: 21,
      key: 'manual_leads_total',
      name: 'Total Direct Leads',
      screenLocation: 'Reports Page (Manual Leads Tab)',
      repeatingScreens: ['None (Exclusive to Reports)'],
      drilldownAction: 'Leads Drilldown Dialog (initialSource = DIRECT)',
      databaseMapping: "leads.source ILIKE '%manual%' OR leads.source ILIKE '%direct%'",
      businessPurpose: 'Tracks non-paid organic, walk-in, offline, and referral lead acquisition.',
    ),
    'manual_leads_by_sales': MasterKpiDefinition(
      id: 22,
      key: 'manual_leads_by_sales',
      name: 'Direct Leads by Sales',
      screenLocation: 'Reports Page (Manual Leads Tab)',
      repeatingScreens: ['None (Exclusive to Reports)'],
      drilldownAction: 'Leads Drilldown Dialog (initialSource = MANUAL)',
      databaseMapping: "leads.created_by = users.id WHERE roles.name = 'Sales' AND leads.source is direct/manual",
      businessPurpose: 'Evaluates sales rep direct self-sourcing and personal network utilization.',
    ),
    'manual_leads_by_telecaller': MasterKpiDefinition(
      id: 23,
      key: 'manual_leads_by_telecaller',
      name: 'Direct Leads by Telecaller',
      screenLocation: 'Reports Page (Manual Leads Tab)',
      repeatingScreens: ['None (Exclusive to Reports)'],
      drilldownAction: 'Leads Drilldown Dialog (initialSource = DIRECT)',
      databaseMapping: "leads.created_by = users.id WHERE roles.name IN ('Telecaller','Tele Caller') AND leads.source is direct/manual",
      businessPurpose: 'Tracks offline caller inquiries logged manually by the telecalling desk.',
    ),
    'manual_leads_by_admin': MasterKpiDefinition(
      id: 24,
      key: 'manual_leads_by_admin',
      name: 'Direct Leads by Admin',
      screenLocation: 'Reports Page (Manual Leads Tab)',
      repeatingScreens: ['None (Exclusive to Reports)'],
      drilldownAction: 'Leads Drilldown Dialog',
      databaseMapping: "leads.created_by = users.id WHERE roles.name = 'Admin' AND leads.source is direct/manual",
      businessPurpose: 'Tracks inquiries injected directly by management or VIP business channels.',
    ),

    // ── Reports Page Sales Pipeline Section (KPI 25) ──
    'active_in_pipeline': MasterKpiDefinition(
      id: 25,
      key: 'active_requirements',
      name: 'Active In Pipeline',
      screenLocation: 'Reports Page (Sales Pipeline Section)',
      repeatingScreens: ['Sales Dashboard'],
      drilldownAction: 'Assigned to Sales Dialog',
      databaseMapping: 'requirements.deleted_at IS NULL',
      businessPurpose: 'Measures client requirements actively being serviced and matched with properties.',
    ),

    // ── Reports Page Qualified Leads & Intent (KPIs 26–30) ──
    'qualified_interested': MasterKpiDefinition(
      id: 26,
      key: 'qualified_interested',
      name: 'Qualified Interested Leads',
      screenLocation: 'Reports Page (Qualified Tab)',
      repeatingScreens: ['None (Exclusive to Reports)'],
      drilldownAction: 'Leads Drilldown Dialog',
      databaseMapping: "leads.call_disposition NOT IN ('CNR','NOT_INTERESTED','NOT_ATTEMPTED') AND leads.stage != 'LOST'",
      businessPurpose: 'Removes junk, unreached, and disinterested contacts to reveal genuine client pipeline.',
    ),
    'tenants_want_rent': MasterKpiDefinition(
      id: 27,
      key: 'want_rent_count',
      name: 'Tenants (Want Rent)',
      screenLocation: 'Reports Page (Qualified Tab)',
      repeatingScreens: ['Requirements Page (Rent filter)'],
      drilldownAction: 'Leads Drilldown Dialog (businessType = Rent, leadType = Requirement)',
      databaseMapping: "leads.lead_type = 'Requirement' AND NOT (leads.notes ILIKE '%buy%' OR leads.notes ILIKE '%sale%')",
      businessPurpose: 'Isolates genuine tenant demand seeking residential or commercial rentals.',
    ),
    'owners_want_list': MasterKpiDefinition(
      id: 28,
      key: 'want_list_count',
      name: 'Owners (Want to List)',
      screenLocation: 'Reports Page (Qualified Tab)',
      repeatingScreens: ['Leads Page (Listing filter)'],
      drilldownAction: 'Leads Drilldown Dialog (leadType = Listing)',
      databaseMapping: "leads.lead_type = 'Property Listing'",
      businessPurpose: 'Isolates supply-side inquiries from property landlords wishing to list units.',
    ),
    'buyers_want_resale': MasterKpiDefinition(
      id: 29,
      key: 'want_resale_count',
      name: 'Buyers (Re-sale)',
      screenLocation: 'Reports Page (Qualified Tab)',
      repeatingScreens: ['Requirements Page (Sale filter)'],
      drilldownAction: 'Leads Drilldown Dialog (businessType = Re-sale, leadType = Requirement)',
      databaseMapping: "leads.lead_type = 'Requirement' AND (leads.notes ILIKE '%buy%' OR leads.notes ILIKE '%sale%' OR leads.notes ILIKE '%resale%')",
      businessPurpose: 'Isolates high-ticket investor and buyer demand seeking property acquisitions.',
    ),
    'active_in_sales': MasterKpiDefinition(
      id: 30,
      key: 'active_in_sales_count',
      name: 'Active in Sales Handover',
      screenLocation: 'Reports Page (Qualified Tab)',
      repeatingScreens: ['Admin Dashboard (Assigned to Sales)'],
      drilldownAction: 'Assigned to Sales Dialog',
      databaseMapping: "leads.stage = 'SALES' OR leads.allocation_status = 'HANDED_TO_SALES' OR leads.assigned_to IS NOT NULL",
      businessPurpose: 'Verifies that qualified warm prospects are actively in conversation with sales reps.',
    ),
  };
}
