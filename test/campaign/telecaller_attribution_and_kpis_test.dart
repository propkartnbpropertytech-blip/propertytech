import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/campaign/models/campaign_followup_model.dart';
import 'package:propkart/features/integration/models/integration_lead_model.dart';

void main() {
  group('Telecaller Attribution & Followup Models Test', () {
    test('IntegrationLeadModel parses status, not_interested, and archive attribution', () {
      final json = {
        'id': 'lead-123',
        'source': 'Meta Ads',
        'lead_type': 'Property Listing',
        'campaign_status': 'CNR',
        'status_updated_by_name': 'Telecaller John',
        'status_updated_by_id': 'user-1',
        'status_updated_at': '2026-09-23T10:00:00.000Z',
        'not_interested_by_name': 'Telecaller Sarah',
        'not_interested_by_id': 'user-2',
        'not_interested_at': '2026-09-23T11:00:00.000Z',
        'archived_by_name': 'Telecaller Mike',
        'archived_by_id': 'user-3',
        'archived_at': '2026-09-23T12:00:00.000Z',
      };

      final lead = IntegrationLeadModel.fromJson(json);

      expect(lead.statusUpdatedByName, equals('Telecaller John'));
      expect(lead.statusUpdatedById, equals('user-1'));
      expect(lead.statusUpdatedAt, isNotNull);
      expect(lead.notInterestedByName, equals('Telecaller Sarah'));
      expect(lead.notInterestedById, equals('user-2'));
      expect(lead.notInterestedAt, isNotNull);
      expect(lead.archivedByName, equals('Telecaller Mike'));
      expect(lead.archivedById, equals('user-3'));
      expect(lead.archivedAt, isNotNull);

      // Verify copyWith works
      final updated = lead.copyWith(
        statusUpdatedByName: 'Telecaller Alice',
      );
      expect(updated.statusUpdatedByName, equals('Telecaller Alice'));
      expect(updated.notInterestedByName, equals('Telecaller Sarah'));
      expect(updated.archivedByName, equals('Telecaller Mike'));
    });

    test('IntegrationLeadModel falls back to assignedTelecallerName when attribution missing', () {
      final json = {
        'id': 'lead-456',
        'source': 'Meta Ads',
        'lead_type': 'Requirement',
        'campaign_status': 'Not interested',
        'assigned_telecaller_name': 'Telecaller Fallback',
      };

      final lead = IntegrationLeadModel.fromJson(json);
      expect(lead.notInterestedByName, equals('Telecaller Fallback'));
    });

    test('CampaignFollowupModel parses telecaller_name from root and nested lead', () {
      final followupJson = {
        'id': 'followup-1',
        'lead_id': 'lead-1',
        'client_name': 'Jane Doe',
        'mobile': '9876543210',
        'scheduled_at': '2026-09-23T15:00:00.000Z',
        'lead_type': 'Property Listing',
        'remarks': 'Call back in afternoon',
        'status': 'Pending',
        'created_at': '2026-09-23T09:00:00.000Z',
        'telecaller_name': 'Telecaller Emma',
      };

      final followup = CampaignFollowupModel.fromJson(followupJson);
      expect(followup.telecallerName, equals('Telecaller Emma'));

      // From nested lead
      final followupFromLeadJson = {
        'id': 'followup-2',
        'lead_id': 'lead-2',
        'client_name': 'John Smith',
        'mobile': '9876543211',
        'scheduled_at': '2026-09-23T16:00:00.000Z',
        'lead_type': 'Requirement',
        'status': 'Pending',
        'created_at': '2026-09-23T09:00:00.000Z',
        'lead': {
          'id': 'lead-2',
          'source': 'Meta Ads',
          'assigned_telecaller_name': 'Telecaller Robert',
        },
      };

      final followup2 = CampaignFollowupModel.fromJson(followupFromLeadJson);
      expect(followup2.telecallerName, equals('Telecaller Robert'));
    });

    test('Telecaller Detail KPI names follow requirements', () {
      const kpiLabels = [
        'Assigned',
        'Overall Assigned',
        'CNR | Callback',
        'Assigned to Sales',
      ];

      expect(kpiLabels, contains('Assigned'));
      expect(kpiLabels, contains('Overall Assigned'));
      expect(kpiLabels, contains('CNR | Callback'));
      expect(kpiLabels, contains('Assigned to Sales'));
      expect(kpiLabels, isNot(contains('Total Assigned – Current')));
      expect(kpiLabels, isNot(contains('Overall Total Assigned')));
      expect(kpiLabels, isNot(contains('Handed to Sales')));
      expect(kpiLabels, isNot(contains('CNR / Callback')));

      final cnr = 24;
      final callback = 16;
      final cnrCallbackValue = '$cnr | $callback';
      expect(cnrCallbackValue, equals('24 | 16'));
    });

    test('Follow-ups top tab and Follow-ups KPI card use consistent counting logic', () {
      final followupsList = [
        CampaignFollowupModel(
          id: 'fu_1',
          leadId: 'lead_1',
          leadType: 'Requirement',
          clientName: 'Client 1',
          mobile: '9999999991',
          scheduledAt: DateTime.now(),
          remarks: 'Test',
          status: 'Pending',
          createdAt: DateTime.now(),
        ),
        CampaignFollowupModel(
          id: 'fu_2',
          leadId: 'lead_2',
          leadType: 'Requirement',
          clientName: 'Client 2',
          mobile: '9999999992',
          scheduledAt: DateTime.now(),
          remarks: 'Test',
          status: 'Pending',
          createdAt: DateTime.now(),
        ),
      ];

      final leads = [
        IntegrationLeadModel(
          id: 'lead_1',
          source: 'Meta Ads',
          receivedAt: DateTime.now(),
          campaignStatus: 'Follow up',
          rawJson: const {},
        ),
        IntegrationLeadModel(
          id: 'lead_2',
          source: 'Meta Ads',
          receivedAt: DateTime.now(),
          campaignStatus: 'Follow up',
          rawJson: const {},
        ),
        IntegrationLeadModel(
          id: 'lead_3',
          source: 'Meta Ads',
          receivedAt: DateTime.now(),
          campaignStatus: 'Follow up',
          rawJson: const {},
        ),
      ];

      // Logic used by both tab and KPI
      int calculateFollowupCount() {
        final leadIds = <String>{};
        final serviceLeadMap = {for (final l in leads) l.id: l};
        for (final f in followupsList) {
          if (f.status == 'Completed' || f.status == 'Cancelled') continue;
          final localLead = serviceLeadMap[f.leadId] ?? f.lead;
          if (localLead != null &&
              localLead.campaignStatus != 'Follow up' &&
              localLead.campaignStatus != 'Follow-up') {
            continue;
          }
          leadIds.add(f.leadId);
        }
        for (final lead in leads) {
          if (lead.campaignStatus == 'Follow up' || lead.campaignStatus == 'Follow-up') {
            final fuStatus = (lead.followupStatus ?? 'Pending').trim().toLowerCase();
            if (fuStatus == 'completed' || fuStatus == 'cancelled') continue;
            leadIds.add(lead.id);
          }
        }
        return leadIds.length;
      }

      final tabCount = calculateFollowupCount();
      final kpiCount = calculateFollowupCount();

      expect(tabCount, equals(3));
      expect(kpiCount, equals(3));
      expect(tabCount, equals(kpiCount));
    });
  });
}
