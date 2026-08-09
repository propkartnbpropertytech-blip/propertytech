import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
import '../models/document_model.dart';
import 'library_widgets.dart';

class ServiceAgentLibraryScreen extends StatefulWidget {
  const ServiceAgentLibraryScreen({super.key});

  @override
  State<ServiceAgentLibraryScreen> createState() => _ServiceAgentLibraryScreenState();
}

class _ServiceAgentLibraryScreenState extends State<ServiceAgentLibraryScreen> {
  // Local list representing the DB
  late List<ServiceAgentDocument> _allDocuments;
  List<ServiceAgentDocument> _filteredDocuments = [];

  // Table parameters
  String? _sortField = 'uploadDate';
  bool _sortAscending = false;
  int _currentPage = 1;
  int _pageSize = 10;

  // Filter controllers
  final TextEditingController _searchController = TextEditingController();
  String _selectedServiceType = 'All';
  String _selectedDocType = 'All';
  String _selectedStatus = 'All';
  DateTimeRange? _selectedDateRange;

  // Dropdown options
  final List<String> _serviceTypes = [
    'All',
    'Electrician',
    'Plumber',
    'Carpenter',
    'Painter',
    'AC Technician',
    'Cleaning Service',
    'Pest Control',
    'CCTV Service',
    'Interior Designer',
    'Movers & Packers',
    'Other'
  ];

