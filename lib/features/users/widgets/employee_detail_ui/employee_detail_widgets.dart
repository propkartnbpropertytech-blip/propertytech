import 'package:flutter/material.dart';
import '../../../../core/design_system/widgets/crm_network_image.dart';
import '../../models/user_model.dart';
import 'employee_detail_tokens.dart';

// -----------------------------------------------------------------------------
// Shared primitives
// -----------------------------------------------------------------------------

/// Hover-aware tap surface used by every interactive New_UI element.
class _EvHover extends StatefulWidget {
  final Widget Function(BuildContext context, bool hovered) builder;
  final VoidCallback? onTap;

  const _EvHover({required this.builder, this.onTap});

  @override
  State<_EvHover> createState() => _EvHoverState();
}

class _EvHoverState extends State<_EvHover> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: widget.builder(context, _hovered),
      ),
    );
  }
}

String evInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return '?';
  return parts.take(2).map((p) => p[0]).join().toUpperCase();
}

/// Rounded-square avatar (photo or initials).
class EvAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double size;
  final double radius;
  final double fontSize;
  final EvTone tone;

  const EvAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 56,
    this.radius = 14,
    this.fontSize = 19,
    this.tone = EvTone.green,
  });

  @override
  Widget build(BuildContext context) {
    final fg = EvTokens.tone(tone);
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final initials = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: EvTokens.toneBg(tone, alpha: 0.14),
      child: Text(
        evInitials(name),
        style: EvTokens.text(size: fontSize, weight: FontWeight.w700, color: fg),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: hasPhoto
            ? CrmNetworkImage(
                url: photoUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                cacheLogicalWidth: size,
                error: (_) => initials,
              )
            : initials,
      ),
    );
  }
}

/// Pill badge (role / status / lead status).
class EvBadge extends StatelessWidget {
  final String label;
  final EvTone tone;

  const EvBadge({super.key, required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: EvTokens.toneBg(tone),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: EvTokens.text(
          size: 10.5,
          weight: FontWeight.w700,
          color: EvTokens.tone(tone),
        ),
      ),
    );
  }
}

