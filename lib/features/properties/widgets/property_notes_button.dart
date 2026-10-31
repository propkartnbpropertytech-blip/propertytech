import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/design_system/crm_design_system.dart';
import '../../../core/design_system/widgets/app_status_snackbar.dart';
import '../../../core/security/permission_matrix_service.dart';
import '../../../core/security/role_guard.dart';
import '../models/property_model.dart';
import '../services/property_notes_controller.dart';

/// Property card link: "+ Add Notes" when the property has no notes, otherwise "View Notes".
class PropertyNotesButton extends StatelessWidget {
  final PropertyModel property;

  /// Spacing applied only while the link is visible (hidden when "Add Notes" is turned off).
  final double topSpacing;
  final double trailingSpacing;

  const PropertyNotesButton({
    super.key,
    required this.property,
    this.topSpacing = 0,
    this.trailingSpacing = 0,
  });

  static const permissionKey = 'page.properties.notes';

  @override
  Widget build(BuildContext context) {
    if (property.id.isEmpty || property.id.startsWith('temp_')) return const SizedBox.shrink();
    final notes = PropertyNotesController.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([notes, PermissionMatrixService.instance]),
      builder: (context, _) {
        notes.ensureCount(property.id);
        final allowed = notes.enabled &&
            PermissionMatrixService.instance.isActionAllowed(RoleGuard.currentUser?.role, permissionKey);
        if (!allowed) return const SizedBox.shrink();
        final hasNotes = (notes.countFor(property.id) ?? 0) > 0;
        return Padding(
          padding: EdgeInsets.only(top: topSpacing, right: trailingSpacing),
          child: Builder(
          builder: (anchorContext) => InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () => showPropertyNotesPopover(anchorContext, property, hasNotes: hasNotes),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                hasNotes ? 'View Notes' : '+ Add Notes',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  color: hasNotes ? CRMColors.primaryOf(context) : CRMColors.textOf(context),
                ),
              ),
            ),
          ),
          ),
        );
      },
    );
  }
}

/// Anchored notes popover (bottom sheet on narrow screens) for viewing, adding and deleting notes.
Future<void> showPropertyNotesPopover(
  BuildContext anchorContext,
  PropertyModel property, {
  required bool hasNotes,
}) async {
  final screen = MediaQuery.sizeOf(anchorContext);
  if (screen.width < 600) {
    await showModalBottomSheet<void>(
      context: anchorContext,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: CRMColors.cardBgOf(anchorContext),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: screen.height * 0.8),
          child: _PropertyNotesPanel(property: property, startWithNotes: hasNotes),
        ),
      ),
    );
    return;
  }

  final box = anchorContext.findRenderObject() as RenderBox?;
  if (box == null || !box.attached) return;
  final anchor = box.localToGlobal(Offset.zero) & box.size;
  await showGeneralDialog<void>(
    context: anchorContext,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: 'Close notes',
    barrierColor: Colors.black.withValues(alpha: 0.15),
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (_, _, _) => _NotesPopoverLayout(
      anchor: anchor,
      child: _PropertyNotesPanel(property: property, startWithNotes: hasNotes),
    ),
    transitionBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
  );
}

class _NotesPopoverLayout extends StatelessWidget {
  final Rect anchor;
  final Widget child;

  const _NotesPopoverLayout({required this.anchor, required this.child});

