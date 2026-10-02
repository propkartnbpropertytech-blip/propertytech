import 'dart:async';

import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'mobile_layout.dart';
import 'mobile_states.dart';
import 'mobile_touch.dart';

enum MobileSearchStatus {
  idle,

  /// Query edited, debounce pending; previous results (or idle) stay visible.
  typing,
  loading,
  results,
  empty,
  error,
}

/// Full-screen search chrome. Data source, debounce, and results belong to the
/// calling surface (DR-018); this widget stores no search history.
class MobileSearch extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String>? onSubmitted;

  /// The surface's existing debounce. Zero means no debounce.
  final Duration debounce;
  final MobileSearchStatus status;
  final Widget? results;
  final Widget? idleState;
  final Widget? emptyState;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;
  final VoidCallback? onFilterTap;
  final int activeFilterCount;
  final TextEditingController? controller;
  final bool autofocus;

  /// False renders only the search row, for use as a pinned header above a
  /// screen's own list (the screen then shows results/empty/error itself).
  final bool showResultsBody;

  const MobileSearch({
    super.key,
    required this.hintText,
    required this.onQueryChanged,
    this.onSubmitted,
    this.debounce = Duration.zero,
    this.status = MobileSearchStatus.idle,
    this.results,
    this.idleState,
    this.emptyState,
    this.onRetry,
    this.onBack,
    this.onFilterTap,
    this.activeFilterCount = 0,
    this.controller,
    this.autofocus = true,
    this.showResultsBody = true,
  });

  @override
  State<MobileSearch> createState() => _MobileSearchState();
}

class _MobileSearchState extends State<MobileSearch> {
  late final TextEditingController _controller;
  Timer? _debounce;

  bool get _ownsController => widget.controller == null;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  void _emit(String value) {
    _debounce?.cancel();
    if (widget.debounce == Duration.zero) {
      widget.onQueryChanged(value);
      return;
    }
    _debounce = Timer(widget.debounce, () => widget.onQueryChanged(value));
  }

  void _clear() {
    _controller.clear();
    _debounce?.cancel();
    widget.onQueryChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final field = _buildField(context);
    if (!widget.showResultsBody) return field;
    return Column(
      children: [
        field,
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CRMSpacing.xxs,
        vertical: CRMSpacing.xs,
      ),
      child: Row(
        children: [
          if (widget.onBack != null)
            MobileIconAction(
              icon: Icons.arrow_back_rounded,
              label: 'Back',
              onPressed: widget.onBack,
            ),
          Expanded(
            child: SizedBox(
              height: MobileLayout.minTouchTarget,
              child: TextField(
                controller: _controller,
                autofocus: widget.autofocus,
                textInputAction: TextInputAction.search,
                onChanged: _emit,
                onSubmitted: widget.onSubmitted,
                style: CRMTypography.body.copyWith(
                  color: CRMColors.textOf(context),
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  isDense: true,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : MobileIconAction(
                          icon: Icons.close_rounded,
                          label: 'Clear search',
                          iconSize: 20,
                          onPressed: _clear,
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(CRMBorderRadius.input),
                  ),
                ),
              ),
            ),
          ),
          if (widget.onFilterTap != null)
            MobileIconAction(
              icon: Icons.tune_rounded,
              label: 'Filters',
              badgeCount: widget.activeFilterCount,
              onPressed: widget.onFilterTap,
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (widget.status) {
      case MobileSearchStatus.idle:
        return widget.idleState ?? const SizedBox.shrink();
      case MobileSearchStatus.typing:
        return widget.results ?? widget.idleState ?? const SizedBox.shrink();
      case MobileSearchStatus.loading:
        return const SingleChildScrollView(
          padding: EdgeInsets.all(CRMSpacing.m),
          child: MobileLoadingState(),
        );
      case MobileSearchStatus.results:
        return widget.results ?? const SizedBox.shrink();
      case MobileSearchStatus.empty:
        return widget.emptyState ??
            MobileEmptyState(
              icon: Icons.search_off_rounded,
              title: 'No matches',
              actionLabel: 'Clear',
              onAction: _clear,
            );
      case MobileSearchStatus.error:
        return MobileErrorState(onRetry: widget.onRetry);
    }
  }
}
