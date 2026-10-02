import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'mobile_actions.dart';
import 'mobile_layout.dart';

/// Layout-only form primitives. Fields, validation, payloads, and submit
/// logic stay in the existing feature forms.

/// "Step 2 of 4 · Location" header for multi-step forms.
class MobileFormStepHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String stepTitle;

  const MobileFormStepHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'Step $currentStep of $totalSteps, $stepTitle',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: CRMSpacing.xs),
        child: Text(
          'Step $currentStep of $totalSteps · $stepTitle',
          style: CRMTypography.cardTitle.copyWith(
            color: CRMColors.textOf(context),
          ),
        ),
      ),
    );
  }
}

/// Linear progress for multi-step forms. [currentStep] is 1-based.
class MobileFormProgress extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const MobileFormProgress({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final value =
        totalSteps <= 0 ? 0.0 : (currentStep / totalSteps).clamp(0.0, 1.0);
    return Semantics(
      label: 'Form progress',
      value: '${(value * 100).round()} percent',
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CRMBorderRadius.round),
        child: LinearProgressIndicator(
          value: value,
          minHeight: 4,
          backgroundColor: CRMColors.borderOf(context),
        ),
      ),
    );
  }
}

/// Titled group of fields.
class MobileFormSection extends StatelessWidget {
  final String? title;
  final String? description;
  final List<Widget> children;
  final double fieldSpacing;

  const MobileFormSection({
    super.key,
    this.title,
    this.description,
    required this.children,
    this.fieldSpacing = CRMSpacing.m,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CRMSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Semantics(
              header: true,
              child: Text(
                title!,
                style: CRMTypography.sectionTitle.copyWith(
                  color: CRMColors.textOf(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: CRMSpacing.xxs),
          ],
          if (description != null) ...[
            Text(
              description!,
              style: CRMTypography.caption.copyWith(
                color: CRMColors.textSecondaryOf(context),
              ),
            ),
            const SizedBox(height: CRMSpacing.xs),
          ],
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: fieldSpacing),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Back / Next-or-Save actions for forms, with saving and draft indication.
class MobileFormActions extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final String nextLabel;
  final String backLabel;
  final bool saving;
  final bool canProceed;

  /// Optional "Draft saved" style text shown above the buttons.
  final String? draftStatus;

  const MobileFormActions({
    super.key,
    this.onBack,
    required this.onNext,
    this.nextLabel = 'Next',
    this.backLabel = 'Back',
    this.saving = false,
    this.canProceed = true,
    this.draftStatus,
  });

  @override
  Widget build(BuildContext context) {
    final bar = MobileStickyActionBar(
      secondary: onBack == null
          ? null
          : MobileAction(
              label: backLabel,
              onPressed: onBack,
              enabled: !saving,
            ),
      primary: MobileAction(
        label: nextLabel,
        onPressed: onNext,
        loading: saving,
        enabled: canProceed,
      ),
    );
    if (draftStatus == null) return bar;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.only(bottom: CRMSpacing.xxs),
            child: Text(
              draftStatus!,
              style: CRMTypography.caption.copyWith(
                color: CRMColors.textSecondaryOf(context),
              ),
            ),
          ),
        ),
        bar,
      ],
    );
  }
}

/// Scaffold for mobile forms: optional step header and progress, scrollable
/// body that dismisses the keyboard on drag, and pinned [actions].
class MobileFormScaffold extends StatelessWidget {
  final Widget? stepHeader;
  final Widget? progress;
  final List<Widget> children;
  final Widget? actions;
  final GlobalKey<FormState>? formKey;
  final ScrollController? controller;

  const MobileFormScaffold({
    super.key,
    this.stepHeader,
    this.progress,
    required this.children,
    this.actions,
    this.formKey,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final horizontal = MobileLayout.horizontalPaddingOf(context);
    Widget body = SingleChildScrollView(
      controller: controller,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        horizontal,
        CRMSpacing.m,
        horizontal,
        CRMSpacing.l,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: MobileLayout.contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
    if (formKey != null) body = Form(key: formKey, child: body);

    return Column(
      children: [
        if (stepHeader != null || progress != null)
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontal,
              CRMSpacing.xs,
              horizontal,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ?stepHeader,
                ?progress,
              ],
            ),
          ),
        Expanded(child: body),
        ?actions,
      ],
    );
  }
}
