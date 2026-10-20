import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/storage/session_cleanup.dart';
import 'package:propkart/features/library/models/area_item.dart';
import 'package:propkart/features/library/models/document_model.dart';
import 'package:propkart/features/library/repository/library_repository.dart';
import 'package:propkart/features/properties/models/property_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LibraryRepository libraryRepo;

  PropertyModel createDummyProperty(String id, String title) {
    return PropertyModel.fromJson({
      'id': id,
      'property_code': 'PROP-$id',
      'title': title,
      'price': 1000000,
      'listing_type_name': 'Rent',
      'category_name': 'Residential',
      'property_status_name': 'Active',
      'images': [],
    });
  }

  ServiceAgentDocument createDummyAgentDoc(String id, String name) {
    return ServiceAgentDocument(
      id: id,
      agentName: name,
      serviceType: 'Plumber',
      mobileNumber: '9876543210',
      documentName: 'Aadhaar Card',
      documentType: 'Aadhaar Card',
      uploadDate: DateTime.now(),
      uploadedBy: 'admin',
      status: DocumentStatus.active,
      description: 'Test document',
      fileSize: '500 KB',
      fileExtension: 'pdf',
      fileUrl: 'https://example.com/test.pdf',
      approvalStatus: 'approved',
      area: ['Thaltej'],
    );
  }

  setUp(() {
    libraryRepo = LibraryRepository();
    libraryRepo.clearCache();
  });

  group('LibraryRepository Caching & Deduplication Tests', () {
    test('getMasterProperties caches result and reuses cache within TTL', () async {
      expect(libraryRepo.hasCachedProperties, isFalse);

      final dummyList = [
        createDummyProperty('prop-1', 'Greenwood Villa'),
        createDummyProperty('prop-2', 'Skyline Heights'),
      ];

      libraryRepo.setCachedPropertiesForTesting(dummyList);
      expect(libraryRepo.hasCachedProperties, isTrue);

      // Call getMasterProperties without forceRefresh
      final result = await libraryRepo.getMasterProperties(forceRefresh: false);
      expect(result.length, 2);
      expect(result.first.title, 'Greenwood Villa');
    });

    test('invalidateMasterProperties clears cache and forces fresh fetch state', () async {
      libraryRepo.setCachedPropertiesForTesting([
        createDummyProperty('prop-1', 'Greenwood Villa'),
      ]);
      expect(libraryRepo.hasCachedProperties, isTrue);

      libraryRepo.invalidateMasterProperties();
      expect(libraryRepo.hasCachedProperties, isFalse);
    });

    test('getServiceAgentDocuments caches result and reuses within TTL', () async {
      expect(libraryRepo.hasCachedServiceAgents, isFalse);

      final dummyDocs = [
        createDummyAgentDoc('doc-1', 'Rajesh Sharma'),
        createDummyAgentDoc('doc-2', 'Amit Patel'),
      ];

      libraryRepo.setCachedServiceAgentsForTesting(dummyDocs);
      expect(libraryRepo.hasCachedServiceAgents, isTrue);

      final result = await libraryRepo.getServiceAgentDocuments(forceRefresh: false);
      expect(result.length, 2);
      expect(result.first.agentName, 'Rajesh Sharma');
    });

    test('invalidateServiceAgents clears cached service agent documents', () async {
      libraryRepo.setCachedServiceAgentsForTesting([
        createDummyAgentDoc('doc-1', 'Rajesh Sharma'),
      ]);
      expect(libraryRepo.hasCachedServiceAgents, isTrue);

      libraryRepo.invalidateServiceAgents();
      expect(libraryRepo.hasCachedServiceAgents, isFalse);
    });

    test('getServiceAgentAreas caches area metadata and returns cached list', () async {
      expect(libraryRepo.hasCachedAreas, isFalse);

      final dummyAreas = [
        AreaItem(id: '1', name: 'Thaltej', pincode: '380059'),
        AreaItem(id: '2', name: 'Bodakdev', pincode: '380054'),
      ];

      libraryRepo.setCachedAreasForTesting(dummyAreas);
      expect(libraryRepo.hasCachedAreas, isTrue);

      final result = await libraryRepo.getServiceAgentAreas(forceRefresh: false);
      expect(result.length, 2);
      expect(result.first.name, 'Thaltej');
      expect(result.last.pincode, '380054');
    });

    test('SessionCleanup.clearLocalSession clears all LibraryRepository in-memory caches for user isolation', () async {
      libraryRepo.setCachedPropertiesForTesting([createDummyProperty('prop-1', 'Villa')]);
      libraryRepo.setCachedServiceAgentsForTesting([createDummyAgentDoc('doc-1', 'Rajesh')]);
      libraryRepo.setCachedAreasForTesting([AreaItem(id: '1', name: 'Thaltej')]);

      expect(libraryRepo.hasCachedProperties, isTrue);
      expect(libraryRepo.hasCachedServiceAgents, isTrue);
      expect(libraryRepo.hasCachedAreas, isTrue);

      // Perform session cleanup
      await SessionCleanup.clearLocalSession(clearToken: false);

      expect(libraryRepo.hasCachedProperties, isFalse);
      expect(libraryRepo.hasCachedServiceAgents, isFalse);
      expect(libraryRepo.hasCachedAreas, isFalse);
    });

    test('parseServiceAgentDocument accurately parses json response with area fallback', () {
      final json = {
        'id': 'agent-101',
        'agent_name': 'Karan Verma',
        'service_type': 'Electrician',
        'mobile_number': '9988776655',
        'document_type': 'Trade Certificate',
        'upload_date': '2026-05-10T10:00:00.000Z',
        'uploaded_by': 'admin',
        'status': 'active',
        'approval_status': 'approved',
        'file_url': 'https://example.com/cert.pdf',
        'area': 'Vastrapur, Navrangpura',
      };

      final doc = LibraryRepository.parseServiceAgentDocument(json);
      expect(doc.id, 'agent-101');
      expect(doc.agentName, 'Karan Verma');
      expect(doc.serviceType, 'Electrician');
      expect(doc.area.length, 2);
      expect(doc.area.contains('Vastrapur'), isTrue);
      expect(doc.area.contains('Navrangpura'), isTrue);
    });
  });
}
