import 'package:flutter/material.dart';

import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../ai_search_suggestions.dart';

class AiSearchChipData {
  final String keyName;
  final String label;

  const AiSearchChipData(this.keyName, this.label);
}

class AiSearchRowData {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  /// Short label shown next to the row, for example the Recycle Bin marker.
  final String? badge;
  final Color badgeColor;

  const AiSearchRowData({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.badgeColor = CRMColors.danger,
  });
}

class AiSearchGroupData {
  final String title;
  final String category;
  final int total;
  final List<AiSearchRowData> rows;
  final IconData icon;
  /// False for groups the search API cannot page, such as the Recycle Bin.
  final bool canLoadMore;

  const AiSearchGroupData({
    required this.title,
    required this.category,
    required this.total,
    required this.rows,
    this.icon = Icons.search_rounded,
    this.canLoadMore = true,
  });
}

/// The AI colours, shared by the field and the panel.
class AiSearchTheme {
  AiSearchTheme._();

  static Color accent(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E);

  static Color violet(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFFA5B4FC) : const Color(0xFF6366F1);

  static LinearGradient gradient(BuildContext context) => LinearGradient(
        colors: [accent(context), violet(context)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );
}

/// A text suggestion row: what it fills in and where it came from.
class AiSuggestionEntry {
  final String text;
  final String kind;
  final AiRecentSearch? recent;

  const AiSuggestionEntry(this.text, this.kind, {this.recent});
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

