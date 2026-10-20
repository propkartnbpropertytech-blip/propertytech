import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'web_storage_service.dart';

/// One-time, safe, idempotent migration from legacy browser localStorage
/// to IndexedDB for Flutter Web.
class WebStorageMigration {
  static const String migrationFlagKey = 'web_storage_migration_completed_v1';

  /// Execute migration if needed. Safe to call multiple times (idempotent).
  static Future<void> migrateLegacyLocalStorageIfNeeded({bool force = false}) async {
    if (!kIsWeb && !force) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadyMigrated = prefs.getBool(migrationFlagKey) ?? false;
      if (alreadyMigrated) {
        return;
      }

      await WebStorage().initialize();

      // Check if metadata store already records migration
      final metaRecord = await WebStorage().getRecord(
        WebStorageStores.metadata,
        'migration_v1',
      );
      if (metaRecord != null) {
        await prefs.setBool(migrationFlagKey, true);
        return;
      }

      debugPrint('WebStorageMigration: Starting legacy localStorage -> IndexedDB migration...');

      // 1. Migrate Properties
      final rawProps = prefs.getStringList('cached_properties');
      if (rawProps != null && rawProps.isNotEmpty) {
        final batch = <String, String>{};
        for (final item in rawProps) {
          try {
            final map = jsonDecode(item);
            final id = map['id']?.toString();
            if (id != null && id.isNotEmpty) {
              batch[id] = item;
            }
          } catch (_) {}
        }
        if (batch.isNotEmpty) {
          await WebStorage().putBatch(WebStorageStores.properties, batch);
          debugPrint('WebStorageMigration: Migrated ${batch.length} properties to IndexedDB.');
        }
      }

      // 2. Migrate Requirements
      final rawReqs = prefs.getStringList('cached_requirements');
      if (rawReqs != null && rawReqs.isNotEmpty) {
        final batch = <String, String>{};
        for (final item in rawReqs) {
          try {
            final map = jsonDecode(item);
            final id = map['id']?.toString();
            if (id != null && id.isNotEmpty) {
              batch[id] = item;
            }
          } catch (_) {}
        }
        if (batch.isNotEmpty) {
          await WebStorage().putBatch(WebStorageStores.requirements, batch);
          debugPrint('WebStorageMigration: Migrated ${batch.length} requirements to IndexedDB.');
        }
      }

      // 3. Migrate Followups
      final rawFollowups = prefs.getStringList('cached_followups');
      if (rawFollowups != null && rawFollowups.isNotEmpty) {
        final batch = <String, String>{};
        for (final item in rawFollowups) {
          try {
            final map = jsonDecode(item);
            final id = map['id']?.toString();
            if (id != null && id.isNotEmpty) {
              batch[id] = item;
            }
          } catch (_) {}
        }
        if (batch.isNotEmpty) {
          await WebStorage().putBatch(WebStorageStores.followups, batch);
          debugPrint('WebStorageMigration: Migrated ${batch.length} followups to IndexedDB.');
        }
      }

      // 4. Migrate Lookups
      final rawLookups = prefs.getStringList('cached_lookups');
      if (rawLookups != null && rawLookups.isNotEmpty) {
        final batch = <String, String>{};
        for (final item in rawLookups) {
          try {
            final map = jsonDecode(item);
            final id = map['id']?.toString();
            if (id != null && id.isNotEmpty) {
              batch[id] = item;
            }
          } catch (_) {}
        }
        if (batch.isNotEmpty) {
          await WebStorage().putBatch(WebStorageStores.lookups, batch);
          debugPrint('WebStorageMigration: Migrated ${batch.length} lookups to IndexedDB.');
        }
      }

      // 5. Migrate Campaign Leads
      final rawCampaignLeads = prefs.getString('isar_campaign_leads_web_v1');
      if (rawCampaignLeads != null && rawCampaignLeads.isNotEmpty) {
        try {
          final list = jsonDecode(rawCampaignLeads) as List<dynamic>;
          final batch = <String, String>{};
          for (final item in list) {
            final map = item as Map<String, dynamic>;
            final id = map['id']?.toString();
            if (id != null && id.isNotEmpty) {
              batch[id] = jsonEncode(map);
            }
          }
          if (batch.isNotEmpty) {
            await WebStorage().putBatch(WebStorageStores.campaignLeads, batch);
            debugPrint('WebStorageMigration: Migrated ${batch.length} campaign leads to IndexedDB.');
          }
        } catch (_) {}
      }

      // 6. Record migration metadata
      final metaData = jsonEncode({
        'status': 'completed',
        'migratedAt': DateTime.now().toIso8601String(),
        'version': 1,
      });
      await WebStorage().putRecord(WebStorageStores.metadata, 'migration_v1', metaData);
      await prefs.setBool(migrationFlagKey, true);

      // 7. Cleanup legacy large string lists from localStorage to prevent quota exhaustion
      await prefs.remove('cached_properties');
      await prefs.remove('cached_requirements');
      await prefs.remove('cached_followups');
      await prefs.remove('cached_lookups');
      await prefs.remove('isar_campaign_leads_web_v1');

      debugPrint('WebStorageMigration: Legacy localStorage cleanup completed successfully.');
    } catch (e) {
      debugPrint('WebStorageMigration: Error during migration: $e');
    }
  }
}
