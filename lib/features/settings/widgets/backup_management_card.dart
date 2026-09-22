import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/utils/file_downloader.dart';

class BackupManagementCard extends StatefulWidget {
  const BackupManagementCard({super.key});

  @override
  State<BackupManagementCard> createState() => _BackupManagementCardState();
}

class _BackupManagementCardState extends State<BackupManagementCard> {
  bool _isLoading = false;
  bool _isDownloading = false;
  bool _isRunningBackup = false;
  List<Map<String, dynamic>> _backups = [];
  Map<String, dynamic>? _latestBackup;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchBackups();
  }

  Future<void> _fetchBackups() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await DioClient.dio.get('/backup/list');
      if (res.data != null && res.data['success'] == true) {
        final data = res.data['data'];
        final list = (data['backups'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        final latest = data['latest'] != null
            ? Map<String, dynamic>.from(data['latest'] as Map)
            : (list.isNotEmpty ? list.first : null);

        if (mounted) {
          setState(() {
            _backups = list;
            _latestBackup = latest;
            _isLoading = false;
          });
        }
      } else {
        throw Exception(res.data?['message'] ?? 'Failed to load backups');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadLatestBackup() async {
    if (_latestBackup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No backup available to download.')),
      );
      return;
    }

    final filename = _latestBackup!['filename']?.toString() ?? 'propkart_daily_backup.dump';
    await _downloadSpecificBackup(filename);
  }

  Future<void> _downloadSpecificBackup(String filename) async {
    setState(() => _isDownloading = true);

    try {
      final res = await DioClient.dio.get(
        '/backup/download/$filename',
        options: Options(responseType: ResponseType.bytes),
      );

      if (res.data != null) {
        final bytes = res.data as List<int>;
        await FileDownloader.download(bytes, filename);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Downloaded $filename (${bytes.length} bytes)'),
              backgroundColor: CRMColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: CRMColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _runBackupNow() async {
    setState(() => _isRunningBackup = true);

    try {
      final res = await DioClient.dio.post('/backup/run');
      if (res.data != null && res.data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res.data['message'] ?? 'Backup snapshot created successfully!'),
              backgroundColor: CRMColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        await _fetchBackups();
      } else {
        throw Exception(res.data?['message'] ?? 'Failed to trigger backup');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: $e'),
            backgroundColor: CRMColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRunningBackup = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CRMCard(
      elevated: true,
      title: 'Automated Daily Backups (Hostinger VPS)',
      subtitle:
          'Daily offsite PostgreSQL database snapshots and analytical CSV masters stored in Hostinger VPS with a 21-day rolling retention.',
      headerAction: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CRMButton(
            label: 'Download Latest Daily Backup',
            prefixIcon: Icons.download_rounded,
            isLoading: _isDownloading,
            onPressed: _latestBackup == null ? null : _downloadLatestBackup,
          ),
          const SizedBox(width: 8),
          CRMButton(
            label: 'Run Backup Now',
            prefixIcon: Icons.backup_rounded,
            variant: CRMButtonVariant.secondary,
            isLoading: _isRunningBackup,
            onPressed: _runBackupNow,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Refresh backup list',
            onPressed: _isLoading ? null : _fetchBackups,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: CRMSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status overview pill
            Container(
              padding: const EdgeInsets.all(CRMSpacing.m),
              decoration: BoxDecoration(
                color: CRMColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CRMColors.success.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.cloud_done_rounded, color: CRMColors.success, size: 28),
                  const SizedBox(width: CRMSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _latestBackup != null
                              ? 'Latest Daily Snapshot: ${_latestBackup!['filename']} (${_latestBackup!['sizeFormatted']})'
                              : 'No automated backups found yet.',
                          style: CRMTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: CRMColors.textOf(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Storage Target: Hostinger VPS (/root/backups/propkart) • 21-Day Retention',
                          style: CRMTypography.caption.copyWith(
                            color: CRMColors.textSecondaryOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: CRMSpacing.l),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(CRMSpacing.m),
                decoration: BoxDecoration(
                  color: CRMColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CRMColors.danger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: CRMColors.danger),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Failed to load backups: $_errorMessage',
                        style: TextStyle(color: CRMColors.danger),
                      ),
                    ),
                  ],
                ),
              )
            else if (_backups.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No backup snapshots found. Click "Run Backup Now" to create your first daily snapshot.',
                  style: TextStyle(color: CRMColors.textSecondaryOf(context)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _backups.length,
                separatorBuilder: (context, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _backups[index];
                  final isLatest = item['isLatest'] == true;
                  final filename = item['filename']?.toString() ?? item['id']?.toString() ?? 'backup';
                  final size = item['sizeFormatted']?.toString() ?? '--';
                  final createdAt = item['createdAt']?.toString() ?? '';

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isLatest ? CRMColors.success : CRMColors.primary).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isLatest ? Icons.verified_user_rounded : Icons.folder_zip_rounded,
                        color: isLatest ? CRMColors.success : CRMColors.primary,
                        size: 22,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          filename,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        if (isLatest) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: CRMColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: CRMColors.success.withValues(alpha: 0.4)),
                            ),
                            child: const Text(
                              'LATEST',
                              style: TextStyle(
                                color: CRMColors.success,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      'Size: $size • Created: $createdAt • Target: Hostinger VPS',
                      style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.download_rounded),
                      tooltip: 'Download snapshot',
                      onPressed: () => _downloadSpecificBackup(filename),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
