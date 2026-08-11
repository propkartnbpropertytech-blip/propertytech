import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_shadows.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'skeletons.dart';

class CRMColumn<T> {
  final String label;
  final Widget Function(T item) cellBuilder;
  final bool sortable;
  final double? width;
  final String sortField;

  const CRMColumn({
    required this.label,
    required this.cellBuilder,
    this.sortable = false,
    this.width,
    this.sortField = '',
  });
}

class CRMDataTable<T> extends StatelessWidget {
  final List<CRMColumn<T>> columns;
  final List<T> items;
  final bool isLoading;
  final String? sortField;
  final bool sortAscending;
  final Function(String field, bool ascending)? onSort;
  final Function(T item)? onRowTap;
  final List<T> selectedItems;
  final Function(List<T> selected)? onSelectionChanged;
  final int currentPage;
  final int totalPages;
  final Function(int page)? onPageChanged;
  final int totalItems;
  final int itemsPerPage;
  final Function(int rows)? onItemsPerPageChanged;

  const CRMDataTable({
    super.key,
    required this.columns,
    required this.items,
    this.isLoading = false,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
    this.onRowTap,
    this.selectedItems = const [],
    this.onSelectionChanged,
    this.currentPage = 1,
    this.totalPages = 1,
    this.onPageChanged,
    this.totalItems = 0,
    this.itemsPerPage = 10,
    this.onItemsPerPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(CRMSpacing.m),
        child: CRMListSkeleton(count: 5),
      );
    }

    final hasSelection = onSelectionChanged != null;

    final startItem = totalItems == 0 ? 0 : (currentPage - 1) * itemsPerPage + 1;
    var endItem = startItem + items.length - 1;
    if (endItem > totalItems) endItem = totalItems;

    return Container(
      decoration: BoxDecoration(
        color: CRMColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(CRMBorderRadius.card),
        border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.55), width: 0.5),
        boxShadow: CRMShadows.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: CRMColors.borderOf(context),
              ),
              child: DataTable(
                showCheckboxColumn: hasSelection,
                headingRowColor: WidgetStateProperty.all(CRMColors.groupedBackground),
                dataRowColor: WidgetStateProperty.all(CRMColors.cardBgOf(context)),
                dataRowMinHeight: 64.0,
                dataRowMaxHeight: 128.0,
                horizontalMargin: CRMSpacing.m,
                columnSpacing: CRMSpacing.l,
                sortColumnIndex: sortField != null
                    ? columns.indexWhere((c) => c.sortField == sortField)
                    : null,
                sortAscending: sortAscending,
                columns: [
                  ...columns.map((c) {
                    return DataColumn(
                      label: Text(
                        c.label,
                        style: CRMTypography.captionBold.copyWith(
                          color: CRMColors.textSecondaryOf(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onSort: c.sortable && onSort != null
                          ? (index, ascending) {
                              onSort!(c.sortField, ascending);
                            }
                          : null,
                    );
                  }),
                ],
                rows: items.map((item) {
                  final isSelected = selectedItems.contains(item);
                  return DataRow(
                    selected: isSelected,
                    onSelectChanged: hasSelection
                        ? (selected) {
                            final updated = List<T>.from(selectedItems);
                            if (selected == true) {
                              updated.add(item);
                            } else {
                              updated.remove(item);
                            }
                            onSelectionChanged!(updated);
                          }
                        : null,
                    cells: columns.map((c) {
                      return DataCell(
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onRowTap != null ? () => onRowTap!(item) : null,
                          child: Container(
                            alignment: Alignment.centerLeft,
                            width: c.width,
                            child: c.cellBuilder(item),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ),
        if (onPageChanged != null)
          Container(
            padding: const EdgeInsets.symmetric(vertical: CRMSpacing.s, horizontal: CRMSpacing.m),
            decoration: BoxDecoration(
              color: CRMColors.cardBgOf(context),
              border: Border(top: BorderSide(color: CRMColors.borderOf(context))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing $startItem–$endItem of $totalItems',
                  style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                ),
                Row(
                  children: [
                    Text(
                      'Rows: ',
                      style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                    ),
                    DropdownButton<int>(
                      value: itemsPerPage,
                      dropdownColor: CRMColors.surfaceElevatedOf(context),
                      underline: const SizedBox.shrink(),
                      icon: const Icon(Icons.arrow_drop_down_rounded, size: 20),
                      style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context)),
                      items: const [
                        DropdownMenuItem(value: 10, child: Text('10')),
                        DropdownMenuItem(value: 25, child: Text('25')),
                        DropdownMenuItem(value: 50, child: Text('50')),
                      ],
                      onChanged: onItemsPerPageChanged != null
                          ? (val) {
                              if (val != null) onItemsPerPageChanged!(val);
                            }
                          : null,
                    ),
                    const SizedBox(width: CRMSpacing.l),
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: currentPage > 1 ? () => onPageChanged!(currentPage - 1) : null,
                    ),
                    const SizedBox(width: CRMSpacing.m),
                    Text(
                      '$currentPage / $totalPages',
                      style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context)),
                    ),
                    const SizedBox(width: CRMSpacing.m),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: currentPage < totalPages ? () => onPageChanged!(currentPage + 1) : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
}
