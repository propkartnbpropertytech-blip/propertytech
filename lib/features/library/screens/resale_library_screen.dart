import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/tokens/app_breakpoints.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/crm_status_chips.dart';
import '../../../core/design_system/widgets/dialogs.dart';
import '../../../core/design_system/widgets/inputs.dart';
import '../models/document_model.dart';
import '../widgets/library_vault/library_vault_tokens.dart';
import '../widgets/library_vault/library_vault_widgets.dart';
import 'library_widgets.dart';
import '../../properties/models/property_model.dart';
import '../repository/library_repository.dart';

class ResaleLibraryScreen extends StatefulWidget {
  final Map<String, dynamic>? initialArgs;
  const ResaleLibraryScreen({super.key, this.initialArgs});

  @override
  State<ResaleLibraryScreen> createState() => _ResaleLibraryScreenState();
}

class _ResaleLibraryScreenState extends State<ResaleLibraryScreen> {
  // Local list representing the DB
  late List<ResaleDocument> _allDocuments;
  List<ResaleDocument> _filteredDocuments = [];

  // Table parameters
  String? _sortField = 'uploadDate';
  bool _sortAscending = false;
  int _currentPage = 1;
  int _pageSize = 10;

  // Filter controllers
  final TextEditingController _searchController = TextEditingController();
  String _selectedProperty = 'All';
  String _selectedSeller = 'All';
  String _selectedBuyer = 'All';
  String _selectedDocType = 'All';
  String _selectedStatus = 'All';
  DateTimeRange? _selectedDateRange;

  List<PropertyModel> _masterPropertiesList = [];

  // Autocomplete suggestions
  List<String> _properties = ['All'];
  final List<String> _docTypes = [
    'All',
    'Sale Agreement',
    'Sale Deed',
    'Property Documents',
    'Tax Receipt',
    'NOC',
    'Floor Plan',
    'Property Photos',
    'Property Video',
    'Loan Documents',
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
    _allDocuments = ResaleDocument.getMockData();
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

  Future<void> _loadMasterProperties({bool forceRefresh = false}) async {
    try {
      final list = await LibraryRepository().getMasterProperties(forceRefresh: forceRefresh);
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
    });
  }

