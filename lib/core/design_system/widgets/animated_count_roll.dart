import 'package:flutter/material.dart';

/// An animated rolling counter widget for KPI values.
/// Smoothly animates numbers up or down upon initial load or when value updates,
/// maintaining state so that unrelated parent rebuilds do NOT restart the animation.
class AnimatedCountRoll extends StatefulWidget {
  /// The value to display. Can be a number (int, double) or a string containing numbers.
  final dynamic value;

  /// Text style for the displayed value.
  final TextStyle? style;

  /// Duration of the roll animation.
  final Duration duration;

  /// Animation curve.
  final Curve curve;

  /// Optional prefix string (e.g. '₹').
  final String? prefix;

  /// Optional suffix string (e.g. '%', ' Leads').
  final String? suffix;

  /// Optional decimal places. If null, auto-detects from value.
  final int? decimalPlaces;

  const AnimatedCountRoll({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 550),
    this.curve = Curves.easeOutCubic,
    this.prefix,
    this.suffix,
    this.decimalPlaces,
  });

  @override
  State<AnimatedCountRoll> createState() => _AnimatedCountRollState();
}

class _AnimatedCountRollState extends State<AnimatedCountRoll> {
  double? _prevNumber;

  @override
  void initState() {
    super.initState();
    final parsed = _extractNumber(widget.value);
    _prevNumber = parsed?.number;
  }

  @override
  void didUpdateWidget(covariant AnimatedCountRoll oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldParsed = _extractNumber(oldWidget.value);
    if (oldParsed != null) {
      _prevNumber = oldParsed.number;
    }
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _extractNumber(widget.value);

    // If no numeric value can be parsed (e.g. "N/A" or "-"), render standard text
    if (parsed == null) {
      return Text(
        '${widget.prefix ?? ''}${widget.value?.toString() ?? '0'}${widget.suffix ?? ''}',
        style: _mergedStyle(context),
      );
    }

    final double targetNumber = parsed.number;
    final double startNumber = _prevNumber ?? targetNumber;
    final String derivedPrefix = widget.prefix ?? parsed.prefix;
    final String derivedSuffix = widget.suffix ?? parsed.suffix;
    final int decimals = widget.decimalPlaces ?? parsed.decimals;

    return TweenAnimationBuilder<double>(
      key: ValueKey(targetNumber),
      tween: Tween<double>(begin: startNumber, end: targetNumber),
      duration: widget.duration,
      curve: widget.curve,
      builder: (context, currentVal, child) {
        final formattedNumber = decimals > 0
            ? currentVal.toStringAsFixed(decimals)
            : currentVal.round().toString();

        return Text(
          '$derivedPrefix$formattedNumber$derivedSuffix',
          style: _mergedStyle(context),
        );
      },
    );
  }

  TextStyle _mergedStyle(BuildContext context) {
    final baseStyle =
        widget.style ?? Theme.of(context).textTheme.headlineMedium ?? const TextStyle();
    return baseStyle.copyWith(
      fontFeatures: [
        ...?baseStyle.fontFeatures,
        const FontFeature.tabularFigures(),
      ],
    );
  }

  static _ParsedNumber? _extractNumber(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) {
      final isInt = raw is int || raw == raw.roundToDouble();
      return _ParsedNumber(
        number: raw.toDouble(),
        prefix: '',
        suffix: '',
        decimals: isInt ? 0 : 1,
      );
    }

    final str = raw.toString().trim();
    if (str.isEmpty) return null;

    // Regular expression to match prefix, number (with optional decimals/commas), and suffix
    final regex = RegExp(r'^([^0-9.-]*)([0-9,]+(?:\.[0-9]+)?)(.*)$');
    final match = regex.firstMatch(str);

    if (match == null) return null;

    final prefix = match.group(1) ?? '';
    final numStr = (match.group(2) ?? '').replaceAll(',', '');
    final suffix = match.group(3) ?? '';

    final number = double.tryParse(numStr);
    if (number == null) return null;

    final decimals = numStr.contains('.') ? numStr.split('.').last.length : 0;

    return _ParsedNumber(
      number: number,
      prefix: prefix,
      suffix: suffix,
      decimals: decimals,
    );
  }
}

class _ParsedNumber {
  final double number;
  final String prefix;
  final String suffix;
  final int decimals;

  _ParsedNumber({
    required this.number,
    required this.prefix,
    required this.suffix,
    required this.decimals,
  });
}
