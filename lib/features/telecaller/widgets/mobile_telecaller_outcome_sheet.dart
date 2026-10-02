import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/design_system/mobile/mobile.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../integration/services/integration_service.dart';
import '../data/telecaller_repository.dart';

enum TelecallerOutcomeType {
  followUp('Follow-Up', Icons.schedule_rounded),
  callback('Callback', Icons.phone_callback_rounded),
  cnr('CNR', Icons.phone_missed_rounded),
  pickedUp('Picked Up', Icons.handshake_outlined),
  interested('Interested', Icons.thumb_up_alt_outlined),
  notInterested('Not Interested', Icons.do_not_disturb_on_rounded);

  final String label;
  final IconData icon;
  const TelecallerOutcomeType(this.label, this.icon);
}

class MobileTelecallerOutcomeSheet extends StatefulWidget {
  final String leadId;
  final String clientName;
  final String phone;
  final TelecallerOutcomeType initialType;
  final VoidCallback? onDone;

  const MobileTelecallerOutcomeSheet({
    super.key,
    required this.leadId,
    required this.clientName,
    required this.phone,
    this.initialType = TelecallerOutcomeType.followUp,
    this.onDone,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String leadId,
    required String clientName,
    required String phone,
    TelecallerOutcomeType initialType = TelecallerOutcomeType.followUp,
    VoidCallback? onDone,
  }) {
    return MobileSheet.show<bool>(
      context,
      title: 'Record Call Outcome',
      child: MobileTelecallerOutcomeSheet(
        leadId: leadId,
        clientName: clientName,
        phone: phone,
        initialType: initialType,
        onDone: onDone,
      ),
    );
  }

  @override
  State<MobileTelecallerOutcomeSheet> createState() => _MobileTelecallerOutcomeSheetState();
}

class _MobileTelecallerOutcomeSheetState extends State<MobileTelecallerOutcomeSheet> {
  late TelecallerOutcomeType _selectedType;

