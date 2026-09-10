import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../../core/theme/theme_manager.dart';
import '../models/team_message_model.dart';
import '../services/team_messages_service.dart';

class TeamMessengerDialog extends StatefulWidget {
  const TeamMessengerDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => const TeamMessengerDialog(),
    );
  }

  @override
  State<TeamMessengerDialog> createState() => _TeamMessengerDialogState();
}

class _TeamMessengerDialogState extends State<TeamMessengerDialog> {
  final TeamMessagesService _service = TeamMessagesService();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<TeamChatUserModel> _users = [];
  TeamChatUserModel? _selectedUser;
  List<TeamMessageModel> _messages = [];

  bool _isLoadingUsers = true;
  bool _isLoadingMessages = false;
  bool _isSending = false;
  String _selectedRoleFilter = 'All';
  String _searchQuery = '';

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    // Poll every 3.5 seconds for live message updates
    _pollTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      _pollUpdates();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoadingUsers = true);
    }
    try {
      final fetchedUsers = await _service.getTeamUsers();
      if (mounted) {
        setState(() {
          _users = fetchedUsers;
          _isLoadingUsers = false;
          // Auto-select first user if none selected and users list is not empty
          if (_selectedUser == null && _users.isNotEmpty) {
            _selectUser(_users.first);
          } else if (_selectedUser != null) {
            // Update selected user instance reference in list
            final match = _users.where((u) => u.id == _selectedUser!.id).firstOrNull;
            if (match != null) {
              _selectedUser = match;
            }
          }
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() => _isLoadingUsers = false);
      }
    }
  }

  Future<void> _selectUser(TeamChatUserModel user) async {
    setState(() {
      _selectedUser = user;
      _isLoadingMessages = true;
      _messages = [];
    });

    await _loadConversation(user.id);
  }

  Future<void> _loadConversation(String otherUserId, {bool silent = false}) async {
    try {
      final fetchedMessages = await _service.getConversation(otherUserId);
      if (mounted) {
        setState(() {
          _messages = fetchedMessages;
          _isLoadingMessages = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() => _isLoadingMessages = false);
      }
    }
  }

  void _pollUpdates() {
    _loadUsers(silent: true);
    if (_selectedUser != null) {
      _loadConversation(_selectedUser!.id, silent: true);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _selectedUser == null || _isSending) return;

    final targetUser = _selectedUser!;
    _messageController.clear();

    setState(() {
      _isSending = true;
    });

    try {
      final sentMessage = await _service.sendMessage(
        receiverId: targetUser.id,
        message: text,
      );
      if (mounted) {
        setState(() {
          _messages.add(sentMessage);
          _isSending = false;
        });
        _scrollToBottom();
        _loadUsers(silent: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  List<TeamChatUserModel> get _filteredUsers {
    return _users.where((user) {
      final matchesSearch = _searchQuery.isEmpty ||
          user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.role.toLowerCase().contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      if (_selectedRoleFilter == 'All') return true;
      if (_selectedRoleFilter == 'Admins') {
        return user.role.toLowerCase().contains('admin');
      }
      if (_selectedRoleFilter == 'Telecallers') {
        return user.role.toLowerCase().contains('telecaller');
      }
      if (_selectedRoleFilter == 'Sales') {
        return user.role.toLowerCase().contains('sales');
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = ThemeManager();
    final isDark = themeManager.isDarkMode;
    final primaryColor = themeManager.primaryColor;
    final media = MediaQuery.of(context);
    final isMobile = media.size.width < 768;

    final authState = context.watch<AuthBloc>().state;
    final currentUserId = authState is Authenticated ? authState.user.id : '';
    final currentUserRole = authState is Authenticated ? authState.user.role : '';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: isMobile
          ? const EdgeInsets.symmetric(horizontal: 10, vertical: 16)
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: Container(
        width: isMobile ? double.infinity : 980,
        height: isMobile ? media.size.height * 0.88 : 680,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Header Bar ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.forum_rounded,
                      color: primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Team Messenger',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                currentUserRole.isNotEmpty ? currentUserRole : 'Team',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Direct end-to-end messaging across team members',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    onPressed: () => _loadUsers(),
                    tooltip: 'Refresh',
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // ── Main Content Area ─────────────────────────────────────────
            Expanded(
              child: isMobile
                  ? (_selectedUser == null
                      ? _buildUserSidebar(isDark, primaryColor)
                      : _buildChatThread(isDark, primaryColor, currentUserId, isMobile: true))
                  : Row(
                      children: [
                        // Left User Sidebar (Width: 320)
                        SizedBox(
                          width: 320,
                          child: _buildUserSidebar(isDark, primaryColor),
                        ),
                        // Divider
                        Container(
                          width: 1,
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                        // Right Chat Thread
                        Expanded(
                          child: _buildChatThread(isDark, primaryColor, currentUserId),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSidebar(bool isDark, Color primaryColor) {
    final roles = ['All', 'Admins', 'Telecallers', 'Sales'];

    return Column(
      children: [
        // Search & Role Filters Bar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
          ),
          child: Column(
            children: [
              // Search input
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'Search team member...',
                  hintStyle: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                  fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  filled: true,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Role Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: roles.map((role) {
                    final isSelected = _selectedRoleFilter == role;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(
                          role,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: primaryColor,
                        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide.none,
                        ),
                        visualDensity: VisualDensity.compact,
                        onSelected: (_) {
                          setState(() => _selectedRoleFilter = role);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Users List
        Expanded(
          child: _isLoadingUsers
              ? const Center(child: CircularProgressIndicator())
              : _filteredUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 38,
                            color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No team members found',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: _filteredUsers.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        indent: 64,
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      ),
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        final isSelected = _selectedUser?.id == user.id;

                        final initials = user.name.isNotEmpty
                            ? user.name
                                .trim()
                                .split(' ')
                                .map((e) => e.isNotEmpty ? e[0] : '')
                                .take(2)
                                .join()
                                .toUpperCase()
                            : 'U';

                        return InkWell(
                          onTap: () => _selectUser(user),
                          child: Container(
                            color: isSelected
                                ? (isDark
                                    ? primaryColor.withValues(alpha: 0.18)
                                    : primaryColor.withValues(alpha: 0.08))
                                : Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: primaryColor.withValues(alpha: 0.15),
                                      child: Text(
                                        initials,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              user.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                            ),
                                          ),
                                          if (user.lastMessageAt != null)
                                            Text(
                                              _formatTime(user.lastMessageAt!),
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              user.role,
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              user.lastMessage ?? 'No messages yet',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: user.unreadCount > 0
                                                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                                    : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                                                fontWeight: user.unreadCount > 0
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                          if (user.unreadCount > 0) ...[
                                            const SizedBox(width: 4),
                                            Container(
                                              padding: const EdgeInsets.all(5),
                                              decoration: BoxDecoration(
                                                color: primaryColor,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                '${user.unreadCount}',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildChatThread(bool isDark, Color primaryColor, String currentUserId, {bool isMobile = false}) {
    if (_selectedUser == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_outlined,
              size: 54,
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 12),
            Text(
              'Select a team member to start chatting',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    final targetUser = _selectedUser!;
    final initials = targetUser.name.isNotEmpty
        ? targetUser.name
            .trim()
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : 'U';

    return Column(
      children: [
        // Thread Top Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            border: Border(
              bottom: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
          ),
          child: Row(
            children: [
              if (isMobile) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => setState(() => _selectedUser = null),
                ),
                const SizedBox(width: 4),
              ],
              CircleAvatar(
                radius: 18,
                backgroundColor: primaryColor.withValues(alpha: 0.15),
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      targetUser.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      targetUser.role,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Message List Area
        Expanded(
          child: Container(
            color: isDark ? const Color(0xFF090D16) : const Color(0xFFF1F5F9),
            child: _isLoadingMessages
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet. Say hi to ${targetUser.name}!',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg.senderId == currentUserId;
                          return _buildMessageBubble(msg, isMe, isDark, primaryColor);
                        },
                      ),
          ),
        ),

        // Message Input Bar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: RawKeyboardListener(
                  focusNode: FocusNode(),
                  onKey: (event) {
                    if (event is RawKeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.enter &&
                        !event.isShiftPressed) {
                      _sendMessage();
                    }
                  },
                  child: TextField(
                    controller: _messageController,
                    maxLines: 3,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      filled: true,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _isSending ? null : _sendMessage,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: _isSending
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(TeamMessageModel msg, bool isMe, bool isDark, Color primaryColor) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isMe
              ? primaryColor
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMe ? 14 : 2),
            bottomRight: Radius.circular(isMe ? 2 : 14),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAlignment.end : CrossAlignment.start,
          children: [
            Text(
              msg.message,
              style: TextStyle(
                fontSize: 13.5,
                color: isMe
                    ? Colors.white
                    : (isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A)),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(msg.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.8)
                        : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 14,
                    color: msg.isRead
                        ? const Color(0xFF60A5FA)
                        : Colors.white.withValues(alpha: 0.8),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    if (now.day == date.day && now.month == date.month && now.year == date.year) {
      return DateFormat('h:mm a').format(date.toLocal());
    } else {
      return DateFormat('MMM d, h:mm a').format(date.toLocal());
    }
  }
}
