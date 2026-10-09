import 'package:flutter/material.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/theme/theme_manager.dart';
import '../models/support_issue_model.dart';
import '../services/support_service.dart';

class CreateIssueModal extends StatefulWidget {
  final List<SupportCatalogPage> catalog;
  final VoidCallback onSubmitted;
  final String? initialPageKey;

  const CreateIssueModal({
    super.key,
    required this.catalog,
    required this.onSubmitted,
    this.initialPageKey,
  });

  @override
  State<CreateIssueModal> createState() => _CreateIssueModalState();
}

class _CreateIssueModalState extends State<CreateIssueModal> {
  int _currentStep = 0;

  SupportCatalogPage? _selectedPage;
  SupportCatalogFunction? _selectedFunction;
  String _issueType = 'Function not working';
  String _priority = 'Medium';
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _attachmentUrlController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;
  SupportIssue? _submittedIssue;

  final List<String> _issueTypes = const [
    'Function not working',
    'Incorrect data or count',
    'Data not saving or updating',
    'Error message or unexpected behavior',
    'Slow performance',
    'UI or display issue',
    'Access or permission issue',
    'Other',
  ];

  final List<String> _priorities = const ['Low', 'Medium', 'High', 'Critical'];

  @override
  void initState() {
    super.initState();
    if (widget.catalog.isNotEmpty) {
      if (widget.initialPageKey != null && widget.initialPageKey!.isNotEmpty) {
        final match = widget.catalog.firstWhere(
          (p) => p.pageKey == widget.initialPageKey,
          orElse: () => widget.catalog.first,
        );
        _selectedPage = match;
      } else {
        _selectedPage = widget.catalog.first;
      }
      if (_selectedPage != null && _selectedPage!.functions.isNotEmpty) {
        _selectedFunction = _selectedPage!.functions.first;
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _attachmentUrlController.dispose();
    super.dispose();
  }

  void _onPageChanged(SupportCatalogPage? page) {
    setState(() {
      _selectedPage = page;
      if (page != null && page.functions.isNotEmpty) {
        _selectedFunction = page.functions.first;
      } else {
        _selectedFunction = null;
      }
    });
  }

  Future<void> _submitTicket() async {
    if (_selectedPage == null || _selectedFunction == null) {
      setState(() => _errorMessage = 'Please select a page and function.');
      return;
    }
    final desc = _descriptionController.text.trim();
    if (desc.length < 5) {
      setState(() => _errorMessage = 'Please provide a description (at least 5 characters).');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final attachments = <Map<String, dynamic>>[];
      final attUrl = _attachmentUrlController.text.trim();
      if (attUrl.isNotEmpty) {
        attachments.add({
          'file_name': 'Attachment Link / Screenshot',
          'file_path': attUrl,
          'file_type': 'image_or_link',
        });
      }

      final issue = await SupportService.instance.createIssue(
        pageKey: _selectedPage!.pageKey,
        pageName: _selectedPage!.pageName,
        functionKey: _selectedFunction!.key,
        functionName: _selectedFunction!.name,
        issueType: _issueType,
        priority: _priority,
        description: desc,
        attachments: attachments,
      );

      setState(() {
        _submittedIssue = issue;
        _isSubmitting = false;
        _currentStep = 4; // Success step
      });

      widget.onSubmitted();
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = ThemeManager().primaryColor;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 620,
        constraints: const BoxConstraints(maxHeight: 720),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.help_outline_rounded, color: primaryColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report an Issue / Support Request',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Step ${_currentStep + 1} of 5 — Select details and submit',
                        style: TextStyle(
                          fontSize: 12,
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
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Step Indicator Progress Bar
            Row(
              children: List.generate(5, (index) {
                final isActive = index <= _currentStep;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isActive ? primaryColor : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: CRMColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CRMColors.danger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: CRMColors.danger, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 12.5, color: CRMColors.danger, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

            // Step Content Body
            Expanded(
              child: SingleChildScrollView(
                child: _buildStepBody(isDark, primaryColor),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Navigation Buttons Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0 && _currentStep < 4)
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _currentStep--),
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const Text('Previous'),
                  )
                else
                  const SizedBox.shrink(),
                Row(
                  children: [
                    if (_currentStep < 4)
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    const SizedBox(width: 10),
                    if (_currentStep < 3)
                      ElevatedButton.icon(
                        onPressed: () {
                          if (_currentStep == 0 && _selectedPage == null) {
                            setState(() => _errorMessage = 'Please select a page.');
                            return;
                          }
                          if (_currentStep == 1 && _selectedFunction == null) {
                            setState(() => _errorMessage = 'Please select a function.');
                            return;
                          }
                          setState(() {
                            _errorMessage = null;
                            _currentStep++;
                          });
                        },
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: const Text('Next Step'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      )
                    else if (_currentStep == 3)
                      ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitTicket,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.send_rounded, size: 16),
                        label: Text(_isSubmitting ? 'Submitting...' : 'Submit Support Ticket'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Done / Close'),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBody(bool isDark, Color primaryColor) {
    switch (_currentStep) {
      case 0:
        return _buildStep1PageSelection(isDark, primaryColor);
      case 1:
        return _buildStep2FunctionSelection(isDark, primaryColor);
      case 2:
        return _buildStep3IssueTypeSelection(isDark, primaryColor);
      case 3:
        return _buildStep4DescriptionAndAttachments(isDark, primaryColor);
      case 4:
        return _buildStep5SuccessConfirmation(isDark, primaryColor);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1PageSelection(bool isDark, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 1: Select Affected Page',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Select the specific page where you experienced an issue. Only pages authorized for your role are listed.',
          style: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<SupportCatalogPage>(
              value: _selectedPage,
              isExpanded: true,
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              items: widget.catalog.map((page) {
                return DropdownMenuItem<SupportCatalogPage>(
                  value: page,
                  child: Row(
                    children: [
                      Icon(Icons.article_outlined, size: 18, color: primaryColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          page.pageName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          page.category,
                          style: TextStyle(fontSize: 10, color: primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: _onPageChanged,
            ),
          ),
        ),
        if (_selectedPage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: primaryColor, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedPage!.description.isNotEmpty
                        ? _selectedPage!.description
                        : 'Page Route: ${_selectedPage!.pageKey}',
                    style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStep2FunctionSelection(bool isDark, Color primaryColor) {
    final functions = _selectedPage?.functions ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 2: Select Specific Function in "${_selectedPage?.pageName ?? 'Selected Page'}"',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose the exact button, tab, filter, form, or feature that failed or gave incorrect data.',
          style: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),
        if (functions.isEmpty)
          const Text('No specific subfunctions defined for this page.')
        else
          Column(
            children: functions.map((fn) {
              final isSelected = _selectedFunction?.key == fn.key;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor.withValues(alpha: 0.08)
                      : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? primaryColor
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: RadioListTile<SupportCatalogFunction>(
                  title: Text(
                    fn.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  value: fn,
                  groupValue: _selectedFunction,
                  activeColor: primaryColor,
                  onChanged: (val) {
                    setState(() => _selectedFunction = val);
                  },
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildStep3IssueTypeSelection(bool isDark, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 3: Select Issue Category',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Help us route your issue quickly by choosing the closest issue type.',
          style: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _issueTypes.map((type) {
            final isSelected = _issueType == type;
            return ChoiceChip(
              label: Text(type),
              selected: isSelected,
              selectedColor: primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              onSelected: (selected) {
                if (selected) setState(() => _issueType = type);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep4DescriptionAndAttachments(bool isDark, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 4: Priority & Detailed Description',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Describe the problem clearly. Mention any error message, unexpected count, or missing button.',
          style: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),

        // Priority Selection
        Row(
          children: [
            const Text('Priority Level:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(width: 14),
            Expanded(
              child: SegmentedButton<String>(
                segments: _priorities
                    .map((p) => ButtonSegment<String>(value: p, label: Text(p)))
                    .toList(),
                selected: {_priority},
                onSelectionChanged: (val) {
                  setState(() => _priority = val.first);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Description TextField
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: 'Provide detailed steps to reproduce the issue...',
            hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 14),

        // Optional Screenshot / Attachment Link
        TextField(
          controller: _attachmentUrlController,
          style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white : const Color(0xFF0F172A)),
          decoration: InputDecoration(
            labelText: 'Screenshot / Image Link (Optional)',
            hintText: 'https://...',
            prefixIcon: const Icon(Icons.link_rounded, size: 18),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep5SuccessConfirmation(bool isDark, Color primaryColor) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: CRMColors.success,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 16),
        const Text(
          'Support Ticket Created Successfully!',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Ticket ID: ${_submittedIssue?.ticketNumber ?? "SUP-1001"}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryColor),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Your issue has been logged and assigned for resolution. You can track updates and replies directly from your Support page.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
