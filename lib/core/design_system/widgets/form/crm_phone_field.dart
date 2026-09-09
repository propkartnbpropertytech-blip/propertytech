import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:intl_phone_field/countries.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';
import '../../../utils/validators.dart';

class CRMPhoneField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final FormFieldValidator<String>? validator;
  final bool isRequired;
  final bool enabled;
  final ValueChanged<PhoneNumber>? onChanged;

  const CRMPhoneField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText = '9567354680',
    this.validator,
    this.isRequired = false,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$labelText${isRequired ? " *" : ""}',
          style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondaryOf(context)),
        ),
        const SizedBox(height: CRMSpacing.xs),
        IntlPhoneField(
          controller: controller,
          enabled: enabled,
          keyboardType: TextInputType.phone,
          style: CRMTypography.body.copyWith(
            color: enabled ? CRMColors.textOf(context) : CRMColors.textMutedOf(context),
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: CRMTypography.body.copyWith(color: CRMColors.textMutedOf(context)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: CRMSpacing.m,
              vertical: CRMSpacing.s,
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
            counterText: '',
          ),
          initialCountryCode: 'IN',
          countries: [countries.firstWhere((c) => c.code == 'IN')],
          disableLengthCheck: true,
          dropdownTextStyle: CRMTypography.body.copyWith(
            color: CRMColors.textOf(context),
            fontWeight: FontWeight.w600,
          ),
          flagsButtonPadding: const EdgeInsets.only(left: CRMSpacing.s),
          dropdownIconPosition: IconPosition.trailing,
          showCountryFlag: false,
          showDropdownIcon: false,
          onChanged: (phone) {
            onChanged?.call(phone);
          },
          validator: (v) {
            if (isRequired) {
              if (v == null || v.number.trim().isEmpty) {
                return '$labelText is required';
              }
              return CRMValidators.indianMobile(v.number);
            }
            return validator?.call(v?.number ?? '');
          },
        ),
      ],
    );
  }
}