  final List<String> _docTypes = [
    'All',
    'ID Proof',
    'GST Certificate',
    'Service Agreement',
    'Price List',
    'Quotation',
    'Invoice',
    'Work Photos',
    'Other Documents'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _allDocuments = ServiceAgentDocument.getMockData();
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    List<ServiceAgentDocument> temp = List.from(_allDocuments);

    // Search
    final searchQuery = _searchController.text.trim().toLowerCase();
    if (searchQuery.isNotEmpty) {
      temp = temp.where((doc) => doc.agentName.toLowerCase().contains(searchQuery) || doc.documentName.toLowerCase().contains(searchQuery)).toList();
    }

    // Service Type Filter
    if (_selectedServiceType != 'All') {
      temp = temp.where((doc) => doc.serviceType == _selectedServiceType).toList();
    }

    // Doc Type Filter
    if (_selectedDocType != 'All') {
      temp = temp.where((doc) => doc.documentType == _selectedDocType).toList();
    }

    // Status Filter
    if (_selectedStatus != 'All') {
      final targetStatus = DocumentStatusExtension.fromString(_selectedStatus);
      temp = temp.where((doc) => doc.status == targetStatus).toList();
    }

    // Date Range Filter
    if (_selectedDateRange != null) {
      temp = temp.where((doc) {
        return doc.uploadDate.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
            doc.uploadDate.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Sort
    if (_sortField != null) {
      temp.sort((a, b) {
        dynamic valA;
        dynamic valB;

        switch (_sortField) {
          case 'agentName':
            valA = a.agentName.toLowerCase();
            valB = b.agentName.toLowerCase();
            break;
          case 'serviceType':
            valA = a.serviceType.toLowerCase();
            valB = b.serviceType.toLowerCase();
            break;
          case 'documentName':
            valA = a.documentName.toLowerCase();
            valB = b.documentName.toLowerCase();
            break;
          case 'documentType':
            valA = a.documentType.toLowerCase();
            valB = b.documentType.toLowerCase();
            break;
          case 'uploadDate':
            valA = a.uploadDate;
            valB = b.uploadDate;
            break;
          case 'status':
            valA = a.status.index;
            valB = b.status.index;
            break;
          default:
            valA = a.uploadDate;
            valB = b.uploadDate;
        }

        int comp = valA.compareTo(valB);
        return _sortAscending ? comp : -comp;
      });
    }

    setState(() {
      _filteredDocuments = temp;
      _currentPage = 1;
    });
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _selectedServiceType = 'All';
      _selectedDocType = 'All';
      _selectedStatus = 'All';
      _selectedDateRange = null;
    });
    _applyFiltersAndSort();
  }

  // Summary Metrics
  int get _totalCount => _allDocuments.length;
  int get _activeCount => _allDocuments.where((d) => d.status == DocumentStatus.active).length;
  int get _expiredCount => _allDocuments.where((d) => d.status == DocumentStatus.expired).length;
  int get _recentCount => _allDocuments.where((d) => d.uploadDate.isAfter(DateTime.now().subtract(const Duration(days: 7)))).length;

  // Pagination helper
  List<ServiceAgentDocument> get _paginatedDocuments {
    int start = (_currentPage - 1) * _pageSize;
    int end = start + _pageSize;
    if (start >= _filteredDocuments.length) return [];
    if (end > _filteredDocuments.length) end = _filteredDocuments.length;
    return _filteredDocuments.sublist(start, end);
  }

  int get _totalPages => (_filteredDocuments.length / _pageSize).ceil();

  // Action methods
  void _viewDocument(ServiceAgentDocument doc) {
    showDialog(
      context: context,
      builder: (context) {
        final isVideo = doc.fileExtension == 'mp4' || doc.fileExtension == 'mov';
        return Dialog(
          backgroundColor: CRMColors.surfaceElevatedOf(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CRMBorderRadius.dialog),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: Padding(
              padding: const EdgeInsets.all(CRMSpacing.l),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FileIconHelper.getIconForExtension(doc.fileExtension, size: 28),
                      const SizedBox(width: CRMSpacing.s),
                      Expanded(
                        child: Text(
                          doc.documentName,
                          style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      CRMStatusChip(status: doc.status.displayName),
                    ],
                  ),
                  const Divider(height: CRMSpacing.xl),
                  _buildDetailRow(context, 'Agent Name:', doc.agentName),
                  _buildDetailRow(context, 'Service Type:', doc.serviceType),
                  _buildDetailRow(context, 'Mobile Number:', doc.mobileNumber),
                  _buildDetailRow(context, 'Document Name:', doc.documentName),
                  _buildDetailRow(context, 'Document Type:', doc.documentType),
                  _buildDetailRow(context, 'Uploaded On:', DateFormat('dd MMM yyyy, hh:mm a').format(doc.uploadDate)),
                  _buildDetailRow(context, 'Uploaded By:', doc.uploadedBy),
                  _buildDetailRow(context, 'File Details:', '${doc.fileSize} (${doc.fileExtension.toUpperCase()})'),
                  const SizedBox(height: CRMSpacing.m),
                  Text(
                    'Description:',
                    style: CRMTypography.captionBold.copyWith(color: CRMColors.textSecondaryOf(context)),
                  ),
                  const SizedBox(height: CRMSpacing.xxs),
                  Text(
                    doc.description.isNotEmpty ? doc.description : 'No description provided.',
                    style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
                  ),
                  if (isVideo) ...[
                    const SizedBox(height: CRMSpacing.m),
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(CRMBorderRadius.input),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: Icon(
                              Icons.video_library_outlined,
                              size: 48,
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.play_circle_outline_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 6),
                                Text(
                                  'Play work showcase video',
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: CRMSpacing.l),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CRMButton(
                        label: 'Close',
                        variant: CRMButtonVariant.outline,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: CRMSpacing.s),
                      CRMButton(
                        label: 'Download File',
                        variant: CRMButtonVariant.primary,
                        onPressed: () {
                          Navigator.pop(context);
                          _downloadDocument(doc);
                        },
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

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: CRMTypography.captionBold.copyWith(color: CRMColors.textSecondaryOf(context)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textOf(context)),
            ),
          ),
        ],
      ),
    );
  }

  void _downloadDocument(ServiceAgentDocument doc) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(CRMSpacing.xl),
          decoration: BoxDecoration(
            color: CRMColors.surfaceElevatedOf(context),
            borderRadius: BorderRadius.circular(CRMBorderRadius.l),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: CRMColors.primaryOf(context)),
              const SizedBox(height: CRMSpacing.m),
              Text(
                'Downloading ${doc.documentName}...',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${doc.documentName} successfully saved!'),
          backgroundColor: CRMColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _shareDocument(ServiceAgentDocument doc) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: CRMColors.surfaceElevatedOf(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CRMBorderRadius.dialog),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(CRMSpacing.l),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Share Document',
                    style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context)),
                  ),
                  const SizedBox(height: CRMSpacing.s),
                  Text(
                    'Select how you want to share ${doc.documentName}:',
                    style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                  ),
                  const SizedBox(height: CRMSpacing.m),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: CRMColors.info,
                      child: Icon(Icons.link_rounded, color: Colors.white),
                    ),
                    title: const Text('Copy Access Link'),
                    subtitle: const Text('Expires in 7 days'),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Document sharing link copied to clipboard!'),
                          backgroundColor: CRMColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.orangeAccent,
                      child: Icon(Icons.mail_outline_rounded, color: Colors.white),
                    ),
                    title: const Text('Send via Email'),
                    subtitle: Text('To agent contact'),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Document emailed to ${doc.agentName}!'),
                          backgroundColor: CRMColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: CRMSpacing.l),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CRMButton(
                        label: 'Cancel',
                        variant: CRMButtonVariant.outline,
                        onPressed: () => Navigator.pop(context),
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

  void _deleteDocument(ServiceAgentDocument doc) async {
    final confirm = await CRMDialogs.showDeleteConfirmation(
      context,
      title: 'Delete Agent Document',
      content: 'Are you sure you want to delete "${doc.documentName}"? This action cannot be undone.',
    );

    if (confirm == true) {
      setState(() {
        _allDocuments.removeWhere((d) => d.id == doc.id);
        _applyFiltersAndSort();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document "${doc.documentName}" was successfully deleted.'),
            backgroundColor: CRMColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showUploadEditDialog([ServiceAgentDocument? existingDoc]) {
    final isEditing = existingDoc != null;
    final formKey = GlobalKey<FormState>();

    final agentController = TextEditingController(text: existingDoc?.agentName);
    final mobileController = TextEditingController(text: existingDoc?.mobileNumber);
    final nameController = TextEditingController(text: existingDoc?.documentName);
    final descController = TextEditingController(text: existingDoc?.description);

    String localServiceType = existingDoc?.serviceType ?? 'Electrician';
    String localDocType = existingDoc?.documentType ?? 'ID Proof';
    DocumentStatus localStatus = existingDoc?.status ?? DocumentStatus.active;
    String localFileName = existingDoc?.documentName ?? '';
    String localFileExt = existingDoc?.fileExtension ?? 'pdf';
    String localFileSize = existingDoc?.fileSize ?? '0 KB';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: CRMColors.surfaceElevatedOf(context),
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(CRMBorderRadius.dialog),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 550, maxHeight: 850),
                child: Padding(
                  padding: const EdgeInsets.all(CRMSpacing.l),
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isEditing ? 'Edit Agent Document' : 'Upload Agent Document',
                                style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () async {
                                  final nameVal = nameController.text;
                                  final hasInput = nameVal.isNotEmpty ||
                                      agentController.text.isNotEmpty ||
                                      mobileController.text.isNotEmpty;

                                  if (hasInput && !isEditing) {
                                    final discard = await CRMDialogs.showUnsavedChangesDialog(context);
                                    if (discard == true && context.mounted) {
                                      Navigator.pop(context);
                                    }
                                  } else {
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: CRMSpacing.m),
                          CRMTextField(
                            controller: agentController,
                            labelText: 'Agent Name *',
                            hintText: 'e.g. A1 Electricians Ltd',
                            validator: (val) => val == null || val.trim().isEmpty ? 'Agent name required' : null,
                          ),
                          const SizedBox(height: CRMSpacing.m),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Service Type *',
                                      style: CRMTypography.label.copyWith(color: CRMColors.textSecondaryOf(context)),
                                    ),
                                    const SizedBox(height: CRMSpacing.xs),
                                    DropdownButtonFormField<String>(
                                      value: localServiceType,
                                      isExpanded: true,
                                      dropdownColor: CRMColors.surfaceElevatedOf(context),
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: CRMSpacing.s),
                                        filled: true,
                                        fillColor: CRMColors.cardBgOf(context),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(CRMBorderRadius.input),
                                          borderSide: BorderSide(color: CRMColors.borderOf(context)),
                                        ),
                                      ),
                                      items: _serviceTypes
                                          .where((t) => t != 'All')
                                          .map((t) => DropdownMenuItem(
                                                value: t,
                                                child: Text(t, style: TextStyle(color: CRMColors.textOf(context))),
                                              ))
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setModalState(() {
                                            localServiceType = val;
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: CRMSpacing.m),
                              Expanded(
                                child: CRMTextField(
                                  controller: mobileController,
                                  labelText: 'Mobile Number *',
                                  hintText: '+91 XXXXX XXXXX',
                                  keyboardType: TextInputType.phone,
                                  validator: (val) => val == null || val.trim().isEmpty ? 'Mobile number required' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: CRMSpacing.m),
                          Row(
                            children: [
                              Expanded(
                                child: CRMTextField(
                                  controller: nameController,
                                  labelText: 'Document Name *',
                                  hintText: 'e.g. GSTIN Certificate',
                                  validator: (val) => val == null || val.trim().isEmpty ? 'Document name required' : null,
                                ),
                              ),
                              const SizedBox(width: CRMSpacing.m),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Document Type *',
                                      style: CRMTypography.label.copyWith(color: CRMColors.textSecondaryOf(context)),
                                    ),
                                    const SizedBox(height: CRMSpacing.xs),
                                    DropdownButtonFormField<String>(
                                      value: localDocType,
                                      isExpanded: true,
                                      dropdownColor: CRMColors.surfaceElevatedOf(context),
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: CRMSpacing.s),
                                        filled: true,
                                        fillColor: CRMColors.cardBgOf(context),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(CRMBorderRadius.input),
                                          borderSide: BorderSide(color: CRMColors.borderOf(context)),
                                        ),
                                      ),
                                      items: _docTypes
                                          .where((t) => t != 'All')
                                          .map((t) => DropdownMenuItem(
                                                value: t,
                                                child: Text(t, style: TextStyle(color: CRMColors.textOf(context))),
                                              ))
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setModalState(() {
                                            localDocType = val;
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: CRMSpacing.m),
                          CRMTextField(
                            controller: descController,
                            labelText: 'Description',
                            hintText: 'Add description or registration validity notes...',
                            maxLines: 2,
                          ),
                          const SizedBox(height: CRMSpacing.m),
                          DragDropUploadZone(
                            initialFileName: localFileName,
                            initialFileSize: localFileSize,
                            onFileSelected: (name, ext, size) {
                              setModalState(() {
                                localFileName = name;
                                localFileExt = ext;
                                localFileSize = size;
                                if (nameController.text.trim().isEmpty && name.isNotEmpty) {
                                  nameController.text = name.split('.').first;
                                }
                              });
                            },
                          ),
                          const SizedBox(height: CRMSpacing.m),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Status',
                                style: CRMTypography.label.copyWith(color: CRMColors.textSecondaryOf(context)),
                              ),
                              const SizedBox(height: CRMSpacing.xs),
                              Row(
                                children: [
                                  Radio<DocumentStatus>(
                                    value: DocumentStatus.active,
                                    groupValue: localStatus,
                                    activeColor: CRMColors.primaryOf(context),
                                    onChanged: (val) => setModalState(() => localStatus = val!),
                                  ),
                                  Text('Active', style: TextStyle(color: CRMColors.textOf(context))),
                                  const SizedBox(width: CRMSpacing.s),
                                  Radio<DocumentStatus>(
                                    value: DocumentStatus.expired,
                                    groupValue: localStatus,
                                    activeColor: CRMColors.primaryOf(context),
                                    onChanged: (val) => setModalState(() => localStatus = val!),
                                  ),
                                  Text('Expired', style: TextStyle(color: CRMColors.textOf(context))),
                                  const SizedBox(width: CRMSpacing.s),
                                  Radio<DocumentStatus>(
                                    value: DocumentStatus.archived,
                                    groupValue: localStatus,
                                    activeColor: CRMColors.primaryOf(context),
                                    onChanged: (val) => setModalState(() => localStatus = val!),
                                  ),
                                  Text('Archived', style: TextStyle(color: CRMColors.textOf(context))),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: CRMSpacing.l),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              CRMButton(
                                label: 'Cancel',
                                variant: CRMButtonVariant.outline,
                                onPressed: () async {
                                  final nameVal = nameController.text;
                                  final hasInput = nameVal.isNotEmpty ||
                                      agentController.text.isNotEmpty ||
                                      mobileController.text.isNotEmpty;

                                  if (hasInput && !isEditing) {
                                    final discard = await CRMDialogs.showUnsavedChangesDialog(context);
                                    if (discard == true && context.mounted) {
                                      Navigator.pop(context);
                                    }
                                  } else {
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                              const SizedBox(width: CRMSpacing.s),
                              CRMButton(
                                label: isEditing ? 'Save Changes' : 'Upload',
                                variant: CRMButtonVariant.primary,
                                onPressed: () {
                                  if (formKey.currentState!.validate()) {
                                    if (localFileName.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please upload a document file.'),
                                          backgroundColor: CRMColors.danger,
                                        ),
                                      );
                                      return;
                                    }

                                    if (isEditing) {
                                      final idx = _allDocuments.indexWhere((d) => d.id == existingDoc.id);
                                      if (idx != -1) {
                                        setState(() {
                                          _allDocuments[idx] = existingDoc.copyWith(
                                            agentName: agentController.text.trim(),
                                            serviceType: localServiceType,
                                            mobileNumber: mobileController.text.trim(),
                                            documentName: nameController.text.trim(),
                                            documentType: localDocType,
                                            description: descController.text.trim(),
                                            status: localStatus,
                                            fileSize: localFileSize,
                                            fileExtension: localFileExt,
                                          );
                                        });
                                      }
                                    } else {
                                      final newDoc = ServiceAgentDocument(
                                        id: 'agent-${DateTime.now().millisecondsSinceEpoch}',
                                        agentName: agentController.text.trim(),
                                        serviceType: localServiceType,
                                        mobileNumber: mobileController.text.trim(),
                                        documentName: nameController.text.trim(),
                                        documentType: localDocType,
                                        uploadDate: DateTime.now(),
                                        uploadedBy: 'admin',
                                        status: localStatus,
                                        description: descController.text.trim(),
                                        fileSize: localFileSize,
                                        fileExtension: localFileExt,
                                      );
                                      setState(() {
                                        _allDocuments.insert(0, newDoc);
                                      });
                                    }

                                    _applyFiltersAndSort();
                                    Navigator.pop(context);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isEditing ? 'Agent document updated!' : 'Agent document uploaded successfully!',
                                        ),
                                        backgroundColor: CRMColors.success,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Breadcrumb
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const LibraryBreadcrumb(currentPageName: 'Service Agent Library'),
                      Text(
                        'Service Agent Document Library',
                        style: CRMTypography.pageTitle.copyWith(color: CRMColors.textOf(context)),
                      ),
                      Text(
                        'Store, filter, and organize service provider SLA agreements and invoices.',
                        style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
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
                      CRMButton(
                        label: 'Upload Document',
                        prefixIcon: Icons.add_rounded,
                        onPressed: () => _showUploadEditDialog(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: CRMSpacing.m),

              // Top Cards Grid
              LayoutBuilder(builder: (context, constraints) {
                int columns = isDesktop ? 4 : 2;
                double spacing = CRMSpacing.m;
                double cardWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: CRMKPICard(
                        title: 'Total Agents Documents',
                        value: '$_totalCount',
                        icon: Icons.badge_rounded,
                        iconColor: CRMColors.primaryOf(context),
                        benefit: 'Vendor credentials ready when you need them',
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: CRMKPICard(
                        title: 'Active Documents',
                        value: '$_activeCount',
                        icon: Icons.check_circle_rounded,
                        iconColor: CRMColors.success,
                        benefit: 'Valid contracts keep service work moving',
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: CRMKPICard(
                        title: 'Expired Documents',
                        value: '$_expiredCount',
                        icon: Icons.history_rounded,
                        iconColor: CRMColors.danger,
                        benefit: 'Renew SLAs before coverage gaps',
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: CRMKPICard(
                        title: 'Recent Uploads (7d)',
                        value: '$_recentCount',
                        icon: Icons.cloud_done_rounded,
                        iconColor: CRMColors.info,
                        benefit: 'Latest proofs keep vendors accountable',
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: CRMSpacing.l),

              // Filter Controls Card
              CRMCard(
                padding: const EdgeInsets.all(CRMSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.filter_alt_rounded, size: 18, color: CRMColors.primaryOf(context)),
                        const SizedBox(width: 6),
                        Text(
                          'Advanced Filters',
                          style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: CRMColors.textOf(context)),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _resetFilters,
                          child: const Text('Reset All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    LayoutBuilder(
                      builder: (context, filterConstraints) {
                        int rowColumns = isDesktop ? 4 : (isTablet ? 2 : 2);
                        double filterSpacing = CRMSpacing.s;
                        double inputWidth = ((filterConstraints.maxWidth - (filterSpacing * (rowColumns - 1))) / rowColumns) - 1.0;

                        return Wrap(
                          spacing: filterSpacing,
                          runSpacing: filterSpacing,
                          children: [
                            // Search Box
                            SizedBox(
                              width: inputWidth,
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Search Agent or Document',
                                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                onChanged: (_) => _applyFiltersAndSort(),
                              ),
                            ),
                            // Service Type Dropdown
                            _buildFilterDropdown('Service Type', _selectedServiceType, _serviceTypes, (val) {
                              setState(() => _selectedServiceType = val!);
                              _applyFiltersAndSort();
                            }, inputWidth),
                            // Doc Type Dropdown
                            _buildFilterDropdown('Doc Type', _selectedDocType, _docTypes, (val) {
                              setState(() => _selectedDocType = val!);
                              _applyFiltersAndSort();
                            }, inputWidth),
                            // Status Dropdown
                            _buildFilterDropdown('Status', _selectedStatus, ['All', 'Active', 'Expired', 'Archived'], (val) {
                              setState(() => _selectedStatus = val!);
                              _applyFiltersAndSort();
                            }, inputWidth),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: CRMSpacing.m),

              // Data Table Area
              _filteredDocuments.isEmpty
                    ? CRMEmptyState(
                        title: 'No Provider Documents',
                        description: 'No service agent records match the current filters.',
                        actionLabel: 'Reset Filters',
                        onActionPressed: _resetFilters,
                      )
                    : (isMobile
                        ? Column(
                            children: [
                              ..._paginatedDocuments.map((doc) => _buildMobileDocumentCard(doc)),
                              _buildMobilePagination(),
                            ],
                          )
                        : CRMDataTable<ServiceAgentDocument>(
                            currentPage: _currentPage,
                            totalPages: _totalPages,
                            onPageChanged: (page) {
                              setState(() {
                                _currentPage = page;
                              });
                            },
                            totalItems: _filteredDocuments.length,
                            itemsPerPage: _pageSize,
                            onItemsPerPageChanged: (rows) {
                              setState(() {
                                _pageSize = rows;
                                _currentPage = 1;
                              });
                              _applyFiltersAndSort();
                            },
                            sortField: _sortField,
                        sortAscending: _sortAscending,
                        onSort: (field, ascending) {
                          setState(() {
                            _sortField = field;
                            _sortAscending = ascending;
                          });
                          _applyFiltersAndSort();
                        },
                        columns: [
                          CRMColumn<ServiceAgentDocument>(
                            label: 'Agent Name',
                            sortable: true,
                            sortField: 'agentName',
                            width: 180,
                            cellBuilder: (doc) => Text(
                              doc.agentName,
                              style: CRMTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: CRMColors.textOf(context),
                              ),
                            ),
                          ),
                          CRMColumn<ServiceAgentDocument>(
                            label: 'Service Type',
                            sortable: true,
                            sortField: 'serviceType',
                            width: 140,
                            cellBuilder: (doc) => Text(doc.serviceType, style: TextStyle(color: CRMColors.textOf(context))),
                          ),
                          CRMColumn<ServiceAgentDocument>(
                            label: 'Mobile Number',
                            width: 140,
                            cellBuilder: (doc) => Text(doc.mobileNumber, style: TextStyle(color: CRMColors.textOf(context))),
                          ),
                          CRMColumn<ServiceAgentDocument>(
                            label: 'Document Name',
                            sortable: true,
                            sortField: 'documentName',
                            width: 250,
                            cellBuilder: (doc) => Row(
                              children: [
                                FileIconHelper.getIconForExtension(doc.fileExtension),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        doc.documentName,
                                        style: CRMTypography.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: CRMColors.textOf(context),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        doc.fileSize,
                                        style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CRMColumn<ServiceAgentDocument>(
                            label: 'Document Type',
                            sortable: true,
                            sortField: 'documentType',
                            width: 150,
                            cellBuilder: (doc) => Text(doc.documentType, style: TextStyle(color: CRMColors.textOf(context))),
                          ),
                          CRMColumn<ServiceAgentDocument>(
                            label: 'Upload Date',
                            sortable: true,
                            sortField: 'uploadDate',
                            width: 120,
                            cellBuilder: (doc) => Text(
                              DateFormat('dd MMM yyyy').format(doc.uploadDate),
                              style: TextStyle(color: CRMColors.textOf(context)),
                            ),
                          ),
                          CRMColumn<ServiceAgentDocument>(
                            label: 'Uploaded By',
                            width: 110,
                            cellBuilder: (doc) => Text(doc.uploadedBy, style: TextStyle(color: CRMColors.textOf(context))),
                          ),
                          CRMColumn<ServiceAgentDocument>(
                            label: 'Status',
                            sortable: true,
                            sortField: 'status',
                            width: 110,
                            cellBuilder: (doc) => CRMStatusChip(status: doc.status.displayName),
                          ),
                          CRMColumn<ServiceAgentDocument>(
                            label: 'Actions',
                            width: 80,
                            cellBuilder: (doc) => PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert_rounded, color: CRMColors.textSecondaryOf(context)),
                              onSelected: (val) {
                                switch (val) {
                                  case 'view':
                                    _viewDocument(doc);
                                    break;
                                  case 'download':
                                    _downloadDocument(doc);
                                    break;
                                  case 'edit':
                                    _showUploadEditDialog(doc);
                                    break;
                                  case 'share':
                                    _shareDocument(doc);
                                    break;
                                  case 'delete':
                                    _deleteDocument(doc);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'view',
                                  child: Row(
                                    children: [Icon(Icons.visibility_outlined, size: 18), SizedBox(width: 8), Text('View')],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'download',
                                  child: Row(
                                    children: [Icon(Icons.download_rounded, size: 18), SizedBox(width: 8), Text('Download')],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit')],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'share',
                                  child: Row(
                                    children: [Icon(Icons.share_outlined, size: 18), SizedBox(width: 8), Text('Share')],
                                  ),
                                ),
                                const PopupMenuDivider(),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [Icon(Icons.delete_outline_rounded, color: CRMColors.danger, size: 18), SizedBox(width: 8), Text('Delete', style: TextStyle(color: CRMColors.danger))],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        items: _paginatedDocuments,
                      )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String currentValue,
    List<String> items,
    void Function(String?) onChanged,
    double width,
  ) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        value: currentValue,
        isExpanded: true,
        dropdownColor: CRMColors.cardBgOf(context),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
          contentPadding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: 10),
          filled: true,
          fillColor: CRMColors.backgroundOf(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CRMBorderRadius.s),
            borderSide: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.6)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CRMBorderRadius.s),
            borderSide: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CRMBorderRadius.s),
            borderSide: BorderSide(color: CRMColors.primaryOf(context), width: 1.5),
          ),
        ),
        style: CRMTypography.body.copyWith(color: CRMColors.textOf(context), fontSize: 13),
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 13,
                      color: CRMColors.textOf(context),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildMobileDocumentCard(ServiceAgentDocument doc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CRMSpacing.m),
      child: CRMCard(
        padding: const EdgeInsets.all(CRMSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FileIconHelper.getIconForExtension(doc.fileExtension, size: 24),
              const SizedBox(width: CRMSpacing.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.documentName,
                      style: CRMTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: CRMColors.textOf(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${doc.fileSize} • ${doc.documentType}',
                      style: CRMTypography.caption.copyWith(
                        color: CRMColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: CRMColors.textSecondaryOf(context)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onSelected: (val) {
                  switch (val) {
                    case 'view':
                      _viewDocument(doc);
                      break;
                    case 'download':
                      _downloadDocument(doc);
                      break;
                    case 'edit':
                      _showUploadEditDialog(doc);
                      break;
                    case 'share':
                      _shareDocument(doc);
                      break;
                    case 'delete':
                      _deleteDocument(doc);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [Icon(Icons.visibility_outlined, size: 18), SizedBox(width: 8), Text('View')],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'download',
                    child: Row(
                      children: [Icon(Icons.download_rounded, size: 18), SizedBox(width: 8), Text('Download')],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit')],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [Icon(Icons.share_outlined, size: 18), SizedBox(width: 8), Text('Share')],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [Icon(Icons.delete_outline_rounded, color: CRMColors.danger, size: 18), SizedBox(width: 8), Text('Delete', style: TextStyle(color: CRMColors.danger))],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.m),
          const Divider(height: 1),
          const SizedBox(height: CRMSpacing.s),
          _buildMobileDetailItem('Agent Name', doc.agentName),
          _buildMobileDetailItem('Service Type', doc.serviceType),
          _buildMobileDetailItem('Mobile Number', doc.mobileNumber),
          _buildMobileDetailItem('Uploaded By', doc.uploadedBy),
          _buildMobileDetailItem('Upload Date', DateFormat('dd MMM yyyy').format(doc.uploadDate)),
          const SizedBox(height: CRMSpacing.m),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CRMStatusChip(status: doc.status.displayName),
              Text(
                doc.fileExtension.toUpperCase(),
                style: CRMTypography.captionBold.copyWith(
                  color: CRMColors.textMutedOf(context),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildMobileDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
          ),
          const SizedBox(width: CRMSpacing.m),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: CRMTypography.bodyMedium.copyWith(
                color: CRMColors.textOf(context),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobilePagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: CRMSpacing.s, bottom: CRMSpacing.l),
      child: CRMCard(
        padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: CRMSpacing.xs),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Page $_currentPage of $_totalPages',
              style: CRMTypography.captionBold.copyWith(color: CRMColors.textSecondaryOf(context)),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: _currentPage < _totalPages ? () => setState(() => _currentPage++) : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