  void _applyFiltersAndSort() {
    List<ResaleDocument> temp = List.from(_allDocuments);

    // Search — matches document name, property name, seller name, buyer name
    final searchQuery = _searchController.text.trim().toLowerCase();
    if (searchQuery.isNotEmpty) {
      temp = temp.where((doc) =>
        doc.name.toLowerCase().contains(searchQuery) ||
        doc.propertyName.toLowerCase().contains(searchQuery) ||
        doc.sellerName.toLowerCase().contains(searchQuery) ||
        doc.buyerName.toLowerCase().contains(searchQuery)
      ).toList();
    }

    // Property Filter
    if (_selectedProperty != 'All') {
      temp = temp.where((doc) => doc.propertyName == _selectedProperty).toList();
    }

    // Seller Filter
    if (_selectedSeller != 'All') {
      temp = temp.where((doc) => doc.sellerName == _selectedSeller).toList();
    }

    // Buyer Filter
    if (_selectedBuyer != 'All') {
      temp = temp.where((doc) => doc.buyerName == _selectedBuyer).toList();
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
          case 'sellerName':
            valA = a.sellerName.toLowerCase();
            valB = b.sellerName.toLowerCase();
            break;
          case 'buyerName':
            valA = a.buyerName.toLowerCase();
            valB = b.buyerName.toLowerCase();
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
      _selectedSeller = 'All';
      _selectedBuyer = 'All';
      _selectedDocType = 'All';
      _selectedStatus = 'All';
      _selectedDateRange = null;
    });
    _applyFiltersAndSort();
  }

  // Summary Metrics
  int get _totalCount => _allDocuments.length;
  int get _activeCount => _allDocuments.where((d) => d.status == DocumentStatus.active).length;
  int get _soldCount => _allDocuments.where((d) => d.status == DocumentStatus.archived).length;
  int get _recentCount => _allDocuments.where((d) => d.uploadDate.isAfter(DateTime.now().subtract(const Duration(days: 7)))).length;

  // Pagination helper
  List<ResaleDocument> get _paginatedDocuments {
    int start = (_currentPage - 1) * _pageSize;
    int end = start + _pageSize;
    if (start >= _filteredDocuments.length) return [];
    if (end > _filteredDocuments.length) end = _filteredDocuments.length;
    return _filteredDocuments.sublist(start, end);
  }

  int get _totalPages => (_filteredDocuments.length / _pageSize).ceil();

  // Action methods
  void _viewDocument(ResaleDocument doc) {
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
                  _buildDetailRow(context, 'Seller Name:', doc.sellerName),
                  _buildDetailRow(context, 'Buyer Name:', doc.buyerName),
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
                                  'Play property walkthrough video',
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

  void _downloadDocument(ResaleDocument doc) async {
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
          content: Text('${doc.name} successfully saved to download folder!'),
          backgroundColor: CRMColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _shareDocument(ResaleDocument doc) {
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
                    subtitle: Text('To buyer/seller contacts'),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Document emailed to ${doc.buyerName}!'),
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

  void _deleteDocument(ResaleDocument doc) async {
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

  void _showUploadEditDialog([ResaleDocument? existingDoc, String? defaultClientName]) {
    final isEditing = existingDoc != null;
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(text: existingDoc?.name);
    final propController = TextEditingController(text: existingDoc?.propertyName);
    final sellerController = TextEditingController(text: existingDoc?.sellerName);
    final buyerController = TextEditingController(text: existingDoc?.buyerName ?? defaultClientName);
    final descController = TextEditingController(text: existingDoc?.description);

    String localType = existingDoc?.documentType ?? 'Sale Agreement';
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
                                isEditing ? 'Edit Resale Document' : 'Upload Resale Document',
                                style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () async {
                                  final nameVal = nameController.text;
                                  final hasInput = nameVal.isNotEmpty ||
                                      propController.text.isNotEmpty ||
                                      sellerController.text.isNotEmpty;

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
                            hintText: 'e.g. Registered Sale Deed',
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
                                    final saleProperties = _masterPropertiesList
                                        .where((p) => !p.listingTypeName.toLowerCase().contains('rent'))
                                        .map((p) => p.title)
                                        .toSet()
                                        .toList();
                                    final source = saleProperties.isNotEmpty ? saleProperties : _properties.where((p) => p != 'All').toList();
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
                                      hintText: 'e.g. DLF CyberCity Suite',
                                      validator: (val) => val == null || val.trim().isEmpty ? 'Property name required' : null,
                                    );
                                  },
                                  onSelected: (String selection) {
                                    setModalState(() {
                                      propController.text = selection;
                                      final matches = _masterPropertiesList.where((p) => p.title == selection);
                                      if (matches.isNotEmpty) {
                                        sellerController.text = matches.first.ownerName;
                                      } else {
                                        final docMatches = _allDocuments.where((d) => d.propertyName == selection);
                                        if (docMatches.isNotEmpty) {
                                          sellerController.text = docMatches.first.sellerName;
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
                                  controller: sellerController,
                                  labelText: 'Seller Name *',
                                  hintText: 'e.g. Vikram Seth',
                                  validator: (val) => val == null || val.trim().isEmpty ? 'Seller name required' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: CRMSpacing.m),
                          Row(
                            children: [
                              Expanded(
                                child: CRMTextField(
                                  controller: buyerController,
                                  labelText: 'Buyer Name *',
                                  hintText: 'e.g. Aditya Birla',
                                  validator: (val) => val == null || val.trim().isEmpty ? 'Buyer name required' : null,
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
                            hintText: 'Add description, NOC approval codes or loan tracking IDs...',
                            maxLines: 2,
                          ),
                          const SizedBox(height: CRMSpacing.m),
                          DragDropUploadZone(
                            initialFileName: localFileName,
                            initialFileSize: localFileSize,
                            onFileSelected: (name, ext, size, fileUrl) {
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
                                  Text('Archived (Sold)', style: TextStyle(color: CRMColors.textOf(context))),
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
                                      sellerController.text.isNotEmpty;

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
                                          content: Text('Please upload or drag & drop a file.'),
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
                                            sellerName: sellerController.text.trim(),
                                            buyerName: buyerController.text.trim(),
                                            documentType: localType,
                                            description: descController.text.trim(),
                                            status: localStatus,
                                            fileSize: localFileSize,
                                            fileExtension: localFileExt,
                                          );
                                        });
                                      }
                                    } else {
                                      final newDoc = ResaleDocument(
                                        id: 'sale-${DateTime.now().millisecondsSinceEpoch}',
                                        name: nameController.text.trim(),
                                        propertyName: propController.text.trim(),
                                        sellerName: sellerController.text.trim(),
                                        buyerName: buyerController.text.trim(),
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
                                          isEditing ? 'Document info saved successfully!' : 'Document uploaded successfully!',
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

  // ───────────────────────── New_UI vault shell ─────────────────────────────

  /// Selected KPI card (0 total, 1 active, 2 archived/sold, 3 recent uploads).
  int? _selectedKpi;

  void _onKpiTap(int index) {
    final deselect = _selectedKpi == index;
    setState(() {
      _selectedKpi = deselect ? null : index;
      _selectedStatus = 'All';
      _selectedDateRange = null;
      if (!deselect) {
        if (index == 1) _selectedStatus = 'Active';
        if (index == 2) _selectedStatus = 'Archived';
        if (index == 3) {
          final now = DateTime.now();
          _selectedDateRange = DateTimeRange(
            start: now.subtract(const Duration(days: 6)),
            end: now,
          );
        }
      }
    });
    _applyFiltersAndSort();
  }

  void _onResetAll() {
    setState(() => _selectedKpi = null);
    _resetFilters();
  }

  void _onSort(String field) {
    setState(() {
      if (_sortField == field) {
        _sortAscending = !_sortAscending;
      } else {
        _sortField = field;
        _sortAscending = true;
      }
    });
    _applyFiltersAndSort();
  }

  Widget _buildRowActions(ResaleDocument doc) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LvIconAction(
          icon: Icons.visibility_outlined,
          tooltip: 'Preview',
          onTap: () => _viewDocument(doc),
        ),
        LvIconAction(
          icon: Icons.file_download_outlined,
          tooltip: 'Download',
          onTap: () => _downloadDocument(doc),
        ),
        LvIconAction(
          icon: Icons.edit_outlined,
          tooltip: 'Edit',
          onTap: () => _showUploadEditDialog(doc),
        ),
        LvIconAction(
          icon: Icons.share_outlined,
          tooltip: 'Share',
          onTap: () => _shareDocument(doc),
        ),
        LvIconAction(
          icon: Icons.delete_outline_rounded,
          tooltip: 'Delete',
          danger: true,
          onTap: () => _deleteDocument(doc),
        ),
      ],
    );
  }

  List<LvKpiItem> _buildKpis() {
    return [
      LvKpiItem(
        icon: Icons.description_outlined,
        label: 'Total documents',
        value: '$_totalCount',
        hint: 'All sale paperwork',
        selected: _selectedKpi == 0,
        onTap: () => _onKpiTap(0),
      ),
      LvKpiItem(
        icon: Icons.check_circle_outline_rounded,
        label: 'Active',
        value: '$_activeCount',
        hint: 'Live deals ready to close',
        selected: _selectedKpi == 1,
        onTap: () => _onKpiTap(1),
      ),
      LvKpiItem(
        icon: Icons.flag_outlined,
        label: 'Sold property docs',
        value: '$_soldCount',
        hint: 'Kept for compliance',
        selected: _selectedKpi == 2,
        onTap: () => _onKpiTap(2),
      ),
      LvKpiItem(
        icon: Icons.cloud_upload_outlined,
        label: 'Uploaded this week',
        value: '$_recentCount',
        hint: 'Keeps deals moving',
        selected: _selectedKpi == 3,
        onTap: () => _onKpiTap(3),
      ),
    ];
  }

  List<LvChecklistItem> _buildChecklist() {
    final types = _allDocuments.map((d) => d.documentType).toList();
    return [
      LvChecklistItem(
        label: 'Sale deeds & agreements',
        count: lvCountByKeywords(types, ['deed', 'agreement']),
      ),
      LvChecklistItem(
        label: 'Legal documents',
        count: lvCountByKeywords(types, ['legal', 'title', 'property document']),
      ),
      LvChecklistItem(
        label: 'Society NOCs & floor plans',
        count: lvCountByKeywords(types, ['noc', 'floor']),
      ),
      LvChecklistItem(
        label: 'Tax & municipal receipts',
        count: lvCountByKeywords(types, ['tax', 'municipal', 'receipt']),
      ),
      LvChecklistItem(
        label: 'Home loan approvals',
        count: lvCountByKeywords(types, ['loan', 'sanction']),
      ),
    ];
  }

  List<LvColumn<ResaleDocument>> _buildColumns() {
    return [
      LvColumn<ResaleDocument>(
        label: 'Document',
        flex: 4,
        sortField: 'name',
        cell: (context, d) => LvDocNameCell(
          extension: d.fileExtension,
          name: d.name,
          size: d.fileSize,
        ),
      ),
      LvColumn<ResaleDocument>(
        label: 'Property',
        flex: 3,
        sortField: 'propertyName',
        cell: (context, d) => LvCellText(primary: d.propertyName),
      ),
      LvColumn<ResaleDocument>(
        label: 'Buyer · Seller',
        flex: 3,
        sortField: 'buyerName',
        cell: (context, d) => LvCellText(primary: d.buyerName, secondary: d.sellerName),
      ),
      LvColumn<ResaleDocument>(
        label: 'Type',
        flex: 2,
        sortField: 'documentType',
        cell: (context, d) => LvTagPill(label: d.documentType),
      ),
      LvColumn<ResaleDocument>(
        label: 'Uploaded',
        flex: 2,
        sortField: 'uploadDate',
        cell: (context, d) => LvCellText(
          primary: DateFormat('dd MMM yyyy').format(d.uploadDate),
          secondary: 'by ${d.uploadedBy}',
        ),
      ),
      LvColumn<ResaleDocument>(
        label: 'Status',
        flex: 2,
        sortField: 'status',
        cell: (context, d) => LvStatusPill(label: d.status.displayName),
      ),
    ];
  }

  Widget _buildMainPanel(bool isPhone) {
    final resaleSuggestions = _masterPropertiesList
        .where((p) => !p.listingTypeName.toLowerCase().contains('rent'))
        .map((p) => p.title)
        .toList();

    final filterBar = LvFilterBar(
      searchController: _searchController,
      searchHint: 'Document, property or person',
      searchSuggestions: resaleSuggestions,
      onSuggestionSelected: (_) => _applyFiltersAndSort(),
      onSearchChanged: (_) => _applyFiltersAndSort(),
      dropdowns: [
        LvDropdownField(
          label: 'Document type',
          value: _selectedDocType,
          items: _docTypes,
          onChanged: (v) {
            if (v == null) return;
            setState(() => _selectedDocType = v);
            _applyFiltersAndSort();
          },
        ),
        LvDropdownField(
          label: 'Status',
          value: _selectedStatus,
          items: const ['All', 'Active', 'Expired', 'Archived'],
          onChanged: (v) {
            if (v == null) return;
            setState(() {
              _selectedStatus = v;
              if (_selectedKpi != 3) _selectedKpi = null;
            });
            _applyFiltersAndSort();
          },
        ),
      ],
      onReset: _onResetAll,
    );

    final footerLabel = _filteredDocuments.length == _allDocuments.length
        ? 'Showing ${_paginatedDocuments.length} of ${_filteredDocuments.length} documents'
        : 'Showing ${_paginatedDocuments.length} of ${_filteredDocuments.length} documents · ${_allDocuments.length} total';

    final footer = LvPanelFooter(
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
        _applyFiltersAndSort();
      },
    );

    Widget body;
    if (_filteredDocuments.isEmpty) {
      body = LvEmpty(
        title: 'No documents match',
        message: 'Try another type or status.',
        actionLabel: 'Reset filters',
        onAction: _onResetAll,
      );
    } else if (isPhone) {
      body = Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
        child: Column(
          children: [
            for (final doc in _paginatedDocuments)
              LvDocMobileCard(
                extension: doc.fileExtension,
                name: doc.name,
                subtitle: '${doc.fileSize} • ${doc.documentType}',
                statusLabel: doc.status.displayName,
                details: [
                  MapEntry('Property', doc.propertyName),
                  MapEntry('Buyer', doc.buyerName),
                  MapEntry('Seller', doc.sellerName),
                  MapEntry('Uploaded', '${DateFormat('dd MMM yyyy').format(doc.uploadDate)} by ${doc.uploadedBy}'),
                ],
                actions: _buildRowActions(doc),
              ),
          ],
        ),
      );
    } else {
      body = LvDocTable<ResaleDocument>(
        columns: _buildColumns(),
        items: _paginatedDocuments,
        actionsBuilder: (context, doc) => _buildRowActions(doc),
        actionsWidth: 176,
        sortField: _sortField,
        sortAscending: _sortAscending,
        onSort: _onSort,
      );
    }

    return LvPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [filterBar, body, footer],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = CRMBreakpoints.isPhone(context);

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
                child: LvBreadcrumb(vaultName: 'Re-Sale Library'),
              ),
              const SizedBox(height: 16),
              LvHero(
                icon: Icons.sell_rounded,
                title: 'Re-Sale Library',
                subtitle: 'Sale deeds, NOCs, floor plans, tax and loan papers for properties being sold.',
                onExport: (format) => DocumentExportHelper.triggerExport(context, format),
                primaryLabel: 'Upload document',
                onPrimary: () => _showUploadEditDialog(),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: LvVaultTabs(current: LvVault.resale),
              ),
              const SizedBox(height: 16),
              LvKpiStrip(items: _buildKpis()),
              const SizedBox(height: 16),
              LvChecklist(items: _buildChecklist()),
              const SizedBox(height: 16),
              _buildMainPanel(isPhone),
            ],
          ),
        ),
      ),
    );
  }
}
