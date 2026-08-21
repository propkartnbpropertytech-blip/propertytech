import 'package:flutter/material.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';
import '../../../utils/dates.dart';
import '../../../utils/validators.dart';

class CRMDatePicker extends StatefulWidget {
  final String labelText;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime> onDateSelected;
  final bool isRequired;
  final bool enabled;

  const CRMDatePicker({
    super.key,
    required this.labelText,
    required this.onDateSelected,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.isRequired = false,
    this.enabled = true,
  });

  @override
  State<CRMDatePicker> createState() => _CRMDatePickerState();
}

class _CRMDatePickerState extends State<CRMDatePicker> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  Future<void> _pickDate() async {
    if (!widget.enabled) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: widget.firstDate ?? DateTime(2020),
      lastDate: widget.lastDate ?? DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: CRMColors.primaryOf(context),
              onPrimary: Colors.white,
              onSurface: CRMColors.textOf(context),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      widget.onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayText = _selectedDate != null ? CRMDatesHelper.formatDate(_selectedDate) : 'Select Date';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.labelText}${widget.isRequired ? " *" : ""}',
          style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondaryOf(context)),
        ),
        const SizedBox(height: CRMSpacing.xs),
        InkWell(
          onTap: widget.enabled ? _pickDate : null,
          borderRadius: BorderRadius.circular(CRMBorderRadius.s),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: CRMSpacing.m,
              vertical: CRMSpacing.s + 4,
            ),
            decoration: BoxDecoration(
              color: widget.enabled ? CRMColors.cardBgOf(context) : CRMColors.background,
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              border: Border.all(color: CRMColors.borderOf(context), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  displayText,
                  style: CRMTypography.body.copyWith(
                    color: _selectedDate != null
                        ? CRMColors.textOf(context)
                        : CRMColors.textMutedOf(context),
                  ),
                ),
                Icon(
                  Icons.calendar_month_rounded,
                  color: CRMColors.textMutedOf(context),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
