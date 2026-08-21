import 'package:flutter/material.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';

class CRMTimePicker extends StatefulWidget {
  final String labelText;
  final TimeOfDay? initialTime;
  final ValueChanged<TimeOfDay> onTimeSelected;
  final bool isRequired;
  final bool enabled;

  const CRMTimePicker({
    super.key,
    required this.labelText,
    required this.onTimeSelected,
    this.initialTime,
    this.isRequired = false,
    this.enabled = true,
  });

  @override
  State<CRMTimePicker> createState() => _CRMTimePickerState();
}

class _CRMTimePickerState extends State<CRMTimePicker> {
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initialTime;
  }

  Future<void> _pickTime() async {
    if (!widget.enabled) return;

    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
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
        _selectedTime = picked;
      });
      widget.onTimeSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayText = _selectedTime != null ? _selectedTime!.format(context) : 'Select Time';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.labelText}${widget.isRequired ? " *" : ""}',
          style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondaryOf(context)),
        ),
        const SizedBox(height: CRMSpacing.xs),
        InkWell(
          onTap: widget.enabled ? _pickTime : null,
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
                    color: _selectedTime != null
                        ? CRMColors.textOf(context)
                        : CRMColors.textMutedOf(context),
                  ),
                ),
                Icon(
                  Icons.access_time_rounded,
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
