import 'package:flutter/material.dart';

import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';

class AiSearchChipData {
  final String keyName;
  final String label;

  const AiSearchChipData(this.keyName, this.label);
}

class AiSearchRowData {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const AiSearchRowData({required this.title, required this.subtitle, required this.onTap});
}

class AiSearchGroupData {
  final String title;
  final String category;
  final int total;
  final List<AiSearchRowData> rows;

  const AiSearchGroupData({
    required this.title,
    required this.category,
    required this.total,
    required this.rows,
  });
}

class AiSearchPanel extends StatelessWidget {
  final String query;
  final bool loading;
  final bool failed;
  final bool offline;
  final bool stale;
  final bool uncertain;
  final List<AiSearchChipData> chips;
  final List<AiSearchGroupData> groups;
  final ValueChanged<String>? onExample;
  final ValueChanged<String>? onRemoveChip;
  final ValueChanged<String>? onMore;
  final VoidCallback? onClose;

  const AiSearchPanel({
    super.key,
    required this.query,
    this.loading = false,
    this.failed = false,
    this.offline = false,
    this.stale = false,
    this.uncertain = false,
    this.chips = const [],
    this.groups = const [],
    this.onExample,
    this.onRemoveChip,
    this.onMore,
    this.onClose,
  });

  static const examples = [
    '2 BHK rentals in Satellite under ₹35,000',
    'My leads with overdue follow-ups',
    'Available property in Gota',
  ];

  @override
  Widget build(BuildContext context) {
    final trimmed = query.trim();
    final hasRows = groups.any((group) => group.rows.isNotEmpty);
    final border = CRMColors.borderOf(context);
    return Material(
      elevation: 2,
      color: CRMColors.cardBgOf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CRMBorderRadius.input),
        side: BorderSide(color: border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 480),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: CRMSpacing.s),
          children: [
            Row(
              children: [
                const SizedBox(width: CRMSpacing.m),
                Expanded(
                  child: Text(
                    'Suggestions',
                    style: TextStyle(
                      color: CRMColors.textSecondaryOf(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('ai-search-close'),
                  onPressed: onClose,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded, size: 18, semanticLabel: 'Close'),
                ),
              ],
            ),
            if (stale) const _Banner('Showing the last saved results. This search did not complete.'),
            if (uncertain && chips.isNotEmpty)
              const _Banner('Check these filters. You can remove one and search again.'),
            if (chips.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final chip in chips)
                      InputChip(
                        label: Text(chip.label),
                        deleteIcon: const Icon(Icons.close_rounded, size: 16),
                        deleteButtonTooltipMessage: '',
                        onDeleted: onRemoveChip == null ? null : () => onRemoveChip!(chip.keyName),
                      ),
                  ],
                ),
              ),
            if (loading)
              const Padding(
                padding: EdgeInsets.all(CRMSpacing.m),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Searching…'),
                  ],
                ),
              )
            else if (trimmed.isEmpty)
              _examples()
            else if (failed && !hasRows)
              Padding(
                padding: const EdgeInsets.all(CRMSpacing.m),
                child: Text(
                  offline ? 'You are offline. Search will use saved results when they exist.' : 'Search could not finish. Try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: CRMColors.textSecondaryOf(context)),
                ),
              )
            else if (!hasRows)
              Padding(
                padding: const EdgeInsets.all(CRMSpacing.m),
                child: Text(
                  'No matches for this search.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: CRMColors.textSecondaryOf(context)),
                ),
              )
            else
              for (final group in groups)
                if (group.rows.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(CRMSpacing.m, CRMSpacing.s, CRMSpacing.m, 4),
                    child: Text(
                      '${group.title.toUpperCase()} · ${group.total}',
                      style: TextStyle(color: CRMColors.primaryOf(context), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.1),
                    ),
                  ),
                  for (final row in group.rows)
                    ListTile(
                      dense: true,
                      title: Text(row.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(row.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: row.onTap,
                    ),
                  if (group.total > group.rows.length)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: onMore == null ? null : () => onMore!(group.category),
                        child: Text('View more ${group.title.toLowerCase()}'),
                      ),
                    ),
                ],
          ],
        ),
      ),
    );
  }

  Widget _examples() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: CRMSpacing.s, vertical: 4),
            child: Text('Try asking'),
          ),
          for (final example in examples)
            ListTile(
              dense: true,
              leading: const Icon(Icons.auto_awesome_outlined, size: 18),
              title: Text(example),
              onTap: onExample == null ? null : () => onExample!(example),
            ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final String text;

  const _Banner(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(CRMSpacing.m, 4, CRMSpacing.m, 8),
      child: Text(text, style: TextStyle(color: CRMColors.textSecondaryOf(context), fontSize: 12)),
    );
  }
}
