import 'package:flutter/material.dart';
import '../../../core/storage/local_repositories.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/data_table.dart';
import '../../../core/utils/currency.dart';
import '../models/property_model.dart';
import '../services/properties_service.dart';
import '../../requirements/models/requirement_model.dart';
import '../../requirements/services/requirements_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/models/user_model.dart' as auth_model;
import '../../users/repository/users_repository.dart';
import '../../users/models/user_model.dart' as user_settings_model;

class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  final PropertiesService _propertiesService = PropertiesService();
  final RequirementsService _requirementsService = RequirementsService();

  bool _isLoading = true;
  String _selectedTab = 'Properties'; // 'Properties' or 'Requirements'
  String _propertiesSubTab = 'Rent'; // 'Rent' or 'Re-sale'
  String _requirementsSubTab = 'Bin'; // 'Bin' or 'Not Interested'
  String _requirementsListingSubTab = 'Rent'; // 'Rent' or 'Re-sale'
  int _autoDeleteDays = 30; // 15, 30, 60

  List<PropertyModel> _binProperties = [];
  List<RequirementModel> _binRequirements = [];
  final Map<String, user_settings_model.UserModel> _usersMap = {};

  int _propertiesPerPage = 15;
  int _requirementsPerPage = 15;
  int _currentPropertiesPage = 1;
  int _currentRequirementsPage = 1;

  bool _isRentProperty(PropertyModel p) {
    final typeName = p.listingTypeName.toLowerCase();
    if (typeName.contains('re-sale') || typeName.contains('resale')) return false;
    if (typeName.contains('rent')) return true;
    final lookupName = LookupLocalRepository.getLookupNameSync(p.listingTypeId)?.toLowerCase() ?? '';
    if (lookupName.contains('re-sale') || lookupName.contains('resale')) return false;
    if (lookupName.contains('rent')) return true;
    return p.listingTypeId == '1c1ccfc1-d318-4b66-9a43-c551532d1802';
  }

  List<PropertyModel> get _visibleBinProperties {
    if (_propertiesSubTab == 'Rent') {
      return _binProperties.where(_isRentProperty).toList();
    }
    return _binProperties.where((p) => !_isRentProperty(p)).toList();
  }

  bool _isRentRequirement(RequirementModel r) {
    final typeName = (r.listingTypeName ?? '').toLowerCase();
    if (typeName.contains('re-sale') || typeName.contains('resale')) return false;
    if (typeName.contains('rent')) return true;
    final lookupName = LookupLocalRepository.getLookupNameSync(r.listingTypeId ?? '')?.toLowerCase() ?? '';
    if (lookupName.contains('re-sale') || lookupName.contains('resale')) return false;
    if (lookupName.contains('rent')) return true;
    return r.listingTypeId == '1c1ccfc1-d318-4b66-9a43-c551532d1802';
  }

  List<RequirementModel> get _visibleBinRequirements {
    if (_requirementsListingSubTab == 'Rent') {
      return _binRequirements.where(_isRentRequirement).toList();
    }
    return _binRequirements.where((r) => !_isRentRequirement(r)).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadAutoDeleteDays();
    _fetchBinData();
  }

  Future<void> _loadAutoDeleteDays() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoDeleteDays = prefs.getInt('auto_delete_days') ?? 30;
    });
  }

  Future<void> _saveAutoDeleteDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('auto_delete_days', days);
    setState(() {
      _autoDeleteDays = days;
    });
  }

  Future<void> _fetchBinData() async {
    setState(() {
      _currentPropertiesPage = 1;
      _currentRequirementsPage = 1;
    });
    if (_selectedTab == 'Properties') {
      await _fetchBinProperties();
    } else {
      await _fetchBinRequirements();
    }
  }

  Future<void> _fetchBinProperties() async {
    setState(() => _isLoading = true);
    try {
      final res = await _propertiesService.getBinProperties();
      final data = res['data'] as Map<String, dynamic>? ?? {};
      final list = data['properties'] as List? ?? [];

      final authState = context.read<AuthBloc>().state;
      auth_model.UserModel? currentUser;
      if (authState is Authenticated) {
        currentUser = authState.user;
      }

      List<PropertyModel> parsedList = list.map((p) => PropertyModel.fromJson(p)).toList();

      if (currentUser != null) {
        final role = currentUser.role;
        final currentUserId = currentUser.id;
        final currentUserAdminId = currentUser.adminId;

        if (role == 'Admin') {
          parsedList = parsedList.where((p) =>
            p.createdBy == currentUserId || p.adminId == currentUserId
          ).toList();
        } else if (role != 'Super Admin') {
          parsedList = parsedList.where((p) =>
            p.createdBy == currentUserId || (currentUserAdminId != null && p.adminId == currentUserAdminId)
          ).toList();
        }
      }

      setState(() {
        _binProperties = parsedList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load bin properties: $e'), backgroundColor: CRMColors.danger),
        );
      }
    }
  }

  Future<void> _fetchBinRequirements() async {
    setState(() => _isLoading = true);
    try {
      if (_usersMap.isEmpty) {
        try {
          final usersList = await UsersRepository().getUsers();
          for (var u in usersList) {
            _usersMap[u.id] = u;
          }
        } catch (_) {}
      }

      final res = _requirementsSubTab == 'Bin'
          ? await _requirementsService.getBinRequirements()
          : await _requirementsService.getRequirements(status: 'Not Interested');
      final data = res['data'] as Map<String, dynamic>? ?? {};
      final list = data['requirements'] as List? ?? [];

      final authState = context.read<AuthBloc>().state;
      auth_model.UserModel? currentUser;
      if (authState is Authenticated) {
        currentUser = authState.user;
      }
      final isSales = currentUser?.role?.toLowerCase() == 'sales';
      final currentUserId = currentUser?.id;

      List<RequirementModel> parsedList = list.map((r) => RequirementModel.fromJson(r)).toList();

      if (currentUser != null) {
        final role = currentUser.role;
        if (role == 'Admin') {
          parsedList = parsedList.where((r) =>
            r.createdBy == currentUserId || r.adminId == currentUserId
          ).toList();
        } else if (role != 'Super Admin') {
          parsedList = parsedList.where((r) =>
            r.createdBy == currentUserId
          ).toList();
        }
      }

      setState(() {
        _binRequirements = parsedList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load requirements: $e'), backgroundColor: CRMColors.danger),
        );
      }
    }
  }

  Future<void> _restoreProperty(String id) async {
    try {
      await _propertiesService.restoreProperty(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property restored successfully'), backgroundColor: CRMColors.success),
      );
      _fetchBinProperties();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to restore property: $e'), backgroundColor: CRMColors.danger),
      );
    }
  }

  Future<void> _restoreRequirement(RequirementModel r) async {
    try {
      if (_requirementsSubTab == 'Bin') {
        await _requirementsService.restoreRequirement(r.id);
      } else {
        await _requirementsService.updateRequirement(r.id, {'status': 'Interested'});
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Requirement restored successfully'), backgroundColor: CRMColors.success),
      );
      _fetchBinRequirements();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to restore requirement: $e'), backgroundColor: CRMColors.danger),
      );
    }
  }

  Future<void> _deleteRequirement(RequirementModel r) async {
    try {
      await _requirementsService.deleteRequirement(r.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Requirement moved to Recycle Bin'), backgroundColor: CRMColors.success),
      );
      _fetchBinRequirements();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete requirement: $e'), backgroundColor: CRMColors.danger),
      );
    }
  }

  Future<void> _permanentDeleteProperty(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permanently Delete Property'),
        content: const Text('Are you sure? This action cannot be undone and will erase this property forever.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete Permanently', style: TextStyle(color: CRMColors.danger))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _propertiesService.permanentDeleteProperty(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property permanently deleted'), backgroundColor: CRMColors.success),
      );
      _fetchBinProperties();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete property: $e'), backgroundColor: CRMColors.danger),
      );
    }
  }

  Future<void> _permanentDeleteRequirement(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permanently Delete Requirement'),
        content: const Text('Are you sure? This action cannot be undone and will erase this requirement forever.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete Permanently', style: TextStyle(color: CRMColors.danger))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _requirementsService.permanentDeleteRequirement(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Requirement permanently deleted'), backgroundColor: CRMColors.success),
      );
      _fetchBinRequirements();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete requirement: $e'), backgroundColor: CRMColors.danger),
      );
    }
  }

  Future<void> _emptyBinProperties() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Empty Recycle Bin (Properties)'),
        content: const Text('Are you sure you want to permanently erase ALL deleted properties in the bin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Empty Bin', style: TextStyle(color: CRMColors.danger))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _propertiesService.emptyBin();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Properties recycle bin emptied'), backgroundColor: CRMColors.success),
      );
      _fetchBinProperties();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to empty bin: $e'), backgroundColor: CRMColors.danger),
      );
    }
  }

  Future<void> _emptyBinRequirements() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Empty Recycle Bin (Requirements)'),
        content: const Text('Are you sure you want to permanently erase ALL deleted requirements in the bin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Empty Bin', style: TextStyle(color: CRMColors.danger))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _requirementsService.emptyBin();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Requirements recycle bin emptied'), backgroundColor: CRMColors.success),
      );
      _fetchBinRequirements();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to empty bin: $e'), backgroundColor: CRMColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    bool isAdmin = false;
    if (authState is Authenticated) {
      final role = authState.user.role.toLowerCase();
      isAdmin = role == 'admin' || role == 'super admin';
    }

    final bool hasData = _selectedTab == 'Properties' 
        ? _binProperties.isNotEmpty 
        : (_requirementsSubTab == 'Bin' && _binRequirements.isNotEmpty);
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    Widget headerControls = Wrap(
      spacing: CRMSpacing.s,
      runSpacing: CRMSpacing.s,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: CRMColors.cardBgOf(context),
            borderRadius: BorderRadius.circular(CRMBorderRadius.s),
            border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.6), width: 0.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _autoDeleteDays,
              icon: const Icon(Icons.arrow_drop_down),
              style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textOf(context)),
              dropdownColor: CRMColors.cardBgOf(context),
              onChanged: (int? newValue) {
                if (newValue != null) {
                  _saveAutoDeleteDays(newValue);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Auto-delete period set to $newValue days'),
                      backgroundColor: CRMColors.success,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              items: const [
                DropdownMenuItem<int>(
                  value: 15,
                  child: Text('Auto Delete: 15 days'),
                ),
                DropdownMenuItem<int>(
                  value: 30,
                  child: Text('Auto Delete: 30 days'),
                ),
                DropdownMenuItem<int>(
                  value: 60,
                  child: Text('Auto Delete: 60 days'),
                ),
              ],
            ),
          ),
        ),
        if (hasData && isAdmin)
          CRMButton(
            label: 'Empty Bin',
            variant: CRMButtonVariant.danger,
            prefixIcon: Icons.delete_forever_rounded,
            onPressed: _selectedTab == 'Properties' ? _emptyBinProperties : _emptyBinRequirements,
          ),
      ],
    );

    Widget pageHeader = isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recycle Bin', style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context))),
              const SizedBox(height: 4),
              Text(
                _selectedTab == 'Properties' ? 'Deleted Properties' : 'Deleted Leads',
                style: CRMTypography.pageTitle.copyWith(
                  color: CRMColors.textOf(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: CRMSpacing.s),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Properties'),
                    selected: _selectedTab == 'Properties',
                    selectedColor: CRMColors.primaryOf(context).withValues(alpha: 0.12),
                    labelStyle: TextStyle(
                      color: _selectedTab == 'Properties' ? CRMColors.primaryOf(context) : CRMColors.textOf(context),
                      fontWeight: _selectedTab == 'Properties' ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedTab = 'Properties';
                        });
                        _fetchBinData();
                      }
                    },
                  ),
                  const SizedBox(width: CRMSpacing.s),
                  ChoiceChip(
                    label: const Text('Leads'),
                    selected: _selectedTab == 'Requirements',
                    selectedColor: CRMColors.primaryOf(context).withValues(alpha: 0.12),
                    labelStyle: TextStyle(
                      color: _selectedTab == 'Requirements' ? CRMColors.primaryOf(context) : CRMColors.textOf(context),
                      fontWeight: _selectedTab == 'Requirements' ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedTab = 'Requirements';
                        });
                        _fetchBinData();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: CRMSpacing.m),
              headerControls,
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recycle Bin', style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context))),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: CRMSpacing.m,
                      runSpacing: CRMSpacing.s,
                      children: [
                        Text(
                          _selectedTab == 'Properties' ? 'Deleted Properties' : 'Deleted Leads',
                          style: CRMTypography.pageTitle.copyWith(
                            color: CRMColors.textOf(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ChoiceChip(
                          label: const Text('Properties'),
                          selected: _selectedTab == 'Properties',
                          selectedColor: CRMColors.primaryOf(context).withValues(alpha: 0.12),
                          labelStyle: TextStyle(
                            color: _selectedTab == 'Properties' ? CRMColors.primaryOf(context) : CRMColors.textOf(context),
                            fontWeight: _selectedTab == 'Properties' ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedTab = 'Properties';
                              });
                              _fetchBinData();
                            }
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Leads'),
                          selected: _selectedTab == 'Requirements',
                          selectedColor: CRMColors.primaryOf(context).withValues(alpha: 0.12),
                          labelStyle: TextStyle(
                            color: _selectedTab == 'Requirements' ? CRMColors.primaryOf(context) : CRMColors.textOf(context),
                            fontWeight: _selectedTab == 'Requirements' ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedTab = 'Requirements';
                              });
                              _fetchBinData();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              headerControls,
            ],
          );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? CRMSpacing.m : CRMSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            pageHeader,
            const SizedBox(height: CRMSpacing.m),
            if (_selectedTab == 'Properties') ...[
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Rent'),
                    selected: _propertiesSubTab == 'Rent',
                    selectedColor: CRMColors.primaryOf(context).withValues(alpha: 0.12),
                    labelStyle: TextStyle(
                      color: _propertiesSubTab == 'Rent' ? CRMColors.primaryOf(context) : CRMColors.textOf(context),
                      fontWeight: _propertiesSubTab == 'Rent' ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _propertiesSubTab = 'Rent';
                          _currentPropertiesPage = 1;
                        });
                      }
                    },
                  ),
                  const SizedBox(width: CRMSpacing.s),
                  ChoiceChip(
                    label: const Text('Re-sale'),
                    selected: _propertiesSubTab == 'Re-sale',
                    selectedColor: CRMColors.primaryOf(context).withValues(alpha: 0.12),
                    labelStyle: TextStyle(
                      color: _propertiesSubTab == 'Re-sale' ? CRMColors.primaryOf(context) : CRMColors.textOf(context),
                      fontWeight: _propertiesSubTab == 'Re-sale' ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _propertiesSubTab = 'Re-sale';
                          _currentPropertiesPage = 1;
                        });
                      }
                    },
                  ),
                ],
              ),
            ] else ...[
              Wrap(
                spacing: CRMSpacing.s,
                runSpacing: CRMSpacing.s,
                children: [
                  ChoiceChip(
                    label: const Text('Bin'),
                    selected: _requirementsSubTab == 'Bin',
                    selectedColor: CRMColors.primaryOf(context).withValues(alpha: 0.12),
                    labelStyle: TextStyle(
                      color: _requirementsSubTab == 'Bin' ? CRMColors.primaryOf(context) : CRMColors.textOf(context),
                      fontWeight: _requirementsSubTab == 'Bin' ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _requirementsSubTab = 'Bin';
                          _currentRequirementsPage = 1;
                        });
                        _fetchBinRequirements();
                      }
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Not Interested'),
                    selected: _requirementsSubTab == 'Not Interested',
                    selectedColor: CRMColors.primaryOf(context).withValues(alpha: 0.12),
                    labelStyle: TextStyle(
                      color: _requirementsSubTab == 'Not Interested' ? CRMColors.primaryOf(context) : CRMColors.textOf(context),
                      fontWeight: _requirementsSubTab == 'Not Interested' ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _requirementsSubTab = 'Not Interested';
                          _currentRequirementsPage = 1;
                        });
                        _fetchBinRequirements();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Rent'),
                    selected: _requirementsListingSubTab == 'Rent',
                    selectedColor: CRMColors.primaryOf(context).withValues(alpha: 0.12),
                    labelStyle: TextStyle(
                      color: _requirementsListingSubTab == 'Rent' ? CRMColors.primaryOf(context) : CRMColors.textOf(context),
                      fontWeight: _requirementsListingSubTab == 'Rent' ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _requirementsListingSubTab = 'Rent';
                          _currentRequirementsPage = 1;
                        });
                      }
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Re-sale'),
                    selected: _requirementsListingSubTab == 'Re-sale',
                    selectedColor: CRMColors.primaryOf(context).withValues(alpha: 0.12),
                    labelStyle: TextStyle(
                      color: _requirementsListingSubTab == 'Re-sale' ? CRMColors.primaryOf(context) : CRMColors.textOf(context),
                      fontWeight: _requirementsListingSubTab == 'Re-sale' ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _requirementsListingSubTab = 'Re-sale';
                          _currentRequirementsPage = 1;
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
            const SizedBox(height: CRMSpacing.l),
            CRMCard(
              child: _isLoading
                  ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                  : _selectedTab == 'Properties'
                      ? _visibleBinProperties.isEmpty
                          ? _buildEmptyState('No deleted ${_propertiesSubTab.toLowerCase()} properties found in bin.')
                          : Builder(
                              builder: (context) {
                                final authState = context.read<AuthBloc>().state;
                                final currentUser = authState is Authenticated ? authState.user : null;
                                final isUserAdminOrSuperAdmin = currentUser != null &&
                                    (currentUser.role == 'Admin' || currentUser.role == 'Super Admin');

                                final targetProperties = _visibleBinProperties;
                                final totalItems = targetProperties.length;
                                final totalPages = (totalItems / _propertiesPerPage).ceil().clamp(1, double.infinity).toInt();
                                final startIndex = (_currentPropertiesPage - 1) * _propertiesPerPage;
                                final endIndex = (startIndex + _propertiesPerPage).clamp(0, totalItems);
                                final paginatedProperties = targetProperties.sublist(startIndex, endIndex);

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    CRMDataTable(
                                      showDecoration: false,
                                      isLoading: false,
                                      showCheckboxColumn: false,
                                      dataRowMinHeight: 56.0,
                                      dataRowMaxHeight: 64.0,
                                      columns: [
                                        const DataColumn(label: Text('Code')),
                                        if (isUserAdminOrSuperAdmin)
                                          const DataColumn(label: Text('Listed By')),
                                        const DataColumn(label: Text('Property Name')),
                                        const DataColumn(label: Text('Owner')),
                                        const DataColumn(label: Text('Area')),
                                        const DataColumn(label: Text('Price')),
                                        const DataColumn(label: Text('Actions')),
                                      ],
                                      rows: paginatedProperties.map((p) {
                                        return DataRow(
                                          cells: [
                                            DataCell(Text(p.propertyCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                                            if (isUserAdminOrSuperAdmin)
                                              DataCell(Text(p.createdByName)),
                                            DataCell(Text(p.title)),
                                            DataCell(Text(p.ownerName)),
                                            DataCell(Text(p.areaName)),
                                            DataCell(Text(CRMCurrencyFormatter.formatShort(p.price), style: const TextStyle(fontWeight: FontWeight.w600))),
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: Icon(Icons.restore_rounded, color: CRMColors.success, size: 20),
                                                    tooltip: 'Restore Property',
                                                    onPressed: () => _restoreProperty(p.id),
                                                  ),
                                                  if (isUserAdminOrSuperAdmin) ...[
                                                    const SizedBox(width: 8),
                                                    IconButton(
                                                      icon: Icon(Icons.delete_forever_rounded, color: CRMColors.danger, size: 20),
                                                      tooltip: 'Permanently Delete',
                                                      onPressed: () => _permanentDeleteProperty(p.id),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: CRMSpacing.m),
                                    _buildPropertiesPagination(
                                      totalItems,
                                      totalPages,
                                      _currentPropertiesPage,
                                    ),
                                  ],
                                );
                              },
                            )
                      : _visibleBinRequirements.isEmpty
                          ? _buildEmptyState(_requirementsSubTab == 'Bin'
                              ? 'No deleted ${_requirementsListingSubTab.toLowerCase()} leads found.'
                              : 'No ${_requirementsListingSubTab.toLowerCase()} leads marked as "Not Interested".')
                          : Builder(
                              builder: (context) {
                                final authState = context.read<AuthBloc>().state;
                                auth_model.UserModel? currentUser;
                                if (authState is Authenticated) {
                                  currentUser = authState.user;
                                }
                                final isUserAdminOrSuperAdmin = currentUser != null &&
                                    (currentUser.role?.toLowerCase() == 'admin' ||
                                        currentUser.role?.toLowerCase() == 'super admin');

                                final targetRequirements = _visibleBinRequirements;
                                final totalItems = targetRequirements.length;
                                final totalPages = (totalItems / _requirementsPerPage).ceil().clamp(1, double.infinity).toInt();
                                final startIndex = (_currentRequirementsPage - 1) * _requirementsPerPage;
                                final endIndex = (startIndex + _requirementsPerPage).clamp(0, totalItems);
                                final paginatedRequirements = targetRequirements.sublist(startIndex, endIndex);

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    CRMDataTable(
                                      showDecoration: false,
                                      isLoading: false,
                                      showCheckboxColumn: false,
                                      dataRowMinHeight: 56.0,
                                      dataRowMaxHeight: 64.0,
                                      columns: [
                                        const DataColumn(label: Text('Client Name')),
                                        const DataColumn(label: Text('Specs / Config')),
                                        const DataColumn(label: Text('Budget Range')),
                                        const DataColumn(label: Text('Target Area(s)')),
                                        if (isUserAdminOrSuperAdmin)
                                          const DataColumn(label: Text('Salesperson')),
                                        const DataColumn(label: Text('Actions')),
                                      ],
                                      rows: paginatedRequirements.map((r) {
                                        final budgetRange = '${CRMCurrencyFormatter.formatShort(r.minBudget)} - ${CRMCurrencyFormatter.formatShort(r.maxBudget)}';
                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(r.clientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                  Text(r.clientMobile, style: TextStyle(color: CRMColors.textMutedOf(context), fontSize: 11)),
                                                ],
                                              ),
                                            ),
                                            DataCell(Text('${r.propertyTypeName} (${r.configurationName ?? "-"})')),
                                            DataCell(Text(budgetRange, style: const TextStyle(fontWeight: FontWeight.w600))),
                                            DataCell(
                                              SizedBox(
                                                width: 160,
                                                child: Tooltip(
                                                  message: r.areaNames.join(', '),
                                                  child: Text(
                                                    r.areaNames.join(', '),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(color: CRMColors.textSecondaryOf(context), fontSize: 13),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (isUserAdminOrSuperAdmin)
                                              DataCell(
                                                Builder(
                                                  builder: (context) {
                                                    final salespersonName = r.creatorName ?? r.assigneeName ?? 'N/A';
                                                    final mobile = r.creatorMobile ?? '';
                                                    final email = r.creatorEmail ?? '';
                                                    return Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Text(salespersonName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                        if (email.isNotEmpty || mobile.isNotEmpty)
                                                          Text('${email.isNotEmpty ? email : "No email"} • ${mobile.isNotEmpty ? mobile : "No mobile"}',
                                                              style: TextStyle(color: CRMColors.textMutedOf(context), fontSize: 11))
                                                        else
                                                          Text('No contact details',
                                                              style: TextStyle(color: CRMColors.textMutedOf(context), fontSize: 11)),
                                                      ],
                                                    );
                                                  }
                                                )
                                              ),
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: Icon(Icons.restore_rounded, color: CRMColors.success, size: 20),
                                                    tooltip: _requirementsSubTab == 'Bin' ? 'Restore Requirement' : 'Make Active / Restore',
                                                    onPressed: () => _restoreRequirement(r),
                                                  ),
                                                  if (_requirementsSubTab == 'Bin' && isUserAdminOrSuperAdmin) ...[
                                                    const SizedBox(width: 8),
                                                    IconButton(
                                                      icon: Icon(Icons.delete_forever_rounded, color: CRMColors.danger, size: 20),
                                                      tooltip: 'Permanently Delete',
                                                      onPressed: () => _permanentDeleteRequirement(r.id),
                                                    ),
                                                  ]
                                                  else if (_requirementsSubTab != 'Bin') ...[
                                                    const SizedBox(width: 8),
                                                    IconButton(
                                                      icon: Icon(Icons.delete_outline_rounded, color: CRMColors.danger, size: 20),
                                                      tooltip: 'Move to Recycle Bin',
                                                      onPressed: () => _deleteRequirement(r),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: CRMSpacing.m),
                                    _buildRequirementsPagination(
                                      totalItems,
                                      totalPages,
                                      _currentRequirementsPage,
                                    ),
                                  ],
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String description) {
    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_sweep_outlined, size: 64, color: CRMColors.textSecondaryOf(context)),
            const SizedBox(height: CRMSpacing.m),
            Text(
              'Recycle Bin is Empty',
              style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context)),
            ),
            const SizedBox(height: CRMSpacing.xs),
            Text(
              description,
              style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertiesPagination(int totalItems, int totalPages, int currentPage) {
    final from = totalItems == 0 ? 0 : (currentPage - 1) * _propertiesPerPage + 1;
    final to = (currentPage * _propertiesPerPage).clamp(0, totalItems);
    final double screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 500;

    final infoText = Text(
      'Showing $from–$to of $totalItems',
      style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
    );

    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Rows:',
            style:
                CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context))),
        const SizedBox(width: CRMSpacing.xs),
        DropdownButton<int>(
          value: _propertiesPerPage,
          underline: const SizedBox.shrink(),
          items: const [
            DropdownMenuItem(value: 15, child: Text('15')),
            DropdownMenuItem(value: 30, child: Text('30')),
            DropdownMenuItem(value: 50, child: Text('50')),
          ],
          onChanged: (val) {
            if (val == null) return;
            setState(() {
              _propertiesPerPage = val;
              _currentPropertiesPage = 1;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed:
              currentPage > 1 ? () => setState(() => _currentPropertiesPage--) : null,
        ),
        Text(
          '$currentPage / $totalPages',
          style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context)),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: currentPage < totalPages
              ? () => setState(() => _currentPropertiesPage++)
              : null,
        ),
      ],
    );

    if (isMobile) {
      return Column(
        children: [
          infoText,
          const SizedBox(height: CRMSpacing.s),
          controls,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        infoText,
        controls,
      ],
    );
  }

  Widget _buildRequirementsPagination(int totalItems, int totalPages, int currentPage) {
    final from = totalItems == 0 ? 0 : (currentPage - 1) * _requirementsPerPage + 1;
    final to = (currentPage * _requirementsPerPage).clamp(0, totalItems);
    final double screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 500;

    final infoText = Text(
      'Showing $from–$to of $totalItems',
      style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
    );

    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Rows:',
            style:
                CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context))),
        const SizedBox(width: CRMSpacing.xs),
        DropdownButton<int>(
          value: _requirementsPerPage,
          underline: const SizedBox.shrink(),
          items: const [
            DropdownMenuItem(value: 15, child: Text('15')),
            DropdownMenuItem(value: 30, child: Text('30')),
            DropdownMenuItem(value: 50, child: Text('50')),
          ],
          onChanged: (val) {
            if (val == null) return;
            setState(() {
              _requirementsPerPage = val;
              _currentRequirementsPage = 1;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed:
              currentPage > 1 ? () => setState(() => _currentRequirementsPage--) : null,
        ),
        Text(
          '$currentPage / $totalPages',
          style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context)),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: currentPage < totalPages
              ? () => setState(() => _currentRequirementsPage++)
              : null,
        ),
      ],
    );

    if (isMobile) {
      return Column(
        children: [
          infoText,
          const SizedBox(height: CRMSpacing.s),
          controls,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        infoText,
        controls,
      ],
    );
  }
}
