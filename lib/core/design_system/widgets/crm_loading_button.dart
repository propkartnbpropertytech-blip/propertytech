import 'package:flutter/material.dart';
import 'buttons.dart';

class CRMLoadingButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? prefixIcon;
  final double? width;
  final CRMButtonVariant variant;

  const CRMLoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.prefixIcon,
    this.width,
    this.variant = CRMButtonVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    return CRMButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      prefixIcon: prefixIcon,
      width: width,
      variant: variant,
    );
  }
}
