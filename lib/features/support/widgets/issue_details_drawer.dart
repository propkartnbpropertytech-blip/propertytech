import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/security/role_guard.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/theme/theme_manager.dart';
import '../models/support_issue_model.dart';
import '../services/support_service.dart';

class IssueDetailsDrawer extends StatefulWidget {
  final String issueId;
  final VoidCallback onUpdated;

  const IssueDetailsDrawer({
    super.key,
    required this.issueId,
    required this.onUpdated,
  });

  @override
  State<IssueDetailsDrawer> createState() => _IssueDetailsDrawerState();
}

class _IssueDetailsDrawerState extends State<IssueDetailsDrawer> {
  bool _isLoading = true;
  SupportIssue? _issue;

  final TextEditingController _commentController = TextEditingController();
  bool _isInternalNote = false;
  bool _isSendingComment = false;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _loadIssueDetails();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadIssueDetails() async {
    setState(() => _isLoading = true);
    final data = await SupportService.instance.fetchIssueById(widget.issueId);
    if (mounted) {
      setState(() {
        _issue = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSendingComment = true);
    try {
      await SupportService.instance.addComment(
        widget.issueId,
        text,
        isInternalNote: _isInternalNote,
      );
      _commentController.clear();
      await _loadIssueDetails();
      widget.onUpdated();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post reply: $e'), backgroundColor: CRMColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingComment = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_issue == null) return;
    setState(() => _isUpdatingStatus = true);
    try {
      await SupportService.instance.updateIssue(widget.issueId, status: newStatus);
      await _loadIssueDetails();
      widget.onUpdated();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: CRMColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  Future<void> _updatePriority(String newPriority) async {
    if (_issue == null) return;
    setState(() => _isUpdatingStatus = true);
    try {
      await SupportService.instance.updateIssue(widget.issueId, priority: newPriority);
      await _loadIssueDetails();
      widget.onUpdated();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update priority: $e'), backgroundColor: CRMColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return const Color(0xFF3B82F6);
      case 'in progress':
        return const Color(0xFFF59E0B);
      case 'waiting for user':
        return const Color(0xFF8B5CF6);
      case 'resolved':
        return const Color(0xFF10B981);
      case 'closed':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return const Color(0xFFEF4444);
      case 'high':
        return const Color(0xFFF97316);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'low':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = ThemeManager().primaryColor;
    final isSuperAdmin = RoleGuard.isSuperAdmin(RoleGuard.currentUser?.role);

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 780,
        constraints: const BoxConstraints(maxHeight: 800),
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _issue == null
                ? const Center(child: Text('Support ticket not found.'))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _issue!.ticketNumber,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryColor),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_issue!.pageName} -> ${_issue!.functionName}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Reported by ${_issue!.reporterName} (${_issue!.reporterRole}) on ${DateFormat('MMM d, yyyy h:mm a').format(_issue!.createdAt)}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 14),

                      // Status & Priority Bar (Controls for Super Admin)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            if (_isUpdatingStatus)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                              ),
                            const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                            if (isSuperAdmin)
                              DropdownButton<String>(
                                value: _issue!.status,
                                isDense: true,
                                underline: const SizedBox.shrink(),
                                items: const ['Open', 'In Progress', 'Waiting for User', 'Resolved', 'Closed']
                                    .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12.5))))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) _updateStatus(val);
                                },
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(_issue!.status).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _issue!.status,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _getStatusColor(_issue!.status)),
                                ),
                              ),

                            const Spacer(),

                            // Priority Badge / Dropdown
                            const Text('Priority: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                            if (isSuperAdmin)
                              DropdownButton<String>(
                                value: _issue!.priority,
                                isDense: true,
                                underline: const SizedBox.shrink(),
                                items: const ['Low', 'Medium', 'High', 'Critical']
                                    .map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 12.5))))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) _updatePriority(val);
                                },
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(_issue!.priority).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _issue!.priority,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _getPriorityColor(_issue!.priority)),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Main Details Tabs / Split View
                      Expanded(
                        child: DefaultTabController(
                          length: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TabBar(
                                labelColor: primaryColor,
                                unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                indicatorColor: primaryColor,
                                tabs: const [
                                  Tab(text: 'Issue Description'),
                                  Tab(text: 'Replies & Discussion'),
                                  Tab(text: 'Diagnostic Timeline'),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: TabBarView(
                                  children: [
                                    _buildDescriptionTab(isDark, primaryColor),
                                    _buildRepliesTab(isDark, primaryColor, isSuperAdmin),
                                    _buildTimelineTab(isDark, primaryColor),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildDescriptionTab(bool isDark, Color primaryColor) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Issue Type Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Issue Category: ${_issue!.issueType}',
              style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 14),

          // Description Text
          const Text('Detailed Description:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Text(
              _issue!.description,
              style: TextStyle(fontSize: 13, height: 1.4, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
          const SizedBox(height: 16),

          // Attachments Section
          if (_issue!.attachments.isNotEmpty) ...[
            const Text('Attachments & Screenshots:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Column(
              children: _issue!.attachments.map((att) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file_rounded, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          att.fileName,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        att.filePath,
                        style: TextStyle(fontSize: 11, color: primaryColor, decoration: TextDecoration.underline),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRepliesTab(bool isDark, Color primaryColor, bool isSuperAdmin) {
    return Column(
      children: [
        // Comments Stream
        Expanded(
          child: _issue!.comments.isEmpty
              ? Center(
                  child: Text(
                    'No replies yet. Super Admin will respond here.',
                    style: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                )
              : ListView.builder(
                  itemCount: _issue!.comments.length,
                  itemBuilder: (ctx, index) {
                    final c = _issue!.comments[index];
                    final isMe = c.senderId == RoleGuard.currentUser?.id;
                    final isInternal = c.isInternalNote;

                    if (isInternal && !isSuperAdmin) {
                      return const SizedBox.shrink();
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isInternal
                            ? Colors.amber.withValues(alpha: 0.1)
                            : (isMe
                                ? primaryColor.withValues(alpha: 0.08)
                                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC))),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isInternal
                              ? Colors.amber.withValues(alpha: 0.3)
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    c.senderName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      c.senderRole,
                                      style: TextStyle(fontSize: 9.5, color: primaryColor, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  if (isInternal) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'INTERNAL NOTE',
                                        style: TextStyle(fontSize: 9, color: Colors.amber, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                DateFormat('MMM d, h:mm a').format(c.createdAt),
                                style: TextStyle(fontSize: 10.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            c.comment,
                            style: TextStyle(fontSize: 12.5, height: 1.35, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 10),

        // Reply Input Bar
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              if (isSuperAdmin)
                Row(
                  children: [
                    Checkbox(
                      value: _isInternalNote,
                      onChanged: (val) {
                        setState(() => _isInternalNote = val == true);
                      },
                    ),
                    const Text('Post as Internal Note (visible to Super Admin only)', style: TextStyle(fontSize: 11.5)),
                  ],
                ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        hintText: isSuperAdmin
                            ? (_isInternalNote ? 'Write internal note...' : 'Type reply to reporter...')
                            : 'Add follow-up comment...',
                        isDense: true,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isSendingComment ? null : _sendComment,
                    icon: _isSendingComment
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.send_rounded, color: primaryColor, size: 20),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineTab(bool isDark, Color primaryColor) {
    return _issue!.timeline.isEmpty
        ? const Center(child: Text('No diagnostic timeline events recorded.'))
        : ListView.builder(
            itemCount: _issue!.timeline.length,
            itemBuilder: (ctx, index) {
              final t = _issue!.timeline[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.history_rounded, size: 16, color: primaryColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.description,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${t.actorName} (${t.actorRole}) • ${DateFormat('MMM d, yyyy h:mm a').format(t.createdAt)}',
                            style: TextStyle(fontSize: 10.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
  }
}
