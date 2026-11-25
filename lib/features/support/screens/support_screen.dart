import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/cloudinary_uploader.dart';
import '../../../core/design_system/tokens/app_breakpoints.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/security/admin_action_gate.dart';
import '../../../core/security/role_guard.dart';
import '../models/support_issue_model.dart';
import '../models/support_navigation_registry.dart';
import '../services/support_service.dart';
import '../widgets/issue_details_drawer.dart';
import '../widgets/support_ui/support_tokens.dart';
import '../widgets/support_ui/support_widgets.dart';

class SupportScreen extends StatefulWidget {
  final String? initialPageKey;

  const SupportScreen({
    super.key,
    this.initialPageKey,
  });

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _PartOption {
  final String pageKey;
  final String pageName;
  final SupportFunctionItem function;

  const _PartOption({
    required this.pageKey,
    required this.pageName,
    required this.function,
  });

  String get label => function.name;
}

class _SupportScreenState extends State<SupportScreen> {
  static const _defaultIssueTypes = [
    'Something is not working',
    'Data not saving',
    'Wrong numbers / data',
    'Page not loading / slow',
    'Question / how do I…',
    'Feature request',
    'Other',
  ];

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isUploadingShot = false;
  List<SupportIssue> _issues = [];
  SupportStats _stats = const SupportStats(
    total: 0,
    open: 0,
    inProgress: 0,
    waitingForUser: 0,
    resolved: 0,
    closed: 0,
  );

  /// all | Open | In Progress | Complete
  String _kpiFilter = 'all';
  String _statusFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _formKey = GlobalKey();

  List<SupportPageItem> _pages = [];
  SupportPageItem? _selectedPage;
  SupportSubpageItem? _selectedSubpage;
  _PartOption? _selectedPart;
  String? _issueType;
  String _priority = 'Medium';
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _attachmentUrl;
  String? _attachmentName;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _initPages();
    _loadData();
    if (widget.initialPageKey != null && widget.initialPageKey!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToForm());
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initPages() {
    final role = RoleGuard.currentUser?.role ?? '';
    _pages = SupportNavigationRegistry.getPagesForRole(role);

    if (widget.initialPageKey != null && widget.initialPageKey!.isNotEmpty) {
      final key = widget.initialPageKey!;
      for (final p in _pages) {
        if (p.route == key || p.key == key) {
          _selectedPage = p;
          break;
        }
        for (final sub in p.subpages) {
          if (sub.route == key || sub.key == key) {
            _selectedPage = p;
            _selectedSubpage = sub;
            break;
          }
        }
        if (_selectedPage != null) break;
      }
    }

    _selectedPage ??= _pages.isNotEmpty ? _pages.first : null;
    if (_selectedPage != null && _selectedPage!.hasSubpages && _selectedSubpage == null) {
      _selectedSubpage = _selectedPage!.subpages.isNotEmpty ? _selectedPage!.subpages.first : null;
    }
    final parts = _currentParts;
    _selectedPart = parts.isNotEmpty ? parts.first : null;
    final types = _currentIssueTypes;
    _issueType = types.isNotEmpty ? types.first : null;
  }

  List<_PartOption> get _currentParts {
    final page = _selectedPage;
    if (page == null) return const [];

    if (page.hasSubpages) {
      final sub = _selectedSubpage;
      if (sub == null) return const [];
      return sub.functions
          .map(
            (f) => _PartOption(
              pageKey: sub.route,
              pageName: '${page.title} → ${sub.title}',
              function: f,
            ),
          )
          .toList();
    }

    return page.directFunctions
        .map(
          (f) => _PartOption(
            pageKey: page.route,
            pageName: page.title,
            function: f,
          ),
        )
        .toList();
  }

