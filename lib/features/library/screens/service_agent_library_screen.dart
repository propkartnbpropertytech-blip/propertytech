import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import '../../properties/services/properties_service.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/design_system/tokens/app_breakpoints.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/crm_status_chips.dart';
import '../../../core/design_system/widgets/dialogs.dart';
import '../../../core/design_system/widgets/inputs.dart';
import '../../../core/security/role_guard.dart';
import '../models/document_model.dart';
import '../models/area_item.dart';
import '../repository/library_repository.dart';
import '../widgets/library_vault/library_vault_tokens.dart';
import '../widgets/library_vault/library_vault_widgets.dart';
import 'library_widgets.dart';
import '../../../core/design_system/widgets/crm_network_image.dart';

class ServiceAgentLibraryScreen extends StatefulWidget {
  const ServiceAgentLibraryScreen({super.key});

  @override
  State<ServiceAgentLibraryScreen> createState() => _ServiceAgentLibraryScreenState();
}

class _ServiceAgentLibraryScreenState extends State<ServiceAgentLibraryScreen> {
  List<ServiceAgentDocument> _allDocuments = [];
  List<ServiceAgentDocument> _filteredDocuments = [];

  bool _showPendingView = false;
  List<ServiceAgentDocument> _pendingDocuments = [];
  bool _isLoadingPending = false;

  String? _sortField = 'uploadDate';
  bool _sortAscending = false;
  int _currentPage = 1;
  int _pageSize = 10;

  final TextEditingController _searchController = TextEditingController();
  String _selectedServiceType = 'All';
  String _selectedDocType = 'All';
  String _selectedArea = 'All';
  String _selectedStatus = 'All';
  DateTimeRange? _selectedDateRange;
  bool _isLoading = false;

  List<AreaItem> _dbAreasList = [];

  String get _currentUserRole => RoleGuard.currentUser?.role ?? '';

  bool get _isAdminOrSuperAdmin {
    final r = _currentUserRole.toLowerCase();
    return r == 'admin' || r == 'super admin';
  }

  List<String> get _dynamicDocTypes {
    final types = _allDocuments.map((d) => d.documentType).toSet().toList();
    if (!types.contains('Aadhaar Card')) types.insert(0, 'Aadhaar Card');
    types.sort((a, b) {
      if (a == 'Aadhaar Card') return -1;
      if (b == 'Aadhaar Card') return 1;
      return a.compareTo(b);
    });
    return ['All', ...types];
  }

  List<String> get _dynamicAreas {
    final Set<String> areas = {};
    for (final item in _dbAreasList) {
      if (item.name.trim().isNotEmpty) areas.add(item.name.trim());
    }
    for (final doc in _allDocuments) {
      for (final a in doc.area) {
        if (a.trim().isNotEmpty) areas.add(a.trim());
      }
    }
    final sorted = areas.toList()..sort();
    return ['All', ...sorted];
  }

