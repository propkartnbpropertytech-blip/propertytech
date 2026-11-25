import 'package:flutter/material.dart';
import '../../../../core/design_system/tokens/app_typography.dart';
import '../../../../core/design_system/widgets/crm_network_image.dart';
import '../../models/user_model.dart';
import 'employees_tokens.dart';

class EmKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  final Color dot;
  final bool selected;
  final VoidCallback? onTap;

  const EmKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.hint,
    required this.dot,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: EmTokens.panelBg(context),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? EmTokens.green : EmTokens.line(context),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      label,
                      style: CRMTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: EmTokens.ink(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: CRMTypography.pageTitle.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: EmTokens.ink(context),
                  height: 1.1,
                ),
              ),
              Text(
                hint,
                style: CRMTypography.caption.copyWith(
                  fontSize: 11.5,
                  color: EmTokens.muted(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmLoginOffBanner extends StatelessWidget {
  final String names;
  final VoidCallback onShow;

  const EmLoginOffBanner({
    super.key,
    required this.names,
    required this.onShow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: EmTokens.amberBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EmTokens.amberLine),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded, color: EmTokens.amber, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: CRMTypography.body.copyWith(fontSize: 13, color: EmTokens.amberInk),
                children: [
                  TextSpan(
                    text: names,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: EmTokens.amberDeep),
                  ),
                  const TextSpan(text: " can’t log in right now."),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: onShow,
            style: TextButton.styleFrom(
              foregroundColor: EmTokens.amberDeep,
              backgroundColor: Colors.white,
              side: const BorderSide(color: EmTokens.amberLine),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Show them'),
          ),
        ],
      ),
    );
  }
}

class EmFilterChip extends StatelessWidget {
  final String label;
  final String? count;
  final bool selected;
  final VoidCallback onTap;

  const EmFilterChip({
    super.key,
    required this.label,
    this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? EmTokens.greenSoft : EmTokens.panelBg(context),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? EmTokens.green : EmTokens.line(context),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: CRMTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected ? EmTokens.green : EmTokens.ink(context),
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Text(
                  count!,
                  style: CRMTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: selected ? EmTokens.green : EmTokens.muted(context),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class EmRoleBadge extends StatelessWidget {
  final String role;
  const EmRoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: EmTokens.roleBg(role),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role,
        style: CRMTypography.caption.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
          color: EmTokens.roleColor(role),
        ),
      ),
    );
  }
}

class EmDetailPanel extends StatelessWidget {
  final UserModel user;
  final bool canEdit;
  final bool canDelete;
  final bool canToggle;
  final bool canOpen;
  final VoidCallback onCall;
  final VoidCallback onEdit;
  final VoidCallback onOpenProfile;
  final ValueChanged<bool> onToggleLogin;
  final VoidCallback onRemove;

  const EmDetailPanel({
    super.key,
    required this.user,
    required this.canEdit,
    required this.canDelete,
    required this.canToggle,
    required this.canOpen,
    required this.onCall,
    required this.onEdit,
    required this.onOpenProfile,
    required this.onToggleLogin,
    required this.onRemove,
  });

