import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'isar_collections.dart';
import 'local_repositories.dart';

class IsarService {
  static final IsarService _instance = IsarService._internal();
  factory IsarService() => _instance;
  IsarService._internal();

  Isar? _isar;

  Isar get isar {
    if (_isar == null) {
      if (kIsWeb) {
        throw StateError("Isar database is not available on Flutter Web. Running in-memory instead.");
      }
      throw StateError("Isar has not been initialized. Call initialize() first.");
    }
    return _isar!;
  }

  Future<void> initialize() async {
    if (_isar != null) return;

    if (kIsWeb) {
      print("🌐 [ISAR WEB] Bypassing Isar.open. Running local repositories in-memory.");
      await LookupLocalRepository().loadInMemoryCache();
      await PropertyLocalRepository().loadInMemoryCache();
      await RequirementLocalRepository().loadInMemoryCache();
      return;
    }

    Directory dir;
    try {
      dir = await getApplicationSupportDirectory();
    } catch (e) {
      print("⚠️ [ISAR INIT] getApplicationSupportDirectory failed: $e. Falling back to getApplicationDocumentsDirectory...");
      dir = await getApplicationDocumentsDirectory();
    }

    final schemas = [
      LookupItemLocalSchema,
      PropertyLocalSchema,
      RequirementLocalSchema,
      FollowupLocalSchema,
      BuilderLocalSchema,
      OwnerLocalSchema,
      ClientLocalSchema,
      OutboxLocalSchema,
      DashboardLocalSchema,
    ];

    try {
      print("📁 [ISAR INIT] Opening Isar in directory: ${dir.path}");
      
      // Ensure any stale instance from a failed run or previous crash is closed
      final existing = Isar.getInstance();
      if (existing != null) {
        await existing.close();
      }

      _isar = await Isar.open(
        schemas,
        directory: dir.path,
      );
    } catch (e) {
      print("⚠️ [ISAR INIT WARNING] Failed to open Isar in support dir: $e. Attempting to close instance, clear database files, and retry...");
      try {
        // Cleanly close the instance so the name is released
        final existing = Isar.getInstance();
        if (existing != null) {
          await existing.close();
        }

        // Delete support directory database files
        final isarFile = File('${dir.path}/default.isar');
        if (await isarFile.exists()) {
          await isarFile.delete();
        }
        final lockFile = File('${dir.path}/default.isar.lock');
        if (await lockFile.exists()) {
          await lockFile.delete();
        }

        // Delete documents directory database files in case they exist
        try {
          final docDir = await getApplicationDocumentsDirectory();
          final docIsarFile = File('${docDir.path}/default.isar');
          if (await docIsarFile.exists()) {
            await docIsarFile.delete();
          }
          final docLockFile = File('${docDir.path}/default.isar.lock');
          if (await docLockFile.exists()) {
            await docLockFile.delete();
          }
        } catch (_) {}

        print("📁 [ISAR INIT] Retrying open after database files clear...");
        _isar = await Isar.open(
          schemas,
          directory: dir.path,
        );
      } catch (retryError) {
        print("❌ [ISAR FATAL ERROR] Failed to open Isar after clear/retry: $retryError");
        
        // Final fallback: If both fail, try a custom instance name so the app runs successfully
        try {
          print("📁 [ISAR INIT] Fallback: Opening Isar with custom instance name 'propkart_db'...");
          final existing = Isar.getInstance('propkart_db');
          if (existing != null) {
            await existing.close();
          }
          _isar = await Isar.open(
            schemas,
            directory: dir.path,
            name: 'propkart_db',
          );
        } catch (fallbackError) {
          print("❌ [ISAR ABSOLUTE FATAL] Fallback open failed: $fallbackError");
          rethrow;
        }
      }
    }
    await _migrateRequirements();
  }

  Future<void> _migrateRequirements() async {
    final requirements = await _isar!.requirementLocals.where().findAll();
    final toUpdate = <RequirementLocal>[];

    for (final req in requirements) {
      if (req.listingTypeId == null) {
        String? remarksStr = req.remarks;
        String? listingTypeId;
        String? listingTypeName;
        String? cleanRemarks = remarksStr;

        if (remarksStr != null && remarksStr.startsWith('[lt:')) {
          final closeBracketIdx = remarksStr.indexOf(']');
          if (closeBracketIdx != -1) {
            final content = remarksStr.substring('[lt:'.length, closeBracketIdx);
            final parts = content.split(':');
            if (parts.isNotEmpty) {
              listingTypeId = parts[0];
              if (parts.length > 1) {
                listingTypeName = parts[1];
              }
            }
            cleanRemarks = remarksStr.substring(closeBracketIdx + 1).trim();
            if (cleanRemarks.isEmpty) cleanRemarks = null;
          }
        }

        req.listingTypeId = listingTypeId ?? 'Unknown';
        req.listingTypeName = listingTypeName ?? 'Unknown';
        req.remarks = cleanRemarks;
        toUpdate.add(req);
      }
    }

    if (toUpdate.isNotEmpty) {
      print("🔄 [ISAR MIGRATION] Migrating ${toUpdate.length} requirements with listing type columns...");
      await _isar!.writeTxn(() async {
        await _isar!.requirementLocals.putAll(toUpdate);
      });
      print("✅ [ISAR MIGRATION] Requirements migration complete.");
    }
  }

  Future<void> clearAll() async {
    await isar.writeTxn(() async {
      await isar.clear();
    });
  }
}
