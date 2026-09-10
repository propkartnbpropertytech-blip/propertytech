import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:propkart/features/integration/services/integration_service.dart';
import 'package:propkart/features/integration/models/integration_lead_model.dart';
import 'package:propkart/core/storage/local_repositories.dart';
import 'package:propkart/core/storage/isar_collections.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    CampaignLeadLocalRepository.inMemory.clear();
    final service = IntegrationService();
    await service.clearAllLeads();
  });

  group('Campaign Google Sheet Header Order & Reordering Tests', () {
    test('Preserves exact Google Sheet column sequence when rows are ingested', () async {
      final service = IntegrationService();
      await service.ensureLoaded();

      final sheetRows = [
        {
          'Unique_ID': 'SH-001',
          'Client_Name': 'Aditi Rao',
          'Contact_Phone': '+91 9988776655',
          'Preferred_City': 'Pune',
          'Budget_Range': '90 Lakhs',
          'Unit_Type': '2 BHK',
          'Sheet_Notes': 'Immediate buyer',
        },
      ];

      await service.ingestRows(sheetRows, source: 'Google Sheets');

      final headers = service.getDetectedHeaders();

      // Ensure headers strictly reflect the sheet order (NOT re-arranged by hardcoded priorities)
      expect(headers, equals([
        'Unique_ID',
        'Client_Name',
        'Contact_Phone',
        'Preferred_City',
        'Budget_Range',
        'Unit_Type',
        'Sheet_Notes',
      ]));
    });

    test('Drag-and-drop reordering moves headers accurately', () async {
      final service = IntegrationService();
      await service.ensureLoaded();

      final sheetRows = [
        {
          'Col_A': '1',
          'Col_B': '2',
          'Col_C': '3',
          'Col_D': '4',
        }
      ];

      await service.ingestRows(sheetRows, source: 'Google Sheets');
      expect(service.getDetectedHeaders(), equals(['Col_A', 'Col_B', 'Col_C', 'Col_D']));

      // Move Col_A (index 0) to after Col_B (index 2 in Flutter ReorderableListView convention)
      await service.reorderHeaders(0, 2);
      expect(service.getDetectedHeaders(), equals(['Col_B', 'Col_A', 'Col_C', 'Col_D']));

      // Move Col_D (index 3) to start (index 0)
      await service.reorderHeaders(3, 0);
      expect(service.getDetectedHeaders(), equals(['Col_D', 'Col_B', 'Col_A', 'Col_C']));
    });

    test('Move header left (-1) and right (+1) works correctly', () async {
      final service = IntegrationService();
      await service.ensureLoaded();

      final sheetRows = [
        {'Alpha': 'a', 'Beta': 'b', 'Gamma': 'c'}
      ];
      await service.ingestRows(sheetRows, source: 'Google Sheets');

      // Move Beta left
      await service.moveHeader('Beta', -1);
      expect(service.getDetectedHeaders(), equals(['Beta', 'Alpha', 'Gamma']));

      // Move Beta right
      await service.moveHeader('Beta', 1);
      expect(service.getDetectedHeaders(), equals(['Alpha', 'Beta', 'Gamma']));
    });

    test('Reset to Sheet Order restores the original column layout', () async {
      final service = IntegrationService();
      await service.ensureLoaded();

      final sheetRows = [
        {'First': '1', 'Second': '2', 'Third': '3'}
      ];
      await service.ingestRows(sheetRows, source: 'Google Sheets');

      // Jumble columns
      await service.reorderHeaders(0, 3);
      expect(service.getDetectedHeaders(), equals(['Second', 'Third', 'First']));

      // Reset to original sheet order
      await service.resetHeaderOrderToSheet();
      expect(service.getDetectedHeaders(), equals(['First', 'Second', 'Third']));
    });
  });

  group('Campaign Leads Persistence Tests', () {
    test('CampaignLeadLocalRepository persists and retrieves leads across sessions', () async {
      final repo = CampaignLeadLocalRepository();

      final testLead = CampaignLeadLocal()
        ..id = 'test_lead_001'
        ..source = 'Google Sheets'
        ..rawJsonString = '{"Full Name": "Test Buyer", "City": "Mumbai"}'
        ..receivedAt = DateTime.now()
        ..isDuplicate = false
        ..importStatus = 'Pending'
        ..qualityStatus = 'Qualified';

      await repo.saveLead(testLead);

      final leads = await repo.getLeads();
      expect(leads.any((l) => l.id == 'test_lead_001'), isTrue);

      final retrieved = leads.firstWhere((l) => l.id == 'test_lead_001');
      expect(retrieved.source, equals('Google Sheets'));
      expect(retrieved.qualityStatus, equals('Qualified'));

      // Delete lead test
      await repo.deleteLead('test_lead_001');
      final leadsAfterDelete = await repo.getLeads();
      expect(leadsAfterDelete.any((l) => l.id == 'test_lead_001'), isFalse);
    });
  });

  group('Excel-Style Filtering & Sorting Simulation Tests', () {
    test('Compound column filtering with unique values and (Blanks)', () {
      final sampleLeads = [
        IntegrationLeadModel(
          id: '1',
          source: 'Google Sheets',
          rawJson: {'City': 'Mumbai', 'Budget': '1 Cr', 'Config': '2 BHK'},
          receivedAt: DateTime.now(),
        ),
        IntegrationLeadModel(
          id: '2',
          source: 'Google Sheets',
          rawJson: {'City': 'Pune', 'Budget': '75 Lakhs', 'Config': '1 BHK'},
          receivedAt: DateTime.now(),
        ),
        IntegrationLeadModel(
          id: '3',
          source: 'Meta Ads',
          rawJson: {'City': 'Mumbai', 'Budget': '2 Cr', 'Config': '3 BHK'},
          receivedAt: DateTime.now(),
        ),
        IntegrationLeadModel(
          id: '4',
          source: 'Google Sheets',
          rawJson: {'City': '', 'Budget': '50 Lakhs', 'Config': '1 BHK'},
          receivedAt: DateTime.now(),
        ),
      ];

      // Filter: City in {'Mumbai', '(Blanks)'}
      final cityFilter = {'Mumbai', '(Blanks)'};
      final filtered = sampleLeads.where((lead) {
        final rawCity = lead.getStringValue('City').trim();
        final matchCity = rawCity.isEmpty ? '(Blanks)' : rawCity;
        return cityFilter.contains(matchCity);
      }).toList();

      expect(filtered.length, equals(3));
      expect(filtered.map((l) => l.id), containsAll(['1', '3', '4']));
      expect(filtered.any((l) => l.id == '2'), isFalse);
    });

    test('Excel sorting alphabetically and reverse', () {
      final sampleLeads = [
        IntegrationLeadModel(
          id: '1',
          source: 'Google Sheets',
          rawJson: {'Name': 'Charlie'},
          receivedAt: DateTime.now(),
        ),
        IntegrationLeadModel(
          id: '2',
          source: 'Google Sheets',
          rawJson: {'Name': 'Alice'},
          receivedAt: DateTime.now(),
        ),
        IntegrationLeadModel(
          id: '3',
          source: 'Google Sheets',
          rawJson: {'Name': 'Bob'},
          receivedAt: DateTime.now(),
        ),
      ];

      // Sort Ascending (A to Z)
      final ascList = List<IntegrationLeadModel>.from(sampleLeads);
      ascList.sort((a, b) => a.getStringValue('Name').compareTo(b.getStringValue('Name')));
      expect(ascList.map((l) => l.getStringValue('Name')).toList(), equals(['Alice', 'Bob', 'Charlie']));

      // Sort Descending (Z to A)
      final descList = List<IntegrationLeadModel>.from(sampleLeads);
      descList.sort((a, b) => b.getStringValue('Name').compareTo(a.getStringValue('Name')));
      expect(descList.map((l) => l.getStringValue('Name')).toList(), equals(['Charlie', 'Bob', 'Alice']));
    });
  });
}
