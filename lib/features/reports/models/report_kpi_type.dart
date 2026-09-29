import 'package:flutter/material.dart';

enum ReportKpiType {
  // Campaign KPIs (Section 1)
  totalLeads,
  propertyListingLeads,
  requirementLeads,
  telecallers,
  newOpenLeads,
  cnrLeads,
  callbackLeads,
  campaignFollowupLeads,
  notInterestedLeads,
  leadsAssignedToSalesPickedUp,

  // Leads Page KPIs (Section 2)
  leadsNotStarted,
  leadsCallAttempted,
  leadsFollowups,
  leadsReFollowups,
  leadsInterested,
  leadsSiteVisitScheduled,
  leadsSiteVisitDone,
  leadsNegotiation,
  leadsRejected,

  // Compatibility / other KPIs
  salesUsers,
  leadsAssignedToSales,
  siteVisitsDone,
  convertedToWon,
  leadsContacted,
  leadQualificationRate,
  siteVisitsScheduled,
  callAttempted,
  callPickedUp,
  callOpen,
  lostUnsuccessful;

  String get displayName {
    switch (this) {
      case ReportKpiType.totalLeads:
        return 'Total Leads';
      case ReportKpiType.propertyListingLeads:
        return 'Property Listing Leads';
      case ReportKpiType.requirementLeads:
        return 'Requirement Leads';
      case ReportKpiType.telecallers:
        return 'Telecallers';
      case ReportKpiType.newOpenLeads:
        return 'New / Open Leads';
      case ReportKpiType.cnrLeads:
        return 'CNR';
      case ReportKpiType.callbackLeads:
        return 'Callback';
      case ReportKpiType.campaignFollowupLeads:
        return 'Follow-Ups';
      case ReportKpiType.notInterestedLeads:
        return 'Not Interested';
      case ReportKpiType.leadsAssignedToSalesPickedUp:
        return 'Leads Assigned to Sales (Picked Up)';

      // Leads Page KPIs
      case ReportKpiType.leadsNotStarted:
        return 'Not Started';
      case ReportKpiType.leadsCallAttempted:
        return 'Call Attempted';
      case ReportKpiType.leadsFollowups:
        return 'Follow-Ups';
      case ReportKpiType.leadsReFollowups:
        return 'Re-Follow-Ups';
      case ReportKpiType.leadsInterested:
        return 'Interested';
      case ReportKpiType.leadsSiteVisitScheduled:
        return 'Site Visit Scheduled';
      case ReportKpiType.leadsSiteVisitDone:
        return 'Site Visit Done';
      case ReportKpiType.leadsNegotiation:
        return 'Negotiation';
      case ReportKpiType.leadsRejected:
        return 'Rejected Leads';

      // Other / Compat
      case ReportKpiType.salesUsers:
        return 'Sales Users';
      case ReportKpiType.leadsContacted:
        return 'Leads Contacted';
      case ReportKpiType.leadsAssignedToSales:
        return 'Leads Assigned to Sales (Picked Up)';
      case ReportKpiType.leadQualificationRate:
        return 'Lead Qualification Rate';
      case ReportKpiType.siteVisitsScheduled:
        return 'Site Visits Scheduled';
      case ReportKpiType.siteVisitsDone:
        return 'Site Visits Done';
      case ReportKpiType.convertedToWon:
        return 'Converted to Won';
      case ReportKpiType.callAttempted:
        return 'Call Attempted';
      case ReportKpiType.callPickedUp:
        return 'Call Picked Up';
      case ReportKpiType.callOpen:
        return 'Call Open';
      case ReportKpiType.lostUnsuccessful:
        return 'Lost / Unsuccessful Leads';
    }
  }

  IconData get icon {
    switch (this) {
      case ReportKpiType.totalLeads:
        return Icons.leaderboard_rounded;
      case ReportKpiType.propertyListingLeads:
        return Icons.apartment_rounded;
      case ReportKpiType.requirementLeads:
        return Icons.manage_search_rounded;
      case ReportKpiType.telecallers:
        return Icons.headset_mic_rounded;
      case ReportKpiType.newOpenLeads:
        return Icons.mark_email_unread_rounded;
      case ReportKpiType.cnrLeads:
        return Icons.phone_missed_rounded;
      case ReportKpiType.callbackLeads:
        return Icons.phone_callback_rounded;
      case ReportKpiType.campaignFollowupLeads:
        return Icons.event_repeat_rounded;
      case ReportKpiType.notInterestedLeads:
        return Icons.thumb_down_alt_rounded;
      case ReportKpiType.leadsAssignedToSalesPickedUp:
        return Icons.assignment_ind_rounded;

      // Leads Page KPIs
      case ReportKpiType.leadsNotStarted:
        return Icons.hourglass_empty_rounded;
      case ReportKpiType.leadsCallAttempted:
        return Icons.phone_in_talk_rounded;
      case ReportKpiType.leadsFollowups:
        return Icons.schedule_rounded;
      case ReportKpiType.leadsReFollowups:
        return Icons.update_rounded;
      case ReportKpiType.leadsInterested:
        return Icons.favorite_rounded;
      case ReportKpiType.leadsSiteVisitScheduled:
        return Icons.location_on_rounded;
      case ReportKpiType.leadsSiteVisitDone:
        return Icons.task_alt_rounded;
      case ReportKpiType.leadsNegotiation:
        return Icons.handshake_rounded;
      case ReportKpiType.leadsRejected:
        return Icons.cancel_rounded;

      // Compat
      case ReportKpiType.salesUsers:
        return Icons.badge_rounded;
      case ReportKpiType.leadsContacted:
        return Icons.contact_phone_rounded;
      case ReportKpiType.leadsAssignedToSales:
        return Icons.assignment_ind_rounded;
      case ReportKpiType.leadQualificationRate:
        return Icons.verified_user_rounded;
      case ReportKpiType.siteVisitsScheduled:
        return Icons.calendar_month_rounded;
      case ReportKpiType.siteVisitsDone:
        return Icons.event_available_rounded;
      case ReportKpiType.convertedToWon:
        return Icons.emoji_events_rounded;
      case ReportKpiType.callAttempted:
        return Icons.phone_forwarded_rounded;
      case ReportKpiType.callPickedUp:
        return Icons.phone_in_talk_rounded;
      case ReportKpiType.callOpen:
        return Icons.phone_missed_rounded;
      case ReportKpiType.lostUnsuccessful:
        return Icons.cancel_outlined;
    }
  }

