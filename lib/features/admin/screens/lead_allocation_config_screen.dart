import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/api/dio_client.dart';

class LeadAllocationConfigScreen extends StatefulWidget {
  const LeadAllocationConfigScreen({super.key});

  @override
  State<LeadAllocationConfigScreen> createState() => _LeadAllocationConfigScreenState();
}

class _LeadAllocationConfigScreenState extends State<LeadAllocationConfigScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  // Target role can be: 'Telecaller', 'Sales', or 'NONE'
  String _targetRole = 'Telecaller';
  bool _isUpdatingRole = false;

  // Dynamic campaigns & connections fetched directly from DB
  List<Map<String, dynamic>> _campaigns = [];
  List<Map<String, dynamic>> _telecallers = [];
  List<Map<String, dynamic>> _salespersons = [];

  // Granular allocations: [{ id, role, campaign_id, category_name, user_id, is_enabled, user_name }]
  List<Map<String, dynamic>> _categoryAllocations = [];

  // In-flight saving ids for toggles and deletions
  final Set<String> _pendingActionIds = {};

  // Search filter query
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _salesPoolScrollController = ScrollController();
  final ScrollController _telecallerPoolScrollController = ScrollController();

  // Static standard property categories for Salesperson
  static const List<Map<String, dynamic>> _salesPropertyCategories = [
    {
      'id': 'Residential',
      'name': 'Residential',
      'icon': Icons.home_outlined,
      'color': Color(0xFF6366F1),
    },
    {
      'id': 'Commercial',
      'name': 'Commercial',
      'icon': Icons.business_outlined,
      'color': Color(0xFFF59E0B),
    },
    {
      'id': 'Land & Plot',
      'name': 'Land & Plot',
      'icon': Icons.terrain_outlined,
      'color': Color(0xFF10B981),
    },
    {
      'id': 'Industrial',
      'name': 'Industrial',
      'icon': Icons.factory_outlined,
      'color': Color(0xFFEC4899),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await DioClient.dio.get(ApiConstants.adminAllocationConfig);
      final rawData = res.data is Map ? (res.data['data'] ?? res.data) : null;
      final data = rawData is Map ? Map<String, dynamic>.from(rawData) : <String, dynamic>{};

      final rawTargetRole = (data['targetRole'] ?? 'NONE').toString().trim();
      final rawCampaigns = (data['campaigns'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final rawTelecallers = (data['telecallers'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final rawSalespersons = (data['salespersons'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final rawCategoryAllocations = (data['categoryAllocations'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      setState(() {
        if (rawTargetRole.toLowerCase() == 'sales') {
          _targetRole = 'Sales';
        } else if (rawTargetRole.toLowerCase() == 'telecaller') {
          _targetRole = 'Telecaller';
        } else {
          _targetRole = 'NONE';
        }

        _campaigns = rawCampaigns;
        _telecallers = rawTelecallers;
        _salespersons = rawSalespersons;
        _categoryAllocations = List<Map<String, dynamic>>.from(rawCategoryAllocations);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load allocation configuration: $e';
      });
    }
  }

  /// Toggle interaction rules:
  /// - Both can be OFF simultaneously (_targetRole = 'NONE')
  /// - Both cannot be ON at the same time
  /// - Tapping active toggle turns it OFF (_targetRole = 'NONE')
  /// - Tapping inactive toggle turns it ON and the other OFF
  Future<void> _handleToggleRole(String toggledRole) async {
    if (_isUpdatingRole) return;

    String newRole;
    if (_targetRole == toggledRole) {
      // User tapped the currently active toggle -> Turn it OFF
      newRole = 'NONE';
    } else {
      // User tapped an inactive toggle -> Turn it ON (and other turns OFF)
      newRole = toggledRole;
    }

    setState(() {
      _isUpdatingRole = true;
    });

    try {
      await DioClient.dio.post(
        ApiConstants.adminAllocationConfigRole,
        data: {'role': newRole},
      );

      setState(() {
        _targetRole = newRole;
        _isUpdatingRole = false;
      });

      if (mounted) {
        String msg;
        Color bg;
        if (newRole == 'Sales') {
          msg = 'Direct Sales allocation is now active. Leads route to Salespersons.';
          bg = const Color(0xFF10B981);
        } else if (newRole == 'Telecaller') {
          msg = 'Telecaller allocation is now active. Leads route to Telecallers.';
          bg = const Color(0xFF3B82F6);
        } else {
          msg = 'Lead allocation turned OFF. Incoming leads will wait in queue.';
          bg = const Color(0xFFF59E0B);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: bg,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUpdatingRole = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update allocation mode: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Get assigned users for a specific campaign and category
  List<Map<String, dynamic>> _getAssignedAllocations(String role, String campaignId, String categoryName) {
    final targetRole = role.toUpperCase();
    final targetCamp = campaignId.trim().toUpperCase();
    final targetCat = categoryName.trim().toUpperCase();

    return _categoryAllocations.where((a) {
      final aRole = (a['role'] ?? '').toString().toUpperCase();
      final aCamp = (a['campaign_id'] ?? '').toString().toUpperCase();
      final aCat = (a['category_name'] ?? '').toString().toUpperCase();
      return aRole == targetRole && aCamp == targetCamp && aCat == targetCat;
    }).toList();
  }

  /// Assign a user (Salesperson or Telecaller) to a campaign category
  Future<void> _assignUserToCategory({
    required String role,
    required String campaignId,
    required String categoryName,
    required Map<String, dynamic> user,
  }) async {
    final userId = user['id']?.toString() ?? '';
    final userName = user['name']?.toString() ?? 'User';
    if (userId.isEmpty) return;

// Category allocation can be added and toggled independently

    final existing = _getAssignedAllocations(role, campaignId, categoryName);
    final alreadyAssigned = existing.any((a) => a['user_id']?.toString() == userId);
    if (alreadyAssigned) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userName is already assigned to this category.'),
            backgroundColor: const Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempRecord = {
      'id': tempId,
      'role': role,
      'campaign_id': campaignId,
      'category_name': categoryName,
      'user_id': userId,
      'user_name': userName,
      'is_enabled': true,
    };

    // Optimistic UI update
    setState(() {
      _categoryAllocations.add(tempRecord);
      _pendingActionIds.add(tempId);
    });

    try {
      final res = await DioClient.dio.post(
        ApiConstants.adminAllocationCategoryAllocation,
        data: {
          'role': role,
          'campaignId': campaignId,
          'categoryName': categoryName,
          'userId': userId,
          'isEnabled': true,
        },
      );

      final resPayload = res.data is Map ? res.data as Map : {};
      final savedData = resPayload['data'] is Map ? resPayload['data'] as Map : resPayload;
      final saved = savedData.isNotEmpty ? Map<String, dynamic>.from(savedData) : null;
      if (saved != null && mounted) {
        setState(() {
          _categoryAllocations.removeWhere((a) =>
              a['id'] == tempId ||
              a['id'] == saved['id'] ||
              (a['user_id']?.toString() == userId &&
                  a['role']?.toString().toUpperCase() == role.toUpperCase() &&
                  a['campaign_id']?.toString().toUpperCase() == campaignId.toUpperCase() &&
                  a['category_name']?.toString().toUpperCase() == categoryName.toUpperCase()));
          _categoryAllocations.add({
            ...saved,
            'user_name': userName,
          });
          _pendingActionIds.remove(tempId);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _categoryAllocations.removeWhere((a) => a['id'] == tempId);
          _pendingActionIds.remove(tempId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign $userName: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  int _salesAllocationCount(String campaignId) {
    final camp = campaignId.trim().toUpperCase();
    return _categoryAllocations.where((a) {
      return (a['role'] ?? '').toString().toUpperCase() == 'SALES' &&
          (a['campaign_id'] ?? '').toString().toUpperCase() == camp;
    }).length;
  }

  /// "Same As": pick another campaign and copy its Salesperson allocation to this campaign.
  Future<void> _showSameAsDialog(String targetCampaignId, String targetCampaignName) async {
    final sources = _campaigns
        .where((c) => (c['id'] ?? '').toString().trim().toUpperCase() != targetCampaignId.trim().toUpperCase())
        .toList();
    String? selectedId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          String selectedName = '';
          for (final c in sources) {
            if ((c['id'] ?? '').toString() == selectedId) {
              selectedName = c['name']?.toString() ?? selectedId!;
            }
          }
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Same As — $targetCampaignName'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select a campaign to copy its Salesperson allocation from.',
                    style: TextStyle(fontSize: 12.5, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  if (sources.isEmpty)
                    const Text(
                      'No other campaign is available.',
                      style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: SingleChildScrollView(
                        child: Column(
                          children: sources.map((c) {
                            final id = (c['id'] ?? '').toString();
                            final name = c['name']?.toString() ?? id;
                            final count = _salesAllocationCount(id);
                            final hasAssignments = count > 0;
                            final isSelected = selectedId == id;
                            return ListTile(
                              onTap: hasAssignments ? () => setDialogState(() => selectedId = id) : null,
                              enabled: hasAssignments,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                color: isSelected ? const Color(0xFF10B981) : Colors.grey,
                              ),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                hasAssignments ? '$count Salesperson assignment${count == 1 ? '' : 's'}' : 'No Salesperson assigned',
                                style: const TextStyle(fontSize: 11.5),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  if (selectedId != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Salesperson assignments of $targetCampaignName will be replaced with those of $selectedName. Telecaller settings are not changed.',
                      style: const TextStyle(fontSize: 12, color: Color(0xFFB45309), height: 1.35),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: selectedId == null ? null : () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true || selectedId == null || !mounted) return;
    await _copySalesAllocationFrom(selectedId!, targetCampaignId, targetCampaignName);
  }

  Future<void> _copySalesAllocationFrom(String sourceCampaignId, String targetCampaignId, String targetCampaignName) async {
    final pendingKey = 'same_as_$targetCampaignId';
    setState(() => _pendingActionIds.add(pendingKey));
    try {
      final res = await DioClient.dio.post(
        ApiConstants.adminAllocationCategoryCopy,
        data: {
          'sourceCampaignId': sourceCampaignId,
          'targetCampaignId': targetCampaignId,
        },
      );
      final payload = res.data is Map ? res.data as Map : {};
      final data = payload['data'] is Map ? payload['data'] as Map : {};
      final copied = (data['allocations'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (!mounted) return;
      final target = targetCampaignId.trim().toUpperCase();
      setState(() {
        _categoryAllocations.removeWhere((a) =>
            (a['role'] ?? '').toString().toUpperCase() == 'SALES' &&
            (a['campaign_id'] ?? '').toString().toUpperCase() == target);
        _categoryAllocations.addAll(copied);
        _pendingActionIds.remove(pendingKey);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Salesperson allocation copied to $targetCampaignName.'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _pendingActionIds.remove(pendingKey));
      var message = 'Failed to copy Salesperson allocation.';
      if (e is DioException) {
        final body = e.response?.data;
        if (body is Map && (body['message']?.toString().trim().isNotEmpty ?? false)) {
          message = body['message'].toString();
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }


  /// Toggle a salesperson's individual lead allocation availability ON / OFF
  Future<void> _toggleSalespersonAvailability(String userId, String userName, bool newStatus) async {
    if (_pendingActionIds.contains(userId)) return;

    final index = _salespersons.indexWhere((u) => u['id']?.toString() == userId);
    if (index == -1) return;

    final oldAllocEnabled = _salespersons[index]['isAllocatedEnabled'] != false && _salespersons[index]['status'] != 'INACTIVE';
    final Map<String, bool> oldCategoryStates = {};
    for (final alloc in _categoryAllocations) {
      if (alloc['user_id']?.toString() == userId && alloc['id'] != null) {
        oldCategoryStates[alloc['id'].toString()] = alloc['is_enabled'] != false;
      }
    }

    // Optimistic UI update
    setState(() {
      _salespersons[index]['isAllocatedEnabled'] = newStatus;
      _salespersons[index]['status'] = newStatus ? 'ACTIVE' : 'INACTIVE';
      for (final alloc in _categoryAllocations) {
        if (alloc['user_id']?.toString() == userId) {
          alloc['is_enabled'] = newStatus;
        }
      }

      _pendingActionIds.add(userId);
    });

    try {
      await DioClient.dio.post(
        ApiConstants.adminAllocationConfigUserAvailability,
        data: {
          'userId': userId,
          'isEnabled': newStatus,
        },
      );

      if (mounted) {
        setState(() {
          _pendingActionIds.remove(userId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? '$userName is now ACTIVE for lead allocation & round-robin.'
                  : '$userName is now PAUSED (OFF) from lead allocation.',
            ),
            backgroundColor: newStatus ? const Color(0xFF10B981) : const Color(0xFF64748B),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _salespersons[index]['isAllocatedEnabled'] = oldAllocEnabled;
          _salespersons[index]['status'] = oldAllocEnabled ? 'ACTIVE' : 'INACTIVE';
          if (oldCategoryStates.isNotEmpty) {
            for (final alloc in _categoryAllocations) {
              final id = alloc['id']?.toString();
              if (id != null && oldCategoryStates.containsKey(id)) {
                alloc['is_enabled'] = oldCategoryStates[id];
              }
            }
          }

          _pendingActionIds.remove(userId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status for $userName: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Toggle an assigned user's allocation within a specific category
  Future<void> _toggleCategoryAllocation(String allocationId, bool newStatus) async {
    if (_pendingActionIds.contains(allocationId)) return;

    // Optimistic update
    final index = _categoryAllocations.indexWhere((a) => a['id']?.toString() == allocationId);
    if (index == -1) return;

    final oldStatus = _categoryAllocations[index]['is_enabled'] != false;
    setState(() {
      _categoryAllocations[index]['is_enabled'] = newStatus;
      _pendingActionIds.add(allocationId);
    });

    try {
      await DioClient.dio.patch(
        ApiConstants.adminAllocationCategoryToggle(allocationId),
        data: {'isEnabled': newStatus},
      );
      if (mounted) {
        setState(() {
          _pendingActionIds.remove(allocationId);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _categoryAllocations[index]['is_enabled'] = oldStatus;
          _pendingActionIds.remove(allocationId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update toggle: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Remove an assigned user from a campaign category
  Future<void> _deleteCategoryAllocation(String allocationId, String userName) async {
    if (_pendingActionIds.contains(allocationId)) return;

    final index = _categoryAllocations.indexWhere((a) => a['id']?.toString() == allocationId);
    if (index == -1) return;

    final removedItem = _categoryAllocations[index];

    // Optimistic remove
    setState(() {
      _categoryAllocations.removeAt(index);
      _pendingActionIds.add(allocationId);
    });

    try {
      await DioClient.dio.delete(
        ApiConstants.adminAllocationCategoryDelete(allocationId),
      );
      if (mounted) {
        setState(() {
          _pendingActionIds.remove(allocationId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed $userName from this category.'),
            backgroundColor: const Color(0xFF64748B),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _categoryAllocations.insert(index, removedItem);
          _pendingActionIds.remove(allocationId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove assignment: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Open quick-add user dialog for a specific campaign & category
  void _openQuickAssignModal({
    required String role,
    required String campaignId,
    required String categoryName,
    required String campaignTitle,
  }) {
    final availableUsers = role == 'Sales' ? _salespersons : _telecallers;
    final assigned = _getAssignedAllocations(role, campaignId, categoryName);
    final assignedUserIds = assigned.map((a) => a['user_id']?.toString()).toSet();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            role == 'Sales' ? 'Assign Salesperson' : 'Assign Telecaller',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            role == 'Sales'
                                ? '$campaignTitle → $categoryName'
                                : campaignTitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                if (availableUsers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        role == 'Sales' ? 'No salespersons found.' : 'No telecallers found.',
                        style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: availableUsers.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final u = availableUsers[i];
                        final uId = u['id']?.toString() ?? '';
                        final uName = u['name']?.toString() ?? 'Unnamed';
                        final isAlready = assignedUserIds.contains(uId);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: (role == 'Sales' ? const Color(0xFF10B981) : const Color(0xFF3B82F6))
                                .withValues(alpha: 0.15),
                            child: Text(
                              uName.isNotEmpty ? uName[0].toUpperCase() : 'U',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: role == 'Sales' ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                              ),
                            ),
                          ),
                          title: Text(
                            uName,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                          ),
                          subtitle: Text(
                            'Workload: ${u['currentWorkload'] ?? 0} leads',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                          trailing: isAlready
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Assigned',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                                  ),
                                )
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: role == 'Sales' ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    _assignUserToCategory(
                                      role: role,
                                      campaignId: campaignId,
                                      categoryName: categoryName,
                                      user: u,
                                    );
                                  },
                                  child: const Text('Assign', style: TextStyle(fontSize: 12.5)),
                                ),
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: isMobile
          ? AppBar(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              elevation: 0.5,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                onPressed: () => context.pop(),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lead Allocation Configuration',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Dynamic campaign & property-category lead routing',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh Configuration',
                  onPressed: _loadConfig,
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : isMobile
                  ? RefreshIndicator(
                      onRefresh: _loadConfig,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        children: [
                          _buildDualRoleTogglesCard(isDark, true),
                          const SizedBox(height: 24),
                          if (_targetRole == 'Sales')
                            _buildSalespersonAllocationView(isDark, true, screenWidth)
                          else if (_targetRole == 'Telecaller')
                            _buildTelecallerAllocationView(isDark, true, screenWidth)
                          else
                            _buildBothOffView(isDark),
                          const SizedBox(height: 48),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadConfig,
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDesktopHeader(isDark),
                                  const SizedBox(height: 20),
                                  _buildDualRoleTogglesCard(isDark, false),
                                  const SizedBox(height: 24),
                                  if (_targetRole == 'Sales') ...[
                                    _buildSalespersonSectionHeader(isDark, false),
                                    const SizedBox(height: 12),
                                  ] else if (_targetRole == 'Telecaller') ...[
                                    _buildTelecallerSectionHeader(isDark, false),
                                    const SizedBox(height: 12),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          if (_targetRole == 'Sales') ...[
                            SliverPersistentHeader(
                              pinned: true,
                              delegate: _StickyPoolHeaderDelegate(
                                isDark: isDark,
                                height: 104.0,
                                child: _buildUserDraggablePool(
                                  users: _salespersons,
                                  role: 'Sales',
                                  isDark: isDark,
                                  accentColor: const Color(0xFF10B981),
                                  isSticky: true,
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSearchField(isDark),
                                    const SizedBox(height: 20),
                                    _buildSalespersonCampaignsList(isDark, screenWidth),
                                  ],
                                ),
                              ),
                            ),
                          ] else if (_targetRole == 'Telecaller') ...[
                            SliverPersistentHeader(
                              pinned: true,
                              delegate: _StickyPoolHeaderDelegate(
                                isDark: isDark,
                                height: 104.0,
                                child: _buildUserDraggablePool(
                                  users: _telecallers,
                                  role: 'Telecaller',
                                  isDark: isDark,
                                  accentColor: const Color(0xFF3B82F6),
                                  isSticky: true,
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSearchField(isDark),
                                    const SizedBox(height: 20),
                                    _buildTelecallerCampaignsList(isDark, screenWidth),
                                  ],
                                ),
                              ),
                            ),
                          ] else
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
                                child: _buildBothOffView(isDark),
                              ),
                            ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildDesktopHeader(bool isDark) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          tooltip: 'Back to Lead Allocation',
          onPressed: () => context.pop(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lead Allocation Configuration',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Dynamic campaign & property-category lead routing',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh Configuration',
          onPressed: _loadConfig,
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadConfig,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 1. DUAL ROLE TOGGLES CARD
  // -------------------------------------------------------------
  Widget _buildDualRoleTogglesCard(bool isDark, bool isMobile) {
    final bool isTelecallerOn = _targetRole == 'Telecaller';
    final bool isSalespersonOn = _targetRole == 'Sales';
    final bool isBothOff = _targetRole == 'NONE';

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.alt_route_rounded, color: Color(0xFF6366F1), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lead Allocation Routing Mode',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Turn ON either Telecaller or Salesperson. Only one can be active at a time, or both can be OFF.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isUpdatingRole)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 18),

          // Side-by-side toggles
          LayoutBuilder(
            builder: (context, constraints) {
              final toggle1 = _buildToggleItem(
                title: 'Telecaller',
                subtitle: 'Campaign leads route to Telecallers first',
                icon: Icons.headset_mic_outlined,
                isOn: isTelecallerOn,
                activeColor: const Color(0xFF3B82F6),
                onChanged: (_) => _handleToggleRole('Telecaller'),
                isDark: isDark,
              );

              final toggle2 = _buildToggleItem(
                title: 'Salesperson',
                subtitle: 'Direct allocation to Sales by property category',
                icon: Icons.badge_outlined,
                isOn: isSalespersonOn,
                activeColor: const Color(0xFF10B981),
                onChanged: (_) => _handleToggleRole('Sales'),
                isDark: isDark,
              );

              if (isMobile) {
                return Column(
                  children: [
                    toggle1,
                    const SizedBox(height: 12),
                    toggle2,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: toggle1),
                  const SizedBox(width: 16),
                  Expanded(child: toggle2),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Informative Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isBothOff
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.1)
                  : (isTelecallerOn ? const Color(0xFF3B82F6) : const Color(0xFF10B981)).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isBothOff
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                    : (isTelecallerOn ? const Color(0xFF3B82F6) : const Color(0xFF10B981)).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isBothOff ? Icons.pause_circle_outline : Icons.info_outline,
                  size: 18,
                  color: isBothOff
                      ? const Color(0xFFD97706)
                      : (isTelecallerOn ? const Color(0xFF3B82F6) : const Color(0xFF10B981)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isBothOff
                        ? 'Allocation is currently OFF. Incoming leads will be kept in waiting queue until Telecaller or Salesperson allocation is turned ON.'
                        : (isTelecallerOn
                            ? 'Telecaller mode is ON. Incoming campaign leads route to assigned Telecallers in round-robin order.'
                            : 'Salesperson mode is ON. Leads route directly to Salespersons based on Campaign & Property Category (Residential, Commercial, Land & Plot, Industrial).'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isBothOff
                          ? (isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309))
                          : (isTelecallerOn
                              ? (isDark ? Colors.blue.shade200 : const Color(0xFF1D4ED8))
                              : (isDark ? const Color(0xFFA7F3D0) : const Color(0xFF047857))),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isOn,
    required Color activeColor,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => onChanged(!isOn),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isOn
              ? activeColor.withValues(alpha: isDark ? 0.16 : 0.08)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isOn ? activeColor : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            width: isOn ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isOn ? activeColor : Colors.grey.shade500.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isOn ? Colors.white : Colors.grey, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: isOn ? activeColor : (isDark ? Colors.white : const Color(0xFF0F172A)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isOn ? activeColor.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isOn ? 'ON' : 'OFF',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isOn ? activeColor : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isOn,
              activeThumbColor: activeColor,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. BOTH OFF STATE
  // -------------------------------------------------------------
  Widget _buildBothOffView(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.pause_circle_filled, size: 52, color: Color(0xFFF59E0B)),
            ),
            const SizedBox(height: 18),
            const Text(
              'Lead Allocation is Paused',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Text(
                'Both Telecaller and Salesperson allocations are turned OFF. Incoming marketing campaign leads will wait in the queue without being automatically routed.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.headset_mic_outlined, size: 18),
                  label: const Text('Enable Telecaller Mode'),
                  onPressed: () => _handleToggleRole('Telecaller'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.badge_outlined, size: 18),
                  label: const Text('Enable Salesperson Mode'),
                  onPressed: () => _handleToggleRole('Sales'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 3. SALESPERSON ALLOCATION VIEW & COMPONENTS
  // -------------------------------------------------------------
  Widget _buildSalespersonSectionHeader(bool isDark, bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Salesperson Campaign Lead Allocation',
                style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 3),
              Text(
                'Drag salespersons into property categories below, or click + on any category.',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF10B981), width: 1),
          ),
          child: Text(
            '${_salespersons.length} Salespersons',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
          ),
        ),
      ],
    );
  }

  Widget _buildSalespersonCampaignsList(bool isDark, double screenWidth) {
    final filteredCampaigns = _campaigns.where((c) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final name = (c['name'] ?? '').toString().toLowerCase();
      final id = (c['id'] ?? '').toString().toLowerCase();
      return name.contains(q) || id.contains(q);
    }).toList();

    if (filteredCampaigns.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Text(
            _searchQuery.isNotEmpty
                ? 'No campaigns match "$_searchQuery"'
                : 'No campaigns found in database.',
            style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final bool isTwoCol = maxWidth >= 860;
        final double spacing = 18.0;
        final double cardWidth = isTwoCol ? (maxWidth - spacing) / 2 : maxWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: filteredCampaigns.map((camp) {
            return SizedBox(
              width: cardWidth,
              child: _buildSalespersonCampaignCard(camp, isDark, cardWidth),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSalespersonAllocationView(bool isDark, bool isMobile, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSalespersonSectionHeader(isDark, isMobile),
        const SizedBox(height: 16),
        _buildUserDraggablePool(
          users: _salespersons,
          role: 'Sales',
          isDark: isDark,
          accentColor: const Color(0xFF10B981),
          isSticky: false,
        ),
        const SizedBox(height: 20),
        _buildSearchField(isDark),
        const SizedBox(height: 20),
        _buildSalespersonCampaignsList(isDark, screenWidth),
      ],
    );
  }

  // -------------------------------------------------------------
  // 4. TELECALLER ALLOCATION VIEW & COMPONENTS
  // -------------------------------------------------------------
  Widget _buildTelecallerSectionHeader(bool isDark, bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Telecaller Campaign Lead Allocation',
                style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 3),
              Text(
                'Drag telecallers into campaign connections. Leads route to assigned telecallers.',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF3B82F6), width: 1),
          ),
          child: Text(
            '${_telecallers.length} Telecallers',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
          ),
        ),
      ],
    );
  }

  Widget _buildTelecallerCampaignsList(bool isDark, double screenWidth) {
    final filteredCampaigns = _campaigns.where((c) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final name = (c['name'] ?? '').toString().toLowerCase();
      final id = (c['id'] ?? '').toString().toLowerCase();
      return name.contains(q) || id.contains(q);
    }).toList();

    if (filteredCampaigns.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Text(
            _searchQuery.isNotEmpty
                ? 'No campaign connections match "$_searchQuery"'
                : 'No campaign connections found in database.',
            style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final bool isTwoCol = maxWidth >= 860;
        final double spacing = 18.0;
        final double cardWidth = isTwoCol ? (maxWidth - spacing) / 2 : maxWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: filteredCampaigns.map((camp) {
            return SizedBox(
              width: cardWidth,
              child: _buildTelecallerCampaignConnectionCard(camp, isDark),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTelecallerAllocationView(bool isDark, bool isMobile, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTelecallerSectionHeader(isDark, isMobile),
        const SizedBox(height: 16),
        _buildUserDraggablePool(
          users: _telecallers,
          role: 'Telecaller',
          isDark: isDark,
          accentColor: const Color(0xFF3B82F6),
          isSticky: false,
        ),
        const SizedBox(height: 20),
        _buildSearchField(isDark),
        const SizedBox(height: 20),
        _buildTelecallerCampaignsList(isDark, screenWidth),
      ],
    );
  }

  // -------------------------------------------------------------
  // USER DRAGGABLE POOL TRAY
  // -------------------------------------------------------------
  Widget _buildUserDraggablePool({
    required List<Map<String, dynamic>> users,
    required String role,
    required bool isDark,
    required Color accentColor,
    bool isSticky = false,
  }) {
    if (isSticky) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.touch_app_outlined, size: 16, color: accentColor),
                const SizedBox(width: 8),
                Text(
                  role == 'Sales'
                      ? 'Available Salespersons (Drag to assign)'
                      : 'Available Telecallers (Drag to assign)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                Text(
                  'Hold & drag into any drop zone below',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: () {
                    final ctrl = role == 'Sales' ? _salesPoolScrollController : _telecallerPoolScrollController;
                    if (ctrl.hasClients) {
                      ctrl.animateTo(
                        (ctrl.offset - 220).clamp(0.0, ctrl.position.maxScrollExtent),
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.chevron_left,
                      size: 16,
                      color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    final ctrl = role == 'Sales' ? _salesPoolScrollController : _telecallerPoolScrollController;
                    if (ctrl.hasClients) {
                      ctrl.animateTo(
                        (ctrl.offset + 220).clamp(0.0, ctrl.position.maxScrollExtent),
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (users.isEmpty)
              SizedBox(
                height: 38,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'No active users found for this role.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ),
              )
            else
              SizedBox(
                height: 40,
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    scrollbars: false,
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                    },
                  ),
                  child: SingleChildScrollView(
                    controller: role == 'Sales' ? _salesPoolScrollController : _telecallerPoolScrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: users.map((u) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: _buildDraggableUserChip(u, role, isDark, accentColor),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 480;
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.touch_app_outlined, size: 16, color: accentColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            role == 'Sales'
                                ? 'Available Salespersons (Drag to assign)'
                                : 'Available Telecallers (Drag to assign)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hold & drag into any drop zone below',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Icon(Icons.touch_app_outlined, size: 16, color: accentColor),
                  const SizedBox(width: 8),
                  Text(
                    role == 'Sales'
                        ? 'Available Salespersons (Drag to assign)'
                        : 'Available Telecallers (Drag to assign)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Hold & drag into any drop zone below',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          if (users.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No active users found for this role.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: users.map((u) {
                return _buildDraggableUserChip(u, role, isDark, accentColor);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildDraggableUserChip(
    Map<String, dynamic> user,
    String role,
    bool isDark,
    Color accentColor,
  ) {
    final userId = user['id']?.toString() ?? '';
    final name = user['name']?.toString() ?? 'User';
    final workload = (user['currentWorkload'] as num?)?.toInt() ?? 0;
    final isAllocEnabled = user['isAllocatedEnabled'] != false && user['status'] != 'INACTIVE';
    final isPending = _pendingActionIds.contains(userId);
    final canDrag = !isPending;

    final chipContent = _buildChipContent(
      user: user,
      name: name,
      workload: workload,
      isDark: isDark,
      accentColor: accentColor,
      role: role,
      isAllocEnabled: isAllocEnabled,
      isPending: isPending,
      canDrag: canDrag,
    );

    if (!canDrag) {
      return chipContent;
    }

    return Draggable<Map<String, dynamic>>(
      data: user,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.drag_indicator, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: chipContent,
      ),
      child: chipContent,
    );
  }

  Widget _buildChipContent({
    required Map<String, dynamic> user,
    required String name,
    required int workload,
    required bool isDark,
    required Color accentColor,
    required String role,
    required bool isAllocEnabled,
    required bool isPending,
    required bool canDrag,
  }) {
    final userId = user['id']?.toString() ?? '';
    final isSales = role == 'Sales';

    final effectiveColor = (!isSales || isAllocEnabled)
        ? accentColor
        : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (!isSales || isAllocEnabled)
            ? accentColor.withValues(alpha: isDark ? 0.15 : 0.08)
            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: (!isSales || isAllocEnabled)
              ? accentColor.withValues(alpha: 0.35)
              : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: effectiveColor,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: (!isSales || isAllocEnabled)
                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
          ),
          if (!isSales) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: effectiveColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$workload leads',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: effectiveColor),
              ),
            ),
          ],
          if (isSales) ...[
            const SizedBox(width: 8),
            // Individual ON/OFF Toggle switch next to Salesperson's name
            Tooltip(
              message: isAllocEnabled
                  ? 'Allocation ACTIVE (Click to turn OFF for $name)'
                  : 'Allocation OFF (Click to turn ON for $name)',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isAllocEnabled ? 'ON' : 'OFF',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: isAllocEnabled
                          ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (isPending)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    SizedBox(
                      height: 20,
                      width: 32,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Switch(
                          value: isAllocEnabled,
                          activeThumbColor: const Color(0xFF10B981),
                          activeTrackColor: const Color(0xFFA7F3D0),
                          inactiveThumbColor: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          inactiveTrackColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          onChanged: (val) {
                            _toggleSalespersonAvailability(userId, name, val);
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(width: 6),
          Tooltip(
            message: canDrag ? 'Hold & drag to assign' : 'Disabled from lead allocation (Turn ON to drag)',
            child: Icon(
              canDrag ? Icons.drag_indicator : Icons.block,
              size: 14,
              color: canDrag
                  ? (isDark ? Colors.grey.shade400 : Colors.grey.shade500)
                  : (isDark ? Colors.red.shade400 : Colors.red.shade600),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // SALESPERSON CAMPAIGN CARD (With 4 Property Categories directly underneath)
  // -------------------------------------------------------------
  Widget _buildSalespersonCampaignCard(Map<String, dynamic> campaign, bool isDark, double screenWidth) {
    final campId = (campaign['id'] ?? '').toString();
    final campName = campaign['name']?.toString() ?? campId;
    final provider = campaign['provider']?.toString() ?? '';
    final isConnection = campaign['isConnection'] == true;

    // Count assigned salespersons across all 4 categories for this campaign
    int totalAssigned = 0;
    for (final cat in _salesPropertyCategories) {
      totalAssigned += _getAssignedAllocations('Sales', campId, cat['name']).length;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Campaign Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.campaign_outlined, color: Color(0xFF10B981), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (isConnection)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'CONNECTION',
                                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
                              ),
                            ),
                          Text(
                            provider.isNotEmpty ? 'Source: $provider' : 'Marketing Campaign',
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: totalAssigned > 0
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    totalAssigned > 0 ? '$totalAssigned Assigned' : 'Unassigned',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: totalAssigned > 0 ? const Color(0xFF10B981) : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Copy Salesperson allocation from another campaign',
                  child: OutlinedButton.icon(
                    onPressed: _pendingActionIds.contains('same_as_$campId')
                        ? null
                        : () => _showSameAsDialog(campId, campName),
                    icon: _pendingActionIds.contains('same_as_$campId')
                        ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.copy_all_rounded, size: 14),
                    label: const Text('Same As', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981),
                      side: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4 Property Categories Drop Zones Directly Underneath
          Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 480;
                final spacing = 12.0;

                if (!isWide) {
                  // Single Column when card is very narrow
                  return Column(
                    children: _salesPropertyCategories.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildSalesCategoryDropZone(
                          campaignId: campId,
                          campaignTitle: campName,
                          category: cat,
                          isDark: isDark,
                        ),
                      );
                    }).toList(),
                  );
                }

                // 2 Columns on desktop / tablet
                final colWidth = (constraints.maxWidth - spacing) / 2;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: _salesPropertyCategories.map((cat) {
                    return SizedBox(
                      width: colWidth,
                      child: _buildSalesCategoryDropZone(
                        campaignId: campId,
                        campaignTitle: campName,
                        category: cat,
                        isDark: isDark,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // SALES CATEGORY DROP ZONE
  // -------------------------------------------------------------
  Widget _buildSalesCategoryDropZone({
    required String campaignId,
    required String campaignTitle,
    required Map<String, dynamic> category,
    required bool isDark,
  }) {
    final catName = category['name'] as String;
    final catIcon = category['icon'] as IconData;
    final catColor = category['color'] as Color;

    final assigned = _getAssignedAllocations('Sales', campaignId, catName);

    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) {
        final u = details.data;
        return (u['isAllocatedEnabled'] != false && u['status'] != 'INACTIVE');
      },
      onAcceptWithDetails: (details) {
        _assignUserToCategory(
          role: 'Sales',
          campaignId: campaignId,
          categoryName: catName,
          user: details.data,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isHovered
                ? catColor.withValues(alpha: isDark ? 0.25 : 0.12)
                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHovered
                  ? catColor
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              width: isHovered ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Header Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(catIcon, size: 16, color: catColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        catName,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    // Quick add (+) button
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      color: catColor,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Assign Salesperson to $catName',
                      onPressed: () {
                        _openQuickAssignModal(
                          role: 'Sales',
                          campaignId: campaignId,
                          categoryName: catName,
                          campaignTitle: campaignTitle,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Category Assigned Salespersons List or Empty Drop State
              if (assigned.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.drag_indicator,
                          size: 20,
                          color: isHovered ? catColor : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isHovered ? 'Drop Salesperson here' : 'Drop Salesperson or click +',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isHovered ? FontWeight.bold : FontWeight.normal,
                            color: isHovered ? catColor : (isDark ? Colors.grey.shade500 : Colors.grey.shade500),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                _ScrollableAssignedUserList(
                  assigned: assigned,
                  itemBuilder: (alloc) => _buildAssignedUserTile(
                    allocation: alloc,
                    isDark: isDark,
                    accentColor: const Color(0xFF10B981),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // TELECALLER CAMPAIGN CONNECTION CARD (Drop zone directly on connection)
  // -------------------------------------------------------------
  Widget _buildTelecallerCampaignConnectionCard(Map<String, dynamic> campaign, bool isDark) {
    final campId = (campaign['id'] ?? '').toString();
    final campName = campaign['name']?.toString() ?? campId;
    final provider = campaign['provider']?.toString() ?? '';
    final isConnection = campaign['isConnection'] == true;

    final assigned = _getAssignedAllocations('Telecaller', campId, 'ALL');

    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        _assignUserToCategory(
          role: 'Telecaller',
          campaignId: campId,
          categoryName: 'ALL',
          user: details.data,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered
                  ? const Color(0xFF3B82F6)
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              width: isHovered ? 2.0 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: isHovered
                      ? const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.2 : 0.08)
                      : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.hub_outlined, color: Color(0xFF3B82F6), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            campName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (isConnection)
                                Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'CONNECTION',
                                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
                                  ),
                                ),
                              Text(
                                provider.isNotEmpty ? 'Provider: $provider' : 'Marketing Campaign Connection',
                                style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                        foregroundColor: const Color(0xFF3B82F6),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Assign', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        _openQuickAssignModal(
                          role: 'Telecaller',
                          campaignId: campId,
                          categoryName: 'ALL',
                          campaignTitle: campName,
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Assigned Telecallers or Empty Drop State
              if (assigned.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.drag_indicator,
                          size: 24,
                          color: isHovered ? const Color(0xFF3B82F6) : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isHovered
                              ? 'Drop Telecaller here to assign to $campName'
                              : 'No Telecallers assigned. Drag Telecallers here or click Assign.',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isHovered ? FontWeight.bold : FontWeight.normal,
                            color: isHovered
                                ? const Color(0xFF3B82F6)
                                : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                _ScrollableAssignedUserList(
                  assigned: assigned,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (alloc) => _buildAssignedUserTile(
                    allocation: alloc,
                    isDark: isDark,
                    accentColor: const Color(0xFF3B82F6),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // ASSIGNED USER TILE (WITH INDEPENDENT TOGGLE & REMOVE BUTTON)
  // -------------------------------------------------------------
  Widget _buildAssignedUserTile({
    required Map<String, dynamic> allocation,
    required bool isDark,
    required Color accentColor,
  }) {
    final allocId = allocation['id']?.toString() ?? '';
    final userName = allocation['user_name']?.toString() ?? 'User';

    // Independent campaign category toggle
    final bool isCategoryEnabled = allocation['is_enabled'] != false;
    final bool isPending = _pendingActionIds.contains(allocId);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? (isCategoryEnabled ? const Color(0xFF1E293B) : const Color(0xFF0F172A))
            : (isCategoryEnabled ? Colors.white : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCategoryEnabled
              ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
              : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: isCategoryEnabled
                ? accentColor.withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.2),
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: isCategoryEnabled ? accentColor : Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isCategoryEnabled
                        ? (isDark ? Colors.white : const Color(0xFF0F172A))
                        : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isCategoryEnabled ? 'Receiving Leads' : 'Allocation Paused',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isCategoryEnabled ? accentColor : Colors.red.shade400,
                  ),
                ),
              ],
            ),
          ),
          if (isPending)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            )
          else ...[
            // Independent category-level lead allocation toggle
            Transform.scale(
              scale: 0.75,
              child: Switch(
                value: isCategoryEnabled,
                activeThumbColor: accentColor,
                onChanged: (newVal) => _toggleCategoryAllocation(allocId, newVal),
              ),
            ),
            // Remove button (unassign from this specific category independently)
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Unassign $userName',
              onPressed: () => _deleteCategoryAllocation(allocId, userName),
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // SEARCH FIELD WIDGET
  // -------------------------------------------------------------
  Widget _buildSearchField(bool isDark) {
    return TextField(
      controller: _searchController,
      onChanged: (val) {
        setState(() {
          _searchQuery = val;
        });
      },
      decoration: InputDecoration(
        hintText: 'Search campaigns or connections dynamically...',
        hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              )
            : null,
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
        ),
      ),
    );
  }
}

class _ScrollableAssignedUserList extends StatefulWidget {
  final List<Map<String, dynamic>> assigned;
  final Widget Function(Map<String, dynamic> alloc) itemBuilder;
  final EdgeInsetsGeometry padding;

  const _ScrollableAssignedUserList({
    required this.assigned,
    required this.itemBuilder,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  State<_ScrollableAssignedUserList> createState() => _ScrollableAssignedUserListState();
}

class _ScrollableAssignedUserListState extends State<_ScrollableAssignedUserList> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.assigned.length <= 4) {
      return Padding(
        padding: widget.padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.assigned.map(widget.itemBuilder).toList(),
        ),
      );
    }

    return Padding(
      padding: widget.padding,
      child: SizedBox(
        height: 206, // Fixed height for 4 items so dimensions stay stable
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          radius: const Radius.circular(4),
          thickness: 4,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.only(right: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: widget.assigned.map(widget.itemBuilder).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _StickyPoolHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  final bool isDark;

  _StickyPoolHeaderDelegate({
    required this.child,
    required this.height,
    required this.isDark,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isPinned = shrinkOffset > 2.0;
    return SizedBox.expand(
      child: Container(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: isPinned
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyPoolHeaderDelegate oldDelegate) {
    return true;
  }
}
