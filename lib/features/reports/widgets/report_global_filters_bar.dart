import 'package:flutter/material.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/theme/theme_manager.dart';
import '../../users/models/user_model.dart';
import '../../properties/models/property_model.dart';
import '../models/report_filter_state.dart';

class ReportGlobalFiltersBar extends StatelessWidget {
  final ReportFilterState filters;
  final List<String> availableStatuses;
  final List<String> availableSources;
  final List<UserModel> telecallers;
  final List<UserModel> salesUsers;
  final List<PropertyModel> properties;
  final ValueChanged<ReportFilterState> onFiltersChanged;
  final VoidCallback onResetFilters;

  const ReportGlobalFiltersBar({
    super.key,
    required this.filters,
    required this.availableStatuses,
    required this.availableSources,
    required this.telecallers,
    required this.salesUsers,
    required this.properties,
    required this.onFiltersChanged,
    required this.onResetFilters,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = CRMColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Filter modal button
              InkWell(
                onTap: () => _openFilterModal(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: filters.hasActiveFilters
                        ? primaryColor.withValues(alpha: isDark ? 0.25 : 0.12)
                        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: filters.hasActiveFilters ? primaryColor : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.filter_list_rounded,
                        size: 16,
                        color: filters.hasActiveFilters ? primaryColor : (isDark ? Colors.white70 : Colors.black87),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: filters.hasActiveFilters ? primaryColor : (isDark ? Colors.white : const Color(0xFF14213D)),
                        ),
                      ),
                      if (filters.hasActiveFilters) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            filters.activeFiltersCount.toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Reset All Filters Button (if active)
              if (filters.hasActiveFilters)
                TextButton.icon(
                  onPressed: onResetFilters,
                  icon: const Icon(Icons.clear_all_rounded, size: 16, color: Color(0xFFDC2626)),
                  label: const Text(
                    'Clear All',
                    style: TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),

              const SizedBox(width: 8),

              // Active filter chips scroll
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (filters.leadStatus != null)
                        _buildFilterChip('Status: ${filters.leadStatus}', () {
                          onFiltersChanged(filters.copyWith(clearLeadStatus: true));
                        }),
                      if (filters.leadSource != null)
                        _buildFilterChip('Source: ${filters.leadSource}', () {
                          onFiltersChanged(filters.copyWith(clearLeadSource: true));
                        }),
                      if (filters.telecallerName != null)
                        _buildFilterChip('Telecaller: ${filters.telecallerName}', () {
                          onFiltersChanged(filters.copyWith(clearTelecaller: true));
                        }),
                      if (filters.salesUserName != null)
                        _buildFilterChip('Sales: ${filters.salesUserName}', () {
                          onFiltersChanged(filters.copyWith(clearSalesUser: true));
                        }),
                      if (filters.propertyName != null)
                        _buildFilterChip('Property: ${filters.propertyName}', () {
                          onFiltersChanged(filters.copyWith(clearProperty: true));
                        }),
                      if (filters.leadType != null)
                        _buildFilterChip('Type: ${filters.leadType}', () {
                          onFiltersChanged(filters.copyWith(clearLeadType: true));
                        }),
                      if (filters.locationName != null)
                        _buildFilterChip('Location: ${filters.locationName}', () {
                          onFiltersChanged(filters.copyWith(clearLocation: true));
                        }),
                      if (filters.campaign != null)
                        _buildFilterChip('Campaign: ${filters.campaign}', () {
                          onFiltersChanged(filters.copyWith(clearCampaign: true));
                        }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        deleteIcon: const Icon(Icons.close, size: 13),
        onDeleted: onRemove,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  void _openFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ReportFilterSheet(
        initialFilters: filters,
        availableStatuses: availableStatuses,
        availableSources: availableSources,
        telecallers: telecallers,
        salesUsers: salesUsers,
        properties: properties,
        onApply: (updated) {
          Navigator.of(sheetContext).pop();
          onFiltersChanged(updated);
        },
        onReset: () {
          Navigator.of(sheetContext).pop();
          onResetFilters();
        },
      ),
    );
  }
}

class _ReportFilterSheet extends StatefulWidget {
  final ReportFilterState initialFilters;
  final List<String> availableStatuses;
  final List<String> availableSources;
  final List<UserModel> telecallers;
  final List<UserModel> salesUsers;
  final List<PropertyModel> properties;
  final ValueChanged<ReportFilterState> onApply;
  final VoidCallback onReset;

  const _ReportFilterSheet({
    required this.initialFilters,
    required this.availableStatuses,
    required this.availableSources,
    required this.telecallers,
    required this.salesUsers,
    required this.properties,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_ReportFilterSheet> createState() => _ReportFilterSheetState();
}

class _ReportFilterSheetState extends State<_ReportFilterSheet> {
  late ReportFilterState _current;
  final TextEditingController _campaignController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _current = widget.initialFilters;
    _campaignController.text = _current.campaign ?? '';
    _locationController.text = _current.locationName ?? '';
  }

  @override
  void dispose() {
    _campaignController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = CRMColors.primary;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        maxWidth: 600,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Global Report Filters',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable Filter Fields
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Status Dropdown
                  _buildDropdownSection(
                    title: 'Lead Status',
                    value: _current.leadStatus,
                    items: widget.availableStatuses,
                    onChanged: (val) => setState(() => _current = _current.copyWith(leadStatus: val, clearLeadStatus: val == null)),
                  ),
                  const SizedBox(height: 16),

                  // 2. Lead Source Dropdown
                  _buildDropdownSection(
                    title: 'Lead Source',
                    value: _current.leadSource,
                    items: widget.availableSources.isNotEmpty
                        ? widget.availableSources
                        : ['Website', 'Facebook Ads', 'Instagram', '99Acres', 'MagicBricks', 'Referral', 'WhatsApp', 'Direct'],
                    onChanged: (val) => setState(() => _current = _current.copyWith(leadSource: val, clearLeadSource: val == null)),
                  ),
                  const SizedBox(height: 16),

                  // 3. Telecaller Dropdown
                  _buildUserDropdownSection(
                    title: 'Telecaller',
                    selectedId: _current.telecallerId,
                    users: widget.telecallers,
                    onChanged: (user) {
                      setState(() {
                        if (user == null) {
                          _current = _current.copyWith(clearTelecaller: true);
                        } else {
                          _current = _current.copyWith(
                            telecallerId: user.id,
                            telecallerName: user.fullName,
                          );
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // 4. Sales User Dropdown
                  _buildUserDropdownSection(
                    title: 'Sales User',
                    selectedId: _current.salesUserId,
                    users: widget.salesUsers,
                    onChanged: (user) {
                      setState(() {
                        if (user == null) {
                          _current = _current.copyWith(clearSalesUser: true);
                        } else {
                          _current = _current.copyWith(
                            salesUserId: user.id,
                            salesUserName: user.fullName,
                          );
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // 5. Property / Project Dropdown
                  _buildPropertyDropdownSection(),
                  const SizedBox(height: 16),

                  // 6. Lead Type (Rent / Sale)
                  _buildDropdownSection(
                    title: 'Lead Type',
                    value: _current.leadType,
                    items: const ['Rent', 'Sale', 'Commercial', 'Residential'],
                    onChanged: (val) => setState(() => _current = _current.copyWith(leadType: val, clearLeadType: val == null)),
                  ),
                  const SizedBox(height: 16),

                  // 7. Location (Area / City)
                  const Text('Location (Area / City)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      hintText: 'Filter by city or area name...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (val) => _current = _current.copyWith(locationName: val.trim().isEmpty ? null : val.trim(), clearLocation: val.trim().isEmpty),
                  ),
                  const SizedBox(height: 16),

                  // 8. Campaign
                  const Text('Campaign', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _campaignController,
                    decoration: const InputDecoration(
                      hintText: 'Filter by campaign name / keyword...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (val) => _current = _current.copyWith(campaign: val.trim().isEmpty ? null : val.trim(), clearCampaign: val.trim().isEmpty),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: widget.onReset,
                  child: const Text('Reset All Filters', style: TextStyle(color: Color(0xFFDC2626))),
                ),
                ElevatedButton(
                  onPressed: () => widget.onApply(_current),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSection({
    required String title,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: items.contains(value) ? value : null,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          hint: Text('All $title'),
          isExpanded: true,
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text('All ${title}s'),
            ),
            ...items.map(
              (it) => DropdownMenuItem<String>(
                value: it,
                child: Text(it),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildUserDropdownSection({
    required String title,
    required String? selectedId,
    required List<UserModel> users,
    required ValueChanged<UserModel?> onChanged,
  }) {
    final selectedUser = users.where((u) => u.id == selectedId).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        DropdownButtonFormField<UserModel>(
          initialValue: selectedUser,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          hint: Text('All ${title}s'),
          isExpanded: true,
          items: [
            DropdownMenuItem<UserModel>(
              value: null,
              child: Text('All ${title}s'),
            ),
            ...users.map(
              (u) => DropdownMenuItem<UserModel>(
                value: u,
                child: Text(u.fullName.isNotEmpty ? u.fullName : u.email),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildPropertyDropdownSection() {
    final selectedProp = widget.properties.where((p) => p.id == _current.propertyId).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Project / Property', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        DropdownButtonFormField<PropertyModel>(
          initialValue: selectedProp,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          hint: const Text('All Properties'),
          isExpanded: true,
          items: [
            const DropdownMenuItem<PropertyModel>(
              value: null,
              child: Text('All Properties'),
            ),
            ...widget.properties.take(20).map(
              (p) => DropdownMenuItem<PropertyModel>(
                value: p,
                child: Text('${p.title.isNotEmpty ? p.title : 'Property'} (${p.propertyCode})'),
              ),
            ),
          ],
          onChanged: (prop) {
            setState(() {
              if (prop == null) {
                _current = _current.copyWith(clearProperty: true);
              } else {
                _current = _current.copyWith(
                  propertyId: prop.id,
                  propertyName: prop.title,
                );
              }
            });
          },
        ),
      ],
    );
  }
}