  List<String> get _currentIssueTypes {
    final fn = _selectedPart?.function;
    if (fn == null) return _defaultIssueTypes;
    final opts = SupportNavigationRegistry.getIssueOptionsForFunction(fn);
    return opts.isNotEmpty ? opts : _defaultIssueTypes;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final statusForApi = _statusFilter == 'All' ? null : _statusFilter;
    final statsData = await SupportService.instance.fetchStats();
    final issuesData = await SupportService.instance.fetchIssues(
      status: statusForApi,
      search: _searchQuery,
      page: 1,
      limit: 50,
    );

    if (!mounted) return;
    setState(() {
      _stats = statsData;
      _issues = (issuesData['issues'] as List<SupportIssue>?) ?? [];
      _isLoading = false;
    });
  }

  List<SupportIssue> get _visibleIssues {
    if (_kpiFilter == 'all') return _issues;
    return _issues.where((i) {
      final n = _normalizeStatus(i.status);
      if (_kpiFilter == 'Complete') return n == 'Complete';
      return n == _kpiFilter;
    }).toList();
  }

  void _scrollToForm() {
    final ctx = _formKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  void _openIssueDetails(String issueId) {
    showDialog(
      context: context,
      builder: (ctx) => IssueDetailsDrawer(
        issueId: issueId,
        onUpdated: _loadData,
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return SuTokens.blue;
      case 'in progress':
        return SuTokens.amber;
      case 'complete':
      case 'resolved':
      case 'closed':
        return SuTokens.green2;
      default:
        return const Color(0xFF64748B);
    }
  }

  String _normalizeStatus(String status) {
    final lower = status.trim().toLowerCase();
    if (lower == 'open') return 'Open';
    if (lower == 'in progress') return 'In Progress';
    if (lower == 'complete' || lower == 'resolved' || lower == 'closed') return 'Complete';
    return 'Open';
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
      case 'high':
        return SuTokens.red;
      case 'medium':
        return SuTokens.amber;
      case 'low':
        return SuTokens.green;
      default:
        return const Color(0xFF64748B);
    }
  }

  Future<void> _launchExternal(Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $e')),
        );
      }
    }
  }

  Future<void> _pickScreenshot() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() {
      _isUploadingShot = true;
      _formError = null;
    });

    try {
      final bytes = await file.readAsBytes();
      if (bytes.length > 10 * 1024 * 1024) {
        throw Exception('Image size exceeds the 10 MB limit.');
      }
      final ext = file.name.split('.').last.toLowerCase();
      final isPng = ext == 'png';
      final url = await CloudinaryUploader.upload(
        bytes: bytes,
        filename: file.name,
        mimeType: isPng ? 'image/png' : 'image/jpeg',
        resourceType: 'image',
        fallbackEndpoint: '/properties/upload-media',
      );
      if (!mounted) return;
      setState(() {
        _attachmentUrl = url;
        _attachmentName = file.name;
        _isUploadingShot = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingShot = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload screenshot: $e'), backgroundColor: CRMColors.danger),
      );
    }
  }

  void _clearForm() {
    setState(() {
      _subjectController.clear();
      _descriptionController.clear();
      _attachmentUrl = null;
      _attachmentName = null;
      _priority = 'Medium';
      _formError = null;
      final types = _currentIssueTypes;
      _issueType = types.isNotEmpty ? types.first : null;
    });
  }

  Future<void> _submitTicket() async {
    if (!RoleGuard.canAction('page.support.report_issue')) return;

    final subject = _subjectController.text.trim();
    final description = _descriptionController.text.trim();
    if (subject.isEmpty || description.isEmpty) {
      setState(() => _formError = 'Please add a subject and a short description');
      return;
    }
    if (_selectedPage == null) {
      setState(() => _formError = 'Please select a page');
      return;
    }
    if (_selectedPage!.hasSubpages && _selectedSubpage == null) {
      setState(() => _formError = 'Please select a subpage');
      return;
    }
    if (_selectedPart == null) {
      setState(() => _formError = 'Please select the part of the page');
      return;
    }
    if (_issueType == null || _issueType!.isEmpty) {
      setState(() => _formError = 'Please select an issue type');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _formError = null;
    });

    try {
      final fullDescription = '$subject\n\n$description';
      final attachments = _attachmentUrl == null
          ? <Map<String, dynamic>>[]
          : [
              {
                'file_name': _attachmentName ?? 'screenshot',
                'file_path': _attachmentUrl,
                'file_type': 'image',
              },
            ];

      final issue = await SupportService.instance.createIssue(
        pageKey: _selectedPart!.pageKey,
        pageName: _selectedPart!.pageName,
        functionKey: _selectedPart!.function.key,
        functionName: _selectedPart!.function.name,
        issueType: _issueType!,
        priority: _priority,
        description: fullDescription,
        attachments: attachments,
      );

      if (!mounted) return;
      _clearForm();
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Ticket ${issue.ticketNumber} submitted · we’ll reply here and on WhatsApp'),
          backgroundColor: CRMColors.success,
        ),
      );
      await _loadData();
      _openIssueDetails(issue.id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _formError = e.toString().replaceAll('Exception:', '').trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final narrow = CRMBreakpoints.isPhone(context);
    final wide = CRMBreakpoints.widthOf(context) >= 1100;
    final padding = CRMBreakpoints.pagePadding(context);

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminActionGate(
          actionKey: 'page.support.report_issue',
          fallback: const SuHeroBanner(),
          child: SuHeroBanner(onRaiseTicket: _scrollToForm),
        ),
        const SizedBox(height: 16),
        SuKpiStrip(
          total: _stats.total,
          open: _stats.open,
          inProgress: _stats.inProgress,
          complete: _stats.complete,
          selected: _kpiFilter,
          onSelected: (v) {
            setState(() {
              _kpiFilter = v;
              _statusFilter = v == 'all' ? 'All' : v;
            });
            _loadData();
          },
        ),
        const SizedBox(height: 16),
        SuContactWays(
          onWhatsApp: () => _launchExternal(Uri.parse('https://wa.me/919999999999')),
          onCall: () => _launchExternal(Uri.parse('tel:+917900000000')),
          onEmail: () => _launchExternal(Uri.parse('mailto:support@nbpropertytech.com')),
        ),
        const SizedBox(height: 16),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: KeyedSubtree(key: _formKey, child: _buildRaiseForm(context))),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _buildTicketsCard(context),
                    const SizedBox(height: 16),
                    const SuFaqSection(),
                  ],
                ),
              ),
            ],
          )
        else ...[
          KeyedSubtree(key: _formKey, child: _buildRaiseForm(context)),
          const SizedBox(height: 16),
          _buildTicketsCard(context),
          const SizedBox(height: 16),
          const SuFaqSection(),
        ],
        if (narrow) const SizedBox(height: 24),
      ],
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(padding),
            child: body,
          ),
        ),
      ),
    );
  }

  Widget _buildRaiseForm(BuildContext context) {
    final canReport = RoleGuard.canAction('page.support.report_issue');
    final parts = _currentParts;
    final issueTypes = _currentIssueTypes;
    final hasSubpages = _selectedPage?.hasSubpages == true;

    return SuCardShell(
      title: 'Raise a ticket',
      subtitle: 'Tell us what went wrong — one short form',
      child: AbsorbPointer(
        absorbing: !canReport,
        child: Opacity(
          opacity: canReport ? 1 : 0.55,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Subject *', style: CRMTypography.captionBold.copyWith(color: SuTokens.ink2(context))),
              const SizedBox(height: 6),
              TextField(
                controller: _subjectController,
                decoration: suFieldDecoration(context, hint: 'e.g. Lead details not saving'),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stack = constraints.maxWidth < 520;
                  final pageField = _dropdownField<SupportPageItem>(
                    context,
                    label: 'Page *',
                    value: _selectedPage,
                    items: _pages,
                    labelOf: (p) => p.title,
                    onChanged: (p) {
                      if (p == null) return;
                      setState(() {
                        _selectedPage = p;
                        _selectedSubpage = p.hasSubpages && p.subpages.isNotEmpty ? p.subpages.first : null;
                        final nextParts = _currentParts;
                        _selectedPart = nextParts.isNotEmpty ? nextParts.first : null;
                        final types = _currentIssueTypes;
                        _issueType = types.isNotEmpty ? types.first : null;
                      });
                    },
                  );
                  final partOrSub = hasSubpages
                      ? _dropdownField<SupportSubpageItem>(
                          context,
                          label: 'Subpage *',
                          value: _selectedSubpage,
                          items: _selectedPage?.subpages ?? const [],
                          labelOf: (s) => s.title,
                          onChanged: (s) {
                            setState(() {
                              _selectedSubpage = s;
                              final nextParts = _currentParts;
                              _selectedPart = nextParts.isNotEmpty ? nextParts.first : null;
                              final types = _currentIssueTypes;
                              _issueType = types.isNotEmpty ? types.first : null;
                            });
                          },
                        )
                      : _dropdownField<_PartOption>(
                          context,
                          label: 'Part of the page *',
                          value: _selectedPart,
                          items: parts,
                          labelOf: (p) => p.label,
                          onChanged: (p) {
                            setState(() {
                              _selectedPart = p;
                              final types = _currentIssueTypes;
                              _issueType = types.isNotEmpty ? types.first : null;
                            });
                          },
                        );

                  if (stack) {
                    return Column(
                      children: [
                        pageField,
                        const SizedBox(height: 12),
                        partOrSub,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: pageField),
                      const SizedBox(width: 12),
                      Expanded(child: partOrSub),
                    ],
                  );
                },
              ),
              if (hasSubpages) ...[
                const SizedBox(height: 12),
                _dropdownField<_PartOption>(
                  context,
                  label: 'Part of the page *',
                  value: _selectedPart,
                  items: parts,
                  labelOf: (p) => p.label,
                  onChanged: (p) {
                    setState(() {
                      _selectedPart = p;
                      final types = _currentIssueTypes;
                      _issueType = types.isNotEmpty ? types.first : null;
                    });
                  },
                ),
              ],
              const SizedBox(height: 12),
              _dropdownField<String>(
                context,
                label: 'Type',
                value: issueTypes.contains(_issueType) ? _issueType : (issueTypes.isNotEmpty ? issueTypes.first : null),
                items: issueTypes,
                labelOf: (s) => s,
                onChanged: (v) => setState(() => _issueType = v),
              ),
              const SizedBox(height: 12),
              Text('Describe the issue *', style: CRMTypography.captionBold.copyWith(color: SuTokens.ink2(context))),
              const SizedBox(height: 6),
              TextField(
                controller: _descriptionController,
                minLines: 4,
                maxLines: 6,
                decoration: suFieldDecoration(
                  context,
                  hint: 'What did you click, what did you expect, what happened instead?',
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _isUploadingShot ? null : _pickScreenshot,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: SuTokens.line(context), style: BorderStyle.solid, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      if (_isUploadingShot)
                        const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      else
                        Icon(Icons.attach_file_rounded, size: 18, color: SuTokens.muted(context)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _attachmentName == null
                              ? '📎 Add a screenshot (optional)'
                              : '📎 ${_attachmentName!}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CRMTypography.caption.copyWith(
                            fontSize: 12.5,
                            color: SuTokens.ink2(context),
                            fontWeight: _attachmentName == null ? FontWeight.w400 : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (_attachmentName != null)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => setState(() {
                            _attachmentUrl = null;
                            _attachmentName = null;
                          }),
                          icon: const Icon(Icons.close_rounded, size: 16),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('Priority', style: CRMTypography.captionBold.copyWith(fontSize: 11.5, color: SuTokens.ink2(context))),
              const SizedBox(height: 5),
              SuPriorityPicker(
                selected: _priority,
                onChanged: (v) => setState(() => _priority = v),
              ),
              if (_formError != null) ...[
                const SizedBox(height: 12),
                Text(_formError!, style: CRMTypography.caption.copyWith(color: SuTokens.red)),
              ],
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: _isSubmitting ? null : _clearForm,
                    child: const Text('Clear'),
                  ),
                  FilledButton(
                    onPressed: (_isSubmitting || !canReport) ? null : _submitTicket,
                    style: FilledButton.styleFrom(backgroundColor: SuTokens.green),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Submit ticket'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdownField<T>(
    BuildContext context, {
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) labelOf,
    required ValueChanged<T?> onChanged,
  }) {
    final safeValue = value != null && items.contains(value) ? value : (items.isNotEmpty ? items.first : null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: CRMTypography.captionBold.copyWith(color: SuTokens.ink2(context))),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: SuTokens.panel(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: SuTokens.line(context)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: safeValue,
              isExpanded: true,
              isDense: true,
              borderRadius: BorderRadius.circular(10),
              hint: Text('Select', style: CRMTypography.caption.copyWith(color: SuTokens.muted(context))),
              items: items
                  .map(
                    (item) => DropdownMenuItem<T>(
                      value: item,
                      child: Text(labelOf(item), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: items.isEmpty ? null : onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTicketsCard(BuildContext context) {
    final visible = _visibleIssues;
    final openCount = _stats.open + _stats.inProgress;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: SuTokens.panel(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SuTokens.line(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My tickets',
                  style: CRMTypography.bodyMedium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: SuTokens.ink(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$openCount open · ${_stats.total} total',
                  style: CRMTypography.caption.copyWith(fontSize: 12, color: SuTokens.muted(context)),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: SuTokens.line(context)),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stack = constraints.maxWidth < 480;
                final search = TextField(
                  controller: _searchController,
                  decoration: suFieldDecoration(
                    context,
                    hint: 'Search ticket #, page or issue',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  ),
                  onChanged: (val) {
                    _searchQuery = val.trim();
                    _searchDebounce?.cancel();
                    _searchDebounce = Timer(const Duration(milliseconds: 250), _loadData);
                  },
                );
                final status = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: SuTokens.line(context)),
                    color: SuTokens.panel(context),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _statusFilter,
                      isDense: true,
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('Status: All')),
                        DropdownMenuItem(value: 'Open', child: Text('Open')),
                        DropdownMenuItem(value: 'In Progress', child: Text('In progress')),
                        DropdownMenuItem(value: 'Complete', child: Text('Complete')),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _statusFilter = v;
                          _kpiFilter = v == 'All' ? 'all' : v;
                        });
                        _loadData();
                      },
                    ),
                  ),
                );

                if (stack) {
                  return Column(
                    children: [
                      search,
                      const SizedBox(height: 8),
                      Align(alignment: Alignment.centerLeft, child: status),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: search),
                    const SizedBox(width: 8),
                    status,
                  ],
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              child: Text(
                'No tickets here.',
                style: CRMTypography.body.copyWith(fontSize: 13, color: SuTokens.muted(context)),
              ),
            )
          else
            ...visible.map((issue) {
              final subject = issue.description.split('\n').first.trim().isNotEmpty
                  ? issue.description.split('\n').first.trim()
                  : '${issue.pageName} → ${issue.functionName}';
              return SuTicketRow(
                subject: subject,
                meta:
                    '${issue.ticketNumber} · ${issue.pageName} → ${issue.functionName} · ${DateFormat('d MMM, h:mm a').format(issue.createdAt)}',
                status: _normalizeStatus(issue.status),
                priority: issue.priority,
                statusColor: _statusColor(issue.status),
                priorityColor: _priorityColor(issue.priority),
                onTap: () => _openIssueDetails(issue.id),
              );
            }),
        ],
      ),
    );
  }
}
