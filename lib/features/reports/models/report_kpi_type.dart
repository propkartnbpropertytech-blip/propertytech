import 'package:flutter/material.dart';

enum ReportKpiType {
  totalLeads,
  telecallers,
  salesUsers,
  leadsContacted,
  leadsAssignedToSales,
  leadQualificationRate,
  siteVisitsScheduled,
  siteVisitsDone,
  convertedToWon,
  callAttempted,
  callPickedUp,
  callOpen,
  lostUnsuccessful;

  String get displayName {
    switch (this) {
      case ReportKpiType.totalLeads:
        return 'Total Leads';
      case ReportKpiType.telecallers:
        return 'Telecallers';
      case ReportKpiType.salesUsers:
        return 'Sales Users';
      case ReportKpiType.leadsContacted:
        return 'Leads Contacted';
      case ReportKpiType.leadsAssignedToSales:
        return 'Leads Assigned to Sales';
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
      case ReportKpiType.telecallers:
        return Icons.headset_mic_rounded;
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
      case ReportKpiType.telecallers:
        return const Color(0xFF64748B);
      case ReportKpiType.salesUsers:
        return const Color(0xFF475569);
      case ReportKpiType.leadsContacted:
        return const Color(0xFF0284C7);
      case ReportKpiType.leadsAssignedToSales:
        return const Color(0xFF2563EB);
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
      case ReportKpiType.telecallers:
        return '% of total team';
      case ReportKpiType.salesUsers:
        return '% of total team';
      case ReportKpiType.leadsContacted:
        return '% of Total Leads';
      case ReportKpiType.leadsAssignedToSales:
        return '% of Total Leads';
      case ReportKpiType.leadQualificationRate:
        return '% of Contacted Leads';
      case ReportKpiType.siteVisitsScheduled:
        return '% of Qualified Leads';
      case ReportKpiType.siteVisitsDone:
        return '% of Scheduled Visits';
      case ReportKpiType.convertedToWon:
        return '% of Assigned / Pipeline Leads';
      case ReportKpiType.callAttempted:
        return '% of Total Leads';
      case ReportKpiType.callPickedUp:
        return '% of Call Attempted';
      case ReportKpiType.callOpen:
        return '% of Call Attempted';
      case ReportKpiType.lostUnsuccessful:
        return '% of Total Leads';
    }
  }
}
