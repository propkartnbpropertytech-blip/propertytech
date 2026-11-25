import 'package:flutter/material.dart';
import '../../../../core/design_system/tokens/app_breakpoints.dart';
import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../core/design_system/tokens/app_typography.dart';
import 'support_tokens.dart';

class SuHeroBanner extends StatelessWidget {
  final VoidCallback? onRaiseTicket;

  const SuHeroBanner({super.key, this.onRaiseTicket});

  @override
  Widget build(BuildContext context) {
    final narrow = CRMBreakpoints.isPhone(context);
    final title = Text(
      'Need help? We’re here.',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: CRMTypography.pageTitle.copyWith(
        fontSize: narrow ? 20 : 22,
        fontWeight: FontWeight.w700,
        color: SuTokens.ink(context),
      ),
    );
    final subtitle = Text(
      'Report a problem or ask a question — the PropKart support team usually replies within 2 working hours.',
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: CRMTypography.body.copyWith(fontSize: 13, color: SuTokens.muted(context)),
    );

    final cta = onRaiseTicket == null
        ? null
        : FilledButton.icon(
            onPressed: onRaiseTicket,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Raise a ticket'),
            style: FilledButton.styleFrom(
              backgroundColor: SuTokens.green,
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: narrow ? 16 : 22, vertical: narrow ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [SuTokens.greenBgOf(context), SuTokens.panel(context)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: const [0, 0.6],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SuTokens.line(context)),
      ),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: 4),
                subtitle,
                if (cta != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, child: cta),
                ],
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      const SizedBox(height: 4),
                      subtitle,
                    ],
                  ),
                ),
                if (cta != null) ...[
                  const SizedBox(width: 12),
                  cta,
                ],
              ],
            ),
    );
  }
}

class SuKpiStrip extends StatelessWidget {
  final int total;
  final int open;
  final int inProgress;
  final int complete;
  final String selected; // all | Open | In Progress | Complete
  final ValueChanged<String> onSelected;

  const SuKpiStrip({
    super.key,
    required this.total,
    required this.open,
    required this.inProgress,
    required this.complete,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      ('all', 'Total tickets', total, Icons.confirmation_number_outlined),
      ('Open', 'Open', open, Icons.fiber_new_rounded),
      ('In Progress', 'In progress', inProgress, Icons.hourglass_top_rounded),
      ('Complete', 'Complete', complete, Icons.check_circle_outline_rounded),
    ];

    final narrow = CRMBreakpoints.widthOf(context) < 900;
    if (narrow) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: items
            .map(
              (e) => SizedBox(
                width: (CRMBreakpoints.widthOf(context) - CRMBreakpoints.pagePadding(context) * 2 - 12) / 2,
                child: _card(context, e.$1, e.$2, e.$3, e.$4),
              ),
            )
            .toList(),
      );
    }

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: _card(context, items[i].$1, items[i].$2, items[i].$3, items[i].$4)),
        ],
      ],
    );
  }

  Widget _card(BuildContext context, String key, String label, int value, IconData icon) {
    final on = selected == key;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onSelected(key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: SuTokens.panel(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: on ? SuTokens.green2 : SuTokens.line(context)),
            boxShadow: on
                ? [
                    BoxShadow(
                      color: SuTokens.greenBg.withValues(alpha: 0.9),
                      blurRadius: 0,
                      spreadRadius: 3,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: SuTokens.greenBgOf(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: SuTokens.greenTextOf(context)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CRMTypography.caption.copyWith(fontSize: 12, color: SuTokens.muted(context)),
                    ),
                    Text(
                      '$value',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CRMTypography.sectionTitle.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: SuTokens.ink(context),
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

class SuContactWays extends StatelessWidget {
  final VoidCallback onWhatsApp;
  final VoidCallback onCall;
  final VoidCallback onEmail;

  const SuContactWays({
    super.key,
    required this.onWhatsApp,
    required this.onCall,
    required this.onEmail,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.chat_rounded, SuTokens.whatsappBg, SuTokens.whatsappFg, 'WhatsApp support', 'Fastest · Mon–Sat, 9:30 AM – 7 PM', onWhatsApp),
      (Icons.call_rounded, SuTokens.callBg, SuTokens.callFg, 'Call us', '+91 79 0000 0000', onCall),
      (Icons.mail_outline_rounded, SuTokens.emailBg, SuTokens.emailFg, 'Email', 'support@nbpropertytech.com', onEmail),
    ];

    final narrow = CRMBreakpoints.widthOf(context) < 900;
    final cards = items
        .map(
          (e) => _way(
            context,
            icon: e.$1,
            bg: e.$2,
            fg: e.$3,
            title: e.$4,
            subtitle: e.$5,
            onTap: e.$6,
          ),
        )
        .toList();

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
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: cards[i]),
        ],
      ],
    );
  }

  Widget _way(
    BuildContext context, {
    required IconData icon,
    required Color bg,
    required Color fg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: SuTokens.panel(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SuTokens.line(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: fg, size: 20),
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
                      style: CRMTypography.bodyMedium.copyWith(fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: CRMTypography.caption.copyWith(fontSize: 12, color: SuTokens.muted(context)),
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

class SuCardShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry? bodyPadding;

  const SuCardShell({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.bodyPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: SuTokens.panel(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SuTokens.line(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CRMTypography.bodyMedium.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: SuTokens.ink(context),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: CRMTypography.caption.copyWith(fontSize: 12, color: SuTokens.muted(context)),
                        ),
                      ],
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          Divider(height: 1, color: SuTokens.line(context)),
          Padding(
            padding: bodyPadding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class SuPriorityPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const SuPriorityPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Low', 'Low · can wait', SuTokens.green),
      ('Medium', 'Medium', SuTokens.amber),
      ('High', 'High · blocking work', SuTokens.red),
    ];

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _chip(context, items[i].$1, items[i].$2, items[i].$3),
          ),
        ],
      ],
    );
  }

  Widget _chip(BuildContext context, String key, String label, Color color) {
    final on = selected == key;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () => onChanged(key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 36,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: on ? color.withValues(alpha: 0.1) : SuTokens.panel(context),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: on ? color : SuTokens.line(context)),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: CRMTypography.captionBold.copyWith(
              fontSize: 12,
              color: on ? color : SuTokens.ink2(context),
            ),
          ),
        ),
      ),
    );
  }
}

