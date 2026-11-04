import 'package:flutter/material.dart';

import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/security/role_guard.dart';
import '../services/property_sharing_controller.dart';

/// Admin-only "Share Rent / Resale Properties with Other Admins" switch shown beside + Add Property.
/// Only the switch for the active listing tab ([isRent]) is shown.
/// Other Admins see the shared properties only when Super Admin has also enabled cross-Admin
/// visibility for the listing type and the individual property is shared.
class ShareMyPropertiesToggle extends StatefulWidget {
  final bool compact;
  final bool isRent;

  const ShareMyPropertiesToggle({super.key, this.compact = false, required this.isRent});

  @override
  State<ShareMyPropertiesToggle> createState() => _ShareMyPropertiesToggleState();
}

class _ShareMyPropertiesToggleState extends State<ShareMyPropertiesToggle> {
  static const _rentLabel = 'Share Rent Properties with Other Admins';
  static const _resaleLabel = 'Share Resale Properties with Other Admins';

  final _sharing = PropertySharingController.instance;

  bool get _isAdmin => RoleGuard.currentUser?.role == 'Admin';

  @override
  void initState() {
    super.initState();
    if (_isAdmin) _sharing.load();
  }

  Future<void> _update(BuildContext context, {bool? rent, bool? resale}) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await _sharing.setAdminShare(rent: rent, resale: resale);
    final typeLabel = rent != null ? 'Rent' : 'Resale';
    final value = rent ?? resale ?? false;
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok
            ? (value
                ? 'Your $typeLabel properties are now shared with other Admins.'
                : 'Your $typeLabel properties are now hidden from other Admins.')
            : 'Could not update property sharing. Please try again.'),
        backgroundColor: ok ? CRMColors.success : CRMColors.danger,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _switch(BuildContext context, bool value, ValueChanged<bool> onChanged) {
    return Transform.scale(
      scale: 0.8,
      child: Switch(
        value: value,
        activeTrackColor: CRMColors.primaryOf(context),
        onChanged: _sharing.savingAdminShare ? null : onChanged,
      ),
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => ListenableBuilder(
        listenable: _sharing,
        builder: (sheetContext, _) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isRent)
                SwitchListTile(
                  title: const Text(_rentLabel, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  value: _sharing.shareRent,
                  onChanged: _sharing.savingAdminShare ? null : (v) => _update(sheetContext, rent: v),
                )
              else
                SwitchListTile(
                  title: const Text(_resaleLabel, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  value: _sharing.shareResale,
                  onChanged: _sharing.savingAdminShare ? null : (v) => _update(sheetContext, resale: v),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: _sharing,
      builder: (context, _) {
        if (!_sharing.canManage) return const SizedBox.shrink();

        final isRent = widget.isRent;
        final shared = isRent ? _sharing.shareRent : _sharing.shareResale;

        if (widget.compact) {
          return IconButton(
            tooltip: isRent ? _rentLabel : _resaleLabel,
            icon: Icon(
              Icons.share_outlined,
              size: 20,
              color: shared ? CRMColors.primaryOf(context) : CRMColors.textSecondaryOf(context),
            ),
            onPressed: () => _openSheet(context),
          );
        }

        final labelStyle = TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: CRMColors.textOf(context),
        );

        return Container(
          height: 40,
          padding: const EdgeInsets.only(left: 12, right: 4),
          decoration: BoxDecoration(
            color: CRMColors.cardBgOf(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: CRMColors.borderOf(context)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.share_outlined, size: 16, color: CRMColors.textSecondaryOf(context)),
              const SizedBox(width: 8),
              Text('Share with Other Admins:', style: labelStyle),
              const SizedBox(width: 8),
              Tooltip(
                message: isRent ? _rentLabel : _resaleLabel,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(isRent ? 'Rent' : 'Resale', style: labelStyle),
                    _switch(
                      context,
                      shared,
                      (v) => isRent ? _update(context, rent: v) : _update(context, resale: v),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
