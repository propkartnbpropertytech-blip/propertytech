import 'package:flutter/material.dart';

import '../../../core/design_system/tokens/app_spacing.dart';

/// Header field for AI Search. One 12px corner, the same radius as the suggestion panel.
class AiSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onOpened;
  final VoidCallback? onClear;
  final bool dense;
  final bool autofocus;

  const AiSearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onOpened,
    this.onClear,
    this.dense = false,
    this.autofocus = false,
  });

  static const placeholder = 'Search or ask anything in PropKart…';
  static const radius = CRMBorderRadius.input;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E);
    final text = dark ? const Color(0xFFF8FAFC) : const Color(0xFF14213D);
    final listenables = <Listenable>[?controller, ?focusNode];
    if (listenables.isEmpty) return _field(context, accent, text, dark, false, false);
    return ListenableBuilder(
      listenable: Listenable.merge(listenables),
      builder: (context, _) => _field(
        context,
        accent,
        text,
        dark,
        controller?.text.isNotEmpty ?? false,
        focusNode?.hasFocus ?? false,
      ),
    );
  }

  Widget _field(BuildContext context, Color accent, Color text, bool dark, bool hasText, bool focused) {
    final fill = dark ? const Color(0xFF1E293B) : Colors.white;
    final violet = dark ? const Color(0xFFA5B4FC) : const Color(0xFF6366F1);
    return Semantics(
      textField: true,
      label: 'AI Search',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: dense ? 40 : 42,
        padding: EdgeInsets.all(focused ? 1.5 : 1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(colors: focused ? [accent, violet] : [accent, accent]),
          boxShadow: focused
              ? [BoxShadow(color: violet.withValues(alpha: dark ? 0.35 : 0.22), blurRadius: 14, spreadRadius: 0.5)]
              : const [],
        ),
        child: Container(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(radius - 1),
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          onTap: onOpened,
          autofocus: autofocus,
          style: TextStyle(fontSize: 13.5, color: text),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(
              color: dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              fontSize: dense ? 12.5 : 13,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 10, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (rect) => LinearGradient(colors: [accent, violet]).createShader(rect),
                    child: const Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'AI Search',
                    style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 108, minHeight: 36),
            suffixIcon: hasText
                ? IconButton(
                    tooltip: 'Clear search',
                    onPressed: onClear,
                    icon: Icon(Icons.close_rounded, size: 18, color: accent),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: dense ? 9 : 10, horizontal: 8),
            isDense: true,
          ),
        ),
        ),
      ),
    );
  }
}