class SuTicketRow extends StatelessWidget {
  final String subject;
  final String meta;
  final String status;
  final String priority;
  final Color statusColor;
  final Color priorityColor;
  final VoidCallback onTap;

  const SuTicketRow({
    super.key,
    required this.subject,
    required this.meta,
    required this.status,
    required this.priority,
    required this.statusColor,
    required this.priorityColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: SuTokens.line(context))),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: CRMTypography.bodyMedium.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: SuTokens.ink(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      meta,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: CRMTypography.caption.copyWith(fontSize: 12, color: SuTokens.muted(context)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      status,
                      style: CRMTypography.captionBold.copyWith(fontSize: 11, color: statusColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    priority,
                    style: CRMTypography.captionBold.copyWith(fontSize: 12, color: priorityColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SuFaqSection extends StatelessWidget {
  const SuFaqSection({super.key});

  static const _items = [
    (
      'How do I give a salesperson more leads?',
      'Go to Lead Allocation → Configure and raise their share, or assign leads by hand from the Leads page.',
    ),
    (
      'A teammate can’t log in',
      'Open Employees → Password requests, or turn on Login access for that person.',
    ),
    (
      'How do I restore a deleted property?',
      'Open the Recycle Bin, find it under Properties and click Restore. Items stay for 30 days.',
    ),
    (
      'Why do some leads show “Other area”?',
      'The area in the lead form didn’t match your list. Add it in Settings → Locations.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SuCardShell(
      title: 'Quick answers',
      bodyPadding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
      child: Column(
        children: [
          for (final item in _items)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 10),
                title: Text(
                  item.$1,
                  style: CRMTypography.bodyMedium.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item.$2,
                      style: CRMTypography.body.copyWith(
                        fontSize: 13,
                        color: SuTokens.ink2(context),
                        height: 1.5,
                      ),
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

InputDecoration suFieldDecoration(BuildContext context, {String? hint, Widget? prefixIcon}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: CRMTypography.caption.copyWith(color: SuTokens.muted(context)),
    prefixIcon: prefixIcon,
    filled: true,
    fillColor: SuTokens.panel(context),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: SuTokens.line(context)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: SuTokens.line(context)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: SuTokens.green),
    ),
  );
}
