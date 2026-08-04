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
import '../../properties/models/property_model.dart';
import '../../properties/repository/properties_repository.dart';

class RentalLibraryScreen extends StatefulWidget {
  final Map<String, dynamic>? initialArgs;
  const RentalLibraryScreen({super.key, this.initialArgs});

  @override
  State<RentalLibraryScreen> createState() => _RentalLibraryScreenState();
}

class _RentalLibraryScreenState extends State<RentalLibraryScreen> {
  // Local list representing the DB
  late List<RentalDocument> _allDocuments;
  List<RentalDocument> _filteredDocuments = [];

  // Table parameters
  String? _sortField = 'uploadDate';
  bool _sortAscending = false;
  int _currentPage = 1;
  int _pageSize = 10;

  // Filter controllers
  final TextEditingController _searchController = TextEditingController();
  String _selectedProperty = 'All';
  String _selectedTenant = 'All';
  String _selectedOwner = 'All';
  String _selectedDocType = 'All';
  String _selectedStatus = 'All';
  DateTimeRange? _selectedDateRange;

  List<PropertyModel> _masterPropertiesList = [];

  // Autocomplete suggestions
  List<String> _properties = ['All'];
  List<String> _tenants = ['All'];
  List<String> _owners = ['All'];
  final List<String> _docTypes = [
    'All',
    'Rental Agreement',
    'Tenant ID Proof',
    'Owner ID Proof',
    'Rent Receipt',
    'Security Deposit Receipt',
    'Electricity Bill',
    'Water Bill',
    'Maintenance Bill',
    'Property Photos',
    'Property Videos',
    'Other Documents'
  ];

