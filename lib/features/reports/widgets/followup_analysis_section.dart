import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme_manager.dart';
import '../models/report_data.dart';

class FollowupAnalysisSection extends StatefulWidget {
  final List<FollowupCategoryData> categories;

  const FollowupAnalysisSection({
    super.key,
    required this.categories,
  });

  @override
  State<FollowupAnalysisSection> createState() => _FollowupAnalysisSectionState();
}

class _FollowupAnalysisSectionState extends State<FollowupAnalysisSection> {
  int _selectedCategoryIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;

    if (widget.categories.isEmpty) {
      return const SizedBox.shrink();
    }

    final activeCategory = widget.categories[_selectedCategoryIndex.clamp(0, widget.categories.length - 1)];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            children: [
              Icon(Icons.phone_callback_rounded, size: 18),
              SizedBox(width: 8),
              Text(
                'Follow-up Analysis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4 Category Cards / Tabs
          Row(
            children: List.generate(widget.categories.length, (idx) {
              final cat = widget.categories[idx];
              final isSelected = idx == _selectedCategoryIndex;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: idx == widget.categories.length - 1 ? 0 : 8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedCategoryIndex = idx),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cat.color.withValues(alpha: isDark ? 0.2 : 0.1)
                            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? cat.color : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          width: isSelected ? 1.5 : 0.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.categoryName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? cat.color : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cat.count.toString(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? cat.color : (isDark ? Colors.white : const Color(0xFF14213D)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),

          // Detailed Table of Items for Active Category
          if (activeCategory.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No follow-ups currently in ${activeCategory.categoryName}.',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${activeCategory.categoryName} (${activeCategory.items.length})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: activeCategory.color,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: activeCategory.items.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final item = activeCategory.items[i];
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        title: Row(
                          children: [
                            Text(
                              item.leadName,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            const SizedBox(width: 8),
                            if (item.clientMobile != null)
                              Text(
                                item.clientMobile!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          'Assigned: ${item.assignedUserName ?? 'Agent'} · Scheduled: ${DateFormat('dd MMM, hh:mm a').format(item.followupDateTime)} · Note: ${item.lastActivity ?? 'None'}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: activeCategory.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.nextAction,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: activeCategory.color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.chevron_right, size: 18),
                              onPressed: () {
                                context.go('/requirements?search=${Uri.encodeComponent(item.leadName)}');
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
