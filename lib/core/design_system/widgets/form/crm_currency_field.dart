import 'package:flutter/material.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';
import '../../../utils/formatters.dart';
import '../../../utils/validators.dart';
import 'crm_amount_preview.dart';

class CRMCurrencyField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final FormFieldValidator<String>? validator;
  final bool isRequired;
  final bool enabled;

  const CRMCurrencyField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText = 'e.g. 5,00,000',
    this.validator,
    this.isRequired = false,
    this.enabled = true,
  });

  @override
  State<CRMCurrencyField> createState() => _CRMCurrencyFieldState();
}

class _CRMCurrencyFieldState extends State<CRMCurrencyField> {
  late String _currentText;

  @override
  void initState() {
    super.initState();
    _currentText = widget.controller.text;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {
        _currentText = widget.controller.text;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.labelText}${widget.isRequired ? " *" : ""}',
          style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondaryOf(context)),
        ),
        const SizedBox(height: CRMSpacing.xs),
        TextFormField(
          controller: widget.controller,
          enabled: widget.enabled,
          keyboardType: TextInputType.number,
          inputFormatters: [
            IndianCurrencyFormatter(),
          ],
          style: CRMTypography.body.copyWith(
            color: widget.enabled ? CRMColors.textOf(context) : CRMColors.textMutedOf(context),
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: CRMTypography.body.copyWith(color: CRMColors.textMutedOf(context)),
            prefixIcon: Icon(
              Icons.currency_rupee_rounded,
              color: CRMColors.textMutedOf(context),
              size: 20,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: CRMSpacing.m,
              vertical: CRMSpacing.s,
            ),
            filled: true,
            fillColor: widget.enabled ? CRMColors.cardBgOf(context) : CRMColors.background,
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
          validator: widget.isRequired
              ? (v) => CRMValidators.required(v, message: '${widget.labelText} is required')
              : widget.validator,
        ),
        CRMAmountPreview(valueText: _currentText),
      ],
    );
  }
}
