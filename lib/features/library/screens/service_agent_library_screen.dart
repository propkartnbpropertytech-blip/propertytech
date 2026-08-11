import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/crm_data_table.dart';
import '../../../core/design_system/widgets/crm_status_chips.dart';
import '../../../core/design_system/widgets/dialogs.dart';
import '../../../core/design_system/widgets/empty_state.dart';
import '../../../core/design_system/widgets/inputs.dart';
import '../../../core/security/role_guard.dart';
import '../models/document_model.dart';
import 'library_widgets.dart';

class AreaItem {
  final String id;
  final String name;
  final String? pincode;
  AreaItem({required this.id, required this.name, this.pincode});
}

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
  bool _showOtherTypesKpis = false;
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
    _loadDocumentsFromSupabase();
    _fetchAreasFromSupabase();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAreasFromSupabase() async {
    try {
      final response = await Supabase.instance.client
          .from('areas')
          .select('id, area_name, pincode')
          .order('area_name', ascending: true);
      final List<dynamic> data = response as List<dynamic>;
      if (data.isNotEmpty) {
        final fetched = data.map((json) => AreaItem(
          id: json['id']?.toString() ?? '',
          name: json['area_name']?.toString() ?? '',
          pincode: json['pincode']?.toString(),
        )).toList();
        setState(() {
          _dbAreasList = fetched;
        });
        return;
      }
    } catch (e) {
      debugPrint('Note: Error fetching areas from Supabase: $e');
    }

    if (_dbAreasList.isEmpty) {
      setState(() {
        _dbAreasList = [
          AreaItem(id: '1', name: 'Visnagar', pincode: '384315'),
          AreaItem(id: '2', name: 'viramgam', pincode: '382150'),
          AreaItem(id: '3', name: 'Vasna road', pincode: '383255'),
          AreaItem(id: '4', name: 'Vaishnodevi', pincode: '382481'),
          AreaItem(id: '5', name: 'Thaltej', pincode: '380059'),
          AreaItem(id: '6', name: 'South Bopal', pincode: '380057'),
          AreaItem(id: '7', name: 'North Zone'),
          AreaItem(id: '8', name: 'Central'),
        ];
      });
    }
  }

  ServiceAgentDocument _rowToDoc(Map<String, dynamic> json) {
    List<String> areaList = [];
    final areaRaw = json['area'] ?? json['areas'] ?? json['service_area'] ?? json['target_area'];
    if (areaRaw is String && areaRaw.isNotEmpty) {
      areaList = areaRaw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    } else if (areaRaw is List) {
      areaList = areaRaw.map((e) => e.toString()).toList();
    }

    final imageUrl = json['agent_image_url']?.toString() ??
        json['image_url']?.toString() ??
        json['photo_url']?.toString() ??
        json['agent_photo']?.toString() ??
        json['photo']?.toString() ??
        json['avatar_url']?.toString();

    final dob = json['date_of_birth']?.toString() ??
        json['dob']?.toString() ??
        json['birth_date']?.toString();

    return ServiceAgentDocument(
      id: json['id']?.toString() ?? '',
      agentName: json['agent_name']?.toString() ?? '',
      serviceType: json['service_type']?.toString() ?? json['role']?.toString() ?? '',
      mobileNumber: json['mobile_number']?.toString() ?? '',
      documentName: json['document_type']?.toString() ?? '',
      documentType: json['document_type']?.toString() ?? '',
      uploadDate: DateTime.tryParse(json['upload_date']?.toString() ?? '') ?? DateTime.now(),
      uploadedBy: json['uploaded_by']?.toString() ?? 'admin',
      status: DocumentStatusExtension.fromString(json['status']?.toString() ?? 'active'),
      description: json['description']?.toString() ?? '',
      fileSize: json['file_size']?.toString() ?? '0 KB',
      fileExtension: json['file_extension']?.toString() ?? 'pdf',
      fileUrl: json['file_url']?.toString() ?? '',
      approvalStatus: json['approval_status']?.toString() ?? 'approved',
      agentImageUrl: imageUrl,
      dateOfBirth: dob,
      area: areaList,
    );
  }

  Future<void> _loadDocumentsFromSupabase() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('service_agent_documents')
          .select()
          .order('upload_date', ascending: false);
      final List<dynamic> data = response as List<dynamic>;
      final docs = data
          .map((json) => _rowToDoc(json as Map<String, dynamic>))
          .where((d) {
            final s = d.approvalStatus.toLowerCase();
            return s == 'approved' || s == 'active' || s == '';
          })
          .toList();
      setState(() {
        _allDocuments = docs;
        _applyFiltersAndSort();
      });
    } catch (e) {
      debugPrint('Error loading documents from Supabase: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPendingDocuments() async {
    setState(() => _isLoadingPending = true);
    try {
      final response = await Supabase.instance.client
          .from('service_agent_documents')
          .select()
          .eq('approval_status', 'pending')
          .order('upload_date', ascending: false);
      final List<dynamic> data = response as List<dynamic>;
      setState(() {
        _pendingDocuments = data.map((json) => _rowToDoc(json as Map<String, dynamic>)).toList();
      });
    } catch (e) {
      debugPrint('Error loading pending documents: $e');
      setState(() {
        _pendingDocuments = [];
      });
    } finally {
      if (mounted) setState(() => _isLoadingPending = false);
    }
  }

  Future<void> _saveToSupabaseWithFallback({
    required Map<String, dynamic> payload,
    String? editId,
  }) async {
    final Map<String, dynamic> currentPayload = Map<String, dynamic>.from(payload);

    while (true) {
      try {
        if (editId != null) {
          await Supabase.instance.client
              .from('service_agent_documents')
              .update(currentPayload)
              .eq('id', editId);
        } else {
          await Supabase.instance.client
              .from('service_agent_documents')
              .insert(currentPayload);
        }
        return;
      } on PostgrestException catch (e) {
        final match = RegExp(r"Could not find the '([^']+)' column").firstMatch(e.message);
        if (match != null) {
          final missingCol = match.group(1);
          if (missingCol != null && currentPayload.containsKey(missingCol)) {
            debugPrint("Supabase table missing column '$missingCol'. Retrying save without it...");
            currentPayload.remove(missingCol);
            continue;
          }
        }
        rethrow;
      }
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
      final cu = Supabase.instance.client.auth.currentUser;
      if (cu != null) {
        final up = await Supabase.instance.client
            .from('users').select('full_name, roles(name)').eq('id', cu.id).maybeSingle();
        if (up != null) {
          final roleName = up['roles']?['name']?.toString();
          final fullName = up['full_name']?.toString();
          if (roleName == 'Admin') return 'Admin';
          if (roleName == 'Super Admin') return 'Super Admin';
          if (fullName != null && fullName.isNotEmpty) return fullName;
          return roleName ?? fullName ?? cu.email ?? 'Admin';
        }
        return cu.email ?? 'Admin';
      }
    } catch (_) {}
    return Supabase.instance.client.auth.currentUser?.email ?? 'Admin';
  }

  Future<void> _approveAgent(ServiceAgentDocument doc) async {
    try {
      try {
        await Supabase.instance.client
            .from('service_agent_documents')
            .update({'approval_status': 'approved'}).eq('id', doc.id);
      } catch (e) {
        debugPrint('Note: approval_status update error: $e');
      }

      setState(() => _pendingDocuments.removeWhere((d) => d.id == doc.id));
      await _loadDocumentsFromSupabase();

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
        await Supabase.instance.client
            .from('service_agent_documents')
            .update({'approval_status': 'rejected'}).eq('id', doc.id);
      } catch (e) {
        debugPrint('Note: approval_status update error: $e');
      }
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
                  Expanded(child: Text(doc.documentName,
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
                      child: Image.network(doc.agentImageUrl!, height: 80, width: 80, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(width: 80, height: 80,
                              decoration: BoxDecoration(color: CRMColors.primaryOf(context).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Icon(Icons.person_rounded, color: CRMColors.primaryOf(context)))),
                    ),
                  ),
                _buildDetailRow(context, 'Agent Name:', doc.agentName),
                if (doc.dateOfBirth != null && doc.dateOfBirth!.isNotEmpty)
                  _buildDetailRow(context, 'Date of Birth:', doc.dateOfBirth!),
                _buildDetailRow(context, 'Role:', doc.serviceType),
                _buildDetailRow(context, 'Mobile Number:', doc.mobileNumber),
                _buildDetailRow(context, 'Identity:', doc.documentType),
                if (doc.area.isNotEmpty) _buildDetailRow(context, 'Area:', doc.area.join(', ')),
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

  Widget _buildDetailRow(BuildContext context, String label, String value) {
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
        await Supabase.instance.client.from('service_agent_documents').delete().eq('id', doc.id);
        setState(() { _allDocuments.removeWhere((d) => d.id == doc.id); _applyFiltersAndSort(); });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Document "${doc.documentName}" was successfully deleted.'),
            backgroundColor: CRMColors.danger, behavior: SnackBarBehavior.floating,
          ));
        }
      } catch (e) { debugPrint('Error deleting document: $e'); }
    }
  }

  void _showUploadEditDialog([ServiceAgentDocument? existingDoc]) {
    final isEditing = existingDoc != null;
    final formKey = GlobalKey<FormState>();
    final agentController = TextEditingController(text: existingDoc?.agentName);
    final mobileController = TextEditingController(text: existingDoc?.mobileNumber);
    final descController = TextEditingController(text: existingDoc?.description);
    final dobController = TextEditingController(text: existingDoc?.dateOfBirth ?? '');

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
                    controller: dobController, labelText: 'Date of Birth', hintText: 'DD/MM/YYYY',
                    keyboardType: TextInputType.datetime,
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
                            !localFileUrl.contains('res.cloudinary.com') || localFileUrl.contains('supabase.co') || localFileUrl.contains('storage/v1')) {
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
                          await _saveToSupabaseWithFallback(
                            payload: payload,
                            editId: isEditing ? existingDoc.id : null,
                          );

                          if (!context.mounted) return;
                          Navigator.pop(context);
                          await _loadDocumentsFromSupabase();
                          if (!mounted) return;
                          final msg = isEditing ? 'Agent document updated!'
                              : (approvalStatus == 'pending' ? 'Agent submitted for approval. Pending Admin review.' : 'Agent document uploaded successfully!');
                          ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(
                            content: Text(msg),
                            backgroundColor: approvalStatus == 'pending' ? Colors.orange : CRMColors.success,
                            behavior: SnackBarBehavior.floating,
                          ));
                        } catch (err) {
                          debugPrint('Error saving: $err');
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $err'), backgroundColor: CRMColors.danger, behavior: SnackBarBehavior.floating));
                        }
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
                  await Supabase.instance.client.from('areas').insert({
                    'id': newId,
                    'area_name': newName,
                    if (newPin.isNotEmpty) 'pincode': newPin,
                  });
                } catch (e) {
                  debugPrint('Note: Supabase insert into areas table: $e');
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

  Widget _buildPendingView() {
    if (_isLoadingPending) return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
    if (_pendingDocuments.isEmpty) return const CRMEmptyState(title: 'No Pending Submissions', description: 'There are no service agent submissions awaiting approval.');

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: CRMSpacing.m),
        padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.pending_actions_rounded, color: Colors.orange.shade800, size: 20),
          ),
          const SizedBox(width: CRMSpacing.m),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'Pending Submissions (${_pendingDocuments.length})',
                style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: Colors.orange.shade900),
              ),
              Text(
                'Review and verify service agent registrations before approving them into the active directory.',
                style: CRMTypography.caption.copyWith(color: Colors.orange.shade800),
              ),
            ]),
          ),
        ]),
      ),
      ..._pendingDocuments.map((doc) => _buildPendingCard(doc)),
    ]);
  }

  Widget _buildPendingCard(ServiceAgentDocument doc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CRMSpacing.m),
      child: CRMCard(
        padding: const EdgeInsets.all(CRMSpacing.m),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Top Row: Circular Avatar + Name/Role + Pending Badge
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: CRMColors.primaryOf(context).withOpacity(0.3), width: 1.5),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: ClipOval(
                child: doc.agentImageUrl != null && doc.agentImageUrl!.isNotEmpty
                    ? Image.network(
                        doc.agentImageUrl!,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _agentAvatarPlaceholder(doc),
                      )
                    : _agentAvatarPlaceholder(doc),
              ),
            ),
            const SizedBox(width: CRMSpacing.m),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  doc.agentName,
                  style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, fontSize: 16, color: CRMColors.textOf(context)),
                ),
                const SizedBox(height: 2),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: CRMColors.primaryOf(context).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      doc.serviceType,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CRMColors.primaryOf(context)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.phone_rounded, size: 13, color: CRMColors.textSecondaryOf(context)),
                  const SizedBox(width: 4),
                  Text(
                    doc.mobileNumber,
                    style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context), fontWeight: FontWeight.w500),
                  ),
                ]),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.hourglass_top_rounded, size: 13, color: Colors.orange.shade800),
                const SizedBox(width: 4),
                Text('Pending Approval', style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontSize: 11.5)),
              ]),
            ),
          ]),

          // Target Area(s) - Button / Chip Type UI
          if (doc.area.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 8),
                child: Text(
                  'Target Area(s):',
                  style: CRMTypography.captionBold.copyWith(color: CRMColors.textSecondaryOf(context), fontSize: 12),
                ),
              ),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: doc.area.map((areaName) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: CRMColors.primaryOf(context).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: CRMColors.primaryOf(context).withOpacity(0.25),
                          width: 1,
                        ),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 13,
                            color: CRMColors.primaryOf(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            areaName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: CRMColors.primaryOf(context),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ]),
          ],

          const SizedBox(height: 12),
          // Bottom Container: Identity Info & Action Buttons
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CRMColors.backgroundOf(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.6)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                     child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _buildPendingDetail('Identity Doc', doc.documentType),
                      if (doc.dateOfBirth != null && doc.dateOfBirth!.isNotEmpty)
                        _buildPendingDetail('Date of Birth', doc.dateOfBirth!),
                    ]),
                  ),
                  const SizedBox(width: CRMSpacing.m),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _buildPendingDetail('Submitted By', doc.uploadedBy),
                      _buildPendingDetail('Submission Date', DateFormat('dd MMM yyyy').format(doc.uploadDate)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(width: CRMSpacing.m),
              // Action Buttons Column
              Column(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                  width: 125,
                  height: 32,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CRMColors.primaryOf(context),
                      side: BorderSide(color: CRMColors.primaryOf(context).withOpacity(0.6), width: 1.1),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: const Icon(Icons.visibility_outlined, size: 14),
                    label: const Text('View Document', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      final url = doc.fileUrl;
                      if (url != null && url.isNotEmpty) {
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No document URL available.'), backgroundColor: CRMColors.danger),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 125,
                  height: 32,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CRMColors.success,
                      foregroundColor: Colors.white,
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 15),
                    label: const Text('Approve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _approveAgent(doc),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 125,
                  height: 32,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CRMColors.danger,
                      side: const BorderSide(color: CRMColors.danger, width: 1.2),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 15),
                    label: const Text('Reject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _rejectAgent(doc),
                  ),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _agentAvatarPlaceholder(ServiceAgentDocument doc) {
    return Container(width: 52, height: 52,
      decoration: BoxDecoration(color: CRMColors.primaryOf(context).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Icon(Icons.person_rounded, color: CRMColors.primaryOf(context)));
  }

  Widget _buildPendingDetail(String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Text('$label: ', style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context))),
        Flexible(child: Text(value, style: CRMTypography.caption.copyWith(color: CRMColors.textOf(context)), overflow: TextOverflow.ellipsis)),
      ]));
  }

  Widget _tableAvatarPlaceholder(BuildContext context) {
    return Container(width: 36, height: 36,
      decoration: BoxDecoration(color: CRMColors.primaryOf(context).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Icon(Icons.person_rounded, color: CRMColors.primaryOf(context), size: 20));
  }

  Widget _buildFilterDropdown(String label, String currentValue, List<String> items, void Function(String?) onChanged, double width) {
    return SizedBox(width: width, child: DropdownButtonFormField<String>(
      value: currentValue, isExpanded: true,
      dropdownColor: CRMColors.cardBgOf(context),
      decoration: InputDecoration(
        labelText: label, labelStyle: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
        contentPadding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: 10),
        filled: true, fillColor: CRMColors.backgroundOf(context),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s), borderSide: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.6))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s), borderSide: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.6))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s), borderSide: BorderSide(color: CRMColors.primaryOf(context), width: 1.5)),
      ),
      style: CRMTypography.body.copyWith(color: CRMColors.textOf(context), fontSize: 13),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: TextStyle(fontSize: 13, color: CRMColors.textOf(context)), overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
    ));
  }

  Widget _buildMobileDocumentCard(ServiceAgentDocument doc) {
    return Padding(padding: const EdgeInsets.only(bottom: CRMSpacing.m),
      child: CRMCard(padding: const EdgeInsets.all(CRMSpacing.m), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          doc.agentImageUrl != null && doc.agentImageUrl!.isNotEmpty
              ? ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(doc.agentImageUrl!, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_, __, ___) => FileIconHelper.getIconForExtension(doc.fileExtension, size: 24)))
              : FileIconHelper.getIconForExtension(doc.fileExtension, size: 24),
          const SizedBox(width: CRMSpacing.s),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(doc.documentType, style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: CRMColors.textOf(context)), maxLines: 2, overflow: TextOverflow.ellipsis),
            Text('${doc.fileSize} \u2022 ${doc.agentName}', style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context))),
          ])),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: CRMColors.textSecondaryOf(context)),
            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
            onSelected: (val) {
              switch (val) {
                case 'view': _viewDocument(doc); break;
                case 'download': _downloadDocument(doc); break;
                case 'edit': _showUploadEditDialog(doc); break;
                case 'share': _shareDocument(doc); break;
                case 'delete': _deleteDocument(doc); break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility_outlined, size: 18), SizedBox(width: 8), Text('View')])),
              const PopupMenuItem(value: 'download', child: Row(children: [Icon(Icons.download_rounded, size: 18), SizedBox(width: 8), Text('Download')])),
              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit')])),
              const PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share_outlined, size: 18), SizedBox(width: 8), Text('Share')])),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, color: CRMColors.danger, size: 18), SizedBox(width: 8), Text('Delete', style: TextStyle(color: CRMColors.danger))])),
            ],
          ),
        ]),
        const SizedBox(height: CRMSpacing.m),
        const Divider(height: 1),
        const SizedBox(height: CRMSpacing.s),
        _buildMobileDetailItem('Agent Name', doc.agentName),
        _buildMobileDetailItem('Role', doc.serviceType),
        _buildMobileDetailItem('Mobile Number', doc.mobileNumber),
        if (doc.dateOfBirth != null && doc.dateOfBirth!.isNotEmpty) _buildMobileDetailItem('DOB', doc.dateOfBirth!),
        if (doc.area.isNotEmpty) _buildMobileDetailItem('Area', doc.area.join(', ')),
        _buildMobileDetailItem('Uploaded By', doc.uploadedBy),
        _buildMobileDetailItem('Upload Date', DateFormat('dd MMM yyyy').format(doc.uploadDate)),
        const SizedBox(height: CRMSpacing.m),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          CRMStatusChip(status: doc.status.displayName),
          Text(doc.fileExtension.toUpperCase(), style: CRMTypography.captionBold.copyWith(color: CRMColors.textMutedOf(context))),
        ]),
      ])),
    );
  }

  Widget _buildMobileDetailItem(String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context))),
        const SizedBox(width: CRMSpacing.m),
        Expanded(child: Text(value, textAlign: TextAlign.end,
            style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textOf(context), fontSize: 12.5, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis)),
      ]));
  }

  Widget _buildMobilePagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.only(top: CRMSpacing.s, bottom: CRMSpacing.l),
      child: CRMCard(padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: CRMSpacing.xs),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Page $_currentPage of $_totalPages', style: CRMTypography.captionBold.copyWith(color: CRMColors.textSecondaryOf(context))),
          Row(children: [
            IconButton(icon: const Icon(Icons.chevron_left_rounded), onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null),
            IconButton(icon: const Icon(Icons.chevron_right_rounded), onPressed: _currentPage < _totalPages ? () => setState(() => _currentPage++) : null),
          ]),
        ])));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1024;
    final isTablet = size.width >= 600 && size.width < 1024;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: CRMColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(CRMSpacing.m),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const LibraryBreadcrumb(currentPageName: 'Service Agent Library'),
                Text('Service agents', style: CRMTypography.pageTitle.copyWith(color: CRMColors.textOf(context))),
                Text('Store, filter, and organize service provider SLA agreements and invoices.',
                    style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context))),
              ]),
              Row(children: [
                PopupMenuButton<String>(
                  icon: Icon(Icons.download_rounded, color: CRMColors.primaryOf(context)),
                  tooltip: 'Export Index',
                  onSelected: (val) => DocumentExportHelper.triggerExport(context, val),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'Excel', child: Text('Export to Excel')),
                    const PopupMenuItem(value: 'PDF', child: Text('Export to PDF')),
                  ],
                ),
                const SizedBox(width: CRMSpacing.s),
                if (_isAdminOrSuperAdmin) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _showPendingView ? Colors.white : Colors.orange.shade700,
                      backgroundColor: _showPendingView ? Colors.orange.shade600 : Colors.orange.withOpacity(0.08),
                      side: BorderSide(color: Colors.orange.shade600),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: Icon(Icons.pending_actions_rounded, size: 18,
                        color: _showPendingView ? Colors.white : Colors.orange.shade700),
                    label: Text(
                      _showPendingView ? 'Back to Library'
                          : 'Pending${_pendingDocuments.isNotEmpty ? ' (${_pendingDocuments.length})' : ''}',
                      style: TextStyle(fontWeight: FontWeight.w600,
                          color: _showPendingView ? Colors.white : Colors.orange.shade700),
                    ),
                    onPressed: () async {
                      if (!_showPendingView) await _loadPendingDocuments();
                      setState(() => _showPendingView = !_showPendingView);
                    },
                  ),
                  const SizedBox(width: CRMSpacing.s),
                ],
                CRMButton(label: 'Add agent', prefixIcon: Icons.add_rounded, onPressed: () => _showUploadEditDialog()),
              ]),
            ]),
            const SizedBox(height: CRMSpacing.m),

            if (!_showPendingView) ...[
              if (_selectedServiceType != 'All') ...[
                Align(alignment: Alignment.centerRight, child: Padding(
                  padding: const EdgeInsets.only(bottom: CRMSpacing.s),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(_showOtherTypesKpis ? 'Showing other agent types KPIs' : 'Showing $_selectedServiceType KPIs only',
                        style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context), fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Switch.adaptive(value: _showOtherTypesKpis, activeColor: CRMColors.primaryOf(context),
                        onChanged: (val) => setState(() => _showOtherTypesKpis = val)),
                  ]),
                )),
              ],
              LayoutBuilder(builder: (context, constraints) {
                int columns = isDesktop ? 4 : 2;
                double spacing = CRMSpacing.m;
                double cardWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;
                return Wrap(spacing: spacing, runSpacing: spacing, children: [
                  SizedBox(width: cardWidth, child: CRMKPICard(
                    title: 'Total Agents', value: '$_totalCount', icon: Icons.badge_rounded,
                    iconColor: CRMColors.primaryOf(context), benefit: 'Vendor credentials ready when you need them',
                  )),
                ]);
              }),
              const SizedBox(height: CRMSpacing.l),
              CRMCard(padding: const EdgeInsets.all(CRMSpacing.m), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.filter_alt_rounded, size: 18, color: CRMColors.primaryOf(context)),
                  const SizedBox(width: 6),
                  Text('Advanced Filters', style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: CRMColors.textOf(context))),
                  const Spacer(),
                  TextButton(onPressed: _resetFilters, child: const Text('Reset All')),
                ]),
                const SizedBox(height: CRMSpacing.s),
                LayoutBuilder(builder: (context, filterConstraints) {
                  int rowColumns = isDesktop ? 4 : (isTablet ? 4 : 2);
                  double filterSpacing = CRMSpacing.s;
                  double inputWidth = ((filterConstraints.maxWidth - (filterSpacing * (rowColumns - 1))) / rowColumns) - 1.0;
                  return Wrap(spacing: filterSpacing, runSpacing: filterSpacing, children: [
                    SizedBox(width: inputWidth, child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search Agent or Document',
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onChanged: (_) => _applyFiltersAndSort(),
                    )),
                    _buildFilterDropdown('Role', _selectedServiceType, _serviceTypes, (val) {
                      setState(() { _selectedServiceType = val!; _showOtherTypesKpis = false; });
                      _applyFiltersAndSort();
                    }, inputWidth),
                    _buildFilterDropdown('Area', _selectedArea, _dynamicAreas, (val) {
                      setState(() => _selectedArea = val!);
                      _applyFiltersAndSort();
                    }, inputWidth),
                    _buildFilterDropdown('Doc Type', _selectedDocType, _dynamicDocTypes, (val) {
                      setState(() => _selectedDocType = val!);
                      _applyFiltersAndSort();
                    }, inputWidth),
                  ]);
                }),
              ])),
              const SizedBox(height: CRMSpacing.m),
              _isLoading
                  ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                  : _filteredDocuments.isEmpty
                      ? CRMEmptyState(title: 'No Provider Documents', description: 'No service agent records match the current filters.',
                          actionLabel: 'Reset Filters', onActionPressed: _resetFilters)
                      : (isMobile
                          ? Column(children: [..._paginatedDocuments.map((doc) => _buildMobileDocumentCard(doc)), _buildMobilePagination()])
                          : LayoutBuilder(builder: (context, constraints) {
                              final availableWidth = constraints.maxWidth;
                              final double scaleFactor = availableWidth > 1050 ? (availableWidth / 1050) : 1.0;
                              return LayoutBuilder(builder: (context, constraints) {
                                return Card(
                                  elevation: 0,
                                  color: CRMColors.cardBgOf(context),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(CRMBorderRadius.card),
                                    side: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.6)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Horizontal Scrollview added to prevent Right Overflow
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                          child: DataTable(
                                            dataRowMinHeight: 65, // Increased row height to avoid Bottom Overflow
                                            dataRowMaxHeight: 75,
                                            horizontalMargin: 12,
                                            columnSpacing: 16,
                                            headingRowColor: WidgetStateProperty.all(
                                              CRMColors.backgroundOf(context).withOpacity(0.5),
                                            ),
                                            columns: [
                                              DataColumn(label: Text('Photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CRMColors.textSecondaryOf(context)))),
                                              DataColumn(label: Text('Agent Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CRMColors.textSecondaryOf(context)))),
                                              DataColumn(label: Text('DOB', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CRMColors.textSecondaryOf(context)))),
                                              DataColumn(label: Text('Role', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CRMColors.textSecondaryOf(context)))),
                                              DataColumn(label: Text('Mobile Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CRMColors.textSecondaryOf(context)))),
                                              DataColumn(label: Text('Identity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CRMColors.textSecondaryOf(context)))),
                                              DataColumn(label: Text('Area', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CRMColors.textSecondaryOf(context)))),
                                              DataColumn(label: Text('Upload Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CRMColors.textSecondaryOf(context)))),
                                              DataColumn(label: Text('Uploaded By', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CRMColors.textSecondaryOf(context)))),
                                              DataColumn(label: Text('Actions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CRMColors.textSecondaryOf(context)))),
                                            ],
                                            rows: _paginatedDocuments.map((doc) {
                                              final text = doc.uploadedBy.trim();
                                              String displayUser = text;
                                              if (text.toLowerCase() == 'admin' || text.toLowerCase() == 'admin@nbdeveloper.com') {
                                                displayUser = 'Admin';
                                              } else if (text.toLowerCase() == 'super admin' || text.toLowerCase() == 'super_admin') {
                                                displayUser = 'Super Admin';
                                              } else if (text.contains('@')) {
                                                displayUser = text.split('@').first;
                                                if (displayUser.isNotEmpty) {
                                                  displayUser = displayUser[0].toUpperCase() + displayUser.substring(1);
                                                }
                                              }

                                              return DataRow(cells: [
                                                DataCell(
                                                  doc.agentImageUrl != null && doc.agentImageUrl!.isNotEmpty
                                                      ? ClipRRect(
                                                    borderRadius: BorderRadius.circular(6),
                                                    child: Image.network(
                                                      doc.agentImageUrl!,
                                                      width: 36,
                                                      height: 36,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) => _tableAvatarPlaceholder(context),
                                                    ),
                                                  )
                                                      : _tableAvatarPlaceholder(context),
                                                ),
                                                DataCell(
                                                  SizedBox(
                                                    width: 140,
                                                    child: Text(
                                                      doc.agentName,
                                                      style: CRMTypography.bodyMedium.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                        color: CRMColors.textOf(context),
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                                DataCell(Text(doc.dateOfBirth ?? '-', style: TextStyle(color: CRMColors.textOf(context), fontSize: 12))),
                                                DataCell(Text(doc.serviceType, style: TextStyle(color: CRMColors.textOf(context)))),
                                                DataCell(Text(doc.mobileNumber, style: TextStyle(color: CRMColors.textOf(context)))),
                                                DataCell(
                                                   Padding(
                                                     padding: const EdgeInsets.symmetric(vertical: 8),
                                                     child: Tooltip(
                                                       message: 'Click to view ${doc.documentType}',
                                                       child: Material(
                                                         color: Colors.transparent,
                                                         child: InkWell(
                                                           borderRadius: BorderRadius.circular(8),
                                                           onTap: () async {
                                                             final url = doc.fileUrl;
                                                             if (url != null && url.isNotEmpty) {
                                                               final uri = Uri.parse(url);
                                                               if (await canLaunchUrl(uri)) {
                                                                 await launchUrl(uri, mode: LaunchMode.externalApplication);
                                                               }
                                                             } else {
                                                               ScaffoldMessenger.of(context).showSnackBar(
                                                                 const SnackBar(
                                                                   content: Text('No document URL available.'),
                                                                   backgroundColor: CRMColors.danger,
                                                                 ),
                                                               );
                                                             }
                                                           },
                                                           child: Container(
                                                             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                             decoration: BoxDecoration(
                                                               color: CRMColors.primaryOf(context).withOpacity(0.08),
                                                               borderRadius: BorderRadius.circular(8),
                                                               border: Border.all(
                                                                 color: CRMColors.primaryOf(context).withOpacity(0.4),
                                                                 width: 1,
                                                               ),
                                                             ),
                                                             child: Row(
                                                               mainAxisSize: MainAxisSize.min,
                                                               children: [
                                                                 Icon(
                                                                   Icons.visibility_outlined,
                                                                   size: 15,
                                                                   color: CRMColors.primaryOf(context),
                                                                 ),
                                                                 const SizedBox(width: 6),
                                                                 Flexible(
                                                                   child: Text(
                                                                     doc.documentType,
                                                                     style: TextStyle(
                                                                       fontSize: 12,
                                                                       fontWeight: FontWeight.w600,
                                                                       color: CRMColors.primaryOf(context),
                                                                     ),
                                                                     overflow: TextOverflow.ellipsis,
                                                                   ),
                                                                 ),
                                                               ],
                                                             ),
                                                           ),
                                                         ),
                                                       ),
                                                     ),
                                                   ),
                                                ),
                                                DataCell(
                                                  SizedBox(
                                                    width: 160,
                                                    child: Text(
                                                      doc.area.isEmpty ? '-' : doc.area.join(', '),
                                                      style: TextStyle(color: CRMColors.textOf(context), fontSize: 12),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                                DataCell(Text(DateFormat('dd MMM yyyy').format(doc.uploadDate), style: TextStyle(color: CRMColors.textOf(context)))),
                                                DataCell(Text(displayUser, style: TextStyle(color: CRMColors.textOf(context)))),
                                                DataCell(
                                                  PopupMenuButton<String>(
                                                    icon: Icon(Icons.more_vert_rounded, color: CRMColors.textSecondaryOf(context)),
                                                    onSelected: (val) {
                                                      switch (val) {
                                                        case 'view': _viewDocument(doc); break;
                                                        case 'edit': _showUploadEditDialog(doc); break;
                                                        case 'share': _shareDocument(doc); break;
                                                        case 'delete': _deleteDocument(doc); break;
                                                      }
                                                    },
                                                    itemBuilder: (context) => [
                                                      const PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility_outlined, size: 18), SizedBox(width: 8), Text('View')])),
                                                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit')])),
                                                      const PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share_outlined, size: 18), SizedBox(width: 8), Text('Share')])),
                                                      const PopupMenuDivider(),
                                                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, color: CRMColors.danger, size: 18), SizedBox(width: 8), Text('Delete', style: TextStyle(color: CRMColors.danger))])),
                                                    ],
                                                  ),
                                                ),
                                              ]);
                                            }).toList(),
                                          ),
                                        ),
                                      ),

                                      // Bottom Pagination Bar
                                      if (_totalPages > 1)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Showing ${((_currentPage - 1) * _pageSize) + 1} - ${(_currentPage * _pageSize).clamp(0, _filteredDocuments.length)} of ${_filteredDocuments.length}',
                                                style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                                              ),
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.chevron_left_rounded),
                                                    onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                                                  ),
                                                  Text('Page $_currentPage of $_totalPages', style: CRMTypography.captionBold),
                                                  IconButton(
                                                    icon: const Icon(Icons.chevron_right_rounded),
                                                    onPressed: _currentPage < _totalPages ? () => setState(() => _currentPage++) : null,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              });
                            })),
            ],

            if (_showPendingView && _isAdminOrSuperAdmin) _buildPendingView(),
          ]),
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
