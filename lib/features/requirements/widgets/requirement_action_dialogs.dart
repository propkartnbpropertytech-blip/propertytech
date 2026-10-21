import 'package:flutter/material.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/app_status_snackbar.dart';
import '../models/requirement_model.dart';
import '../repository/requirements_repository.dart';

/// Reusable modals and action dialogs for requirement leads (status transitions, notes, win/lost reasons).
class RequirementActionDialogs {
  /// Prompts user to select a new pipeline status for a requirement lead.
  static Future<String?> showStatusDialog(
    BuildContext context, {
    required RequirementModel requirement,
    required List<String> availableStatuses,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.swap_horiz_rounded, color: CRMColors.primaryOf(context), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Update Status: ${requirement.clientName}',
                  style: CRMTypography.headline.copyWith(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: availableStatuses.map((status) {
                final isCurrent = requirement.status.toLowerCase() == status.toLowerCase();
                return ListTile(
                  dense: true,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  title: Text(
                    status,
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? CRMColors.primaryOf(context) : CRMColors.textOf(context),
                    ),
                  ),
                  trailing: isCurrent ? Icon(Icons.check, color: CRMColors.primaryOf(context), size: 18) : null,
                  onTap: () => Navigator.pop(ctx, status),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  /// Displays notes viewer and input dialog for a requirement lead.
  static Future<void> showNotesDialog(
    BuildContext context, {
    required RequirementModel requirement,
    required RequirementsRepository repository,
    VoidCallback? onNoteAdded,
  }) async {
    final textController = TextEditingController();
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.notes_rounded, color: CRMColors.primaryOf(context), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Lead Notes — ${requirement.clientName}',
                  style: CRMTypography.headline.copyWith(fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (requirement.notes != null && requirement.notes!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: CRMColors.backgroundOf(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CRMColors.borderOf(context)),
                    ),
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: SingleChildScrollView(
                      child: Text(
                        requirement.notes!,
                        style: TextStyle(fontSize: 12.5, color: CRMColors.textOf(context)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: textController,
                  maxLines: 3,
                  style: TextStyle(fontSize: 13, color: CRMColors.textOf(context)),
                  decoration: InputDecoration(
                    hintText: 'Add an internal note or observation...',
                    hintStyle: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(context)),
                    filled: true,
                    fillColor: CRMColors.backgroundOf(context),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final note = textController.text.trim();
                      if (note.isEmpty) return;

                      setState(() => isSaving = true);
                      try {
                        await repository.addRequirementNote(requirement.id, note);
                        if (dialogCtx.mounted) {
                          Navigator.pop(dialogCtx);
                          AppStatusSnackBar.show(
                            context,
                            message: 'Note saved successfully.',
                            isSuccess: true,
                          );
                          onNoteAdded?.call();
                        }
                      } catch (e) {
                        setState(() => isSaving = false);
                        if (dialogCtx.mounted) {
                          AppStatusSnackBar.show(
                            context,
                            message: 'Failed to save note: $e',
                            isSuccess: false,
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Add Note'),
            ),
          ],
        ),
      ),
    );
    textController.dispose();
  }
}
