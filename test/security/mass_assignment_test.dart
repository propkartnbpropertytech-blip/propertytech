import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/properties/models/property_model.dart';
import 'package:propkart/features/requirements/models/requirement_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mass Assignment Protection Tests', () {
    test('PropertyModel.fromJson ignores unmapped privilege escalation fields', () {
      final poisonedJson = <String, dynamic>{
        'id': 'p123',
        'title': 'Test Property',
        'price': 5000000.0,
        'is_super_admin': true,
        'role': 'Super Admin',
        'bypass_tenant': true,
        'system_override': true,
      };

      final model = PropertyModel.fromJson(poisonedJson);
      expect(model.id, equals('p123'));
      expect(model.title, equals('Test Property'));
      expect(model.price, equals(5000000.0));

      final serialized = model.toJson();
      expect(serialized.containsKey('is_super_admin'), isFalse);
      expect(serialized.containsKey('bypass_tenant'), isFalse);
      expect(serialized.containsKey('system_override'), isFalse);
    });

    test('RequirementModel.fromJson safely deserializes without accepting injected permissions', () {
      final poisonedJson = <String, dynamic>{
        'id': 'r123',
        'client_name': 'Valid Customer',
        'client_mobile': '9876543210',
        'category_id': 'c1',
        'category_name': 'Residential',
        'property_type_id': 'pt1',
        'property_type_name': 'Apartment',
        'min_budget': 1000000.0,
        'max_budget': 2000000.0,
        'area_names': ['Vastrapur'],
        'status': 'Active',
        'created_at': DateTime.now().toIso8601String(),
        'escalate_privilege': true,
        'admin_override': true,
        'permissions': ['all'],
      };

      final model = RequirementModel.fromJson(poisonedJson);
      expect(model.id, equals('r123'));
      expect(model.clientName, equals('Valid Customer'));

      final serialized = model.toJson();
      expect(serialized.containsKey('escalate_privilege'), isFalse);
      expect(serialized.containsKey('admin_override'), isFalse);
      expect(serialized.containsKey('permissions'), isFalse);
    });
  });
}
