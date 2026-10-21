import 'package:flutter/material.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/cards.dart';

/// Reusable filter bar for search, listing type, configuration, and status.
class RequirementFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String>? onSearchChanged;
  final String activeListingTab;
  final ValueChanged<String> onListingTabChanged;
  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;
  final List<String> statusOptions;
  final VoidCallback? onClearFilters;
  final Widget? trailingActions;

  const RequirementFilterBar({
    super.key,
    required this.searchController,
    this.onSearchChanged,
    required this.activeListingTab,
    required this.onListingTabChanged,
    required this.selectedStatus,
    required this.onStatusChanged,
    this.statusOptions = const [
      'All',
      'Pending',
      'Contacted',
      'Site Visit',
      'Deal Won',
      'Lost',
    ],
    this.onClearFilters,
    this.trailingActions,
  });

  @override
  Widget build(BuildContext context) {
    return CRMCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
                  decoration: InputDecoration(
                    hintText: 'Search by client name, mobile, specs, remarks...',
                    hintStyle: CRMTypography.body.copyWith(
                      color: CRMColors.textSecondaryOf(context),
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: CRMColors.textSecondaryOf(context),
                    ),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              searchController.clear();
                              onSearchChanged?.call('');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: CRMColors.backgroundOf(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: CRMColors.borderOf(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: CRMColors.borderOf(context)),
                    ),
                  ),
                ),
              ),
              if (trailingActions != null) ...[
                const SizedBox(width: 8),
                trailingActions!,
              ],
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Listing Type Segment: Rent / Re-Sale / All
              _buildListingTypeToggle(context),
              // Status Dropdown
              _buildStatusDropdown(context),
              if (onClearFilters != null)
                TextButton.icon(
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                  label: const Text('Reset', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListingTypeToggle(BuildContext context) {
    final tabs = ['All', 'Rent', 'Re-Sale'];
    final primary = CRMColors.primaryOf(context);

    return Container(
      decoration: BoxDecoration(
        color: CRMColors.backgroundOf(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CRMColors.borderOf(context)),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: tabs.map((tab) {
          final isSelected = activeListingTab.toLowerCase() == tab.toLowerCase();
          return InkWell(
            onTap: () => onListingTabChanged(tab),
            borderRadius: BorderRadius.circular(6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                tab,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : CRMColors.textSecondaryOf(context),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusDropdown(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: CRMColors.backgroundOf(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CRMColors.borderOf(context)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: statusOptions.contains(selectedStatus) ? selectedStatus : 'All',
          icon: Icon(Icons.arrow_drop_down, color: CRMColors.textSecondaryOf(context), size: 18),
          style: TextStyle(
            fontSize: 12,
            color: CRMColors.textOf(context),
            fontWeight: FontWeight.w500,
          ),
          onChanged: (val) {
            if (val != null) onStatusChanged(val);
          },
          items: statusOptions.map((s) {
            return DropdownMenuItem<String>(
              value: s,
              child: Text(s),
            );
          }).toList(),
        ),
      ),
    );
  }
}
