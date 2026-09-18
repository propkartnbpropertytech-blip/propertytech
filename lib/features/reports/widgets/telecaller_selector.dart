import 'package:flutter/material.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/theme/theme_manager.dart';
import '../../users/models/user_model.dart';

class TelecallerSelector extends StatelessWidget {
  final List<UserModel> telecallers;
  final String? selectedId;
  final ValueChanged<UserModel> onSelected;

  const TelecallerSelector({
    super.key,
    required this.telecallers,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = CRMColors.primary;
    final selected = telecallers.where((u) => u.id == selectedId).firstOrNull;
    final label = selected == null
        ? 'Select Telecaller'
        : (selected.fullName.isNotEmpty ? selected.fullName : selected.email);

    return InkWell(
      onTap: () => _openPicker(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected != null
                ? primaryColor.withValues(alpha: 0.45)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.headset_mic_rounded, size: 16, color: primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Telecaller',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected != null
                          ? (isDark ? Colors.white : const Color(0xFF14213D))
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down_rounded,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final isDark = ThemeManager().isDarkMode;
    final result = await showModalBottomSheet<UserModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TelecallerSearchSheet(
        telecallers: telecallers,
        selectedId: selectedId,
        isDark: isDark,
      ),
    );
    if (result != null) onSelected(result);
  }
}

class _TelecallerSearchSheet extends StatefulWidget {
  final List<UserModel> telecallers;
  final String? selectedId;
  final bool isDark;

  const _TelecallerSearchSheet({
    required this.telecallers,
    required this.selectedId,
    required this.isDark,
  });

  @override
  State<_TelecallerSearchSheet> createState() => _TelecallerSearchSheetState();
}

class _TelecallerSearchSheetState extends State<_TelecallerSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = CRMColors.primary;
    final q = _query.trim().toLowerCase();
    final filtered = widget.telecallers.where((u) {
      if (q.isEmpty) return true;
      final name = u.fullName.toLowerCase();
      final email = u.email.toLowerCase();
      final mobile = (u.mobile ?? '').toLowerCase();
      return name.contains(q) || email.contains(q) || mobile.contains(q);
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
        maxWidth: 560,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Select Telecaller',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              autofocus: widget.telecallers.length > 8,
              decoration: InputDecoration(
                hintText: 'Search by name, email, or mobile...',
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (val) => setState(() => _query = val),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      widget.telecallers.isEmpty
                          ? 'No telecallers found in this organisation.'
                          : 'No telecaller matches your search.',
                      style: TextStyle(
                        fontSize: 13,
                        color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final user = filtered[i];
                      final isSelected = user.id == widget.selectedId;
                      final name = user.fullName.isNotEmpty ? user.fullName : user.email;
                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: primaryColor.withValues(alpha: 0.08),
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: primaryColor.withValues(alpha: 0.12),
                          child: Text(
                            _initials(name),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text(
                          [
                            if (user.email.isNotEmpty) user.email,
                            if (user.mobile != null && user.mobile!.isNotEmpty) user.mobile,
                          ].join(' · '),
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded, color: primaryColor, size: 18)
                            : null,
                        onTap: () => Navigator.of(context).pop(user),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return 'T';
    return parts.take(2).map((p) => p[0]).join().toUpperCase();
  }
}