  /// True after the search was submitted: the panel shows full grouped results.
  final bool resultsMode;
  final bool suggestLoading;
  final List<AiRecentSearch> recent;
  final List<AiPopularSearch> popular;
  final List<AiPageSuggestion> pages;
  final List<AiCompletion> completions;
  final int highlight;
  final ValueChanged<AiSuggestionEntry>? onSuggestion;
  final ValueChanged<AiRecentSearch>? onRemoveRecent;
  final VoidCallback? onViewAllHistory;
  final ValueChanged<AiPageSuggestion>? onPage;
  final VoidCallback? onSeeAll;
  final VoidCallback? onOpenFiltered;
  final String? openFilteredLabel;

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
    this.resultsMode = true,
    this.suggestLoading = false,
    this.recent = const [],
    this.popular = const [],
    this.pages = const [],
    this.completions = const [],
    this.highlight = -1,
    this.onSuggestion,
    this.onRemoveRecent,
    this.onViewAllHistory,
    this.onPage,
    this.onSeeAll,
    this.onOpenFiltered,
    this.openFilteredLabel,
  });

  static const examples = [
    '2 BHK rentals in Satellite under ₹35,000',
    'My leads with overdue follow-ups',
    'Available property in Gota',
  ];

  /// Keyboard order of the text suggestions, the same order the panel draws them.
  static List<AiSuggestionEntry> suggestionEntries({
    required String query,
    List<AiRecentSearch> recent = const [],
    List<AiPopularSearch> popular = const [],
    List<AiCompletion> completions = const [],
  }) {
    final seen = <String>{};
    final entries = <AiSuggestionEntry>[];
    void add(String text, String kind, {AiRecentSearch? item}) {
      final key = text.trim().toLowerCase();
      if (key.isEmpty || !seen.add(key)) return;
      entries.add(AiSuggestionEntry(text, kind, recent: item));
    }

    for (final item in recent) {
      add(item.query, 'recent', item: item);
    }
    if (query.trim().isNotEmpty) {
      for (final item in completions) {
        add(item.text, 'completion');
      }
    }
    for (final item in popular) {
      add(item.query, 'popular');
    }
    if (query.trim().isEmpty && entries.isEmpty) {
      for (final example in examples) {
        add(example, 'example');
      }
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    try {
    final trimmed = query.trim();
    final border = CRMColors.borderOf(context);
    final children = <Widget>[
      _header(context, trimmed),
      if (suggestLoading || (loading && !resultsMode)) _progress(context) else const SizedBox(height: 2),
      if (stale) const _Banner('Showing the last saved results. This search did not complete.'),
      if (uncertain && chips.isNotEmpty) const _Banner('Check these filters. You can remove one and search again.'),
      if (chips.isNotEmpty) _chipsRow(context),
      ..._body(context, trimmed),
    ];
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, (1 - value) * -6), child: child),
      ),
      child: Material(
        elevation: 6,
        shadowColor: AiSearchTheme.accent(context).withValues(alpha: 0.25),
        color: CRMColors.cardBgOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CRMBorderRadius.input),
          side: BorderSide(color: border),
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 520),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: CRMSpacing.s),
            children: children,
          ),
        ),
      ),
    );
    } catch (e, st) {
      debugPrint('⚠️ Error in AiSearchPanel.build: $e\n$st');
      return const SizedBox.shrink();
    }
  }

  List<Widget> _body(BuildContext context, String trimmed) {
    if (resultsMode) {
      final hasRows = groups.any((group) => group.rows.isNotEmpty);
      if (loading) {
        return [
          const Padding(
            padding: EdgeInsets.all(CRMSpacing.m),
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 8),
                Text('Searching…'),
              ],
            ),
          ),
        ];
      }
      if (trimmed.isEmpty) return _idle(context);
      if (failed && !hasRows) {
        return [
          _message(
            context,
            offline ? 'You are offline. Search will use saved results when they exist.' : 'Search could not finish. Try again.',
          ),
        ];
      }
      if (!hasRows) {
        return [
          _message(context, 'No matches for this search.'),
          if (onOpenFiltered != null) _openFiltered(context),
        ];
      }
      return [..._groups(context), if (onOpenFiltered != null) _openFiltered(context)];
    }
    if (trimmed.isEmpty) return _idle(context);
    return _typing(context, trimmed);
  }

  Widget _header(BuildContext context, String trimmed) {
    final title = trimmed.isEmpty ? 'Suggestions' : (resultsMode ? 'Results' : 'Suggestions');
    return Padding(
      padding: const EdgeInsets.fromLTRB(CRMSpacing.m, 6, 4, 0),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (rect) => AiSearchTheme.gradient(context).createShader(rect),
            child: const Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
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
    );
  }

  Widget _progress(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          minHeight: 2,
          color: AiSearchTheme.violet(context),
          backgroundColor: AiSearchTheme.accent(context).withValues(alpha: 0.15),
        ),
      ),
    );
  }

  Widget _chipsRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(CRMSpacing.m, 6, CRMSpacing.m, 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Understood:',
            style: TextStyle(color: CRMColors.textSecondaryOf(context), fontSize: 11, fontWeight: FontWeight.w600),
          ),
          for (final chip in chips)
            InputChip(
              label: Text(chip.label),
              labelStyle: TextStyle(fontSize: 12, color: AiSearchTheme.accent(context), fontWeight: FontWeight.w600),
              backgroundColor: AiSearchTheme.accent(context).withValues(alpha: 0.08),
              side: BorderSide(color: AiSearchTheme.accent(context).withValues(alpha: 0.3)),
              visualDensity: VisualDensity.compact,
              deleteIcon: const Icon(Icons.close_rounded, size: 16),
              deleteButtonTooltipMessage: '',
              onDeleted: onRemoveChip == null ? null : () => onRemoveChip!(chip.keyName),
            ),
        ],
      ),
    );
  }

  List<Widget> _idle(BuildContext context) {
    final widgets = <Widget>[];
    var index = 0;
    if (recent.isNotEmpty) {
      widgets.add(_section(context, 'Recent searches', Icons.history_rounded));
      for (final item in recent) {
        widgets.add(_suggestionTile(
          context,
          AiSuggestionEntry(item.query, 'recent', recent: item),
          selected: highlight == index++,
          query: '',
        ));
      }
      if (onViewAllHistory != null) {
        widgets.add(Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: CRMSpacing.s),
            child: TextButton.icon(
              key: const ValueKey('ai-search-view-all'),
              onPressed: onViewAllHistory,
              icon: const Icon(Icons.manage_history_rounded, size: 16),
              label: const Text('View all searches'),
            ),
          ),
        ));
      }
    }
    final popularEntries = popular.where((item) => !recent.any((r) => r.query.toLowerCase() == item.query.toLowerCase())).toList();
    if (popularEntries.isNotEmpty) {
      widgets.add(_section(context, 'Popular in your team', Icons.trending_up_rounded));
      for (final item in popularEntries) {
        widgets.add(_suggestionTile(context, AiSuggestionEntry(item.query, 'popular'), selected: highlight == index++, query: ''));
      }
    }
    widgets.add(_section(context, 'Try asking', Icons.auto_awesome_outlined));
    final examplesHighlighted = recent.isEmpty && popularEntries.isEmpty;
    for (final example in examples) {
      final selected = examplesHighlighted && highlight == index++;
      widgets.add(ListTile(
        dense: true,
        selected: selected,
        selectedTileColor: AiSearchTheme.accent(context).withValues(alpha: 0.08),
        leading: Icon(Icons.auto_awesome_outlined, size: 18, color: AiSearchTheme.violet(context)),
        title: Text(example),
        onTap: onExample == null ? null : () => onExample!(example),
      ));
    }
    return widgets;
  }

  List<Widget> _typing(BuildContext context, String trimmed) {
    final widgets = <Widget>[];
    final entries = suggestionEntries(query: trimmed, recent: recent, popular: popular, completions: completions);
    for (var i = 0; i < entries.length; i++) {
      widgets.add(_suggestionTile(context, entries[i], selected: highlight == i, query: trimmed));
    }
    if (pages.isNotEmpty) {
      widgets.add(_section(context, 'Go to', Icons.open_in_new_rounded));
      for (final page in pages) {
        widgets.add(ListTile(
          dense: true,
          leading: _iconBadge(context, _pageIcon(page.icon)),
          title: _highlighted(context, page.label, trimmed),
          trailing: Icon(Icons.arrow_forward_rounded, size: 16, color: CRMColors.textSecondaryOf(context)),
          onTap: onPage == null ? null : () => onPage!(page),
        ));
      }
    }
    final hasRows = groups.any((group) => group.rows.isNotEmpty);
    if (hasRows) widgets.addAll(_groups(context));
    final anything = entries.isNotEmpty || pages.isNotEmpty || hasRows;
    if (!anything && !suggestLoading) {
      widgets.add(failed
          ? _message(context, offline ? 'You are offline. Search will use saved results when they exist.' : 'Search could not finish. Try again.')
          : _message(context, 'No matches for this search.'));
    }
    if (onSeeAll != null) widgets.add(_seeAll(context, trimmed));
    if (onOpenFiltered != null) widgets.add(_openFiltered(context));
    return widgets;
  }

  List<Widget> _groups(BuildContext context) {
    return [
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
              leading: _iconBadge(context, group.icon),
              title: _highlighted(context, row.title, resultsMode ? '' : query.trim(), maxLines: 1),
              subtitle: Text(row.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: row.badge == null
                  ? Icon(Icons.chevron_right_rounded, size: 18, color: CRMColors.textSecondaryOf(context))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _badge(context, row.badge!, row.badgeColor),
                        Icon(Icons.chevron_right_rounded, size: 18, color: CRMColors.textSecondaryOf(context)),
                      ],
                    ),
              onTap: row.onTap,
            ),
          if (group.canLoadMore && group.total > group.rows.length)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: CRMSpacing.s),
                child: TextButton(
                  onPressed: onMore == null ? null : () => onMore!(group.category),
                  child: Text('View more ${group.title.toLowerCase()}'),
                ),
              ),
            ),
        ],
    ];
  }

  Widget _suggestionTile(BuildContext context, AiSuggestionEntry entry, {required bool selected, required String query}) {
    final icon = switch (entry.kind) {
      'recent' => Icons.history_rounded,
      'popular' => Icons.trending_up_rounded,
      'completion' => Icons.place_outlined,
      _ => Icons.auto_awesome_outlined,
    };
    final removable = entry.kind == 'recent' && entry.recent != null && onRemoveRecent != null;
    return ListTile(
      dense: true,
      selected: selected,
      selectedTileColor: AiSearchTheme.accent(context).withValues(alpha: 0.08),
      leading: Icon(icon, size: 18, color: entry.kind == 'popular' ? AiSearchTheme.violet(context) : CRMColors.textSecondaryOf(context)),
      title: _highlighted(context, entry.text, query, maxLines: 1),
      trailing: removable
          ? IconButton(
              tooltip: 'Remove from history',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded, size: 16),
              onPressed: () => onRemoveRecent!(entry.recent!),
            )
          : Icon(Icons.north_west_rounded, size: 14, color: CRMColors.textSecondaryOf(context)),
      onTap: onSuggestion == null ? null : () => onSuggestion!(entry),
    );
  }

  Widget _seeAll(BuildContext context, String trimmed) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(CRMSpacing.s, 4, CRMSpacing.s, 0),
      child: InkWell(
        key: const ValueKey('ai-search-see-all'),
        borderRadius: BorderRadius.circular(8),
        onTap: onSeeAll,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(colors: [
              AiSearchTheme.accent(context).withValues(alpha: 0.10),
              AiSearchTheme.violet(context).withValues(alpha: 0.10),
            ]),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, size: 18, color: AiSearchTheme.accent(context)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'See all results for "$trimmed"',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AiSearchTheme.accent(context), fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              Text('Enter', style: TextStyle(fontSize: 11, color: CRMColors.textSecondaryOf(context))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _openFiltered(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(CRMSpacing.s, 4, CRMSpacing.s, 0),
        child: TextButton.icon(
          key: const ValueKey('ai-search-open-filtered'),
          onPressed: onOpenFiltered,
          icon: const Icon(Icons.filter_alt_outlined, size: 16),
          label: Text(openFilteredLabel ?? 'Open the page with these filters'),
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(CRMSpacing.m, CRMSpacing.s, CRMSpacing.m, 2),
      child: Row(
        children: [
          Icon(icon, size: 13, color: CRMColors.textSecondaryOf(context)),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(color: CRMColors.textSecondaryOf(context), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _message(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.all(CRMSpacing.m),
      child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: CRMColors.textSecondaryOf(context))),
    );
  }

  Widget _iconBadge(BuildContext context, IconData icon) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AiSearchTheme.accent(context).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: AiSearchTheme.accent(context)),
    );
  }

  Widget _badge(BuildContext context, String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _highlighted(BuildContext context, String text, String query, {int maxLines = 2}) {
    final base = TextStyle(color: CRMColors.textOf(context), fontSize: 13.5);
    final needle = query.trim().toLowerCase();
    final at = needle.isEmpty ? -1 : text.toLowerCase().indexOf(needle);
    if (at < 0) return Text(text, maxLines: maxLines, overflow: TextOverflow.ellipsis, style: base);
    return Text.rich(
      TextSpan(style: base, children: [
        TextSpan(text: text.substring(0, at)),
        TextSpan(text: text.substring(at, at + needle.length), style: const TextStyle(fontWeight: FontWeight.w800)),
        TextSpan(text: text.substring(at + needle.length)),
      ]),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  static IconData _pageIcon(String name) => switch (name) {
        'dashboard' => Icons.dashboard_outlined,
        'apartment' => Icons.apartment_outlined,
        'people' => Icons.people_outline_rounded,
        'event' => Icons.event_outlined,
        'emoji_events' => Icons.emoji_events_outlined,
        'block' => Icons.block_rounded,
        'campaign' => Icons.campaign_outlined,
        'phone' => Icons.phone_in_talk_outlined,
        'phone_missed' => Icons.phone_missed_outlined,
        'hub' => Icons.hub_outlined,
        'alt_route' => Icons.alt_route_rounded,
        'badge' => Icons.badge_outlined,
        'bar_chart' => Icons.bar_chart_rounded,
        'photo_library' => Icons.photo_library_outlined,
        'chat' => Icons.chat_bubble_outline_rounded,
        'support_agent' => Icons.support_agent_rounded,
        'settings' => Icons.settings_outlined,
        'person' => Icons.person_outline_rounded,
        'delete' => Icons.delete_outline_rounded,
        'contacts' => Icons.contacts_outlined,
        'key' => Icons.key_outlined,
        'business' => Icons.business_outlined,
        'history' => Icons.history_rounded,
        'security' => Icons.security_rounded,
        'workspace_premium' => Icons.workspace_premium_outlined,
        'domain' => Icons.domain_rounded,
        'admin_panel_settings' => Icons.admin_panel_settings_outlined,
        'insights' => Icons.insights_outlined,
        _ => Icons.open_in_new_rounded,
      };
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
