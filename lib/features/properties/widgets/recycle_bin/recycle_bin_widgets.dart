import 'package:flutter/material.dart';
import '../../../../core/design_system/tokens/app_breakpoints.dart';
import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../core/design_system/tokens/app_typography.dart';
import 'recycle_bin_tokens.dart';

/// Badge pill used on recycle-bin rows and banners.
class RbBadge extends StatelessWidget {
  final String label;
  final Color? background;
  final Color? foreground;
  final bool mono;

  const RbBadge({
    super.key,
    required this.label,
    this.background,
    this.foreground,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = background ?? RbTokens.soft(context);
    final fg = foreground ?? RbTokens.ink2(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(CRMBorderRadius.badge),
        border: Border.all(color: bg == RbTokens.soft(context) ? RbTokens.line(context) : bg),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: (mono ? CRMTypography.captionBold : CRMTypography.captionBold).copyWith(
          color: fg,
          fontSize: 11,
          fontFamily: mono ? 'monospace' : null,
          letterSpacing: mono ? 0.2 : 0,
        ),
      ),
    );
  }
}

/// Segmented Properties / Leads control with count pills.
class RbKindSegment extends StatelessWidget {
  final String selected; // 'prop' | 'lead'
  final int propertyCount;
  final int leadCount;
  final ValueChanged<String> onChanged;

  const RbKindSegment({
    super.key,
    required this.selected,
    required this.propertyCount,
    required this.leadCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: RbTokens.soft(context),
        borderRadius: BorderRadius.circular(CRMBorderRadius.s),
        border: Border.all(color: RbTokens.line(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _seg(context, 'prop', 'Properties', propertyCount),
          _seg(context, 'lead', 'Leads', leadCount),
        ],
      ),
    );
  }