  final TextEditingController _remarksController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 2));
  TimeOfDay _selectedTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 2)));

  // Picked up (Sales handoff) state
  String? _selectedSalesUserId;
  List<Map<String, dynamic>> _salesUsers = [];
  bool _loadingSalesUsers = true;

  // Not interested state
  String _selectedNotInterestedReason = 'Budget mismatch';
  static const List<String> _notInterestedReasons = [
    'Budget mismatch',
    'Location mismatch',
    'Already purchased',
    'Invalid number',
    'Fake lead',
    'Not looking currently',
    'Other',
  ];

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _fetchSalesUsers();
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _fetchSalesUsers() async {
    try {
      final res = await DioClient.dio.get('/telecaller/sales-users');
      final list = List<dynamic>.from(res.data['data'] ?? []);
      if (mounted) {
        setState(() {
          _salesUsers = list.map((u) => Map<String, dynamic>.from(u as Map)).toList();
          if (_salesUsers.isNotEmpty) {
            _selectedSalesUserId = _salesUsers.first['id']?.toString();
          }
          _loadingSalesUsers = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingSalesUsers = false);
      }
    }
  }

  bool get _isValid {
    if (_isSaving) return false;
    if (_selectedType == TelecallerOutcomeType.pickedUp) {
      if (_remarksController.text.trim().isEmpty) return false;
      if (_selectedSalesUserId == null || _selectedSalesUserId!.isEmpty) return false;
    }
    if (_selectedType == TelecallerOutcomeType.followUp) {
      if (_remarksController.text.trim().isEmpty) return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_isValid) {
      if (_selectedType == TelecallerOutcomeType.pickedUp && _remarksController.text.trim().isEmpty) {
        setState(() => _errorMessage = 'Property key points remarks are required for sales handoff.');
      } else if (_selectedType == TelecallerOutcomeType.followUp && _remarksController.text.trim().isEmpty) {
        setState(() => _errorMessage = 'Follow-up remarks are required.');
      }
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final cleanRemarks = _remarksController.text.trim();
      final scheduledDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      final callbackAtIso = scheduledDateTime.toUtc().toIso8601String();

      switch (_selectedType) {
        case TelecallerOutcomeType.pickedUp:
          String? targetSalesName;
          for (final u in _salesUsers) {
            if (u['id']?.toString() == _selectedSalesUserId) {
              targetSalesName = (u['full_name'] ?? u['fullName'] ?? 'Sales User').toString();
              break;
            }
          }
          await TelecallerRepository().recordOutcome(
            widget.leadId,
            outcome: 'PICKED_UP',
            remarks: cleanRemarks,
            salesUserId: _selectedSalesUserId,
            assignedToName: targetSalesName,
          );
          IntegrationService().notifyOutcomeRecorded(
            widget.leadId,
            outcome: 'PICKED_UP',
            remarks: cleanRemarks,
            salesUserId: _selectedSalesUserId,
            assignedToName: targetSalesName,
          );
          break;

        case TelecallerOutcomeType.callback:
          await TelecallerRepository().recordOutcome(
            widget.leadId,
            outcome: 'CALLBACK',
            remarks: cleanRemarks.isNotEmpty ? cleanRemarks : 'Callback requested',
            callbackAt: callbackAtIso,
          );
          IntegrationService().notifyOutcomeRecorded(
            widget.leadId,
            outcome: 'CALLBACK',
            remarks: cleanRemarks.isNotEmpty ? cleanRemarks : 'Callback requested',
            callbackAt: callbackAtIso,
          );
          break;

        case TelecallerOutcomeType.followUp:
          await IntegrationService().scheduleFollowup(
            widget.leadId,
            scheduledDateTime,
            cleanRemarks,
            status: 'Follow up',
          );
          IntegrationService().notifyOutcomeRecorded(
            widget.leadId,
            outcome: 'FOLLOWUP',
            remarks: cleanRemarks,
            callbackAt: callbackAtIso,
          );
          break;

        case TelecallerOutcomeType.cnr:
          await TelecallerRepository().recordOutcome(
            widget.leadId,
            outcome: 'CNR',
            remarks: cleanRemarks.isNotEmpty ? cleanRemarks : 'Customer Not Received',
          );
          IntegrationService().notifyOutcomeRecorded(
            widget.leadId,
            outcome: 'CNR',
            remarks: cleanRemarks.isNotEmpty ? cleanRemarks : 'Marked as CNR',
          );
          break;

        case TelecallerOutcomeType.interested:
          await IntegrationService().updateLeadCampaignStatus(widget.leadId, 'Interested');
          IntegrationService().notifyOutcomeRecorded(
            widget.leadId,
            outcome: 'INTERESTED',
            remarks: cleanRemarks.isNotEmpty ? cleanRemarks : 'Client interested in property',
          );
          break;

        case TelecallerOutcomeType.notInterested:
          final fullReason = cleanRemarks.isNotEmpty
              ? '$_selectedNotInterestedReason: $cleanRemarks'
              : _selectedNotInterestedReason;
          await IntegrationService().updateLeadCampaignStatus(widget.leadId, 'Not interested', reason: fullReason);
          IntegrationService().notifyOutcomeRecorded(
            widget.leadId,
            outcome: 'NOT_INTERESTED',
            remarks: fullReason,
          );
          break;
      }

      if (mounted) {
        widget.onDone?.call();
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Failed to record outcome. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Lead Info Summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2430) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: CRMColors.primary.withValues(alpha: 0.12),
                  child: Icon(Icons.person_outline_rounded, color: CRMColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.clientName.isNotEmpty ? widget.clientName : 'Client',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.phone.isNotEmpty ? widget.phone : 'No phone number',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Outcome Selector Chips (touch friendly, min 48px hit target)
          const Text(
            'Select Outcome',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TelecallerOutcomeType.values.map((type) {
              final isSelected = _selectedType == type;
              return Semantics(
                button: true,
                selected: isSelected,
                label: 'Outcome option ${type.label}',
                child: InkWell(
                  onTap: _isSaving
                      ? null
                      : () {
                          setState(() {
                            _selectedType = type;
                            _errorMessage = null;
                          });
                        },
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? CRMColors.primary.withValues(alpha: 0.12)
                          : (isDark ? const Color(0xFF1E2430) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? CRMColors.primary : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                        width: isSelected ? 1.8 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          type.icon,
                          size: 18,
                          color: isSelected ? CRMColors.primary : (isDark ? Colors.white70 : const Color(0xFF475569)),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          type.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? CRMColors.primary : (isDark ? Colors.white : const Color(0xFF1E293B)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Contextual Form Fields
          if (_selectedType == TelecallerOutcomeType.followUp || _selectedType == TelecallerOutcomeType.callback) ...[
            Text(
              _selectedType == TelecallerOutcomeType.followUp ? 'Follow-Up Date & Time *' : 'Callback Date & Time *',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Date Picker Button (48px)
                Expanded(
                  flex: 3,
                  child: Semantics(
                    button: true,
                    label: 'Select date',
                    child: InkWell(
                      onTap: _isSaving
                          ? null
                          : () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setState(() => _selectedDate = picked);
                              }
                            },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2430) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 18, color: CRMColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                DateFormat('EEE, d MMM').format(_selectedDate),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Time Picker Button (48px)
                Expanded(
                  flex: 2,
                  child: Semantics(
                    button: true,
                    label: 'Select time',
                    child: InkWell(
                      onTap: _isSaving
                          ? null
                          : () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: _selectedTime,
                              );
                              if (picked != null) {
                                setState(() => _selectedTime = picked);
                              }
                            },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2430) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time_rounded, size: 18, color: CRMColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedTime.format(context),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          if (_selectedType == TelecallerOutcomeType.pickedUp) ...[
            const Text(
              'Assign to Sales Executive *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            if (_loadingSalesUsers)
              const SizedBox(
                height: 48,
                child: Center(child: MobileInlineLoader(label: 'Loading sales executives...')),
              )
            else
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2430) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedSalesUserId,
                    hint: const Text('Select sales executive'),
                    items: _salesUsers.map((user) {
                      final uid = user['id']?.toString() ?? '';
                      final uname = (user['full_name'] ?? user['fullName'] ?? 'Sales').toString();
                      return DropdownMenuItem<String>(
                        value: uid,
                        child: Text(uname, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: _isSaving
                        ? null
                        : (val) {
                            setState(() => _selectedSalesUserId = val);
                          },
                  ),
                ),
              ),
            const SizedBox(height: 12),
          ],

          if (_selectedType == TelecallerOutcomeType.notInterested) ...[
            const Text(
              'Reason for Not Interested *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2430) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedNotInterestedReason,
                  items: _notInterestedReasons.map((r) {
                    return DropdownMenuItem<String>(
                      value: r,
                      child: Text(r, style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: _isSaving
                      ? null
                      : (val) {
                          if (val != null) {
                            setState(() => _selectedNotInterestedReason = val);
                          }
                        },
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Remarks Field
          Text(
            _selectedType == TelecallerOutcomeType.pickedUp
                ? 'Property Key Points & Remarks *'
                : (_selectedType == TelecallerOutcomeType.followUp ? 'Follow-Up Remarks *' : 'Remarks (Optional)'),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _remarksController,
            maxLines: 2,
            enabled: !_isSaving,
            decoration: InputDecoration(
              hintText: _selectedType == TelecallerOutcomeType.pickedUp
                  ? 'Enter mandatory key points for sales handoff...'
                  : 'Enter outcome remarks or customer requirements...',
              hintStyle: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade500 : const Color(0xFF94A3B8),
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E2430) : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
              ),
            ),
            onChanged: (_) {
              if (_errorMessage != null) {
                setState(() => _errorMessage = null);
              }
            },
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: CRMColors.danger, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],

          const SizedBox(height: 20),

          // Action Button (48px height, direct server write -> "Saving...", never "Waiting to sync")
          MobileActionButton.primary(
            MobileAction(
              label: 'Save Outcome',
              loading: _isSaving,
              enabled: !_isSaving,
              onPressed: _submit,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
