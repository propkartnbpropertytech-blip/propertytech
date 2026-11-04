import 'package:flutter/material.dart';

import '../../../core/design_system/tokens/app_colors.dart';
import '../models/property_model.dart';
import '../services/property_sharing_controller.dart';

/// Shows the owner Admin's name and company on a property shared by another Admin.
class SharedPropertyAdminBadge extends StatelessWidget {
  final PropertyModel property;
  final double bottomSpacing;

  const SharedPropertyAdminBadge({super.key, required this.property, this.bottomSpacing = 0});

  @override
  Widget build(BuildContext context) {
    final sharing = PropertySharingController.instance;
    return ListenableBuilder(
      listenable: sharing,
      builder: (context, _) {
        final name = sharing.sharedAdminNameFor(property);
        if (name == null) return const SizedBox.shrink();
        final company = sharing.sharedAdminCompanyFor(property);
        const color = CRMColors.info;
        const textStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color);

        Widget part(IconData icon, String text) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: textStyle),
                ),
              ],
            );

        final badge = Tooltip(
          message: company == null ? 'Admin: $name' : 'Admin: $name\nCompany: $company',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                part(Icons.admin_panel_settings_outlined, 'Admin: $name'),
                if (company != null) ...[
                  Container(
                    width: 1,
                    height: 14,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: color.withValues(alpha: 0.35),
                  ),
                  part(Icons.business_outlined, 'Company: $company'),
                ],
              ],
            ),
          ),
        );
        return bottomSpacing > 0
            ? Padding(padding: EdgeInsets.only(bottom: bottomSpacing), child: badge)
            : badge;
      },
    );
  }
}
