import 'package:flutter/material.dart';

import '../../../core/design_system/tokens/app_colors.dart';
import '../models/property_model.dart';
import '../services/property_sharing_controller.dart';

/// Quick per-property ON/OFF control on property cards: whether this property is
/// visible to other Admins and their employees (subject to the Admin-level Rent/Resale
/// sharing and the Super Admin switches).
class PropertyShareCardToggle extends StatelessWidget {
  final PropertyModel property;

  const PropertyShareCardToggle({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final sharing = PropertySharingController.instance;
    return ListenableBuilder(
      listenable: sharing,
      builder: (context, _) {
        if (!sharing.canToggleProperty(property)) return const SizedBox.shrink();

        final isRent = property.listingTypeName.toLowerCase().contains('rent');
        final typeLabel = isRent ? 'Rent' : 'Resale';
        final shared = sharing.isPropertyShared(property.id);
        final saving = sharing.isSavingProperty(property.id);
        final color = shared ? CRMColors.primaryOf(context) : CRMColors.textSecondaryOf(context);

        return Tooltip(
          message: 'Share This $typeLabel Property with Other Admins',
          child: Container(
            height: 28,
            padding: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(shared ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  'Share $typeLabel',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                ),
                SizedBox(
                  height: 28,
                  child: FittedBox(
                    child: Switch(
                      value: shared,
                      activeTrackColor: CRMColors.primaryOf(context),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: saving
                          ? null
                          : (value) async {
                              final messenger = ScaffoldMessenger.of(context);
                              final ok = await sharing.setPropertyShared(property.id, value);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(ok
                                      ? (value
                                          ? 'Property is now visible to other Admins.'
                                          : 'Property is now hidden from other Admins.')
                                      : 'Could not update property visibility. Please try again.'),
                                  backgroundColor: ok ? CRMColors.success : CRMColors.danger,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
