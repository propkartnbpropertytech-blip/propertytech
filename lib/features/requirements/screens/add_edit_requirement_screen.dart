import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/requirements_bloc.dart';
import '../models/requirement_model.dart';
import '../../properties/repository/properties_repository.dart';
import '../../properties/models/property_model.dart';
import '../../../core/design_system/crm_design_system.dart';
import '../../../core/storage/crm_draft_repository.dart';
import '../../owners/repository/owners_repository.dart';
import '../../owners/models/owner_model.dart';
import '../../requirements/repository/requirements_repository.dart';
import '../../../core/storage/repository_coordinator.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/models/user_model.dart';
import '../../../core/design_system/widgets/form/crm_multi_select_dropdown.dart';
import '../../settings/screens/location_config_screen.dart';
import '../../properties/services/properties_service.dart';
import 'package:dio/dio.dart';

class AddEditRequirementScreen extends StatefulWidget {
  final RequirementModel? requirement;
  final VoidCallback onSaved;
  final bool isInline;

  const AddEditRequirementScreen({
    super.key,
    this.requirement,
    required this.onSaved,
    this.isInline = false,
  });

  @override
  State<AddEditRequirementScreen> createState() => _AddEditRequirementScreenState();
}

class _AddEditRequirementScreenState extends State<AddEditRequirementScreen> {
  final _formKey = GlobalKey<FormState>();
  final PropertiesRepository _propertiesRepository = PropertiesRepository();
  late PageController _pageController;
  int _activeStep = 0;

  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _budgetController = TextEditingController();
  final _minAreaController = TextEditingController();
  final _maxAreaController = TextEditingController();
  final _remarksController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedTypeId;
  final List<String> _selectedTypeIds = [];
  List<LookupItem> _cities = [];
  String? _selectedConfigId;
  final List<String> _selectedConfigIds = [];
  String? _selectedListingTypeId;
  final List<String> _selectedFurnishingIds = [];
  final List<String> _selectedFacingIds = [];
  String _selectedStatus = "Not Started";
  final List<String> _selectedAreaIds = [];
  String _areaSearchQuery = '';
  String? _customerFoundMessage;
  bool _isSaved = false;