  @override
  Widget build(BuildContext context) {
    const margin = 16.0;
    const arrowHeight = 10.0;
    final screen = MediaQuery.sizeOf(context);
    final width = (screen.width - margin * 2).clamp(260.0, 360.0);

    double left = anchor.center.dx - width / 2;
    if (left + width > screen.width - margin) left = screen.width - width - margin;
    if (left < margin) left = margin;
    final arrowLeft = (anchor.center.dx - left - 10).clamp(16.0, width - 36);

    final spaceBelow = screen.height - anchor.bottom - margin - arrowHeight - 4;
    final spaceAbove = anchor.top - margin - arrowHeight - 4;
    final showAbove = spaceBelow < 320 && spaceAbove > spaceBelow;
    final maxHeight = (showAbove ? spaceAbove : spaceBelow).clamp(200.0, 560.0);
    final cardColor = CRMColors.cardBgOf(context);

    final arrow = Padding(
      padding: EdgeInsets.only(left: arrowLeft),
      child: CustomPaint(
        size: const Size(20, arrowHeight),
        painter: _PopoverArrowPainter(color: cardColor, pointingDown: showAbove),
      ),
    );

    return Stack(
      children: [
        Positioned(
          left: left,
          top: showAbove ? null : anchor.bottom + 4,
          bottom: showAbove ? screen.height - anchor.top + 4 : null,
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!showAbove) arrow,
                Container(
                  width: width,
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: child,
                ),
                if (showAbove) arrow,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PopoverArrowPainter extends CustomPainter {
  final Color color;
  final bool pointingDown;

  const _PopoverArrowPainter({required this.color, this.pointingDown = false});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (pointingDown) {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0);
    } else {
      path
        ..moveTo(0, size.height)
        ..lineTo(size.width / 2, 0)
        ..lineTo(size.width, size.height);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PopoverArrowPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.pointingDown != pointingDown;
}

class _PropertyNotesPanel extends StatefulWidget {
  final PropertyModel property;
  final bool startWithNotes;

  const _PropertyNotesPanel({required this.property, required this.startWithNotes});

  @override
  State<_PropertyNotesPanel> createState() => _PropertyNotesPanelState();
}

class _PropertyNotesPanelState extends State<_PropertyNotesPanel> {
  final _noteController = TextEditingController();
  List<PropertyNote> _notes = const [];
  late bool _loading = widget.startWithNotes;
  String? _loadError;
  bool _saving = false;
  final Set<String> _deleting = {};
  String? _confirmDeleteId;

  bool get _hasText => _noteController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (widget.startWithNotes) _load();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final notes = await PropertyNotesController.instance.fetchNotes(widget.property.id);
      if (!mounted) return;
      setState(() {
        _notes = notes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = PropertyNotesController.errorMessage(e, 'Could not load notes. Please try again.');
      });
    }
  }

  Future<void> _save() async {
    final text = _noteController.text.trim();
    if (text.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final created = await PropertyNotesController.instance.addNote(widget.property.id, text);
      if (!mounted) return;
      AppStatusSnackBar.show(context, message: 'Note added successfully', icon: Icons.check_circle_rounded);
      if (!widget.startWithNotes && _notes.isEmpty) {
        Navigator.of(context).pop();
        return;
      }
      setState(() {
        _saving = false;
        _notes = [created, ..._notes];
        _noteController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppStatusSnackBar.show(
        context,
        message: PropertyNotesController.errorMessage(e, 'Could not add note. Please try again.'),
        isSuccess: false,
      );
    }
  }

  Future<void> _delete(PropertyNote note) async {
    setState(() {
      _confirmDeleteId = null;
      _deleting.add(note.id);
    });
    try {
      await PropertyNotesController.instance.deleteNote(widget.property.id, note.id);
      if (!mounted) return;
      AppStatusSnackBar.show(context, message: 'Note deleted successfully', icon: Icons.delete_outline_rounded);
      setState(() {
        _deleting.remove(note.id);
        _notes = _notes.where((n) => n.id != note.id).toList();
      });
      if (_notes.isEmpty) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting.remove(note.id));
      AppStatusSnackBar.show(
        context,
        message: PropertyNotesController.errorMessage(e, 'Could not delete note. Please try again.'),
        isSuccess: false,
      );
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  Widget _buildHeader(BuildContext context) {
    final showList = widget.startWithNotes || _notes.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 6, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              showList ? 'Notes${_notes.isNotEmpty ? ' (${_notes.length})' : ''}' : '+ Add Note',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: CRMColors.textOf(context)),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close_rounded, size: 20, color: CRMColors.textMutedOf(context)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteTile(BuildContext context, PropertyNote n) {
    final primary = CRMColors.primaryOf(context);
    final deleting = _deleting.contains(n.id);
    final confirming = _confirmDeleteId == n.id;
    final subtitle = [n.createdByRole, n.companyName].where((s) => s.isNotEmpty).join(' • ');
    final date = n.createdAt != null ? DateFormat("dd MMM ''yy, h:mm a").format(n.createdAt!.toLocal()) : '';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: confirming
            ? CRMColors.danger.withValues(alpha: 0.05)
            : (Theme.of(context).brightness == Brightness.dark ? Colors.black12 : Colors.white),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: confirming
              ? CRMColors.danger.withValues(alpha: 0.4)
              : CRMColors.borderOf(context).withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: primary.withValues(alpha: 0.12),
                child: Text(
                  _initials(n.createdByName),
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: primary),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.createdByName.isNotEmpty ? n.createdByName : 'Unknown user',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: CRMColors.textOf(context)),
                    ),
                    if (subtitle.isNotEmpty || date.isNotEmpty)
                      Text(
                        [subtitle, date].where((s) => s.isNotEmpty).join(' • '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10.5, color: CRMColors.textMutedOf(context)),
                      ),
                  ],
                ),
              ),
              if (n.canDelete)
                deleting
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Delete note',
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: CRMColors.danger),
                        onPressed: () => setState(() => _confirmDeleteId = confirming ? null : n.id),
                      ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 36, right: 8, top: 6),
            child: SelectableText(
              n.note,
              style: TextStyle(fontSize: 13, height: 1.4, color: CRMColors.textOf(context)),
            ),
          ),
          if (confirming)
            Padding(
              padding: const EdgeInsets.only(left: 36, right: 8, top: 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Delete this note?',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CRMColors.danger),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _confirmDeleteId = null),
                    child: Text('Cancel', style: TextStyle(fontSize: 12, color: CRMColors.textOf(context))),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CRMColors.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _delete(n),
                    child: const Text('Delete', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotesList(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(_loadError!, style: const TextStyle(fontSize: 12, color: CRMColors.danger)),
            ),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_notes.isEmpty) return const SizedBox.shrink();
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      itemCount: _notes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _buildNoteTile(context, _notes[index]),
    );
  }

  Widget _buildComposer(BuildContext context) {
    final showList = widget.startWithNotes || _notes.isNotEmpty;
    final primary = CRMColors.primaryOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showList) ...[
            Text(
              '+ Add Note',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: CRMColors.textOf(context)),
            ),
            const SizedBox(height: 8),
          ],
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.black12 : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: CRMColors.borderOf(context).withValues(alpha: 0.6)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: TextField(
              controller: _noteController,
              autofocus: !widget.startWithNotes,
              enabled: !_saving,
              minLines: 2,
              maxLines: 4,
              maxLength: PropertyNotesController.maxNoteLength,
              onChanged: (_) => setState(() {}),
              style: TextStyle(fontSize: 13, color: CRMColors.textOf(context)),
              decoration: InputDecoration(
                hintText: 'Type your note here...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: CRMColors.textSecondaryOf(context).withValues(alpha: 0.6),
                ),
                border: InputBorder.none,
                isDense: true,
                counterText: '',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _saving
                    ? null
                    : () {
                        _noteController.clear();
                        setState(() {});
                      },
                child: Text(
                  'Clear',
                  style: TextStyle(color: CRMColors.textOf(context), fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFA0AEC0).withValues(alpha: 0.35),
                  disabledForegroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: (_saving || !_hasText) ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showList = widget.startWithNotes || _notes.isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context),
        if (showList) ...[
          Flexible(child: _buildNotesList(context)),
          Divider(height: 1, color: CRMColors.borderOf(context).withValues(alpha: 0.6)),
        ],
        _buildComposer(context),
      ],
    );
  }
}
