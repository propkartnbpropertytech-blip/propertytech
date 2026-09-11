import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../../core/theme/theme_manager.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../models/team_message_model.dart';
import '../services/team_messages_service.dart';

/// Full dedicated screen for Team Messages with routing (/messages),
/// role categorization, and back navigation.
class TeamMessagesScreen extends StatefulWidget {
  const TeamMessagesScreen({super.key});

  @override
  State<TeamMessagesScreen> createState() => _TeamMessagesScreenState();
}

class _TeamMessagesScreenState extends State<TeamMessagesScreen> {
  final TeamMessagesService _service = TeamMessagesService();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  List<TeamChatUserModel> _users = [];
  TeamChatUserModel? _selectedUser;
  List<TeamMessageModel> _messages = [];

  bool _isLoadingUsers = true;
  bool _isLoadingMessages = false;
  bool _isSending = false;
  String _selectedRoleFilter = 'All';
  String _searchQuery = '';
  bool _viewingAdminChat = false;
  final Set<String> _collapsedTeams = {};

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    // Live polling every 3.5 seconds
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
    _messageFocusNode.dispose();
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
          // Auto-select first user if none selected and on desktop
          final isMobile = MediaQuery.of(context).size.width < 768;
          if (_selectedUser == null && _users.isNotEmpty && !isMobile) {
            final firstTeam = _sortedTeamKeys.firstOrNull;
            final firstUser = (firstTeam != null ? _groupedUsers[firstTeam]?.firstOrNull : null) ?? _users.first;
            _selectUser(firstUser);
          } else if (_selectedUser != null) {
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
      _viewingAdminChat = false;
      _isLoadingMessages = true;
      _messages = [];
    });

    await _loadConversation(user.id);
  }

  Future<void> _loadConversation(String otherUserId, {bool silent = false}) async {
    try {
      final authState = context.read<AuthBloc>().state;
      final isSuperAdmin = authState is Authenticated &&
          authState.user.role.toLowerCase() == 'super admin';
      final withAdminId = (_viewingAdminChat && isSuperAdmin && _selectedUser?.role.toLowerCase() != 'admin')
          ? _selectedUser?.adminId
          : null;

      final fetchedMessages = await _service.getConversation(
        otherUserId,
        withAdminId: withAdminId,
      );
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

    if (_viewingAdminChat) {
      setState(() => _viewingAdminChat = false);
    }

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
        _messageFocusNode.requestFocus();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: CRMColors.danger,
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
          user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.role.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (user.teamName ?? '').toLowerCase().contains(_searchQuery.toLowerCase());

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

  Map<String, List<TeamChatUserModel>> get _groupedUsers {
    final filtered = _filteredUsers;
    final Map<String, List<TeamChatUserModel>> map = {};
    for (final u in filtered) {
      final key = u.teamName ?? 'General Team';
      if (!map.containsKey(key)) {
        map[key] = [];
      }
      map[key]!.add(u);
    }

    // Sort inside each team: Admin (1), Telecaller (2), Sales (3)
    int roleRank(String r) {
      final s = r.toLowerCase();
      if (s.contains('admin')) return 1;
      if (s.contains('telecaller')) return 2;
      return 3;
    }

    for (final key in map.keys) {
      map[key]!.sort((a, b) {
        final rankDiff = roleRank(a.role) - roleRank(b.role);
        if (rankDiff != 0) return rankDiff;
        return a.name.compareTo(b.name);
      });
    }

    return map;
  }

  List<String> get _sortedTeamKeys {
    final keys = _groupedUsers.keys.toList();
    keys.sort((a, b) {
      final aIsProp = a.toLowerCase().contains('propkart');
      final bIsProp = b.toLowerCase().contains('propkart');
      if (aIsProp && !bIsProp) return -1;
      if (!aIsProp && bIsProp) return 1;
      return a.compareTo(b);
    });
    return keys;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = ThemeManager().primaryColor;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    final authState = context.watch<AuthBloc>().state;
    final currentUserId = authState is Authenticated ? authState.user.id : '';
    final currentUserRole = authState is Authenticated ? authState.user.role : '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? CRMSpacing.s : CRMSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Master Screen Header with Back Button ─────────────
              _buildTopHeader(context, isDark, primaryColor, currentUserRole),

              const SizedBox(height: CRMSpacing.m),

              // ── Main Body Messenger Card ──────────────────────────
              Expanded(
                child: CRMCard(
                  padding: EdgeInsets.zero,
                  child: isMobile
                      ? (_selectedUser == null
                          ? _buildUserSidebar(isDark, primaryColor)
                          : _buildChatThread(isDark, primaryColor, currentUserId, currentUserRole, isMobile: true))
                      : Row(
                          children: [
                            // Left User Roster Column
                            SizedBox(
                              width: 320,
                              child: _buildUserSidebar(isDark, primaryColor),
                            ),
                            // Vertical Divider
                            Container(
                              width: 1,
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                            // Right Active Chat Column
                            Expanded(
                              child: _buildChatThread(isDark, primaryColor, currentUserId, currentUserRole),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top Page Header with Back Button ──────────────────────────
  Widget _buildTopHeader(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    String currentUserRole,
  ) {
    return Row(
      children: [
        // Back Button
        IconButton.filledTonal(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          tooltip: 'Back to Dashboard',
          style: IconButton.styleFrom(
            backgroundColor: primaryColor.withValues(alpha: 0.12),
            foregroundColor: primaryColor,
          ),
        ),
        const SizedBox(width: CRMSpacing.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Team Messages',
                    style: CRMTypography.sectionTitle.copyWith(
                      color: CRMColors.textOf(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(CRMBorderRadius.badge),
                      border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      currentUserRole.isNotEmpty ? currentUserRole.toUpperCase() : 'TEAM',
                      style: CRMTypography.captionBold.copyWith(
                        color: primaryColor,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Direct end-to-end messaging across Propkart Admin, Telecallers, and Sales team',
                style: CRMTypography.caption.copyWith(
                  color: CRMColors.textSecondaryOf(context),
                ),
              ),
            ],
          ),
        ),
        // Refresh Button
        IconButton(
          onPressed: () => _loadUsers(),
          icon: const Icon(Icons.refresh_rounded, size: 20),
          tooltip: 'Refresh conversations',
          color: CRMColors.textSecondaryOf(context),
        ),
      ],
    );
  }

  // ── Left User Sidebar ─────────────────────────────────────────
  Widget _buildUserSidebar(bool isDark, Color primaryColor) {
    final roles = ['All', 'Admins', 'Telecallers', 'Sales'];

    return Column(
      children: [
        // Search & Role Filter Header
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
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textOf(context)),
                decoration: InputDecoration(
                  hintText: 'Search team member...',
                  hintStyle: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                  prefixIcon: Icon(Icons.search_rounded, size: 18, color: CRMColors.textSecondaryOf(context)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  isDense: true,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: CRMColors.borderOf(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: CRMColors.borderOf(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryColor),
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
                        label: Text(role),
                        selected: isSelected,
                        selectedColor: primaryColor.withValues(alpha: 0.15),
                        backgroundColor: Colors.transparent,
                        labelStyle: CRMTypography.captionBold.copyWith(
                          fontSize: 11,
                          color: isSelected ? primaryColor : CRMColors.textSecondaryOf(context),
                        ),
                        side: BorderSide(
                          color: isSelected ? primaryColor : CRMColors.borderOf(context),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(CRMBorderRadius.badge),
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

        // User list grouped by teams
        Expanded(
          child: _isLoadingUsers
              ? const Center(child: CircularProgressIndicator())
              : _filteredUsers.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.group_off_rounded, size: 36, color: CRMColors.textSecondaryOf(context)),
                            const SizedBox(height: 8),
                            Text(
                              'No team members found',
                              style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Team members will appear organized by team units here.',
                              textAlign: TextAlign.center,
                              style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _sortedTeamKeys.length,
                      itemBuilder: (context, teamIndex) {
                        final teamName = _sortedTeamKeys[teamIndex];
                        final teamUsers = _groupedUsers[teamName] ?? [];
                        final isCollapsed = _collapsedTeams.contains(teamName);
                        final isPropkart = teamName.toLowerCase().contains('propkart');

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Team Section Header
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (isCollapsed) {
                                    _collapsedTeams.remove(teamName);
                                  } else {
                                    _collapsedTeams.add(teamName);
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                margin: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isPropkart
                                      ? const Color(0xFF2563EB).withValues(alpha: isDark ? 0.18 : 0.08)
                                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isPropkart
                                        ? const Color(0xFF2563EB).withValues(alpha: 0.3)
                                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isPropkart ? Icons.verified_user_rounded : Icons.corporate_fare_rounded,
                                      size: 16,
                                      color: isPropkart
                                          ? const Color(0xFF2563EB)
                                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        isPropkart ? 'Propkart Admin Team' : '$teamName Team',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${teamUsers.length}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      isCollapsed ? Icons.keyboard_arrow_right_rounded : Icons.keyboard_arrow_down_rounded,
                                      size: 18,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Team Members List
                            if (!isCollapsed)
                              ...teamUsers.map((user) => _buildUserTile(user, primaryColor, isDark)),
                          ],
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildUserTile(
    TeamChatUserModel user,
    Color primaryColor,
    bool isDark,
  ) {
    final isSelected = _selectedUser?.id == user.id;
    final roleColor = _getRoleColor(user.role);
    final isAdmin = user.role.toLowerCase() == 'admin';

    return InkWell(
      onTap: () => _selectUser(user),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: isDark ? 0.18 : 0.08)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? primaryColor : Colors.transparent,
              width: 3.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Avatar with status
            Stack(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: roleColor.withValues(alpha: 0.15),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: roleColor,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: CRMColors.success,
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
            const SizedBox(width: 10),
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                user.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isAdmin) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.star_rounded, size: 14, color: Color(0xFF2563EB)),
                            ],
                          ],
                        ),
                      ),
                      if (user.lastMessageAt != null)
                        Text(
                          _formatTimeAgo(user.lastMessageAt!),
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      // Distinct Role Badge
                      _buildRoleBadge(user.role, roleColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          user.lastMessage ?? user.email,
                          style: TextStyle(
                            fontSize: 11,
                            color: user.unreadCount > 0
                                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            fontWeight: user.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.unreadCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${user.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
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
  }

  // ── Right Chat Area ───────────────────────────────────────────
  Widget _buildChatThread(
    bool isDark,
    Color primaryColor,
    String currentUserId,
    String currentUserRole, {
    bool isMobile = false,
  }) {
    if (_selectedUser == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.forum_outlined, size: 48, color: primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Select a team member',
              style: CRMTypography.sectionTitle.copyWith(
                color: CRMColors.textOf(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Chat directly with Propkart Admin, Telecallers, and Sales agents',
              style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
            ),
          ],
        ),
      );
    }

    final targetUser = _selectedUser!;
    final roleColor = _getRoleColor(targetUser.role);

    return Column(
      children: [
        // Top Conversation Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  onPressed: () => setState(() => _selectedUser = null),
                  tooltip: 'Back to team members',
                ),
                const SizedBox(width: 4),
              ],
              CircleAvatar(
                radius: 18,
                backgroundColor: roleColor.withValues(alpha: 0.15),
                child: Text(
                  targetUser.name.isNotEmpty ? targetUser.name[0].toUpperCase() : 'U',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: roleColor,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            targetUser.name,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildRoleBadge(targetUser.role, roleColor),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${targetUser.email} • Team: ${targetUser.teamName ?? 'Propkart'}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                onPressed: () => _loadConversation(targetUser.id),
                tooltip: 'Refresh chat',
                color: CRMColors.textSecondaryOf(context),
              ),
            ],
          ),
        ),

        // Super Admin Mode Switcher: Direct Chat vs Admin Conversation Inspection
        if (currentUserRole.toLowerCase() == 'super admin' &&
            targetUser.role.toLowerCase() != 'admin' &&
            targetUser.adminName != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: [
                      const ButtonSegment<bool>(
                        value: false,
                        icon: Icon(Icons.chat_outlined, size: 14),
                        label: Text('Direct Chat', style: TextStyle(fontSize: 11.5)),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        icon: const Icon(Icons.history_edu_rounded, size: 14),
                        label: Text('Team Chat (${targetUser.adminName})', style: const TextStyle(fontSize: 11.5)),
                      ),
                    ],
                    selected: {_viewingAdminChat},
                    onSelectionChanged: (Set<bool> val) {
                      setState(() {
                        _viewingAdminChat = val.first;
                        _isLoadingMessages = true;
                      });
                      _loadConversation(targetUser.id);
                    },
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_viewingAdminChat)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Inspection Mode: Viewing messages between ${targetUser.name} and ${targetUser.adminName ?? 'Admin'}.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],

        // Message bubbles list
        Expanded(
          child: _isLoadingMessages
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 40, color: CRMColors.textSecondaryOf(context)),
                          const SizedBox(height: 12),
                          Text(
                            'No messages yet',
                            style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Send a greeting to start chatting with ${targetUser.name}',
                            style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final bool isMe;
                        final String? senderLabel;

                        if (_viewingAdminChat) {
                          isMe = msg.senderId != targetUser.id;
                          senderLabel = msg.senderId == targetUser.id
                              ? targetUser.name
                              : (targetUser.adminName ?? 'Admin');
                        } else {
                          isMe = msg.senderId == currentUserId;
                          senderLabel = null;
                        }

                        return _buildMessageBubble(
                          msg,
                          isMe,
                          primaryColor,
                          isDark,
                          senderLabel: senderLabel,
                        );
                      },
                    ),
        ),

        // Input composer bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.enter &&
                        !HardwareKeyboard.instance.isShiftPressed) {
                      _sendMessage();
                    }
                  },
                  child: TextField(
                    controller: _messageController,
                    focusNode: _messageFocusNode,
                    minLines: 1,
                    maxLines: 4,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type your message to ${targetUser.name}...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      filled: true,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _isSending ? null : _sendMessage,
                icon: _isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(
    TeamMessageModel msg,
    bool isMe,
    Color primaryColor,
    bool isDark, {
    String? senderLabel,
  }) {
    final bubbleColor = isMe
        ? primaryColor
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9));
    final textColor = isMe
        ? Colors.white
        : (isDark ? Colors.white : const Color(0xFF0F172A));

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMe ? 14 : 2),
            bottomRight: Radius.circular(isMe ? 2 : 14),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (senderLabel != null) ...[
              Text(
                senderLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isMe
                      ? (isDark ? Colors.lightBlueAccent : Colors.white)
                      : (isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB)),
                ),
              ),
              const SizedBox(height: 3),
            ],
            Text(
              msg.message,
              style: TextStyle(
                fontSize: 13.5,
                color: textColor,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('h:mm a').format(msg.createdAt.toLocal()),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : const Color(0xFF94A3B8),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 13,
                    color: msg.isRead ? Colors.lightBlueAccent : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Role Badge Pill ───────────────────────────────────────────
  Widget _buildRoleBadge(String role, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    final r = role.toLowerCase().trim();
    if (r.contains('super')) return const Color(0xFFF59E0B); // Amber
    if (r.contains('admin')) return const Color(0xFF2563EB); // Blue
    if (r.contains('telecaller')) return const Color(0xFF059669); // Emerald Green
    return const Color(0xFF7C3AED); // Purple for Sales
  }

  String _formatTimeAgo(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time.toLocal());

    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays == 1) return 'yesterday';
    return DateFormat('MMM d').format(time.toLocal());
  }
}