  String get _initials {
    final parts = user.fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final loginOn = user.isActive;
    return Container(
      decoration: BoxDecoration(
        color: EmTokens.panelBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EmTokens.line(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: EmTokens.soft(context).withValues(alpha: 0.45),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _avatar(context, 54, 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            style: CRMTypography.sectionTitle.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: EmTokens.ink(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              EmRoleBadge(role: user.roleName),
                              Text(
                                loginOn ? 'Can log in' : 'Login off',
                                style: CRMTypography.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: loginOn ? EmTokens.green : EmTokens.muted(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: user.mobile == null || user.mobile!.isEmpty ? null : onCall,
                        style: FilledButton.styleFrom(
                          backgroundColor: EmTokens.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Call'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: canEdit ? onEdit : null,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: EmTokens.line(context)),
                        ),
                        child: const Text('Edit details'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Contact', style: _sec(context)),
                _kv(context, 'Email', user.email),
                _kv(context, 'Mobile', user.mobile?.isNotEmpty == true ? user.mobile! : '—'),
                const SizedBox(height: 10),
                Text('Access', style: _sec(context)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: EmTokens.line(context)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Login access',
                              style: CRMTypography.body.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: EmTokens.ink(context),
                              ),
                            ),
                            Text(
                              'Can sign in and receive work',
                              style: CRMTypography.caption.copyWith(
                                fontSize: 11.5,
                                color: EmTokens.muted(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        key: ValueKey('em-login-panel-${user.id}'),
                        value: loginOn,
                        onChanged: canToggle ? onToggleLogin : null,
                        activeThumbColor: EmTokens.green,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (canOpen)
                  OutlinedButton(
                    onPressed: onOpenProfile,
                    child: const Text('Open full profile →'),
                  ),
                const SizedBox(height: 8),
                if (canDelete)
                  OutlinedButton(
                    onPressed: onRemove,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: EmTokens.redText,
                      side: BorderSide(color: EmTokens.redText.withValues(alpha: 0.35)),
                    ),
                    child: const Text('Remove employee'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(BuildContext context, double size, double fontSize) {
    final photo = user.profilePhoto;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: EmTokens.roleBg(user.roleName),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: photo != null && photo.isNotEmpty
          ? CrmNetworkImage(url: photo, width: size, height: size, fit: BoxFit.cover)
          : Text(
              _initials,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: EmTokens.roleColor(user.roleName),
              ),
            ),
    );
  }

  TextStyle _sec(BuildContext context) => CRMTypography.caption.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: EmTokens.muted(context),
      );

  Widget _kv(BuildContext context, String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(k, style: CRMTypography.body.copyWith(fontSize: 13, color: EmTokens.ink2(context))),
          ),
          Flexible(
            child: Text(
              v,
              textAlign: TextAlign.right,
              style: CRMTypography.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: EmTokens.ink(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmRoleSummaryCard extends StatelessWidget {
  final String title;
  final Color badgeColor;
  final Color badgeBg;
  final int count;
  final String blurb;
  final List<UserModel> people;
  final ValueChanged<UserModel>? onPersonTap;
  final Widget? emptyChild;

  const EmRoleSummaryCard({
    super.key,
    required this.title,
    required this.badgeColor,
    required this.badgeBg,
    required this.count,
    required this.blurb,
    required this.people,
    this.onPersonTap,
    this.emptyChild,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EmTokens.panelBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EmTokens.line(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(999)),
                child: Text(
                  title,
                  style: CRMTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$count',
                style: CRMTypography.pageTitle.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            blurb,
            style: CRMTypography.body.copyWith(fontSize: 12.5, color: EmTokens.ink2(context), height: 1.45),
          ),
          const SizedBox(height: 12),
          if (people.isEmpty)
            emptyChild ??
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: EmTokens.line(context)),
                  ),
                  child: Text(
                    'No one in this role yet.',
                    textAlign: TextAlign.center,
                    style: CRMTypography.caption.copyWith(color: EmTokens.muted(context)),
                  ),
                )
          else
            ...people.map((u) {
              final ini = u.fullName.trim().isEmpty
                  ? '?'
                  : u.fullName.trim().split(RegExp(r'\s+')).map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase();
              return Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Material(
                  color: EmTokens.soft(context),
                  borderRadius: BorderRadius.circular(9),
                  child: InkWell(
                    onTap: onPersonTap == null ? null : () => onPersonTap!(u),
                    borderRadius: BorderRadius.circular(9),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 13,
                            backgroundColor: badgeBg,
                            child: Text(
                              ini,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: badgeColor),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              u.fullName,
                              style: CRMTypography.body.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: u.isActive ? EmTokens.greenBright : const Color(0xFFD1D5DB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
