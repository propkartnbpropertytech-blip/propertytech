import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme_manager.dart';
import '../../../core/security/role_guard.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../models/dashboard_summary.dart';
import '../services/dashboard_service.dart';

class PersonalNoteItem {
  final String id;
  final String content;
  final DateTime createdAt;
  final bool isCompleted;

  PersonalNoteItem({
    required this.id,
    required this.content,
    required this.createdAt,
    this.isCompleted = false,
  });

  PersonalNoteItem copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    bool? isCompleted,
  }) {
    return PersonalNoteItem(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'isCompleted': isCompleted,
      };

  factory PersonalNoteItem.fromJson(Map<String, dynamic> json) {
    return PersonalNoteItem(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: json['content']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      isCompleted: json['is_completed'] as bool? ?? json['isCompleted'] as bool? ?? json['completed'] as bool? ?? false,
    );
  }
}

class TodaysScheduleCard extends StatefulWidget {
  final List<DashboardSiteVisit>? siteVisits;
  final VoidCallback? onViewCalendar;
  final Function(DashboardSiteVisit)? onSiteVisitTap;
  final Function(DashboardSiteVisit)? onAddVisit;

  const TodaysScheduleCard({
    super.key,
    this.siteVisits,
    this.onViewCalendar,
    this.onSiteVisitTap,
    this.onAddVisit,
  });

  @override
  State<TodaysScheduleCard> createState() => _TodaysScheduleCardState();
}