  Widget _seg(BuildContext context, String key, String label, int count) {
    final on = selected == key;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onChanged(key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: on ? RbTokens.panelBg(context) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: on
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: CRMTypography.bodyMedium.copyWith(
                  fontSize: 13,
                  fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                  color: on ? RbTokens.greenTextOf(context) : RbTokens.ink2(context),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: on ? RbTokens.green : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: CRMTypography.captionBold.copyWith(
                    fontSize: 11,
                    color: on ? Colors.white : RbTokens.ink2(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rent / Re-sale / All chip row.
class RbTypeChips extends StatelessWidget {
  final String selected; // Rent | Re-sale | All
  final ValueChanged<String> onChanged;

  const RbTypeChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: ['Rent', 'Re-sale', 'All'].map((t) {
        final on = selected == t;
        return FilterChip(
          selected: on,
          showCheckmark: false,
          label: Text(t),
          labelStyle: CRMTypography.captionBold.copyWith(
            fontSize: 12.5,
            color: on ? RbTokens.greenTextOf(context) : RbTokens.ink2(context),
          ),
          selectedColor: RbTokens.greenBgOf(context),
          backgroundColor: RbTokens.panelBg(context),
          side: BorderSide(
            color: on ? RbTokens.greenLineOf(context) : RbTokens.line(context),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          onSelected: (_) => onChanged(t),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        );
      }).toList(),
    );
  }
}

/// Green restore-window banner.
class RbInfoBanner extends StatelessWidget {
  final int autoDeleteDays;
  final String countLabel;

  const RbInfoBanner({
    super.key,
    required this.autoDeleteDays,
    required this.countLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: RbTokens.greenBgOf(context),
        borderRadius: BorderRadius.circular(CRMBorderRadius.m),
        border: Border.all(color: RbTokens.greenLineOf(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: RbTokens.panelBg(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: RbTokens.greenLineOf(context)),
            ),
            child: Icon(Icons.replay_rounded, color: RbTokens.greenTextOf(context), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Restore anything within $autoDeleteDays days',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CRMTypography.bodyMedium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: RbTokens.greenDeepOf(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'After that, items are deleted for good. Restored items go back to Properties or Leads.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: CRMTypography.caption.copyWith(
                    fontSize: 12.5,
                    color: RbTokens.greenTextOf(context),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 220),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: RbTokens.panelBg(context),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: RbTokens.greenLineOf(context)),
                ),
                child: Text(
                  countLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: CRMTypography.captionBold.copyWith(
                    fontSize: 12,
                    color: RbTokens.greenTextOf(context),
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

/// Lead-kind selector cards (listing / requirement).
class RbLeadKindCards extends StatelessWidget {
  final String selected; // list | req
  final int listingCount;
  final int requirementCount;
  final String listingSubtitle;
  final String requirementSubtitle;
  final ValueChanged<String> onChanged;

  const RbLeadKindCards({
    super.key,
    required this.selected,
    required this.listingCount,
    required this.requirementCount,
    required this.listingSubtitle,
    required this.requirementSubtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final narrow = CRMBreakpoints.widthOf(context) < 900;
    final cards = [
      _card(
        context,
        keyName: 'list',
        icon: Icons.home_rounded,
        title: 'Property listing leads',
        count: listingCount,
        subtitle: listingSubtitle,
      ),
      _card(
        context,
        keyName: 'req',
        icon: Icons.vpn_key_rounded,
        title: 'Requirement leads',
        count: requirementCount,
        subtitle: requirementSubtitle,
      ),
    ];

    if (narrow) {
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            cards[i],
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: cards[i]),
        ],
      ],
    );
  }

  Widget _card(
    BuildContext context, {
    required String keyName,
    required IconData icon,
    required String title,
    required int count,
    required String subtitle,
  }) {
    final on = selected == keyName;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(CRMBorderRadius.m),
        onTap: () => onChanged(keyName),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: on ? RbTokens.greenBgOf(context) : RbTokens.panelBg(context),
            borderRadius: BorderRadius.circular(CRMBorderRadius.m),
            border: Border.all(
              color: on ? RbTokens.green : RbTokens.line(context),
              width: on ? 1.5 : 1,
            ),
            boxShadow: on
                ? [
                    BoxShadow(
                      color: RbTokens.green.withValues(alpha: 0.08),
                      blurRadius: 0,
                      spreadRadius: 3,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: on ? RbTokens.green : RbTokens.soft(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: on ? Colors.white : RbTokens.ink2(context)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CRMTypography.bodyMedium.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: on ? RbTokens.greenTextOf(context) : RbTokens.ink(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                          decoration: BoxDecoration(
                            color: on ? RbTokens.green : const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$count',
                            style: CRMTypography.captionBold.copyWith(
                              fontSize: 11,
                              color: on ? Colors.white : RbTokens.ink2(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: CRMTypography.caption.copyWith(
                        fontSize: 12,
                        color: RbTokens.muted(context),
                      ),
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

/// One deleted item row — overflow-safe for phone and desktop.
class RbItemRow extends StatelessWidget {
  final bool selected;
  final ValueChanged<bool?>? onSelected;
  final IconData thumbIcon;
  final List<Widget> tags;
  final String title;
  final List<InlineSpan> metaSpans;
  final String price;
  final String priceHint;
  final VoidCallback? onRestore;
  final VoidCallback? onDeleteForever;
  final bool canRestore;
  final bool canDeleteForever;
  final String restoreLabel;
  final String deleteLabel;

  const RbItemRow({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.thumbIcon,
    required this.tags,
    required this.title,
    required this.metaSpans,
    required this.price,
    required this.priceHint,
    required this.onRestore,
    required this.onDeleteForever,
    required this.canRestore,
    required this.canDeleteForever,
    this.restoreLabel = 'Restore',
    this.deleteLabel = 'Delete forever',
  });

  @override
  Widget build(BuildContext context) {
    final narrow = CRMBreakpoints.widthOf(context) < 900;

    final mid = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: 6, runSpacing: 4, children: tags),
        const SizedBox(height: 4),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: CRMTypography.bodyMedium.copyWith(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: RbTokens.ink(context),
          ),
        ),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(children: metaSpans),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    final priceCol = Column(
      crossAxisAlignment: narrow ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          price,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CRMTypography.sectionTitle.copyWith(
            fontSize: narrow ? 18 : 20,
            fontWeight: FontWeight.w700,
            color: RbTokens.ink(context),
          ),
        ),
        Text(
          priceHint,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CRMTypography.caption.copyWith(fontSize: 11, color: RbTokens.muted(context)),
        ),
      ],
    );

    final actions = Wrap(
      spacing: 7,
      runSpacing: 7,
      alignment: narrow ? WrapAlignment.start : WrapAlignment.end,
      children: [
        if (canRestore)
          _ActionButton(
            label: restoreLabel,
            icon: Icons.replay_rounded,
            filled: true,
            onPressed: onRestore,
          ),
        if (canDeleteForever)
          _ActionButton(
            label: deleteLabel,
            icon: Icons.delete_forever_rounded,
            danger: true,
            onPressed: onDeleteForever,
          ),
      ],
    );

    final thumb = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: RbTokens.soft(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(thumbIcon, size: 22, color: RbTokens.muted(context)),
    );

    if (narrow) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: RbTokens.line(context))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (onSelected != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: selected,
                        onChanged: onSelected,
                        activeColor: RbTokens.green,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                thumb,
                const SizedBox(width: 12),
                Expanded(child: mid),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: priceCol),
                actions,
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: RbTokens.line(context))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (onSelected != null) ...[
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: selected,
                onChanged: onSelected,
                activeColor: RbTokens.green,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 12),
          ],
          thumb,
          const SizedBox(width: 14),
          Expanded(child: mid),
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 96, maxWidth: 140),
            child: priceCol,
          ),
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 148),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (canRestore)
                  _ActionButton(
                    label: restoreLabel,
                    icon: Icons.replay_rounded,
                    filled: true,
                    fullWidth: true,
                    onPressed: onRestore,
                  ),
                if (canRestore && canDeleteForever) const SizedBox(height: 7),
                if (canDeleteForever)
                  _ActionButton(
                    label: deleteLabel,
                    icon: Icons.delete_forever_rounded,
                    danger: true,
                    fullWidth: true,
                    onPressed: onDeleteForever,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool filled;
  final bool danger;
  final bool fullWidth;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = false,
    this.danger = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final Color border;
    if (danger) {
      bg = Colors.transparent;
      fg = RbTokens.red;
      border = RbTokens.redLineOf(context);
    } else if (filled) {
      bg = RbTokens.greenBgOf(context);
      fg = RbTokens.greenTextOf(context);
      border = RbTokens.greenLineOf(context);
    } else {
      bg = RbTokens.panelBg(context);
      fg = RbTokens.ink2(context);
      border = RbTokens.line(context);
    }

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 34,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 15, color: fg),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CRMTypography.captionBold.copyWith(fontSize: 12.5, color: fg),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

class RbEmptyState extends StatelessWidget {
  final String noun;
  final String typeLabel;

  const RbEmptyState({
    super.key,
    required this.noun,
    required this.typeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: RbTokens.greenBgOf(context),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, color: RbTokens.greenTextOf(context), size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              'Nothing here',
              style: CRMTypography.sectionTitle.copyWith(
                fontWeight: FontWeight.w700,
                color: RbTokens.ink(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Deleted $noun ($typeLabel) will show up here for 30 days.',
              textAlign: TextAlign.center,
              style: CRMTypography.body.copyWith(color: RbTokens.muted(context), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class RbSidePanel extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;
  final bool danger;

  const RbSidePanel({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: danger ? RbTokens.redBgOf(context) : RbTokens.panelBg(context),
        borderRadius: BorderRadius.circular(CRMBorderRadius.m),
        border: Border.all(
          color: danger ? RbTokens.redLineOf(context) : RbTokens.line(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CRMTypography.captionBold.copyWith(
                    fontSize: 12,
                    letterSpacing: 0.3,
                    color: danger ? RbTokens.redDeep : RbTokens.ink2(context),
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class RbBulkBar extends StatelessWidget {
  final int count;
  final VoidCallback onClear;
  final VoidCallback? onRestore;
  final VoidCallback? onDelete;

  const RbBulkBar({
    super.key,
    required this.count,
    required this.onClear,
    this.onRestore,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: RbTokens.greenBgOf(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: RbTokens.greenLineOf(context)),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          Text(
            '$count item${count == 1 ? '' : 's'} selected',
            style: CRMTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: RbTokens.greenDeepOf(context),
            ),
          ),
          if (onRestore != null)
            TextButton.icon(
              onPressed: onRestore,
              icon: const Icon(Icons.replay_rounded, size: 16),
              label: const Text('Restore selected'),
              style: TextButton.styleFrom(foregroundColor: RbTokens.green),
            ),
          if (onDelete != null)
            TextButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_forever_rounded, size: 16),
              label: const Text('Delete forever'),
              style: TextButton.styleFrom(foregroundColor: RbTokens.red),
            ),
          TextButton(
            onPressed: onClear,
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
