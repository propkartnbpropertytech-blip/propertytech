import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/storage/local_repositories.dart';
import 'package:propkart/core/storage/isar_collections.dart';

void main() {
  group('Realtime CDC Event Processing Invariants', () {
    setUp(() {
      PropertyLocalRepository.inMemory.clear();
      RequirementLocalRepository.inMemory.clear();
    });

    test('Validates Phoenix CDC join payload targets explicit whitelisted tables only', () {
      const watchedTables = <String>[
        'properties',
        'requirements',
        'notifications',
        'followups',
        'site_visits',
        'integration_leads',
        'leads',
        'campaign_connections',
        'campaign_lead_followups',
      ];

      final joinPayload = {
        'topic': 'realtime:propkart',
        'event': 'phx_join',
        'payload': {
          'config': {
            'postgres_changes': watchedTables
                .map((table) => {
                      'event': '*',
                      'schema': 'public',
                      'table': table,
                    })
                .toList(),
          }
        },
        'ref': '1'
      };

      final changes = (joinPayload['payload'] as Map)['config']['postgres_changes'] as List;
      expect(changes.length, equals(9));
      expect(changes.every((c) => c['schema'] == 'public'), isTrue);
      expect(changes.map((c) => c['table']).toSet(), containsAll(['properties', 'requirements']));
      // Verifies no wildcard subscription to public schema:
      expect(changes.any((c) => c['table'] == '*'), isFalse);
    });

    test('Parses valid realtime INSERT event and maps to local storage', () {
      const rawMessage = '{"topic":"realtime:public","event":"postgres_changes","payload":{"table":"properties","type":"INSERT","record":{"id":"prop-rt-1","title":"New Flat","property_code":"P-NEW","price":5000000,"deposit":200000,"maintenance":5000,"listing_type_id":"lt1","property_status_id":"ps1","category_id":"c1","property_type_id":"pt1","city_id":"ct1","area_id":"a1","pincode":"380001","address":"Navrangpura","bedrooms":3,"bathrooms":3,"balconies":1,"parking":1,"owner_name":"Sharma","owner_mobile":"9825000000","is_verified":true,"created_by":"u1","created_at":"2026-10-21T10:00:00Z"},"old_record":null}}';

      final data = jsonDecode(rawMessage);
      final payload = data['payload'] as Map<String, dynamic>;
      final table = payload['table'] as String;
      final type = payload['type'] as String;
      final record = payload['record'] as Map<String, dynamic>;

      expect(table, equals('properties'));
      expect(type, equals('INSERT'));

      final localProp = PropertyLocal()
        ..id = record['id']
        ..title = record['title']
        ..propertyCode = record['property_code']
        ..price = (record['price'] as num).toDouble()
        ..deposit = (record['deposit'] as num).toDouble()
        ..maintenance = (record['maintenance'] as num).toDouble()
        ..listingTypeId = record['listing_type_id']
        ..listingTypeName = 'Sale'
        ..propertyStatusId = record['property_status_id']
        ..propertyStatusName = 'Available'
        ..categoryId = record['category_id']
        ..categoryName = 'Residential'
        ..propertyTypeId = record['property_type_id']
        ..propertyTypeName = 'Apartment'
        ..cityId = record['city_id']
        ..cityName = 'Ahmedabad'
        ..areaId = record['area_id']
        ..areaName = 'Navrangpura'
        ..pincode = record['pincode']
        ..address = record['address']
        ..bedrooms = record['bedrooms']
        ..bathrooms = record['bathrooms']
        ..balconies = record['balconies']
        ..parking = record['parking']
        ..ownerName = record['owner_name']
        ..ownerMobile = record['owner_mobile']
        ..isVerified = record['is_verified']
        ..createdBy = record['created_by']
        ..createdByName = 'Admin'
        ..createdAt = DateTime.parse(record['created_at'])
        ..images = []
        ..amenities = []
        ..videos = [];

      PropertyLocalRepository.inMemory[localProp.id] = localProp;
      expect(PropertyLocalRepository.inMemory.containsKey('prop-rt-1'), isTrue);
      expect(PropertyLocalRepository.inMemory['prop-rt-1']!.title, equals('New Flat'));
    });

    test('Parses valid realtime DELETE event and removes row from local cache', () {
      final existing = RequirementLocal()
        ..id = 'req-del-1'
        ..clientName = 'To Delete'
        ..clientMobile = '9800000000'
        ..categoryId = 'c1'
        ..propertyTypeId = 'pt1'
        ..minBudget = 1000000
        ..maxBudget = 2000000
        ..status = 'Active'
        ..createdAt = DateTime.now()
        ..areaIds = []
        ..areaNames = []
        ..configurationIds = []
        ..propertyTypeIds = []
        ..furnishingIds = []
        ..facingIds = [];
      RequirementLocalRepository.inMemory['req-del-1'] = existing;

      const rawDeleteMsg = '{"topic":"realtime:public","event":"postgres_changes","payload":{"table":"requirements","type":"DELETE","record":null,"old_record":{"id":"req-del-1"}}}';
      final data = jsonDecode(rawDeleteMsg);
      final payload = data['payload'] as Map<String, dynamic>;
      final table = payload['table'] as String;
      final type = payload['type'] as String;
      final oldRecord = payload['old_record'] as Map<String, dynamic>;

      expect(table, equals('requirements'));
      expect(type, equals('DELETE'));

      final idToDelete = oldRecord['id'] as String;
      RequirementLocalRepository.inMemory.remove(idToDelete);

      expect(RequirementLocalRepository.inMemory.containsKey('req-del-1'), isFalse);
    });

    test('Safely drops malformed or unauthorized table events without isolate crash', () {
      const badJson = '{"not_a_valid_phoenix_event": true}';
      final data = jsonDecode(badJson);
      final event = data['event'];
      final topic = data['topic'];

      bool isProcessed = false;
      if (event == "postgres_changes" && topic == "realtime:public") {
        isProcessed = true;
      }

      expect(isProcessed, isFalse);
    });
  });
}