  @override
  void initState() {
    super.initState();
    _allDocuments = RentalDocument.getMockData();
    _updateFilterOptions();
    _applyFiltersAndSort();
    _loadMasterProperties();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final args = widget.initialArgs;
        if (args != null && args['autoOpenUpload'] == true) {
          final clientName = args['clientName'] as String?;
          _showUploadEditDialog(null, clientName);
        }
      }
    });
  }

  Future<void> _loadMasterProperties() async {
    try {
      final list = await PropertiesRepository().getProperties();
      if (mounted) {
        setState(() {
          _masterPropertiesList = list;
        });
      }
    } catch (_) {}
  }

  void _updateFilterOptions() {
    setState(() {
      _properties = ['All', ..._allDocuments.map((d) => d.propertyName).toSet()];
      _tenants = ['All', ..._allDocuments.map((d) => d.tenantName).toSet()];
      _owners = ['All', ..._allDocuments.map((d) => d.ownerName).toSet()];
    });
  }

  void _applyFiltersAndSort() {
    List<RentalDocument> temp = List.from(_allDocuments);

    // Search — matches document name, property name, tenant name, owner name
    final searchQuery = _searchController.text.trim().toLowerCase();
    if (searchQuery.isNotEmpty) {
      temp = temp.where((doc) =>
        doc.name.toLowerCase().contains(searchQuery) ||
        doc.propertyName.toLowerCase().contains(searchQuery) ||
        doc.tenantName.toLowerCase().contains(searchQuery) ||
        doc.ownerName.toLowerCase().contains(searchQuery)
      ).toList();
    }

    // Property Filter
    if (_selectedProperty != 'All') {
      temp = temp.where((doc) => doc.propertyName == _selectedProperty).toList();
    }

    // Tenant Filter
    if (_selectedTenant != 'All') {
      temp = temp.where((doc) => doc.tenantName == _selectedTenant).toList();
    }

    // Owner Filter
    if (_selectedOwner != 'All') {
      temp = temp.where((doc) => doc.ownerName == _selectedOwner).toList();
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
          case 'name':
            valA = a.name.toLowerCase();
            valB = b.name.toLowerCase();
            break;
          case 'propertyName':
            valA = a.propertyName.toLowerCase();
            valB = b.propertyName.toLowerCase();
            break;
          case 'tenantName':
            valA = a.tenantName.toLowerCase();
            valB = b.tenantName.toLowerCase();
            break;
          case 'ownerName':
            valA = a.ownerName.toLowerCase();
            valB = b.ownerName.toLowerCase();
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
      _selectedProperty = 'All';
      _selectedTenant = 'All';
      _selectedOwner = 'All';
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
  List<RentalDocument> get _paginatedDocuments {
    int start = (_currentPage - 1) * _pageSize;
    int end = start + _pageSize;
    if (start >= _filteredDocuments.length) return [];
    if (end > _filteredDocuments.length) end = _filteredDocuments.length;
    return _filteredDocuments.sublist(start, end);
  }

  int get _totalPages => (_filteredDocuments.length / _pageSize).ceil();

  // Action methods
  void _viewDocument(RentalDocument doc) {
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
                          doc.name,
                          style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      CRMStatusChip(status: doc.status.displayName),
                    ],
                  ),
                  const Divider(height: CRMSpacing.xl),
                  _buildDetailRow(context, 'Property:', doc.propertyName),
                  _buildDetailRow(context, 'Tenant Name:', doc.tenantName),
                  _buildDetailRow(context, 'Owner Name:', doc.ownerName),
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
                                  'Play inspection video walkthrough',
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

  void _downloadDocument(RentalDocument doc) async {
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
                'Downloading ${doc.name}...',
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
          content: Text('${doc.name} successfully downloaded to downloads directory!'),
          backgroundColor: CRMColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _shareDocument(RentalDocument doc) {
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
                    'Select how you want to share ${doc.name}:',
                    style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                  ),
                  const SizedBox(height: CRMSpacing.m),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blueAccent,
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
                    subtitle: Text('To tenant/owner contacts'),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Document emailed to ${doc.tenantName}!'),
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

  void _deleteDocument(RentalDocument doc) async {
    final confirm = await CRMDialogs.showDeleteConfirmation(
      context,
      title: 'Delete Document',
      content: 'Are you sure you want to delete "${doc.name}"? This action cannot be undone.',
    );

    if (confirm == true) {
      setState(() {
        _allDocuments.removeWhere((d) => d.id == doc.id);
        _updateFilterOptions();
        _applyFiltersAndSort();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document "${doc.name}" was successfully deleted.'),
            backgroundColor: CRMColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showUploadEditDialog([RentalDocument? existingDoc, String? defaultClientName]) {
    final isEditing = existingDoc != null;
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(text: existingDoc?.name);
    final propController = TextEditingController(text: existingDoc?.propertyName);
    final tenantController = TextEditingController(text: existingDoc?.tenantName ?? defaultClientName);
    final ownerController = TextEditingController(text: existingDoc?.ownerName);
    final descController = TextEditingController(text: existingDoc?.description);

    String localType = existingDoc?.documentType ?? 'Rental Agreement';
    DocumentStatus localStatus = existingDoc?.status ?? DocumentStatus.active;
    String localFileName = existingDoc?.name ?? '';
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
                                isEditing ? 'Edit Rental Document Info' : 'Upload Rental Document',
                                style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () async {
                                  final nameVal = nameController.text;
                                  final hasInput = nameVal.isNotEmpty ||
                                      propController.text.isNotEmpty ||
                                      tenantController.text.isNotEmpty;

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
                            controller: nameController,
                            labelText: 'Document Name *',
                            hintText: 'e.g. Greenwood Villa Agreement',
                            validator: (val) => val == null || val.trim().isEmpty ? 'Document name required' : null,
                          ),
                          const SizedBox(height: CRMSpacing.m),
                          Row(
                            children: [
                              Expanded(
                                child: Autocomplete<String>(
                                  optionsBuilder: (TextEditingValue textEditingValue) {
                                    if (textEditingValue.text.isEmpty) {
                                      return const Iterable<String>.empty();
                                    }
                                    final rentProperties = _masterPropertiesList
                                        .where((p) => p.listingTypeName.toLowerCase().contains('rent'))
                                        .map((p) => p.title)
                                        .toSet()
                                        .toList();
                                    final source = rentProperties.isNotEmpty ? rentProperties : _properties.where((p) => p != 'All').toList();
                                    return source
                                        .where((String option) => option
                                            .toLowerCase()
                                            .contains(textEditingValue.text.toLowerCase()));
                                  },
                                  fieldViewBuilder: (BuildContext context,
                                      TextEditingController textEditingController,
                                      FocusNode focusNode,
                                      VoidCallback onFieldSubmitted) {
                                    if (textEditingController.text.isEmpty && propController.text.isNotEmpty) {
                                      textEditingController.text = propController.text;
                                    }
                                    textEditingController.addListener(() {
                                      propController.text = textEditingController.text;
                                    });
                                    return CRMTextField(
                                      controller: textEditingController,
                                      focusNode: focusNode,
                                      labelText: 'Property Name *',
                                      hintText: 'e.g. Greenwood Villa',
                                      validator: (val) => val == null || val.trim().isEmpty ? 'Property name required' : null,
                                    );
                                  },
                                  onSelected: (String selection) {
                                    setModalState(() {
                                      propController.text = selection;
                                      final matches = _masterPropertiesList.where((p) => p.title == selection);
                                      if (matches.isNotEmpty) {
                                        ownerController.text = matches.first.ownerName;
                                      } else {
                                        final docMatches = _allDocuments.where((d) => d.propertyName == selection);
                                        if (docMatches.isNotEmpty) {
                                          ownerController.text = docMatches.first.ownerName;
                                        }
                                      }
                                    });
                                  },
                                  optionsViewBuilder: (context, onSelected, options) {
                                    return Align(
                                      alignment: Alignment.topLeft,
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Material(
                                          elevation: 8.0,
                                          shadowColor: Colors.black.withOpacity(0.25),
                                          borderRadius: BorderRadius.circular(8),
                                          color: CRMColors.surfaceElevatedOf(context),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.5)),
                                            ),
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(maxHeight: 250, maxWidth: 240),
                                              child: ListView.separated(
                                                padding: EdgeInsets.zero,
                                                shrinkWrap: true,
                                                itemCount: options.length,
                                                separatorBuilder: (context, index) => Divider(
                                                  height: 1,
                                                  color: CRMColors.divider.withOpacity(0.5),
                                                ),
                                                itemBuilder: (BuildContext context, int index) {
                                                  final String option = options.elementAt(index);
                                                  final prop = _masterPropertiesList.where((p) => p.title == option).firstOrNull;
                                                  final String subtitleText = prop != null
                                                      ? '${prop.propertyCode} • ${prop.areaName}'
                                                      : 'Existing Property';
                                                  return InkWell(
                                                    onTap: () => onSelected(option),
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            Icons.home_work_rounded,
                                                            size: 16,
                                                            color: CRMColors.primaryOf(context),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  option,
                                                                  style: TextStyle(
                                                                    color: CRMColors.textOf(context),
                                                                    fontSize: 13,
                                                                    fontWeight: FontWeight.bold,
                                                                  ),
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                                const SizedBox(height: 2),
                                                                Text(
                                                                  subtitleText,
                                                                  style: TextStyle(
                                                                    color: CRMColors.textSecondaryOf(context),
                                                                    fontSize: 10.5,
                                                                  ),
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: CRMSpacing.m),
                              Expanded(
                                child: CRMTextField(
                                  controller: tenantController,
                                  labelText: 'Tenant Name *',
                                  hintText: 'e.g. Rajesh Kumar',
                                  validator: (val) => val == null || val.trim().isEmpty ? 'Tenant name required' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: CRMSpacing.m),
                          Row(
                            children: [
                              Expanded(
                                child: CRMTextField(
                                  controller: ownerController,
                                  labelText: 'Owner Name *',
                                  hintText: 'e.g. Amit Patel',
                                  validator: (val) => val == null || val.trim().isEmpty ? 'Owner name required' : null,
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
                                      value: localType,
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
                                            localType = val;
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
                            hintText: 'Add important notes regarding renewal or clauses...',
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
                                      propController.text.isNotEmpty ||
                                      tenantController.text.isNotEmpty;

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
                                          content: Text('Please select or upload a document file.'),
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
                                            name: nameController.text.trim(),
                                            propertyName: propController.text.trim(),
                                            tenantName: tenantController.text.trim(),
                                            ownerName: ownerController.text.trim(),
                                            documentType: localType,
                                            description: descController.text.trim(),
                                            status: localStatus,
                                            fileSize: localFileSize,
                                            fileExtension: localFileExt,
                                          );
                                        });
                                      }
                                    } else {
                                      final newDoc = RentalDocument(
                                        id: 'rent-${DateTime.now().millisecondsSinceEpoch}',
                                        name: nameController.text.trim(),
                                        propertyName: propController.text.trim(),
                                        tenantName: tenantController.text.trim(),
                                        ownerName: ownerController.text.trim(),
                                        documentType: localType,
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

                                    _updateFilterOptions();
                                    _applyFiltersAndSort();
                                    Navigator.pop(context);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isEditing ? 'Document updated successfully!' : 'Document uploaded successfully!',
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
              isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const LibraryBreadcrumb(currentPageName: 'Rental Library'),
                        Text(
                          'Rental Document Library',
                          style: CRMTypography.pageTitle.copyWith(
                            color: CRMColors.textOf(context),
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Store, filter, and organize rental leasing documents.',
                          style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                        ),
                        const SizedBox(height: CRMSpacing.m),
                        Row(
                          children: [
                            Expanded(
                              child: CRMButton(
                                label: 'Upload Document',
                                prefixIcon: Icons.add_rounded,
                                onPressed: () => _showUploadEditDialog(),
                              ),
                            ),
                            const SizedBox(width: CRMSpacing.s),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: CRMColors.borderOf(context)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: PopupMenuButton<String>(
                                icon: Icon(Icons.download_rounded, color: CRMColors.primaryOf(context)),
                                tooltip: 'Export Index',
                                onSelected: (val) => DocumentExportHelper.triggerExport(context, val),
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'Excel', child: Text('Export to Excel')),
                                  const PopupMenuItem(value: 'PDF', child: Text('Export to PDF')),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const LibraryBreadcrumb(currentPageName: 'Rental Library'),
                              Text(
                                'Rental Document Library',
                                style: CRMTypography.pageTitle.copyWith(color: CRMColors.textOf(context)),
                              ),
                              Text(
                                'Store, filter, and organize rental leasing documents.',
                                style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: CRMSpacing.m),
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
                        title: 'Total Documents',
                        value: '$_totalCount',
                        icon: Icons.folder_rounded,
                        iconColor: CRMColors.primaryOf(context),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: CRMKPICard(
                        title: 'Active Documents',
                        value: '$_activeCount',
                        icon: Icons.check_circle_rounded,
                        iconColor: CRMColors.success,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: CRMKPICard(
                        title: 'Expired Documents',
                        value: '$_expiredCount',
                        icon: Icons.history_rounded,
                        iconColor: CRMColors.danger,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: CRMKPICard(
                        title: 'Recent Uploads (7d)',
                        value: '$_recentCount',
                        icon: Icons.cloud_done_rounded,
                        iconColor: Colors.blue,
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
                      ],
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    LayoutBuilder(
                      builder: (context, filterConstraints) {
                        // Build rental property name suggestions from master list
                        final rentalSuggestions = _masterPropertiesList
                            .where((p) => p.listingTypeName.toLowerCase().contains('rent'))
                            .map((p) => p.title)
                            .toList();

                        final double dropdownSpacing = CRMSpacing.s;

                        return Column(
                          children: [
                            // Row 1: Search field + Reset All button
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Autocomplete<String>(
                                    optionsBuilder: (textEditingValue) {
                                      final query = textEditingValue.text.trim().toLowerCase();
                                      if (query.isEmpty) return const Iterable<String>.empty();
                                      return rentalSuggestions.where(
                                        (name) => name.toLowerCase().contains(query),
                                      );
                                    },
                                    onSelected: (selected) {
                                      _searchController.text = selected;
                                      _applyFiltersAndSort();
                                    },
                                    fieldViewBuilder: (context, autoController, focusNode, onFieldSubmitted) {
                                      return TextField(
                                        controller: autoController,
                                        focusNode: focusNode,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: CRMColors.textOf(context),
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Search by document name, property, tenant, owner...',
                                          hintStyle: TextStyle(fontSize: 13, color: CRMColors.textSecondaryOf(context)),
                                          prefixIcon: Icon(Icons.search_rounded, size: 20, color: CRMColors.primaryOf(context)),
                                          suffixIcon: autoController.text.isNotEmpty
                                              ? IconButton(
                                                  icon: Icon(Icons.close_rounded, size: 16, color: CRMColors.textSecondaryOf(context)),
                                                  onPressed: () {
                                                    autoController.clear();
                                                    _searchController.clear();
                                                    _applyFiltersAndSort();
                                                  },
                                                )
                                              : null,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                          filled: true,
                                          fillColor: CRMColors.backgroundOf(context),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: CRMColors.borderOf(context)),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: CRMColors.borderOf(context)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: CRMColors.primaryOf(context), width: 1.5),
                                          ),
                                        ),
                                        onChanged: (value) {
                                          _searchController.text = value;
                                          _applyFiltersAndSort();
                                        },
                                      );
                                    },
                                    optionsViewBuilder: (context, onSelected, options) {
                                      return Align(
                                        alignment: Alignment.topLeft,
                                        child: Material(
                                          elevation: 6,
                                          borderRadius: BorderRadius.circular(10),
                                          color: CRMColors.surfaceElevatedOf(context),
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(maxHeight: 220),
                                            child: ListView.separated(
                                              padding: const EdgeInsets.symmetric(vertical: 6),
                                              shrinkWrap: true,
                                              itemCount: options.length,
                                              separatorBuilder: (_, __) => Divider(
                                                height: 1,
                                                color: CRMColors.divider.withOpacity(0.5),
                                              ),
                                              itemBuilder: (context, index) {
                                                final option = options.elementAt(index);
                                                final prop = _masterPropertiesList
                                                    .where((p) => p.title == option)
                                                    .firstOrNull;
                                                return InkWell(
                                                  onTap: () => onSelected(option),
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.home_work_rounded, size: 16, color: CRMColors.primaryOf(context)),
                                                        const SizedBox(width: 10),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                option,
                                                                style: TextStyle(
                                                                  fontSize: 13,
                                                                  fontWeight: FontWeight.w600,
                                                                  color: CRMColors.textOf(context),
                                                                ),
                                                              ),
                                                              if (prop != null)
                                                                Text(
                                                                  '${prop.propertyCode} • ${prop.areaName}',
                                                                  style: TextStyle(
                                                                    fontSize: 11,
                                                                    color: CRMColors.textSecondaryOf(context),
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: CRMSpacing.s),
                                // Reset All button — premium UI
                                ElevatedButton.icon(
                                  onPressed: _resetFilters,
                                  icon: const Icon(Icons.refresh_rounded, size: 16),
                                  label: const Text('Reset All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: CRMColors.primaryOf(context),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    elevation: 0,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: CRMSpacing.s),
                            // Row 2: Doc Type + Status dropdowns
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFilterDropdown('Doc Type', _selectedDocType, _docTypes, (val) {
                                    setState(() => _selectedDocType = val!);
                                    _applyFiltersAndSort();
                                  }, 0),
                                ),
                                SizedBox(width: dropdownSpacing),
                                Expanded(
                                  child: _buildFilterDropdown('Status', _selectedStatus, ['All', 'Active', 'Expired', 'Archived'], (val) {
                                    setState(() => _selectedStatus = val!);
                                    _applyFiltersAndSort();
                                  }, 0),
                                ),
                              ],
                            ),
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
                        title: 'No Documents Found',
                        description: 'Try adjusting your search criteria or clear the filters to see all rental files.',
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
                        : CRMDataTable<RentalDocument>(
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
                          CRMColumn<RentalDocument>(
                            label: 'Document Name',
                            sortable: true,
                            sortField: 'name',
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
                                        doc.name,
                                        style: CRMTypography.bodyMedium.copyWith(
                                          fontWeight: FontWeight.bold,
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
                          CRMColumn<RentalDocument>(
                            label: 'Property Name',
                            sortable: true,
                            sortField: 'propertyName',
                            width: 180,
                            cellBuilder: (doc) => Text(doc.propertyName, style: TextStyle(color: CRMColors.textOf(context))),
                          ),
                          CRMColumn<RentalDocument>(
                            label: 'Tenant Name',
                            sortable: true,
                            sortField: 'tenantName',
                            width: 140,
                            cellBuilder: (doc) => Text(doc.tenantName, style: TextStyle(color: CRMColors.textOf(context))),
                          ),
                          CRMColumn<RentalDocument>(
                            label: 'Owner Name',
                            sortable: true,
                            sortField: 'ownerName',
                            width: 140,
                            cellBuilder: (doc) => Text(doc.ownerName, style: TextStyle(color: CRMColors.textOf(context))),
                          ),
                          CRMColumn<RentalDocument>(
                            label: 'Document Type',
                            sortable: true,
                            sortField: 'documentType',
                            width: 150,
                            cellBuilder: (doc) => Text(doc.documentType, style: TextStyle(color: CRMColors.textOf(context))),
                          ),
                          CRMColumn<RentalDocument>(
                            label: 'Upload Date',
                            sortable: true,
                            sortField: 'uploadDate',
                            width: 120,
                            cellBuilder: (doc) => Text(
                              DateFormat('dd MMM yyyy').format(doc.uploadDate),
                              style: TextStyle(color: CRMColors.textOf(context)),
                            ),
                          ),
                          CRMColumn<RentalDocument>(
                            label: 'Uploaded By',
                            width: 110,
                            cellBuilder: (doc) => Text(doc.uploadedBy, style: TextStyle(color: CRMColors.textOf(context))),
                          ),
                          CRMColumn<RentalDocument>(
                            label: 'Status',
                            sortable: true,
                            sortField: 'status',
                            width: 110,
                            cellBuilder: (doc) => CRMStatusChip(status: doc.status.displayName),
                          ),
                          CRMColumn<RentalDocument>(
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
    final child = DropdownButtonFormField<String>(
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
    );
    if (width > 0) {
      return SizedBox(width: width, child: child);
    }
    return child;
  }

  Widget _buildMobileDocumentCard(RentalDocument doc) {
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
                      doc.name,
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
          _buildMobileDetailItem('Property Name', doc.propertyName),
          _buildMobileDetailItem('Tenant Name', doc.tenantName),
          _buildMobileDetailItem('Owner Name', doc.ownerName),
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
