import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/tokens/app_colors.dart';
import '../../../../core/design_system/tokens/app_typography.dart';
import '../../../../core/design_system/widgets/crm_network_image.dart';
import 'library_vault_tokens.dart';

/// Presentational widgets for the New_UI Library vault screens
/// (library-vault.html). They hold no business logic: every action is a
/// callback supplied by the owning screen.

TextStyle _ts(
  Color color,
  double size, {
  FontWeight weight = FontWeight.w400,
  double? letterSpacing,
  double? height,
}) {
  return CRMTypography.body.copyWith(
    color: color,
    fontSize: size,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    height: height,
  );
}

Color _greenLine(BuildContext context) => CRMColors.isDark
    ? LvTokens.green2.withValues(alpha: 0.4)
    : const Color(0xFFA7F3D0);

/// Counts documents whose type contains any of [keywords] (case-insensitive).
int lvCountByKeywords(Iterable<String> documentTypes, List<String> keywords) {
  var n = 0;
  for (final raw in documentTypes) {
    final t = raw.toLowerCase();
    if (keywords.any((k) => t.contains(k))) n++;
  }
  return n;
}

// ─────────────────────────────────────────────────────────────────────────────
// Breadcrumb
// ─────────────────────────────────────────────────────────────────────────────

class LvBreadcrumb extends StatefulWidget {
  final String vaultName;
  const LvBreadcrumb({super.key, required this.vaultName});

  @override
  State<LvBreadcrumb> createState() => _LvBreadcrumbState();
}

class _LvBreadcrumbState extends State<LvBreadcrumb> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final muted = LibTokens.muted(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.go('/library'),
            child: Text(
              'Library',
              style: _ts(
                LibTokens.greenTextOf(context),
                12.5,
                weight: FontWeight.w600,
              ).copyWith(
                decoration:
                    _hover ? TextDecoration.underline : TextDecoration.none,
                decorationColor: LibTokens.greenTextOf(context),
              ),
            ),
          ),
        ),
        Text('  /  ', style: _ts(muted, 12.5)),
        Flexible(
          child: Text(
            widget.vaultName,
            overflow: TextOverflow.ellipsis,
            style: _ts(muted, 12.5),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero
// ─────────────────────────────────────────────────────────────────────────────

class LvHero extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  /// Called with 'Excel' or 'PDF'. When null the Export button is hidden.
  final ValueChanged<String>? onExport;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback onPrimary;

  /// Extra buttons rendered before Export (optional).
  final List<Widget> extraActions;

  const LvHero({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.onPrimary,
    this.primaryIcon = Icons.add_rounded,
    this.onExport,
    this.extraActions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final iconBox = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: LibTokens.greenBgOf(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, size: 24, color: LibTokens.greenTextOf(context)),
    );

    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: _ts(
            LibTokens.ink(context),
            24,
            weight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: _ts(LibTokens.muted(context), 13)),
      ],
    );

    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...extraActions,
        if (onExport != null) _LvExportButton(onSelected: onExport!),
        FilledButton.icon(
          onPressed: onPrimary,
          icon: Icon(primaryIcon, size: 18),
          label: Text(
            primaryLabel,
            style: _ts(Colors.white, 13, weight: FontWeight.w600),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: LibTokens.green,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 760;
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  iconBox,
                  const SizedBox(width: 14),
                  Expanded(child: texts),
                ],
              ),
              const SizedBox(height: 12),
              actions,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            iconBox,
            const SizedBox(width: 14),
            Expanded(child: texts),
            const SizedBox(width: 12),
            actions,
          ],
        );
      },
    );
  }
}

class _LvExportButton extends StatefulWidget {
  final ValueChanged<String> onSelected;
  const _LvExportButton({required this.onSelected});

  @override
  State<_LvExportButton> createState() => _LvExportButtonState();
}

