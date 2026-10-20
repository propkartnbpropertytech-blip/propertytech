import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../../core/api/cloudinary_uploader.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/widgets/crm_network_image.dart';
import '../../../core/design_system/widgets/drawers.dart';
import '../../../core/security/role_guard.dart';
import '../../../core/theme/theme_manager.dart';
import '../models/support_issue_model.dart';
import '../models/support_navigation_registry.dart';
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
  int _currentStep = 0; // 0: Page/Subpage, 1: Function, 2: Problem, 3: Description, 4: Success

  List<SupportPageItem> _pages = [];
  SupportPageItem? _selectedPage;
  SupportSubpageItem? _selectedSubpage;
  final Set<String> _expandedPages = {};

  SupportFunctionItem? _selectedFunction;
  String? _issueType;
  String _priority = 'Medium';
  final TextEditingController _descriptionController = TextEditingController();
  final List<String> _uploadedImages = [];
  final List<String?> _uploadedSlotUrls = [null, null, null];
  final List<bool> _slotUploading = [false, false, false];

  bool _isSubmitting = false;
  String? _errorMessage;
  SupportIssue? _submittedIssue;

  final List<String> _priorities = const ['Low', 'Medium', 'High', 'Critical'];

  @override
  void initState() {
    super.initState();
    _initRolePages();
  }

  void _initRolePages() {
    final userRole = RoleGuard.currentUser?.role ?? '';
    _pages = SupportNavigationRegistry.getPagesForRole(userRole);

    // If initialPageKey is provided, pre-select corresponding page/subpage
    if (widget.initialPageKey != null && widget.initialPageKey!.isNotEmpty && _pages.isNotEmpty) {
      final key = widget.initialPageKey!;
      for (final p in _pages) {
        if (p.route == key || p.key == key) {
          _selectedPage = p;
          if (p.hasSubpages) {
            _expandedPages.add(p.key);
          }
          break;
        }
        for (final sub in p.subpages) {
          if (sub.route == key || sub.key == key) {
            _selectedPage = p;
            _selectedSubpage = sub;
            _expandedPages.add(p.key);
            break;
          }
        }
        if (_selectedPage != null) break;
      }
    }

    // Default to first page if not selected
    if (_selectedPage == null && _pages.isNotEmpty) {
      _selectedPage = _pages.first;
      if (_selectedPage!.hasSubpages) {
        _expandedPages.add(_selectedPage!.key);
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _onPageSelected(SupportPageItem page) {
    setState(() {
      _selectedPage = page;
      _selectedSubpage = null;
      _selectedFunction = null;
      _issueType = null;
      _errorMessage = null;

      if (page.hasSubpages) {
        if (!_expandedPages.contains(page.key)) {
          _expandedPages.add(page.key);
        }
      }
    });
  }

  void _onSubpageSelected(SupportPageItem parentPage, SupportSubpageItem subpage) {
    setState(() {
      _selectedPage = parentPage;
      _selectedSubpage = subpage;
      _selectedFunction = null;
      _issueType = null;
      _errorMessage = null;
    });
  }

  void _togglePageExpansion(String pageKey) {
    setState(() {
      if (_expandedPages.contains(pageKey)) {
        _expandedPages.remove(pageKey);
      } else {
        _expandedPages.add(pageKey);
      }
    });
  }

  List<SupportFunctionItem> get _currentFunctions {
    if (_selectedSubpage != null) {
      return _selectedSubpage!.functions;
    }
    if (_selectedPage != null) {
      return _selectedPage!.directFunctions;
    }
    return const [];
  }

  String get _currentSelectionDisplayName {
    if (_selectedPage == null) return 'None';
    if (_selectedSubpage != null) {
      return '${_selectedPage!.title} → ${_selectedSubpage!.title}';
    }
    return _selectedPage!.title;
  }

  Future<void> _submitTicket() async {
    if (_selectedPage == null) {
      setState(() => _errorMessage = 'Please select a page.');
      return;
    }
    if (_selectedPage!.hasSubpages && _selectedSubpage == null) {
      setState(() => _errorMessage = 'Please select a specific subpage under "${_selectedPage!.title}".');
      return;
    }
    if (_selectedFunction == null) {
      setState(() => _errorMessage = 'Please select a function or KPI.');
      return;
    }
    if (_issueType == null || _issueType!.isEmpty) {
      setState(() => _errorMessage = 'Please select the problem you experienced.');
      return;
    }

    final rawDesc = _descriptionController.text.trim();
    if (_issueType == 'Other' && rawDesc.length < 5) {
      setState(() => _errorMessage = 'Please provide a detailed explanation of the issue (at least 5 characters).');
      return;
    }

    final desc = rawDesc.isNotEmpty
        ? rawDesc
        : '[$_issueType] reported for ${_selectedFunction!.name} in $_currentSelectionDisplayName';

    if (desc.length < 5) {
      setState(() => _errorMessage = 'Description must be at least 5 characters long.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final attachments = _uploadedImages.map((url) {
        final uriParts = url.split('/').last.split('?').first;
        return {
          'file_name': uriParts.isNotEmpty ? uriParts : 'Issue Screenshot',
          'file_path': url,
          'file_type': 'image',
        };
      }).toList();

      final pageKey = _selectedSubpage?.route ?? _selectedPage!.route;
      final pageName = _currentSelectionDisplayName;

      final issue = await SupportService.instance.createIssue(
        pageKey: pageKey,
        pageName: pageName,
        functionKey: _selectedFunction!.key,
        functionName: _selectedFunction!.name,
        issueType: _issueType!,
        priority: _priority,
        description: desc,
        attachments: attachments,
      );

      if (mounted) {
        setState(() {
          _submittedIssue = issue;
          _isSubmitting = false;
          _currentStep = 4; // Step 5 Success Screen
        });
        widget.onSubmitted();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = ThemeManager().primaryColor;
    final screenSize = MediaQuery.of(context).size;
    final modalWidth = math.min(screenSize.width - 32, 680.0);
    final modalHeight = math.min(screenSize.height - 40, 760.0);

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: modalWidth,
        height: modalHeight,
        padding: const EdgeInsets.all(24),
        child: Column(
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
                        _getStepSubtitle(),
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
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Step Progress Bar (5 Steps)
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
            const SizedBox(height: 16),

            // Error banner if any
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 14),
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

            // Current Step Body (Scrollable)
            Expanded(
              child: SingleChildScrollView(
                child: _buildStepBody(isDark, primaryColor),
              ),
            ),

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Footer Actions
            _buildFooter(isDark, primaryColor),
          ],
        ),
      ),
    );
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0:
        return 'Step 1 of 5 — Select affected page or subpage';
      case 1:
        return 'Step 2 of 5 — Select function or KPI';
      case 2:
        return 'Step 3 of 5 — Select problem experienced';
      case 3:
        return 'Step 4 of 5 — Detailed description & remarks';
      case 4:
        return 'Step 5 of 5 — Issue submitted successfully';
      default:
        return '';
    }
  }

  Widget _buildStepBody(bool isDark, Color primaryColor) {
    switch (_currentStep) {
      case 0:
        return _buildStep1PageSelection(isDark, primaryColor);
      case 1:
        return _buildStep2FunctionSelection(isDark, primaryColor);
      case 2:
        return _buildStep3ProblemSelection(isDark, primaryColor);
      case 3:
        return _buildStep4DescriptionRemarks(isDark, primaryColor);
      case 4:
        return _buildStep5Success(isDark, primaryColor);
      default:
        return const SizedBox.shrink();
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STEP 1: Select Page / Subpage (Role-Based Dynamic Tree)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildStep1PageSelection(bool isDark, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 1: Select Page / Subpage',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose the exact sidebar page or nested subpage where the issue occurred. Only pages authorized for your role are displayed.',
          style: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),

        if (_pages.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.center,
            child: const Text('No accessible pages found for your current role.'),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pages.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final page = _pages[index];
              return _buildPageItemCard(page, isDark, primaryColor);
            },
          ),

        const SizedBox(height: 14),

        // Selected indicator summary pill
        if (_selectedPage != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: primaryColor, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      children: [
                        const TextSpan(text: 'Selected Target: ', style: TextStyle(fontWeight: FontWeight.w600)),
                        TextSpan(
                          text: _currentSelectionDisplayName,
                          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                        ),
                        if (_selectedPage!.hasSubpages && _selectedSubpage == null)
                          const TextSpan(
                            text: '  (Please click a subpage below to continue)',
                            style: TextStyle(color: Color(0xFFE11D48), fontWeight: FontWeight.bold, fontSize: 11.5),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPageItemCard(SupportPageItem page, bool isDark, Color primaryColor) {
    final isSelectedPage = _selectedPage?.key == page.key;
    final isExpanded = _expandedPages.contains(page.key);
    final hasSubpages = page.hasSubpages;
    final isDirectlySelected = isSelectedPage && _selectedSubpage == null;

    return Container(
      decoration: BoxDecoration(
        color: isSelectedPage
            ? (isDark ? const Color(0xFF1E293B) : Colors.white)
            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelectedPage
              ? primaryColor
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isSelectedPage ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Page Header Row
          InkWell(
            onTap: () {
              if (hasSubpages) {
                _togglePageExpansion(page.key);
                // Also set page as selected if not yet
                if (_selectedPage?.key != page.key) {
                  _onPageSelected(page);
                }
              } else {
                _onPageSelected(page);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelectedPage
                          ? primaryColor.withValues(alpha: 0.15)
                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFEDF2F7)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      page.icon,
                      size: 20,
                      color: isSelectedPage ? primaryColor : (isDark ? Colors.white70 : const Color(0xFF4A5568)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              page.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelectedPage ? FontWeight.bold : FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            if (hasSubpages) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${page.subpages.length} Subpages',
                                  style: TextStyle(fontSize: 10, color: primaryColor, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (page.description != null && page.description!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            page.description!,
                            style: TextStyle(fontSize: 11.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Trailing indicator: Expansion arrow for subpages, or Radio check for direct page
                  if (hasSubpages)
                    IconButton(
                      icon: Icon(
                        isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        size: 22,
                      ),
                      onPressed: () => _togglePageExpansion(page.key),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    )
                  else
                    _buildRadioIndicator(isDirectlySelected, primaryColor),
                ],
              ),
            ),
          ),

          // Subpages expansion list
          if (hasSubpages && isExpanded) ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.only(left: 20, right: 12, top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF090D16).withValues(alpha: 0.5) : const Color(0xFFF1F5F9).withValues(alpha: 0.6),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                children: page.subpages.map((subpage) {
                  final isSubSelected = isSelectedPage && _selectedSubpage?.key == subpage.key;
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(
                      color: isSubSelected
                          ? primaryColor.withValues(alpha: 0.12)
                          : (isDark ? const Color(0xFF1E293B) : Colors.white),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSubSelected
                            ? primaryColor
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        width: isSubSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _onSubpageSelected(page, subpage),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          child: Row(
                            children: [
                              Icon(
                                subpage.icon,
                                size: 18,
                                color: isSubSelected ? primaryColor : (isDark ? Colors.white70 : const Color(0xFF4A5568)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      subpage.title,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSubSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    if (subpage.description != null && subpage.description!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        subpage.description!,
                                        style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildRadioIndicator(isSubSelected, primaryColor),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STEP 2: Select Function / Individual KPI Card
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildStep2FunctionSelection(bool isDark, Color primaryColor) {
    final functions = _currentFunctions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 2: Select Specific Function in "$_currentSelectionDisplayName"',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose the exact KPI card, button, tab, filter, form, or feature that failed or gave incorrect data.',
          style: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),

        if (functions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: const Text('No specific subfunctions registered for this page. Click Next to report a general issue.'),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: functions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final fn = functions[index];
              final isSelected = _selectedFunction?.key == fn.key;

              return Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor.withValues(alpha: 0.1)
                      : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? primaryColor
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      setState(() {
                        _selectedFunction = fn;
                        _issueType = null;
                        _errorMessage = null;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primaryColor.withValues(alpha: 0.2)
                                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFEDF2F7)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              fn.icon ?? Icons.extension_outlined,
                              size: 18,
                              color: isSelected ? primaryColor : (isDark ? Colors.white70 : const Color(0xFF4A5568)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              fn.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          if (fn.badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(left: 6, right: 8),
                              decoration: BoxDecoration(
                                color: fn.category == SupportFunctionCategory.kpi
                                    ? const Color(0xFF0EA5E9).withValues(alpha: 0.15)
                                    : primaryColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                fn.badge!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: fn.category == SupportFunctionCategory.kpi
                                      ? const Color(0xFF0284C7)
                                      : primaryColor,
                                ),
                              ),
                            ),
                          _buildRadioIndicator(isSelected, primaryColor),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STEP 3: Select Problem Related to Chosen Function
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildStep3ProblemSelection(bool isDark, Color primaryColor) {
    final fn = _selectedFunction;
    final options = fn != null
        ? SupportNavigationRegistry.getIssueOptionsForFunction(fn)
        : const ['Function not working', 'Incorrect data or count', 'Other'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 3: What problem are you experiencing with "${fn?.name ?? 'Selected Function'}"?',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Select the specific problem that describes what failed. If none match, choose Other to explain in your own words.',
          style: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: options.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final opt = options[index];
            final isSelected = _issueType == opt;
            final isOther = opt == 'Other';

            return Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor.withValues(alpha: 0.1)
                    : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? primaryColor
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    setState(() {
                      _issueType = opt;
                      _errorMessage = null;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          isOther ? Icons.edit_note_rounded : Icons.report_problem_outlined,
                          size: 20,
                          color: isSelected
                              ? primaryColor
                              : (isOther
                                  ? const Color(0xFFF59E0B)
                                  : (isDark ? Colors.white60 : const Color(0xFF64748B))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            opt,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                  : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildRadioIndicator(isSelected, primaryColor),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STEP 4: Issue Description & Other Remarks
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildStep4DescriptionRemarks(bool isDark, Color primaryColor) {
    final isOther = _issueType == 'Other';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isOther) ...[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.mode_edit_outline_rounded, color: Color(0xFFD97706), size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Other — Please describe the issue',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Explain the problem in your own words. Please provide detailed steps, what you clicked, and what was unexpected.',
            style: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ] else ...[
          Text(
            'Step 4: Priority & Remarks for "$_issueType"',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Add any additional observations, error messages, or context to help our engineering team resolve this promptly.',
            style: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ],

        const SizedBox(height: 16),

        // Issue Context Summary Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildContextRow('Target Page', _currentSelectionDisplayName, isDark),
              const SizedBox(height: 6),
              _buildContextRow('Function / KPI', _selectedFunction?.name ?? '', isDark),
              const SizedBox(height: 6),
              _buildContextRow('Problem Type', _issueType ?? 'Other', isDark),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Priority Level Selector
        Row(
          children: [
            const Text('Priority Level:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(width: 14),
            Expanded(
              child: SegmentedButton<String>(
                segments: _priorities
                    .map((p) => ButtonSegment<String>(value: p, label: Text(p, style: const TextStyle(fontSize: 12))))
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

        // Detailed Description TextField
        Text(
          isOther ? 'Detailed Description *' : 'Description / Steps to Reproduce',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: isOther
                ? 'Please explain the issue here in detail so our team can investigate...'
                : 'Provide optional remarks, specific lead/property IDs, or steps to reproduce...',
            hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 12.5),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),

        const SizedBox(height: 16),

        // Three dedicated Screenshot Upload Fields with Image Previews
        _buildThreeImageUploadFields(isDark, primaryColor),
      ],
    );
  }

  void _syncUploadedImages() {
    _uploadedImages.clear();
    for (final url in _uploadedSlotUrls) {
      if (url != null && url.trim().isNotEmpty) {
        _uploadedImages.add(url.trim());
      }
    }
  }

  Future<void> _pickImageForSlot(int slotIndex) async {
    if (!kIsWeb && Platform.isWindows) {
      await _pickAndUploadSlotImages(slotIndex, ImageSource.gallery);
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: Text('Take Photo (Screenshot ${slotIndex + 1})'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadSlotImages(slotIndex, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text('Choose from Gallery (Screenshot ${slotIndex + 1})'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadSlotImages(slotIndex, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadSlotImages(int slotIndex, ImageSource source) async {
    final picker = ImagePicker();
    final List<XFile> pickedFiles = [];

    if (source == ImageSource.gallery) {
      try {
        final multi = await picker.pickMultiImage();
        if (multi.isNotEmpty) {
          pickedFiles.addAll(multi);
        }
      } catch (_) {
        final single = await picker.pickImage(source: source);
        if (single != null) pickedFiles.add(single);
      }
    } else {
      final single = await picker.pickImage(source: source);
      if (single != null) pickedFiles.add(single);
    }

    if (pickedFiles.isEmpty) return;

    // Distribute picked files: first to target slot, then to any subsequent empty slots
    final slotsToFill = <int>[slotIndex];
    for (int i = 0; i < 3; i++) {
      if (i != slotIndex && _uploadedSlotUrls[i] == null) {
        slotsToFill.add(i);
      }
    }

    final countToProcess = math.min(pickedFiles.length, slotsToFill.length);

    for (int i = 0; i < countToProcess; i++) {
      final targetSlot = slotsToFill[i];
      final pickedFile = pickedFiles[i];

      setState(() {
        _slotUploading[targetSlot] = true;
      });

      try {
        final String fileExt = pickedFile.name.split('.').last.toLowerCase();
        final bool isPng = fileExt == 'png';
        final String mimeType = isPng ? 'image/png' : 'image/jpeg';
        List<int> uploadBytes;
        String filename = pickedFile.name;

        if (kIsWeb || (!kIsWeb && Platform.isWindows)) {
          uploadBytes = await pickedFile.readAsBytes();
          if (uploadBytes.length > 10 * 1024 * 1024) {
            throw Exception("Image size exceeds the 10 MB limit.");
          }
        } else {
          final File file = File(pickedFile.path);
          File uploadFile = file;

          try {
            final String targetPath =
                "${Directory.systemTemp.path}/support_img_${DateTime.now().millisecondsSinceEpoch}_$targetSlot.${isPng ? 'png' : 'jpg'}";
            final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
              file.absolute.path,
              targetPath,
              quality: 75,
              format: isPng ? CompressFormat.png : CompressFormat.jpeg,
              minWidth: 1200,
              minHeight: 1200,
            );
            if (compressedFile != null) {
              uploadFile = File(compressedFile.path);
              filename = isPng ? 'screenshot_${targetSlot + 1}.png' : 'screenshot_${targetSlot + 1}.jpg';
            }
          } catch (compressErr) {
            debugPrint("Image compression fallback: $compressErr");
            uploadFile = file;
          }

          uploadBytes = await uploadFile.readAsBytes();
          if (uploadBytes.length > 10 * 1024 * 1024) {
            throw Exception("Image size exceeds the 10 MB limit.");
          }
        }

        final publicUrl = await CloudinaryUploader.upload(
          bytes: uploadBytes,
          filename: filename,
          mimeType: mimeType,
          resourceType: 'image',
          fallbackEndpoint: '/properties/upload-media',
        );

        if (mounted) {
          setState(() {
            _uploadedSlotUrls[targetSlot] = publicUrl;
            _slotUploading[targetSlot] = false;
            _syncUploadedImages();
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _slotUploading[targetSlot] = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to upload Screenshot ${targetSlot + 1}: $e"),
              backgroundColor: CRMColors.danger,
            ),
          );
        }
      }
    }
  }

  Widget _buildThreeImageUploadFields(bool isDark, Color primaryColor) {
    final uploadedCount = _uploadedImages.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Attach Screenshots (Optional)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$uploadedCount/3 Uploaded',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                ),
              ],
            ),
            if (_slotUploading.contains(true))
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Uploading...',
                    style: TextStyle(fontSize: 11, color: primaryColor, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Upload up to 3 screenshots so support can easily inspect the problem. Previews appear immediately in each field.',
          style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 520;
            if (isNarrow) {
              return Column(
                children: List.generate(3, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildUploadSlotCard(index, isDark, primaryColor, height: 140),
                  );
                }),
              );
            } else {
              return Row(
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index < 2 ? 10 : 0,
                      ),
                      child: _buildUploadSlotCard(index, isDark, primaryColor, height: 155),
                    ),
                  );
                }),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildUploadSlotCard(int slotIndex, bool isDark, Color primaryColor, {required double height}) {
    final isUploading = _slotUploading[slotIndex];
    final imageUrl = _uploadedSlotUrls[slotIndex];
    final slotTitle = 'Screenshot ${slotIndex + 1}';

    // 1. Uploading State
    if (isUploading) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: primaryColor.withValues(alpha: 0.5)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: primaryColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Uploading $slotTitle...',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Uploaded State: Clear Image Preview Visible In Respective Field!
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Display uploaded image preview
              CrmNetworkImage(
                url: imageUrl,
                fit: BoxFit.cover,
                cacheLogicalWidth: 400,
                cacheLogicalHeight: 300,
                placeholder: (ctx) => Container(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (ctx) => Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    child: const Center(
                      child: Icon(Icons.broken_image_rounded, size: 28, color: Colors.grey),
                    ),
                  ),
                ),
              ),

              // Gradient overlay at top for contrast
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 38,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Top Left Badge: "Screenshot N"
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text(
                        slotTitle,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Top Right Actions: Zoom, Replace, Delete
              Positioned(
                top: 6,
                right: 6,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Zoom
                    _buildSlotIconButton(
                      icon: Icons.zoom_in_rounded,
                      tooltip: 'View Full Preview',
                      onTap: () {
                        final activeUrls = _uploadedSlotUrls.whereType<String>().toList();
                        final idx = activeUrls.indexOf(imageUrl);
                        showDialog(
                          context: context,
                          barrierColor: Colors.black.withValues(alpha: 0.9),
                          builder: (ctx) => CRMImageZoomViewer(
                            images: activeUrls,
                            initialIndex: idx >= 0 ? idx : 0,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    // Replace
                    _buildSlotIconButton(
                      icon: Icons.refresh_rounded,
                      tooltip: 'Replace $slotTitle',
                      onTap: () => _pickImageForSlot(slotIndex),
                    ),
                    const SizedBox(width: 4),
                    // Remove
                    _buildSlotIconButton(
                      icon: Icons.delete_outline_rounded,
                      tooltip: 'Remove $slotTitle',
                      color: const Color(0xFFEF4444),
                      onTap: () {
                        setState(() {
                          _uploadedSlotUrls[slotIndex] = null;
                          _syncUploadedImages();
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Tap anywhere on image to zoom preview
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      final activeUrls = _uploadedSlotUrls.whereType<String>().toList();
                      final idx = activeUrls.indexOf(imageUrl);
                      showDialog(
                        context: context,
                        barrierColor: Colors.black.withValues(alpha: 0.9),
                        builder: (ctx) => CRMImageZoomViewer(
                          images: activeUrls,
                          initialIndex: idx >= 0 ? idx : 0,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Empty State: Distinct Upload Field
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _pickImageForSlot(slotIndex),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add_photo_alternate_outlined, size: 22, color: primaryColor),
              ),
              const SizedBox(height: 8),
              Text(
                slotTitle,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Click to upload',
                style: TextStyle(
                  fontSize: 10.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlotIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(icon, size: 14, color: color),
          ),
        ),
      ),
    );
  }

  Widget _buildContextRow(String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
        const Text(': ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRadioIndicator(bool isSelected, Color primaryColor) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? primaryColor : const Color(0xFF94A3B8),
          width: 2,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor,
                ),
              ),
            )
          : null,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STEP 5: Success Confirmation
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildStep5Success(bool isDark, Color primaryColor) {
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
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              _buildContextRow('Reported Page', _submittedIssue?.pageName ?? _currentSelectionDisplayName, isDark),
              const SizedBox(height: 8),
              _buildContextRow('Function / KPI', _submittedIssue?.functionName ?? _selectedFunction?.name ?? '', isDark),
              const SizedBox(height: 8),
              _buildContextRow('Problem Type', _submittedIssue?.issueType ?? _issueType ?? '', isDark),
              const SizedBox(height: 8),
              _buildContextRow('Priority', _submittedIssue?.priority ?? _priority, isDark),
              if (_uploadedImages.isNotEmpty) ...[
                const SizedBox(height: 12),
                Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        'Screenshots',
                        style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      ),
                    ),
                    const Text(': ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _uploadedImages.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final url = entry.value;
                          return InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                barrierColor: Colors.black.withValues(alpha: 0.9),
                                builder: (ctx) => CRMImageZoomViewer(
                                  images: _uploadedImages,
                                  initialIndex: idx,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Stack(
                                children: [
                                  CrmNetworkImage(
                                    url: url,
                                    width: 58,
                                    height: 58,
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      color: Colors.black.withValues(alpha: 0.65),
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Text(
                                        '#${idx + 1}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 18),
        Text(
          'Your ticket has been logged and assigned to Super Admin for investigation. You can monitor responses, post updates, and chat with the admin directly from your Support page.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // FOOTER ACTIONS
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildFooter(bool isDark, Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0 && _currentStep < 4)
          OutlinedButton.icon(
            onPressed: () => setState(() => _currentStep--),
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('Previous'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          )
        else
          const SizedBox.shrink(),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_currentStep < 4) ...[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
            ],

            if (_currentStep == 0)
              ElevatedButton.icon(
                onPressed: () {
                  if (_selectedPage == null) {
                    setState(() => _errorMessage = 'Please select an affected page.');
                    return;
                  }
                  if (_selectedPage!.hasSubpages && _selectedSubpage == null) {
                    setState(() => _errorMessage = 'Please select a specific subpage under "${_selectedPage!.title}".');
                    return;
                  }
                  setState(() {
                    _errorMessage = null;
                    _currentStep = 1;
                  });
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('Next Step'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              )
            else if (_currentStep == 1)
              ElevatedButton.icon(
                onPressed: () {
                  if (_selectedFunction == null) {
                    setState(() => _errorMessage = 'Please select a specific function or KPI.');
                    return;
                  }
                  setState(() {
                    _errorMessage = null;
                    _currentStep = 2;
                  });
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('Next Step'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              )
            else if (_currentStep == 2)
              ElevatedButton.icon(
                onPressed: () {
                  if (_issueType == null || _issueType!.isEmpty) {
                    setState(() => _errorMessage = 'Please select the problem you are experiencing.');
                    return;
                  }
                  setState(() {
                    _errorMessage = null;
                    _currentStep = 3;
                  });
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('Next Step'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                label: Text(_isSubmitting ? 'Submitting...' : 'Submit Ticket'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              )
            else
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                child: const Text('Done / Close'),
              ),
          ],
        ),
      ],
    );
  }
}
