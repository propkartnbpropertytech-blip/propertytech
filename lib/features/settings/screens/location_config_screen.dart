import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/dialogs.dart';
import '../../properties/models/property_model.dart';
import '../../properties/services/properties_service.dart';

class LocationConfigScreen extends StatefulWidget {
  const LocationConfigScreen({super.key});

  @override
  State<LocationConfigScreen> createState() => _LocationConfigScreenState();
}

class _LocationConfigScreenState extends State<LocationConfigScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PropertiesService _propertiesService = PropertiesService();
  bool _isLoading = true;

  // Data lists
  List<LookupItem> _cities = [];
  List<AreaLookup> _areas = [];

  // Form State / Editing State
  bool _isCityFormOpen = false;
  LookupItem? _editingCity;
  final _cityFormKey = GlobalKey<FormState>();
  final _cityNameController = TextEditingController();
  final _cityStateController = TextEditingController(text: 'Gujarat');
  final _cityCountryController = TextEditingController(text: 'India');
  bool _cityIsActive = true;

  bool _isAreaFormOpen = false;
  AreaLookup? _editingArea;
  final _areaFormKey = GlobalKey<FormState>();
  final _areaNameController = TextEditingController();
  final _areaPincodeController = TextEditingController();
  String? _areaSelectedCityId;
  bool _areaIsActive = true;
  bool _isFetchingPincode = false;
  bool _isSavingArea = false;
  bool _areaFormIsModal = false;

  // Search filters
  String _citySearchQuery = '';
  String _areaSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _areaPincodeController.addListener(_onPincodeChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cityNameController.dispose();
    _cityStateController.dispose();
    _cityCountryController.dispose();
    _areaNameController.dispose();
    _areaPincodeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final response = await _propertiesService.getPropertyMetadata();
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final meta = PropertyMetadataModel.fromJson(data['metadata'] ?? {});
      setState(() {
        _cities = meta.cities;
        _areas = meta.areas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Failed to load configuration data: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? CRMColors.danger : CRMColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Postal code API integration
  void _onPincodeChanged() {
    final pincode = _areaPincodeController.text.trim();
    if (pincode.length == 6 && !_isFetchingPincode) {
      _lookupPincode(pincode);
    }
  }

  Future<void> _lookupPincode(String pincode) async {
    setState(() => _isFetchingPincode = true);
    try {
      final dio = Dio();
      final response = await dio.get('https://api.postalpincode.in/pincode/$pincode');
      
      if (response.statusCode == 200 && response.data is List && response.data.isNotEmpty) {
        final data = response.data[0] as Map<String, dynamic>;
        final status = data['Status']?.toString();
        final postOffices = data['PostOffice'] as List?;
        
        if (status == 'Success' && postOffices != null && postOffices.isNotEmpty) {
          final firstOffice = postOffices[0] as Map<String, dynamic>;
          final districtName = firstOffice['District']?.toString() ?? '';
          
          LookupItem? matchedCity;
          for (final city in _cities) {
            if (city.name.toLowerCase() == districtName.toLowerCase()) {
              matchedCity = city;
              break;
            }
          }
          
          if (matchedCity != null) {
            setState(() {
              _areaSelectedCityId = matchedCity!.id;
              if (_areaNameController.text.isEmpty && postOffices.isNotEmpty) {
                _areaNameController.text = postOffices[0]['Name']?.toString() ?? '';
              }
            });
            _showSnackBar('City auto-resolved to: ${matchedCity.name}');
          } else if (districtName.isNotEmpty) {
            _showCityAutoAddDialog(districtName, postOffices);
          }
        }
      }
    } catch (e) {
      debugPrint("⚠️ [Pincode API Error] $e");
    } finally {
      if (mounted) {
        setState(() => _isFetchingPincode = false);
      }
    }
  }

  void _showCityAutoAddDialog(String districtName, List postOffices) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.card)),
        backgroundColor: CRMColors.surfaceElevatedOf(context),
        title: Text('City "$districtName" Not Found', style: CRMTypography.sectionTitle),
        content: Text('Pincode maps to "$districtName", which is not configured. Would you like to create this city first?', style: CRMTypography.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                final result = await _propertiesService.createCity(districtName);
                final newCity = LookupItem.fromJson(result['data']['city']);
                await _loadData();
                setState(() {
                  _areaSelectedCityId = newCity.id;
                  if (_areaNameController.text.isEmpty && postOffices.isNotEmpty) {
                    _areaNameController.text = postOffices[0]['Name']?.toString() ?? '';
                  }
                });
                _showSnackBar('City "$districtName" created and selected.');
              } catch (e) {
                _showSnackBar('Failed to create city: $e', isError: true);
              } finally {
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Add & Select City'),
          ),
        ],
      ),
    );
  }

  // --- City Operations ---
  void _openCityForm([LookupItem? city]) {
    setState(() {
      _editingCity = city;
      if (city != null) {
        _cityNameController.text = city.name;
        _cityStateController.text = city.state ?? 'Gujarat';
        _cityCountryController.text = city.country ?? 'India';
        _cityIsActive = true;
      } else {
        _cityNameController.clear();
        _cityStateController.text = 'Gujarat';
        _cityCountryController.text = 'India';
        _cityIsActive = true;
      }
    });

    final bool isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) {
          return Container(
            decoration: BoxDecoration(
              color: CRMColors.cardBgOf(context),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(CRMBorderRadius.l)),
            ),
            padding: EdgeInsets.only(
              left: CRMSpacing.m,
              right: CRMSpacing.m,
              top: CRMSpacing.m,
              bottom: MediaQuery.of(context).viewInsets.bottom + CRMSpacing.m,
            ),
            child: SingleChildScrollView(
              child: _buildCityFormPanel(),
            ),
          );
        },
      );
    } else {
      setState(() {
        _isCityFormOpen = true;
      });
    }
  }

  void _closeCityForm() {
    setState(() {
      _isCityFormOpen = false;
      _editingCity = null;
      _cityNameController.clear();
    });
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _saveCity() async {
    if (!_cityFormKey.currentState!.validate()) return;

    final name = _cityNameController.text.trim();
    final stateName = _cityStateController.text.trim();
    final countryName = _cityCountryController.text.trim();

    // Prevent duplicates
    final exists = _cities.any((c) =>
        c.name.toLowerCase() == name.toLowerCase() &&
        (_editingCity == null || c.id != _editingCity!.id));

    if (exists) {
      _showSnackBar('A city named "$name" already exists.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_editingCity == null) {
        // Create new
        await _propertiesService.createCity(name);
        _showSnackBar('City "$name" created successfully!');
      } else {
        // Edit existing
        await _propertiesService.updateCity(
          _editingCity!.id,
          name,
          state: stateName,
          country: countryName,
        );
        _showSnackBar('City updated successfully!');
      }
      _closeCityForm();
      await _loadData();
    } catch (e) {
      _showSnackBar('Operation failed: $e', isError: true);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCity(LookupItem city) async {
    final hasAreas = _areas.any((a) => a.cityId == city.id);
    String warningMsg = 'Are you sure you want to delete "${city.name}"?';
    if (hasAreas) {
      warningMsg = 'Warning: "${city.name}" has mapped areas. Deleting this city will also delete all its associated area mappings. Proceed?';
    }

    final confirm = await CRMDialogs.showDeleteConfirmation(
      context,
      title: 'Delete City',
      content: warningMsg,
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _propertiesService.deleteCity(city.id);
      _showSnackBar('City deleted successfully.');
      await _loadData();
    } catch (e) {
      _showSnackBar('Failed to delete city: $e', isError: true);
      setState(() => _isLoading = false);
    }
  }

  // --- Area Operations ---
  void _openAreaForm([AreaLookup? area]) {
    setState(() {
      _editingArea = area;
      if (area != null) {
        _areaNameController.text = area.name;
        _areaPincodeController.text = area.pincode;
        _areaSelectedCityId = area.cityId;
        _areaIsActive = true;
      } else {
        _areaNameController.clear();
        _areaPincodeController.clear();
        _areaSelectedCityId = _cities.isNotEmpty ? _cities.first.id : null;
        _areaIsActive = true;
      }
    });

    final bool isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      _areaFormIsModal = true;
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) {
          return Container(
            decoration: BoxDecoration(
              color: CRMColors.cardBgOf(context),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(CRMBorderRadius.l)),
            ),
            padding: EdgeInsets.only(
              left: CRMSpacing.m,
              right: CRMSpacing.m,
              top: CRMSpacing.m,
              bottom: MediaQuery.of(context).viewInsets.bottom + CRMSpacing.m,
            ),
            child: SingleChildScrollView(
              child: _buildAreaFormPanel(),
            ),
          );
        },
      ).whenComplete(() {
        _areaFormIsModal = false;
      });
    } else {
      _areaFormIsModal = false;
      setState(() {
        _isAreaFormOpen = true;
      });
    }
  }

  void _closeAreaForm() {
    final shouldPopModal = _areaFormIsModal;
    setState(() {
      _isAreaFormOpen = false;
      _editingArea = null;
      _areaNameController.clear();
      _areaPincodeController.clear();
      _isSavingArea = false;
    });
    if (shouldPopModal && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _saveArea() async {
    if (_isSavingArea) return;
    if (!_areaFormKey.currentState!.validate()) return;
    if (_areaSelectedCityId == null) {
      _showSnackBar('Please select an associated city.', isError: true);
      return;
    }

    final name = _areaNameController.text.trim();
    final pincode = _areaPincodeController.text.trim();

    // Prevent duplicates
    final exists = _areas.any((a) =>
        a.cityId == _areaSelectedCityId &&
        a.name.toLowerCase() == name.toLowerCase() &&
        a.pincode == pincode &&
        (_editingArea == null || a.id != _editingArea!.id));

    if (exists) {
      _showSnackBar('An area named "$name" with pincode "$pincode" already exists in this city.', isError: true);
      return;
    }

    setState(() => _isSavingArea = true);
    try {
      if (_editingArea == null) {
        final response = await _propertiesService.createArea(_areaSelectedCityId!, name, pincode);
        final data = response['data'] as Map<String, dynamic>? ?? {};
        final areaJson = data['area'] as Map<String, dynamic>? ?? {};
        if (areaJson['id'] != null) {
          final created = AreaLookup.fromJson(areaJson);
          setState(() {
            _areas = [..._areas, created];
          });
        }
        _showSnackBar('Area created successfully!');
      } else {
        final editingId = _editingArea!.id;
        await _propertiesService.updateArea(editingId, _areaSelectedCityId!, name, pincode);
        setState(() {
          _areas = _areas
              .map((a) => a.id == editingId
                  ? AreaLookup(
                      id: a.id,
                      name: name,
                      cityId: _areaSelectedCityId!,
                      pincode: pincode,
                    )
                  : a)
              .toList();
        });
        _showSnackBar('Area updated successfully!');
      }
      _closeAreaForm();
    } catch (e) {
      if (mounted) setState(() => _isSavingArea = false);
      _showSnackBar('Operation failed: $e', isError: true);
    }
  }

  Future<void> _deleteArea(AreaLookup area) async {
    final confirm = await CRMDialogs.showDeleteConfirmation(
      context,
      title: 'Delete Area',
      content: 'Are you sure you want to delete area "${area.name}" mapping?',
    );

    if (confirm != true) return;

    try {
      await _propertiesService.deleteArea(area.id);
      if (!mounted) return;
      setState(() {
        _areas = _areas.where((a) => a.id != area.id).toList();
      });
      _showSnackBar('Area configuration deleted.');
    } catch (e) {
      _showSnackBar('Failed to delete area: $e', isError: true);
    }
  }

  // --- Rendering UI Panels ---
  Widget _buildCitySection() {
    final filtered = _cities.where((c) {
      if (_citySearchQuery.isEmpty) return true;
      return c.name.toLowerCase().contains(_citySearchQuery.toLowerCase()) ||
          (c.state ?? '').toLowerCase().contains(_citySearchQuery.toLowerCase());
    }).toList();

    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title and Add button
        if (isMobile)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('City Records', style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context))),
              const SizedBox(height: CRMSpacing.xxs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${filtered.length} active cities configured',
                      style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                    ),
                  ),
                  CRMButton(
                    label: 'Add New City',
                    prefixIcon: Icons.add_rounded,
                    onPressed: () => _openCityForm(),
                  ),
                ],
              ),
            ],
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('City Records', style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context))),
                  Text('${filtered.length} active cities configured', style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context))),
                ],
              ),
              CRMButton(
                label: 'Add New City',
                prefixIcon: Icons.add_rounded,
                onPressed: () => _openCityForm(),
              ),
            ],
          ),
        const SizedBox(height: CRMSpacing.m),

        // Inline Form Editor Panel
        if (_isCityFormOpen) ...[
          _buildCityFormPanel(),
          const SizedBox(height: CRMSpacing.m),
        ],

        // Search bar
        TextField(
          style: TextStyle(color: CRMColors.textOf(context)),
          decoration: InputDecoration(
            hintText: 'Search cities...',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: CRMColors.cardBgOf(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CRMBorderRadius.input),
              borderSide: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.4)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CRMBorderRadius.input),
              borderSide: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.4)),
            ),
          ),
          onChanged: (val) => setState(() => _citySearchQuery = val),
        ),
        const SizedBox(height: CRMSpacing.m),

        // Structured List Table
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: CRMColors.cardBgOf(context),
              borderRadius: BorderRadius.circular(CRMBorderRadius.m),
              border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.4)),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => Divider(color: CRMColors.borderOf(context).withOpacity(0.3), height: 1),
              itemBuilder: (context, index) {
                final city = filtered[index];
                if (isMobile) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: CRMSpacing.m),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: CRMColors.primary.withValues(alpha: 0.08),
                          child: Icon(Icons.location_city_outlined, color: CRMColors.primary, size: 20),
                        ),
                        const SizedBox(width: CRMSpacing.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                city.name,
                                style: CRMTypography.bodyMedium.copyWith(
                                  color: CRMColors.textOf(context),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${city.state ?? 'Gujarat'}, ${city.country ?? 'India'}',
                                style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: CRMSpacing.s),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: CRMColors.success.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Active',
                                style: CRMTypography.captionBold.copyWith(
                                  color: CRMColors.success,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 16),
                                  color: CRMColors.primary,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  padding: EdgeInsets.zero,
                                  tooltip: 'Edit City',
                                  onPressed: () => _openCityForm(city),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, color: CRMColors.danger, size: 16),
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  padding: EdgeInsets.zero,
                                  tooltip: 'Delete City',
                                  onPressed: () => _deleteCity(city),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: CRMSpacing.xs),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          city.name,
                          style: CRMTypography.bodyMedium.copyWith(
                            color: CRMColors.textOf(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status Chip inline
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: CRMColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Active',
                          style: CRMTypography.captionBold.copyWith(
                            color: CRMColors.success,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text('${city.state ?? 'Gujarat'}, ${city.country ?? 'India'}', style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context))),
                  leading: CircleAvatar(
                    backgroundColor: CRMColors.primary.withOpacity(0.08),
                    child: Icon(Icons.location_city_outlined, color: CRMColors.primary, size: 20),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        color: CRMColors.primary,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                        tooltip: 'Edit City',
                        onPressed: () => _openCityForm(city),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded, color: CRMColors.danger, size: 16),
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                        tooltip: 'Delete City',
                        onPressed: () => _deleteCity(city),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCityFormPanel() {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: isMobile ? EdgeInsets.zero : const EdgeInsets.all(CRMSpacing.m),
      decoration: isMobile
          ? null
          : BoxDecoration(
              color: CRMColors.primary.withOpacity(0.03),
              borderRadius: BorderRadius.circular(CRMBorderRadius.m),
              border: Border.all(color: CRMColors.primary.withOpacity(0.15), width: 1.5),
            ),
      child: Form(
        key: _cityFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _editingCity == null ? 'Create New City Configuration' : 'Edit City: ${_editingCity!.name}',
              style: CRMTypography.bodyMedium.copyWith(color: CRMColors.primary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: CRMSpacing.m),
            if (isMobile) ...[
              TextFormField(
                controller: _cityNameController,
                style: TextStyle(color: CRMColors.textOf(context)),
                decoration: InputDecoration(
                  labelText: 'City Name *',
                  labelStyle: TextStyle(color: CRMColors.textSecondaryOf(context)),
                  filled: true,
                  fillColor: CRMColors.cardBgOf(context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.input)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: CRMSpacing.s),
              TextFormField(
                controller: _cityStateController,
                style: TextStyle(color: CRMColors.textOf(context)),
                decoration: InputDecoration(
                  labelText: 'State Name',
                  labelStyle: TextStyle(color: CRMColors.textSecondaryOf(context)),
                  filled: true,
                  fillColor: CRMColors.cardBgOf(context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.input)),
                ),
              ),
              const SizedBox(height: CRMSpacing.s),
              TextFormField(
                controller: _cityCountryController,
                style: TextStyle(color: CRMColors.textOf(context)),
                decoration: InputDecoration(
                  labelText: 'Country',
                  labelStyle: TextStyle(color: CRMColors.textSecondaryOf(context)),
                  filled: true,
                  fillColor: CRMColors.cardBgOf(context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.input)),
                ),
              ),
              const SizedBox(height: CRMSpacing.s),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Status: ', style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context))),
                  Switch(
                    value: _cityIsActive,
                    activeColor: CRMColors.success,
                    onChanged: (val) => setState(() => _cityIsActive = val),
                  ),
                  Text(_cityIsActive ? 'Active' : 'Inactive', style: CRMTypography.captionBold.copyWith(color: _cityIsActive ? CRMColors.success : CRMColors.textSecondaryOf(context))),
                ],
              ),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityNameController,
                      style: TextStyle(color: CRMColors.textOf(context)),
                      decoration: InputDecoration(
                        labelText: 'City Name *',
                        labelStyle: TextStyle(color: CRMColors.textSecondaryOf(context)),
                        filled: true,
                        fillColor: CRMColors.cardBgOf(context),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.input)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: CRMSpacing.s),
                  Expanded(
                    child: TextFormField(
                      controller: _cityStateController,
                      style: TextStyle(color: CRMColors.textOf(context)),
                      decoration: InputDecoration(
                        labelText: 'State Name',
                        labelStyle: TextStyle(color: CRMColors.textSecondaryOf(context)),
                        filled: true,
                        fillColor: CRMColors.cardBgOf(context),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.input)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: CRMSpacing.s),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityCountryController,
                      style: TextStyle(color: CRMColors.textOf(context)),
                      decoration: InputDecoration(
                        labelText: 'Country',
                        labelStyle: TextStyle(color: CRMColors.textSecondaryOf(context)),
                        filled: true,
                        fillColor: CRMColors.cardBgOf(context),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.input)),
                      ),
                    ),
                  ),
                  const SizedBox(width: CRMSpacing.m),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Status: ', style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context))),
                      Switch(
                        value: _cityIsActive,
                        activeColor: CRMColors.success,
                        onChanged: (val) => setState(() => _cityIsActive = val),
                      ),
                      Text(_cityIsActive ? 'Active' : 'Inactive', style: CRMTypography.captionBold.copyWith(color: _cityIsActive ? CRMColors.success : CRMColors.textSecondaryOf(context))),
                    ],
                  ),
                ],
              ),
            ],
            const SizedBox(height: CRMSpacing.m),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _closeCityForm,
                  child: Text('Cancel', style: TextStyle(color: CRMColors.textSecondaryOf(context))),
                ),
                const SizedBox(width: CRMSpacing.s),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CRMColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.input)),
                  ),
                  onPressed: _saveCity,
                  child: Text('Save Configuration', style: CRMTypography.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAreaSection() {
    final filtered = _areas.where((a) {
      if (_areaSearchQuery.isEmpty) return true;
      final city = _cities.firstWhere((c) => c.id == a.cityId, orElse: () => LookupItem(id: '', name: '')).name;
      return a.name.toLowerCase().contains(_areaSearchQuery.toLowerCase()) ||
          a.pincode.contains(_areaSearchQuery) ||
          city.toLowerCase().contains(_areaSearchQuery.toLowerCase());
    }).toList();

    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title and Add button
        if (isMobile)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Area Mapping & Postal Config', style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context))),
              const SizedBox(height: CRMSpacing.xxs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${filtered.length} areas mapped to active cities',
                      style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                    ),
                  ),
                  CRMButton(
                    label: 'Add New Area',
                    prefixIcon: Icons.add_rounded,
                    onPressed: () => _openAreaForm(),
                  ),
                ],
              ),
            ],
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Area Mapping & Postal Config', style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context))),
                  Text('${filtered.length} areas mapped to active cities', style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context))),
                ],
              ),
              CRMButton(
                label: 'Add New Area',
                prefixIcon: Icons.add_rounded,
                onPressed: () => _openAreaForm(),
              ),
            ],
          ),
        const SizedBox(height: CRMSpacing.m),

        // Inline Form Editor Panel
        if (_isAreaFormOpen) ...[
          _buildAreaFormPanel(),
          const SizedBox(height: CRMSpacing.m),
        ],

        // Search bar
        TextField(
          style: TextStyle(color: CRMColors.textOf(context)),
          decoration: InputDecoration(
            hintText: 'Search areas, pincodes, or cities...',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: CRMColors.cardBgOf(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CRMBorderRadius.input),
              borderSide: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.4)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CRMBorderRadius.input),
              borderSide: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.4)),
            ),
          ),
          onChanged: (val) => setState(() => _areaSearchQuery = val),
        ),
        const SizedBox(height: CRMSpacing.m),

        // Structured List Table
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: CRMColors.cardBgOf(context),
              borderRadius: BorderRadius.circular(CRMBorderRadius.m),
              border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.4)),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => Divider(color: CRMColors.borderOf(context).withOpacity(0.3), height: 1),
              itemBuilder: (context, index) {
                final area = filtered[index];
                final cityName = _cities.firstWhere((c) => c.id == area.cityId, orElse: () => LookupItem(id: '', name: 'Unknown')).name;
                if (isMobile) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: CRMSpacing.m),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: CRMColors.primary.withValues(alpha: 0.08),
                          child: Icon(Icons.map_outlined, color: CRMColors.primary, size: 20),
                        ),
                        const SizedBox(width: CRMSpacing.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                area.name,
                                style: CRMTypography.bodyMedium.copyWith(
                                  color: CRMColors.textOf(context),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'City: $cityName | Pincode: ${area.pincode}',
                                style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: CRMSpacing.s),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: CRMColors.success.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Active',
                                style: CRMTypography.captionBold.copyWith(
                                  color: CRMColors.success,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 16),
                                  color: CRMColors.primary,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  padding: EdgeInsets.zero,
                                  tooltip: 'Edit Area Mapping',
                                  onPressed: () => _openAreaForm(area),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, color: CRMColors.danger, size: 16),
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  padding: EdgeInsets.zero,
                                  tooltip: 'Delete Area Mapping',
                                  onPressed: () => _deleteArea(area),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: CRMSpacing.xs),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          area.name,
                          style: CRMTypography.bodyMedium.copyWith(
                            color: CRMColors.textOf(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status Chip inline
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: CRMColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Active',
                          style: CRMTypography.captionBold.copyWith(
                            color: CRMColors.success,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text('City: $cityName | Pincode: ${area.pincode}', style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context))),
                  leading: CircleAvatar(
                    backgroundColor: CRMColors.primary.withOpacity(0.08),
                    child: Icon(Icons.map_outlined, color: CRMColors.primary, size: 20),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        color: CRMColors.primary,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                        tooltip: 'Edit Area Mapping',
                        onPressed: () => _openAreaForm(area),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded, color: CRMColors.danger, size: 16),
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                        tooltip: 'Delete Area Mapping',
                        onPressed: () => _deleteArea(area),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAreaFormPanel() {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: isMobile ? EdgeInsets.zero : const EdgeInsets.all(CRMSpacing.m),
      decoration: isMobile
          ? null
          : BoxDecoration(
              color: CRMColors.primary.withOpacity(0.03),
              borderRadius: BorderRadius.circular(CRMBorderRadius.m),
              border: Border.all(color: CRMColors.primary.withOpacity(0.15), width: 1.5),
            ),
      child: Form(
        key: _areaFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _editingArea == null ? 'Create New Area Mapping' : 'Edit Area: ${_editingArea!.name}',
              style: CRMTypography.bodyMedium.copyWith(color: CRMColors.primary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: CRMSpacing.m),
            Builder(builder: (context) {
              final bool isMobile = MediaQuery.of(context).size.width < 600;
              if (isMobile) {
                return Column(
                  children: [
                    TextFormField(
                      controller: _areaPincodeController,
                      style: TextStyle(color: CRMColors.textOf(context)),
                      decoration: InputDecoration(
                        labelText: 'Pincode (6 Digits) *',
                        labelStyle: TextStyle(color: CRMColors.textSecondaryOf(context)),
                        filled: true,
                        fillColor: CRMColors.cardBgOf(context),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.input)),
                        suffixIcon: _isFetchingPincode
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
                      onFieldSubmitted: (v) {
                        final pincode = v.trim();
                        if (pincode.length == 6 && !_isFetchingPincode) {
                          _lookupPincode(pincode);
                        }
                      },
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (v.trim().length != 6 || int.tryParse(v) == null) {
                          return 'Enter a valid 6-digit number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    DropdownButtonFormField<String>(
                      value: _areaSelectedCityId,
                      dropdownColor: CRMColors.cardBgOf(context),
                      style: TextStyle(color: CRMColors.textOf(context)),
                      decoration: InputDecoration(
                        labelText: 'Select City *',
                        labelStyle: TextStyle(color: CRMColors.textSecondaryOf(context)),
                        filled: true,
                        fillColor: CRMColors.cardBgOf(context),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.input)),
                      ),
                      items: _cities.map((c) {
                        return DropdownMenuItem(value: c.id, child: Text(c.name, style: TextStyle(color: CRMColors.textOf(context))));
                      }).toList(),
                      onChanged: (v) => setState(() => _areaSelectedCityId = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    TextFormField(
                      controller: _areaNameController,
                      style: TextStyle(color: CRMColors.textOf(context)),
                      decoration: InputDecoration(
                        labelText: 'Area Name *',
                        labelStyle: TextStyle(color: CRMColors.textSecondaryOf(context)),
                        filled: true,
                        fillColor: CRMColors.cardBgOf(context),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.input)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Status: ', style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context))),
                        Switch(
                          value: _areaIsActive,
                          activeColor: CRMColors.success,
                          onChanged: (val) => setState(() => _areaIsActive = val),
                        ),
                        Text(_areaIsActive ? 'Active' : 'Inactive', style: CRMTypography.captionBold.copyWith(color: _areaIsActive ? CRMColors.success : CRMColors.textSecondaryOf(context))),
                      ],
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _areaPincodeController,
                            style: TextStyle(color: CRMColors.textOf(context)),
                            decoration: InputDecoration(
                              labelText: 'Pincode (6 Digits) *',
                              labelStyle: TextStyle(color: CRMColors.textSecondaryOf(context)),
                              filled: true,
                              fillColor: CRMColors.cardBgOf(context),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.input)),
                              suffixIcon: _isFetchingPincode
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
                            onFieldSubmitted: (v) {
                              final pincode = v.trim();
                              if (pincode.length == 6 && !_isFetchingPincode) {
                                _lookupPincode(pincode);
                              }
                            },
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              if (v.trim().length != 6 || int.tryParse(v) == null) {
                                return 'Enter a valid 6-digit number';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: CRMSpacing.s),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _areaSelectedCityId,
                            dropdownColor: CRMColors.cardBgOf(context),
                            style: TextStyle(color: CRMColors.textOf(context)),
                            decoration: InputDecoration(
                              labelText: 'Select City *',
                              labelStyle: TextStyle(color: CRMColors.textSecondaryOf(context)),
                              filled: true,
                              fillColor: CRMColors.cardBgOf(context),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.input)),
                            ),
                            items: _cities.map((c) {
                              return DropdownMenuItem(value: c.id, child: Text(c.name, style: TextStyle(color: CRMColors.textOf(context))));
                            }).toList(),
                            onChanged: (v) => setState(() => _areaSelectedCityId = v),
                            validator: (v) => v == null ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _areaNameController,
                            style: TextStyle(color: CRMColors.textOf(context)),
                            decoration: InputDecoration(
                              labelText: 'Area Name *',
                              labelStyle: TextStyle(color: CRMColors.textSecondaryOf(context)),
                              filled: true,
                              fillColor: CRMColors.cardBgOf(context),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.input)),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: CRMSpacing.m),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Status: ', style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context))),
                            Switch(
                              value: _areaIsActive,
                              activeColor: CRMColors.success,
                              onChanged: (val) => setState(() => _areaIsActive = val),
                            ),
                            Text(_areaIsActive ? 'Active' : 'Inactive', style: CRMTypography.captionBold.copyWith(color: _areaIsActive ? CRMColors.success : CRMColors.textSecondaryOf(context))),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              }
            }),
            const SizedBox(height: CRMSpacing.m),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _closeAreaForm,
                  child: Text('Cancel', style: TextStyle(color: CRMColors.textSecondaryOf(context))),
                ),
                const SizedBox(width: CRMSpacing.s),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CRMColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.input)),
                  ),
                  onPressed: _isSavingArea ? null : _saveArea,
                  child: _isSavingArea
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text('Save Configuration', style: CRMTypography.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Location Configurations',
          style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context), fontWeight: FontWeight.bold),
        ),
        backgroundColor: CRMColors.cardBgOf(context),
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: CRMColors.textOf(context)),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/settings');
            }
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: CRMColors.primary,
          unselectedLabelColor: CRMColors.textSecondaryOf(context),
          indicatorColor: CRMColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.location_city_rounded), text: 'Cities'),
            Tab(icon: Icon(Icons.map_outlined), text: 'Areas / Micro-markets'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(CRMSpacing.l),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCitySection(),
                  _buildAreaSection(),
                ],
              ),
            ),
    );
  }
}
