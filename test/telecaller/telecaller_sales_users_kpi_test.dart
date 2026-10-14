import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Telecaller Sales Users KPI & Date Filter Logic Tests', () {
    test('1. Deduplicates sales users by email and phone preventing duplicate counting', () {
      final rawSalesUsers = [
        {'id': '1', 'name': 'Somel Rathod', 'email': 'somel@nbpropertytech.com', 'mobile': '9016134875'},
        {'id': '2', 'name': 'Rajan Purani', 'email': 'rajan@nbpropertytech.com', 'mobile': '6357993704'},
        {'id': '3', 'name': 'Rakesh Jadav', 'email': 'rakesh@nbpropertytech.com', 'mobile': '9227087898'},
        {'id': '4', 'name': 'Viral Jadeja', 'email': 'viral.jadeja465@gmail.com', 'mobile': '9016134878'},
        // Duplicate entry for Viral Jadeja with same email
        {'id': '5-dup', 'name': 'Viral Jadeja', 'email': 'viral.jadeja465@gmail.com', 'mobile': '9016134878'},
        // Duplicate entry with uppercase / whitespace variations
        {'id': '6-dup', 'name': 'Somel Rathod', 'email': ' SOMEL@nbpropertytech.com ', 'mobile': '9016134875'},
      ];

      final uniqueKeys = <String>{};
      final deduplicatedUsers = <Map<String, String>>[];

      for (final user in rawSalesUsers) {
        final email = (user['email'] ?? '').trim().toLowerCase();
        final mobile = (user['mobile'] ?? '').trim();
        final key = email.isNotEmpty ? email : (mobile.isNotEmpty ? mobile : user['id']!);
        if (uniqueKeys.add(key)) {
          deduplicatedUsers.add(user);
        }
      }

      // Exactly 4 unique salespersons
      expect(deduplicatedUsers.length, 4);
      expect(deduplicatedUsers.map((u) => u['name']).toList(), [
        'Somel Rathod',
        'Rajan Purani',
        'Rakesh Jadav',
        'Viral Jadeja',
      ]);
    });

    test('2. When a new Salesperson is added, KPI count increments accurately without duplicates', () {
      final existingUsers = [
        {'id': '1', 'name': 'Somel Rathod', 'email': 'somel@nbpropertytech.com'},
        {'id': '2', 'name': 'Rajan Purani', 'email': 'rajan@nbpropertytech.com'},
        {'id': '3', 'name': 'Rakesh Jadav', 'email': 'rakesh@nbpropertytech.com'},
        {'id': '4', 'name': 'Viral Jadeja', 'email': 'viral.jadeja465@gmail.com'},
      ];

      // Add a newly joined salesperson
      final newSalesperson = {'id': '5', 'name': 'Kavya Sharma', 'email': 'kavya@nbpropertytech.com'};
      final duplicateNewSalesperson = {'id': '6', 'name': 'Kavya Sharma', 'email': 'kavya@nbpropertytech.com'};

      final updatedUsers = [...existingUsers, newSalesperson, duplicateNewSalesperson];

      final uniqueKeys = <String>{};
      final deduped = <Map<String, String>>[];
      for (final u in updatedUsers) {
        final key = (u['email'] ?? '').trim().toLowerCase();
        if (uniqueKeys.add(key)) {
          deduped.add(u);
        }
      }

      // Exactly 5 unique salespersons (duplicate new salesperson rejected)
      expect(deduped.length, 5);
      expect(deduped.any((u) => u['name'] == 'Kavya Sharma'), isTrue);
    });

    test('3. Date filter matches timestamps within selected period', () {
      final now = DateTime(2026, 10, 13, 14, 0, 0);

      bool matchesDate(DateTime dt, String filter, {DateTime? customStart, DateTime? customEnd}) {
        final local = dt.toLocal();
        if (filter == 'Today') {
          return local.year == now.year && local.month == now.month && local.day == now.day;
        } else if (filter == 'Weekly') {
          final startOf7Days = DateTime(now.year, now.month, now.day - 6);
          final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
          return !local.isBefore(startOf7Days) && !local.isAfter(endOfToday);
        } else if (filter == 'Monthly') {
          final startOf30Days = DateTime(now.year, now.month, now.day - 29);
          final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
          return !local.isBefore(startOf30Days) && !local.isAfter(endOfToday);
        } else if (filter == 'Custom Range') {
          if (customStart != null && customEnd != null) {
            return !local.isBefore(customStart) && !local.isAfter(customEnd);
          }
        }
        return true;
      }

      final todayDate = DateTime(2026, 10, 13, 9, 30);
      final threeDaysAgo = DateTime(2026, 10, 10, 11, 0);
      final twoWeeksAgo = DateTime(2026, 9, 29, 15, 0);
      final threeMonthsAgo = DateTime(2026, 7, 15, 10, 0);

      // Today filter
      expect(matchesDate(todayDate, 'Today'), isTrue);
      expect(matchesDate(threeDaysAgo, 'Today'), isFalse);
      expect(matchesDate(twoWeeksAgo, 'Today'), isFalse);

      // Weekly filter
      expect(matchesDate(todayDate, 'Weekly'), isTrue);
      expect(matchesDate(threeDaysAgo, 'Weekly'), isTrue);
      expect(matchesDate(twoWeeksAgo, 'Weekly'), isFalse);

      // Monthly filter
      expect(matchesDate(todayDate, 'Monthly'), isTrue);
      expect(matchesDate(threeDaysAgo, 'Monthly'), isTrue);
      expect(matchesDate(twoWeeksAgo, 'Monthly'), isTrue);
      expect(matchesDate(threeMonthsAgo, 'Monthly'), isFalse);

      // Custom Range filter (01 Oct to 11 Oct 2026)
      final cStart = DateTime(2026, 10, 1);
      final cEnd = DateTime(2026, 10, 11, 23, 59, 59);
      expect(matchesDate(threeDaysAgo, 'Custom Range', customStart: cStart, customEnd: cEnd), isTrue);
      expect(matchesDate(todayDate, 'Custom Range', customStart: cStart, customEnd: cEnd), isFalse);
      expect(matchesDate(twoWeeksAgo, 'Custom Range', customStart: cStart, customEnd: cEnd), isFalse);
    });
  });
}
