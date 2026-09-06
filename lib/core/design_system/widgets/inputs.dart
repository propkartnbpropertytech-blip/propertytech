import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

class CRMTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool readOnly;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;
  final int? maxLength;
  final int? maxLines;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final VoidCallback? onTap;

  const CRMTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.readOnly = false,
    this.suffixIcon,
    this.validator,
    this.maxLength,
    this.maxLines = 1,
    this.onChanged,
    this.focusNode,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(CRMBorderRadius.input);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: CRMTypography.label.copyWith(
            color: CRMColors.textSecondaryOf(context),
          ),
        ),
        const SizedBox(height: CRMSpacing.xs),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          obscureText: obscureText,
          readOnly: readOnly,
          onTap: onTap,
          style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: CRMTypography.body.copyWith(
              color: CRMColors.textMutedOf(context),
            ),
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: CRMColors.textMutedOf(context),
                    size: 20,
                  )
                : null,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: CRMSpacing.m,
              vertical: CRMSpacing.s,
            ),
            filled: true,
            fillColor: CRMColors.cardBgOf(context),
            border: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: CRMColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: CRMColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(
                color: CRMColors.primaryOf(context),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(color: CRMColors.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(color: CRMColors.danger, width: 1.5),
            ),
          ),
          validator: validator,
          maxLength: maxLength,
          maxLines: maxLines,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
