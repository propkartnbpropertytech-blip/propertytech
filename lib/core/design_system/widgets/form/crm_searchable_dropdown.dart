import 'package:flutter/material.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';
import '../buttons.dart';

class CRMDropdownItem {
  final String id;
  final String label;

  const CRMDropdownItem({required this.id, required this.label});
}

class CRMSearchableDropdown extends StatefulWidget {
  final String labelText;
  final String? selectedValue;
  final List<CRMDropdownItem> items;
  final ValueChanged<String?> onChanged;
  final VoidCallback? onAddPressed;
  final String? addTooltip;
  final bool isRequired;
  final bool enabled;

  const CRMSearchableDropdown({
    super.key,
    required this.labelText,
    required this.selectedValue,
    required this.items,
    required this.onChanged,
    this.onAddPressed,
    this.addTooltip = 'Add new option',
    this.isRequired = false,
    this.enabled = true,
  });

  @override
  State<CRMSearchableDropdown> createState() => _CRMSearchableDropdownState();
}

class _CRMSearchableDropdownState extends State<CRMSearchableDropdown> {
  void _showSearchDialog() {
    if (!widget.enabled) return;

    final searchController = TextEditingController();
    List<CRMDropdownItem> filteredItems = List.from(widget.items);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: CRMColors.cardBgOf(context),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Select ${widget.labelText}', style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context))),
                if (widget.onAddPressed != null)
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, color: CRMColors.success),
                    onPressed: () {
                      Navigator.pop(ctx);
                      widget.onAddPressed!();
                    },
                    tooltip: widget.addTooltip,
                  ),
              ],
            ),
            content: SizedBox(
              width: 320,
              height: 400,
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    style: TextStyle(color: CRMColors.textOf(context)),
                    decoration: InputDecoration(
                      hintText: 'Type to search...',
                      hintStyle: TextStyle(color: CRMColors.textMutedOf(context)),
                      prefixIcon: const Icon(Icons.search_rounded),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                    ),
                    onChanged: (val) {
                      setState(() {
                        filteredItems = widget.items
                            .where((item) => item.label.toLowerCase().contains(val.toLowerCase()))
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: CRMSpacing.m),
                  Expanded(
                    child: filteredItems.isEmpty
                        ? Center(
                            child: Text(
                              'No matching results found.',
                              style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context)),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              final isSelected = item.id == widget.selectedValue;
                              return ListTile(
                                tileColor: isSelected ? CRMColors.primaryOf(context).withOpacity(0.08) : null,
                                title: Text(
                                  item.label,
                                  style: CRMTypography.body.copyWith(
                                    color: isSelected ? CRMColors.primaryOf(context) : CRMColors.textOf(context),
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                trailing: isSelected ? const Icon(Icons.check_rounded, color: CRMColors.success) : null,
                                onTap: () {
                                  widget.onChanged(item.id);
                                  Navigator.pop(ctx);
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedItem = widget.items.firstWhere(
      (item) => item.id == widget.selectedValue,
      orElse: () => const CRMDropdownItem(id: '', label: ''),
    );

    final displayLabel = selectedItem.id.isNotEmpty ? selectedItem.label : 'Select Option';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.labelText}${widget.isRequired ? " *" : ""}',
          style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondaryOf(context)),
        ),
        const SizedBox(height: CRMSpacing.xs),
        InkWell(
          onTap: widget.enabled ? _showSearchDialog : null,
          borderRadius: BorderRadius.circular(CRMBorderRadius.s),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: CRMSpacing.m,
              vertical: CRMSpacing.s + 4,
            ),
            decoration: BoxDecoration(
              color: widget.enabled ? CRMColors.cardBgOf(context) : CRMColors.background,
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              border: Border.all(color: CRMColors.borderOf(context), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    displayLabel,
                    style: CRMTypography.body.copyWith(
                      color: selectedItem.id.isNotEmpty
                          ? CRMColors.textOf(context)
                          : CRMColors.textMutedOf(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  color: CRMColors.textMutedOf(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
