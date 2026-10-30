import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/security/role_guard.dart';
import 'package:propkart/features/telecaller/data/telecaller_repository.dart';

void main() {
  test('sales availability and heartbeat do not use the telecaller routes', () {
    expect(availabilityPathForRole('Sales'), '/sales/availability');
    expect(availabilityPathForRole('Salesperson'), '/sales/availability');
    expect(heartbeatPathForRole('Sales'), '/sales/heartbeat');
    expect(availabilityPathForRole('Telecaller'), '/telecaller/availability');
    expect(heartbeatPathForRole('Telecaller'), '/telecaller/heartbeat');
  });

  test('sales logout closes the allocation shift', () {
    expect(RoleGuard.endsAllocationShift('Sales'), isTrue);
    expect(RoleGuard.endsAllocationShift('Salesperson'), isTrue);
    expect(RoleGuard.endsAllocationShift('Telecaller'), isTrue);
    expect(RoleGuard.endsAllocationShift('Admin'), isFalse);
  });
}
