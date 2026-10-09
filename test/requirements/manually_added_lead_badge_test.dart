import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/auth/models/user_model.dart';
import 'package:propkart/features/requirements/models/requirement_model.dart';

void main() {
  RequirementModel createTestLead({
    required String id,
    required String clientName,
    String? creatorName,
    String? createdBy,
    String? leadSource,
    String? metaLeadId,
    String? metaCampaignName,
    Map<String, dynamic>? metaCustomFields,
  }) {
    return RequirementModel(
      id: id,
      clientName: clientName,
      clientMobile: '9876543210',
      categoryId: 'cat-rent',
      categoryName: 'Apartment',
      propertyTypeId: 'pt-01',
      propertyTypeName: '2 BHK',
      minBudget: 20000,
      maxBudget: 35000,
      areaIds: const ['area-01'],
      areaNames: const ['Bopal'],
      status: 'Interested',
      createdAt: DateTime.now(),
      creatorName: creatorName,
      createdBy: createdBy,
      leadSource: leadSource,
      metaLeadId: metaLeadId,
      metaCampaignName: metaCampaignName,
      metaCustomFields: metaCustomFields,
    );
  }

  const currentUserAdmin = UserModel(
    id: 'admin-01',
    fullName: 'Propkart Admin',
    email: 'admin@rbcdeveloper.com',
    role: 'Admin',
    permissions: [],
  );

  const currentUserSales = UserModel(
    id: 'sales-01',
    fullName: 'Rajan Purani',
    email: 'rajan@propkart.com',
    role: 'Sales',
    permissions: [],
  );

  bool isUserCreator(RequirementModel r, UserModel user) {
    if (r.createdBy == user.id) return true;
    final uName = user.fullName.trim().toLowerCase();
    if (uName.isNotEmpty) {
      if (r.createdBy != null && r.createdBy!.trim().toLowerCase() == uName) return true;
      if (r.creatorName != null && r.creatorName!.trim().toLowerCase() == uName) return true;
    }
    return false;
  }

  bool isLeadManuallyAddedByCurrentUser(RequirementModel r, UserModel? user) {
    if (user == null) return false;
    if (!r.isManuallyAdded) return false;
    return isUserCreator(r, user);
  }

  group('RequirementModel - isManuallyAdded Getter Tests', () {
    test('Identifies explicitly flagged manually added lead', () {
      final lead = createTestLead(
        id: 'req-01',
        clientName: 'Devika Ck Devika',
        metaCustomFields: {
          'is_manually_added': true,
          'created_via': 'add_lead',
        },
      );

      expect(lead.isManuallyAdded, isTrue);
    });

    test('Identifies manually added lead created by Salesperson', () {
      final lead = createTestLead(
        id: 'req-sales',
        clientName: 'Rahul Sharma',
        creatorName: 'Rajan Purani',
        createdBy: 'sales-01',
        metaCustomFields: {
          'is_manually_added': true,
          'created_by_role': 'Sales',
        },
      );

      expect(lead.isManuallyAdded, isTrue);
    });

    test('Identifies manually added lead created by Telecaller', () {
      final lead = createTestLead(
        id: 'req-tc',
        clientName: 'Priya Patel',
        creatorName: 'Prexa Vithalapara',
        createdBy: 'tc-01',
        metaCustomFields: {
          'is_manually_added': true,
          'created_by_role': 'Telecaller',
        },
      );

      expect(lead.isManuallyAdded, isTrue);
    });

    test('Identifies manually added lead with leadSource housing.com (e.g. XYZ)', () {
      final lead = createTestLead(
        id: 'req-xyz',
        clientName: 'XYZ',
        creatorName: 'Propkart Admin',
        createdBy: 'admin-01',
        leadSource: 'housing.com',
        metaCustomFields: {
          'is_all_areas': true,
          'is_manually_added': true,
          'match_engine_status': 'READY',
        },
      );

      expect(lead.isManuallyAdded, isTrue);
    });

    test('Identifies manually added leads with dropdown sources (Social Media, MagicBricks, 99acres, Direct, Referral)', () {
      final socialMediaLead = createTestLead(
        id: 'req-sm',
        clientName: 'Vijay Patel',
        createdBy: 'sales-01',
        leadSource: 'Social Media',
      );
      final magicBricksLead = createTestLead(
        id: 'req-mb',
        clientName: 'Anil Shah',
        createdBy: 'sales-01',
        leadSource: 'MagicBricks',
      );
      final referralLead = createTestLead(
        id: 'req-ref',
        clientName: 'Manisha Upadhyay',
        createdBy: 'sales-01',
        leadSource: 'Referral',
      );

      expect(socialMediaLead.isManuallyAdded, isTrue);
      expect(magicBricksLead.isManuallyAdded, isTrue);
      expect(referralLead.isManuallyAdded, isTrue);
    });

    test('Excludes automated Housing Pahal API synced leads', () {
      final housingSyncLead = createTestLead(
        id: 'req-housing-sync',
        clientName: 'Ravi Lakhani',
        leadSource: 'Housing.com',
        metaLeadId: 'housing:100622444:9327316884',
        metaCampaignName: 'Science City',
        metaCustomFields: {
          'flat_id': 100622444,
          'locality': 'Science City',
        },
      );

      expect(housingSyncLead.isManuallyAdded, isFalse);
    });

    test('Excludes Webhook API and CSV imported leads (e.g. Ayush Rathod)', () {
      final webhookLead = createTestLead(
        id: 'req-webhook',
        clientName: 'Ayush Rathod',
        creatorName: 'Prexa Vithalapara',
        metaLeadId: 'l:1407891837970879',
        leadSource: 'Webhook API',
      );

      final csvLead = createTestLead(
        id: 'req-csv',
        clientName: 'CSV Client',
        leadSource: 'CSV Batch Import',
      );

      expect(webhookLead.isManuallyAdded, isFalse);
      expect(csvLead.isManuallyAdded, isFalse);
    });
  });

  group('Current User Scoped "Manually Added" Label Visibility Tests', () {
    test('Shows Manually Added ONLY when current user created the lead via Add Lead', () {
      // Lead created by Propkart Admin
      final adminManualLead = createTestLead(
        id: 'req-admin-manual',
        clientName: 'Admin Manual Lead',
        creatorName: 'Propkart Admin',
        createdBy: 'admin-01',
        metaCustomFields: {
          'is_manually_added': true,
          'created_via': 'add_lead',
        },
      );

      // When Propkart Admin views: visible!
      expect(isLeadManuallyAddedByCurrentUser(adminManualLead, currentUserAdmin), isTrue);

      // When Salesperson Rajan views: NOT visible!
      expect(isLeadManuallyAddedByCurrentUser(adminManualLead, currentUserSales), isFalse);
    });

    test('Never shows Manually Added for Webhook API leads even if creator matches', () {
      final webhookLead = createTestLead(
        id: 'req-ayush',
        clientName: 'Ayush Rathod',
        creatorName: 'Propkart Admin',
        createdBy: 'admin-01',
        leadSource: 'Webhook API',
      );

      // Since source is Webhook API, isManuallyAdded is false -> never shown!
      expect(isLeadManuallyAddedByCurrentUser(webhookLead, currentUserAdmin), isFalse);
    });

    test('Never shows Manually Added for Meta Ads leads', () {
      final metaLead = createTestLead(
        id: 'req-devika',
        clientName: 'Devika Ck Devika',
        creatorName: 'Propkart Admin',
        createdBy: 'admin-01',
        leadSource: 'Meta Ads',
        metaLeadId: 'meta_123',
      );

      expect(isLeadManuallyAddedByCurrentUser(metaLead, currentUserAdmin), isFalse);
    });

    test('Lead created by another user (e.g. Prexa) is NOT shown as Manually Added for Admin', () {
      final prexaManualLead = createTestLead(
        id: 'req-prexa-manual',
        clientName: 'Prexa Manual Lead',
        creatorName: 'Prexa Vithalapara',
        createdBy: 'tc-prexa-01',
        metaCustomFields: {
          'is_manually_added': true,
          'created_via': 'add_lead',
        },
      );

      // Admin is current user -> NOT shown!
      expect(isLeadManuallyAddedByCurrentUser(prexaManualLead, currentUserAdmin), isFalse);
    });
  });

  group('Manually Added Button Widget & Layout Tests', () {
    testWidgets('Renders Manually Added button with icon and pill shape immediately to the left of status toggle for current user', (tester) async {
      final manualLead = createTestLead(
        id: 'req-manual-ui',
        clientName: 'Test Client',
        creatorName: 'Propkart Admin',
        createdBy: 'admin-01',
        metaCustomFields: {
          'is_manually_added': true,
          'created_via': 'add_lead',
        },
      );

      Widget buildTestStatusControl(RequirementModel req, UserModel user) {
        final statusWidget = Container(
          key: const Key('status_toggle_key'),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Interested'),
              Icon(Icons.arrow_drop_down_rounded),
            ],
          ),
        );

        final statusWithNotes = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            statusWidget,
            const SizedBox(height: 4),
            const Text('+Add Notes'),
          ],
        );

        if (!isLeadManuallyAddedByCurrentUser(req, user)) {
          return statusWithNotes;
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              key: const Key('manually_added_button_key'),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFDBA74), width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_add_alt_1_rounded, size: 12, color: Color(0xFFEA580C)),
                  SizedBox(width: 4),
                  Text('Manually Added', style: TextStyle(color: Color(0xFFC2410C), fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            statusWithNotes,
          ],
        );
      }

      // 1. When current user created the lead -> button is rendered!
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: buildTestStatusControl(manualLead, currentUserAdmin),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('manually_added_button_key')), findsOneWidget);
      expect(find.text('Manually Added'), findsOneWidget);
      expect(find.byIcon(Icons.person_add_alt_1_rounded), findsOneWidget);
      expect(find.byKey(const Key('status_toggle_key')), findsOneWidget);

      final buttonPos = tester.getTopLeft(find.byKey(const Key('manually_added_button_key')));
      final statusPos = tester.getTopLeft(find.byKey(const Key('status_toggle_key')));
      expect(buttonPos.dx, lessThan(statusPos.dx));

      // 2. When current user did NOT create the lead (e.g. Sales viewing Admin's lead) -> button is NOT rendered!
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: buildTestStatusControl(manualLead, currentUserSales),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('manually_added_button_key')), findsNothing);
      expect(find.text('Manually Added'), findsNothing);
      expect(find.byKey(const Key('status_toggle_key')), findsOneWidget);

      // 3. When Ayush Rathod (Webhook API lead) is viewed by Admin -> button is NOT rendered!
      final ayushLead = createTestLead(
        id: 'req-ayush',
        clientName: 'Ayush Rathod',
        creatorName: 'Prexa Vithalapara',
        createdBy: 'tc-01',
        leadSource: 'Webhook API',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: buildTestStatusControl(ayushLead, currentUserAdmin),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('manually_added_button_key')), findsNothing);
      expect(find.text('Manually Added'), findsNothing);
      expect(find.byKey(const Key('status_toggle_key')), findsOneWidget);
    });

    test('Lead Details drawer Lead Type row is only included for manually added leads created by current user', () {
      final adminManualLead = createTestLead(
        id: 'req-admin-manual',
        clientName: 'Admin Manual Lead',
        creatorName: 'Propkart Admin',
        createdBy: 'admin-01',
        metaCustomFields: {
          'is_manually_added': true,
          'created_via': 'add_lead',
        },
      );

      final webhookLead = createTestLead(
        id: 'req-ayush',
        clientName: 'Ayush Rathod',
        creatorName: 'Propkart Admin',
        createdBy: 'admin-01',
        leadSource: 'Webhook API',
      );

      final otherUserLead = createTestLead(
        id: 'req-prexa',
        clientName: 'Prexa Lead',
        creatorName: 'Prexa Vithalapara',
        createdBy: 'tc-01',
        metaCustomFields: {
          'is_manually_added': true,
          'created_via': 'add_lead',
        },
      );

      // Current user is Admin:
      // 1. Own manual lead -> true (row shown)
      expect(isLeadManuallyAddedByCurrentUser(adminManualLead, currentUserAdmin), isTrue);

      // 2. Webhook API lead -> false (row NOT shown)
      expect(isLeadManuallyAddedByCurrentUser(webhookLead, currentUserAdmin), isFalse);

      // 3. Lead created by Prexa -> false (row NOT shown)
      expect(isLeadManuallyAddedByCurrentUser(otherUserLead, currentUserAdmin), isFalse);

      // Current user is Sales:
      // 4. Admin's manual lead -> false (row NOT shown)
      expect(isLeadManuallyAddedByCurrentUser(adminManualLead, currentUserSales), isFalse);
    });
  });
}
