import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/reports/models/business_insight_summary.dart';
import 'package:propkart/features/reports/models/report_date_range.dart';
import 'package:propkart/features/reports/widgets/business_insight_drilldowns.dart';
import 'package:propkart/features/reports/widgets/report_date_filter_bar.dart';

void main() {
  final sampleJson = <String, dynamic>{
    "total_leads": 1301,
    "sources": <String, dynamic>{
      "meta": <String, dynamic>{
        "total": 700,
        "property_listing": 300,
        "requirement": 400,
        "not_interested": 521,
        "rejected": 0
      },
      "housing": <String, dynamic>{
        "total": 300,
        "property_listing": 100,
        "requirement": 200,
        "not_interested": 73,
        "rejected": 0
      },
      "webhook": <String, dynamic>{
        "total": 200,
        "property_listing": 85,
        "requirement": 115,
        "not_interested": 47,
        "rejected": 0
      },
      "manual": <String, dynamic>{
        "total": 101,
        "property_listing": 0,
        "requirement": 101,
        "not_interested": 36,
        "rejected": 0
      }
    },
    "property_listing_leads": <String, dynamic>{
      "total": 485,
      "by_source": <String, dynamic>{
        "meta": 300,
        "housing": 100,
        "webhook": 85,
        "manual": 0
      },
      "kpis": <String, dynamic>{
        "total_listing_leads": 485,
        "call_outcomes": 19,
        "follow_ups": 67,
        "cnr": 106,
        "callback": 19,
        "not_interested": 235,
        "archived_property": 84,
        "wrong_lead": 0
      },
      "kpis_by_source": <String, dynamic>{
        "all": <String, dynamic>{
          "total_listing_leads": 485,
          "call_outcomes": 19,
          "follow_ups": 67,
          "cnr": 106,
          "callback": 19,
          "not_interested": 235,
          "archived_property": 84,
          "wrong_lead": 0
        }
      }
    },
    "requirement_leads": <String, dynamic>{
      "total": 816,
      "by_source": <String, dynamic>{
        "meta": 400,
        "housing": 200,
        "webhook": 115,
        "manual": 101
      },
      "kpis": <String, dynamic>{
        "total_requirement_leads": 816,
        "follow_ups": 165,
        "wrong_lead": 0,
        "not_interested": 442,
        "archived": 3,
        "transfer_picked_up": 34,
        "callback": 23,
        "cnr": 102
      },
      "kpis_by_source": <String, dynamic>{
        "all": <String, dynamic>{
          "total_requirement_leads": 816,
          "follow_ups": 165,
          "wrong_lead": 0,
          "not_interested": 442,
          "archived": 3,
          "transfer_picked_up": 34,
          "callback": 23,
          "cnr": 102
        }
      }
    },
    "telecallers": <String, dynamic>{
      "total_count": 0,
      "list": <dynamic>[]
    },
    "new_open_leads": <String, dynamic>{
      "total": 0,
      "by_source": <String, dynamic>{
        "meta": <String, dynamic>{"total": 0, "property_listing": 0, "requirement": 0},
        "housing": <String, dynamic>{"total": 0, "property_listing": 0, "requirement": 0},
        "webhook": <String, dynamic>{"total": 0, "property_listing": 0, "requirement": 0},
        "manual": <String, dynamic>{"total": 0}
      }
    },
    "cnr_leads": <String, dynamic>{
      "total": 0,
      "by_source": <String, dynamic>{
        "meta": <String, dynamic>{"total": 0, "property_listing": 0, "requirement": 0},
        "housing": <String, dynamic>{"total": 0, "property_listing": 0, "requirement": 0},
        "webhook": <String, dynamic>{"total": 0, "property_listing": 0, "requirement": 0}
      }
    },
    "callback_leads": <String, dynamic>{
      "total": 0,
      "by_source": <String, dynamic>{
        "meta": <String, dynamic>{"total": 0, "property_listing": 0, "requirement": 0},
        "housing": <String, dynamic>{"total": 0, "property_listing": 0, "requirement": 0},
        "webhook": <String, dynamic>{"total": 0, "property_listing": 0, "requirement": 0}
      }
    },
    "followup_leads": <String, dynamic>{
      "total": 0,
      "by_source": <String, dynamic>{"meta": 0, "housing": 0, "webhook": 0}
    },
    "not_interested_leads": <String, dynamic>{
      "total": 677,
      "by_source": <String, dynamic>{"meta": 521, "housing": 73, "webhook": 47}
    },
    "assigned_to_sales_picked_up": <String, dynamic>{
      "total": 0,
      "by_telecaller": <dynamic>[]
    },
    "leads_page_kpis": <String, dynamic>{
      "not_started": 0,
      "call_attempted": 0,
      "call_attempted_picked_up": 0,
      "call_attempted_open": 0,
      "follow_ups": 0,
      "re_follow_ups": 0,
      "interested": 0,
      "site_visit_scheduled": 0,
      "site_visit_done": 0,
      "negotiation": 0,
      "rejected_leads": 0
    }
  };

  final sampleSummary = BusinessInsightSummary.fromJson(sampleJson);

  testWidgets('PropertyListingLeadsView renders ReportDateFilterBar and displays accurate counts', (tester) async {
    final activeRange = ReportDateRange.currentYear();
    ReportDateRange? selectedRange;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PropertyListingLeadsView(
              summary: sampleSummary,
              from: activeRange.startDate,
              to: activeRange.endDate,
              dateRange: activeRange,
              onDateRangeChanged: (newRange) => selectedRange = newRange,
              onBack: () {},
            ),
          ),
        ),
      ),
    );

    // Verify DateFilterBar is rendered
    expect(find.byType(ReportDateFilterBar), findsOneWidget);
    expect(find.text('Property Listing Leads'), findsOneWidget);
    expect(find.text('Total Listing Leads'), findsOneWidget);
    expect(find.text('Call Outcomes'), findsOneWidget);
    expect(find.text('Follow-Ups'), findsOneWidget);
    expect(find.text('CNR'), findsOneWidget);
    expect(find.text('Callback'), findsOneWidget);
    expect(find.text('Not Interested'), findsOneWidget);
    expect(find.text('Archived Property'), findsOneWidget);
    expect(find.text('Wrong Lead'), findsOneWidget);

    // Verify numbers
    expect(find.text('485'), findsWidgets);
    expect(find.text('235'), findsOneWidget);
    expect(find.text('84'), findsOneWidget);

    // Tap 'Today' in filter bar
    await tester.tap(find.text('Today'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(selectedRange, isNotNull);
    expect(selectedRange!.periodType, ReportPeriodType.today);
  });

  testWidgets('RequirementLeadsView renders ReportDateFilterBar and displays accurate counts', (tester) async {
    final activeRange = ReportDateRange.currentYear();
    ReportDateRange? selectedRange;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RequirementLeadsView(
              summary: sampleSummary,
              from: activeRange.startDate,
              to: activeRange.endDate,
              dateRange: activeRange,
              onDateRangeChanged: (newRange) => selectedRange = newRange,
              onBack: () {},
            ),
          ),
        ),
      ),
    );

    // Verify DateFilterBar is rendered
    expect(find.byType(ReportDateFilterBar), findsOneWidget);
    expect(find.text('Requirement Leads'), findsWidgets);
    expect(find.text('Total Requirement Leads'), findsOneWidget);
    expect(find.text('Wrong Lead'), findsOneWidget);
    expect(find.text('Not Interested'), findsOneWidget);
    expect(find.text('Archived'), findsOneWidget);
    expect(find.text('Transfer / Picked Up'), findsOneWidget);
    expect(find.text('Callback'), findsOneWidget);
    expect(find.text('CNR'), findsOneWidget);

    // Verify numbers
    expect(find.text('816'), findsWidgets);
    expect(find.text('442'), findsOneWidget);
    expect(find.text('165'), findsOneWidget);
    expect(find.text('34'), findsOneWidget);

    // Tap 'Today' in filter bar
    await tester.tap(find.text('Today'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(selectedRange, isNotNull);
    expect(selectedRange!.periodType, ReportPeriodType.today);
  });
}
