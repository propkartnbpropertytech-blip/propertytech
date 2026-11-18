import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/storage/isar_collections.dart';
import 'package:propkart/core/storage/local_repositories.dart';
import 'package:propkart/features/requirements/bloc/requirements_bloc.dart';

void main() {
  group('Inter-Sales Lead Transfer Frontend Invariants', () {
    test('FetchRequirementsEvent supports forceRefresh flag', () {
      final defaultEvent = FetchRequirementsEvent();
      expect(defaultEvent.refreshFromServer, isTrue);
      expect(defaultEvent.forceRefresh, isFalse);

      final forcedEvent = FetchRequirementsEvent(forceRefresh: true);
      expect(forcedEvent.refreshFromServer, isTrue);
      expect(forcedEvent.forceRefresh, isTrue);
    });

    test('RequirementLocalRepository.saveRequirements with clearExisting prunes transferred-away leads', () async {
      final repo = RequirementLocalRepository();
      final leadA = RequirementLocal()
        ..id = 'lead-a'
        ..clientName = 'Client A'
        ..clientMobile = '9999999991'
        ..assignedTo = 'sales-1'
        ..status = 'Assigned'
        ..createdAt = DateTime.now();

      final leadB = RequirementLocal()
        ..id = 'lead-b'
        ..clientName = 'Client B'
        ..clientMobile = '9999999992'
        ..assignedTo = 'sales-1'
        ..status = 'Assigned'
        ..createdAt = DateTime.now();

      await repo.saveRequirements([leadA, leadB], clearExisting: true);
      expect(RequirementLocalRepository.inMemory.keys, containsAll(['lead-a', 'lead-b']));

      // After lead-a is transferred to sales-2, unfiltered server refresh returns only lead-b
      await repo.saveRequirements([leadB], clearExisting: true);
      expect(RequirementLocalRepository.inMemory.containsKey('lead-a'), isFalse);
      expect(RequirementLocalRepository.inMemory.containsKey('lead-b'), isTrue);
    });
  });
}