class _LvExportButtonState extends State<_LvExportButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Export Index',
      onSelected: widget.onSelected,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'Excel', child: Text('Export to Excel')),
        PopupMenuItem(value: 'PDF', child: Text('Export to PDF')),
      ],
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: AnimatedContainer(
          duration: LvTokens.motion,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _hover ? LibTokens.soft(context) : LibTokens.panelBg(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hover ? LibTokens.green2 : LibTokens.line(context),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.file_download_outlined,
                size: 18,
                color: LibTokens.ink(context),
              ),
              const SizedBox(width: 8),
              Text(
                'Export index',
                style: _ts(
                  LibTokens.ink(context),
                  13,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vault tabs
// ─────────────────────────────────────────────────────────────────────────────

enum LvVault { rental, resale, service }

extension LvVaultX on LvVault {
  String get label {
    switch (this) {
      case LvVault.rental:
        return 'Rental';
      case LvVault.resale:
        return 'Re-Sale';
      case LvVault.service:
        return 'Service agents';
    }
  }

  IconData get icon {
    switch (this) {
      case LvVault.rental:
        return Icons.home_rounded;
      case LvVault.resale:
        return Icons.sell_rounded;
      case LvVault.service:
        return Icons.handyman_rounded;
    }
  }

  String get route {
    switch (this) {
      case LvVault.rental:
        return '/rental-library';
      case LvVault.resale:
        return '/resale-library';
      case LvVault.service:
        return '/service-agent-library';
    }
  }
}

class LvVaultTabs extends StatelessWidget {
  final LvVault current;

  /// Optional override; by default navigates with `context.go(route)`.
  final ValueChanged<LvVault>? onTap;

  const LvVaultTabs({super.key, required this.current, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in LvVault.values)
          _LvVaultTab(
            vault: v,
            selected: v == current,
            onTap: () {
              if (v == current) return;
              if (onTap != null) {
                onTap!(v);
              } else {
                context.go(v.route);
              }
            },
          ),
      ],
    );
  }
}

class _LvVaultTab extends StatefulWidget {
  final LvVault vault;
  final bool selected;
  final VoidCallback onTap;
  const _LvVaultTab({
    required this.vault,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_LvVaultTab> createState() => _LvVaultTabState();
}

class _LvVaultTabState extends State<_LvVaultTab> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.selected;
    final fg = on ? LvTokens.tabOnFg(context) : LibTokens.ink2(context);
    final bg = on
        ? LvTokens.tabOnBg(context)
        : (_hover ? LibTokens.soft(context) : LibTokens.panelBg(context));
    final border = on
        ? LvTokens.tabOnBg(context)
        : (_hover ? LibTokens.green2 : LibTokens.line(context));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: LvTokens.motion,
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.vault.icon, size: 16, color: fg),
              const SizedBox(width: 8),
              Text(
                widget.vault.label,
                style: _ts(fg, 13, weight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KPI strip
// ─────────────────────────────────────────────────────────────────────────────

class LvKpiItem {
  final IconData icon;
  final String label;
  final String value;
  final String hint;
  final bool selected;
  final VoidCallback? onTap;

  const LvKpiItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
    this.selected = false,
    this.onTap,
  });
}

class LvKpiStrip extends StatelessWidget {
  final List<LvKpiItem> items;
  const LvKpiStrip({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 12.0;
        final cols = c.maxWidth >= 820 ? 4 : 2;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final k in items) SizedBox(width: w, child: _LvKpiCard(item: k)),
          ],
        );
      },
    );
  }
}

class _LvKpiCard extends StatefulWidget {
  final LvKpiItem item;
  const _LvKpiCard({required this.item});

  @override
  State<_LvKpiCard> createState() => _LvKpiCardState();
}

