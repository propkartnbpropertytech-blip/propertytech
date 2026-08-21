import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'buttons.dart';

void showCRMFilterDrawer({
  required BuildContext context,
  required Widget Function(BuildContext context, StateSetter setDrawerState) builder,
  required VoidCallback onApply,
  required VoidCallback onClear,
  String title = 'Filter Mappings',
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Filter Drawer barrier',
    barrierColor: Colors.black.withOpacity(0.3),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, anim1, anim2) {
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 400,
            height: double.infinity,
            decoration: BoxDecoration(
              color: CRMColors.cardBgOf(context),
              border: Border(left: BorderSide(color: CRMColors.borderOf(context), width: 1.5)),
            ),
            child: SafeArea(
              child: StatefulBuilder(
                builder: (context, setDrawerState) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(CRMSpacing.m),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              title,
                              style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context)),
                            ),
                            IconButton(
                              icon: Icon(Icons.close_rounded, color: CRMColors.textSecondaryOf(context)),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      Divider(color: CRMColors.borderOf(context), height: 1),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(CRMSpacing.m),
                          child: builder(context, setDrawerState),
                        ),
                      ),
                      Divider(color: CRMColors.borderOf(context), height: 1),
                      Padding(
                        padding: const EdgeInsets.all(CRMSpacing.m),
                        child: Row(
                          children: [
                            Expanded(
                              child: CRMButton(
                                label: 'Clear All',
                                variant: CRMButtonVariant.outline,
                                onPressed: () {
                                  onClear();
                                  setDrawerState(() {});
                                },
                              ),
                            ),
                            const SizedBox(width: CRMSpacing.s),
                            Expanded(
                              child: CRMButton(
                                label: 'Apply Filters',
                                variant: CRMButtonVariant.primary,
                                onPressed: () {
                                  onApply();
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, anim1, anim2, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(anim1),
        child: child,
      );
    },
  );
}
