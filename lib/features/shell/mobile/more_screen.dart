import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/mobile/mobile_layout.dart';
import '../../../core/design_system/mobile/mobile_list.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/security/role_guard.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../settings/screens/sync_debug_screen.dart';
import '../../telecaller/widgets/telecaller_availability_toggle.dart';
import 'mobile_app_shell.dart';
import 'mobile_nav_config.dart';

/// `/more` route: profile header plus the role's permitted secondary
/// destinations. Reads identity from [AuthBloc]; grants nothing itself.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is Authenticated ? authState.user : RoleGuard.currentUser;
    final role = user?.role;
    final badges = MobileShellBadges.maybeOf(context);

    return MobileMoreView(
      name: user?.fullName ?? '',
      email: user?.email ?? '',
      role: role ?? '',
      sections: MobileNavConfig.moreForRole(role),
      badges: {'messages': badges?.unreadMessages ?? 0},
      shiftControl: RoleGuard.isTelecaller(role)
          ? const TelecallerAvailabilityToggle(compact: true)
          : null,
      onOpen: (entry) {
        switch (entry.target) {
          case MobileMoreTarget.route:
            context.go(entry.route);
          case MobileMoreTarget.syncDiagnostics:
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SyncDebugScreen()),
            );
        }
      },
    );
  }
}

/// Pure presentation of the More screen, testable without blocs.
class MobileMoreView extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final List<MobileMoreSection> sections;
  final Widget? shiftControl;
  final Map<String, int> badges;
  final ValueChanged<MobileMoreEntry> onOpen;

  const MobileMoreView({
    super.key,
    required this.name,
    required this.email,
    required this.role,
    required this.sections,
    required this.onOpen,
    this.shiftControl,
    this.badges = const {},
  });

  @override
  Widget build(BuildContext context) {
    final horizontal = MobileLayout.horizontalPaddingOf(context);
    return ListView(
      padding: const EdgeInsets.only(bottom: CRMSpacing.l),
      children: [
        Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: MobileLayout.contentMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfileHeader(
                  name: name,
                  email: email,
                  role: role,
                  horizontalPadding: horizontal,
                ),
                if (shiftControl != null) ...[
                  const MobileSectionHeader(title: 'Shift'),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontal),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: shiftControl,
                    ),
                  ),
                ],
                for (final section in sections) ...[
                  MobileSectionHeader(title: section.title),
                  for (final entry in section.entries)
                    MobileListItem(
                      key: ValueKey('more_${entry.id}'),
                      icon: entry.icon,
                      title: entry.label,
                      badgeCount: badges[entry.id] ?? 0,
                      onTap: () => onOpen(entry),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final double horizontalPadding;

  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.role,
    required this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) {
    final primary = CRMColors.primaryOf(context);
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Semantics(
      container: true,
      label: [name, role, email].where((s) => s.isNotEmpty).join(', '),
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          CRMSpacing.m,
          horizontalPadding,
          0,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: primary.withValues(alpha: 0.12),
              child: Text(
                initial,
                style: CRMTypography.cardTitle.copyWith(color: primary),
              ),
            ),
            const SizedBox(width: CRMSpacing.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'Signed in' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CRMTypography.cardTitle.copyWith(
                      color: CRMColors.textOf(context),
                    ),
                  ),
                  if (role.isNotEmpty || email.isNotEmpty)
                    Text(
                      [role, email].where((s) => s.isNotEmpty).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CRMTypography.caption.copyWith(
                        color: CRMColors.textSecondaryOf(context),
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