class _LvKpiCardState extends State<_LvKpiCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final k = widget.item;
    final tappable = k.onTap != null;
    final borderColor = k.selected
        ? LibTokens.green2
        : (_hover && tappable
            ? LibTokens.green2.withValues(alpha: 0.55)
            : LibTokens.line(context));

    return MouseRegion(
      cursor: tappable ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: k.onTap,
        child: AnimatedContainer(
          duration: LvTokens.motion,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: LibTokens.panelBg(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            boxShadow: k.selected
                ? [
                    BoxShadow(
                      color: LibTokens.greenBgOf(context),
                      spreadRadius: 3,
                      blurRadius: 0,
                    ),
                  ]
                : const [],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: LibTokens.greenBgOf(context),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  k.icon,
                  size: 18,
                  color: LibTokens.greenTextOf(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      k.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _ts(LibTokens.muted(context), 12),
                    ),
                    Text(
                      k.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _ts(
                        LibTokens.ink(context),
                        22,
                        weight: FontWeight.w700,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      k.hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _ts(LibTokens.muted(context), 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Panel + checklist
// ─────────────────────────────────────────────────────────────────────────────

/// Bordered white card (HTML `.xc`) with optional header (`.xch`).
class LvPanel extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const LvPanel({
    super.key,
    this.title,
    this.subtitle,
    this.trailing,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final line = LibTokens.line(context);
    return Container(
      decoration: BoxDecoration(
        color: LibTokens.panelBg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: line)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title!,
                          style: _ts(
                            LibTokens.ink(context),
                            15,
                            weight: FontWeight.w700,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: _ts(LibTokens.muted(context), 12.5),
                          ),
                        ],
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ],
      ),
    );
  }
}

class LvChecklistItem {
  final String label;
  final int count;
  const LvChecklistItem({required this.label, required this.count});
  bool get done => count > 0;
}

class LvChecklist extends StatelessWidget {
  final List<LvChecklistItem> items;
  final String title;
  final String subtitle;

  const LvChecklist({
    super.key,
    required this.items,
    this.title = 'Checklist for every deal',
    this.subtitle = 'Folders this vault should have for each property',
  });

  @override
  Widget build(BuildContext context) {
    return LvPanel(
      title: title,
      subtitle: subtitle,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [for (final i in items) _LvChecklistChip(item: i)],
      ),
    );
  }
}

class _LvChecklistChip extends StatelessWidget {
  final LvChecklistItem item;
  const _LvChecklistChip({required this.item});

  @override
  Widget build(BuildContext context) {
    final done = item.done;
    final fg = done ? LibTokens.greenTextOf(context) : LibTokens.ink2(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: done ? LibTokens.greenBgOf(context) : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: done ? _greenLine(context) : LibTokens.line(context),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (done) ...[
            Icon(Icons.check_rounded, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _ts(fg, 12),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: LibTokens.soft(context),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${item.count}',
              style: _ts(LibTokens.muted(context), 11, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter bar
// ─────────────────────────────────────────────────────────────────────────────

class LvDropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const LvDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = items.contains(value)
        ? value
        : (items.isNotEmpty ? items.first : null);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 4),
      decoration: BoxDecoration(
        color: LibTokens.panelBg(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: LibTokens.line(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: _ts(LibTokens.muted(context), 11)),
          DropdownButtonHideUnderline(
            child: SizedBox(
              height: 24,
              child: DropdownButton<String>(
                value: safeValue,
                isExpanded: true,
                isDense: true,
                borderRadius: BorderRadius.circular(10),
                dropdownColor: LibTokens.panelBg(context),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: LibTokens.muted(context),
                ),
                style: _ts(LibTokens.ink(context), 13, weight: FontWeight.w500),
                items: [
                  for (final i in items)
                    DropdownMenuItem<String>(
                      value: i,
                      child: Text(
                        i,
                        overflow: TextOverflow.ellipsis,
                        style: _ts(LibTokens.ink(context), 13),
                      ),
                    ),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LvSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback? onCleared;

  /// Optional autocomplete suggestions (e.g. master property names).
  final List<String> suggestions;
  final ValueChanged<String>? onSuggestionSelected;

  const LvSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hint = 'Search',
    this.onCleared,
    this.suggestions = const [],
    this.onSuggestionSelected,
  });

  @override
  State<LvSearchField> createState() => _LvSearchFieldState();
}

class _LvSearchFieldState extends State<LvSearchField> {
  final FocusNode _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() => _focused = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final fieldWidth = c.maxWidth;
        return RawAutocomplete<String>(
          textEditingController: widget.controller,
          focusNode: _focus,
          optionsBuilder: (value) {
            final q = value.text.trim().toLowerCase();
            if (q.isEmpty || widget.suggestions.isEmpty) {
              return const Iterable<String>.empty();
            }
            return widget.suggestions
                .where((s) => s.toLowerCase().contains(q))
                .take(8);
          },
          onSelected: (s) => widget.onSuggestionSelected?.call(s),
          fieldViewBuilder: (context, controller, focusNode, onSubmit) {
            return Container(
              padding: const EdgeInsets.fromLTRB(12, 6, 6, 4),
              decoration: BoxDecoration(
                color: LibTokens.panelBg(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _focused ? LibTokens.green2 : LibTokens.line(context),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: LibTokens.muted(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Search',
                          style: _ts(LibTokens.muted(context), 11),
                        ),
                        SizedBox(
                          height: 24,
                          child: TextField(
                            controller: controller,
                            focusNode: focusNode,
                            onChanged: widget.onChanged,
                            style: _ts(LibTokens.ink(context), 13),
                            cursorColor: LibTokens.green,
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 4),
                              hintText: widget.hint,
                              hintStyle: _ts(LibTokens.muted(context), 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, v, _) {
                      if (v.text.isEmpty) return const SizedBox(width: 6);
                      return InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () {
                          controller.clear();
                          widget.onChanged('');
                          widget.onCleared?.call();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: LibTokens.muted(context),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Material(
                  color: LibTokens.panelBg(context),
                  elevation: 4,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: LibTokens.line(context)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: 220,
                      maxWidth: fieldWidth,
                      minWidth: fieldWidth,
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, i) {
                        final o = options.elementAt(i);
                        return InkWell(
                          onTap: () => onSelected(o),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.home_work_outlined,
                                  size: 16,
                                  color: LibTokens.greenTextOf(context),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    o,
                                    overflow: TextOverflow.ellipsis,
                                    style: _ts(
                                      LibTokens.ink(context),
                                      13,
                                      weight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Small pill segmented control (HTML `.seg2`).
class LvSegment extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  const LvSegment({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: LibTokens.soft(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < labels.length; i++)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: LvTokens.motion,
                  height: 36,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: i == selected
                        ? LibTokens.panelBg(context)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: i == selected
                          ? LibTokens.line(context)
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    labels[i],
                    style: _ts(
                      i == selected
                          ? LibTokens.ink(context)
                          : LibTokens.muted(context),
                      12.5,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class LvFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String searchHint;
  final ValueChanged<String> onSearchChanged;
  final List<String> searchSuggestions;
  final ValueChanged<String>? onSuggestionSelected;
  final List<LvDropdownField> dropdowns;
  final VoidCallback onReset;

  /// Optional widget shown before the search box (e.g. [LvSegment]).
  final Widget? leading;

  const LvFilterBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.dropdowns,
    required this.onReset,
    this.searchHint = 'Document, property or person',
    this.searchSuggestions = const [],
    this.onSuggestionSelected,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final search = LvSearchField(
      controller: searchController,
      hint: searchHint,
      onChanged: onSearchChanged,
      suggestions: searchSuggestions,
      onSuggestionSelected: onSuggestionSelected,
    );
    final reset = OutlinedButton(
      onPressed: onReset,
      style: OutlinedButton.styleFrom(
        foregroundColor: LibTokens.ink2(context),
        side: BorderSide(color: LibTokens.line(context)),
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        'Reset',
        style: _ts(LibTokens.ink2(context), 13, weight: FontWeight.w600),
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: LibTokens.line(context))),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          const gap = 10.0;
          if (c.maxWidth >= 880) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: gap)],
                Expanded(flex: 3, child: search),
                for (final d in dropdowns) ...[
                  const SizedBox(width: gap),
                  Expanded(flex: 2, child: d),
                ],
                const SizedBox(width: gap),
                reset,
              ],
            );
          }
          final colW = (c.maxWidth - gap) / 2;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[leading!, const SizedBox(height: gap)],
              search,
              const SizedBox(height: gap),
              Wrap(
                spacing: gap,
                runSpacing: gap,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  for (final d in dropdowns) SizedBox(width: colW, child: d),
                  reset,
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pills / badges
// ─────────────────────────────────────────────────────────────────────────────

enum LvTone { green, red, amber, gray }

LvTone lvToneForStatus(String status) {
  switch (status.trim().toLowerCase()) {
    case 'active':
    case 'verified':
    case 'approved':
      return LvTone.green;
    case 'expired':
    case 'rejected':
      return LvTone.red;
    case 'pending':
    case 'waiting':
      return LvTone.amber;
    default:
      return LvTone.gray;
  }
}

class LvStatusPill extends StatelessWidget {
  final String label;
  final LvTone? tone;

  const LvStatusPill({super.key, required this.label, this.tone});

  @override
  Widget build(BuildContext context) {
    final t = tone ?? lvToneForStatus(label);
    late final Color bg;
    late final Color fg;
    switch (t) {
      case LvTone.green:
        bg = LibTokens.greenBgOf(context);
        fg = LibTokens.greenTextOf(context);
        break;
      case LvTone.red:
        bg = LvTokens.redBgOf(context);
        fg = LvTokens.redTextOf(context);
        break;
      case LvTone.amber:
        bg = LvTokens.amberBgOf(context);
        fg = LvTokens.amberTextOf(context);
        break;
      case LvTone.gray:
        bg = LibTokens.soft(context);
        fg = LibTokens.muted(context);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: _ts(fg, 11.5, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Outlined tag (HTML `.bdg.line`), e.g. document type.
class LvTagPill extends StatelessWidget {
  final String label;
  const LvTagPill({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: LibTokens.line(context)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: _ts(LibTokens.ink2(context), 11.5, weight: FontWeight.w500),
      ),
    );
  }
}

class LvDocFileBadge extends StatelessWidget {
  /// File extension, e.g. `pdf`, `mp4`.
  final String extension;
  const LvDocFileBadge({super.key, required this.extension});

  static const _videoExt = {'mp4', 'mov', 'avi', 'mkv', 'webm'};

  @override
  Widget build(BuildContext context) {
    final ext = extension.trim().toLowerCase();
    final isVideo = _videoExt.contains(ext);
    late final Color bg;
    late final Color fg;
    late final String text;
    if (ext == 'pdf' || ext.isEmpty) {
      bg = LvTokens.redBgOf(context);
      fg = LvTokens.redTextOf(context);
      text = 'PDF';
    } else if (isVideo) {
      bg = LvTokens.blueBgOf(context);
      fg = LvTokens.blueTextOf(context);
      text = ext == 'mp4' ? 'MP4' : ext.toUpperCase();
    } else {
      bg = LibTokens.soft(context);
      fg = LibTokens.ink2(context);
      text = ext.length > 4 ? ext.substring(0, 4).toUpperCase() : ext.toUpperCase();
    }
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        text,
        style: _ts(fg, 10, weight: FontWeight.w800),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Table
// ─────────────────────────────────────────────────────────────────────────────

class LvColumn<T> {
  final String label;
  final int flex;

  /// When set the header is clickable and reports this field to onSort.
  final String? sortField;
  final Widget Function(BuildContext context, T item) cell;

  const LvColumn({
    required this.label,
    required this.cell,
    this.flex = 2,
    this.sortField,
  });
}

/// Two-line cell: primary text + muted secondary (HTML `.xs`).
class LvCellText extends StatelessWidget {
  final String primary;
  final String? secondary;
  final bool bold;

  const LvCellText({
    super.key,
    required this.primary,
    this.secondary,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          primary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _ts(
            LibTokens.ink(context),
            13,
            weight: bold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        if (secondary != null && secondary!.isNotEmpty)
          Text(
            secondary!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _ts(LibTokens.muted(context), 12),
          ),
      ],
    );
  }
}

/// File cell: badge + name + size (HTML `.doc`).
class LvDocNameCell extends StatelessWidget {
  final String extension;
  final String name;
  final String size;

  const LvDocNameCell({
    super.key,
    required this.extension,
    required this.name,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        LvDocFileBadge(extension: extension),
        const SizedBox(width: 10),
        Expanded(child: LvCellText(primary: name, secondary: size, bold: true)),
      ],
    );
  }
}

class LvIconAction extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool danger;

  const LvIconAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.danger = false,
  });

  @override
  State<LvIconAction> createState() => _LvIconActionState();
}

class _LvIconActionState extends State<LvIconAction> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final fg = widget.danger
        ? LvTokens.redTextOf(context)
        : (_hover ? LibTokens.greenTextOf(context) : LibTokens.ink2(context));
    final hoverBg = widget.danger
        ? LvTokens.redBgOf(context)
        : LibTokens.greenBgOf(context);
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: LvTokens.motion,
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _hover ? hoverBg : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(widget.icon, size: 17, color: fg),
          ),
        ),
      ),
    );
  }
}

class LvDocRow<T> extends StatefulWidget {
  final List<LvColumn<T>> columns;
  final T item;
  final Widget actions;
  final double actionsWidth;
  final bool showDivider;

  const LvDocRow({
    super.key,
    required this.columns,
    required this.item,
    required this.actions,
    required this.actionsWidth,
    this.showDivider = true,
  });

  @override
  State<LvDocRow<T>> createState() => _LvDocRowState<T>();
}

class _LvDocRowState<T> extends State<LvDocRow<T>> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: LvTokens.motion,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: _hover ? LvTokens.rowHover(context) : Colors.transparent,
          border: widget.showDivider
              ? Border(bottom: BorderSide(color: LibTokens.line(context)))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (final c in widget.columns)
              Expanded(
                flex: c.flex,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: c.cell(context, widget.item),
                  ),
                ),
              ),
            SizedBox(
              width: widget.actionsWidth,
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  duration: LvTokens.motion,
                  opacity: _hover ? 1 : 0.6,
                  child: widget.actions,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LvDocTable<T> extends StatelessWidget {
  final List<LvColumn<T>> columns;
  final List<T> items;
  final Widget Function(BuildContext context, T item) actionsBuilder;
  final double actionsWidth;
  final double minWidth;
  final String? sortField;
  final bool sortAscending;
  final void Function(String field)? onSort;

  const LvDocTable({
    super.key,
    required this.columns,
    required this.items,
    required this.actionsBuilder,
    this.actionsWidth = 190,
    this.minWidth = 1020,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final contentW = c.maxWidth < minWidth ? minWidth : c.maxWidth;
        final table = SizedBox(
          width: contentW,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(context),
              for (var i = 0; i < items.length; i++)
                LvDocRow<T>(
                  columns: columns,
                  item: items[i],
                  actionsWidth: actionsWidth,
                  showDivider: i != items.length - 1,
                  actions: actionsBuilder(context, items[i]),
                ),
            ],
          ),
        );
        if (c.maxWidth >= minWidth) return table;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: table,
        );
      },
    );
  }

  Widget _header(BuildContext context) {
    final line = LibTokens.line(context);
    final muted = LibTokens.muted(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: LibTokens.pageBg(context),
        border: Border(bottom: BorderSide(color: line)),
      ),
      child: Row(
        children: [
          for (final col in columns)
            Expanded(
              flex: col.flex,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _LvHeaderCell(
                  label: col.label,
                  color: muted,
                  sortable: col.sortField != null && onSort != null,
                  active: col.sortField != null && col.sortField == sortField,
                  ascending: sortAscending,
                  onTap: () => onSort?.call(col.sortField!),
                ),
              ),
            ),
          SizedBox(
            width: actionsWidth,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'ACTIONS',
                style: _ts(muted, 11, weight: FontWeight.w600, letterSpacing: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LvHeaderCell extends StatelessWidget {
  final String label;
  final Color color;
  final bool sortable;
  final bool active;
  final bool ascending;
  final VoidCallback onTap;

  const _LvHeaderCell({
    required this.label,
    required this.color,
    required this.sortable,
    required this.active,
    required this.ascending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: _ts(
        active ? LibTokens.greenTextOf(context) : color,
        11,
        weight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
    if (!sortable) return text;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: text),
            if (active) ...[
              const SizedBox(width: 3),
              Icon(
                ascending
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 12,
                color: LibTokens.greenTextOf(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Mobile alternative to a table row.
class LvDocMobileCard extends StatelessWidget {
  final String extension;
  final String name;
  final String subtitle;
  final List<MapEntry<String, String>> details;
  final String statusLabel;
  final Widget actions;

  const LvDocMobileCard({
    super.key,
    required this.extension,
    required this.name,
    required this.subtitle,
    required this.details,
    required this.statusLabel,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LibTokens.panelBg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LibTokens.line(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: LvDocNameCell(
                  extension: extension,
                  name: name,
                  size: subtitle,
                ),
              ),
              const SizedBox(width: 8),
              LvStatusPill(label: statusLabel),
            ],
          ),
          const SizedBox(height: 10),
          for (final d in details)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Text(d.key, style: _ts(LibTokens.muted(context), 12)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      d.value,
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      style: _ts(
                        LibTokens.ink(context),
                        12.5,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Align(alignment: Alignment.centerRight, child: actions),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer / empty
// ─────────────────────────────────────────────────────────────────────────────

class LvPanelFooter extends StatelessWidget {
  final String label;
  final int currentPage;
  final int totalPages;
  final ValueChanged<int>? onPageChanged;
  final int? pageSize;
  final ValueChanged<int>? onPageSizeChanged;

  const LvPanelFooter({
    super.key,
    required this.label,
    this.currentPage = 1,
    this.totalPages = 1,
    this.onPageChanged,
    this.pageSize,
    this.onPageSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final muted = LibTokens.muted(context);
    final showPaging = onPageChanged != null && totalPages > 1;
    final sizes = <int>{10, 25, 50, ?pageSize}.toList()
      ..sort();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: LibTokens.line(context))),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 6,
        spacing: 12,
        children: [
          Text(label, style: _ts(muted, 12.5)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onPageSizeChanged != null && pageSize != null) ...[
                Text('Rows', style: _ts(muted, 12)),
                const SizedBox(width: 6),
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: pageSize,
                    isDense: true,
                    dropdownColor: LibTokens.panelBg(context),
                    style: _ts(LibTokens.ink(context), 12.5),
                    items: [
                      for (final s in sizes)
                        DropdownMenuItem(value: s, child: Text('$s')),
                    ],
                    onChanged: (v) {
                      if (v != null) onPageSizeChanged!(v);
                    },
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (showPaging) ...[
                LvIconAction(
                  icon: Icons.chevron_left_rounded,
                  tooltip: 'Previous page',
                  onTap: () {
                    if (currentPage > 1) onPageChanged!(currentPage - 1);
                  },
                ),
                Text(
                  'Page $currentPage of $totalPages',
                  style: _ts(LibTokens.ink2(context), 12.5, weight: FontWeight.w600),
                ),
                LvIconAction(
                  icon: Icons.chevron_right_rounded,
                  tooltip: 'Next page',
                  onTap: () {
                    if (currentPage < totalPages) onPageChanged!(currentPage + 1);
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class LvEmpty extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const LvEmpty({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: _ts(LibTokens.ink(context), 15, weight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: _ts(LibTokens.muted(context), 13),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: LibTokens.greenTextOf(context),
                  side: BorderSide(color: LibTokens.green2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: _ts(
                    LibTokens.greenTextOf(context),
                    13,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Centered loading indicator sized for a panel body.
class LvLoading extends StatelessWidget {
  const LvLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(48),
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: LibTokens.green,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service agent card
// ─────────────────────────────────────────────────────────────────────────────

enum LvActionKind { primary, neutral, danger }

class LvAgentAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final LvActionKind kind;

  const LvAgentAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.kind = LvActionKind.neutral,
  });
}

class LvMenuAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  const LvMenuAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.danger = false,
  });
}

class LvAgentCard extends StatefulWidget {
  final String name;
  final String role;
  final String mobile;
  final String? imageUrl;
  final String statusLabel;
  final List<String> areas;
  final List<String> badges;
  final String? meta;
  final List<LvAgentAction> actions;
  final List<LvMenuAction> menu;

  const LvAgentCard({
    super.key,
    required this.name,
    required this.role,
    required this.mobile,
    required this.statusLabel,
    this.imageUrl,
    this.areas = const [],
    this.badges = const [],
    this.meta,
    this.actions = const [],
    this.menu = const [],
  });

  @override
  State<LvAgentCard> createState() => _LvAgentCardState();
}

class _LvAgentCardState extends State<LvAgentCard> {
  bool _hover = false;

  String get _initials {
    final parts = widget.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  Widget _avatar(BuildContext context) {
    final fallback = Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: LibTokens.greenBgOf(context),
        shape: BoxShape.circle,
      ),
      child: Text(
        _initials,
        style: _ts(LibTokens.greenTextOf(context), 14, weight: FontWeight.w700),
      ),
    );
    final url = widget.imageUrl;
    if (url == null || url.isEmpty) return fallback;
    return ClipOval(
      child: CrmNetworkImage(
        url: url,
        width: 42,
        height: 42,
        cacheLogicalWidth: 42,
        cacheLogicalHeight: 42,
        fit: BoxFit.cover,
        error: (_) => fallback,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: LvTokens.motion,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: LibTokens.panelBg(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hover
                ? LibTokens.green2.withValues(alpha: 0.55)
                : LibTokens.line(context),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _avatar(context),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _ts(
                          LibTokens.ink(context),
                          14,
                          weight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        [widget.role, widget.mobile]
                            .where((s) => s.trim().isNotEmpty)
                            .join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _ts(LibTokens.muted(context), 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                LvStatusPill(label: widget.statusLabel),
                if (widget.menu.isNotEmpty)
                  PopupMenuButton<int>(
                    tooltip: 'More',
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: 18,
                      color: LibTokens.muted(context),
                    ),
                    onSelected: (i) => widget.menu[i].onTap(),
                    itemBuilder: (context) => [
                      for (var i = 0; i < widget.menu.length; i++)
                        PopupMenuItem<int>(
                          value: i,
                          child: Row(
                            children: [
                              Icon(
                                widget.menu[i].icon,
                                size: 18,
                                color: widget.menu[i].danger
                                    ? LvTokens.red
                                    : LibTokens.ink2(context),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.menu[i].label,
                                style: TextStyle(
                                  color: widget.menu[i].danger
                                      ? LvTokens.red
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            if (widget.areas.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.place_outlined,
                    size: 14,
                    color: LibTokens.muted(context),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.areas.join(', '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _ts(LibTokens.muted(context), 12),
                    ),
                  ),
                ],
              ),
            ],
            if (widget.badges.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final b in widget.badges) LvTagPill(label: '✓ $b'),
                ],
              ),
            ],
            if (widget.meta != null && widget.meta!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.meta!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _ts(LibTokens.muted(context), 11.5),
              ),
            ],
            if (widget.actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final a in widget.actions) _LvSmallButton(action: a),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LvSmallButton extends StatefulWidget {
  final LvAgentAction action;
  const _LvSmallButton({required this.action});

  @override
  State<_LvSmallButton> createState() => _LvSmallButtonState();
}

class _LvSmallButtonState extends State<_LvSmallButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.action;
    late final Color bg;
    late final Color fg;
    late final Color border;
    switch (a.kind) {
      case LvActionKind.primary:
        bg = _hover ? const Color(0xFF065F46) : LibTokens.green;
        fg = Colors.white;
        border = bg;
        break;
      case LvActionKind.danger:
        bg = _hover ? LvTokens.redBgOf(context) : Colors.transparent;
        fg = LvTokens.redTextOf(context);
        border = _hover ? LvTokens.red : LibTokens.line(context);
        break;
      case LvActionKind.neutral:
        bg = _hover ? LibTokens.greenBgOf(context) : Colors.transparent;
        fg = _hover ? LibTokens.greenTextOf(context) : LibTokens.ink(context);
        border = _hover ? LibTokens.green2 : LibTokens.line(context);
        break;
    }
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: a.onTap,
        child: AnimatedContainer(
          duration: LvTokens.motion,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(a.icon, size: 15, color: fg),
              const SizedBox(width: 6),
              Text(a.label, style: _ts(fg, 12.5, weight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Responsive grid for [LvAgentCard]s (HTML `.agent`).
class LvAgentGrid extends StatelessWidget {
  final List<Widget> children;
  const LvAgentGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: LayoutBuilder(
        builder: (context, c) {
          const gap = 12.0;
          const minW = 280.0;
          var cols = ((c.maxWidth + gap) / (minW + gap)).floor();
          if (cols < 1) cols = 1;
          final w = (c.maxWidth - gap * (cols - 1)) / cols;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [for (final ch in children) SizedBox(width: w, child: ch)],
          );
        },
      ),
    );
  }
}
