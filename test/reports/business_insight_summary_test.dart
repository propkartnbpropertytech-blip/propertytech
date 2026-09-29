import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/reports/models/business_insight_summary.dart';

void main() {
  test('BusinessInsightSummary empty constructor has 0s', () {
    const empty = BusinessInsightSummary.empty();
    expect(empty.totalLeads, 0);
    expect(empty.propertyListingLeads.total, 0);
    expect(empty.requirementLeads.total, 0);
    expect(empty.newOpenLeads.total, 0);
    expect(empty.cnrLeads.total, 0);
    expect(empty.callbackLeads.total, 0);
    expect(empty.followupLeads.total, 0);
    expect(empty.notInterestedLeads.total, 0);
    expect(empty.assignedToSalesPickedUp.total, 0);
  });

  test('BusinessInsightSummary parses backend weekly filtered JSON correctly', () {
    final json = {
      "total_leads": 9,
      "sources": {
        "meta": {
          "total": 5,
          "property_listing": 3,
          "requirement": 2,
          "not_interested": 0,
          "rejected": 0
        },
        "housing": {
          "total": 2,
          "property_listing": 0,
          "requirement": 2,
          "not_interested": 0,
          "rejected": 0
        },
        "webhook": {
          "total": 2,
          "property_listing": 2,
          "requirement": 0,
          "not_interested": 0,
          "rejected": 0
        },
        "manual": {
          "total": 0,
          "property_listing": 0,
          "requirement": 0,
          "not_interested": 0,
          "rejected": 0
        }
      },
      "property_listing_leads": {
        "total": 5,
        "by_source": {
          "meta": 3,
          "housing": 0,
          "webhook": 2
        },
        "kpis": {
          "total_listing_leads": 5,
          "call_outcomes": 0,
          "follow_ups": 0,
          "cnr": 0,
          "callback": 0,
          "not_interested": 0,
          "archived_property": 0,
          "wrong_lead": 0
        },
        "kpis_by_source": {
          "all": {
            "total_listing_leads": 5,
            "call_outcomes": 0,
            "follow_ups": 0,
            "cnr": 0,
            "callback": 0,
            "not_interested": 0,
            "archived_property": 0,
            "wrong_lead": 0
          },
          "meta": {
            "total_listing_leads": 3,
            "call_outcomes": 0,
            "follow_ups": 0,
            "cnr": 0,
            "callback": 0,
            "not_interested": 0,
            "archived_property": 0,
            "wrong_lead": 0
          },
          "housing": {
            "total_listing_leads": 0,
            "call_outcomes": 0,
            "follow_ups": 0,
            "cnr": 0,
            "callback": 0,
            "not_interested": 0,
            "archived_property": 0,
            "wrong_lead": 0
          },
          "webhook": {
            "total_listing_leads": 2,
            "call_outcomes": 0,
            "follow_ups": 0,
            "cnr": 0,
            "callback": 0,
            "not_interested": 0,
            "archived_property": 0,
            "wrong_lead": 0
          }
        }
      },
      "requirement_leads": {
        "total": 4,
        "by_source": {
          "meta": 2,
          "housing": 2,
          "webhook": 0
        },
        "kpis": {
          "total_requirement_leads": 4,
          "follow_ups": 0,
          "wrong_lead": 0,
          "not_interested": 0,
          "archived": 0,
          "transfer_picked_up": 0,
          "callback": 0,
          "cnr": 0
        },
        "kpis_by_source": {
          "all": {
            "total_requirement_leads": 4,
            "follow_ups": 0,
            "wrong_lead": 0,
            "not_interested": 0,
            "archived": 0,
            "transfer_picked_up": 0,
            "callback": 0,
            "cnr": 0
          },
          "meta": {
            "total_requirement_leads": 2,
            "follow_ups": 0,
            "wrong_lead": 0,
            "not_interested": 0,
            "archived": 0,
            "transfer_picked_up": 0,
            "callback": 0,
            "cnr": 0
          },
          "housing": {
            "total_requirement_leads": 2,
            "follow_ups": 0,
            "wrong_lead": 0,
            "not_interested": 0,
            "archived": 0,
            "transfer_picked_up": 0,
            "callback": 0,
            "cnr": 0
          },
          "webhook": {
            "total_requirement_leads": 0,
            "follow_ups": 0,
            "wrong_lead": 0,
            "not_interested": 0,
            "archived": 0,
            "transfer_picked_up": 0,
            "callback": 0,
            "cnr": 0
          }
        }
      },
      "new_open_leads": {
        "total": 9,
        "by_source": {
          "meta": {"total": 5, "property_listing": 3, "requirement": 2},
          "housing": {"total": 2, "property_listing": 0, "requirement": 2},
          "webhook": {"total": 2, "property_listing": 2, "requirement": 0},
          "manual": {"total": 0}
        }
      },
      "cnr_leads": {
        "total": 0,
        "by_source": {
          "meta": {"total": 0, "property_listing": 0, "requirement": 0},
          "housing": {"total": 0, "property_listing": 0, "requirement": 0},
          "webhook": {"total": 0, "property_listing": 0, "requirement": 0}
        }
      },
      "callback_leads": {
        "total": 0,
        "by_source": {
          "meta": {"total": 0, "property_listing": 0, "requirement": 0},
          "housing": {"total": 0, "property_listing": 0, "requirement": 0},
          "webhook": {"total": 0, "property_listing": 0, "requirement": 0}
        }
      },
      "followup_leads": {
        "total": 1,
        "by_source": {"meta": 1, "housing": 0, "webhook": 0}
      },
      "not_interested_leads": {
        "total": 0,
        "by_source": {"meta": 0, "housing": 0, "webhook": 0}
      },
      "assigned_to_sales_picked_up": {
        "total": 0,
        "by_telecaller": []
      },
      "telecallers": {
        "total_count": 2,
        "list": []
      },
      "leads_page_kpis": {
        "not_started": 0,
        "call_attempted": 2,
        "call_attempted_picked_up": 0,
        "call_attempted_open": 2,
        "follow_ups": 0,
        "re_follow_ups": 0,
        "interested": 0,
        "site_visit_scheduled": 0,
        "site_visit_done": 0,
        "negotiation": 0,
        "rejected_leads": 0
      }
    };

    final summary = BusinessInsightSummary.fromJson(json);
    expect(summary.totalLeads, 9);
    expect(summary.propertyListingLeads.total, 5);
    expect(summary.requirementLeads.total, 4);
    expect(summary.newOpenLeads.total, 9);
    expect(summary.followupLeads.total, 1);
    expect(summary.cnrLeads.total, 0);
    expect(summary.notInterestedLeads.total, 0);
    expect(summary.assignedToSalesPickedUp.total, 0);

    // Source-filtered KPI retrieval
    final housingListingKpis = summary.propertyListingLeads.getKpisForSource('Housing');
    expect(housingListingKpis.totalListingLeads, 0);

    final metaListingKpis = summary.propertyListingLeads.getKpisForSource('Meta');
    expect(metaListingKpis.totalListingLeads, 3);

    final webhookListingKpis = summary.propertyListingLeads.getKpisForSource('Webhook');
    expect(webhookListingKpis.totalListingLeads, 2);

    final housingReqKpis = summary.requirementLeads.getKpisForSource('Housing');
    expect(housingReqKpis.totalRequirementLeads, 2);
  });
}
