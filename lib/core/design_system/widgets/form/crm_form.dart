import 'package:flutter/material.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../dialogs.dart';

class CRMForm extends StatefulWidget {
  final Widget child;
  final GlobalKey<FormState> formKey;
  final Future<bool> Function() onSave;
  final VoidCallback? onCancel;
  final bool isSaving;
  final bool isDirty;
  final String title;

  const CRMForm({
    super.key,
    required this.child,
    required this.formKey,
    required this.onSave,
    this.onCancel,
    this.isSaving = false,
    this.isDirty = false,
    this.title = '',
  });

  @override
  State<CRMForm> createState() => _CRMFormState();
}

class _CRMFormState extends State<CRMForm> {
  Future<bool> _handlePop() async {
    if (!widget.isDirty || widget.isSaving) {
      return true;
    }

    final confirm = await CRMDialogs.showUnsavedChangesDialog(context);
    return confirm ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.isDirty || widget.isSaving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _handlePop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Stack(
        children: [
          Form(
            key: widget.formKey,
            child: FocusScope(
              child: widget.child,
            ),
          ),
          if (widget.isSaving)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

class CRMFormUtils {
  static bool validateAndScroll(GlobalKey<FormState> formKey, BuildContext context) {
    final isValid = formKey.currentState?.validate() ?? false;
    if (!isValid) {
      bool found = false;
      void visitor(Element element) {
        if (found) return;
        if (element.widget is FormField) {
          final state = (element as StatefulElement).state as FormFieldState;
          if (state.hasError) {
            found = true;
            Scrollable.ensureVisible(
              element,
              duration: const Duration(milliseconds: 300),
              alignment: 0.5,
            );
            return;
          }
        }
        element.visitChildren(visitor);
      }
      context.visitChildElements(visitor);
    }
    return isValid;
  }
}