/// Header / row action button.
class EvButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool primary;
  final bool danger;
  final bool small;

  const EvButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.primary = false,
    this.danger = false,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: _EvHover(
        onTap: onTap,
        builder: (context, hovered) {
          final Color bg;
          final Color border;
          final Color fg;
          if (primary) {
            bg = hovered ? EvTokens.greenHover : EmTokens.green;
            border = bg;
            fg = Colors.white;
          } else if (danger) {
            bg = hovered
                ? EmTokens.redText.withValues(alpha: 0.08)
                : EmTokens.panelBg(context);
            border = hovered
                ? EmTokens.redText.withValues(alpha: 0.5)
                : EmTokens.line(context);
            fg = EmTokens.redText;
          } else {
            bg = hovered ? EmTokens.soft(context) : EmTokens.panelBg(context);
            border = EmTokens.line(context);
            fg = EmTokens.ink2(context);
          }
          return AnimatedContainer(
            duration: EvTokens.hover,
            height: small ? 30 : 34,
            padding: EdgeInsets.symmetric(horizontal: small ? 11 : 14),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 15, color: fg),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: EvTokens.text(
                    size: small ? 12 : 12.5,
                    weight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 38x22 emerald toggle (HTML `.ld-tgl`).
class EvToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const EvToggle({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: _EvHover(
        onTap: enabled ? () => onChanged!(!value) : null,
        builder: (context, hovered) => AnimatedContainer(
          duration: EvTokens.hover,
          width: 38,
          height: 22,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: value ? EmTokens.green : const Color(0xFFD1D5DB),
            borderRadius: BorderRadius.circular(999),
          ),
          child: AnimatedAlign(
            duration: EvTokens.hover,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Breadcrumb + head
// -----------------------------------------------------------------------------

class EvBreadcrumb extends StatelessWidget {
  final String current;
  final VoidCallback onEmployees;

  const EvBreadcrumb({
    super.key,
    required this.current,
    required this.onEmployees,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onEmployees,
            child: Text(
              'Employees',
              style: EvTokens.text(
                size: 12.5,
                weight: FontWeight.w600,
                color: EmTokens.green,
              ),
            ),
          ),
        ),
        Text(
          '  /  ',
          style: EvTokens.text(size: 12.5, color: EmTokens.muted(context)),
        ),
        Text(
          current,
          style: EvTokens.text(size: 12.5, color: EmTokens.muted(context)),
        ),
      ],
    );
  }
}

class EvHead extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showTitle;
  final VoidCallback? onBack;
  final VoidCallback? onCall;
  final VoidCallback? onWhatsapp;
  final VoidCallback? onEmail;

  const EvHead({
    super.key,
    required this.title,
    required this.subtitle,
    this.showTitle = true,
    this.onBack,
    this.onCall,
    this.onWhatsapp,
    this.onEmail,
  });

  @override
  Widget build(BuildContext context) {
    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        if (onBack != null)
          EvButton(
            label: 'Back',
            icon: Icons.arrow_back_rounded,
            onTap: onBack,
          ),
        if (onCall != null)
          EvButton(label: 'Call', icon: Icons.call_outlined, onTap: onCall),
        if (onWhatsapp != null)
          EvButton(
            label: 'WhatsApp',
            icon: Icons.chat_bubble_outline_rounded,
            onTap: onWhatsapp,
          ),
        if (onEmail != null)
          EvButton(
            label: 'Email',
            icon: Icons.mail_outline_rounded,
            onTap: onEmail,
            primary: true,
          ),
      ],
    );

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'EMPLOYEE',
          style: EvTokens.text(
            size: 11,
            weight: FontWeight.w700,
            letterSpacing: 0.88,
            color: EmTokens.green,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: EvTokens.text(
            size: 26,
            weight: FontWeight.w700,
            letterSpacing: -0.3,
            color: EmTokens.ink(context),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: EvTokens.text(size: 13, color: EmTokens.muted(context)),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, c) {
        if (!showTitle) {
          return Align(alignment: Alignment.centerLeft, child: actions);
        }
        if (c.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerLeft, child: actions),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: 16),
            Flexible(child: actions),
          ],
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Profile card
// -----------------------------------------------------------------------------

class _EvInfoCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _EvInfoCell({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _EvHover(
      onTap: onTap,
      builder: (context, hovered) => Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: EmTokens.soft(context),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: EmTokens.muted(context)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: EvTokens.text(
                    size: 10.5,
                    weight: FontWeight.w700,
                    letterSpacing: 0.63,
                    color: EmTokens.muted(context),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: EvTokens.text(
                    size: 13,
                    weight: FontWeight.w600,
                    color: onTap != null
                        ? EmTokens.green
                        : EmTokens.ink(context),
                  ).copyWith(
                    decoration: onTap != null && hovered
                        ? TextDecoration.underline
                        : TextDecoration.none,
                    decorationColor: EmTokens.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EvProfileCard extends StatelessWidget {
  final UserModel user;
  final String joinedLabel;
  final String reportingLabel;
  final ValueChanged<bool>? onToggleLogin;
  final VoidCallback? onEmail;
  final VoidCallback? onCall;
  final VoidCallback? onEdit;
  final VoidCallback? onReset;
  final VoidCallback? onRemove;

  const EvProfileCard({
    super.key,
    required this.user,
    required this.joinedLabel,
    required this.reportingLabel,
    this.onToggleLogin,
    this.onEmail,
    this.onCall,
    this.onEdit,
    this.onReset,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final mobile = (user.mobile ?? '').trim();
    final tone = EvTokens.roleTone(user.roleName);

    final identity = Row(
      children: [
        EvAvatar(
          name: user.fullName,
          photoUrl: user.profilePhoto,
          tone: tone,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    user.fullName,
                    style: EvTokens.text(
                      size: 17,
                      weight: FontWeight.w700,
                      color: EmTokens.ink(context),
                    ),
                  ),
                  EvBadge(label: user.roleName, tone: tone),
                  EvBadge(
                    label: user.isActive ? 'Active' : 'Inactive',
                    tone: user.isActive ? EvTone.green : EvTone.gray,
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                'Joined $joinedLabel',
                style: EvTokens.text(
                  size: 12.5,
                  color: EmTokens.muted(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final login = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Active login',
          style: EvTokens.text(
            size: 12.5,
            weight: FontWeight.w600,
            color: EmTokens.ink2(context),
          ),
        ),
        const SizedBox(width: 10),
        EvToggle(value: user.isActive, onChanged: onToggleLogin),
      ],
    );

    final tools = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (onEdit != null)
          EvButton(label: 'Edit details', small: true, onTap: onEdit),
        if (onReset != null)
          EvButton(label: 'Reset password', small: true, onTap: onReset),
        if (onRemove != null)
          EvButton(label: 'Remove', small: true, danger: true, onTap: onRemove),
      ],
    );

    final hasTools = onEdit != null || onReset != null || onRemove != null;

    final emailCell = _EvInfoCell(
      icon: Icons.mail_outline_rounded,
      label: 'EMAIL',
      value: user.email.isEmpty ? '—' : user.email,
      onTap: user.email.isEmpty ? null : onEmail,
    );
    final mobileCell = _EvInfoCell(
      icon: Icons.call_outlined,
      label: 'MOBILE',
      value: mobile.isEmpty ? '—' : mobile,
      onTap: mobile.isEmpty ? null : onCall,
    );
    final reportingCell = _EvInfoCell(
      icon: Icons.person_outline_rounded,
      label: 'REPORTING / CREATED BY',
      value: reportingLabel,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: EmTokens.panelBg(context),
        borderRadius: BorderRadius.circular(EvTokens.radiusCard),
        border: Border.all(color: EmTokens.line(context)),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final narrow = c.maxWidth < 640;
          final wide = c.maxWidth >= 920;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (narrow) ...[
                identity,
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerLeft, child: login),
              ] else
                Row(
                  children: [
                    Expanded(child: identity),
                    const SizedBox(width: 12),
                    login,
                  ],
                ),
              const SizedBox(height: 16),
              Container(height: 1, color: EmTokens.line(context)),
              const SizedBox(height: 14),
              if (wide)
                Row(
                  children: [
                    Expanded(child: emailCell),
                    const SizedBox(width: 12),
                    Expanded(child: mobileCell),
                    const SizedBox(width: 12),
                    Expanded(child: reportingCell),
                    if (hasTools) ...[const SizedBox(width: 12), tools],
                  ],
                )
              else ...[
                if (narrow) ...[
                  emailCell,
                  const SizedBox(height: 12),
                  mobileCell,
                  const SizedBox(height: 12),
                  reportingCell,
                ] else
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(width: (c.maxWidth - 12) / 2, child: emailCell),
                      SizedBox(width: (c.maxWidth - 12) / 2, child: mobileCell),
                      SizedBox(
                        width: (c.maxWidth - 12) / 2,
                        child: reportingCell,
                      ),
                    ],
                  ),
                if (hasTools) ...[const SizedBox(height: 14), tools],
              ],
            ],
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Business segment
// -----------------------------------------------------------------------------

class EvBizSeg extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  /// Optional display labels keyed by option value.
  final Map<String, String> labels;

  const EvBizSeg({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.labels = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final o in options)
          _EvHover(
            onTap: () => onChanged(o),
            builder: (context, hovered) {
              final on = o == selected;
              return AnimatedContainer(
                duration: EvTokens.hover,
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on
                      ? EmTokens.green.withValues(alpha: 0.1)
                      : (hovered
                          ? EmTokens.soft(context)
                          : EmTokens.panelBg(context)),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: on
                        ? EmTokens.green.withValues(alpha: 0.45)
                        : EmTokens.line(context),
                  ),
                ),
                child: Text(
                  labels[o] ?? o,
                  style: EvTokens.text(
                    size: 12.5,
                    weight: FontWeight.w600,
                    color: on ? EmTokens.green : EmTokens.ink2(context),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// KPI grid
// -----------------------------------------------------------------------------

class EvKpiItem {
  final String title;
  final IconData icon;
  final String value;
  final String hint;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  /// Optional alternate value/hint revealed on hover (e.g. Rent / Re-Sale).
  final String? hoverValue;
  final String? hoverHint;

  const EvKpiItem({
    required this.title,
    required this.icon,
    required this.value,
    required this.hint,
    required this.color,
    this.selected = false,
    this.onTap,
    this.hoverValue,
    this.hoverHint,
  });
}

class _EvKpiCard extends StatelessWidget {
  final EvKpiItem item;
  const _EvKpiCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return _EvHover(
      onTap: item.onTap,
      builder: (context, hovered) {
        final active = hovered || item.selected;
        final showAlt = hovered && (item.hoverValue ?? '').isNotEmpty;
        final value = showAlt ? item.hoverValue! : item.value;
        final hint = showAlt ? (item.hoverHint ?? item.hint) : item.hint;
        return AnimatedContainer(
          duration: EvTokens.hover,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: EmTokens.panelBg(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? item.color : EmTokens.line(context),
              width: item.selected ? 1.6 : 1,
            ),
            boxShadow: hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : const [],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 34),
                    child: Text(
                      item.title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: EvTokens.text(
                        size: 10.5,
                        weight: FontWeight.w700,
                        letterSpacing: 0.52,
                        color: EmTokens.muted(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: EvTokens.text(
                        size: 24,
                        weight: FontWeight.w700,
                        color: EmTokens.ink(context),
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: EvTokens.text(
                      size: 11,
                      color: EmTokens.muted(context),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
              Positioned(
                right: -4,
                top: -2,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item.icon, size: 15, color: item.color),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class EvKpiGrid extends StatelessWidget {
  final List<EvKpiItem> items;

  const EvKpiGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 10.0;
        final cols = c.maxWidth >= 1080 ? 7 : (c.maxWidth >= 640 ? 4 : 2);
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: w,
                child: _EvKpiCard(item: item),
              ),
          ],
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Summary pair
// -----------------------------------------------------------------------------

class EvSummaryData {
  final IconData icon;
  final EvTone tone;
  final String label;
  final String value;
  final String caption;
  final VoidCallback? onTap;

  const EvSummaryData({
    required this.icon,
    required this.tone,
    required this.label,
    required this.value,
    required this.caption,
    this.onTap,
  });
}

class _EvSummary extends StatelessWidget {
  final EvSummaryData data;
  const _EvSummary({required this.data});

  @override
  Widget build(BuildContext context) {
    return _EvHover(
      onTap: data.onTap,
      builder: (context, hovered) => AnimatedContainer(
        duration: EvTokens.hover,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: EmTokens.panelBg(context),
          borderRadius: BorderRadius.circular(EvTokens.radiusCard),
          border: Border.all(
            color: hovered ? EvTokens.tone(data.tone) : EmTokens.line(context),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: EvTokens.toneBg(data.tone),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(data.icon, size: 19, color: EvTokens.tone(data.tone)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.label,
                    style: EvTokens.text(
                      size: 10.5,
                      weight: FontWeight.w700,
                      letterSpacing: 0.63,
                      color: EmTokens.muted(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: EvTokens.text(
                      size: 20,
                      weight: FontWeight.w700,
                      color: EmTokens.ink(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.caption,
                    style: EvTokens.text(
                      size: 12,
                      color: EmTokens.muted(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EvSummaryPair extends StatelessWidget {
  final EvSummaryData left;
  final EvSummaryData right;

  const EvSummaryPair({super.key, required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 700) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _EvSummary(data: left),
              const SizedBox(height: 12),
              _EvSummary(data: right),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _EvSummary(data: left)),
            const SizedBox(width: 16),
            Expanded(child: _EvSummary(data: right)),
          ],
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Card shell, chips, rows, empty, pager
// -----------------------------------------------------------------------------

class EvCardShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final List<Widget> children;

  const EvCardShell({
    super.key,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: EmTokens.panelBg(context),
        borderRadius: BorderRadius.circular(EvTokens.radiusCard),
        border: Border.all(color: EmTokens.line(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: EmTokens.line(context)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: EvTokens.text(
                          size: 14.5,
                          weight: FontWeight.w700,
                          color: EmTokens.ink(context),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: EvTokens.text(
                          size: 12,
                          color: EmTokens.muted(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (actionLabel != null) ...[
                  const SizedBox(width: 10),
                  EvButton(label: actionLabel!, small: true, onTap: onAction),
                ],
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class EvChipItem {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const EvChipItem({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });
}

class EvFilterChips extends StatelessWidget {
  final List<EvChipItem> items;

  const EvFilterChips({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: EmTokens.line(context))),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final item in items)
            _EvHover(
              onTap: item.onTap,
              builder: (context, hovered) {
                final on = item.selected;
                return AnimatedContainer(
                  duration: EvTokens.hover,
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  decoration: BoxDecoration(
                    color: on
                        ? EmTokens.green.withValues(alpha: 0.1)
                        : (hovered
                            ? EmTokens.soft(context)
                            : EmTokens.panelBg(context)),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: on
                          ? EmTokens.green.withValues(alpha: 0.45)
                          : EmTokens.line(context),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.label,
                        style: EvTokens.text(
                          size: 12,
                          weight: FontWeight.w600,
                          color: on ? EmTokens.green : EmTokens.ink2(context),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${item.count}',
                        style: EvTokens.text(
                          size: 10.5,
                          color: on ? EmTokens.green : EmTokens.muted(context),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class EvPropRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final String? priceSuffix;
  final VoidCallback? onTap;

  const EvPropRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.price,
    this.priceSuffix,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _EvHover(
      onTap: onTap,
      builder: (context, hovered) => AnimatedContainer(
        duration: EvTokens.hover,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: hovered
              ? EmTokens.soft(context).withValues(alpha: 0.5)
              : Colors.transparent,
          border: Border(bottom: BorderSide(color: EmTokens.line(context))),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: EmTokens.soft(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.home_work_outlined,
                size: 19,
                color: EmTokens.muted(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: EvTokens.text(
                      size: 13,
                      weight: FontWeight.w700,
                      color: EmTokens.ink(context),
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: EvTokens.text(
                      size: 11.5,
                      color: EmTokens.muted(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: EvTokens.text(
                    size: 13,
                    weight: FontWeight.w700,
                    color: EmTokens.ink(context),
                  ),
                ),
                if (priceSuffix != null)
                  Text(
                    priceSuffix!,
                    style: EvTokens.text(
                      size: 11.5,
                      color: EmTokens.muted(context),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EvLeadRow extends StatelessWidget {
  final String name;
  final String subtitle;
  final String budget;
  final String statusLabel;
  final EvTone statusTone;
  final EvTone avatarTone;
  final VoidCallback? onTap;

  const EvLeadRow({
    super.key,
    required this.name,
    required this.subtitle,
    required this.budget,
    required this.statusLabel,
    required this.statusTone,
    this.avatarTone = EvTone.green,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _EvHover(
      onTap: onTap,
      builder: (context, hovered) => AnimatedContainer(
        duration: EvTokens.hover,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: hovered
              ? EmTokens.soft(context).withValues(alpha: 0.5)
              : Colors.transparent,
          border: Border(bottom: BorderSide(color: EmTokens.line(context))),
        ),
        child: Row(
          children: [
            EvAvatar(
              name: name,
              size: 34,
              radius: 10,
              fontSize: 12,
              tone: avatarTone,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: EvTokens.text(
                      size: 13,
                      weight: FontWeight.w600,
                      color: EmTokens.ink(context),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: EvTokens.text(
                      size: 11.5,
                      color: EmTokens.muted(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  budget,
                  style: EvTokens.text(
                    size: 12.5,
                    weight: FontWeight.w700,
                    color: EmTokens.green,
                  ),
                ),
                const SizedBox(height: 5),
                EvBadge(label: statusLabel, tone: statusTone),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EvEmpty extends StatelessWidget {
  final String title;
  final String message;

  const EvEmpty({super.key, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 34),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: EvTokens.text(
              size: 13.5,
              weight: FontWeight.w700,
              color: EmTokens.ink(context),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            message,
            textAlign: TextAlign.center,
            style: EvTokens.text(size: 13, color: EmTokens.muted(context)),
          ),
        ],
      ),
    );
  }
}

/// Compact pager used under the properties / leads lists.
class EvPager extends StatelessWidget {
  final int total;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;

  const EvPager({
    super.key,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages = total == 0 ? 1 : (total / pageSize).ceil();
    final start = total == 0 ? 0 : (page - 1) * pageSize + 1;
    final end = (page * pageSize).clamp(0, total);
    final muted = EvTokens.text(size: 11.5, color: EmTokens.muted(context));

    Widget arrow(IconData icon, VoidCallback? onTap) => _EvHover(
          onTap: onTap,
          builder: (context, hovered) => Opacity(
            opacity: onTap == null ? 0.35 : 1,
            child: AnimatedContainer(
              duration: EvTokens.hover,
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: hovered && onTap != null
                    ? EmTokens.soft(context)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: EmTokens.ink2(context)),
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 6,
        spacing: 12,
        children: [
          Text('Showing $start–$end of $total', style: muted),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Rows ', style: muted),
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: pageSize,
                  isDense: true,
                  dropdownColor: EmTokens.panelBg(context),
                  icon: const Icon(Icons.arrow_drop_down_rounded, size: 18),
                  style: EvTokens.text(
                    size: 11.5,
                    weight: FontWeight.w600,
                    color: EmTokens.ink(context),
                  ),
                  items: const [
                    DropdownMenuItem(value: 10, child: Text('10')),
                    DropdownMenuItem(value: 15, child: Text('15')),
                  ],
                  onChanged: (v) {
                    if (v != null) onPageSizeChanged(v);
                  },
                ),
              ),
              const SizedBox(width: 6),
              arrow(
                Icons.chevron_left_rounded,
                page > 1 ? () => onPageChanged(page - 1) : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '$page / $totalPages',
                  style: EvTokens.text(
                    size: 11.5,
                    weight: FontWeight.w600,
                    color: EmTokens.ink(context),
                  ),
                ),
              ),
              arrow(
                Icons.chevron_right_rounded,
                page < totalPages ? () => onPageChanged(page + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
