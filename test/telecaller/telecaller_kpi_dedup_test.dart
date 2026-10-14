import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/dashboard/models/kpi_models.dart';

void main() {
  group('Telecaller Total Leads Deduplication Tests', () {
    test('Correctly filters out duplicate leads with the same phone and lead type', () {
      final rawLeads = [
        const LeadListItem(
          id: '1',
          customerName: 'Shailesh Yadav',
          phone: '9157782758',
          sanitizedPhone: '9157782758',
          leadType: 'Requirement',
          stage: 'NEW',
          source: 'Meta',
          allocationStatus: 'ASSIGNED_TO_TELECALLER',
          createdAt: '2026-10-13T04:35:47.562Z',
        ),
        const LeadListItem(
          id: '2',
          customerName: 'Sanat Chawda',
          phone: '6351842948',
          sanitizedPhone: '6351842948',
          leadType: 'Requirement',
          stage: 'NEW',
          source: 'Meta',
          allocationStatus: 'ASSIGNED_TO_TELECALLER',
          createdAt: '2026-10-03T12:37:54.356Z',
        ),
        const LeadListItem(
          id: '3',
          customerName: 'Zeel',
          phone: '9584366883',
          sanitizedPhone: '9584366883',
          leadType: 'Property Listing',
          stage: 'NEW',
          source: 'Meta',
          allocationStatus: 'ASSIGNED_TO_TELECALLER',
          createdAt: '2026-09-25T10:49:34.266Z',
        ),
        // 7 Duplicate rows of Hetal Sapan Oza
        const LeadListItem(
          id: 'dup-1',
          customerName: 'Hetal Sapan Oza',
          phone: '9909929003',
          sanitizedPhone: '9909929003',
          leadType: 'Requirement',
          stage: 'NEW',
          source: 'Webhook',
          allocationStatus: 'ASSIGNED_TO_TELECALLER',
          createdAt: '2026-09-24T08:01:15.270Z',
        ),
        const LeadListItem(
          id: 'dup-2',
          customerName: 'Hetal Sapan Oza',
          phone: '9909929003',
          sanitizedPhone: '9909929003',
          leadType: 'Requirement',
          stage: 'NEW',
          source: 'Webhook',
          allocationStatus: 'ASSIGNED_TO_TELECALLER',
          createdAt: '2026-09-24T07:59:47.826Z',
        ),
        const LeadListItem(
          id: 'dup-3',
          customerName: 'Hetal Sapan Oza',
          phone: '9909929003',
          sanitizedPhone: '9909929003',
          leadType: 'Requirement',
          stage: 'NEW',
          source: 'Webhook',
          allocationStatus: 'ASSIGNED_TO_TELECALLER',
          createdAt: '2026-09-24T07:59:36.958Z',
        ),
        const LeadListItem(
          id: 'dup-4',
          customerName: 'Hetal Sapan Oza',
          phone: '9909929003',
          sanitizedPhone: '9909929003',
          leadType: 'Requirement',
          stage: 'NEW',
          source: 'Webhook',
          allocationStatus: 'ASSIGNED_TO_TELECALLER',
          createdAt: '2026-09-24T07:59:00.413Z',
        ),
        const LeadListItem(
          id: 'dup-5',
          customerName: 'Hetal Sapan Oza',
          phone: '9909929003',
          sanitizedPhone: '9909929003',
          leadType: 'Requirement',
          stage: 'NEW',
          source: 'Webhook',
          allocationStatus: 'ASSIGNED_TO_TELECALLER',
          createdAt: '2026-09-24T07:56:25.822Z',
        ),
        const LeadListItem(
          id: 'dup-6',
          customerName: 'Hetal Sapan Oza',
          phone: '9909929003',
          sanitizedPhone: '9909929003',
          leadType: 'Requirement',
          stage: 'NEW',
          source: 'Webhook',
          allocationStatus: 'ASSIGNED_TO_TELECALLER',
          createdAt: '2026-09-24T07:55:52.004Z',
        ),
        const LeadListItem(
          id: 'dup-7',
          customerName: 'Hetal Sapan Oza',
          phone: '9909929003',
          sanitizedPhone: '9909929003',
          leadType: 'Requirement',
          stage: 'NEW',
          source: 'Webhook',
          allocationStatus: 'ASSIGNED_TO_TELECALLER',
          createdAt: '2026-09-24T07:55:48.549Z',
        ),
        const LeadListItem(
          id: '4',
          customerName: 'Sangita Raval',
          phone: '9429132428',
          sanitizedPhone: '9429132428',
          leadType: 'Property Listing',
          stage: 'NEW',
          source: 'Meta',
          allocationStatus: 'ASSIGNED_TO_TELECALLER',
          createdAt: '2026-09-23T13:25:06.924Z',
        ),
        const LeadListItem(
          id: '5',
          customerName: 'jayesh pandya',
          phone: '8780584456',
          sanitizedPhone: '8780584456',
          leadType: 'Property Listing',
          stage: 'NEW',
          source: 'Meta',
          allocationStatus: 'ASSIGNED_TO_TELECALLER',
          createdAt: '2026-09-23T13:25:06.643Z',
        ),
        const LeadListItem(
          id: '6',
          customerName: 'Monica',
          phone: '6351721811',
          sanitizedPhone: '6351721811',
          leadType: 'Property Listing',
          stage: 'NEW',
          source: 'Meta',
          allocationStatus: 'ASSIGNED_TO_TELECALLER',
          createdAt: '2026-09-23T13:25:06.264Z',
        ),
        const LeadListItem(
          id: '7',
          customerName: 'Tushar Vara',
          phone: '9824053050',
          sanitizedPhone: '9824053050',
          leadType: 'Property Listing',
          stage: 'NEW',
          source: 'Meta',
          allocationStatus: 'ASSIGNED_TO_TELECALLER',
          createdAt: '2026-09-23T13:25:06.040Z',
        ),
        const LeadListItem(
          id: '8',
          customerName: 'Roshan Tiwari',
          phone: '8758830117',
          sanitizedPhone: '8758830117',
          leadType: 'Property Listing',
          stage: 'NEW',
          source: 'Meta',
          allocationStatus: 'ASSIGNED_TO_TELECALLER',
          createdAt: '2026-09-23T13:25:05.830Z',
        ),
      ];

      expect(rawLeads.length, 15);

      final seen = <String>{};
      final uniqueLeads = <LeadListItem>[];
      for (final l in rawLeads) {
        final digits = l.phone.replaceAll(RegExp(r'\D'), '');
        final phoneKey = digits.length >= 10
            ? digits.substring(digits.length - 10)
            : (l.phone.trim().isNotEmpty ? l.phone.trim() : l.id);
        final key = '${phoneKey}_${l.leadType.trim().toLowerCase()}';
        if (seen.add(key)) {
          uniqueLeads.add(l);
        }
      }

      // Must be exactly 9 leads
      expect(uniqueLeads.length, 9);

      // Hetal Sapan Oza must be included exactly once
      final hetalLeads = uniqueLeads.where((l) => l.customerName == 'Hetal Sapan Oza').toList();
      expect(hetalLeads.length, 1);
      expect(hetalLeads.first.id, 'dup-1');
      expect(hetalLeads.first.phone, '9909929003');
    });
  });
}
