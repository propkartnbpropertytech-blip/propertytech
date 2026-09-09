import 'package:flutter/material.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_typography.dart';
import '../../../utils/currency.dart';

class CRMAmountPreview extends StatelessWidget {
  final String valueText;

  const CRMAmountPreview({
    super.key,
    required this.valueText,
  });

  @override
  Widget build(BuildContext context) {
    if (valueText.trim().isEmpty) return const SizedBox.shrink();
    
    final formattedWords = CRMCurrencyFormatter.previewInputText(valueText);
    if (formattedWords.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4.0, left: 4.0),
      child: Text(
        formattedWords,
        style: CRMTypography.captionBold.copyWith(
          color: CRMColors.primaryOf(context),
        ),
      ),
    );
  }
}