  Color get defaultColor {
    switch (this) {
      case ReportKpiType.totalLeads:
        return const Color(0xFF14213D);
      case ReportKpiType.propertyListingLeads:
        return const Color(0xFF0284C7);
      case ReportKpiType.requirementLeads:
        return const Color(0xFF0D9488);
      case ReportKpiType.telecallers:
        return const Color(0xFF64748B);
      case ReportKpiType.newOpenLeads:
        return const Color(0xFF2563EB);
      case ReportKpiType.cnrLeads:
        return const Color(0xFFEA580C);
      case ReportKpiType.callbackLeads:
        return const Color(0xFFD97706);
      case ReportKpiType.campaignFollowupLeads:
        return const Color(0xFF0284C7);
      case ReportKpiType.notInterestedLeads:
        return const Color(0xFFDC2626);
      case ReportKpiType.leadsAssignedToSalesPickedUp:
        return const Color(0xFF7C3AED);

      // Leads Page KPIs
      case ReportKpiType.leadsNotStarted:
        return const Color(0xFF64748B);
      case ReportKpiType.leadsCallAttempted:
        return const Color(0xFF0284C7);
      case ReportKpiType.leadsFollowups:
        return const Color(0xFF0D9488);
      case ReportKpiType.leadsReFollowups:
        return const Color(0xFF2563EB);
      case ReportKpiType.leadsInterested:
        return const Color(0xFF16A34A);
      case ReportKpiType.leadsSiteVisitScheduled:
        return const Color(0xFF9333EA);
      case ReportKpiType.leadsSiteVisitDone:
        return const Color(0xFF7C3AED);
      case ReportKpiType.leadsNegotiation:
        return const Color(0xFFF59E0B);
      case ReportKpiType.leadsRejected:
        return const Color(0xFFDC2626);

      case ReportKpiType.salesUsers:
        return const Color(0xFF475569);
      case ReportKpiType.leadsContacted:
        return const Color(0xFF0284C7);
      case ReportKpiType.leadsAssignedToSales:
        return const Color(0xFF7C3AED);
      case ReportKpiType.leadQualificationRate:
        return const Color(0xFF0D9488);
      case ReportKpiType.siteVisitsScheduled:
        return const Color(0xFF7C3AED);
      case ReportKpiType.siteVisitsDone:
        return const Color(0xFF9333EA);
      case ReportKpiType.convertedToWon:
        return const Color(0xFF16A34A);
      case ReportKpiType.callAttempted:
        return const Color(0xFFD97706);
      case ReportKpiType.callPickedUp:
        return const Color(0xFF059669);
      case ReportKpiType.callOpen:
        return const Color(0xFFE11D48);
      case ReportKpiType.lostUnsuccessful:
        return const Color(0xFFDC2626);
    }
  }

  String get denominatorExplanation {
    switch (this) {
      case ReportKpiType.totalLeads:
        return '% of total records';
      case ReportKpiType.propertyListingLeads:
      case ReportKpiType.requirementLeads:
      case ReportKpiType.newOpenLeads:
      case ReportKpiType.cnrLeads:
      case ReportKpiType.callbackLeads:
      case ReportKpiType.campaignFollowupLeads:
      case ReportKpiType.notInterestedLeads:
      case ReportKpiType.leadsAssignedToSalesPickedUp:
        return '% of Total Leads';

      case ReportKpiType.leadsNotStarted:
      case ReportKpiType.leadsCallAttempted:
      case ReportKpiType.leadsFollowups:
      case ReportKpiType.leadsReFollowups:
      case ReportKpiType.leadsInterested:
      case ReportKpiType.leadsSiteVisitScheduled:
      case ReportKpiType.leadsSiteVisitDone:
      case ReportKpiType.leadsNegotiation:
      case ReportKpiType.leadsRejected:
        return '% of Leads Page records';

      case ReportKpiType.telecallers:
      case ReportKpiType.salesUsers:
        return '% of total team';
      default:
        return '% of total';
    }
  }
}