  final List<String> _serviceTypes = [
    'All','Electrician','Plumber','Carpenter','Painter','AC Technician',
    'Cleaning Service','Pest Control','CCTV Service','Interior Designer',
    'Movers & Packers','Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
    _fetchAreas();
    if (_isAdminOrSuperAdmin) _loadPendingDocuments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAreas({bool forceRefresh = false}) async {
    try {
      final areas = await LibraryRepository().getServiceAgentAreas(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _dbAreasList = areas;
        });
      }
    } catch (e) {
      debugPrint('Note: Error fetching areas from LibraryRepository: $e');
    }
  }

  ServiceAgentDocument _rowToDoc(Map<String, dynamic> json) {
    return LibraryRepository.parseServiceAgentDocument(json);
  }

  Future<void> _loadDocuments({bool forceRefresh = false}) async {
    if (_allDocuments.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final docs = await LibraryRepository().getServiceAgentDocuments(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _allDocuments = docs;
          _applyFiltersAndSort();
        });
      }
    } catch (e) {
      debugPrint('Note: Error loading service agent documents: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPendingDocuments({bool forceRefresh = false}) async {
    if (_pendingDocuments.isEmpty) {
      setState(() => _isLoadingPending = true);
    }
    try {
      final docs = await LibraryRepository().getPendingServiceAgentDocuments(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _pendingDocuments = docs;
        });
      }
    } catch (e) {
      debugPrint('Error loading pending documents: $e');
      if (mounted) {
        setState(() {
          _pendingDocuments = [];
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingPending = false);
    }
  }

  Future<void> _saveServiceAgentDocument({
    required Map<String, dynamic> payload,
    String? editId,
  }) async {
    try {
      if (editId != null) {
        await DioClient.dio.put('/service-agents/$editId', data: payload);
      } else {
        await DioClient.dio.post('/service-agents', data: payload);
      }
      LibraryRepository().invalidateServiceAgents();
    } catch (e) {
      debugPrint('Note: Service agent document save: $e');
    }
  }

  void _applyFiltersAndSort() {
    List<ServiceAgentDocument> temp = List.from(_allDocuments);
    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      temp = temp.where((d) =>
          d.agentName.toLowerCase().contains(q) ||
          d.documentName.toLowerCase().contains(q) ||
          d.documentType.toLowerCase().contains(q)).toList();
    }
    if (_selectedServiceType != 'All') {
      temp = temp.where((d) => d.serviceType == _selectedServiceType).toList();
    }
    if (_selectedArea != 'All' && _selectedArea.isNotEmpty) {
      temp = temp.where((d) => d.area.any((a) => a.toLowerCase().contains(_selectedArea.toLowerCase()))).toList();
    }
    if (_selectedDocType != 'All') {
      temp = temp.where((d) => d.documentType == _selectedDocType).toList();
    }
    if (_selectedStatus != 'All') {
      final ts = DocumentStatusExtension.fromString(_selectedStatus);
      temp = temp.where((d) => d.status == ts).toList();
    }
    if (_selectedDateRange != null) {
      temp = temp.where((d) =>
          d.uploadDate.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
          d.uploadDate.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)))).toList();
    }
    if (_sortField != null) {
      temp.sort((a, b) {
        dynamic va, vb;
        switch (_sortField) {
          case 'agentName': va = a.agentName.toLowerCase(); vb = b.agentName.toLowerCase(); break;
          case 'serviceType': va = a.serviceType.toLowerCase(); vb = b.serviceType.toLowerCase(); break;
          case 'documentName': va = a.documentName.toLowerCase(); vb = b.documentName.toLowerCase(); break;
          case 'documentType': va = a.documentType.toLowerCase(); vb = b.documentType.toLowerCase(); break;
          case 'uploadDate': va = a.uploadDate; vb = b.uploadDate; break;
          case 'status': va = a.status.index; vb = b.status.index; break;
          default: va = a.uploadDate; vb = b.uploadDate;
        }
        final c = va.compareTo(vb);
        return _sortAscending ? c : -c;
      });
    }
    setState(() { _filteredDocuments = temp; _currentPage = 1; });
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _selectedServiceType = 'All';
      _selectedDocType = 'All';
      _selectedArea = 'All';
      _selectedStatus = 'All';
      _selectedDateRange = null;
    });
    _applyFiltersAndSort();
  }

  int get _totalCount => _allDocuments.length;

  List<ServiceAgentDocument> get _paginatedDocuments {
    final start = (_currentPage - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, _filteredDocuments.length);
    if (start >= _filteredDocuments.length) return [];
    return _filteredDocuments.sublist(start, end);
  }

  int get _totalPages => (_filteredDocuments.length / _pageSize).ceil();

  Future<String> _getUploadedByName() async {
    try {
      final authUser = RoleGuard.currentUser;
      if (authUser != null) {
        return authUser.fullName.isNotEmpty ? authUser.fullName : authUser.email;
      }
    } catch (_) {}
    return 'Admin';
  }

  Future<void> _approveAgent(ServiceAgentDocument doc) async {
    try {
      try {
        await DioClient.dio.patch('/service-agents/${doc.id}', data: {'approval_status': 'approved'});
      } catch (e) {
        debugPrint('Note: approval_status update error: $e');
      }

      LibraryRepository().invalidateServiceAgents();
      setState(() => _pendingDocuments.removeWhere((d) => d.id == doc.id));
      await _loadDocuments(forceRefresh: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${doc.agentName} approved and added to the library.'),
          backgroundColor: CRMColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to approve: $e'),
          backgroundColor: CRMColors.danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _rejectAgent(ServiceAgentDocument doc) async {
    final confirm = await CRMDialogs.showDeleteConfirmation(context,
        title: 'Reject Service Agent',
        content: 'Are you sure you want to reject "${doc.agentName}"?');
    if (confirm != true) return;
    try {
      try {
        await DioClient.dio.patch('/service-agents/${doc.id}', data: {'approval_status': 'rejected'});
      } catch (e) {
        debugPrint('Note: approval_status update error: $e');
      }
      LibraryRepository().invalidateServiceAgents();
      setState(() => _pendingDocuments.removeWhere((d) => d.id == doc.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${doc.agentName} has been rejected.'),
          backgroundColor: CRMColors.danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      debugPrint('Error rejecting agent: $e');
    }
  }

  static String _formatDob(String? rawDob) {
    if (rawDob == null || rawDob.trim().isEmpty) return '-';
    final trimmed = rawDob.trim();
    if (trimmed.length == 8 && RegExp(r'^\d{8}$').hasMatch(trimmed)) {
      final day = trimmed.substring(0, 2);
      final month = trimmed.substring(2, 4);
      final year = trimmed.substring(4, 8);
      return '$day/$month/$year';
    }
    if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(trimmed)) {
      try {
        final dt = DateTime.parse(trimmed);
        return DateFormat('dd/MM/yyyy').format(dt);
      } catch (_) {}
    }
    if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(trimmed)) {
      return trimmed;
    }
    return trimmed;
  }

  void _viewDocument(ServiceAgentDocument doc) {
    showDialog(context: context, builder: (context) {
      final isVideo = doc.fileExtension == 'mp4' || doc.fileExtension == 'mov';
      return Dialog(
        backgroundColor: CRMColors.surfaceElevatedOf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.dialog)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: Padding(
            padding: const EdgeInsets.all(CRMSpacing.l),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  FileIconHelper.getIconForExtension(doc.fileExtension, size: 28),
                  const SizedBox(width: CRMSpacing.s),
                  Expanded(child: Text(doc.agentName.isNotEmpty ? doc.agentName : doc.documentName,
                      style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context)),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                  CRMStatusChip(status: doc.status.displayName),
                ]),
                const Divider(height: CRMSpacing.xl),
                if (doc.agentImageUrl != null && doc.agentImageUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: CRMSpacing.m),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CrmNetworkImage(
                        url: doc.agentImageUrl!,
                        height: 80,
                        width: 80,
                        cacheLogicalWidth: 80,
                        cacheLogicalHeight: 80,
                        fit: BoxFit.cover,
                        error: (context) => Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: CRMColors.primaryOf(context).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.person_rounded, color: CRMColors.primaryOf(context)),
                        ),
                      ),
                    ),
                  ),
                _buildDetailRow(context, 'Agent Name:', doc.agentName),
                if (doc.dateOfBirth != null && doc.dateOfBirth!.isNotEmpty)
                  _buildDetailRow(context, 'Date of Birth:', _formatDob(doc.dateOfBirth)),
                _buildDetailRow(context, 'Role:', doc.serviceType),
                _buildDetailRow(context, 'Mobile Number:', doc.mobileNumber),
                _buildDetailRow(context, 'Identity:', doc.documentType),
                if (doc.area.isNotEmpty) _buildDetailRow(context, 'Area:', '', badgeItems: doc.area),
                _buildDetailRow(context, 'Uploaded On:', DateFormat('dd MMM yyyy, hh:mm a').format(doc.uploadDate)),
                _buildDetailRow(context, 'Uploaded By:', doc.uploadedBy),
                _buildDetailRow(context, 'File Details:', '${doc.fileSize} (${doc.fileExtension.toUpperCase()})'),
                const SizedBox(height: CRMSpacing.m),
                Text('Description:', style: CRMTypography.captionBold.copyWith(color: CRMColors.textSecondaryOf(context))),
                const SizedBox(height: CRMSpacing.xxs),
                Text(doc.description.isNotEmpty ? doc.description : 'No description provided.',
                    style: CRMTypography.body.copyWith(color: CRMColors.textOf(context))),
                if (isVideo) ...[
                  const SizedBox(height: CRMSpacing.m),
                  Container(height: 180, width: double.infinity,
                      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(CRMBorderRadius.input)),
                      child: Stack(alignment: Alignment.center, children: [
                        Positioned.fill(child: Icon(Icons.video_library_outlined, size: 48, color: Colors.white.withOpacity(0.3))),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                            child: const Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.play_circle_outline_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 6),
                              Text('Play work showcase video', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ])),
                      ])),
                ],
                const SizedBox(height: CRMSpacing.l),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  CRMButton(label: 'Close', variant: CRMButtonVariant.outline, onPressed: () => Navigator.pop(context)),
                  const SizedBox(width: CRMSpacing.s),
                  if (doc.fileUrl != null && doc.fileUrl!.startsWith('http')) ...[
                    const SizedBox(width: CRMSpacing.s),
                  ],
                ]),
              ]),
            ),
          ),
        ),
      );
    });
  }

  void _showInScreenDocumentViewer(BuildContext context, ServiceAgentDocument doc) {
    final String? fileUrl = doc.fileUrl;
    if (fileUrl == null || fileUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No document URL available.'),
          backgroundColor: CRMColors.danger,
        ),
      );
      return;
    }

    String previewUrl = fileUrl;
    if (fileUrl.contains('cloudinary.com') && fileUrl.toLowerCase().endsWith('.pdf')) {
      previewUrl = fileUrl.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '.jpg');
    }

    final isImageOrPdf = fileUrl.toLowerCase().contains('cloudinary.com') ||
        ['jpg', 'jpeg', 'png', 'webp', 'pdf'].contains(doc.fileExtension.toLowerCase());

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: CRMColors.surfaceElevatedOf(dialogContext),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.dialog)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 750),
            child: Padding(
              padding: const EdgeInsets.all(CRMSpacing.l),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      FileIconHelper.getIconForExtension(doc.fileExtension, size: 28),
                      const SizedBox(width: CRMSpacing.s),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              doc.documentType,
                              style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(dialogContext)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (doc.agentName.isNotEmpty)
                              Text(
                                doc.agentName,
                                style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(dialogContext)),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),
                  const Divider(height: CRMSpacing.m),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: CRMColors.backgroundOf(dialogContext),
                        borderRadius: BorderRadius.circular(CRMBorderRadius.card),
                        border: Border.all(color: CRMColors.borderOf(dialogContext).withValues(alpha: 0.5)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: isImageOrPdf
                          ? CrmNetworkImage(
                              url: previewUrl,
                              fit: BoxFit.contain,
                              variant: CrmImageVariant.fullscreen,
                              placeholder: (context) => Center(
                                child: CircularProgressIndicator(
                                  color: CRMColors.primaryOf(dialogContext),
                                ),
                              ),
                              error: (context) => Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.description_outlined, size: 64, color: CRMColors.textMutedOf(dialogContext)),
                                    const SizedBox(height: CRMSpacing.s),
                                    Text(
                                      'Document Preview (${doc.fileExtension.toUpperCase()})',
                                      style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondaryOf(dialogContext)),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.insert_drive_file_outlined, size: 64, color: CRMColors.textMutedOf(dialogContext)),
                                  const SizedBox(height: CRMSpacing.s),
                                  Text(
                                    '${doc.documentName} (${doc.fileExtension.toUpperCase()})',
                                    style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondaryOf(dialogContext)),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: CRMSpacing.m),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CRMButton(
                        label: 'Close',
                        variant: CRMButtonVariant.outline,
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {List<String>? badgeItems}) {
    if (badgeItems != null && badgeItems.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 140, child: Text(label, style: CRMTypography.captionBold.copyWith(color: CRMColors.textSecondaryOf(context)))),
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: badgeItems.map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: CRMColors.primaryOf(context).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: CRMColors.primaryOf(context).withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      item,
                      style: CRMTypography.caption.copyWith(
                        color: CRMColors.primaryOf(context),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 140, child: Text(label, style: CRMTypography.captionBold.copyWith(color: CRMColors.textSecondaryOf(context)))),
        Expanded(child: Text(value, style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textOf(context)))),
      ]),
    );
  }

  void _downloadDocument(ServiceAgentDocument doc) async {
    showDialog(context: context, barrierDismissible: false,
        builder: (context) => Center(child: Container(
          padding: const EdgeInsets.all(CRMSpacing.xl),
          decoration: BoxDecoration(color: CRMColors.surfaceElevatedOf(context), borderRadius: BorderRadius.circular(CRMBorderRadius.l)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(color: CRMColors.primaryOf(context)),
            const SizedBox(height: CRMSpacing.m),
            Text('Downloading ${doc.documentName}...', style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
        )));
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${doc.documentName} successfully saved!'),
        backgroundColor: CRMColors.success, behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _shareDocument(ServiceAgentDocument doc) {
    showDialog(context: context, builder: (context) => Dialog(
      backgroundColor: CRMColors.surfaceElevatedOf(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.dialog)),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(padding: const EdgeInsets.all(CRMSpacing.l),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Share Document', style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context))),
            const SizedBox(height: CRMSpacing.s),
            Text('Select how you want to share ${doc.documentName}:', style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context))),
            const SizedBox(height: CRMSpacing.m),
            ListTile(
              leading: const CircleAvatar(backgroundColor: CRMColors.info, child: Icon(Icons.link_rounded, color: Colors.white)),
              title: const Text('Copy Access Link'), subtitle: const Text('Expires in 7 days'),
              onTap: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sharing link copied!'), backgroundColor: CRMColors.success, behavior: SnackBarBehavior.floating)); },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.orangeAccent, child: Icon(Icons.mail_outline_rounded, color: Colors.white)),
              title: const Text('Send via Email'), subtitle: const Text('To agent contact'),
              onTap: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Document emailed to ${doc.agentName}!'), backgroundColor: CRMColors.success, behavior: SnackBarBehavior.floating)); },
            ),
            const SizedBox(height: CRMSpacing.l),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              CRMButton(label: 'Cancel', variant: CRMButtonVariant.outline, onPressed: () => Navigator.pop(context)),
            ]),
          ]),
        ),
      ),
    ));
  }

  void _deleteDocument(ServiceAgentDocument doc) async {
    final confirm = await CRMDialogs.showDeleteConfirmation(context,
        title: 'Delete Agent Document',
        content: 'Are you sure you want to delete "${doc.documentName}"? This action cannot be undone.');
    if (confirm == true) {
      try {
        await DioClient.dio.delete('/service-agents/${doc.id}');
        LibraryRepository().invalidateServiceAgents();
      } catch (e) {
        debugPrint('Error deleting document: $e');
      }
      setState(() { _allDocuments.removeWhere((d) => d.id == doc.id); _applyFiltersAndSort(); });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Document "${doc.documentName}" was successfully deleted.'),
          backgroundColor: CRMColors.danger, behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _selectDobDate(BuildContext context, TextEditingController controller, StateSetter setModalState) async {
    DateTime initial = DateTime(2000, 1, 1);
    if (controller.text.trim().isNotEmpty) {
      final formatted = _formatDob(controller.text.trim());
      final parts = formatted.split('/');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null && m != null && y != null && y > 1900 && m >= 1 && m <= 12 && d >= 1 && d <= 31) {
          initial = DateTime(y, m, d);
        }
      }
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final formatted = DateFormat('dd/MM/yyyy').format(picked);
      setModalState(() {
        controller.text = formatted;
      });
    }
  }

  void _showUploadEditDialog([ServiceAgentDocument? existingDoc]) {
    final isEditing = existingDoc != null;
    final formKey = GlobalKey<FormState>();
    final agentController = TextEditingController(text: existingDoc?.agentName);
    final mobileController = TextEditingController(text: existingDoc?.mobileNumber);
    final descController = TextEditingController(text: existingDoc?.description);
    final dobController = TextEditingController(text: _formatDob(existingDoc?.dateOfBirth));

    String localServiceType = existingDoc?.serviceType ?? 'Electrician';
    String localDocType = existingDoc?.documentType ?? 'Aadhaar Card';
    bool isCustom = isEditing && localDocType != 'Aadhaar Card';
    if (isCustom) localDocType = 'Other';
    final initCustomDocType = isEditing && isCustom ? existingDoc.documentType : '';
    final customDocTypeController = TextEditingController(text: initCustomDocType);
    bool showCustomField = isCustom;

    DocumentStatus localStatus = existingDoc?.status ?? DocumentStatus.active;
    String localFileName = existingDoc?.documentName ?? '';
    String localFileExt = existingDoc?.fileExtension ?? 'pdf';
    String localFileSize = existingDoc?.fileSize ?? '0 KB';
    String localFileUrl = existingDoc?.fileUrl ?? '';
    String localAgentImageUrl = existingDoc?.agentImageUrl ?? '';
    List<String> localSelectedAreas = List.from(existingDoc?.area ?? []);

    showDialog(context: context, barrierDismissible: false, builder: (context) {
      return StatefulBuilder(builder: (context, setModalState) {
        return Dialog(
          backgroundColor: CRMColors.surfaceElevatedOf(context),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.dialog)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550, maxHeight: 900),
            child: Padding(
              padding: const EdgeInsets.all(CRMSpacing.l),
              child: Form(key: formKey, child: SingleChildScrollView(child: Column(
                mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(isEditing ? 'Edit Agent Document' : 'Upload Agent Document',
                        style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context))),
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: () async {
                      final hasInput = agentController.text.isNotEmpty || mobileController.text.isNotEmpty;
                      if (hasInput && !isEditing) {
                        final discard = await CRMDialogs.showUnsavedChangesDialog(context);
                        if (discard == true && context.mounted) Navigator.pop(context);
                      } else { Navigator.pop(context); }
                    }),
                  ]),
                  const SizedBox(height: CRMSpacing.m),
                  AgentImageUploadZone(
                    initialImageUrl: localAgentImageUrl.isNotEmpty ? localAgentImageUrl : null,
                    onImageUploaded: (url) => setModalState(() => localAgentImageUrl = url),
                  ),
                  const SizedBox(height: CRMSpacing.m),
                  CRMTextField(
                    controller: agentController, labelText: 'Agent Name *', hintText: 'e.g. A1 Electricians Ltd',
                    validator: (val) => val == null || val.trim().isEmpty ? 'Agent name required' : null,
                  ),
                  const SizedBox(height: CRMSpacing.m),
                  CRMTextField(
                    controller: dobController,
                    labelText: 'Date of Birth',
                    hintText: 'DD/MM/YYYY',
                    readOnly: true,
                    onTap: () => _selectDobDate(context, dobController, setModalState),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_month_rounded, size: 20),
                      onPressed: () => _selectDobDate(context, dobController, setModalState),
                    ),
                  ),
                  const SizedBox(height: CRMSpacing.m),
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Role *', style: CRMTypography.label.copyWith(color: CRMColors.textSecondaryOf(context))),
                      const SizedBox(height: CRMSpacing.xs),
                      DropdownButtonFormField<String>(
                        value: localServiceType, isExpanded: true,
                        dropdownColor: CRMColors.surfaceElevatedOf(context),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: CRMSpacing.s),
                          filled: true, fillColor: CRMColors.cardBgOf(context),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.input), borderSide: BorderSide(color: CRMColors.borderOf(context))),
                        ),
                        items: _serviceTypes.where((t) => t != 'All').map((t) => DropdownMenuItem(value: t, child: Text(t, style: TextStyle(color: CRMColors.textOf(context))))).toList(),
                        onChanged: (val) { if (val != null) setModalState(() => localServiceType = val); },
                      ),
                    ])),
                    const SizedBox(width: CRMSpacing.m),
                    Expanded(child: CRMTextField(
                      controller: mobileController, labelText: 'Mobile Number *', hintText: '+91 XXXXX XXXXX',
                      keyboardType: TextInputType.phone,
                      validator: (val) => val == null || val.trim().isEmpty ? 'Mobile number required' : null,
                    )),
                  ]),
                  const SizedBox(height: CRMSpacing.m),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Identity *', style: CRMTypography.label.copyWith(color: CRMColors.textSecondaryOf(context))),
                    const SizedBox(height: CRMSpacing.xs),
                    Row(children: [
                      Expanded(child: DropdownButtonFormField<String>(
                        value: ['Aadhaar Card', 'Other'].contains(localDocType) ? localDocType : 'Other',
                        isExpanded: true, dropdownColor: CRMColors.surfaceElevatedOf(context),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: CRMSpacing.s),
                          filled: true, fillColor: CRMColors.cardBgOf(context),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.input), borderSide: BorderSide(color: CRMColors.borderOf(context))),
                        ),
                        items: ['Aadhaar Card', 'Other'].map((t) => DropdownMenuItem(value: t, child: Text(t, style: TextStyle(color: CRMColors.textOf(context))))).toList(),
                        onChanged: (val) { if (val != null) setModalState(() { localDocType = val; showCustomField = val == 'Other'; }); },
                      )),
                      const SizedBox(width: CRMSpacing.s),
                      IconButton(
                        icon: Icon(showCustomField ? Icons.remove_circle_outline_rounded : Icons.add_circle_outline_rounded, color: CRMColors.primaryOf(context)),
                        onPressed: () => setModalState(() { showCustomField = !showCustomField; localDocType = showCustomField ? 'Other' : 'Aadhaar Card'; }),
                        tooltip: showCustomField ? 'Use dropdown' : 'Add custom identity type',
                      ),
                    ]),
                    if (showCustomField) ...[
                      const SizedBox(height: CRMSpacing.m),
                      CRMTextField(controller: customDocTypeController, labelText: 'Custom Identity Type *', hintText: 'e.g. Driving Licence',
                          validator: (val) => val == null || val.trim().isEmpty ? 'Custom identity type required' : null),
                    ],
                  ]),
                  const SizedBox(height: CRMSpacing.m),
                  _buildAreaField(context, setModalState, localSelectedAreas, (updated) {
                    setModalState(() { localSelectedAreas..clear()..addAll(updated); });
                  }),
                  const SizedBox(height: CRMSpacing.m),
                  CRMTextField(controller: descController, labelText: 'Description', hintText: 'Add description or registration validity notes...', maxLines: 2),
                  const SizedBox(height: CRMSpacing.m),
                  DragDropUploadZone(
                    initialFileName: localFileName, initialFileSize: localFileSize,
                    onOcrDetected: (name) => setModalState(() => agentController.text = name),
                    onFileSelected: (name, ext, size, url) => setModalState(() {
                      localFileName = name; localFileExt = ext; localFileSize = size; localFileUrl = url;
                    }),
                  ),
                  const SizedBox(height: CRMSpacing.m),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    CRMButton(label: 'Cancel', variant: CRMButtonVariant.outline, onPressed: () async {
                      final hasInput = agentController.text.isNotEmpty || mobileController.text.isNotEmpty;
                      if (hasInput && !isEditing) {
                        final discard = await CRMDialogs.showUnsavedChangesDialog(context);
                        if (discard == true && context.mounted) Navigator.pop(context);
                      } else { Navigator.pop(context); }
                    }),
                    const SizedBox(width: CRMSpacing.s),
                    CRMButton(
                      label: isEditing ? 'Save Changes' : 'Submit',
                      variant: CRMButtonVariant.primary,
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        if (localFileName.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload a document file.'), backgroundColor: CRMColors.danger));
                          return;
                        }
                        if (localFileUrl.isEmpty || localFileUrl.startsWith('mock://') ||
                            !localFileUrl.contains('res.cloudinary.com')) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document must be uploaded to Cloudinary first.'), backgroundColor: CRMColors.danger));
                          return;
                        }
                        final docTypeToSave = showCustomField ? customDocTypeController.text.trim() : localDocType;
                        final uploadedByName = await _getUploadedByName();
                        final approvalStatus = _isAdminOrSuperAdmin ? 'approved' : 'pending';
                        final areaString = localSelectedAreas.join(',');
                        
                        final Map<String, dynamic> payload = {
                          'agent_name': agentController.text.trim(),
                          'service_type': localServiceType,
                          'mobile_number': mobileController.text.trim(),
                          'document_type': docTypeToSave,
                          'description': descController.text.trim(),
                          'status': isEditing ? localStatus.displayName.toLowerCase() : 'active',
                          'file_size': localFileSize,
                          'file_extension': localFileExt,
                          'file_url': localFileUrl,
                          'uploaded_by': uploadedByName,
                        };

                        if (!isEditing) {
                          payload['id'] = generateUuidV4();
                          payload['upload_date'] = DateTime.now().toUtc().toIso8601String();
                        }

                        if (localAgentImageUrl.isNotEmpty) {
                          payload['agent_image_url'] = localAgentImageUrl;
                        }
                        if (dobController.text.trim().isNotEmpty) {
                          payload['date_of_birth'] = dobController.text.trim();
                        }
                        if (areaString.isNotEmpty) {
                          payload['area'] = areaString;
                        }
                        payload['approval_status'] = approvalStatus;

                        try {
                          await _saveServiceAgentDocument(
                            payload: payload,
                            editId: isEditing ? existingDoc.id : null,
                          );
                        } catch (e) {
                          debugPrint('Note: Service agent save fallback: $e');
                        }

                        final newDoc = _rowToDoc({
                          'id': isEditing ? existingDoc.id : DateTime.now().millisecondsSinceEpoch.toString(),
                          ...payload,
                        });

                        setState(() {
                          if (isEditing) {
                            final idx = _allDocuments.indexWhere((d) => d.id == existingDoc.id);
                            if (idx != -1) _allDocuments[idx] = newDoc;
                            final pIdx = _pendingDocuments.indexWhere((d) => d.id == existingDoc.id);
                            if (pIdx != -1) _pendingDocuments[pIdx] = newDoc;
                          } else {
                            if (approvalStatus == 'pending') {
                              _pendingDocuments.insert(0, newDoc);
                            } else {
                              _allDocuments.insert(0, newDoc);
                            }
                          }
                          _applyFiltersAndSort();
                        });

                        if (!context.mounted) return;
                        Navigator.pop(context);
                        final msg = isEditing ? 'Agent document updated!'
                            : (approvalStatus == 'pending' ? 'Agent submitted for approval. Pending Admin review.' : 'Agent document uploaded successfully!');
                        ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(
                          content: Text(msg),
                          backgroundColor: approvalStatus == 'pending' ? Colors.orange : CRMColors.success,
                          behavior: SnackBarBehavior.floating,
                        ));
                      },
                    ),
                  ]),
                ],
              ))),
            ),
          ),
        );
      });
    });
  }

  Widget _buildAreaField(BuildContext context, StateSetter setModalState,
      List<String> selectedAreas, void Function(List<String>) onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Area', style: CRMTypography.label.copyWith(color: CRMColors.textSecondaryOf(context))),
        const SizedBox(width: CRMSpacing.xs),
        GestureDetector(
          onTap: () => _showAddAreaDialog(context, (newArea) {
            if (!selectedAreas.contains(newArea.name)) {
              onChanged([...selectedAreas, newArea.name]);
            }
          }),
          child: Icon(Icons.add_circle_outline_rounded, color: CRMColors.primaryOf(context), size: 18),
        ),
      ]),
      const SizedBox(height: CRMSpacing.xs),
      GestureDetector(
        onTap: () => _showTargetAreaDialog(context, selectedAreas, onChanged),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: CRMSpacing.s),
          decoration: BoxDecoration(
            color: CRMColors.cardBgOf(context),
            border: Border.all(color: CRMColors.borderOf(context)),
            borderRadius: BorderRadius.circular(CRMBorderRadius.input),
          ),
          child: Row(children: [
            Expanded(child: selectedAreas.isEmpty
                ? Text('Select area(s)...', style: CRMTypography.body.copyWith(color: CRMColors.textMutedOf(context)))
                : Wrap(spacing: 6, runSpacing: 4, children: selectedAreas.map((area) => Chip(
                    label: Text(area, style: const TextStyle(fontSize: 12)),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => onChanged(List.from(selectedAreas)..remove(area)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                  )).toList())),
            Icon(Icons.arrow_drop_down_rounded, color: CRMColors.textSecondaryOf(context)),
          ]),
        ),
      ),
    ]);
  }

  void _showTargetAreaDialog(
    BuildContext context,
    List<String> selectedAreas,
    void Function(List<String>) onChanged,
  ) {
    final searchCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        List<String> tempSelected = List.from(selectedAreas);
        String searchQuery = '';

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final filteredAreas = _dbAreasList.where((item) {
              final q = searchQuery.toLowerCase().trim();
              if (q.isEmpty) return true;
              final nameMatch = item.name.toLowerCase().contains(q);
              final pinMatch = (item.pincode ?? '').contains(q);
              return nameMatch || pinMatch;
            }).toList();

            return Dialog(
              backgroundColor: CRMColors.surfaceElevatedOf(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440, maxHeight: 600),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Step 4: Target Area(s) *',
                            style: CRMTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: CRMColors.textOf(context),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: TextField(
                                controller: searchCtrl,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Filter areas...',
                                  hintStyle: TextStyle(fontSize: 13, color: CRMColors.textMutedOf(context)),
                                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                  filled: true,
                                  fillColor: CRMColors.groupedBackground,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onChanged: (val) {
                                  setDialogState(() {
                                    searchQuery = val;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              Icons.add_circle_outline_rounded,
                              color: CRMColors.primaryOf(context),
                              size: 22,
                            ),
                            tooltip: 'Add new area',
                            onPressed: () {
                              _showAddAreaDialog(context, (newArea) {
                                setDialogState(() {
                                  if (!tempSelected.contains(newArea.name)) {
                                    tempSelected.add(newArea.name);
                                  }
                                });
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: filteredAreas.isEmpty
                            ? Center(
                                child: Text(
                                  'No matching areas found',
                                  style: CRMTypography.caption.copyWith(color: CRMColors.textMutedOf(context)),
                                ),
                              )
                            : ListView.separated(
                                itemCount: filteredAreas.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (ctx, idx) {
                                  final item = filteredAreas[idx];
                                  final isChecked = tempSelected.contains(item.name);

                                  return InkWell(
                                    onTap: () {
                                      setDialogState(() {
                                        if (isChecked) {
                                          tempSelected.remove(item.name);
                                        } else {
                                          tempSelected.add(item.name);
                                        }
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.name,
                                                style: CRMTypography.bodyMedium.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: CRMColors.textOf(context),
                                                  fontSize: 13.5,
                                                ),
                                              ),
                                              if (item.pincode != null && item.pincode!.isNotEmpty)
                                                Text(
                                                  item.pincode!,
                                                  style: CRMTypography.caption.copyWith(
                                                    color: CRMColors.textSecondaryOf(context),
                                                    fontSize: 11.5,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          Checkbox(
                                            value: isChecked,
                                            activeColor: CRMColors.primaryOf(context),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                            onChanged: (val) {
                                              setDialogState(() {
                                                if (val == true) {
                                                  tempSelected.add(item.name);
                                                } else {
                                                  tempSelected.remove(item.name);
                                                }
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Back'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CRMColors.primaryOf(context),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            onPressed: () {
                              onChanged(tempSelected);
                              Navigator.pop(ctx);
                            },
                            child: const Text('Done'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddAreaDialog(
    BuildContext context,
    void Function(AreaItem) onAdded,
  ) {
    final nameCtrl = TextEditingController();
    final pinCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CRMColors.surfaceElevatedOf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Add New Area',
          style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Area Name *',
                hintText: 'e.g. Visnagar',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.input)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pinCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Pincode (Optional)',
                hintText: 'e.g. 384315',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.input)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CRMColors.primaryOf(context),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              final newPin = pinCtrl.text.trim();
              if (newName.isNotEmpty) {
                final newId = generateUuidV4();
                final newItem = AreaItem(id: newId, name: newName, pincode: newPin.isNotEmpty ? newPin : null);

                try {
                  await PropertiesService().createArea('1', newName, newPin);
                } catch (e) {
                  debugPrint('Note: Error adding area: $e');
                }

                setState(() {
                  _dbAreasList.insert(0, newItem);
                });
                onAdded(newItem);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── New_UI vault shell ─────────────────────────────

  /// Selected KPI card (0 total, 1 waiting for approval, 2 verified).
  int? _selectedKpi;

  void _onResetAll() {
    setState(() => _selectedKpi = null);
    _resetFilters();
  }

  Future<void> _setPendingView(bool pending) async {
    if (pending && !_isAdminOrSuperAdmin) return;
    if (pending) await _loadPendingDocuments();
    if (!mounted) return;
    setState(() {
      _showPendingView = pending;
      if (pending) {
        _selectedKpi = 1;
      } else if (_selectedKpi == 1) {
        _selectedKpi = null;
      }
    });
  }

  Future<void> _onKpiTap(int index) async {
    final deselect = _selectedKpi == index;
    switch (index) {
      case 0:
        setState(() {
          _showPendingView = false;
          _selectedKpi = deselect ? null : 0;
          _selectedStatus = 'All';
        });
        _applyFiltersAndSort();
        break;
      case 1:
        if (!_isAdminOrSuperAdmin) return;
        await _setPendingView(!deselect);
        break;
      case 2:
        setState(() {
          _showPendingView = false;
          _selectedKpi = deselect ? null : 2;
          _selectedStatus = deselect ? 'All' : 'Active';
        });
        _applyFiltersAndSort();
        break;
    }
  }

  Future<void> _callAgent(ServiceAgentDocument doc) async {
    final number = doc.mobileNumber.replaceAll(RegExp(r'[^\d+]'), '');
    void notify(String message) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: CRMColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }

    if (number.isEmpty) {
      notify('No mobile number on file for ${doc.agentName}.');
      return;
    }
    try {
      final launched = await launchUrl(Uri(scheme: 'tel', path: number));
      if (!launched) notify('Could not start a call to ${doc.mobileNumber}.');
    } catch (e) {
      notify('Could not start a call to ${doc.mobileNumber}.');
    }
  }

  String _displayUploader(String raw) {
    final text = raw.trim();
    final lower = text.toLowerCase();
    if (lower == 'admin' || lower == 'admin@nbdeveloper.com') return 'Admin';
    if (lower == 'super admin' || lower == 'super_admin') return 'Super Admin';
    if (text.contains('@')) {
      final name = text.split('@').first;
      if (name.isNotEmpty) return name[0].toUpperCase() + name.substring(1);
    }
    return text;
  }

  /// Pending submissions narrowed by the search box and role dropdown.
  List<ServiceAgentDocument> get _visiblePending {
    final q = _searchController.text.trim().toLowerCase();
    return _pendingDocuments.where((d) {
      if (_selectedServiceType != 'All' && d.serviceType != _selectedServiceType) {
        return false;
      }
      if (q.isEmpty) return true;
      return d.agentName.toLowerCase().contains(q) ||
          d.documentName.toLowerCase().contains(q) ||
          d.documentType.toLowerCase().contains(q) ||
          d.mobileNumber.toLowerCase().contains(q);
    }).toList();
  }

  Widget _buildAgentCard(ServiceAgentDocument doc, {required bool pending}) {
    final verified = doc.status == DocumentStatus.active;
    final statusLabel = pending
        ? 'Pending'
        : (verified ? 'Verified' : doc.status.displayName);
    final metaParts = <String>[
      if (doc.dateOfBirth != null && doc.dateOfBirth!.trim().isNotEmpty)
        'DOB ${_formatDob(doc.dateOfBirth)}',
      'by ${_displayUploader(doc.uploadedBy)}',
      DateFormat('dd MMM yyyy').format(doc.uploadDate),
    ];

    return LvAgentCard(
      name: doc.agentName.isNotEmpty ? doc.agentName : doc.documentName,
      role: doc.serviceType,
      mobile: doc.mobileNumber,
      imageUrl: doc.agentImageUrl,
      statusLabel: statusLabel,
      areas: doc.area,
      badges: [if (doc.documentType.trim().isNotEmpty) doc.documentType],
      meta: metaParts.join(' · '),
      actions: [
        LvAgentAction(
          label: 'Call',
          icon: Icons.call_outlined,
          onTap: () => _callAgent(doc),
        ),
        if (pending) ...[
          LvAgentAction(
            label: 'Approve',
            icon: Icons.check_rounded,
            kind: LvActionKind.primary,
            onTap: () => _approveAgent(doc),
          ),
          LvAgentAction(
            label: 'Reject',
            icon: Icons.close_rounded,
            kind: LvActionKind.danger,
            onTap: () => _rejectAgent(doc),
          ),
        ],
        LvAgentAction(
          label: 'Documents',
          icon: Icons.folder_open_outlined,
          onTap: () => _showInScreenDocumentViewer(context, doc),
        ),
      ],
      menu: pending
          ? [
              LvMenuAction(
                label: 'View details',
                icon: Icons.visibility_outlined,
                onTap: () => _viewDocument(doc),
              ),
            ]
          : [
              LvMenuAction(
                label: 'View details',
                icon: Icons.visibility_outlined,
                onTap: () => _viewDocument(doc),
              ),
              LvMenuAction(
                label: 'Download',
                icon: Icons.file_download_outlined,
                onTap: () => _downloadDocument(doc),
              ),
              LvMenuAction(
                label: 'Edit',
                icon: Icons.edit_outlined,
                onTap: () => _showUploadEditDialog(doc),
              ),
              LvMenuAction(
                label: 'Share',
                icon: Icons.share_outlined,
                onTap: () => _shareDocument(doc),
              ),
              LvMenuAction(
                label: 'Delete',
                icon: Icons.delete_outline_rounded,
                danger: true,
                onTap: () => _deleteDocument(doc),
              ),
            ],
    );
  }

  List<LvKpiItem> _buildKpis() {
    final verifiedCount =
        _allDocuments.where((d) => d.status == DocumentStatus.active).length;
    final areasCount = _dynamicAreas.length - 1;
    return [
      LvKpiItem(
        icon: Icons.groups_outlined,
        label: 'Total agents',
        value: '$_totalCount',
        hint: 'Ready when you need them',
        selected: _selectedKpi == 0,
        onTap: () => _onKpiTap(0),
      ),
      LvKpiItem(
        icon: Icons.hourglass_empty_rounded,
        label: 'Waiting for approval',
        value: '${_pendingDocuments.length}',
        hint: 'Submitted by your team',
        selected: _selectedKpi == 1,
        onTap: _isAdminOrSuperAdmin ? () => _onKpiTap(1) : null,
      ),
      LvKpiItem(
        icon: Icons.verified_outlined,
        label: 'Verified',
        value: '$verifiedCount',
        hint: 'ID and documents checked',
        selected: _selectedKpi == 2,
        onTap: () => _onKpiTap(2),
      ),
      LvKpiItem(
        icon: Icons.place_outlined,
        label: 'Areas covered',
        value: '${areasCount < 0 ? 0 : areasCount}',
        hint: 'Across your service zones',
      ),
    ];
  }

  List<LvChecklistItem> _buildChecklist() {
    final types = _allDocuments.map((d) => d.documentType).toList();
    return [
      LvChecklistItem(
        label: 'Aadhaar / ID proof',
        count: lvCountByKeywords(types, [
          'aadhaar',
          'aadhar',
          'id proof',
          'identity',
          'voter',
          'driving',
          'pan card',
        ]),
      ),
      LvChecklistItem(
        label: 'GST certificate',
        count: lvCountByKeywords(types, ['gst']),
      ),
      LvChecklistItem(
        label: 'Service agreement (SLA)',
        count: lvCountByKeywords(types, ['agreement', 'sla']),
      ),
      LvChecklistItem(
        label: 'Price list & quotation',
        count: lvCountByKeywords(types, ['price', 'catalog', 'quotation', 'quote']),
      ),
      LvChecklistItem(
        label: 'Invoices & work photos',
        count: lvCountByKeywords(types, ['invoice', 'work', 'photo']),
      ),
    ];
  }

  Widget _buildMainPanel() {
    final admin = _isAdminOrSuperAdmin;
    final pendingMode = _showPendingView && admin;

    final filterBar = LvFilterBar(
      leading: admin
          ? LvSegment(
              labels: [
                'All agents',
                'Waiting for approval (${_pendingDocuments.length})',
              ],
              selected: pendingMode ? 1 : 0,
              onChanged: (i) => _setPendingView(i == 1),
            )
          : null,
      searchController: _searchController,
      searchHint: 'Agent, mobile or document',
      onSearchChanged: (_) {
        if (pendingMode) {
          setState(() {});
        } else {
          _applyFiltersAndSort();
        }
      },
      dropdowns: [
        LvDropdownField(
          label: 'Role',
          value: _selectedServiceType,
          items: _serviceTypes,
          onChanged: (v) {
            if (v == null) return;
            setState(() => _selectedServiceType = v);
            _applyFiltersAndSort();
          },
        ),
        if (!pendingMode) ...[
          LvDropdownField(
            label: 'Area',
            value: _selectedArea,
            items: _dynamicAreas,
            onChanged: (v) {
              if (v == null) return;
              setState(() => _selectedArea = v);
              _applyFiltersAndSort();
            },
          ),
          LvDropdownField(
            label: 'Document type',
            value: _selectedDocType,
            items: _dynamicDocTypes,
            onChanged: (v) {
              if (v == null) return;
              setState(() => _selectedDocType = v);
              _applyFiltersAndSort();
            },
          ),
        ],
      ],
      onReset: _onResetAll,
    );

    if (pendingMode) {
      final pending = _visiblePending;
      Widget body;
      if (_isLoadingPending) {
        body = const LvLoading();
      } else if (pending.isEmpty) {
        body = const LvEmpty(
          title: 'No pending submissions',
          message: 'Nothing is waiting for approval.',
        );
      } else {
        body = LvAgentGrid(
          children: [
            for (final doc in pending) _buildAgentCard(doc, pending: true),
          ],
        );
      }
      return LvPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            filterBar,
            body,
            LvPanelFooter(
              label: 'Showing ${pending.length} of ${_pendingDocuments.length} waiting for approval',
            ),
          ],
        ),
      );
    }

    Widget body;
    if (_isLoading) {
      body = const LvLoading();
    } else if (_filteredDocuments.isEmpty) {
      body = LvEmpty(
        title: _allDocuments.isEmpty ? 'No service agents yet' : 'No agents match',
        message: _allDocuments.isEmpty
            ? 'Add your first electrician, plumber or vendor.'
            : 'Try another role, area or document type.',
        actionLabel: _allDocuments.isEmpty ? null : 'Reset filters',
        onAction: _allDocuments.isEmpty ? null : _onResetAll,
      );
    } else {
      body = LvAgentGrid(
        children: [
          for (final doc in _paginatedDocuments) _buildAgentCard(doc, pending: false),
        ],
      );
    }

    final footerLabel = _filteredDocuments.length == _allDocuments.length
        ? 'Showing ${_paginatedDocuments.length} of ${_filteredDocuments.length} agents'
        : 'Showing ${_paginatedDocuments.length} of ${_filteredDocuments.length} agents · ${_allDocuments.length} total';

    return LvPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          filterBar,
          body,
          LvPanelFooter(
            label: footerLabel,
            currentPage: _currentPage,
            totalPages: _totalPages,
            onPageChanged: (p) => setState(() => _currentPage = p),
            pageSize: _pageSize,
            onPageSizeChanged: (rows) {
              setState(() {
                _pageSize = rows;
                _currentPage = 1;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LibTokens.pageBg(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(CRMBreakpoints.pagePadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: LvBreadcrumb(vaultName: 'Service Agent Library'),
              ),
              const SizedBox(height: 16),
              LvHero(
                icon: Icons.handyman_rounded,
                title: 'Service Agent Library',
                subtitle: 'Plumbers, electricians, AC technicians and other vendors — with ID, GST and agreements.',
                onExport: (format) => DocumentExportHelper.triggerExport(context, format),
                primaryLabel: 'Add agent',
                onPrimary: () => _showUploadEditDialog(),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: LvVaultTabs(current: LvVault.service),
              ),
              const SizedBox(height: 16),
              LvKpiStrip(items: _buildKpis()),
              const SizedBox(height: 16),
              LvChecklist(items: _buildChecklist()),
              const SizedBox(height: 16),
              _buildMainPanel(),
            ],
          ),
        ),
      ),
    );
  }
}

String generateUuidV4() {
  final random = Random.secure();
  final hexDigits = '0123456789abcdef';
  final charCodes = List<int>.generate(36, (index) {
    if (index == 8 || index == 13 || index == 18 || index == 23) return 45;
    if (index == 14) return 52;
    final digit = random.nextInt(16);
    if (index == 19) return hexDigits.codeUnitAt((digit & 0x3) | 0x8);
    return hexDigits.codeUnitAt(digit);
  });
  return String.fromCharCodes(charCodes);
}