  bool _isLoadingMetadata = true;
  List<LookupItem> _categories = [];
  List<LookupItem> _types = [];
  List<LookupItem> _configurations = [];
  List<AreaLookup> _areas = [];
  List<LookupItem> _listingTypes = [];
  List<LookupItem> _furnishings = [];
  List<LookupItem> _facings = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _mobileController.addListener(_handleMobileChange);
    _loadMetadata();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.requirement == null && CRMDraftRepository().hasDraft('requirement')) {
        _showRestoreDraftDialog();
      }
    });
  }

  @override
  void dispose() {
    _mobileController.removeListener(_handleMobileChange);
    _nameController.dispose();
    _mobileController.dispose();
    _budgetController.dispose();
    _minAreaController.dispose();
    _maxAreaController.dispose();
    _remarksController.dispose();
    _pageController.dispose();
    if (!_isSaved && widget.requirement == null) {
      _saveCurrentDraft();
    }
    super.dispose();
  }

  Future<void> _refreshLocationMetadata() async {
    try {
      final service = PropertiesService();
      final response = await service.getPropertyMetadata();
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final meta = PropertyMetadataModel.fromJson(data['metadata'] ?? {});
      
      final oldAreaIds = _areas.map((a) => a.id).toSet();
      final newAreas = meta.areas;
      
      setState(() {
        _areas = newAreas;
        
        // Auto-select the newly created area(s)
        final addedAreas = newAreas.where((a) => !oldAreaIds.contains(a.id)).toList();
        for (final area in addedAreas) {
          if (!_selectedAreaIds.contains(area.id)) {
            _selectedAreaIds.add(area.id);
          }
        }
      });
    } catch (_) {
      // Fail silently
    }
  }

  Future<void> _loadMetadata() async {
    try {
      final metadata = await _propertiesRepository.getPropertyMetadata();
      setState(() {
        _categories = metadata.categories;
        _types = metadata.types;
        _configurations = metadata.configurations;
        _areas = metadata.areas;
        _listingTypes = metadata.listingTypes;
        _furnishings = metadata.furnishings;
        _facings = metadata.facings;
        _cities = metadata.cities;
        
        if (widget.requirement == null) {
          if (_categories.isNotEmpty) {
            _selectedCategoryId = _categories.first.id;
            final firstCatTypes = _types.where((t) => t.categoryId == _selectedCategoryId && t.name.toLowerCase() != 'apartment').toList();
            if (firstCatTypes.isNotEmpty) {
              _selectedTypeId = firstCatTypes.first.id;
              _selectedTypeIds.add(firstCatTypes.first.id);
            }
          }
          if (_listingTypes.isNotEmpty) _selectedListingTypeId = _listingTypes.first.id;
        } else {
          final req = widget.requirement!;
          _nameController.text = req.clientName;
          _mobileController.text = req.clientMobile;
          final double avgBudget = req.minBudget == req.maxBudget ? req.minBudget : (req.minBudget + req.maxBudget) / 2;
          _budgetController.text = CRMCurrencyFormatter.format(avgBudget);
          _minAreaController.text = req.minArea?.toStringAsFixed(0) ?? '';
          _maxAreaController.text = req.maxArea?.toStringAsFixed(0) ?? '';
          _remarksController.text = req.remarks ?? '';
          _selectedCategoryId = req.categoryId;
          _selectedTypeId = req.propertyTypeId;
          _selectedTypeIds.addAll(req.propertyTypeIds);
          if (_selectedTypeIds.isEmpty && req.propertyTypeId != null && req.propertyTypeId!.isNotEmpty) {
            _selectedTypeIds.add(req.propertyTypeId!);
          }
          _selectedConfigId = req.configurationId;
          _selectedConfigIds.addAll(req.configurationIds);
          if (_selectedConfigIds.isEmpty && req.configurationId != null) {
            _selectedConfigIds.add(req.configurationId!);
          }
          _selectedListingTypeId = req.listingTypeId;
          _selectedFurnishingIds.addAll(req.furnishingIds);
          _selectedFacingIds.addAll(req.facingIds);
          
          String statusVal = req.status;
          if (statusVal == 'Active' || statusVal == 'Live') statusVal = 'Interested';
          if (statusVal == 'Closed' || statusVal == 'Won') statusVal = 'Won';
          if (statusVal == 'Suspended' || statusVal == 'Dead') statusVal = 'Not Interested';
          _selectedStatus = statusVal;

          _selectedAreaIds.addAll(req.areaIds);
        }
        
        _isLoadingMetadata = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMetadata = false;
      });
    }
  }

  void _showAddAreaDialog() {
    if (_cities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No cities available. Please add a city first.')),
      );
      return;
    }

    String? dialogSelectedCityId = _cities.first.id;
    final nameController = TextEditingController();
    final pincodeController = TextEditingController();
    bool isFetching = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          Future<void> lookupPincode(String pincode) async {
            setState(() => isFetching = true);
            try {
              final dio = Dio();
              final response = await dio.get('https://api.postalpincode.in/pincode/$pincode');
              if (response.statusCode == 200 && response.data is List && response.data.isNotEmpty) {
                final data = response.data[0] as Map<String, dynamic>;
                final status = data['Status']?.toString();
                final postOffices = data['PostOffice'] as List?;
                if (status == 'Success' && postOffices != null && postOffices.isNotEmpty) {
                  final firstOffice = postOffices[0] as Map<String, dynamic>;
                  final name = firstOffice['Name']?.toString() ?? '';
                  if (name.isNotEmpty) {
                    nameController.text = name;
                  }
                }
              }
            } catch (_) {
              // Fail silently
            } finally {
              setState(() => isFetching = false);
            }
          }

          return AlertDialog(
            backgroundColor: CRMColors.cardBgOf(context),
            title: const Text('Add New Area'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: dialogSelectedCityId,
                  decoration: const InputDecoration(labelText: 'City *'),
                  items: _cities.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (v) => setState(() => dialogSelectedCityId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Area Name *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pincodeController,
                  decoration: InputDecoration(
                    labelText: 'Pincode (6 Digits) *',
                    suffixIcon: isFetching
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onChanged: (v) {
                    final pincode = v.trim();
                    if (pincode.length == 6 && !isFetching) {
                      lookupPincode(pincode);
                    }
                  },
                  onSubmitted: (v) {
                    final pincode = v.trim();
                    if (pincode.length == 6 && !isFetching) {
                      lookupPincode(pincode);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(ctx),
              ),
              TextButton(
                child: const Text('Add'),
                onPressed: () async {
                  final name = nameController.text.trim();
                  final pincode = pincodeController.text.trim();
                  if (name.isNotEmpty && pincode.isNotEmpty && dialogSelectedCityId != null) {
                    try {
                      final service = PropertiesService();
                      final result = await service.createArea(dialogSelectedCityId!, name, pincode);
                      final AreaLookup newArea = AreaLookup(
                        id: result['data']['area']['id'],
                        name: result['data']['area']['area_name'],
                        cityId: result['data']['area']['city_id'],
                        pincode: result['data']['area']['pincode'],
                      );
                      this.setState(() {
                        _areas.add(newArea);
                        _selectedAreaIds.add(newArea.id);
                      });
                      if (mounted) Navigator.pop(ctx);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to add area: $e')),
                      );
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _saveCurrentDraft() {
    if (widget.requirement != null) return;
    final draftData = {
      'activeStep': _activeStep,
      'clientName': _nameController.text,
      'clientMobile': _mobileController.text,
      'category_id': _selectedCategoryId,
      'property_type_id': _selectedTypeId,
      'property_type_ids': _selectedTypeIds,
      'configuration_id': _selectedConfigId,
      'configuration_ids': _selectedConfigIds,
      'listing_type_id': _selectedListingTypeId,
      'budget': _budgetController.text,
      'minArea': _minAreaController.text,
      'maxArea': _maxAreaController.text,
      'remarks': _remarksController.text,
      'status': _selectedStatus,
      'areaIds': _selectedAreaIds,
      'furnishings': _selectedFurnishingIds,
      'facings': _selectedFacingIds,
    };
    CRMDraftRepository().saveDraft('requirement', draftData);
  }

  void _showRestoreDraftDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CRMColors.cardBg,
        title: Text('Restore Unsaved Draft?', style: TextStyle(color: CRMColors.textOf(ctx))),
        content: Text('We found an unsaved draft from your previous session. Would you like to restore it?', style: TextStyle(color: CRMColors.textSecondaryOf(ctx))),
        actions: [
          TextButton(
            child: const Text('Discard'),
            onPressed: () {
              CRMDraftRepository().clearDraft('requirement');
              Navigator.pop(ctx);
            },
          ),
          TextButton(
            child: const Text('Restore'),
            onPressed: () {
              final draft = CRMDraftRepository().getDraft('requirement');
              if (draft != null) {
                setState(() {
                  _activeStep = draft['activeStep'] ?? 0;
                  _nameController.text = draft['clientName'] ?? '';
                  _mobileController.text = draft['clientMobile'] ?? '';
                  _selectedCategoryId = draft['category_id'];
                  _selectedTypeId = draft['property_type_id'];
                  final List<String> types = List<String>.from(draft['property_type_ids'] ?? []);
                  _selectedTypeIds.clear();
                  _selectedTypeIds.addAll(types);
                  _selectedConfigId = draft['configuration_id'];
                  final List<String> configs = List<String>.from(draft['configuration_ids'] ?? []);
                  _selectedConfigIds.clear();
                  _selectedConfigIds.addAll(configs);
                  _selectedListingTypeId = draft['listing_type_id'];
                  _budgetController.text = draft['budget'] ?? '';
                  _minAreaController.text = draft['minArea'] ?? '';
                  _maxAreaController.text = draft['maxArea'] ?? '';
                  _remarksController.text = draft['remarks'] ?? '';
                  _selectedStatus = draft['status'] ?? 'Not Started';
                  
                  final List<String> areas = List<String>.from(draft['areaIds'] ?? []);
                  _selectedAreaIds.clear();
                  _selectedAreaIds.addAll(areas);
                  _selectedFurnishingIds.clear();
                  _selectedFurnishingIds.addAll(List<String>.from(draft['furnishings'] ?? []));
                  _selectedFacingIds.clear();
                  _selectedFacingIds.addAll(List<String>.from(draft['facings'] ?? []));
                });
                if (_pageController.hasClients) {
                  _pageController.jumpToPage(_activeStep);
                }
              }
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _handleMobileChange() {
    _onMobileChanged(_mobileController.text);
  }

  Future<void> _onMobileChanged(String mobile) async {
    if (mobile.length < 10) {
      setState(() {
        _customerFoundMessage = null;
      });
      return;
    }
    
    // 1. Search Owners repository
    try {
      final owners = await OwnersRepository().getOwners();
      final cleanMobile = mobile.replaceAll(RegExp(r'\D'), '');
      final matchedOwner = owners.firstWhere(
        (o) => o.mobile.replaceAll(RegExp(r'\D'), '').contains(cleanMobile),
        orElse: () => OwnerModel(id: '', name: '', mobile: '', email: '', createdAt: DateTime.now()),
      );
      
      if (matchedOwner.id.isNotEmpty) {
        setState(() {
          _nameController.text = matchedOwner.name;
          _customerFoundMessage = "🟢 Found in Contacts: ${matchedOwner.name}";
        });
        return;
      }
    } catch (_) {}
    
    // 2. Search existing local requirements
    try {
      final reqs = await RequirementsRepository().getRequirements();
      final cleanMobile = mobile.replaceAll(RegExp(r'\D'), '');
      final matchedReq = reqs.firstWhere(
        (r) => r.clientMobile.replaceAll(RegExp(r'\D'), '').contains(cleanMobile),
        orElse: () => RequirementModel(
          id: '', clientName: '', clientMobile: '', categoryId: '', categoryName: '',
          propertyTypeId: '', propertyTypeName: '', minBudget: 0, maxBudget: 0,
          areaIds: [], areaNames: [], status: '', createdAt: DateTime.now()
        ),
      );
      
      if (matchedReq.id.isNotEmpty) {
        setState(() {
          _nameController.text = matchedReq.clientName;
          _customerFoundMessage = "🔵 Found in Requirements: ${matchedReq.clientName}";
        });
        return;
      }
    } catch (_) {}
    
    setState(() {
      _customerFoundMessage = null;
    });
  }

  List<LookupItem> _getFilteredTypes() {
    if (_selectedCategoryId == null) return [];
    return _types
        .where((t) => t.categoryId == _selectedCategoryId && t.name.toLowerCase() != 'apartment')
        .toList();
  }

  List<LookupItem> _getFilteredConfigs() {
    if (_selectedCategoryId == null) return [];
    return _configurations.where((c) => c.categoryId == _selectedCategoryId).toList();
  }

  bool _validateStatusTransition(String newStatus) {
    return true;
  }

  void _submitForm() async {
    if (_nameController.text.trim().isEmpty || _mobileController.text.trim().isEmpty) {
      _jumpToStep(0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill Customer Name and Mobile."), backgroundColor: CRMColors.danger),
      );
      return;
    }

    if (_selectedListingTypeId == null) {
      _jumpToStep(1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a Listing Type (Rent or Re-Sale)."), backgroundColor: CRMColors.danger),
      );
      return;
    }

    if (_selectedCategoryId == null || _selectedTypeId == null) {
      _jumpToStep(2);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a Category and Property Type."), backgroundColor: CRMColors.danger),
      );
      return;
    }

    if (_selectedAreaIds.isEmpty) {
      _jumpToStep(3);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one Target Area."), backgroundColor: CRMColors.danger),
      );
      return;
    }

    if (_budgetController.text.isEmpty) {
      _jumpToStep(4);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a Target Budget."), backgroundColor: CRMColors.danger),
      );
      return;
    }

    final clientName = _nameController.text.trim().toLowerCase();
    final clientMobile = _mobileController.text.trim().toLowerCase();

    if (clientName.isNotEmpty && clientMobile.isNotEmpty) {
      try {
        final allReqs = await RepositoryCoordinator().requirementLocal.getRequirements();
        final isDuplicate = allReqs.any((r) =>
          r.id != widget.requirement?.id &&
          r.clientName.toLowerCase() == clientName &&
          r.clientMobile == clientMobile
        );
        if (isDuplicate) {
          if (mounted) {
            final proceed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.card)),
                backgroundColor: CRMColors.surfaceElevatedOf(context),
                title: Text('Duplicate Requirement Detected', style: CRMTypography.sectionTitle),
                content: Text(
                  'A requirement for client "${_nameController.text}" with mobile number "${_mobileController.text}" already exists.\n\nAre you sure you want to save this duplicate requirement?',
                  style: CRMTypography.body,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Save Anyway'),
                  ),
                ],
              ),
            );
            if (proceed != true) return;
          }
        }
      } catch (e) {
        print("⚠️ [DUPLICATE CHECK ERROR] $e");
      }
    }

    final cat = _categories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => LookupItem(id: '', name: 'N/A'),
    );
    final type = _types.firstWhere(
      (t) => t.id == _selectedTypeId,
      orElse: () => LookupItem(id: '', name: 'N/A'),
    );
    final configNames = _selectedConfigIds.map((id) {
      final match = _configurations.firstWhere((c) => c.id == id, orElse: () => LookupItem(id: id, name: id));
      return match.name;
    }).toList();
    final listingType = _listingTypes.firstWhere(
      (lt) => lt.id == _selectedListingTypeId,
      orElse: () => LookupItem(id: '', name: 'N/A'),
    );

    final List<String> areaNames = _selectedAreaIds.map((id) {
      final match = _areas.firstWhere((a) => a.id == id, orElse: () => AreaLookup(id: id, name: id, cityId: '', pincode: ''));
      return match.name;
    }).toList();

    final authState = context.read<AuthBloc>().state;
    UserModel? currentUser;
    if (authState is Authenticated) {
      currentUser = authState.user;
    }

    final budgetVal = CRMCurrencyFormatter.parse(_budgetController.text);
    final minBudget = budgetVal * 0.8;
    final maxBudget = budgetVal * 1.2;

    final req = RequirementModel(
      id: widget.requirement?.id ?? '',
      clientName: _nameController.text.trim(),
      clientMobile: _mobileController.text.trim(),
      categoryId: _selectedCategoryId ?? '',
      categoryName: cat.name,
      propertyTypeId: _selectedTypeId ?? '',
      propertyTypeName: type.name,
      propertyTypeIds: _selectedTypeIds,
      configurationId: _selectedConfigId,
      configurationIds: _selectedConfigIds,
      configurationName: configNames.isNotEmpty ? configNames.join(', ') : null,
      listingTypeId: _selectedListingTypeId,
      listingTypeName: listingType.id.isNotEmpty ? listingType.name : null,
      minBudget: minBudget,
      maxBudget: maxBudget,
      minArea: double.tryParse(_minAreaController.text),
      maxArea: double.tryParse(_maxAreaController.text),
      areaIds: _selectedAreaIds,
      areaNames: areaNames,
      remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
      status: _selectedStatus,
      createdAt: widget.requirement?.createdAt ?? DateTime.now(),
      furnishingIds: _selectedFurnishingIds,
      facingIds: _selectedFacingIds,
      adminId: widget.requirement?.adminId ?? (currentUser?.role == 'Admin' ? currentUser?.id : currentUser?.adminId),
      creatorName: widget.requirement?.creatorName ?? currentUser?.fullName,
      createdBy: widget.requirement?.createdBy ?? currentUser?.id,
    );

    _isSaved = true;
    CRMDraftRepository().clearDraft('requirement');

    if (widget.requirement == null) {
      context.read<RequirementsBloc>().add(CreateRequirementEvent(req));
    } else {
      context.read<RequirementsBloc>().add(UpdateRequirementEvent(req));
    }

    if (widget.isInline) {
      widget.onSaved();
    }
    Navigator.pop(context);
  }

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      if (_activeStep < 6) {
        setState(() {
          _activeStep++;
        });
        _pageController.nextPage(
          duration: CRMMotion.pageTransition,
          curve: CRMMotion.easeInOut,
        );
      } else {
        _submitForm();
      }
    }
  }

  void _prevStep() {
    if (_activeStep > 0) {
      setState(() {
        _activeStep--;
      });
      _pageController.previousPage(
        duration: CRMMotion.pageTransition,
        curve: CRMMotion.easeInOut,
      );
    }
  }

  void _jumpToStep(int step) {
    if (step > _activeStep) {
      if (!_formKey.currentState!.validate()) {
        return;
      }
    }
    setState(() {
      _activeStep = step;
    });
    _pageController.animateToPage(
      step,
      duration: CRMMotion.pageTransition,
      curve: CRMMotion.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingMetadata) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(CRMSpacing.xl),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: CRMSpacing.m),
              Text("Loading parameters..."),
            ],
          ),
        ),
      );
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 700;

    final filteredTypes = _getFilteredTypes();
    if (_selectedTypeId != null && !filteredTypes.any((t) => t.id == _selectedTypeId)) {
      _selectedTypeId = filteredTypes.isNotEmpty ? filteredTypes.first.id : null;
    }
    final filteredConfigs = _getFilteredConfigs();
    _selectedConfigIds.retainWhere((id) => filteredConfigs.any((c) => c.id == id));
    if (_selectedConfigId != null && !filteredConfigs.any((c) => c.id == _selectedConfigId)) {
      _selectedConfigId = null;
    }

    final formContent = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header (only if not inline)
          if (!widget.isInline) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.requirement != null ? "Edit Requirement" : "Add Requirement",
                  style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: CRMSpacing.s),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Edit Requirement Details",
                  style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: CRMColors.textOf(context)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: CRMSpacing.xs),
          ],
          
          // Progress stepper indicator (Interactive horizontal tabs)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: List.generate(7, (index) {
                  final isCurrent = index == _activeStep;
                  final isPassed = index < _activeStep;
                  const stepLabels = ["Customer", "Type", "Prefs", "Location", "Budget", "Notes", "Review"];
                  
                  return GestureDetector(
                    onTap: () => _jumpToStep(index),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isCurrent 
                            ? CRMColors.primary 
                            : isPassed 
                                ? CRMColors.primary.withValues(alpha: 0.1) 
                                : CRMColors.backgroundOf(context),
                        borderRadius: BorderRadius.circular(CRMBorderRadius.round),
                        border: Border.all(
                          color: isCurrent 
                              ? CRMColors.primary 
                              : isPassed 
                                  ? CRMColors.primary.withValues(alpha: 0.3) 
                                  : CRMColors.borderOf(context),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: isCurrent ? Colors.white : CRMColors.primary,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "${index + 1}",
                              style: CRMTypography.captionBold.copyWith(
                                fontSize: 10,
                                color: isCurrent ? CRMColors.primary : Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            stepLabels[index],
                            style: CRMTypography.captionBold.copyWith(
                              color: isCurrent 
                                  ? Colors.white 
                                  : isPassed 
                                      ? CRMColors.primary 
                                      : CRMColors.textSecondaryOf(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: CRMSpacing.s),

          // PageView Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1Customer(),
                _buildStep2Type(),
                _buildStep3Preference(filteredTypes, filteredConfigs),
                _buildStep4Location(),
                _buildStep5BudgetAndArea(),
                _buildStep6Notes(),
                _buildStep7Review(),
              ],
            ),
          ),
          const Divider(),
          const SizedBox(height: CRMSpacing.s),

          // Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_activeStep > 0)
                CRMButton(
                  label: "Back",
                  variant: CRMButtonVariant.outline,
                  onPressed: _prevStep,
                  height: widget.isInline ? 32 : 40,
                )
              else
                const SizedBox.shrink(),
              CRMButton(
                label: _activeStep == 6 ? "Submit" : "Next",
                onPressed: _nextStep,
                height: widget.isInline ? 32 : 40,
              ),
            ],
          ),
        ],
      ),
    );

    final container = Container(
      width: isMobile ? double.infinity : 600,
      height: widget.isInline ? 450 : 600,
      padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.l, vertical: CRMSpacing.m),
      child: formContent,
    );

    if (widget.isInline) {
      return container;
    }

    return Dialog(
      backgroundColor: CRMColors.cardBgOf(context),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.l)),
      child: container,
    );
  }

  // --- STEPS ---

  Widget _buildStep1Customer() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Step 1: Customer Details", style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: CRMSpacing.m),
          CRMPhoneField(
            controller: _mobileController,
            labelText: 'Client Mobile',
            isRequired: true,
          ),
          if (_customerFoundMessage != null) ...[
            const SizedBox(height: CRMSpacing.xs),
            Text(
              _customerFoundMessage!,
              style: CRMTypography.caption.copyWith(color: CRMColors.primary, fontWeight: FontWeight.bold),
            ),
          ],
          const SizedBox(height: CRMSpacing.m),
          CRMTextField(
            controller: _nameController,
            labelText: 'Client Name *',
            hintText: 'Enter name',
            prefixIcon: Icons.person_rounded,
            validator: (v) => v == null || v.trim().isEmpty ? 'Client name required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Type() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Step 2: Requirement Type", style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: CRMSpacing.l),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    final rentType = _listingTypes.firstWhere(
                      (lt) => lt.name.toLowerCase().contains('rent'),
                      orElse: () => LookupItem(id: 'rent', name: 'Rent'),
                    );
                    setState(() {
                      _selectedListingTypeId = rentType.id;
                    });
                  },
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: (_selectedListingTypeId != null &&
                              _listingTypes.firstWhere((lt) => lt.id == _selectedListingTypeId, orElse: () => LookupItem(id: '', name: '')).name.toLowerCase().contains('rent'))
                          ? CRMColors.primary.withValues(alpha: 0.1)
                          : CRMColors.backgroundOf(context),
                      borderRadius: BorderRadius.circular(CRMBorderRadius.m),
                      border: Border.all(
                        color: (_selectedListingTypeId != null &&
                                _listingTypes.firstWhere((lt) => lt.id == _selectedListingTypeId, orElse: () => LookupItem(id: '', name: '')).name.toLowerCase().contains('rent'))
                            ? CRMColors.primary
                            : CRMColors.borderOf(context),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.vpn_key_rounded,
                            color: (_selectedListingTypeId != null &&
                                    _listingTypes.firstWhere((lt) => lt.id == _selectedListingTypeId, orElse: () => LookupItem(id: '', name: '')).name.toLowerCase().contains('rent'))
                                ? CRMColors.primary
                                : CRMColors.textSecondaryOf(context)),
                        const SizedBox(height: 8),
                        Text("For Rent", style: CRMTypography.body.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: CRMSpacing.m),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    final saleType = _listingTypes.firstWhere(
                      (lt) => lt.name.toLowerCase().contains('sale') || lt.name.toLowerCase().contains('resale'),
                      orElse: () => LookupItem(id: 'resale', name: 'Re-Sale'),
                    );
                    setState(() {
                      _selectedListingTypeId = saleType.id;
                    });
                  },
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: (_selectedListingTypeId != null &&
                              (_listingTypes.firstWhere((lt) => lt.id == _selectedListingTypeId, orElse: () => LookupItem(id: '', name: '')).name.toLowerCase().contains('sale') ||
                               _listingTypes.firstWhere((lt) => lt.id == _selectedListingTypeId, orElse: () => LookupItem(id: '', name: '')).name.toLowerCase().contains('resale')))
                          ? CRMColors.primary.withValues(alpha: 0.1)
                          : CRMColors.backgroundOf(context),
                      borderRadius: BorderRadius.circular(CRMBorderRadius.m),
                      border: Border.all(
                        color: (_selectedListingTypeId != null &&
                                (_listingTypes.firstWhere((lt) => lt.id == _selectedListingTypeId, orElse: () => LookupItem(id: '', name: '')).name.toLowerCase().contains('sale') ||
                                 _listingTypes.firstWhere((lt) => lt.id == _selectedListingTypeId, orElse: () => LookupItem(id: '', name: '')).name.toLowerCase().contains('resale')))
                            ? CRMColors.primary
                            : CRMColors.borderOf(context),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.monetization_on_rounded,
                            color: (_selectedListingTypeId != null &&
                                    (_listingTypes.firstWhere((lt) => lt.id == _selectedListingTypeId, orElse: () => LookupItem(id: '', name: '')).name.toLowerCase().contains('sale') ||
                                     _listingTypes.firstWhere((lt) => lt.id == _selectedListingTypeId, orElse: () => LookupItem(id: '', name: '')).name.toLowerCase().contains('resale')))
                                ? CRMColors.primary
                                : CRMColors.textSecondaryOf(context)),
                        const SizedBox(height: 8),
                        Text("For Re-Sale", style: CRMTypography.body.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (widget.requirement != null) ...[
            const SizedBox(height: CRMSpacing.l),
            _buildDropdown(
              label: 'Pipeline Status Stage *',
              value: _selectedStatus,
              items: const [
                DropdownMenuItem(value: "Not Started", child: Text("Not Started")),
                DropdownMenuItem(value: "Follow-up", child: Text("Follow-up")),
                DropdownMenuItem(value: "Interested", child: Text("Interested")),
                DropdownMenuItem(value: "Site Visit", child: Text("Site Visit Sche.")),
                DropdownMenuItem(value: "Site Visit Done", child: Text("Site Visit Done")),
                DropdownMenuItem(value: "Negotiation", child: Text("Negotiation")),
                DropdownMenuItem(value: "Won", child: Text("Won")),
                DropdownMenuItem(value: "Bin", child: Text("Bin")),
                DropdownMenuItem(value: "Not Interested", child: Text("Not Interested")),
              ],
              onChanged: (val) {
                if (val != null && _validateStatusTransition(val)) {
                  setState(() => _selectedStatus = val);
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep3Preference(List<LookupItem> filteredTypes, List<LookupItem> filteredConfigs) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Step 3: Property Preferences", style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: CRMSpacing.m),
          _buildDropdown(
            label: 'Category *',
            value: _selectedCategoryId,
            items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
            onChanged: (val) => setState(() {
               _selectedCategoryId = val;
              _selectedTypeId = null;
              _selectedTypeIds.clear();
              _selectedConfigId = null;
              _selectedConfigIds.clear();
            }),
          ),
          const SizedBox(height: CRMSpacing.m),
          CRMMultiSelectDropdown(
            label: 'Property Type *',
            selectedIds: _selectedTypeIds,
            items: filteredTypes,
            onChanged: (vals) => setState(() {
              _selectedTypeIds.clear();
              _selectedTypeIds.addAll(vals);
              if (vals.isNotEmpty) {
                _selectedTypeId = vals.first;
              } else {
                _selectedTypeId = null;
              }
            }),
          ),
          const SizedBox(height: CRMSpacing.m),
          CRMMultiSelectDropdown(
            label: 'Furnishing',
            selectedIds: _selectedFurnishingIds,
            items: _furnishings,
            onChanged: (vals) => setState(() {
              _selectedFurnishingIds.clear();
              _selectedFurnishingIds.addAll(vals);
            }),
          ),
          const SizedBox(height: CRMSpacing.m),
          CRMMultiSelectDropdown(
            label: 'Facing',
            selectedIds: _selectedFacingIds,
            items: _facings,
            onChanged: (vals) => setState(() {
              _selectedFacingIds.clear();
              _selectedFacingIds.addAll(vals);
            }),
          ),
          const SizedBox(height: CRMSpacing.m),
          if (filteredConfigs.isNotEmpty) ...[
            const SizedBox(height: CRMSpacing.m),
            Text("Configuration", style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondaryOf(context))),
            const SizedBox(height: CRMSpacing.xs),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: filteredConfigs.map((c) {
                final isSelected = _selectedConfigIds.contains(c.id);
                return FilterChip(
                  label: Text(c.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedConfigIds.add(c.id);
                      } else {
                        _selectedConfigIds.remove(c.id);
                      }
                      _selectedConfigId = _selectedConfigIds.firstOrNull;
                    });
                  },
                  selectedColor: CRMColors.primaryOf(context).withOpacity(0.18),
                  checkmarkColor: CRMColors.primaryOf(context),
                  labelStyle: TextStyle(
                    color: isSelected ? CRMColors.primaryOf(context) : CRMColors.textOf(context),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep4Location() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 500;

    final titleWidget = Text("Step 4: Target Area(s) *", style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold));
    final filterWidget = Row(
      children: [
        if (isMobile)
          Expanded(
            child: SizedBox(
              height: 32,
              child: TextField(
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Filter areas...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 14),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  filled: true,
                  fillColor: CRMColors.backgroundOf(context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                ),
                onChanged: (val) => setState(() => _areaSearchQuery = val.trim()),
              ),
            ),
          )
        else
          SizedBox(
            width: 160,
            height: 32,
            child: TextField(
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Filter areas...',
                prefixIcon: const Icon(Icons.search_rounded, size: 14),
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                filled: true,
                fillColor: CRMColors.backgroundOf(context),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
              ),
              onChanged: (val) => setState(() => _areaSearchQuery = val.trim()),
            ),
          ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.add_circle_outline_rounded, color: CRMColors.primaryOf(context), size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => _showAddAreaDialog(),
          tooltip: 'Add New Area',
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleWidget,
                  const SizedBox(height: CRMSpacing.s),
                  filterWidget,
                ],
              )
            : Row(
                children: [
                  titleWidget,
                  const Spacer(),
                  filterWidget,
                ],
              ),
        const SizedBox(height: CRMSpacing.m),
        Expanded(
          child: Builder(
            builder: (context) {
              final filtered = _areas.where((a) {
                if (_areaSearchQuery.isEmpty) return true;
                final query = _areaSearchQuery.toLowerCase();
                return a.name.toLowerCase().contains(query) || a.pincode.contains(query);
              }).toList();

              if (filtered.isEmpty) {
                return const Center(child: Text("No areas found."));
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final area = filtered[index];
                  final isSelected = _selectedAreaIds.contains(area.id);
                  return CheckboxListTile(
                    title: Text(area.name, style: const TextStyle(fontSize: 13)),
                    subtitle: Text(area.pincode, style: const TextStyle(fontSize: 11)),
                    value: isSelected,
                    activeColor: CRMColors.primary,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedAreaIds.add(area.id);
                        } else {
                          _selectedAreaIds.remove(area.id);
                        }
                      });
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStep5BudgetAndArea() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Step 5: Budget & Size Limits", style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: CRMSpacing.m),
          CRMCurrencyField(
            controller: _budgetController,
            labelText: 'Target Budget *',
            isRequired: true,
          ),
          const SizedBox(height: CRMSpacing.m),
          Row(
            children: [
              Expanded(
                child: CRMTextField(
                  controller: _minAreaController,
                  labelText: 'Min Area (Sq.Ft)',
                  hintText: 'e.g. 800',
                  prefixIcon: Icons.square_foot_rounded,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: CRMSpacing.m),
              Expanded(
                child: CRMTextField(
                  controller: _maxAreaController,
                  labelText: 'Max Area (Sq.Ft)',
                  hintText: 'e.g. 1500',
                  prefixIcon: Icons.square_foot_rounded,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep6Notes() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Step 6: Additional Remarks", style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: CRMSpacing.m),
          CRMTextField(
            controller: _remarksController,
            labelText: 'Internal CRM Remarks',
            hintText: 'Enter preferences, customer remarks, or internal notes...',
            prefixIcon: Icons.chat_bubble_outline_rounded,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildStep7Review() {
    final cat = _categories.firstWhere((c) => c.id == _selectedCategoryId, orElse: () => LookupItem(id: '', name: 'None'));
    final type = _types.firstWhere((t) => t.id == _selectedTypeId, orElse: () => LookupItem(id: '', name: 'None'));
    final configNames = _selectedConfigIds.map((id) {
      final match = _configurations.firstWhere((c) => c.id == id, orElse: () => LookupItem(id: id, name: id));
      return match.name;
    }).toList();
    final configDisplayStr = configNames.isNotEmpty ? configNames.join(', ') : 'None';
    
    // Completeness score mock check for review
    double comp = 0.0;
    if (_nameController.text.isNotEmpty) comp += 0.15;
    if (_mobileController.text.isNotEmpty) comp += 0.15;
    if (_selectedCategoryId != null) comp += 0.15;
    if (_selectedTypeId != null) comp += 0.10;
    if (_selectedConfigIds.isNotEmpty) comp += 0.10;
    if (_selectedAreaIds.isNotEmpty) comp += 0.15;
    if (_budgetController.text.isNotEmpty) comp += 0.20;

    final readiness = (_selectedCategoryId != null && _budgetController.text.isNotEmpty && _selectedAreaIds.isNotEmpty)
        ? (_selectedConfigIds.isNotEmpty ? 'Ready' : 'Needs Information')
        : 'Cannot Match';

    final List<String> warnings = [];
    if (_selectedConfigIds.isEmpty) warnings.add("Missing Configuration");
    if (_budgetController.text.isEmpty) warnings.add("Missing Budget");
    if (_selectedAreaIds.isEmpty) warnings.add("Missing Target Area");

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Step 7: Review & Validate", style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: CRMSpacing.m),
          // Scores Card removed
          // Warnings List
          if (warnings.isNotEmpty) ...[
            Text("Missing Requirements Details:", style: CRMTypography.bodyMedium.copyWith(color: CRMColors.danger, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            ...warnings.map((w) => Padding(
                  padding: const EdgeInsets.only(bottom: 2.0),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 14, color: CRMColors.danger),
                      const SizedBox(width: 4),
                      Text(w, style: CRMTypography.caption.copyWith(color: CRMColors.danger)),
                    ],
                  ),
                )),
            const SizedBox(height: CRMSpacing.m),
          ],

          // Details List
          Text("Summary Details:", style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          const Divider(),
          _buildSummaryRow("Client", _nameController.text),
          _buildSummaryRow("Mobile", _mobileController.text),
          _buildSummaryRow("Category", cat.name),
          _buildSummaryRow("Property Type", type.name),
          _buildSummaryRow("Configuration", configDisplayStr),
          _buildSummaryRow("Target Areas", "${_selectedAreaIds.length} Selected"),
          _buildSummaryRow("Budget", _budgetController.text),
          _buildSummaryRow("Pipeline Status", _selectedStatus),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: CRMTypography.caption),
          Text(value.isNotEmpty ? value : "None", style: CRMTypography.caption.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final bool hasValue = items.any((item) => item.value == value);
    final T? safeValue = hasValue ? value : null;

    final List<DropdownMenuItem<T?>> safeItems = [
      if (safeValue == null && !items.any((item) => item.value == null))
        DropdownMenuItem<T?>(value: null, child: Text("Select $label")),
      ...items.map((item) => DropdownMenuItem<T?>(value: item.value, child: item.child)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondaryOf(context))),
        const SizedBox(height: CRMSpacing.xs),
        DropdownButtonFormField<T?>(
          value: safeValue,
          dropdownColor: CRMColors.cardBgOf(context),
          style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: CRMSpacing.s),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              borderSide: BorderSide(color: CRMColors.borderOf(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              borderSide: BorderSide(color: CRMColors.borderOf(context)),
            ),
          ),
          items: safeItems,
          onChanged: onChanged,
        ),
      ],
    );
  }


}
