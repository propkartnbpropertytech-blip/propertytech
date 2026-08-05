import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api/api_client.dart';
import '../../../core/design_system/crm_design_system.dart';
import '../../../core/design_system/widgets/form/crm_date_picker.dart';
import '../../../core/design_system/widgets/crm_map_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bloc/properties_bloc.dart';
import '../models/property_model.dart';
import '../services/properties_service.dart';
import '../repository/properties_repository.dart';
import '../../../core/storage/crm_draft_repository.dart';
import '../../../core/storage/repository_coordinator.dart';
import '../../../core/design_system/widgets/form/crm_video_picker.dart';
import 'package:dio/dio.dart';
import '../../settings/screens/location_config_screen.dart';

class AddEditPropertyScreen extends StatefulWidget {
  final PropertyMetadataModel metadata;
  final PropertyModel? property;
  final String activeTab;
  final String? activeListingTab;

  const AddEditPropertyScreen({
    super.key,
    required this.metadata,
    this.property,
    required this.activeTab,
    this.activeListingTab,
  });

  @override
  State<AddEditPropertyScreen> createState() => _AddEditPropertyScreenState();
}

class _AddEditPropertyScreenState extends State<AddEditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _superBuiltupController = TextEditingController();
  final _carpetController = TextEditingController();
  final _plotController = TextEditingController();
  final _priceController = TextEditingController();
  final _depositController = TextEditingController();
  final _maintenanceController = TextEditingController();
  final _bedroomsController = TextEditingController(text: '1');
  final _bathroomsController = TextEditingController(text: '1');
  final _balconiesController = TextEditingController(text: '0');
  final _parkingController = TextEditingController(text: '0');
  final _floorNoController = TextEditingController();
  final _totalFloorController = TextEditingController();
  final _ageController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerMobileController = TextEditingController();
  final _brokerNameController = TextEditingController();
  final _remarksController = TextEditingController();
  final _blockWingController = TextEditingController();
  final _flatNoController = TextEditingController();
  TextEditingController _facingController = TextEditingController();
  
  final List<String> _propertyImages = [];
  final List<String> _propertyVideos = [];
  Map<String, dynamic> _additionalDetails = {};
  final Map<String, TextEditingController> _customControllers = {};

  String? _selectedCategory;
  String? _selectedType;
  String? _selectedConfig;
  String? _selectedListingType;
  String? _selectedStatus;
  String? _selectedCity;
  String? _selectedArea;
  String? _selectedFurnishing;
  String? _selectedFacing;
  String? _selectedOwnership;
  String? _googlePlaceId;
  double? _latitude;
  double? _longitude;
  int _mapKeyVersion = 0;
  bool _isReverseGeocoding = false;
  Map<String, dynamic>? _selectedPlaceDetails;
  String? _selectedBrokerage;
  bool _isSaved = false;
  String? _selectedParkingType;
  String? _selectedParkingOption;
  bool _isVerified = false;
  DateTime? _availableDate;
  String? _selectedParkingSlot;

  final List<String> _selectedAmenities = [];
  List<AreaLookup> _filteredAreas = [];
  List<LookupItem> _cities = [];
  List<AreaLookup> _areas = [];
  List<LookupItem> _localAmenities = [];
  final List<String> _depositMonthOptions = ['1 Month', '2 Month', '3 Month', '4 Month', '5 Month', '6 Month'];
  String? _selectedDepositMonth;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _priceController.addListener(_onPriceChanged);
    _remarksController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.property == null && CRMDraftRepository().hasDraft('property')) {
        _showRestoreDraftDialog();
      }
    });
  }

  @override
  void dispose() {
    _priceController.removeListener(_onPriceChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    _superBuiltupController.dispose();
    _carpetController.dispose();
    _plotController.dispose();
    _priceController.dispose();
    _depositController.dispose();
    _maintenanceController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _balconiesController.dispose();
    _parkingController.dispose();
    _floorNoController.dispose();
    _totalFloorController.dispose();
    _ageController.dispose();
    _ownerNameController.dispose();
    _ownerMobileController.dispose();
    _brokerNameController.dispose();
    _remarksController.dispose();
    _blockWingController.dispose();
    _flatNoController.dispose();
    _facingController.dispose();
    _customControllers.forEach((_, c) => c.dispose());
    if (!_isSaved && widget.property == null) {
      _saveCurrentDraft();
    }
    super.dispose();
  }

  void _initializeParkingFields() {
    final parkingVal = int.tryParse(_parkingController.text) ?? 0;
    if (parkingVal >= 11) {
      _selectedParkingType = 'Allocated';
      final optIndex = parkingVal ~/ 10;
      final slotVal = parkingVal % 10;
      if (optIndex == 1) {
        _selectedParkingOption = 'Basement 1';
      } else if (optIndex == 2) {
        _selectedParkingOption = 'Basement 2';
      } else if (optIndex == 3) {
        _selectedParkingOption = 'Ground Floor';
      } else {
        _selectedParkingOption = 'Basement 1';
      }
      _selectedParkingSlot = (slotVal >= 1 && slotVal <= 5) ? slotVal.toString() : '1';
    } else if (parkingVal == 1) {
      _selectedParkingType = 'Allocated';
      _selectedParkingOption = 'Basement 1';
      _selectedParkingSlot = '1';
    } else if (parkingVal == 2) {
      _selectedParkingType = 'Allocated';
      _selectedParkingOption = 'Ground Floor';
      _selectedParkingSlot = '1';
    } else {
      _selectedParkingType = 'Open';
      _selectedParkingOption = null;
      _selectedParkingSlot = null;
    }
  }

  void _updateParkingController() {
    if (_selectedParkingType == 'Open') {
      _parkingController.text = '0';
    } else if (_selectedParkingType == 'Allocated') {
      int optIndex = 1;
      if (_selectedParkingOption == 'Basement 1') {
        optIndex = 1;
      } else if (_selectedParkingOption == 'Basement 2') {
        optIndex = 2;
      } else if (_selectedParkingOption == 'Ground Floor') {
        optIndex = 3;
      }
      final slotVal = int.tryParse(_selectedParkingSlot ?? '1') ?? 1;
      _parkingController.text = '${optIndex * 10 + slotVal}';
    } else {
      _parkingController.text = '0';
    }
  }

  void _initializeForm() {
    _cities = List.from(widget.metadata.cities);
    _areas = List.from(widget.metadata.areas);
    _localAmenities = List.from(widget.metadata.amenities);
    _additionalDetails = widget.property?.additionalDetails != null
        ? Map<String, dynamic>.from(widget.property!.additionalDetails!)
        : {};
    _customControllers.clear();
    _additionalDetails.forEach((key, val) {
      _customControllers[key] = TextEditingController(text: val?.toString() ?? '');
    });

    if (widget.metadata.categories.isNotEmpty) _selectedCategory = widget.metadata.categories.first.id;
    if (widget.metadata.types.isNotEmpty) _selectedType = widget.metadata.types.first.id;
    if (widget.metadata.listingTypes.isNotEmpty) {
      if (widget.property == null && widget.activeListingTab != null) {
        final match = widget.metadata.listingTypes.firstWhere(
          (l) {
            final name = l.name.toLowerCase();
            if (widget.activeListingTab == 'Rent') {
              return name == 'rent' || l.id == 'rent';
            } else {
              return name.contains('sale') || l.id.contains('sale');
            }
          },
          orElse: () => LookupItem(id: '', name: ''),
        );
        _selectedListingType = match.id.isNotEmpty ? match.id : widget.metadata.listingTypes.first.id;
      } else {
        _selectedListingType = widget.metadata.listingTypes.first.id;
      }
    }
    if (widget.metadata.statuses.isNotEmpty) {
      final statuses = widget.metadata.statuses;
      final availIndex = statuses.indexWhere((s) => s.name.trim().toLowerCase() == 'available');
      if (availIndex != -1) {
        final avail = statuses.removeAt(availIndex);
        statuses.insert(0, avail);
      }
      _selectedStatus = statuses.first.id;
    }
    if (_cities.isNotEmpty) {
      _selectedCity = _cities.first.id;
      _updateAreasForCity(_selectedCity!);
    }

    final p = widget.property;
    if (p != null) {
      _titleController.text = p.title;
      _descriptionController.text = p.description ?? '';
      _selectedCategory = p.categoryId;
      _selectedType = p.propertyTypeId;
      _selectedConfig = p.configurationId;
      _selectedListingType = p.listingTypeId;
      _selectedStatus = p.propertyStatusId;
      _isVerified = p.isVerified;
      _availableDate = p.possessionDate;
      _selectedCity = p.cityId;
      _updateAreasForCity(p.cityId);
      _selectedArea = p.areaId;
      _addressController.text = p.address;
      _landmarkController.text = p.landmark ?? '';
      _superBuiltupController.text = p.superBuiltupArea?.toStringAsFixed(0) ?? '';
      _carpetController.text = p.carpetArea?.toStringAsFixed(0) ?? '';
      _plotController.text = p.plotArea?.toStringAsFixed(0) ?? '';
      _priceController.text = CRMCurrencyFormatter.format(p.price);
      _depositController.text = CRMCurrencyFormatter.format(p.deposit);
      _maintenanceController.text = p.maintenance.toStringAsFixed(0);
      final price = p.price;
      final deposit = p.deposit;
      if (price > 0 && deposit > 0) {
        final months = deposit / price;
        final formattedOption = months % 1 == 0 ? '${months.toInt()} Month' : '${months.toStringAsFixed(1)} Month';
        if (!_depositMonthOptions.contains(formattedOption)) {
          _depositMonthOptions.add(formattedOption);
        }
        _selectedDepositMonth = formattedOption;
      }
      _selectedFurnishing = p.furnishingTypeId;
      _selectedFacing = p.facingTypeId;
      if (p.facingTypeId != null) {
        final match = widget.metadata.facings.firstWhere(
          (f) => f.id == p.facingTypeId,
          orElse: () => LookupItem(id: '', name: ''),
        );
        if (match.id.isNotEmpty) {
          _facingController.text = match.name;
        }
      }
      _selectedOwnership = p.ownershipTypeId;
      _googlePlaceId = p.googlePlaceId;
      _latitude = p.latitude;
      _longitude = p.longitude;
      _selectedBrokerage = p.brokerageTypeId;
      _blockWingController.text = p.blockWing ?? '';
      _flatNoController.text = p.flatNo ?? '';
      _propertyImages.addAll(p.images);
      _propertyVideos.addAll(p.videos);
      _bedroomsController.text = p.bedrooms.toString();
      _bathroomsController.text = p.bathrooms.toString();
      _balconiesController.text = p.balconies.toString();
      _parkingController.text = p.parking.toString();
      _initializeParkingFields();
      _floorNoController.text = p.floorNo?.toString() ?? '';
      _totalFloorController.text = p.totalFloor?.toString() ?? '';
      _ageController.text = p.ageOfProperty?.toString() ?? '';
      _ownerNameController.text = p.ownerName;
      _ownerMobileController.text = p.ownerMobile;
      _brokerNameController.text = p.brokerName ?? '';
      _remarksController.text = p.remarks ?? '';

      for (final amName in p.amenities) {
        final matched = widget.metadata.amenities.firstWhere(
          (a) => a.name.toLowerCase() == amName.toLowerCase(),
          orElse: () => LookupItem(id: '', name: ''),
        );
        if (matched.id.isNotEmpty) {
          _selectedAmenities.add(matched.id);
        }
      }
    } else {
      _selectedParkingType = 'Open';
      _selectedParkingOption = null;
      _parkingController.text = '0';
    }
  }


  void _showAddCityDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New City'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'City Name'),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text('Add'),
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                try {
                  final service = PropertiesService();
                  final result = await service.createCity(name);
                  final LookupItem newCity = LookupItem(
                    id: result['data']['city']['id'],
                    name: result['data']['city']['city_name'],
                  );
                  setState(() {
                    _cities.add(newCity);
                    _selectedCity = newCity.id;
                  });
                  _updateAreasForCity(newCity.id);
                  if (mounted) Navigator.pop(ctx);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add city: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openInGoogleMaps() async {
    final lat = _latitude ?? 23.0225;
    final lng = _longitude ?? 72.5714;
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _confirmLocation() async {
    if (_selectedPlaceDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a location on the map first."),
          backgroundColor: CRMColors.warning,
        ),
      );
      return;
    }

    setState(() {
      final place = _selectedPlaceDetails!;
      _addressController.text = place['formattedAddress'] ?? '';
      _googlePlaceId = place['placeId'] ?? '';
      _latitude = place['latitude'];
      _longitude = place['longitude'];

      final String propName = place['propertyName'] ?? '';
      if (propName.isNotEmpty && _titleController.text.trim().isEmpty) {
        _titleController.text = propName;
      }
      
      final String landmark = place['addressLine1'] ?? '';
      if (landmark.isNotEmpty) {
        _landmarkController.text = landmark;
      }

      final String city = place['city'] ?? '';
      if (city.isNotEmpty) {
        final matchedCity = widget.metadata.cities.firstWhere(
          (c) => c.name.toLowerCase() == city.toLowerCase(),
          orElse: () => LookupItem(id: '', name: ''),
        );
        if (matchedCity.id.isNotEmpty) {
          _selectedCity = matchedCity.id;
          _updateAreasForCity(matchedCity.id);
        }
      }

      final String area = place['locality'] ?? '';
      if (area.isNotEmpty) {
        final matchedArea = widget.metadata.areas.firstWhere(
          (a) => a.name.toLowerCase() == area.toLowerCase(),
          orElse: () => AreaLookup(id: '', name: '', cityId: '', pincode: ''),
        );
        if (matchedArea.id.isNotEmpty) {
          _selectedArea = matchedArea.id;
        } else if (_selectedCity != null) {
          _showAddAreaDialog(initialName: area, initialPincode: place['postalCode'] ?? '');
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Location confirmed and address updated!"),
        backgroundColor: CRMColors.success,
      ),
    );
  }

  void _showAddAreaDialog({String? initialName, String? initialPincode}) {
    final nameController = TextEditingController(text: initialName);
    final pincodeController = TextEditingController(text: initialPincode);
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
            title: const Text('Add New Area'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                  if (name.isNotEmpty && pincode.isNotEmpty && _selectedCity != null) {
                    try {
                      final service = PropertiesService();
                      final result = await service.createArea(_selectedCity!, name, pincode);
                      final AreaLookup newArea = AreaLookup(
                        id: result['data']['area']['id'],
                        name: result['data']['area']['area_name'],
                        cityId: result['data']['area']['city_id'],
                        pincode: result['data']['area']['pincode'],
                      );
                      this.setState(() {
                        _areas.add(newArea);
                        _filteredAreas.add(newArea);
                        _selectedArea = newArea.id;
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
        if (_selectedCity != null) {
          _filteredAreas = _areas.where((a) => a.cityId == _selectedCity).toList();
          
          // Auto-select the newly created area if it belongs to the current city
          final addedArea = newAreas.firstWhere(
            (a) => !oldAreaIds.contains(a.id) && a.cityId == _selectedCity,
            orElse: () => AreaLookup(id: '', name: '', cityId: '', pincode: ''),
          );
          if (addedArea.id.isNotEmpty) {
            _selectedArea = addedArea.id;
          }
        }
      });
    } catch (_) {
      // Fail silently
    }
  }

  void _showAddBrokerageDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Brokerage Option'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Option Name (e.g. Direct, Broker)'),
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
              if (name.isNotEmpty) {
                try {
                  final repository = PropertiesRepository();
                  final newItem = await repository.createLookup('brokerage', {'name': name});
                  setState(() {
                    widget.metadata.brokerages.add(newItem);
                    _selectedBrokerage = newItem.id;
                  });
                  if (mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add brokerage: $e')),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _saveCurrentDraft() {
    if (widget.property != null) return;
    final draftData = {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'category_id': _selectedCategory,
      'property_type_id': _selectedType,
      'configuration_id': _selectedConfig,
      'listing_type_id': _selectedListingType,
      'property_status_id': _selectedStatus,
      'city_id': _selectedCity,
      'area_id': _selectedArea,
      'address': _addressController.text,
      'landmark': _landmarkController.text,
      'block_wing': _blockWingController.text,
      'flat_no': _flatNoController.text,
      'google_place_id': _googlePlaceId,
      'latitude': _latitude,
      'longitude': _longitude,
      'brokerage_type_id': _selectedBrokerage,
      'super_builtup_area': _superBuiltupController.text,
      'carpet_area': _carpetController.text,
      'plot_area': _plotController.text,
      'price': _priceController.text,
      'deposit': _depositController.text,
      'maintenance': _maintenanceController.text,
      'furnishing_type_id': _selectedFurnishing,
      'facing_type_id': _selectedFacing,
      'facing_name': _facingController.text,
      'ownership_type_id': _selectedOwnership,
      'bedrooms': _bedroomsController.text,
      'bathrooms': _bathroomsController.text,
      'balconies': _balconiesController.text,
      'parking': _parkingController.text,
      'floor_no': _floorNoController.text,
      'total_floor': _totalFloorController.text,
      'age_of_property': _ageController.text,
      'owner_name': _ownerNameController.text,
      'owner_mobile': _ownerMobileController.text,
      'broker_name': _brokerNameController.text,
      'remarks': _remarksController.text,
      'amenities': _selectedAmenities,
      'images': _propertyImages,
      'videos': _propertyVideos,
    };
    CRMDraftRepository().saveDraft('property', draftData);
  }

  void _showRestoreDraftDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Unsaved Draft?'),
        content: const Text('We found an unsaved draft from your previous session. Would you like to restore it?'),
        actions: [
          TextButton(
            child: const Text('Discard'),
            onPressed: () {
              CRMDraftRepository().clearDraft('property');
              Navigator.pop(ctx);
            },
          ),
          TextButton(
            child: const Text('Restore'),
            onPressed: () {
              final draft = CRMDraftRepository().getDraft('property');
              if (draft != null) {
                setState(() {
                  _titleController.text = draft['title'] ?? '';
                  _descriptionController.text = draft['description'] ?? '';
                  _selectedCategory = draft['category_id'];
                  _selectedType = draft['property_type_id'];
                  _selectedConfig = draft['configuration_id'];
                  _selectedListingType = draft['listing_type_id'];
                  _selectedStatus = draft['property_status_id'];
                  _selectedCity = draft['city_id'];
                  if (_selectedCity != null) {
                    _updateAreasForCity(_selectedCity!);
                  }
                  _selectedArea = draft['area_id'];
                  _addressController.text = draft['address'] ?? '';
                  _landmarkController.text = draft['landmark'] ?? '';
                  _blockWingController.text = draft['block_wing'] ?? '';
                  _flatNoController.text = draft['flat_no'] ?? '';
                  _googlePlaceId = draft['google_place_id'];
                  _latitude = draft['latitude'];
                  _longitude = draft['longitude'];
                  _selectedBrokerage = draft['brokerage_type_id'];
                  _superBuiltupController.text = draft['super_builtup_area'] ?? '';
                  _carpetController.text = draft['carpet_area'] ?? '';
                  _plotController.text = draft['plot_area'] ?? '';
                  _priceController.text = draft['price'] ?? '';
                  _depositController.text = draft['deposit'] ?? '';
                  _maintenanceController.text = draft['maintenance'] ?? '';
                  _selectedFurnishing = draft['furnishing_type_id'];
                  _selectedFacing = draft['facing_type_id'];
                  _facingController.text = draft['facing_name'] ?? '';
                  _selectedOwnership = draft['ownership_type_id'];
                  _bedroomsController.text = draft['bedrooms'] ?? '0';
                  _bathroomsController.text = draft['bathrooms'] ?? '0';
                  _balconiesController.text = draft['balconies'] ?? '0';
                  _parkingController.text = draft['parking'] ?? '0';
                  _initializeParkingFields();
                  _floorNoController.text = draft['floor_no'] ?? '';
                  _totalFloorController.text = draft['total_floor'] ?? '';
                  _ageController.text = draft['age_of_property'] ?? '';
                  _ownerNameController.text = draft['owner_name'] ?? '';
                  _ownerMobileController.text = draft['owner_mobile'] ?? '';
                  _brokerNameController.text = draft['broker_name'] ?? '';
                  _remarksController.text = draft['remarks'] ?? '';
                  
                  final List<String> ams = List<String>.from(draft['amenities'] ?? []);
                  _selectedAmenities.clear();
                  _selectedAmenities.addAll(ams);

                  final List<String> imgs = List<String>.from(draft['images'] ?? []);
                  _propertyImages.clear();
                  _propertyImages.addAll(imgs);

                  final List<String> vids = List<String>.from(draft['videos'] ?? []);
                  _propertyVideos.clear();
                  _propertyVideos.addAll(vids);
                });
              }
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _updateAreasForCity(String cityId) {
    setState(() {
      _filteredAreas = _areas.where((a) => a.cityId == cityId).toList();
      if (_filteredAreas.isNotEmpty) {
        _selectedArea = _filteredAreas.first.id;
      } else {
        _selectedArea = null;
      }
    });
  }

  List<LookupItem> _getFilteredTypes() {
    if (_selectedCategory == null) return [];
    return widget.metadata.types
        .where((t) => t.categoryId == _selectedCategory && t.name.toLowerCase() != 'apartment')
        .toList();
  }

  List<LookupItem> _getFilteredConfigs() {
    if (_selectedCategory == null) return [];
    final category = widget.metadata.categories.firstWhere(
      (cat) => cat.id == _selectedCategory,
      orElse: () => LookupItem(id: '', name: ''),
    );
    final catName = category.name.toLowerCase();

    return widget.metadata.configurations.where((c) {
      final configName = c.name.toLowerCase();

      if (catName.contains('commercial')) {
        return configName.contains('office') ||
            configName.contains('shop') ||
            configName.contains('showroom');
      } else if (catName.contains('land') || catName.contains('plot')) {
        return configName.contains('plot');
      } else if (catName.contains('industrial')) {
        return configName.contains('warehouse') ||
            configName.contains('shed') ||
            configName.contains('industrial');
      } else if (catName.contains('residential')) {
        return !configName.contains('office') &&
            !configName.contains('shop') &&
            !configName.contains('showroom') &&
            !configName.contains('plot') &&
            !configName.contains('warehouse') &&
            !configName.contains('shed') &&
            !configName.contains('industrial');
      }

      return c.categoryId == _selectedCategory;
    }).toList();
  }

  void _onConfigurationChanged(String? val) {
    setState(() {
      _selectedConfig = val;
      if (val != null) {
        final config = widget.metadata.configurations.firstWhere(
          (c) => c.id == val,
          orElse: () => LookupItem(id: '', name: ''),
        );
        final name = config.name.trim();
        final match = RegExp(r'^(\d+)\s*(?:BHK|RK)', caseSensitive: false).firstMatch(name);
        if (match != null) {
          final bedroomsStr = match.group(1);
          if (bedroomsStr != null) {
            _bedroomsController.text = bedroomsStr;
          }
        }
      }
    });
  }

  void _onPriceChanged() {
    if (_selectedListingType != null) {
      final selectedType = widget.metadata.listingTypes.firstWhere(
        (l) => l.id == _selectedListingType,
        orElse: () => LookupItem(id: '', name: ''),
      );
      final isRent = selectedType.name.toLowerCase().contains('rent');
      if (isRent) {
        final price = CRMCurrencyFormatter.parse(_priceController.text);
        if (price > 1000000.0) {
          _priceController.removeListener(_onPriceChanged);
          _priceController.text = CRMCurrencyFormatter.format(1000000.0);
          _priceController.selection = TextSelection.fromPosition(
            TextPosition(offset: _priceController.text.length),
          );
          _priceController.addListener(_onPriceChanged);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Rent price cannot exceed 10 Lakh rupees (1,000,000)."),
              backgroundColor: CRMColors.danger,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
    _calculateDeposit();
  }

  void _calculateDeposit() {
    if (_selectedDepositMonth == null) {
      _depositController.text = CRMCurrencyFormatter.format(0.0);
      return;
    }
    final numberStr = _selectedDepositMonth!.replaceAll(RegExp(r'[^0-9.]'), '');
    final months = double.tryParse(numberStr) ?? 0.0;
    final price = CRMCurrencyFormatter.parse(_priceController.text);
    if (price > 0 && months > 0) {
      final deposit = price * months;
      _depositController.text = CRMCurrencyFormatter.format(deposit);
    } else {
      _depositController.text = CRMCurrencyFormatter.format(0.0);
    }
  }

  void _showAddCustomMonthsDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: CRMColors.cardBgOf(dialogContext),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.dialog)),
          title: Text("Custom Deposit Month", style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(dialogContext))),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
            decoration: InputDecoration(
              hintText: "Enter number of months (e.g. 8, 12 or 2.5)",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
            ),
          ),
          actions: [
            CRMButton(
              label: "Cancel",
              variant: CRMButtonVariant.outline,
              onPressed: () => Navigator.pop(dialogContext),
            ),
            CRMButton(
              label: "Add",
              onPressed: () {
                final text = controller.text.trim();
                final val = double.tryParse(text);
                if (val != null && val > 0) {
                  final option = val % 1 == 0 ? '${val.toInt()} Month' : '$val Month';
                  setState(() {
                    if (!_depositMonthOptions.contains(option)) {
                      _depositMonthOptions.add(option);
                    }
                    _selectedDepositMonth = option;
                    _calculateDeposit();
                  });
                  Navigator.pop(dialogContext);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid positive number')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddMasterDialog(String masterType) {
    final controller = TextEditingController();
    final String friendlyTitle = masterType == 'property-type' ? 'Property Type' :
                                 masterType == 'listing-type' ? 'Listing Type' :
                                 masterType[0].toUpperCase() + masterType.substring(1);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add New $friendlyTitle'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: '$friendlyTitle Name *',
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text('Add'),
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                try {
                  final payload = {'name': name};
                  
                  if (masterType == 'property-type' || masterType == 'configuration') {
                    if (_selectedCategory == null) {
                      throw Exception("Please select a Category first.");
                    }
                    payload['category_id'] = _selectedCategory!;
                  }
                  
                  final repository = PropertiesRepository();
                  final response = await repository.createLookup(masterType, payload);
                  
                  setState(() {
                    if (masterType == 'category') {
                      widget.metadata.categories.add(response);
                      _selectedCategory = response.id;
                      _selectedType = null;
                      _selectedConfig = null;
                    } else if (masterType == 'property-type') {
                      widget.metadata.types.add(response);
                      _selectedType = response.id;
                    } else if (masterType == 'configuration') {
                      widget.metadata.configurations.add(response);
                      _selectedConfig = response.id;
                    } else if (masterType == 'listing-type') {
                      widget.metadata.listingTypes.add(response);
                      _selectedListingType = response.id;
                    }
                  });
                  
                  if (mounted) Navigator.pop(ctx);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll("Exception: ", "")),
                      backgroundColor: CRMColors.danger,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _submitForm() async {
    if (!CRMFormUtils.validateAndScroll(_formKey, context)) return;

    final selectedType = widget.metadata.listingTypes.firstWhere(
      (l) => l.id == _selectedListingType,
      orElse: () => LookupItem(id: '', name: ''),
    );
    final isRent = selectedType.name.toLowerCase().contains('rent');
    final price = CRMCurrencyFormatter.parse(_priceController.text);
    if (isRent && price > 1000000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Warning: Rent price exceeds 10 Lakh rupees (1,000,000)."),
          backgroundColor: Colors.orange,
        ),
      );
    }

    final toBeAvailableStatus = widget.metadata.statuses.firstWhere(
      (s) => s.name.toLowerCase().contains('to be available'),
      orElse: () => LookupItem(id: '', name: ''),
    );
    final String toBeAvailableId = toBeAvailableStatus.id;

    if (toBeAvailableId.isNotEmpty && _selectedStatus == toBeAvailableId && _availableDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select an Available Date for 'To Be Available' status."),
          backgroundColor: CRMColors.danger,
        ),
      );
      return;
    }

    final flat = _flatNoController.text.trim().toLowerCase();
    final block = _blockWingController.text.trim().toLowerCase();
    final landmark = _landmarkController.text.trim().toLowerCase();

    if (flat.isNotEmpty) {
      try {
        final allProps = await RepositoryCoordinator().propertyLocal.getProperties();
        final isDuplicate = allProps.any((p) =>
          p.id != widget.property?.id &&
          p.flatNo?.toLowerCase() == flat &&
          p.blockWing?.toLowerCase() == block &&
          p.landmark?.toLowerCase() == landmark
        );
        if (isDuplicate) {
          if (mounted) {
            final proceed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.card)),
                backgroundColor: CRMColors.surfaceElevatedOf(context),
                title: Text('Duplicate Property Detected', style: CRMTypography.sectionTitle),
                content: Text(
                  'An active property with the same Flat No ("${_flatNoController.text}"), Block/Wing ("${_blockWingController.text}"), and Landmark ("${_landmarkController.text}") already exists.\n\nAre you sure you want to save this duplicate property?',
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final toBeAvailableStatus = widget.metadata.statuses.firstWhere(
        (s) => s.name.toLowerCase().contains('to be available'),
        orElse: () => LookupItem(id: '', name: ''),
      );
      final String toBeAvailableId = toBeAvailableStatus.id;

      final selectedTypeItem = widget.metadata.types.firstWhere(
        (t) => t.id == _selectedType,
        orElse: () => LookupItem(id: '', name: ''),
      );
      final propertyTypeName = selectedTypeItem.name.trim().toLowerCase();
      final selectedCategoryItem = widget.metadata.categories.firstWhere(
        (c) => c.id == _selectedCategory,
        orElse: () => LookupItem(id: '', name: ''),
      );
      final categoryName = selectedCategoryItem.name.trim().toLowerCase();
      final isLandOrIndustrial = categoryName.contains('land') || 
                                 categoryName.contains('plot') || 
                                 categoryName.contains('industrial');
      final isBungalow = !isLandOrIndustrial && (
                         propertyTypeName.contains('bungalow') || 
                         propertyTypeName.contains('villa') || 
                         propertyTypeName.contains('rowhouse') || 
                         propertyTypeName.contains('house') || 
                         propertyTypeName.contains('tenament'));

      final String typedFacing = _facingController.text.trim();
      if (typedFacing.isNotEmpty) {
        final match = widget.metadata.facings.firstWhere(
          (f) => f.name.trim().toLowerCase() == typedFacing.toLowerCase(),
          orElse: () => LookupItem(id: '', name: ''),
        );
        if (match.id.isNotEmpty) {
          _selectedFacing = match.id;
        } else {
          final repository = PropertiesRepository();
          final newFacing = await repository.createLookup("facing", {"name": typedFacing});
          widget.metadata.facings.add(newFacing);
          _selectedFacing = newFacing.id;
        }
      } else {
        _selectedFacing = null;
      }

      final propertyData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        'category_id': _selectedCategory,
        'property_type_id': _selectedType,
        'configuration_id': _selectedConfig,
        'listing_type_id': _selectedListingType,
        'property_status_id': _selectedStatus,
        'city_id': _selectedCity,
        'area_id': _selectedArea,
        'address': _addressController.text.trim(),
        'landmark': _landmarkController.text.trim().isEmpty ? null : _landmarkController.text.trim(),
        'block_wing': _blockWingController.text.trim().isEmpty ? null : _blockWingController.text.trim(),
        'flat_no': _flatNoController.text.trim().isEmpty ? null : _flatNoController.text.trim(),
        'google_place_id': _googlePlaceId,
        'formatted_address': _addressController.text.trim(),
        'address_line1': _selectedPlaceDetails != null ? _selectedPlaceDetails!['addressLine1'] : _landmarkController.text.trim(),
        'locality': _selectedPlaceDetails != null ? _selectedPlaceDetails!['locality'] : null,
        'city': _selectedPlaceDetails != null ? _selectedPlaceDetails!['city'] : null,
        'state': _selectedPlaceDetails != null ? _selectedPlaceDetails!['state'] : null,
        'country': _selectedPlaceDetails != null ? _selectedPlaceDetails!['country'] : null,
        'postal_code': _selectedPlaceDetails != null ? _selectedPlaceDetails!['postalCode'] : null,
        'latitude': _latitude,
        'longitude': _longitude,
        'brokerage_type_id': _selectedBrokerage,
        'super_builtup_area': double.tryParse(_superBuiltupController.text),
        'carpet_area': double.tryParse(_carpetController.text),
        'plot_area': double.tryParse(_plotController.text),
        'price': CRMCurrencyFormatter.parse(_priceController.text),
        'deposit': CRMCurrencyFormatter.parse(_depositController.text),
        'maintenance': double.tryParse(_maintenanceController.text) ?? 0.0,
        'furnishing_type_id': _selectedFurnishing,
        'facing_type_id': _selectedFacing,
        'ownership_type_id': _selectedOwnership,
        'bedrooms': int.tryParse(_bedroomsController.text) ?? 0,
        'bathrooms': int.tryParse(_bathroomsController.text) ?? 0,
        'balconies': int.tryParse(_balconiesController.text) ?? 0,
        'parking': int.tryParse(_parkingController.text) ?? 0,
        'floor_no': isBungalow ? null : int.tryParse(_floorNoController.text),
        'total_floor': isBungalow ? null : int.tryParse(_totalFloorController.text),
        'age_of_property': int.tryParse(_ageController.text),
        'owner_name': _ownerNameController.text.trim(),
        'owner_mobile': _ownerMobileController.text.trim(),
        'broker_name': _brokerNameController.text.trim().isEmpty ? null : _brokerNameController.text.trim(),
        'remarks': _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
        'amenities': _selectedAmenities,
        'images': _propertyImages,
        'videos': _propertyVideos,
        'additional_details': _additionalDetails,
        'is_verified': _isVerified,
        'possession_date': (toBeAvailableId.isNotEmpty && _selectedStatus == toBeAvailableId)
            ? _availableDate?.toIso8601String().substring(0, 10)
            : null,
      };

      if (widget.property == null) {
        final repository = PropertiesRepository();
        final duplicateResult = await repository.checkDuplicate({
          'property_type_id': _selectedType,
          'title': _titleController.text.trim(),
          'flat_no': _flatNoController.text.trim(),
          'block_wing': _blockWingController.text.trim(),
          'latitude': _latitude,
          'longitude': _longitude,
          'google_place_id': _googlePlaceId,
          'owner_mobile': _ownerMobileController.text.trim(),
        });

        if (duplicateResult['duplicate'] == true) {
          if (mounted) {
            Navigator.pop(context); // pop loading spinner
          }

          final details = duplicateResult['details'] as Map<String, dynamic>? ?? {};
          final propName = details['propertyName'] ?? 'Unknown';
          final ownerName = details['ownerName'] ?? 'Unknown';
          final createdBy = details['createdBy'] ?? 'Unknown';

          final bool proceed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: CRMColors.warning),
                  SizedBox(width: 8),
                  Text('Possible Duplicate'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('A similar property already exists:'),
                  const SizedBox(height: 8),
                  Text('Property: $propName', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Owner: $ownerName'),
                  Text('Added by: $createdBy'),
                  const SizedBox(height: 16),
                  const Text('Do you want to create this anyway?'),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(ctx, false),
                ),
                TextButton(
                  child: const Text('Create Anyway'),
                  onPressed: () => Navigator.pop(ctx, true),
                ),
              ],
            ),
          ) ?? false;

          if (!proceed) {
            return; // Abort submission
          }

          // Show loader again
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(child: CircularProgressIndicator()),
            );
          }
        }
      }

      if (mounted) {
        Navigator.pop(context); // pop loading spinner
      }

      if (widget.property == null) {
        context.read<PropertiesBloc>().add(
              CreatePropertyEvent(propertyData, activeTab: widget.activeTab),
            );
      } else {
        context.read<PropertiesBloc>().add(
              UpdatePropertyEvent(widget.property!.id, propertyData, activeTab: widget.activeTab),
            );
      }

      _isSaved = true;
      CRMDraftRepository().clearDraft('property');
      if (mounted) {
        Navigator.pop(context); // close form screen
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // pop loading spinner
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to publish property: $e"), backgroundColor: CRMColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.property != null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(isEdit ? 'Edit CRM Listing' : 'Add New Property', style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context))),
            backgroundColor: CRMColors.cardBgOf(context),
            elevation: 0,
            surfaceTintColor: Colors.transparent,
          ),
          body: CRMForm(
            formKey: _formKey,
            isDirty: true,
            onSave: () async {
              _submitForm();
              return true;
            },
            child: Column(
              children: [
                _buildWizardProgress(isMobile),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? CRMSpacing.s : CRMSpacing.l),
                    child: _buildActiveStepContent(isMobile),
                  ),
                ),
                _buildWizardActions(isEdit),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWizardProgress(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: CRMColors.cardBgOf(context),
        border: Border(
          bottom: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.5), width: 0.5),
        ),
      ),
      padding: EdgeInsets.symmetric(
        vertical: CRMSpacing.m,
        horizontal: isMobile ? CRMSpacing.s : CRMSpacing.l,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStepNode(0, 'Basic Info', isMobile),
          _buildStepDivider(),
          _buildStepNode(1, 'Location', isMobile),
          _buildStepDivider(),
          _buildStepNode(2, 'Pricing', isMobile),
          _buildStepDivider(),
          _buildStepNode(3, 'Contacts', isMobile),
        ],
      ),
    );
  }

  Widget _buildStepNode(int index, String label, bool isMobile) {
    final isActive = _currentStep == index;
    final isPassed = _currentStep > index;

    return Row(
      children: [
        AnimatedContainer(
          duration: CRMMotion.fast,
          curve: CRMMotion.easeOut,
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isPassed
                ? CRMColors.success
                : (isActive ? CRMColors.primaryOf(context) : CRMColors.borderOf(context)),
          ),
          alignment: Alignment.center,
          child: isPassed
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : Text('${index + 1}', style: TextStyle(color: isActive ? Colors.white : CRMColors.textSecondaryOf(context), fontSize: 12)),
        ),
        if (!isMobile) ...[
          const SizedBox(width: CRMSpacing.xs),
          Text(
            label,
            style: CRMTypography.captionBold.copyWith(
              color: isActive ? CRMColors.primaryOf(context) : CRMColors.textSecondaryOf(context),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStepDivider() {
    return Expanded(
      child: Divider(
        color: CRMColors.borderOf(context).withOpacity(0.6),
        thickness: 0.5,
        indent: 8,
        endIndent: 8,
      ),
    );
  }

  Widget _buildActiveStepContent(bool isMobile) {
    switch (_currentStep) {
      case 0:
        return _buildBasicStep(isMobile);
      case 1:
        return _buildLocationStep(isMobile);
      case 2:
        return _buildPricingStep(isMobile);
      case 3:
        return _buildContactsStep(isMobile);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBasicStep(bool isMobile) {
    final selectedCategoryItem = widget.metadata.categories.firstWhere(
      (c) => c.id == _selectedCategory,
      orElse: () => LookupItem(id: '', name: ''),
    );
    final categoryName = selectedCategoryItem.name.trim().toLowerCase();
    final isLandOrIndustrial = categoryName.contains('land') || 
                               categoryName.contains('plot') || 
                               categoryName.contains('industrial');

    final filteredTypes = _getFilteredTypes();
    if (_selectedType != null && !filteredTypes.any((t) => t.id == _selectedType)) {
      _selectedType = filteredTypes.isNotEmpty ? filteredTypes.first.id : null;
    }
    final filteredConfigs = _getFilteredConfigs();
    if (_selectedConfig != null && !filteredConfigs.any((c) => c.id == _selectedConfig)) {
      _selectedConfig = null;
    }

    final selectedListingTypeItem = widget.metadata.listingTypes.firstWhere(
      (l) => l.id == _selectedListingType,
      orElse: () => LookupItem(id: '', name: ''),
    );
    final listingName = selectedListingTypeItem.name.trim().toLowerCase();
    final isRent = listingName.contains('rent');

    final filteredStatuses = widget.metadata.statuses.where((s) {
      final name = s.name.toLowerCase();
      if (isRent) {
        return name == 'available' || name.contains('rented out') || name.contains('to be available');
      } else {
        return name == 'available' || name.contains('sold out') || name == 'sold';
      }
    }).toList();

    final toBeAvailableStatus = widget.metadata.statuses.firstWhere(
      (s) => s.name.toLowerCase().contains('to be available'),
      orElse: () => LookupItem(id: '', name: ''),
    );
    final String toBeAvailableId = toBeAvailableStatus.id;

    if (_selectedStatus != null && !filteredStatuses.any((s) => s.id == _selectedStatus)) {
      _selectedStatus = filteredStatuses.isNotEmpty ? filteredStatuses.first.id : null;
    }

    return CRMCard(
      title: 'Basic Property Setup',
      subtitle: 'Complete listing definitions and categories',
      padding: isMobile ? const EdgeInsets.all(CRMSpacing.s) : const EdgeInsets.all(CRMSpacing.m),
      child: Column(
        children: [
          TextFormField(
            controller: _titleController,
            style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
            decoration: InputDecoration(
              labelText: 'Location / Property Name *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
              suffixIcon: IconButton(
                icon: Icon(Icons.search, color: CRMColors.primaryOf(context)),
                onPressed: _showSearchPropertyDialog,
                tooltip: 'Search existing properties',
              ),
            ),
            validator: (v) => v!.isEmpty ? 'Location / Property Name is required' : null,
          ),
          const SizedBox(height: CRMSpacing.m),

          if (isMobile) ...[
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                    ),
                    items: widget.metadata.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedCategory = v;
                        _selectedType = null;
                        _selectedConfig = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: CRMSpacing.xs),
                IconButton(
                  icon: Icon(Icons.add_circle_outline_rounded, color: CRMColors.primaryOf(context)),
                  onPressed: () => _showAddMasterDialog('category'),
                  tooltip: 'Add Category',
                ),
              ],
            ),
            const SizedBox(height: CRMSpacing.m),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedListingType,
                    decoration: InputDecoration(
                      labelText: 'Listing Type *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                    ),
                    items: widget.metadata.listingTypes.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedListingType = v;
                        final selectedListingTypeItem = widget.metadata.listingTypes.firstWhere(
                          (l) => l.id == _selectedListingType,
                          orElse: () => LookupItem(id: '', name: ''),
                        );
                        final listingName = selectedListingTypeItem.name.trim();
                        final isRent = listingName.toLowerCase() == 'rent' || selectedListingTypeItem.id == 'rent';
                        if (!isRent) {
                          _selectedDepositMonth = null;
                          _depositController.text = CRMCurrencyFormatter.format(0.0);
                          _maintenanceController.text = '';
                        }
                        _onPriceChanged();
                      });
                    },
                  ),
                ),
                const SizedBox(width: CRMSpacing.xs),
                IconButton(
                  icon: Icon(Icons.add_circle_outline_rounded, color: CRMColors.primaryOf(context)),
                  onPressed: () => _showAddMasterDialog('listing-type'),
                  tooltip: 'Add Listing Type',
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Category *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                          ),
                          items: widget.metadata.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                          onChanged: (v) {
                            setState(() {
                              _selectedCategory = v;
                              _selectedType = null;
                              _selectedConfig = null;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: CRMSpacing.xs),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline_rounded, color: CRMColors.primaryOf(context)),
                        onPressed: () => _showAddMasterDialog('category'),
                        tooltip: 'Add Category',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: CRMSpacing.s),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedListingType,
                          decoration: InputDecoration(
                            labelText: 'Listing Type *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                          ),
                          items: widget.metadata.listingTypes.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
                          onChanged: (v) {
                            setState(() {
                              _selectedListingType = v;
                              final selectedListingTypeItem = widget.metadata.listingTypes.firstWhere(
                                (l) => l.id == _selectedListingType,
                                orElse: () => LookupItem(id: '', name: ''),
                              );
                              final listingName = selectedListingTypeItem.name.trim();
                              final isRent = listingName.toLowerCase() == 'rent' || selectedListingTypeItem.id == 'rent';
                              if (!isRent) {
                                _selectedDepositMonth = null;
                                _depositController.text = CRMCurrencyFormatter.format(0.0);
                                _maintenanceController.text = '';
                              }
                              _onPriceChanged();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: CRMSpacing.xs),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline_rounded, color: CRMColors.primaryOf(context)),
                        onPressed: () => _showAddMasterDialog('listing-type'),
                        tooltip: 'Add Listing Type',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: CRMSpacing.m),
          if (isMobile) ...[
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedType,
                    decoration: InputDecoration(
                      labelText: 'Property Type *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                    ),
                    items: filteredTypes.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                    onChanged: (v) => setState(() => _selectedType = v),
                  ),
                ),
                const SizedBox(width: CRMSpacing.xs),
                IconButton(
                  icon: Icon(Icons.add_circle_outline_rounded, color: CRMColors.primaryOf(context)),
                  onPressed: () => _showAddMasterDialog('property-type'),
                  tooltip: 'Add Property Type',
                ),
              ],
            ),
            if (!isLandOrIndustrial) ...[
              const SizedBox(height: CRMSpacing.m),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedConfig,
                      decoration: InputDecoration(
                        labelText: 'Configuration',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None')),
                        ...filteredConfigs.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                      ],
                      onChanged: _onConfigurationChanged,
                    ),
                  ),
                  const SizedBox(width: CRMSpacing.xs),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline_rounded, color: CRMColors.primaryOf(context)),
                    onPressed: () => _showAddMasterDialog('configuration'),
                    tooltip: 'Add Configuration',
                  ),
                ],
              ),
            ],
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedType,
                          decoration: InputDecoration(
                            labelText: 'Property Type *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                          ),
                          items: filteredTypes.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                          onChanged: (v) => setState(() => _selectedType = v),
                        ),
                      ),
                      const SizedBox(width: CRMSpacing.xs),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline_rounded, color: CRMColors.primaryOf(context)),
                        onPressed: () => _showAddMasterDialog('property-type'),
                        tooltip: 'Add Property Type',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: CRMSpacing.s),
                Expanded(
                  child: !isLandOrIndustrial
                      ? Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: _selectedConfig,
                                decoration: InputDecoration(
                                  labelText: 'Configuration',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                                ),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('None')),
                                  ...filteredConfigs.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                                ],
                                onChanged: _onConfigurationChanged,
                              ),
                            ),
                            const SizedBox(width: CRMSpacing.xs),
                            IconButton(
                              icon: Icon(Icons.add_circle_outline_rounded, color: CRMColors.primaryOf(context)),
                              onPressed: () => _showAddMasterDialog('configuration'),
                              tooltip: 'Add Configuration',
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
          const SizedBox(height: CRMSpacing.m),
          if (isMobile && toBeAvailableId.isNotEmpty && _selectedStatus == toBeAvailableId) ...[
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _selectedStatus,
              decoration: InputDecoration(
                labelText: 'Property Status *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
              ),
              items: filteredStatuses.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
              onChanged: (v) {
                setState(() {
                  _selectedStatus = v;
                  if (v == toBeAvailableId && _availableDate == null) {
                    _availableDate = DateTime.now();
                  }
                });
              },
            ),
            const SizedBox(height: CRMSpacing.m),
            CRMDatePicker(
              labelText: 'Available Date',
              initialDate: _availableDate,
              isRequired: true,
              onDateSelected: (date) {
                setState(() {
                  _availableDate = date;
                });
              },
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Property Status *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                    ),
                    items: filteredStatuses.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedStatus = v;
                        if (v == toBeAvailableId && _availableDate == null) {
                          _availableDate = DateTime.now();
                        }
                      });
                    },
                  ),
                ),
                if (toBeAvailableId.isNotEmpty && _selectedStatus == toBeAvailableId) ...[
                  const SizedBox(width: CRMSpacing.m),
                  Expanded(
                    child: CRMDatePicker(
                      labelText: 'Available Date',
                      initialDate: _availableDate,
                      isRequired: true,
                      onDateSelected: (date) {
                        setState(() {
                          _availableDate = date;
                        });
                      },
                    ),
                  ),
                ],
              ],
            ),
          ],
          CRMImagePicker(
            imageUrls: _propertyImages,
            onImageAdded: (url) {
              setState(() {
                _propertyImages.add(url);
              });
            },
            onImageRemoved: (index) {
              setState(() {
                _propertyImages.removeAt(index);
              });
            },
            onImageReplaced: (index, url) {
              setState(() {
                _propertyImages[index] = url;
              });
            },
            onImagesReordered: (newUrls) {
              setState(() {
                _propertyImages.clear();
                _propertyImages.addAll(newUrls);
              });
            },
            maxImages: 10,
            uploadEndpoint: '/properties/upload-media',
          ),
          const SizedBox(height: CRMSpacing.m),
          CRMVideoPicker(
            videoUrls: _propertyVideos,
            onVideoAdded: (url) {
              setState(() {
                _propertyVideos.add(url);
              });
            },
            onVideoRemoved: (index) {
              setState(() {
                _propertyVideos.removeAt(index);
              });
            },
            maxVideos: 2,
            uploadEndpoint: '/properties/upload-media',
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep(bool isMobile) {
    final selectedCategoryItem = widget.metadata.categories.firstWhere(
      (c) => c.id == _selectedCategory,
      orElse: () => LookupItem(id: '', name: ''),
    );
    final categoryName = selectedCategoryItem.name.trim().toLowerCase();
    final isCommercial = categoryName.contains('commercial') || selectedCategoryItem.id == 'commercial';
    final flatNoLabel = isCommercial ? 'Office / Shop Number' : 'Flat Number';

    final cityField = Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            value: _selectedCity,
            decoration: InputDecoration(
              labelText: 'City *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
            ),
            items: _cities.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
            onChanged: (v) {
              setState(() => _selectedCity = v);
              if (v != null) _updateAreasForCity(v);
            },
          ),
        ),
        IconButton(
          icon: Icon(Icons.add_circle_outline_rounded, color: CRMColors.primaryOf(context)),
          onPressed: _showAddCityDialog,
          tooltip: 'Add New City',
        ),
      ],
    );

    final areaField = Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            value: _selectedArea,
            decoration: InputDecoration(
              labelText: 'Area *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
            ),
            items: _filteredAreas.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
            onChanged: (v) => setState(() => _selectedArea = v),
          ),
        ),
        IconButton(
          icon: Icon(Icons.add_circle_outline_rounded, color: CRMColors.primaryOf(context)),
          onPressed: _selectedCity == null
              ? null
              : () => _showAddAreaDialog(),
          tooltip: 'Add New Area',
        ),
      ],
    );

    final selectedTypeItem = widget.metadata.types.firstWhere(
      (t) => t.id == _selectedType,
      orElse: () => LookupItem(id: '', name: ''),
    );
    final propertyTypeName = selectedTypeItem.name.trim().toLowerCase();
    final isLandOrIndustrial = categoryName.contains('land') || 
                               categoryName.contains('plot') || 
                               categoryName.contains('industrial');
    final isBungalow = !isLandOrIndustrial && (
                       propertyTypeName.contains('bungalow') || 
                       propertyTypeName.contains('villa') || 
                       propertyTypeName.contains('rowhouse') || 
                       propertyTypeName.contains('house') || 
                       propertyTypeName.contains('tenament'));

    final blockWingField = TextFormField(
      controller: _blockWingController,
      style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
      decoration: InputDecoration(
        labelText: 'Block / Wing',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
      ),
    );

    final flatNoField = TextFormField(
      controller: _flatNoController,
      style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
      decoration: InputDecoration(
        labelText: flatNoLabel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
      ),
    );

    return CRMCard(
      title: 'Location Mapping',
      subtitle: 'Specify geo-coordinates and landmark directions',
      padding: isMobile ? const EdgeInsets.all(CRMSpacing.s) : const EdgeInsets.all(CRMSpacing.m),
      child: Column(
        children: [
          if (isMobile) ...[
            cityField,
            const SizedBox(height: CRMSpacing.m),
            areaField,
          ] else ...[
            Row(
              children: [
                Expanded(child: cityField),
                const SizedBox(width: CRMSpacing.s),
                Expanded(child: areaField),
              ],
            ),
          ],
          if (!isLandOrIndustrial) ...[
            const SizedBox(height: CRMSpacing.m),
            if (isBungalow) ...[
              blockWingField,
            ] else if (isMobile) ...[
              blockWingField,
              const SizedBox(height: CRMSpacing.m),
              flatNoField,
            ] else ...[
              Row(
                children: [
                  Expanded(child: blockWingField),
                  const SizedBox(width: CRMSpacing.s),
                  Expanded(child: flatNoField),
                ],
              ),
            ],
          ],
          const SizedBox(height: CRMSpacing.m),
          TextFormField(
            controller: _addressController,
            style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Address Details *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
            ),
          ),
          const SizedBox(height: CRMSpacing.m),
          TextFormField(
            controller: _landmarkController,
            style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
            decoration: InputDecoration(
              labelText: 'Landmark / Building Name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTextField({
    required String label,
    required String key,
    bool isNumeric = false,
    bool isRequired = false,
  }) {
    if (!_customControllers.containsKey(key)) {
      _customControllers[key] = TextEditingController(text: _additionalDetails[key]?.toString() ?? '');
    }
    final controller = _customControllers[key]!;
    return TextFormField(
      controller: controller,
      style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: '$label${isRequired ? ' *' : ''}',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
      ),
      validator: (v) {
        if (isRequired && (v == null || v.trim().isEmpty)) {
          return '$label is required';
        }
        return null;
      },
      onChanged: (val) {
        _additionalDetails[key] = isNumeric ? (double.tryParse(val) ?? val) : val;
      },
    );
  }

  Widget _buildCustomBooleanField({
    required String label,
    required String key,
    bool isRequired = false,
  }) {
    final bool value = _additionalDetails[key] == true;
    return CheckboxListTile(
      title: Text(label, style: CRMTypography.body.copyWith(color: CRMColors.textOf(context))),
      value: value,
      activeColor: CRMColors.primaryOf(context),
      onChanged: (val) {
        setState(() {
          _additionalDetails[key] = val;
        });
      },
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildCustomDropdownField({
    required String label,
    required String key,
    required List<String> options,
    bool isRequired = false,
  }) {
    final value = _additionalDetails[key]?.toString();
    final selectedValue = options.contains(value) ? value : null;
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: selectedValue,
      decoration: InputDecoration(
        labelText: '$label${isRequired ? ' *' : ''}',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('None')),
        ...options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))),
      ],
      validator: (v) {
        if (isRequired && (v == null || v.isEmpty)) {
          return '$label is required';
        }
        return null;
      },
      onChanged: (val) {
        setState(() {
          _additionalDetails[key] = val;
        });
      },
    );
  }

  Widget _buildLandDetailsSection(bool isMobile, bool isLand, bool isIndustrial) {
    if (!isLand && !isIndustrial) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: CRMSpacing.l),
        Text('Land Details', style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context))),
        const SizedBox(height: CRMSpacing.s),
        if (isMobile) ...[
          _buildCustomTextField(label: 'Plot Length (Ft)', key: 'plot_length', isNumeric: true, isRequired: isLand),
          const SizedBox(height: CRMSpacing.m),
          _buildCustomTextField(label: 'Plot Width (Ft)', key: 'plot_width', isNumeric: true, isRequired: isLand),
          const SizedBox(height: CRMSpacing.m),
          _buildCustomTextField(label: 'Frontage (Ft)', key: 'frontage', isNumeric: true, isRequired: false),
          const SizedBox(height: CRMSpacing.m),
          _buildCustomTextField(label: 'Road Width (Ft)', key: 'road_width', isNumeric: true, isRequired: false),
          const SizedBox(height: CRMSpacing.m),
          if (isLand) ...[
            _buildCustomDropdownField(label: 'Plot Shape', key: 'plot_shape', options: ['Square', 'Rectangle', 'Triangular', 'Irregular', 'Other'], isRequired: false),
            const SizedBox(height: CRMSpacing.m),
          ],
          _buildCustomBooleanField(label: 'Corner Plot', key: 'corner_plot'),
          _buildCustomBooleanField(label: 'Boundary Wall', key: 'boundary_wall'),
          _buildCustomBooleanField(label: 'Gate', key: 'gate'),
        ] else ...[
          Row(
            children: [
              Expanded(child: _buildCustomTextField(label: 'Plot Length (Ft)', key: 'plot_length', isNumeric: true, isRequired: isLand)),
              const SizedBox(width: CRMSpacing.s),
              Expanded(child: _buildCustomTextField(label: 'Plot Width (Ft)', key: 'plot_width', isNumeric: true, isRequired: isLand)),
            ],
          ),
          const SizedBox(height: CRMSpacing.m),
          Row(
            children: [
              Expanded(child: _buildCustomTextField(label: 'Frontage (Ft)', key: 'frontage', isNumeric: true, isRequired: false)),
              const SizedBox(width: CRMSpacing.s),
              Expanded(child: _buildCustomTextField(label: 'Road Width (Ft)', key: 'road_width', isNumeric: true, isRequired: false)),
            ],
          ),
          const SizedBox(height: CRMSpacing.m),
          Row(
            children: [
              if (isLand) ...[
                Expanded(child: _buildCustomDropdownField(label: 'Plot Shape', key: 'plot_shape', options: ['Square', 'Rectangle', 'Triangular', 'Irregular', 'Other'], isRequired: false)),
                const SizedBox(width: CRMSpacing.s),
              ],
              Expanded(child: _buildCustomBooleanField(label: 'Corner Plot', key: 'corner_plot')),
              if (!isLand) const Expanded(child: SizedBox()),
            ],
          ),
          Row(
            children: [
              Expanded(child: _buildCustomBooleanField(label: 'Boundary Wall', key: 'boundary_wall')),
              const SizedBox(width: CRMSpacing.s),
              Expanded(child: _buildCustomBooleanField(label: 'Gate', key: 'gate')),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildLegalDetailsSection(bool isMobile, bool isLand, bool isIndustrial) {
    if (!isLand && !isIndustrial) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: CRMSpacing.l),
        Text('Legal Details', style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context))),
        const SizedBox(height: CRMSpacing.s),
        if (isMobile) ...[
          _buildCustomTextField(label: 'Survey Number', key: 'survey_number', isRequired: false),
          const SizedBox(height: CRMSpacing.m),
          if (isLand) ...[
            _buildCustomTextField(label: 'TP Scheme', key: 'tp_scheme', isRequired: false),
            const SizedBox(height: CRMSpacing.m),
            _buildCustomTextField(label: 'Final Plot Number', key: 'final_plot_number', isRequired: false),
            const SizedBox(height: CRMSpacing.m),
            _buildCustomDropdownField(label: 'NA Status', key: 'na_status', options: ['NA (Non-Agricultural)', 'NOC Pending', 'Agricultural', 'Commercial NA', 'Residential NA', 'Other'], isRequired: false),
            const SizedBox(height: CRMSpacing.m),
          ],
          _buildCustomTextField(label: 'Zone', key: 'zone', isRequired: !isLand && !isIndustrial),
          const SizedBox(height: CRMSpacing.m),
          if (isLand) ...[
            _buildCustomTextField(label: 'RERA Number', key: 'rera'),
            const SizedBox(height: CRMSpacing.m),
          ],
          _buildCustomBooleanField(label: 'Title Clear', key: 'title_clear'),
          if (isIndustrial) ...[
            _buildCustomBooleanField(label: 'Occupancy Certificate (OC)', key: 'occupancy_certificate'),
            _buildCustomBooleanField(label: 'Fire NOC', key: 'fire_noc'),
            _buildCustomBooleanField(label: 'Pollution Clearance', key: 'pollution_clearance'),
            _buildCustomBooleanField(label: 'Factory License', key: 'factory_license'),
          ],
        ] else ...[
          Row(
            children: [
              Expanded(child: _buildCustomTextField(label: 'Survey Number', key: 'survey_number', isRequired: false)),
              const SizedBox(width: CRMSpacing.s),
              if (isLand) ...[
                Expanded(child: _buildCustomTextField(label: 'TP Scheme', key: 'tp_scheme', isRequired: false)),
              ] else ...[
                Expanded(child: _buildCustomTextField(label: 'Zone', key: 'zone', isRequired: !isLand && !isIndustrial)),
              ],
            ],
          ),
          const SizedBox(height: CRMSpacing.m),
          Row(
            children: [
              if (isLand) ...[
                Expanded(child: _buildCustomTextField(label: 'Final Plot Number', key: 'final_plot_number', isRequired: false)),
                const SizedBox(width: CRMSpacing.s),
                Expanded(child: _buildCustomDropdownField(label: 'NA Status', key: 'na_status', options: ['NA (Non-Agricultural)', 'NOC Pending', 'Agricultural', 'Commercial NA', 'Residential NA', 'Other'], isRequired: false)),
              ] else ...[
                Expanded(child: _buildCustomBooleanField(label: 'Title Clear', key: 'title_clear')),
                const SizedBox(width: CRMSpacing.s),
                Expanded(child: _buildCustomBooleanField(label: 'Occupancy Certificate (OC)', key: 'occupancy_certificate')),
              ],
            ],
          ),
          const SizedBox(height: CRMSpacing.m),
          Row(
            children: [
              if (isLand) ...[
                Expanded(child: _buildCustomTextField(label: 'Zone', key: 'zone', isRequired: !isLand && !isIndustrial)),
                const SizedBox(width: CRMSpacing.s),
                Expanded(child: _buildCustomTextField(label: 'RERA Number', key: 'rera')),
              ] else ...[
                Expanded(child: _buildCustomBooleanField(label: 'Fire NOC', key: 'fire_noc')),
                const SizedBox(width: CRMSpacing.s),
                Expanded(child: _buildCustomBooleanField(label: 'Pollution Clearance', key: 'pollution_clearance')),
              ],
            ],
          ),
          if (isLand) ...[
            const SizedBox(height: CRMSpacing.m),
            Row(
              children: [
                Expanded(child: _buildCustomBooleanField(label: 'Title Clear', key: 'title_clear')),
                const SizedBox(width: CRMSpacing.s),
                const Expanded(child: SizedBox()),
              ],
            ),
          ] else ...[
            const SizedBox(height: CRMSpacing.m),
            Row(
              children: [
                Expanded(child: _buildCustomBooleanField(label: 'Factory License', key: 'factory_license')),
                const SizedBox(width: CRMSpacing.s),
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildUtilitiesSection(bool isMobile, bool isLand, bool isIndustrial) {
    if (!isLand && !isIndustrial) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: CRMSpacing.l),
        Text('Utilities', style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context))),
        const SizedBox(height: CRMSpacing.s),
        if (isMobile) ...[
          _buildCustomBooleanField(label: 'Electricity', key: 'electricity'),
          _buildCustomBooleanField(label: 'Water Supply', key: 'water_supply'),
          _buildCustomBooleanField(label: 'Borewell', key: 'borewell'),
          _buildCustomBooleanField(label: 'Sewer Connection', key: 'sewer_connection'),
          _buildCustomBooleanField(label: 'Drainage', key: 'drainage'),
          if (isIndustrial) ...[
            _buildCustomBooleanField(label: 'Power Backup', key: 'power_backup'),
            _buildCustomBooleanField(label: 'Transformer', key: 'transformer'),
            _buildCustomBooleanField(label: 'Gas Pipeline', key: 'gas_pipeline'),
            _buildCustomBooleanField(label: 'Internet Connection', key: 'internet'),
            _buildCustomBooleanField(label: 'Fire Fighting System', key: 'fire_fighting_system'),
          ],
        ] else ...[
          Row(
            children: [
              Expanded(child: _buildCustomBooleanField(label: 'Electricity', key: 'electricity')),
              const SizedBox(width: CRMSpacing.s),
              Expanded(child: _buildCustomBooleanField(label: 'Water Supply', key: 'water_supply')),
            ],
          ),
          Row(
            children: [
              Expanded(child: _buildCustomBooleanField(label: 'Borewell', key: 'borewell')),
              const SizedBox(width: CRMSpacing.s),
              Expanded(child: _buildCustomBooleanField(label: 'Sewer Connection', key: 'sewer_connection')),
            ],
          ),
          Row(
            children: [
              Expanded(child: _buildCustomBooleanField(label: 'Drainage', key: 'drainage')),
              const SizedBox(width: CRMSpacing.s),
              if (isIndustrial) ...[
                Expanded(child: _buildCustomBooleanField(label: 'Power Backup', key: 'power_backup')),
              ] else ...[
                const Expanded(child: SizedBox()),
              ],
            ],
          ),
          if (isIndustrial) ...[
            Row(
              children: [
                Expanded(child: _buildCustomBooleanField(label: 'Transformer', key: 'transformer')),
                const SizedBox(width: CRMSpacing.s),
                Expanded(child: _buildCustomBooleanField(label: 'Gas Pipeline', key: 'gas_pipeline')),
              ],
            ),
            Row(
              children: [
                Expanded(child: _buildCustomBooleanField(label: 'Internet Connection', key: 'internet')),
                const SizedBox(width: CRMSpacing.s),
                Expanded(child: _buildCustomBooleanField(label: 'Fire Fighting System', key: 'fire_fighting_system')),
              ],
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildParkingLogisticsSection(bool isMobile, bool isIndustrial) {
    if (!isIndustrial) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: CRMSpacing.l),
        Text('Parking & Logistics', style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context))),
        const SizedBox(height: CRMSpacing.s),
        if (isMobile) ...[
          _buildCustomBooleanField(label: 'Truck Parking', key: 'truck_parking'),
          _buildCustomBooleanField(label: 'Container Access', key: 'container_access'),
          _buildCustomBooleanField(label: 'Loading Dock', key: 'loading_dock'),
          _buildCustomBooleanField(label: 'Loading Bay', key: 'loading_bay'),
          _buildCustomBooleanField(label: 'Crane Available', key: 'crane_available'),
          const SizedBox(height: CRMSpacing.m),
          _buildCustomTextField(label: 'Crane Capacity (Tons)', key: 'crane_capacity', isNumeric: true),
        ] else ...[
          Row(
            children: [
              Expanded(child: _buildCustomBooleanField(label: 'Truck Parking', key: 'truck_parking')),
              const SizedBox(width: CRMSpacing.s),
              Expanded(child: _buildCustomBooleanField(label: 'Container Access', key: 'container_access')),
            ],
          ),
          Row(
            children: [
              Expanded(child: _buildCustomBooleanField(label: 'Loading Dock', key: 'loading_dock')),
              const SizedBox(width: CRMSpacing.s),
              Expanded(child: _buildCustomBooleanField(label: 'Loading Bay', key: 'loading_bay')),
            ],
          ),
          Row(
            children: [
              Expanded(child: _buildCustomBooleanField(label: 'Crane Available', key: 'crane_available')),
              const SizedBox(width: CRMSpacing.s),
              Expanded(child: _buildCustomTextField(label: 'Crane Capacity (Tons)', key: 'crane_capacity', isNumeric: true)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildIndustrialRoomsSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: CRMSpacing.l),
        Text('Rooms & Building Space', style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context))),
        const SizedBox(height: CRMSpacing.s),
        if (isMobile) ...[
          _buildCustomBooleanField(label: 'Office Space Available', key: 'office_space'),
          _buildCustomBooleanField(label: 'Mezzanine Floor Available', key: 'mezzanine_floor'),
          _buildCustomBooleanField(label: 'Shed Area Available', key: 'shed_area'),
          _buildCustomBooleanField(label: 'Pantry', key: 'pantry'),
          const SizedBox(height: CRMSpacing.m),
          _buildCustomTextField(label: 'Number of Cabins', key: 'cabins', isNumeric: true),
          const SizedBox(height: CRMSpacing.m),
          _buildCustomTextField(label: 'Number of Meeting Rooms', key: 'meeting_rooms', isNumeric: true),
          const SizedBox(height: CRMSpacing.m),
          _buildCustomBooleanField(label: 'Reception Area', key: 'reception'),
        ] else ...[
          Row(
            children: [
              Expanded(child: _buildCustomBooleanField(label: 'Office Space Available', key: 'office_space')),
              const SizedBox(width: CRMSpacing.s),
              Expanded(child: _buildCustomBooleanField(label: 'Mezzanine Floor Available', key: 'mezzanine_floor')),
            ],
          ),
          Row(
            children: [
              Expanded(child: _buildCustomBooleanField(label: 'Shed Area Available', key: 'shed_area')),
              const SizedBox(width: CRMSpacing.s),
              Expanded(child: _buildCustomBooleanField(label: 'Pantry', key: 'pantry')),
            ],
          ),
          const SizedBox(height: CRMSpacing.m),
          Row(
            children: [
              Expanded(child: _buildCustomTextField(label: 'Number of Cabins', key: 'cabins', isNumeric: true)),
              const SizedBox(width: CRMSpacing.s),
              Expanded(child: _buildCustomTextField(label: 'Number of Meeting Rooms', key: 'meeting_rooms', isNumeric: true)),
            ],
          ),
          const SizedBox(height: CRMSpacing.m),
          Row(
            children: [
              Expanded(child: _buildCustomBooleanField(label: 'Reception Area', key: 'reception')),
              const SizedBox(width: CRMSpacing.s),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPricingStep(bool isMobile) {
    final selectedCategoryItem = widget.metadata.categories.firstWhere(
      (c) => c.id == _selectedCategory,
      orElse: () => LookupItem(id: '', name: ''),
    );
    final categoryName = selectedCategoryItem.name.trim().toLowerCase();
    final isIndustrial = categoryName.contains('industrial') || selectedCategoryItem.id == 'industrial';
    final isCommercial = categoryName.contains('commercial') || selectedCategoryItem.id == 'commercial';
    final isLand = categoryName.contains('land') || categoryName.contains('plot');

    final selectedTypeItem = widget.metadata.types.firstWhere(
      (t) => t.id == _selectedType,
      orElse: () => LookupItem(id: '', name: ''),
    );
    final propertyTypeName = selectedTypeItem.name.trim().toLowerCase();
    final isLandOrIndustrial = categoryName.contains('land') || 
                               categoryName.contains('plot') || 
                               categoryName.contains('industrial');
    final isBungalow = !isLandOrIndustrial && (
                       propertyTypeName.contains('bungalow') || 
                       propertyTypeName.contains('villa') || 
                       propertyTypeName.contains('rowhouse') || 
                       propertyTypeName.contains('house') || 
                       propertyTypeName.contains('tenament'));

    final showResidentialRooms = !isIndustrial && !isCommercial;
    final showFloors = !isIndustrial;

    final selectedListingTypeItem = widget.metadata.listingTypes.firstWhere(
      (l) => l.id == _selectedListingType,
      orElse: () => LookupItem(id: '', name: ''),
    );
    final listingName = selectedListingTypeItem.name.trim();
    final isRent = listingName.toLowerCase() == 'rent' || selectedListingTypeItem.id == 'rent';

    final String priceLabel;
    if (listingName.isNotEmpty) {
      if (listingName.toLowerCase() == 'rent') {
        priceLabel = 'Rent Price';
      } else if (listingName.toLowerCase() == 're-sale' || listingName.toLowerCase() == 'resale') {
        priceLabel = 'Re-Sale Price';
      } else {
        priceLabel = '$listingName Price';
      }
    } else {
      priceLabel = 'Rent/Sell Price';
    }

    final priceField = CRMCurrencyField(
      controller: _priceController,
      labelText: priceLabel,
      isRequired: true,
    );

    final depositField = CRMCurrencyField(
      controller: _depositController,
      labelText: 'Deposit Amount',
      enabled: false,
    );

    final superBuiltupField = TextFormField(
      controller: _superBuiltupController,
      style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Super Builtup Area *(In Sq.ft)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
      ),
      validator: (v) {
        if (isLand) return null;
        return (v == null || v.isEmpty) ? 'Area required' : null;
      },
      onChanged: (_) {
        if (_carpetController.text.isNotEmpty) {
          setState(() {});
        }
      },
    );

    final carpetField = TextFormField(
      controller: _carpetController,
      style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Carpet Area Size(In Sq.ft)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (v) {
        if (v != null && v.trim().isNotEmpty) {
          final carpetVal = double.tryParse(v.trim());
          if (carpetVal == null) return 'Invalid number';
          final superVal = double.tryParse(_superBuiltupController.text.trim());
          if (superVal != null && carpetVal > superVal) {
            return 'Carpet area cannot exceed Super Builtup Area (${_superBuiltupController.text.trim()})';
          }
        }
        return null;
      },
    );

    final bedroomValue = _bedroomsController.text.isNotEmpty && int.tryParse(_bedroomsController.text) != null
        ? '${_bedroomsController.text} '
        : '1 ';
    final bedroomOptions = ['1 ', '2 ', '3 ', '4 ', '5 '];
    final bedroomItems = bedroomOptions.contains(bedroomValue)
        ? bedroomOptions
        : [...bedroomOptions, bedroomValue];

    final bedroomsField = DropdownButtonFormField<String>(
      isExpanded: true,
      value: bedroomValue,
      decoration: InputDecoration(
        labelText: 'Bedrooms',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
      ),
      items: bedroomItems.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _bedroomsController.text = val.split(' ')[0];
          });
        }
      },
    );

    final bathroomValue = _bathroomsController.text.isNotEmpty ? _bathroomsController.text : '1';
    final bathroomOptions = ['1', '2', '3', '4', '5', '6'];
    final bathroomItems = bathroomOptions.contains(bathroomValue)
        ? bathroomOptions
        : [...bathroomOptions, bathroomValue];

    final bathroomsField = DropdownButtonFormField<String>(
      isExpanded: true,
      value: bathroomValue,
      decoration: InputDecoration(
        labelText: 'Bathrooms',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
      ),
      items: bathroomItems.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _bathroomsController.text = val;
          });
        }
      },
    );

    final balconyValue = _balconiesController.text.isNotEmpty ? _balconiesController.text : '0';
    final balconyOptions = ['0', '1', '2', '3'];
    final balconyItems = balconyOptions.contains(balconyValue)
        ? balconyOptions
        : [...balconyOptions, balconyValue];

    final balconiesField = DropdownButtonFormField<String>(
      isExpanded: true,
      value: balconyValue,
      decoration: InputDecoration(
        labelText: 'Balconies',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
      ),
      items: balconyItems.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _balconiesController.text = val;
          });
        }
      },
    );

    final parkingField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: _selectedParkingType,
          decoration: InputDecoration(
            labelText: 'Parking',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
          ),
          items: const [
            DropdownMenuItem(value: 'Allocated', child: Text('Allocated')),
            DropdownMenuItem(value: 'Open', child: Text('Open')),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedParkingType = val;
                if (val == 'Open') {
                  _selectedParkingOption = null;
                  _selectedParkingSlot = null;
                } else {
                  if (_selectedParkingOption == null) {
                    _selectedParkingOption = 'Basement 1';
                  }
                  if (_selectedParkingSlot == null) {
                    _selectedParkingSlot = '1';
                  }
                }
                _updateParkingController();
              });
            }
          },
        ),
        if (_selectedParkingType == 'Allocated') ...[
          const SizedBox(height: CRMSpacing.s),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _selectedParkingOption,
            decoration: InputDecoration(
              labelText: 'Parking Option',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
            ),
            items: const [
              DropdownMenuItem(value: 'Basement 1', child: Text('Basement 1')),
              DropdownMenuItem(value: 'Basement 2', child: Text('Basement 2')),
              DropdownMenuItem(value: 'Ground Floor', child: Text('Ground Floor')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedParkingOption = val;
                  _updateParkingController();
                });
              }
            },
          ),
          const SizedBox(height: CRMSpacing.s),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _selectedParkingSlot,
            decoration: InputDecoration(
              labelText: 'Parking Slot',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
            ),
            items: const [
              DropdownMenuItem(value: '1', child: Text('1')),
              DropdownMenuItem(value: '2', child: Text('2')),
              DropdownMenuItem(value: '3', child: Text('3')),
              DropdownMenuItem(value: '4', child: Text('4')),
              DropdownMenuItem(value: '5', child: Text('5')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedParkingSlot = val;
                  _updateParkingController();
                });
              }
            },
          ),
        ],
      ],
    );

    final unitNoField = TextFormField(
      controller: _flatNoController,
      style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
      decoration: InputDecoration(
        labelText: 'Unit Number',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
      ),
    );

    final floorNoField = TextFormField(
      controller: _floorNoController,
      style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Floor No.',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
      ),
    );

    final totalFloorField = DropdownButtonFormField<String>(
      isExpanded: true,
      value: _totalFloorController.text.isEmpty ? null : _totalFloorController.text,
      decoration: InputDecoration(
        labelText: 'Total Floors',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('None')),
        ...List.generate(50, (index) {
          final val = (index + 1).toString();
          return DropdownMenuItem(value: val, child: Text(val));
        }),
      ],
      onChanged: (v) {
        setState(() {
          _totalFloorController.text = v ?? '';
        });
      },
    );

    final ageField = DropdownButtonFormField<String>(
      isExpanded: true,
      value: _ageController.text.isEmpty ? null : () {
        final ageVal = int.tryParse(_ageController.text);
        if (ageVal == null) return null;
        if (ageVal <= 1) return '0 to 1 years';
        if (ageVal <= 5) return '1 to 5 years';
        if (ageVal <= 10) return '5 to 10 years';
        if (ageVal <= 14) return '10+ years';
        if (ageVal <= 19) return '15+ years';
        return '20+ years';
      }(),
      decoration: InputDecoration(
        labelText: 'Age (years)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
      ),
      items: const [
        DropdownMenuItem(value: null, child: Text('None')),
        DropdownMenuItem(value: '0 to 1 years', child: Text('0 to 1 years')),
        DropdownMenuItem(value: '1 to 5 years', child: Text('1 to 5 years')),
        DropdownMenuItem(value: '5 to 10 years', child: Text('5 to 10 years')),
        DropdownMenuItem(value: '10+ years', child: Text('10+ years')),
        DropdownMenuItem(value: '15+ years', child: Text('15+ years')),
        DropdownMenuItem(value: '20+ years', child: Text('20+ years')),
      ],
      onChanged: (v) {
        setState(() {
          if (v == null) {
            _ageController.text = '';
          } else if (v == '0 to 1 years') {
            _ageController.text = '1';
          } else if (v == '1 to 5 years') {
            _ageController.text = '3';
          } else if (v == '5 to 10 years') {
            _ageController.text = '7';
          } else if (v == '10+ years') {
            _ageController.text = '12';
          } else if (v == '15+ years') {
            _ageController.text = '17';
          } else if (v == '20+ years') {
            _ageController.text = '22';
          }
        });
      },
    );

    final furnishingField = DropdownButtonFormField<String>(
      isExpanded: true,
      value: _selectedFurnishing,
      decoration: InputDecoration(
        labelText: 'Furnishing',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('None')),
        ...widget.metadata.furnishings.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name))),
      ],
      onChanged: (v) => setState(() => _selectedFurnishing = v),
    );

    final facingField = Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return widget.metadata.facings.map((f) => f.name);
        }
        return widget.metadata.facings
            .map((f) => f.name)
            .where((String option) {
          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        final match = widget.metadata.facings.firstWhere(
          (f) => f.name.toLowerCase() == selection.toLowerCase(),
          orElse: () => LookupItem(id: '', name: ''),
        );
        if (match.id.isNotEmpty) {
          _selectedFacing = match.id;
          _facingController.text = match.name;
        }
      },
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        textEditingController.text = _facingController.text;
        _facingController = textEditingController;
        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
          decoration: InputDecoration(
            labelText: 'Facing',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
          ),
          onChanged: (val) {
            _selectedFacing = null;
          },
        );
      },
    );


    final brokerageField = CRMSearchableDropdown(
      labelText: 'Brokerage Confirmation',
      selectedValue: _selectedBrokerage,
      items: widget.metadata.brokerages.map((b) => CRMDropdownItem(id: b.id, label: b.name)).toList(),
      onChanged: (v) => setState(() => _selectedBrokerage = v),
      onAddPressed: _showAddBrokerageDialog,
    );

    final depositMonthsField = Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            value: _selectedDepositMonth,
            decoration: InputDecoration(
              labelText: 'Deposit Months *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('None')),
              ..._depositMonthOptions.map((m) => DropdownMenuItem(value: m, child: Text(m))),
            ],
            validator: (v) => isRent && (v == null || v.isEmpty) ? 'Deposit months required' : null,
            onChanged: (v) {
              setState(() {
                _selectedDepositMonth = v;
                _calculateDeposit();
              });
            },
          ),
        ),
        const SizedBox(width: CRMSpacing.xs),
        IconButton(
          icon: Icon(Icons.add_circle_outline_rounded, color: CRMColors.primaryOf(context)),
          onPressed: _showAddCustomMonthsDialog,
          tooltip: 'Add Custom Months',
        ),
      ],
    );

    return CRMCard(
      title: 'Pricing & Sizing Sockets',
      subtitle: 'Complete budget calculations and builtup area parameters',
      padding: isMobile ? const EdgeInsets.all(CRMSpacing.s) : const EdgeInsets.all(CRMSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            priceField,
            if (isRent && !isLand) ...[
              const SizedBox(height: CRMSpacing.m),
              depositMonthsField,
              const SizedBox(height: CRMSpacing.m),
              depositField,
            ],
          ] else ...[
            if (!isRent || isLand)
              priceField
            else
              Row(
                children: [
                  Expanded(child: priceField),
                  const SizedBox(width: CRMSpacing.s),
                  Expanded(child: depositMonthsField),
                  const SizedBox(width: CRMSpacing.s),
                  Expanded(child: depositField),
                ],
              ),
          ],
          if (isRent && !isLand) ...[
            const SizedBox(height: CRMSpacing.m),
            TextFormField(
              controller: _maintenanceController,
              style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Monthly Maintenance Charge',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
              ),
            ),
          ],
          if (isLand || isIndustrial) ...[
            const SizedBox(height: CRMSpacing.m),
            _buildCustomBooleanField(label: 'Price Negotiable', key: 'negotiable', isRequired: true),
          ],
          if (isIndustrial && isRent) ...[
            const SizedBox(height: CRMSpacing.m),
            if (isMobile) ...[
              _buildCustomTextField(label: 'Lock-in Period (Months)', key: 'lock_in_period', isNumeric: true, isRequired: true),
              const SizedBox(height: CRMSpacing.m),
              _buildCustomTextField(label: 'Lease Duration (Years)', key: 'lease_duration', isNumeric: true, isRequired: true),
            ] else ...[
              Row(
                children: [
                  Expanded(child: _buildCustomTextField(label: 'Lock-in Period (Months)', key: 'lock_in_period', isNumeric: true, isRequired: true)),
                  const SizedBox(width: CRMSpacing.s),
                  Expanded(child: _buildCustomTextField(label: 'Lease Duration (Years)', key: 'lease_duration', isNumeric: true, isRequired: true)),
                ],
              ),
            ],
          ],
          if (!isLand) ...[
            const SizedBox(height: CRMSpacing.m),
            if (isMobile) ...[
              superBuiltupField,
              const SizedBox(height: CRMSpacing.m),
              carpetField,
            ] else ...[
              Row(
                children: [
                  Expanded(child: superBuiltupField),
                  const SizedBox(width: CRMSpacing.s),
                  Expanded(child: carpetField),
                ],
              ),
            ],
            if (isIndustrial) ...[
              const SizedBox(height: CRMSpacing.m),
              if (isMobile) ...[
                _buildCustomTextField(label: 'Super Builtup Area (Sq.ft)', key: 'super_built_up_area_custom', isNumeric: true),
                const SizedBox(height: CRMSpacing.m),
                _buildCustomTextField(label: 'Ceiling Height (Ft)', key: 'ceiling_height', isNumeric: true, isRequired: true),
                const SizedBox(height: CRMSpacing.m),
                _buildCustomTextField(label: 'Floor Load Capacity (Tons/Sq.m)', key: 'floor_load_capacity', isNumeric: true, isRequired: true),
              ] else ...[
                Row(
                  children: [
                    Expanded(child: _buildCustomTextField(label: 'Super Builtup Area (Sq.ft)', key: 'super_built_up_area_custom', isNumeric: true)),
                    const SizedBox(width: CRMSpacing.s),
                    Expanded(child: _buildCustomTextField(label: 'Ceiling Height (Ft)', key: 'ceiling_height', isNumeric: true, isRequired: true)),
                    const SizedBox(width: CRMSpacing.s),
                    Expanded(child: _buildCustomTextField(label: 'Floor Load Capacity (Tons/Sq.m)', key: 'floor_load_capacity', isNumeric: true, isRequired: true)),
                  ],
                ),
              ],
            ],
          ],
          const SizedBox(height: CRMSpacing.m),
          if (isMobile) ...[
            TextFormField(
              controller: _plotController,
              style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Plot Area Size(In Sq.ft) ${isLand ? '*' : ''}',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
              ),
              validator: (v) {
                if (isLand && (v == null || v.trim().isEmpty)) {
                  return 'Plot Area Size is required';
                }
                return null;
              },
            ),
            if (isLand || isIndustrial) ...[
              const SizedBox(height: CRMSpacing.m),
              _buildCustomTextField(label: 'Open Area Size(In Sq.ft)', key: 'open_area', isNumeric: true, isRequired: isIndustrial),
              const SizedBox(height: CRMSpacing.m),
              _buildCustomDropdownField(label: 'Area Unit', key: 'area_unit', options: ['Sq.ft', 'Sq.Yard', 'Acre', 'Gunda', 'Bigha', 'Hectare'], isRequired: true),
            ],
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _plotController,
                    style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Plot Area Size(In Sq.ft) ${isLand ? '*' : ''}',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                    ),
                    validator: (v) {
                      if (isLand && (v == null || v.trim().isEmpty)) {
                        return 'Plot Area Size is required';
                      }
                      return null;
                    },
                  ),
                ),
                if (isLand || isIndustrial) ...[
                  const SizedBox(width: CRMSpacing.s),
                  Expanded(child: _buildCustomTextField(label: 'Open Area Size(In Sq.ft)', key: 'open_area', isNumeric: true, isRequired: isIndustrial)),
                  const SizedBox(width: CRMSpacing.s),
                  Expanded(child: _buildCustomDropdownField(label: 'Area Unit', key: 'area_unit', options: ['Sq.ft', 'Sq.Yard', 'Acre', 'Gunda', 'Bigha', 'Hectare'], isRequired: true)),
                ],
              ],
            ),
          ],
          _buildLandDetailsSection(isMobile, isLand, isIndustrial),
          if (!isLand) ...[
            const SizedBox(height: CRMSpacing.l),
            Text('Room & Floor Details', style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context))),
            const SizedBox(height: CRMSpacing.s),
            if (isIndustrial) ...[
              if (isMobile) ...[
                bathroomsField,
                const SizedBox(height: CRMSpacing.m),
                parkingField,
              ] else ...[
                Row(
                  children: [
                    Expanded(child: bathroomsField),
                    const SizedBox(width: CRMSpacing.s),
                    Expanded(child: parkingField),
                  ],
                ),
              ],
              _buildIndustrialRoomsSection(isMobile),
            ] else if (!showResidentialRooms) ...[
              parkingField,
            ] else ...[
              if (isMobile) ...[
                Row(
                  children: [
                    Expanded(child: bedroomsField),
                    const SizedBox(width: CRMSpacing.s),
                    Expanded(child: bathroomsField),
                  ],
                ),
                const SizedBox(height: CRMSpacing.m),
                Row(
                  children: [
                    Expanded(child: balconiesField),
                    const SizedBox(width: CRMSpacing.s),
                    Expanded(child: parkingField),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(child: bedroomsField),
                    const SizedBox(width: CRMSpacing.s),
                    Expanded(child: bathroomsField),
                    const SizedBox(width: CRMSpacing.s),
                    Expanded(child: balconiesField),
                    const SizedBox(width: CRMSpacing.s),
                    Expanded(child: parkingField),
                  ],
                ),
              ],
            ],
            const SizedBox(height: CRMSpacing.m),
            if (isBungalow) ...[
              if (isMobile) ...[
                unitNoField,
                const SizedBox(height: CRMSpacing.m),
                ageField,
              ] else ...[
                Row(
                  children: [
                    Expanded(child: unitNoField),
                    const SizedBox(width: CRMSpacing.s),
                    Expanded(child: ageField),
                  ],
                ),
              ],
            ] else if (isIndustrial || showFloors) ...[
              if (isMobile) ...[
                floorNoField,
                const SizedBox(height: CRMSpacing.m),
                totalFloorField,
                const SizedBox(height: CRMSpacing.m),
                ageField,
              ] else ...[
                Row(
                  children: [
                    Expanded(child: floorNoField),
                    const SizedBox(width: CRMSpacing.s),
                    Expanded(child: totalFloorField),
                    const SizedBox(width: CRMSpacing.s),
                    Expanded(child: ageField),
                  ],
                ),
              ],
            ] else ...[
              ageField,
            ],
          ],
          _buildLegalDetailsSection(isMobile, isLand, isIndustrial),
          _buildUtilitiesSection(isMobile, isLand, isIndustrial),
          _buildParkingLogisticsSection(isMobile, isIndustrial),
          const SizedBox(height: CRMSpacing.l),
          Text('Property Attributes', style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context))),
          const SizedBox(height: CRMSpacing.s),
          if (isMobile) ...[
            if (!isLand && !isIndustrial) ...[
              furnishingField,
              const SizedBox(height: CRMSpacing.m),
            ],
            facingField,
            const SizedBox(height: CRMSpacing.m),
            brokerageField,
          ] else ...[
            Row(
              children: [
                if (!isLand && !isIndustrial) ...[
                  Expanded(child: furnishingField),
                  const SizedBox(width: CRMSpacing.s),
                  Expanded(child: facingField),
                ] else ...[
                  Expanded(child: facingField),
                  const SizedBox(width: CRMSpacing.s),
                  const Expanded(child: SizedBox()),
                ],
              ],
            ),
            const SizedBox(height: CRMSpacing.m),
            Row(
              children: [
                Expanded(child: brokerageField),
                const SizedBox(width: CRMSpacing.s),
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
          if (!isLand && !isIndustrial) ...[
            const SizedBox(height: CRMSpacing.l),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Amenities', style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context))),
                TextButton.icon(
                  onPressed: _showAddAmenityDialog,
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                  label: const Text('Add Custom Amenity'),
                  style: TextButton.styleFrom(
                    foregroundColor: CRMColors.primaryOf(context),
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: CRMSpacing.s),
            Wrap(
              spacing: CRMSpacing.s,
              runSpacing: CRMSpacing.xs,
              children: _localAmenities.map((amenity) {
                final isSelected = _selectedAmenities.contains(amenity.id);
                return FilterChip(
                  label: Text(amenity.name),
                  selected: isSelected,
                  selectedColor: CRMColors.primaryOf(context).withOpacity(0.12),
                  checkmarkColor: CRMColors.primaryOf(context),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedAmenities.add(amenity.id);
                      } else {
                        _selectedAmenities.remove(amenity.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showAddAmenityDialog() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CRMColors.cardBgOf(context),
        title: Text('Add Custom Amenity', style: TextStyle(color: CRMColors.textOf(context))),
        content: TextField(
          controller: controller,
          style: TextStyle(color: CRMColors.textOf(context)),
          decoration: const InputDecoration(
            hintText: 'Enter amenity name (e.g. Solar Panels)',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                try {
                  final newAmenity = await PropertiesRepository().createAmenity(name);
                  setState(() {
                    _localAmenities.add(newAmenity);
                    _selectedAmenities.add(newAmenity.id);
                  });
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add amenity: $e'), backgroundColor: CRMColors.danger),
                    );
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showSearchPropertyDialog() {
    final propertiesBloc = context.read<PropertiesBloc>();
    final state = propertiesBloc.state;
    List<PropertyModel> allProperties = [];
    if (state is PropertiesLoaded) {
      allProperties = state.properties;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        final queryController = TextEditingController();
        List<PropertyModel> filteredProperties = allProperties;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: CRMColors.cardBgOf(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.dialog)),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
                padding: const EdgeInsets.all(CRMSpacing.m),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Search Properties',
                          style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(dialogContext),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    const SizedBox(height: CRMSpacing.m),
                    TextField(
                      controller: queryController,
                      style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
                      decoration: InputDecoration(
                        hintText: 'Type to search properties...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: queryController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  queryController.clear();
                                  setDialogState(() {
                                    filteredProperties = allProperties;
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          filteredProperties = allProperties
                              .where((p) => p.title.toLowerCase().contains(value.toLowerCase()) ||
                                            p.propertyCode.toLowerCase().contains(value.toLowerCase()) ||
                                            p.areaName.toLowerCase().contains(value.toLowerCase()))
                              .toList();
                        });
                      },
                    ),
                    const SizedBox(height: CRMSpacing.m),
                    Expanded(
                      child: filteredProperties.isEmpty
                          ? Center(
                              child: Text(
                                'No matching properties found',
                                style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context)),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filteredProperties.length,
                              separatorBuilder: (context, index) => Divider(color: CRMColors.borderOf(context)),
                              itemBuilder: (context, index) {
                                final property = filteredProperties[index];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: CRMSpacing.s, vertical: CRMSpacing.xxs),
                                  title: Text(
                                    property.title,
                                    style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textOf(context)),
                                  ),
                                  subtitle: Text(
                                    '${property.propertyCode} • ${property.areaName}, ${property.cityName}',
                                    style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _titleController.text = property.title;
                                      _selectedCity = property.cityId;
                                      _updateAreasForCity(property.cityId);
                                      _selectedArea = property.areaId;
                                    });
                                    Navigator.pop(dialogContext);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildContactsStep(bool isMobile) {
    final contactNameField = CRMTextField(
      controller: _ownerNameController,
      labelText: 'Contact Name *',
      validator: (v) => v == null || v.isEmpty ? 'Contact name required' : null,
    );

    final contactMobileField = CRMPhoneField(
      controller: _ownerMobileController,
      labelText: 'Contact Mobile',
      isRequired: true,
    );

    return CRMCard(
      title: 'Contacts Info & Visibility',
      subtitle: 'Verify contact profiles and direct remarks',
      padding: isMobile ? const EdgeInsets.all(CRMSpacing.s) : const EdgeInsets.all(CRMSpacing.m),
      child: Column(
        children: [
          if (isMobile) ...[
            contactNameField,
            const SizedBox(height: CRMSpacing.m),
            contactMobileField,
          ] else ...[
            Row(
              children: [
                Expanded(child: contactNameField),
                const SizedBox(width: CRMSpacing.s),
                Expanded(child: contactMobileField),
              ],
            ),
          ],
          const SizedBox(height: CRMSpacing.m),
          TextFormField(
            controller: _brokerNameController,
            style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
            decoration: InputDecoration(
              labelText: 'Reffer name/Key Collect',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
            ),
          ),
          const SizedBox(height: CRMSpacing.m),
          TextFormField(
            controller: _remarksController,
            style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Operational CRM internal remarks',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
              helperText: '${_getWordCount(_remarksController.text)} / 250 words',
              helperStyle: TextStyle(
                color: _getWordCount(_remarksController.text) > 250 ? CRMColors.danger : CRMColors.textMutedOf(context),
              ),
            ),
            validator: (val) {
              if (val != null && val.trim().isNotEmpty) {
                final words = val.trim().split(RegExp(r'\s+'));
                if (words.length > 250) {
                  return 'Limit exceeded: ${words.length}/250 words';
                }
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWizardActions(bool isEdit) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 500;

    final cancelButton = CRMButton(
      label: 'Cancel',
      variant: CRMButtonVariant.outline,
      onPressed: () => Navigator.pop(context),
    );

    final backButton = _currentStep > 0
        ? CRMButton(
            label: 'Back',
            variant: CRMButtonVariant.secondary,
            onPressed: () => setState(() => _currentStep--),
          )
        : null;

    final nextButton = _currentStep < 3
        ? CRMButton(
            label: 'Next Step',
            variant: CRMButtonVariant.primary,
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                setState(() => _currentStep++);
              }
            },
          )
        : CRMButton(
            label: isEdit ? 'Save Changes' : 'Publish Property',
            variant: CRMButtonVariant.primary,
            onPressed: _submitForm,
          );

    final saveChangesButton = (isEdit && _currentStep < 3)
        ? CRMButton(
            label: 'Save Changes',
            variant: CRMButtonVariant.outline,
            onPressed: _submitForm,
          )
        : null;

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(CRMSpacing.m),
        decoration: BoxDecoration(
          color: CRMColors.cardBgOf(context),
          border: Border(top: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.5), width: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                cancelButton,
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (backButton != null) ...[
                      backButton,
                      const SizedBox(width: CRMSpacing.s),
                    ],
                    nextButton,
                  ],
                ),
              ],
            ),
            if (saveChangesButton != null) ...[
              const SizedBox(height: CRMSpacing.s),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  saveChangesButton,
                ],
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(CRMSpacing.m),
      decoration: BoxDecoration(
        color: CRMColors.cardBgOf(context),
        border: Border(top: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.5), width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          cancelButton,
          Row(
            children: [
              if (backButton != null) ...[
                backButton,
                const SizedBox(width: CRMSpacing.s),
              ],
              if (saveChangesButton != null) ...[
                saveChangesButton,
                const SizedBox(width: CRMSpacing.s),
              ],
              nextButton,
            ],
          ),
        ],
      ),
    );
  }

  int _getWordCount(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }
}