class _TodaysScheduleCardState extends State<TodaysScheduleCard> {
  List<PersonalNoteItem> _notes = [];
  bool _isLoading = true;
  String? _currentUserId;
  int _currentPage = 1;
  static const int _notesPerPage = 3;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = _getUserId(context);
    if (_currentUserId != userId) {
      _currentUserId = userId;
      _loadNotes();
    }
  }

  String _getUserId(BuildContext context) {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        if (authState.user.id.isNotEmpty) return authState.user.id;
        if (authState.user.email.isNotEmpty) return authState.user.email;
      }
    } catch (_) {}

    final currentUser = RoleGuard.currentUser;
    if (currentUser != null) {
      if (currentUser.id.isNotEmpty) return currentUser.id;
      if (currentUser.email.isNotEmpty) return currentUser.email;
    }

    return 'guest_user';
  }

  Future<void> _loadNotes() async {
    final userId = _getUserId(context);
    _currentUserId = userId;

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final remoteNotesJson = await DashboardService().getDashboardNotes();
      final loadedNotes = remoteNotesJson
          .map((item) => PersonalNoteItem.fromJson(item))
          .toList();

      if (mounted) {
        setState(() {
          _notes = loadedNotes;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addNote(String text) async {
    if (text.trim().isEmpty) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final newNote = PersonalNoteItem(
      id: tempId,
      content: text.trim(),
      createdAt: DateTime.now(),
      isCompleted: false,
    );

    setState(() {
      _notes.insert(0, newNote);
      _currentPage = 1;
    });

    final createdData = await DashboardService().createDashboardNote(text.trim());
    if (createdData != null && mounted) {
      final createdNote = PersonalNoteItem.fromJson(createdData);
      setState(() {
        final index = _notes.indexWhere((n) => n.id == tempId);
        if (index != -1) {
          _notes[index] = createdNote;
        }
      });
    }
  }

  void _toggleNoteCompletion(String id) async {
    final index = _notes.indexWhere((note) => note.id == id);
    if (index != -1) {
      final target = _notes[index];
      final newStatus = !target.isCompleted;

      setState(() {
        _notes[index] = target.copyWith(isCompleted: newStatus);
      });

      if (!id.startsWith('temp_')) {
        await DashboardService().updateDashboardNote(id, isCompleted: newStatus);
      }
    }
  }

  void _deleteNote(String id) async {
    setState(() {
      _notes.removeWhere((note) => note.id == id);
      final totalPages = (_notes.length / _notesPerPage).ceil();
      if (_currentPage > totalPages && totalPages >= 1) {
        _currentPage = totalPages;
      }
    });

    if (!id.startsWith('temp_')) {
      await DashboardService().deleteDashboardNote(id);
    }
  }

  void _showAddNoteDialog(BuildContext context) {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = ThemeManager().isDarkMode;
        final primaryColor = ThemeManager().primaryColor;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          child: Container(
            width: 440,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.edit_note_rounded,
                          color: primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Add Note',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF14213D),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'This note is personal and will only be visible to you.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  maxLines: 4,
                  autofocus: true,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Write your note here...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: primaryColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final text = noteController.text.trim();
                        if (text.isNotEmpty) {
                          _addNote(text);
                          Navigator.pop(ctx);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Save Note'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);

    final timeStr = DateFormat('hh:mm a').format(dt);
    if (date.isAtSameMomentAs(today)) {
      return 'Today · $timeStr';
    } else if (date.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      return 'Yesterday · $timeStr';
    } else {
      return DateFormat('dd MMM yyyy · hh:mm a').format(dt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = ThemeManager().primaryColor;

    final totalNotes = _notes.length;
    final totalPages = (totalNotes / _notesPerPage).ceil();
    final currentPage = _currentPage.clamp(1, totalPages > 0 ? totalPages : 1);
    final startIndex = (currentPage - 1) * _notesPerPage;
    final endIndex = (startIndex + _notesPerPage).clamp(0, totalNotes);
    final pageNotes = (startIndex < totalNotes)
        ? _notes.sublist(startIndex, endIndex)
        : <PersonalNoteItem>[];

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        final userId = _getUserId(context);
        if (_currentUserId != userId) {
          _currentUserId = userId;
          _loadNotes();
        }
      },
      child: Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card Header ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      size: 22,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Note',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFF8FAFC)
                            : const Color(0xFF14213D),
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (_notes.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF243044)
                              : const Color(0xFFF1F4F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_notes.length}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF68738A),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                InkWell(
                  onTap: () => _showAddNoteDialog(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          size: 16,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Add',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2),
          ),

          // ── Notes List / Empty State ─────────────────────────
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_notes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sticky_note_2_outlined,
                      size: 38,
                      color: const Color(0xFF68738A).withValues(alpha: 0.35),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No notes added yet',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFFF8FAFC)
                            : const Color(0xFF14213D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Click + Add to create your personal note.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF68738A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pageNotes.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2),
              ),
              itemBuilder: (context, index) {
                final note = pageNotes[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Checkbox on exact left side
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: note.isCompleted,
                            activeColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                              width: 1.5,
                            ),
                            onChanged: (_) => _toggleNoteCompletion(note.id),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableText(
                              note.content,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: note.isCompleted
                                    ? (isDark
                                        ? const Color(0xFF64748B)
                                        : const Color(0xFF94A3B8))
                                    : (isDark
                                        ? const Color(0xFFF8FAFC)
                                        : const Color(0xFF14213D)),
                                decoration: note.isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                decorationColor: isDark
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF94A3B8),
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(note.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                        ),
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF94A3B8),
                        hoverColor: Colors.redAccent.withValues(alpha: 0.1),
                        splashRadius: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        tooltip: 'Delete note',
                        onPressed: () => _deleteNote(note.id),
                      ),
                    ],
                  ),
                );
              },
            ),

          // ── Pagination Footer (Max 3 notes per page) ───────
          if (_notes.isNotEmpty) ...[
            Divider(
              height: 1,
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Page $currentPage of ${totalPages > 0 ? totalPages : 1}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, size: 20),
                        onPressed: currentPage > 1
                            ? () => setState(() => _currentPage--)
                            : null,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        splashRadius: 18,
                        color: isDark
                            ? const Color(0xFFF8FAFC)
                            : const Color(0xFF14213D),
                        disabledColor: isDark
                            ? const Color(0xFF475569)
                            : const Color(0xFFCBD5E1),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, size: 20),
                        onPressed: currentPage < totalPages
                            ? () => setState(() => _currentPage++)
                            : null,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        splashRadius: 18,
                        color: isDark
                            ? const Color(0xFFF8FAFC)
                            : const Color(0xFF14213D),
                        disabledColor: isDark
                            ? const Color(0xFF475569)
                            : const Color(0xFFCBD5E1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
  }
}
