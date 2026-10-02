import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'mobile_layout.dart';
import 'mobile_touch.dart';

ShapeBorder _sheetShape() => const RoundedRectangleBorder(
  borderRadius: BorderRadius.vertical(
    top: Radius.circular(CRMBorderRadius.sheet),
  ),
);

/// Standard bottom sheet: grabber, title, close (48), scrollable body,
/// optional sticky actions, safe area, and keyboard insets.
class MobileSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget> actions;

  const MobileSheet({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
  });

  /// Opens a sheet capped at [maxHeightFactor] of the screen height.
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget child,
    List<Widget> actions = const [],
    double maxHeightFactor = 0.85,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      backgroundColor: CRMColors.surfaceOf(context),
      shape: _sheetShape(),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * maxHeightFactor,
      ),
      builder: (_) => MobileSheet(title: title, actions: actions, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: CRMSpacing.xs),
          ExcludeSemantics(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: CRMColors.borderOf(context),
                borderRadius: BorderRadius.circular(CRMBorderRadius.round),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: CRMSpacing.m),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: CRMTypography.sectionTitle.copyWith(
                        color: CRMColors.textOf(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                MobileIconAction(
                  icon: Icons.close_rounded,
                  label: 'Close',
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m),
              child: child,
            ),
          ),
          if (actions.isNotEmpty)
            Container(
              padding: EdgeInsets.fromLTRB(
                CRMSpacing.m,
                CRMSpacing.s,
                CRMSpacing.m,
                CRMSpacing.s + (keyboard > 0 ? 0 : bottomSafe),
              ),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: CRMColors.borderOf(context)),
                ),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: CRMSpacing.s),
                    Expanded(child: actions[i]),
                  ],
                ],
              ),
            )
          else
            SizedBox(height: CRMSpacing.m + bottomSafe),
        ],
      ),
    );
  }
}

/// One selectable option for filter and sort sheets.
@immutable
class MobileOption {
  final String value;
  final String label;

  const MobileOption({required this.value, required this.label});
}

/// A group of options inside [MobileFilterSheet]. Definitions are supplied by
/// each screen; this component does not know any business filter.
@immutable
class MobileFilterSection {
  final String id;
  final String title;
  final List<MobileOption> options;
  final bool multiSelect;

  const MobileFilterSection({
    required this.id,
    required this.title,
    required this.options,
    this.multiSelect = true,
  });
}

/// Generic filter sheet with Reset and Apply. Returns the selected values per
/// section id on Apply, or null when dismissed without applying.
class MobileFilterSheet extends StatefulWidget {
  final String title;
  final List<MobileFilterSection> sections;
  final Map<String, Set<String>> initialSelection;

  const MobileFilterSheet({
    super.key,
    this.title = 'Filters',
    required this.sections,
    this.initialSelection = const {},
  });

  static Future<Map<String, Set<String>>?> show(
    BuildContext context, {
    String title = 'Filters',
    required List<MobileFilterSection> sections,
    Map<String, Set<String>> initialSelection = const {},
  }) {
    return showModalBottomSheet<Map<String, Set<String>>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: CRMColors.surfaceOf(context),
      shape: _sheetShape(),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      builder: (_) => MobileFilterSheet(
        title: title,
        sections: sections,
        initialSelection: initialSelection,
      ),
    );
  }

  @override
  State<MobileFilterSheet> createState() => _MobileFilterSheetState();
}

class _MobileFilterSheetState extends State<MobileFilterSheet> {
  late Map<String, Set<String>> _selection;

  @override
  void initState() {
    super.initState();
    _selection = {
      for (final s in widget.sections)
        s.id: {...?widget.initialSelection[s.id]},
    };
  }

  void _toggle(MobileFilterSection section, String value) {
    setState(() {
      final current = _selection[section.id]!;
      if (current.contains(value)) {
        current.remove(value);
      } else {
        if (!section.multiSelect) current.clear();
        current.add(value);
      }
    });
  }

  void _reset() {
    setState(() {
      for (final set in _selection.values) {
        set.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const buttonSize = Size.fromHeight(MobileLayout.minTouchTarget);
    return MobileSheet(
      title: widget.title,
      actions: [
        OutlinedButton(
          onPressed: _reset,
          style: OutlinedButton.styleFrom(minimumSize: buttonSize),
          child: const Text('Reset'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selection),
          style: FilledButton.styleFrom(minimumSize: buttonSize),
          child: const Text('Apply'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final section in widget.sections) ...[
            Padding(
              padding: const EdgeInsets.only(
                top: CRMSpacing.s,
                bottom: CRMSpacing.xs,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  section.title,
                  style: CRMTypography.cardTitle.copyWith(
                    color: CRMColors.textOf(context),
                  ),
                ),
              ),
            ),
            Wrap(
              spacing: CRMSpacing.xs,
              runSpacing: CRMSpacing.xs,
              children: [
                for (final option in section.options)
                  FilterChip(
                    label: Text(option.label),
                    selected: _selection[section.id]!.contains(option.value),
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    onSelected: (_) => _toggle(section, option.value),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Generic sort sheet. Choosing an option applies it immediately and returns
/// its value; Reset (shown when [resetValue] is given) returns [resetValue];
/// dismissing returns null. Options and the default come from the caller.
class MobileSortSheet {
  MobileSortSheet._();

  static Future<String?> show(
    BuildContext context, {
    String title = 'Sort',
    required List<MobileOption> options,
    String? selected,
    String? resetValue,
  }) {
    return MobileSheet.show<String>(
      context,
      title: title,
      maxHeightFactor: 0.5,
      actions: [
        if (resetValue != null)
          Builder(
            builder: (sheetContext) => OutlinedButton(
              onPressed: () => Navigator.of(sheetContext).pop(resetValue),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(MobileLayout.minTouchTarget),
              ),
              child: const Text('Reset'),
            ),
          ),
      ],
      child: MobileSortOptions(options: options, selected: selected),
    );
  }
}

/// Radio list used by [MobileSortSheet]; pops with the chosen value.
class MobileSortOptions extends StatelessWidget {
  final List<MobileOption> options;
  final String? selected;

  const MobileSortOptions({
    super.key,
    required this.options,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return RadioGroup<String>(
      groupValue: selected,
      onChanged: (value) => Navigator.of(context).pop(value),
      child: Column(
        children: [
          for (final option in options)
            RadioListTile<String>(
              value: option.value,
              title: Text(option.label),
              contentPadding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}

/// Blocking confirmation for destructive, critical, or irreversible actions.
/// The title must name the object being affected.
class MobileConfirmDialog {
  MobileConfirmDialog._();

  static Future<bool> show(
    BuildContext context, {
    required String title,
    String? message,
    required String confirmLabel,
    String cancelLabel = 'Cancel',
    bool destructive = false,
  }) async {
    const minSize = Size(
      MobileLayout.minTouchTarget,
      MobileLayout.minTouchTarget,
    );
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: !destructive,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: message == null ? null : Text(message),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(minimumSize: minSize),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              minimumSize: minSize,
              backgroundColor: destructive ? CRMColors.danger : null,
              foregroundColor: destructive
                  ? CRMColors.onStrongOf(dialogContext)
                  : null,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
