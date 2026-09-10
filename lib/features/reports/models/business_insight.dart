import 'package:flutter/material.dart';

enum InsightSeverity {
  info,
  success,
  warning,
  danger;

  Color get color {
    switch (this) {
      case InsightSeverity.info:
        return const Color(0xFF0284C7);
      case InsightSeverity.success:
        return const Color(0xFF16A34A);
      case InsightSeverity.warning:
        return const Color(0xFFD97706);
      case InsightSeverity.danger:
        return const Color(0xFFDC2626);
    }
  }

  IconData get icon {
    switch (this) {
      case InsightSeverity.info:
        return Icons.info_outline_rounded;
      case InsightSeverity.success:
        return Icons.trending_up_rounded;
      case InsightSeverity.warning:
        return Icons.warning_amber_rounded;
      case InsightSeverity.danger:
        return Icons.error_outline_rounded;
    }
  }
}

enum InsightCategory {
  volume,
  calls,
  visits,
  conversion,
  team,
  followups;

  String get label {
    switch (this) {
      case InsightCategory.volume:
        return 'Lead Volume';
      case InsightCategory.calls:
        return 'Call Performance';
      case InsightCategory.visits:
        return 'Site Visits';
      case InsightCategory.conversion:
        return 'Deals & Won';
      case InsightCategory.team:
        return 'Team Performance';
      case InsightCategory.followups:
        return 'Follow-ups';
    }
  }
}

class BusinessInsightItem {
  final String id;
  final String title;
  final String description;
  final InsightCategory category;
  final InsightSeverity severity;
  final String? metricValue;
  final String? actionText;
  final VoidCallback? onAction;

  const BusinessInsightItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    this.metricValue,
    this.actionText,
    this.onAction,
  });
}
