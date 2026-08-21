import 'package:flutter/material.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';
import '../../../utils/validators.dart';

class CRMNotesField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final int maxLines;
  final bool isRequired;
  final bool enabled;

  const CRMNotesField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText = 'Enter detailed notes...',
    this.maxLines = 4,
    this.isRequired = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${labelText}${isRequired ? " *" : ""}',
          style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondaryOf(context)),
        ),
        const SizedBox(height: CRMSpacing.xs),
        TextFormField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          style: CRMTypography.body.copyWith(
            color: enabled ? CRMColors.textOf(context) : CRMColors.textMutedOf(context),
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: CRMTypography.body.copyWith(color: CRMColors.textMutedOf(context)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: CRMSpacing.m,
              vertical: CRMSpacing.m,
            ),
            filled: true,
            fillColor: enabled ? CRMColors.cardBgOf(context) : CRMColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              borderSide: BorderSide(color: CRMColors.borderOf(context), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              borderSide: BorderSide(color: CRMColors.borderOf(context), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              borderSide: BorderSide(color: CRMColors.primaryOf(context), width: 1.5),
            ),
          ),
          validator: isRequired
              ? (v) => CRMValidators.required(v, message: '${labelText} is required')
              : null,
        ),
      ],
    );
  }
}
