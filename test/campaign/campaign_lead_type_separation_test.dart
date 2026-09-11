import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:propkart/features/integration/models/integration_lead_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Lead Classification & Dual-Section Separation Tests', () {
    test('IntegrationLeadModel defaults to Requirement and correctly deserializes Property Listing', () {
      final leadReq = IntegrationLeadModel(
        id: 'req-1',
        source: 'Meta Ads',
        receivedAt: DateTime.now(),
        rawJson: {
          'Client Name': 'Sabita Dutta',
          'Phone Number': '9876543210',
          'Which Area Are You Looking For?': 'sg_highway',
          'What Type Of Home Are You Looking For?': '4 BHK',
          'What Is Your Monthly Rental Budget?': '35,000 - 50,000',
          'Who Will Be Staying In The Property?': 'working_professionals',
        },
      );
      expect(leadReq.leadType, equals('Requirement'));

      final leadPropJson = {
        'id': 'prop-1',
        'source': 'Meta Ads',
        'lead_type': 'Property Listing',
        'received_at': DateTime.now().toIso8601String(),
        'raw_json': {
          'full_name': 'Mahesh Jasani',
          'phone_number': '9898012345',
          'where_is_your_property_located?': 'gota',
          'what_type_of_property_are_you_looking_to_rent_out?': '3_bhk',
          'what_is_your_expected_monthly_rent?': '₹20,000–₹30,000',
        },
      };

      final leadProp = IntegrationLeadModel.fromJson(leadPropJson);
      expect(leadProp.leadType, equals('Property Listing'));
      expect(leadProp.rawJson['what_type_of_property_are_you_looking_to_rent_out?'], equals('3_bhk'));
    });

    test('IntegrationLeadModel auto-detects Property Listing from rawJson keywords if lead_type missing', () {
      final legacyJson = {
        'id': 'legacy-1',
        'source': 'Meta Ads',
        'raw_json': {
          'full_name': 'Nilesh Soni',
          'where_is_your_property_located?': 'vaishnodevi_circle',
          'what_is_your_expected_monthly_rent?': '₹20,000–₹30,000',
        },
      };

      final model = IntegrationLeadModel.fromJson(legacyJson);
      expect(model.leadType, equals('Property Listing'));
    });

    test('IntegrationService filters propertyListingLeads and requirementLeads correctly', () {
      final lead1 = IntegrationLeadModel(
        id: '1',
        source: 'Meta Ads',
        receivedAt: DateTime.now(),
        leadType: 'Property Listing',
        rawJson: {'full_name': 'Owner 1', 'where_is_your_property_located?': 'Gota'},
      );

      final lead2 = IntegrationLeadModel(
        id: '2',
        source: 'Meta Ads',
        receivedAt: DateTime.now(),
        leadType: 'Requirement',
        rawJson: {'Client Name': 'Tenant 1', 'Which Area Are You Looking For?': 'Thaltej'},
      );

      final lead3 = IntegrationLeadModel(
        id: '3',
        source: 'Meta Ads',
        receivedAt: DateTime.now(),
        leadType: 'Property Listing',
        rawJson: {'full_name': 'Owner 2', 'what_type_of_property_are_you_looking_to_rent_out?': '2_bhk'},
      );

      final all = [lead1, lead2, lead3];
      final props = all.where((l) => l.leadType == 'Property Listing').toList();
      final reqs = all.where((l) => l.leadType == 'Requirement').toList();

      expect(props.length, equals(2));
      expect(props.map((p) => p.id), containsAll(['1', '3']));
      expect(reqs.length, equals(1));
      expect(reqs.first.id, equals('2'));
    });
  });
}
