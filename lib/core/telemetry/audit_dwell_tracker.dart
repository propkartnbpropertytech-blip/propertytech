import 'package:flutter/material.dart';
import 'audit_telemetry_service.dart';

/// Wraps any widget to track user hover and dwell times (mouse stops & hovers).
/// Dispatches telemetry only when dwell duration exceeds [minDwellDuration] (default: 1.0s).
class AuditHoverDwell extends StatefulWidget {
  final Widget child;
  final String targetType; // e.g. "PropertyCard", "LeadItem", "BrochureBtn"
  final String targetId;   // Unique ID or name of the target
  final String page;       // Route or screen name e.g. "/properties"
  final Map<String, dynamic>? metadata;
  final Duration minDwellDuration;
  final bool isEnabled;

  const AuditHoverDwell({
    super.key,
    required this.child,
    required this.targetType,
    required this.targetId,
    required this.page,
    this.metadata,
    this.minDwellDuration = const Duration(milliseconds: 1000),
    this.isEnabled = true,
  });

  @override
  State<AuditHoverDwell> createState() => _AuditHoverDwellState();
}

class _AuditHoverDwellState extends State<AuditHoverDwell> {
  DateTime? _enterTime;

  void _onPointerEnter() {
    if (!widget.isEnabled) return;
    _enterTime = DateTime.now();
  }

  void _onPointerExit() {
    if (!widget.isEnabled || _enterTime == null) return;
    final dwellDuration = DateTime.now().difference(_enterTime!);
    _enterTime = null;

    if (dwellDuration >= widget.minDwellDuration) {
      AuditTelemetryService.instance.trackHoverDwell(
        targetType: widget.targetType,
        targetId: widget.targetId,
        dwellMs: dwellDuration.inMilliseconds,
        page: widget.page,
        metadata: widget.metadata,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEnabled) {
      return widget.child;
    }

    return MouseRegion(
      onEnter: (_) => _onPointerEnter(),
      onExit: (_) => _onPointerExit(),
      child: widget.child,
    );
  }
}
