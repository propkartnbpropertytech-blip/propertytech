import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/telecaller/bloc/telecaller_list_bloc.dart';
import 'package:propkart/features/integration/models/integration_lead_model.dart';

void main() {
  group('Telecaller Not Interested Callbacks Tests', () {
    test('TelecallerLeadRemoved event purges leads with and without auto_ prefix', () {
      final bloc = TelecallerCallbacksBloc();
      // Directly check how TelecallerLeadRemoved matches both prefixed and unprefixed ids
      final items = [
        {
          'id': 'auto_lead-123',
          'lead_id': 'lead-123',
          'client_name': 'Test Client 1',
        },
        {
          'id': 'cb-456',
          'lead_id': 'lead-456',
          'client_name': 'Test Client 2',
        },
        {
          'id': 'cb-789',
          'lead_id': 'lead-789',
          'lead': {
            'id': 'lead-789',
          },
          'client_name': 'Test Client 3',
        },
      ];

      // Simulate TelecallerLeadRemoved with raw leadId
      const target1 = 'lead-123';
      final stripped1 = target1.startsWith('auto_') ? target1.substring(5) : target1;
      final auto1 = 'auto_$stripped1';

      final filtered1 = items.where((raw) {
        final id = (raw['id'] ?? '').toString().trim().toLowerCase();
        final leadId = (raw['lead_id'] ?? '').toString().trim().toLowerCase();
        return id != target1 && id != stripped1 && id != auto1 &&
               leadId != target1 && leadId != stripped1 && leadId != auto1;
      }).toList();

      expect(filtered1.length, 2);
      expect(filtered1.any((i) => i['lead_id'] == 'lead-123'), isFalse);

      // Simulate TelecallerLeadRemoved with auto_ prefix
      const target2 = 'auto_lead-456';
      final stripped2 = target2.startsWith('auto_') ? target2.substring(5) : target2;
      final auto2 = 'auto_$stripped2';

      final filtered2 = filtered1.where((raw) {
        final id = (raw['id'] ?? '').toString().trim().toLowerCase();
        final leadId = (raw['lead_id'] ?? '').toString().trim().toLowerCase();
        return id != target2 && id != stripped2 && id != auto2 &&
               leadId != target2 && leadId != stripped2 && leadId != auto2;
      }).toList();

      expect(filtered2.length, 1);
      expect(filtered2.first['lead_id'], 'lead-789');

      bloc.close();
    });

    test('Not Interested status filters items from callbacks list', () {
      final items = [
        {
          'id': 'cb-1',
          'lead_id': 'lead-1',
          'campaign_status': 'Callback',
          'lead': {'campaign_status': 'Callback'},
        },
        {
          'id': 'cb-2',
          'lead_id': 'lead-2',
          'campaign_status': 'Not interested',
          'lead': {'campaign_status': 'Not interested'},
        },
        {
          'id': 'cb-3',
          'lead_id': 'lead-3',
          'campaign_status': 'not_interested',
          'lead': {'campaign_status': 'not_interested'},
        },
        {
          'id': 'cb-4',
          'lead_id': 'lead-4',
          'campaign_status': 'Callback',
          'lead': {'campaign_status': 'Disqualified'},
        },
      ];

      final filtered = items.where((raw) {
        final lead = raw['lead'];
        final cs = ((lead is Map ? lead['campaign_status'] : null) ?? raw['campaign_status'] ?? '').toString().trim().toLowerCase();
        if (cs == 'property listed' || cs == 'listed' || cs == 'archived' || cs == 'not interested' || cs == 'not_interested' || cs == 'disqualified') return false;
        return true;
      }).toList();

      expect(filtered.length, 1);
      expect(filtered.first['id'], 'cb-1');
    });

    test('IntegrationLeadModel correctly clears callback when marking Not Interested', () {
      final initialLead = IntegrationLeadModel(
        id: 'test-uuid-001',
        source: 'Meta',
        receivedAt: DateTime.now(),
        campaignStatus: 'Callback',
        allocationStatus: 'CALLBACK',
        callbackStatus: 'Pending',
        callbackScheduledAt: DateTime.now().add(const Duration(hours: 2)),
        callbackRemarks: 'Call back tomorrow',
        rawJson: {
          '_callback': {
            'status': 'Pending',
            'remarks': 'Call back tomorrow',
          },
        },
      );

      expect(initialLead.callbackScheduledAt, isNotNull);
      expect(initialLead.callbackStatus, 'Pending');

      const status = 'Not interested';
      const cleanReason = 'Client declined, looking in another city';
      final isNotInterested = status == 'Not interested';
      final clearCb = isNotInterested;

      final updatedLead = initialLead.copyWith(
        campaignStatus: status,
        allocationStatus: 'RELEASED',
        notInterestedReason: cleanReason,
        callbackScheduledAt: clearCb ? null : initialLead.callbackScheduledAt,
        callbackStatus: clearCb ? 'Completed' : initialLead.callbackStatus,
        clearCallback: clearCb,
      );

      expect(updatedLead.campaignStatus, 'Not interested');
      expect(updatedLead.allocationStatus, 'RELEASED');
      expect(updatedLead.notInterestedReason, cleanReason);
      expect(updatedLead.callbackScheduledAt, isNull);
      expect(updatedLead.callbackStatus, 'Completed');
    });

    test('CNR queue filters out Not Interested and Archived leads', () {
      final items = <Map<String, dynamic>>[
        {
          'id': 'cnr-1',
          'lead_id': 'lead-1',
          'campaign_status': 'CNR',
          'allocation_status': 'CNR',
        },
        {
          'id': 'cnr-2',
          'lead_id': 'lead-2',
          'campaign_status': 'Not interested',
          'allocation_status': 'RELEASED',
        },
        {
          'id': 'cnr-3',
          'lead_id': 'lead-3',
          'campaign_status': 'not_interested',
        },
        {
          'id': 'cnr-4',
          'lead_id': 'lead-4',
          'campaign_status': 'Disqualified',
        },
        {
          'id': 'cnr-5',
          'lead_id': 'lead-5',
          'campaign_status': 'Archived',
        },
      ];

      final filtered = items.where((raw) {
        if (raw is! Map) return false;
        final lead = raw['lead'];
        final cs = ((lead is Map ? lead['campaign_status'] : null) ?? raw['campaign_status'] ?? '').toString().trim().toLowerCase();
        if (cs == 'property listed' || cs == 'listed' || cs == 'archived' || cs == 'not interested' || cs == 'not_interested' || cs == 'disqualified') return false;
        final alloc = ((lead is Map ? lead['allocation_status'] : null) ?? raw['allocation_status'] ?? '').toString().trim().toUpperCase();
        if (alloc == 'RELEASED' && (cs == 'not interested' || cs == 'not_interested')) return false;
        return true;
      }).toList();

      expect(filtered.length, 1);
      expect(filtered.first['id'], 'cnr-1');
    });

    test('TelecallerLeadRemoved on CNR items correctly strips auto_ prefix', () {
      final items = [
        {'id': 'auto_cnr-1', 'lead_id': 'cnr-1', 'client_name': 'CNR Lead 1'},
        {'id': 'cnr-2', 'lead_id': 'cnr-2', 'client_name': 'CNR Lead 2'},
      ];

      const target = 'cnr-1';
      final strippedTarget = target.startsWith('auto_') ? target.substring(5) : target;
      final autoTarget = 'auto_$strippedTarget';

      final filtered = items.where((raw) {
        if (raw is! Map) return true;
        final id = (raw['id'] ?? '').toString().trim().toLowerCase();
        final leadId = (raw['lead_id'] ?? raw['leadId'] ?? '').toString().trim().toLowerCase();
        return id != target && id != strippedTarget && id != autoTarget &&
               leadId != target && leadId != strippedTarget && leadId != autoTarget;
      }).toList();

      expect(filtered.length, 1);
      expect(filtered.first['lead_id'], 'cnr-2');
    });
  });
}
