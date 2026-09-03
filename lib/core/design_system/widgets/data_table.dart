import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_shadows.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'skeletons.dart';
import 'empty_state.dart';

class CRMDataTable extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final bool isLoading;
  final String emptyTitle;
  final String emptyDescription;
  final IconData emptyIcon;
  final bool showCheckboxColumn;
  final double? dataRowMinHeight;
  final double? dataRowMaxHeight;
  final double? columnSpacing;
  final double? horizontalMargin;
  final bool showDecoration;

  const CRMDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.isLoading = false,
    this.emptyTitle = 'No entries found',
    this.emptyDescription = '',
    this.emptyIcon = Icons.folder_open_rounded,
    this.showCheckboxColumn = true,
    this.dataRowMinHeight,
    this.dataRowMaxHeight,
    this.columnSpacing,
    this.horizontalMargin,
    this.showDecoration = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.all(CRMSpacing.m),
        child: Column(
          children: List.generate(5, (index) => const Padding(
            padding: EdgeInsets.only(bottom: CRMSpacing.s),
            child: CRMSkeleton(height: 48),
          )),
        ),
      );
    }

    if (rows.isEmpty) {
      return CRMEmptyState(
        title: emptyTitle,
        description: emptyDescription,
        icon: emptyIcon,
      );
    }

    return Container(
      decoration: showDecoration
          ? BoxDecoration(
              color: CRMColors.cardBgOf(context),
              borderRadius: BorderRadius.circular(CRMBorderRadius.card),
              border: Border.all(color: CRMColors.borderOf(context), width: 1.0),
            )
          : null,
      clipBehavior: showDecoration ? Clip.antiAlias : Clip.none,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double availableWidth = constraints.maxWidth;
          final int colCount = columns.length;
          final double margin = horizontalMargin ?? CRMSpacing.m;
          final double baseContentWidth = colCount * 105.0 + margin * 2;
          
          double spacing = columnSpacing ?? CRMSpacing.m;
          if (columnSpacing == null && colCount > 1) {
            if (availableWidth > baseContentWidth) {
              spacing = (availableWidth - baseContentWidth) / (colCount - 1);
              if (spacing > 20.0) spacing = 20.0;
              if (spacing < 8.0) spacing = 8.0;
            } else {
              spacing = 8.0;
            }
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: availableWidth),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(CRMColors.sidebarBgOf(context)),
                headingTextStyle: CRMTypography.captionBold.copyWith(color: CRMColors.textSecondaryOf(context)),
                dataTextStyle: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
                dataRowMinHeight: dataRowMinHeight ?? 52.0,
                dataRowMaxHeight: dataRowMaxHeight ?? 64.0,
                dividerThickness: 1.0,
                horizontalMargin: margin,
                columnSpacing: spacing,
                columns: columns,
                rows: rows,
                showCheckboxColumn: showCheckboxColumn,
              ),
            ),
          );
        },
      ),
    );
  }
}
