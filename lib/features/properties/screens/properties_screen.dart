import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/tokens/app_shadows.dart';
import '../../../core/design_system/tokens/app_motion.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/crm_page_header.dart';
import '../../../core/design_system/widgets/crm_network_image.dart';
import '../../../core/design_system/widgets/data_table.dart';
import '../../../core/design_system/widgets/drawers.dart';
import '../../../core/design_system/widgets/form/crm_multi_select_dropdown.dart';
import '../../auth/bloc/auth_bloc.dart';
import 'package:flutter/services.dart';
import '../../auth/models/user_model.dart';
import '../bloc/properties_bloc.dart';
import '../models/property_model.dart';
import '../repository/properties_repository.dart';
import 'add_edit_property_screen.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/budget_formatter.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/config/app_config.dart';
import '../../../core/utils/file_downloader.dart';
import '../../requirements/utils/property_share_pdf.dart';

import '../../requirements/models/requirement_model.dart';
import '../../requirements/repository/requirements_repository.dart';
import '../../../core/theme/theme_manager.dart';

class PropertiesScreen extends StatefulWidget {
  final String? openPropertyId;
  const PropertiesScreen({super.key, this.openPropertyId});

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _highlightedPropertyId;
  String _activeTab = 'All';
  String get _activeListingTab => ThemeManager().isRentMode ? 'Rent' : 'Re-Sale';
  set _activeListingTab(String value) {
    ThemeManager().setRentMode(value == 'Rent');
  }
  String _activeCategoryTab = 'Residential';
  String? _activeBhkFilter;
  bool _hasAutoOpenedAdd = false;
  String? _lastOpenedKey;
  String? _selectedCategory;
  final List<String> _selectedConfigurations = [];
  final List<String> _selectedAreas = [];
  String? _selectedListingType;
  bool? _selectedVerification;
  PropertyMetadataModel? _cachedMetadata;
  String? _selectedPriceSortOrRange;
  double? _minPrice;
  double? _maxPrice;
  int _currentPage = 0;
  int _pageSize = 10;
  bool _myAddedOnly = false;
  bool _archiveTabOnly = false;
  final Set<String> _archivedPropertyIds = {};
  String? _selectedStatusFilter;
  bool _isMobileFiltersExpanded = false;
  bool _noImagesOnly = false;
  bool _isTableView = false;
  final Set<String> _selectedPropertyIds = {};

  static const _pageSizeOptions = [10, 25, 50];

  @override
  void initState() {
    super.initState();
    _loadArchivedPropertyIds();
    _loadProperties();
  }

  void _loadArchivedPropertyIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('archived_property_ids') ?? [];
    if (mounted) {
      setState(() {
        _archivedPropertyIds.clear();
        _archivedPropertyIds.addAll(list);
      });
    }
  }

  void _saveArchivedPropertyIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('archived_property_ids', _archivedPropertyIds.toList());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadProperties() {
    context.read<PropertiesBloc>().add(
          LoadPropertiesEvent(
            activeTab: _activeTab,
          ),
        );
  }

  Future<void> _launchWhatsApp(PropertyModel property) async {
    final authState = context.read<AuthBloc>().state;
    String userName = 'User';
    if (authState is Authenticated) {
      userName = authState.user.fullName;
    }

    final text = 'Hello,\n'
        'I am $userName from NB Prop Tech.\n'
        'Is your property still available?\n'
        'Thank you.';
    final url =
        'https://wa.me/${property.ownerMobile}?text=${Uri.encodeComponent(text)}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    }
  }

  bool _hasEditAccess(PropertyModel p, UserModel? currentUser) {
    if (currentUser == null) return false;
    // Allow all sales persons and management roles to edit and delete all properties on Properties page
    return true;
  }

  void _showDeleteConfirmDialog(BuildContext context, PropertyModel p) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: CRMColors.cardBgOf(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.m)),
          title: Text("Delete Property", style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context))),
          content: Text(
            "Are you sure you want to delete the property ${p.title}?",
            style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context)),
          ),
          actions: [
            CRMButton(
              label: "Cancel",
              variant: CRMButtonVariant.outline,
              onPressed: () => Navigator.pop(dialogContext),
            ),
            const SizedBox(width: CRMSpacing.xs),
            CRMButton(
              label: "Delete",
              variant: CRMButtonVariant.danger,
              onPressed: () {
                context.read<PropertiesBloc>().add(DeletePropertyEvent(p.id, activeTab: _activeTab));
                Navigator.pop(dialogContext);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPropertyActionsMenu(BuildContext context, PropertyModel p,
      PropertyMetadataModel? metadata, bool isMine) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        color: CRMColors.textSecondaryOf(context),
        size: 20,
      ),
      tooltip: 'Actions',
      onSelected: (value) async {
        switch (value) {
          case 'edit':
            if (metadata != null) {
              _showAddEditPropertyDialog(context, metadata, p);
            }
            break;
          case 'delete':
            _showDeleteConfirmDialog(context, p);
            break;
          case 'message':
            _launchWhatsApp(p);
            break;
          case 'share':
            _showSharePropertiesDialogForSingleProperty(p);
            break;
          case 'archive':
            setState(() {
              _archivedPropertyIds.add(p.id);
              _saveArchivedPropertyIds();
            });
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Property ${p.propertyCode} moved to Archive.')),
              );
            }
            break;
          case 'unarchive':
            setState(() {
              _archivedPropertyIds.remove(p.id);
              _saveArchivedPropertyIds();
            });
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Property ${p.propertyCode} unarchived.')),
              );
            }
            break;
          case 'restore':
            context.read<PropertiesBloc>().add(
                  RestorePropertyEvent(p.id, activeTab: _activeTab),
                );
            break;
        }
      },
      itemBuilder: (context) => [
        if (_activeTab == 'My Deleted') ...[
          if (isMine)
            const PopupMenuItem<String>(
              value: 'restore',
              child: Row(
                children: [
                  Icon(Icons.restore_rounded,
                      size: 18, color: CRMColors.success),
                  SizedBox(width: 8),
                  Text('Restore'),
                ],
              ),
            ),
        ] else ...[
          if (isMine) ...[
            PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined,
                      size: 18, color: CRMColors.primaryOf(context)),
                  const SizedBox(width: 8),
                  const Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline_rounded,
                      size: 18, color: CRMColors.danger),
                  const SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: CRMColors.danger)),
                ],
              ),
            ),
          ],
          PopupMenuItem<String>(
            value: 'message',
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline_rounded,
                    size: 18, color: CRMColors.success),
                const SizedBox(width: 8),
                const Text('Message'),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'share',
            child: Row(
              children: [
                Icon(Icons.share_outlined,
                    size: 18, color: CRMColors.primaryOf(context)),
                const SizedBox(width: 8),
                const Text('Share Property'),
              ],
            ),
          ),
          if (_archivedPropertyIds.contains(p.id))
            PopupMenuItem<String>(
              value: 'unarchive',
              child: Row(
                children: [
                  Icon(Icons.unarchive_outlined,
                      size: 18, color: CRMColors.primaryOf(context)),
                  const SizedBox(width: 8),
                  const Text('Unarchive Property'),
                ],
              ),
            )
          else
            PopupMenuItem<String>(
              value: 'archive',
              child: Row(
                children: [
                  Icon(Icons.archive_outlined,
                      size: 18, color: CRMColors.textSecondaryOf(context)),
                  const SizedBox(width: 8),
                  const Text('Archive Property'),
                ],
              ),
            ),
        ],
      ],
    );
  }

  void _showSharePropertiesDialogForSingleProperty(PropertyModel p) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isGeneratingLink = false;
        bool isSharingPdf = false;
        String? error;
        String? generatedLink;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (generatedLink != null) {
              return AlertDialog(
                backgroundColor: CRMColors.cardBgOf(context),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(CRMBorderRadius.m)),
                title: Text("Share Link Created",
                    style: CRMTypography.sectionTitle
                        .copyWith(color: CRMColors.textOf(context))),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(CRMSpacing.s),
                      decoration: BoxDecoration(
                        color: CRMColors.backgroundOf(context),
                        borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                        border: Border.all(color: CRMColors.borderOf(context)),
                      ),
                      child: SelectableText(
                        generatedLink!,
                        style: CRMTypography.caption
                            .copyWith(color: CRMColors.primaryOf(context)),
                      ),
                    ),
                    const SizedBox(height: CRMSpacing.m),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: const Text("Copy"),
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: generatedLink!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Link copied to clipboard!")),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: CRMSpacing.s),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white),
                            icon: const Icon(Icons.chat_bubble_outline_rounded,
                                size: 16),
                            label: const Text("WhatsApp"),
                            onPressed: () async {
                              final text = Uri.encodeComponent(
                                  "Hello, here is the property details link: $generatedLink");
                              final url = "https://wa.me/?text=$text";
                              final uri = Uri.parse(url);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.share_rounded, size: 16),
                      label: const Text("Share"),
                      onPressed: () async {
                        try {
                          await Share.share(generatedLink!);
                        } catch (e) {
                          await Clipboard.setData(
                              ClipboardData(text: generatedLink!));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Link copied to clipboard!")),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  ),
                ],
              );
            }

            final bhk = p.configurationName ?? "${p.bedrooms} BHK";
            final price = '₹${BudgetFormatter.format(p.price)}';
            final titleText = "$bhk in ${p.areaName} – $price (${p.propertyCode})";

            return Stack(
              children: [
                AlertDialog(
                  backgroundColor: CRMColors.cardBgOf(context),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(CRMBorderRadius.m)),
                  title: Text("Share Matching Properties",
                      style: CRMTypography.sectionTitle
                          .copyWith(color: CRMColors.textOf(context))),
                  content: SizedBox(
                    width: 400,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(error!,
                                style:
                                    const TextStyle(color: CRMColors.danger)),
                          ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: CRMColors.backgroundOf(context),
                            borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                            border: Border.all(color: CRMColors.borderOf(context)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.other_houses_outlined,
                                  color: CRMColors.primaryOf(context), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  titleText,
                                  style: CRMTypography.body.copyWith(
                                    color: CRMColors.textOf(context),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  actionsAlignment: MainAxisAlignment.spaceBetween,
                  actions: [
                    TextButton(
                      onPressed: (isGeneratingLink || isSharingPdf)
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton(
                          onPressed: (isGeneratingLink || isSharingPdf)
                              ? null
                              : () async {
                                  setDialogState(() => isSharingPdf = true);
                                  try {
                                    final bytes =
                                        await PropertySharePdf.build([p]);
                                    final fileName =
                                        PropertySharePdf.fileName(p);

                                    await FileDownloader.download(
                                        bytes, fileName);

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Property PDF ready to share.'),
                                        ),
                                      );
                                    }

                                    final phone = p.ownerMobile;
                                    final cleanPhone =
                                        phone.replaceAll(RegExp(r'\D'), '');
                                    String formattedPhone = cleanPhone;
                                    if (cleanPhone.length == 10) {
                                      formattedPhone = '91$cleanPhone';
                                    }

                                    final text = Uri.encodeComponent(
                                        "Hello, please find property details for ${p.title ?? 'Property'} (${p.propertyCode}).");
                                    final nativeUrl = formattedPhone.isNotEmpty
                                        ? "whatsapp://send?phone=$formattedPhone&text=$text"
                                        : "whatsapp://send?text=$text";
                                    final nativeUri = Uri.parse(nativeUrl);

                                    if (await canLaunchUrl(nativeUri)) {
                                      await launchUrl(nativeUri,
                                          mode:
                                              LaunchMode.externalApplication);
                                    } else {
                                      final webUrl = formattedPhone.isNotEmpty
                                          ? "https://web.whatsapp.com/send?phone=$formattedPhone&text=$text"
                                          : "https://wa.me/?text=$text";
                                      final webUri = Uri.parse(webUrl);
                                      if (await canLaunchUrl(webUri)) {
                                        await launchUrl(webUri,
                                            mode: LaunchMode
                                                .externalApplication);
                                      } else {
                                        final fallbackUrl =
                                            "https://wa.me/$formattedPhone?text=$text";
                                        final fallbackUri =
                                            Uri.parse(fallbackUrl);
                                        if (await canLaunchUrl(fallbackUri)) {
                                          await launchUrl(fallbackUri,
                                              mode: LaunchMode
                                                  .externalApplication);
                                        }
                                      }
                                    }
                                  } catch (e) {
                                    debugPrint('Share PDF failed: $e');
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Failed to create property PDF.'),
                                          backgroundColor: CRMColors.danger,
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (context.mounted) {
                                      setDialogState(
                                          () => isSharingPdf = false);
                                    }
                                  }
                                },
                          child: const Text("Share PDF"),
                        ),
                        const SizedBox(width: CRMSpacing.s),
                        ElevatedButton(
                          onPressed: (isGeneratingLink || isSharingPdf)
                              ? null
                              : () async {
                                  setDialogState(() => isGeneratingLink = true);
                                  try {
                                    final response = await DioClient.dio.post(
                                      '/share-sessions',
                                      data: {
                                        'property_ids': [p.id],
                                        'expiry_days': 7
                                      },
                                    );
                                    if (response.data != null &&
                                        response.data['success'] == true) {
                                      final sessionId =
                                          response.data['data']['session']['id'];
                                      final authState =
                                          context.read<AuthBloc>().state;
                                      String? currentAgentName;
                                      String? currentAgentMobile;
                                      if (authState is Authenticated) {
                                        currentAgentName =
                                            authState.user.fullName;
                                        currentAgentMobile =
                                            authState.user.mobile;
                                      }

                                      setDialogState(() {
                                        var link =
                                            "${AppConfig.publicShareBaseUrl}/$sessionId";
                                        final queryParams = <String>[];
                                        if (currentAgentName != null &&
                                            currentAgentName.isNotEmpty) {
                                          queryParams.add(
                                              "agentName=${Uri.encodeComponent(currentAgentName)}");
                                        }
                                        if (currentAgentMobile != null &&
                                            currentAgentMobile.isNotEmpty) {
                                          queryParams.add(
                                              "agentMobile=${Uri.encodeComponent(currentAgentMobile)}");
                                        }
                                        if (queryParams.isNotEmpty) {
                                          link += "?${queryParams.join('&')}";
                                        }
                                        generatedLink = link;
                                        isGeneratingLink = false;
                                      });
                                    } else {
                                      setDialogState(() {
                                        error = "Failed to generate link.";
                                        isGeneratingLink = false;
                                      });
                                    }
                                  } catch (e) {
                                    final authState =
                                        context.read<AuthBloc>().state;
                                    String? currentAgentName;
                                    String? currentAgentMobile;
                                    if (authState is Authenticated) {
                                      currentAgentName =
                                          authState.user.fullName;
                                      currentAgentMobile =
                                          authState.user.mobile;
                                    }
                                    setDialogState(() {
                                      var link =
                                          "${AppConfig.publicShareBaseUrl}/${p.id}";
                                      final queryParams = <String>[];
                                      if (currentAgentName != null &&
                                          currentAgentName.isNotEmpty) {
                                        queryParams.add(
                                            "agentName=${Uri.encodeComponent(currentAgentName)}");
                                      }
                                      if (currentAgentMobile != null &&
                                          currentAgentMobile.isNotEmpty) {
                                        queryParams.add(
                                            "agentMobile=${Uri.encodeComponent(currentAgentMobile)}");
                                      }
                                      if (queryParams.isNotEmpty) {
                                        link += "?${queryParams.join('&')}";
                                      }
                                      generatedLink = link;
                                      isGeneratingLink = false;
                                    });
                                  }
                                },
                          child: const Text("Generate Link"),
                        ),
                      ],
                    ),
                  ],
                ),
                if (isGeneratingLink || isSharingPdf)
                  const Positioned.fill(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBulkActionsToolbar(List<PropertyModel> allProperties) {
    if (_selectedPropertyIds.isEmpty) return const SizedBox.shrink();

    final selectedProps = allProperties
        .where((p) => _selectedPropertyIds.contains(p.id))
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: CRMSpacing.m),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: CRMColors.primaryOf(context).withOpacity(0.08),
        borderRadius: BorderRadius.circular(CRMBorderRadius.m),
        border: Border.all(
          color: CRMColors.primaryOf(context).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: CRMColors.primaryOf(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${selectedProps.length} Selected',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedPropertyIds.clear();
                  });
                },
                child: const Text('Deselect All'),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: CRMColors.primaryOf(context),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.share_outlined, size: 16),
                label: const Text('Share Property'),
                onPressed: () {
                  _showSharePropertiesDialogForSelectedProperties(selectedProps);
                },
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                  elevation: 2,
                ),
                icon: const Icon(Icons.compare_arrows_rounded, size: 16, color: Colors.white),
                label: const Text('Compare Property', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () {
                  _showComparePropertiesDialog(selectedProps);
                },
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: CRMColors.danger,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('Move to Bin'),
                onPressed: () {
                  _showBulkDeleteConfirmDialog(selectedProps);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSharePropertiesDialogForSelectedProperties(
      List<PropertyModel> initialSelectedProps) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        List<PropertyModel> currentlySelected = List.from(initialSelectedProps);
        bool isGeneratingLink = false;
        bool isSharingPdf = false;
        String? error;
        String? generatedLink;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (generatedLink != null) {
              return AlertDialog(
                backgroundColor: CRMColors.cardBgOf(context),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(CRMBorderRadius.m)),
                title: Text("Share Link Created",
                    style: CRMTypography.sectionTitle
                        .copyWith(color: CRMColors.textOf(context))),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(CRMSpacing.s),
                      decoration: BoxDecoration(
                        color: CRMColors.backgroundOf(context),
                        borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                        border: Border.all(color: CRMColors.borderOf(context)),
                      ),
                      child: SelectableText(
                        generatedLink!,
                        style: CRMTypography.caption
                            .copyWith(color: CRMColors.primaryOf(context)),
                      ),
                    ),
                    const SizedBox(height: CRMSpacing.m),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: const Text("Copy"),
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: generatedLink!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Link copied to clipboard!")),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: CRMSpacing.s),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white),
                            icon: const Icon(Icons.chat_bubble_outline_rounded,
                                size: 16),
                            label: const Text("WhatsApp"),
                            onPressed: () async {
                              final text = Uri.encodeComponent(
                                  "Hello, here is the property details link: $generatedLink");
                              final url = "https://wa.me/?text=$text";
                              final uri = Uri.parse(url);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.share_rounded, size: 16),
                      label: const Text("Share"),
                      onPressed: () async {
                        try {
                          await Share.share(generatedLink!);
                        } catch (e) {
                          await Clipboard.setData(
                              ClipboardData(text: generatedLink!));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Link copied to clipboard!")),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  ),
                ],
              );
            }

            return Stack(
              children: [
                AlertDialog(
                  backgroundColor: CRMColors.cardBgOf(context),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(CRMBorderRadius.m)),
                  title: Text("Share Matching Properties",
                      style: CRMTypography.sectionTitle
                          .copyWith(color: CRMColors.textOf(context))),
                  content: SizedBox(
                    width: 450,
                    height: 320,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(error!,
                                style:
                                    const TextStyle(color: CRMColors.danger)),
                          ),
                        Text(
                          "Selected ${currentlySelected.length} properties to share:",
                          style: CRMTypography.body
                              .copyWith(color: CRMColors.textSecondaryOf(context)),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: initialSelectedProps.length,
                            itemBuilder: (context, idx) {
                              final p = initialSelectedProps[idx];
                              final isSelected = currentlySelected.contains(p);
                              final bhk =
                                  p.configurationName ?? "${p.bedrooms} BHK";
                              final price =
                                  '₹${BudgetFormatter.format(p.price)}';
                              final title =
                                  "$bhk in ${p.areaName} - $price (${p.propertyCode})";

                              return CheckboxListTile(
                                title: Text(title,
                                    style: CRMTypography.body.copyWith(
                                        color: CRMColors.textOf(context))),
                                value: isSelected,
                                activeColor: CRMColors.primaryOf(context),
                                onChanged:
                                    (isGeneratingLink || isSharingPdf)
                                        ? null
                                        : (val) {
                                            setDialogState(() {
                                              if (val == true) {
                                                currentlySelected.add(p);
                                              } else {
                                                currentlySelected.remove(p);
                                              }
                                            });
                                          },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  actionsAlignment: MainAxisAlignment.spaceBetween,
                  actions: [
                    TextButton(
                      onPressed: (isGeneratingLink || isSharingPdf)
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton(
                          onPressed: currentlySelected.isEmpty ||
                                  isGeneratingLink ||
                                  isSharingPdf
                              ? null
                              : () async {
                                  setDialogState(() => isSharingPdf = true);
                                  try {
                                    final bytes = await PropertySharePdf.build(
                                        currentlySelected);
                                    final fileName = currentlySelected.length == 1
                                        ? PropertySharePdf.fileName(
                                            currentlySelected.first)
                                        : 'Selected_Properties_Details.pdf';

                                    await FileDownloader.download(
                                        bytes, fileName);

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Property PDF ready to share.'),
                                        ),
                                      );
                                    }

                                    final text = Uri.encodeComponent(
                                        "Hello, please find property details for selected properties.");
                                    final nativeUrl =
                                        "whatsapp://send?text=$text";
                                    final nativeUri = Uri.parse(nativeUrl);

                                    if (await canLaunchUrl(nativeUri)) {
                                      await launchUrl(nativeUri,
                                          mode:
                                              LaunchMode.externalApplication);
                                    } else {
                                      final webUrl =
                                          "https://web.whatsapp.com/send?text=$text";
                                      final webUri = Uri.parse(webUrl);
                                      if (await canLaunchUrl(webUri)) {
                                        await launchUrl(webUri,
                                            mode: LaunchMode
                                                .externalApplication);
                                      }
                                    }
                                  } catch (e) {
                                    debugPrint('Share PDF failed: $e');
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Failed to create property PDF.'),
                                          backgroundColor: CRMColors.danger,
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (context.mounted) {
                                      setDialogState(
                                          () => isSharingPdf = false);
                                    }
                                  }
                                },
                          child: const Text("Share PDF"),
                        ),
                        const SizedBox(width: CRMSpacing.s),
                        ElevatedButton(
                          onPressed: currentlySelected.isEmpty ||
                                  isGeneratingLink ||
                                  isSharingPdf
                              ? null
                              : () async {
                                  setDialogState(() => isGeneratingLink = true);
                                  try {
                                    final response = await DioClient.dio.post(
                                      '/share-sessions',
                                      data: {
                                        'property_ids': currentlySelected
                                            .map((p) => p.id)
                                            .toList(),
                                        'expiry_days': 7
                                      },
                                    );
                                    if (response.data != null &&
                                        response.data['success'] == true) {
                                      final sessionId =
                                          response.data['data']['session']['id'];
                                      final authState =
                                          context.read<AuthBloc>().state;
                                      String? currentAgentName;
                                      String? currentAgentMobile;
                                      if (authState is Authenticated) {
                                        currentAgentName =
                                            authState.user.fullName;
                                        currentAgentMobile =
                                            authState.user.mobile;
                                      }

                                      setDialogState(() {
                                        var link =
                                            "${AppConfig.publicShareBaseUrl}/$sessionId";
                                        final queryParams = <String>[];
                                        if (currentAgentName != null &&
                                            currentAgentName.isNotEmpty) {
                                          queryParams.add(
                                              "agentName=${Uri.encodeComponent(currentAgentName)}");
                                        }
                                        if (currentAgentMobile != null &&
                                            currentAgentMobile.isNotEmpty) {
                                          queryParams.add(
                                              "agentMobile=${Uri.encodeComponent(currentAgentMobile)}");
                                        }
                                        if (queryParams.isNotEmpty) {
                                          link += "?${queryParams.join('&')}";
                                        }
                                        generatedLink = link;
                                        isGeneratingLink = false;
                                      });
                                    } else {
                                      setDialogState(() {
                                        error = "Failed to generate link.";
                                        isGeneratingLink = false;
                                      });
                                    }
                                  } catch (e) {
                                    setDialogState(() {
                                      error = "Failed to generate link.";
                                      isGeneratingLink = false;
                                    });
                                  }
                                },
                          child: const Text("Generate Link"),
                        ),
                      ],
                    ),
                  ],
                ),
                if (isGeneratingLink || isSharingPdf)
                  const Positioned.fill(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBulkDeleteConfirmDialog(List<PropertyModel> props) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: CRMColors.cardBgOf(context),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CRMBorderRadius.m)),
          title: Text("Move to Recycle Bin",
              style: CRMTypography.sectionTitle
                  .copyWith(color: CRMColors.textOf(context))),
          content: Text(
            "Are you sure you want to move ${props.length} selected properties to the Recycle Bin?",
            style: CRMTypography.body
                .copyWith(color: CRMColors.textSecondaryOf(context)),
          ),
          actions: [
            CRMButton(
              label: "Cancel",
              variant: CRMButtonVariant.outline,
              onPressed: () => Navigator.pop(dialogContext),
            ),
            const SizedBox(width: CRMSpacing.xs),
            CRMButton(
              label: "Move to Bin",
              variant: CRMButtonVariant.danger,
              onPressed: () {
                for (final p in props) {
                  context.read<PropertiesBloc>().add(
                        DeletePropertyEvent(p.id, activeTab: _activeTab),
                      );
                }
                setState(() {
                  _selectedPropertyIds.clear();
                });
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          "${props.length} properties moved to Recycle Bin.")),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showComparePropertiesDialog(List<PropertyModel> props) {
    if (props.isEmpty) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: CRMColors.cardBgOf(context),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CRMBorderRadius.m)),
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: math.min(MediaQuery.of(context).size.width * 0.9, 1100),
            height: math.min(MediaQuery.of(context).size.height * 0.85, 750),
            padding: const EdgeInsets.all(CRMSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.compare_arrows_rounded,
                            color: CRMColors.primaryOf(context), size: 24),
                        const SizedBox(width: 10),
                        Text(
                          "Compare Properties (${props.length})",
                          style: CRMTypography.sectionTitle
                              .copyWith(color: CRMColors.textOf(context)),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Table(
                        defaultColumnWidth: const FixedColumnWidth(220),
                        border: TableBorder.all(
                          color: CRMColors.borderOf(context),
                          width: 1,
                        ),
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                              color: CRMColors.sidebarBgOf(context),
                            ),
                            children: [
                              _buildCompareHeaderCell("Feature / Property"),
                              ...props.map((p) => _buildCompareHeaderCell(
                                  "${p.propertyCode}\n${p.title ?? 'No Title'}")),
                            ],
                          ),
                          TableRow(
                            children: [
                              _buildCompareLabelCell("Image"),
                              ...props.map((p) => Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Center(
                                      child: Container(
                                        height: 100,
                                        width: 160,
                                        decoration: BoxDecoration(
                                          color: Colors.black87,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: p.images.isNotEmpty
                                            ? CrmNetworkImage(
                                                url: p.images.first,
                                                fit: BoxFit.contain,
                                                cacheLogicalWidth: 320,
                                                cacheLogicalHeight: 200,
                                                error: (context) => const Icon(
                                                    Icons.broken_image_outlined,
                                                    size: 32,
                                                    color: Colors.grey),
                                              )
                                            : Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                        Icons
                                                            .image_not_supported_outlined,
                                                        size: 24,
                                                        color: CRMColors.primaryOf(
                                                                context)
                                                            .withOpacity(0.5)),
                                                    const SizedBox(height: 4),
                                                    Text('NO PHOTOS',
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: CRMColors
                                                              .textMutedOf(context),
                                                        )),
                                                  ],
                                                ),
                                              ),
                                      ),
                                    ),
                                  )),
                            ],
                          ),
                          TableRow(
                            children: [
                              _buildCompareLabelCell("Price"),
                              ...props.map((p) => _buildCompareValueCell(
                                  "₹${BudgetFormatter.format(p.price)}",
                                  isBold: true)),
                            ],
                          ),
                          TableRow(
                            children: [
                              _buildCompareLabelCell("BHK"),
                              ...props.map((p) => _buildCompareValueCell(
                                  p.configurationName ?? "${p.bedrooms} BHK")),
                            ],
                          ),
                          TableRow(
                            children: [
                              _buildCompareLabelCell("Area"),
                              ...props.map(
                                  (p) => _buildCompareValueCell(p.areaName)),
                            ],
                          ),
                          TableRow(
                            children: [
                              _buildCompareLabelCell("Status"),
                              ...props.map((p) => _buildCompareValueCell(
                                  p.statusDisplayName,
                                  color: p.isStatusAvailable
                                      ? CRMColors.success
                                      : CRMColors.warning)),
                            ],
                          ),
                          TableRow(
                            children: [
                              _buildCompareLabelCell("Built up area"),
                              ...props.map((p) {
                                final bArea = (p.superBuiltupArea != null && p.superBuiltupArea! > 0)
                                    ? "${p.superBuiltupArea!.toStringAsFixed(0)} sq.ft."
                                    : ((p.carpetArea != null && p.carpetArea! > 0)
                                        ? "${p.carpetArea!.toStringAsFixed(0)} sq.ft."
                                        : "-");
                                return _buildCompareValueCell(bArea);
                              }),
                            ],
                          ),
                          TableRow(
                            children: [
                              _buildCompareLabelCell("Furnishing"),
                              ...props.map((p) => _buildCompareValueCell(
                                  (p.furnishingTypeName != null && p.furnishingTypeName!.isNotEmpty)
                                      ? p.furnishingTypeName!
                                      : "-")),
                            ],
                          ),
                          TableRow(
                            children: [
                              _buildCompareLabelCell("Floor No"),
                              ...props.map((p) {
                                final fStr = (p.floorNo != null && p.floorNo! > 0)
                                    ? ((p.totalFloor != null && p.totalFloor! > 0)
                                        ? "Floor ${p.floorNo} of ${p.totalFloor}"
                                        : "Floor ${p.floorNo}")
                                    : "-";
                                return _buildCompareValueCell(fStr);
                              }),
                            ],
                          ),
                          TableRow(
                            children: [
                              _buildCompareLabelCell("Property Age"),
                              ...props.map((p) {
                                final aStr = (p.ageOfProperty != null && p.ageOfProperty! > 0)
                                    ? "${p.ageOfProperty} ${p.ageOfProperty == 1 ? 'Year' : 'Years'}"
                                    : (p.ageOfProperty == 0 ? "0-1 Year" : "-");
                                return _buildCompareValueCell(aStr);
                              }),
                            ],
                          ),
                          TableRow(
                            children: [
                              _buildCompareLabelCell("Actions"),
                              ...props.map((p) => Container(
                                    padding: const EdgeInsets.all(8),
                                    alignment: Alignment.center,
                                    child: TextButton.icon(
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        backgroundColor:
                                            CRMColors.primaryOf(context)
                                                .withOpacity(0.08),
                                        foregroundColor:
                                            CRMColors.primaryOf(context),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(6)),
                                      ),
                                      icon: const Icon(
                                          Icons.visibility_outlined,
                                          size: 14),
                                      label: const Text(
                                        'View Details',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      onPressed: () {
                                        Navigator.pop(dialogContext);
                                        _openPropertyDetails(context, p,
                                            forceInAppDrawer: true);
                                      },
                                    ),
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompareHeaderCell(String title) {
    return Container(
      padding: const EdgeInsets.all(12),
      alignment: Alignment.center,
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildCompareLabelCell(String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: CRMColors.sidebarBgOf(context).withOpacity(0.5),
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildCompareValueCell(String value,
      {bool isBold = false, Color? color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      alignment: Alignment.center,
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
          color: color,
        ),
      ),
    );
  }

  String _formatPropertyDate(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inHours < 24 && !difference.isNegative) {
      if (difference.inMinutes < 1) {
        return "Just now";
      } else if (difference.inHours < 1) {
        return "${difference.inMinutes} mins ago";
      } else {
        return "${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago";
      }
    } else {
      return DateFormat('dd-MM-yyyy hh:mm a').format(dt);
    }
  }

  Future<void> _onPropertyStatusChanged(
      BuildContext context,
      PropertyModel p,
      String statusName,
      PropertyMetadataModel? metadata) async {
    if (statusName == 'Available') {
      final currentStatus = (p.propertyStatusName ?? '').toLowerCase();
      final isCurrentlyRentedOrSold =
          currentStatus.contains('rented') || currentStatus.contains('sold');

      if (isCurrentlyRentedOrSold) {
        final clientName =
            await PropertyDealClientStore.getClientName(p.id, property: p);
        final bool hasClient =
            clientName != null && clientName.trim().isNotEmpty;

        if (!context.mounted) return;

        final bool? confirm = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: CRMColors.cardBgOf(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CRMBorderRadius.m),
            ),
            title: Text(
              "Confirm Status Change",
              style: CRMTypography.sectionTitle.copyWith(
                color: CRMColors.textOf(context),
              ),
            ),
            content: Text.rich(
              TextSpan(
                style: CRMTypography.body.copyWith(
                  color: CRMColors.textSecondaryOf(context),
                  height: 1.5,
                ),
                children: hasClient
                    ? [
                        const TextSpan(
                            text: "This property is currently assigned to client "),
                        TextSpan(
                          text: "'$clientName'",
                          style: TextStyle(
                            color: CRMColors.primaryOf(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: " (${p.propertyStatusName}).\n\n",
                          style: TextStyle(
                            color: CRMColors.textOf(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(
                          text: "Are you sure you want to change its status to ",
                        ),
                        TextSpan(
                          text: "Available",
                          style: const TextStyle(
                            color: CRMColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(text: "?"),
                      ]
                    : [
                        const TextSpan(
                          text:
                              "Are you sure you want to change the status of this property from ",
                        ),
                        TextSpan(
                          text: p.propertyStatusName ?? 'Rented Out',
                          style: TextStyle(
                            color: CRMColors.textOf(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(text: " to "),
                        TextSpan(
                          text: "Available",
                          style: const TextStyle(
                            color: CRMColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(text: "?"),
                      ],
              ),
            ),
            actions: [
              CRMButton(
                label: "Cancel",
                variant: CRMButtonVariant.outline,
                onPressed: () => Navigator.pop(dialogContext, false),
              ),
              const SizedBox(width: CRMSpacing.xs),
              CRMButton(
                label: "Yes",
                variant: CRMButtonVariant.primary,
                onPressed: () => Navigator.pop(dialogContext, true),
              ),
            ],
          ),
        );

        if (confirm != true) return;

        await PropertyDealClientStore.removeClientName(p.id);
      }
    }

    if (statusName == 'To Be Available') {
      if (!context.mounted) return;
      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now().add(const Duration(days: 1)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
        helpText: 'Select Available Date',
      );
      if (pickedDate == null) return;

      LookupItem? targetLookup;
      if (metadata != null) {
        for (final s in metadata.statuses) {
          if (s.name.toLowerCase().contains('to be available')) {
            targetLookup = s;
            break;
          }
        }
      }
      final statusId =
          targetLookup?.id ?? '05a73434-e99b-425b-99b2-1825d529ac35';
      if (context.mounted) {
        context.read<PropertiesBloc>().add(
              UpdatePropertyEvent(
                p.id,
                {
                  'property_status_id': statusId,
                  'possession_date':
                      pickedDate.toIso8601String().substring(0, 10),
                },
                activeTab: _activeTab,
              ),
            );
      }
      return;
    }

    LookupItem? targetLookup;
    if (metadata != null) {
      for (final s in metadata.statuses) {
        if (s.name.toLowerCase().replaceAll(' ', '') ==
            statusName.toLowerCase().replaceAll(' ', '')) {
          targetLookup = s;
          break;
        }
      }
    }
    final statusId = targetLookup?.id ?? statusName;
    if (context.mounted) {
      context.read<PropertiesBloc>().add(
            UpdatePropertyEvent(
              p.id,
              {'property_status_id': statusId},
              activeTab: _activeTab,
            ),
          );
    }
  }

  Widget _buildCardStatusBadge(
      PropertyModel p, PropertyMetadataModel? metadata) {
    final isRent = p.listingTypeName.toLowerCase().contains('rent');
    final statusColor = p.isStatusAvailable
        ? CRMColors.success
        : (p.propertyStatusName?.toLowerCase().contains('rented') == true ||
                p.propertyStatusName?.toLowerCase().contains('sold') == true)
            ? CRMColors.warning
            : CRMColors.info;

    return PopupMenuButton<String>(
      tooltip: 'Change Status',
      onSelected: (String statusName) {
        _onPropertyStatusChanged(context, p, statusName, metadata);
      },
      itemBuilder: (BuildContext context) {
        return <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'Available',
            child: Row(
              children: [
                Icon(Icons.check_circle_outline,
                    color: CRMColors.success, size: 16),
                SizedBox(width: 8),
                Text('Available'),
              ],
            ),
          ),
          if (isRent) ...[
            const PopupMenuItem<String>(
              value: 'Rented Out',
              child: Row(
                children: [
                  Icon(Icons.house_outlined,
                      color: CRMColors.warning, size: 16),
                  SizedBox(width: 8),
                  Text('Rented Out'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'To Be Available',
              child: Row(
                children: [
                  Icon(Icons.schedule_outlined,
                      color: CRMColors.info, size: 16),
                  SizedBox(width: 8),
                  Text('To Be Available'),
                ],
              ),
            ),
          ] else ...[
            const PopupMenuItem<String>(
              value: 'Sold Out',
              child: Row(
                children: [
                  Icon(Icons.sell_outlined,
                      color: CRMColors.danger, size: 16),
                  SizedBox(width: 8),
                  Text('Sold Out'),
                ],
              ),
            ),
          ],
        ];
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: statusColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              p.statusDisplayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: Colors.white, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticStatusPill(PropertyModel p) {
    final statusColor = p.isStatusAvailable
        ? CRMColors.success
        : (p.propertyStatusName?.toLowerCase().contains('rented') == true ||
                p.propertyStatusName?.toLowerCase().contains('sold') == true)
            ? CRMColors.warning
            : CRMColors.info;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        p.statusDisplayName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  Widget _buildHousingStyleResultsHeader(BuildContext context, int totalCount, int pageStart, int pageEnd) {
    final categoryText = _activeCategoryTab == 'All' ? '' : '$_activeCategoryTab ';
    final searchText = _searchController.text.trim();
    final locationTitle = searchText.isNotEmpty ? 'in $searchText' : 'in Area';
    final listingText = _activeListingTab == 'Rent' ? 'Rent' : 'Re-Sale';

    return Container(
      margin: const EdgeInsets.only(bottom: CRMSpacing.m),
      padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: CRMSpacing.m),
      decoration: BoxDecoration(
        color: CRMColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.5)),
        boxShadow: CRMShadows.small,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 650;
          final titleWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Showing ${pageStart + (totalCount > 0 ? 1 : 0)}-$pageEnd of $totalCount properties',
                style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context), fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 3),
              Text(
                '${categoryText}Property for $listingText $locationTitle',
                style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context), fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          );

          final sortWidget = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Sort by: ', style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context), fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: CRMColors.backgroundOf(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.6)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _selectedPriceSortOrRange,
                    isDense: true,
                    style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context), fontSize: 13),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Relevance / Newest')),
                      DropdownMenuItem(value: 'l2h', child: Text('Price: Low to High')),
                      DropdownMenuItem(value: 'h2l', child: Text('Price: High to Low')),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedPriceSortOrRange = val;
                        _currentPage = 0;
                      });
                      _loadProperties();
                    },
                  ),
                ),
              ),
            ],
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleWidget,
                const SizedBox(height: 10),
                sortWidget,
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: titleWidget),
              sortWidget,
            ],
          );
        },
      ),
    );
  }

  Widget _buildRichPropertyCard(
      PropertyModel p,
      UserModel? currentUser,
      Set<String> bookmarkedIds,
      PropertyMetadataModel? metadata) {
    final isMine = _hasEditAccess(p, currentUser);
    final bhkText = p.configurationName ?? "${p.bedrooms} BHK";
    final propertyTitle = "$bhkText ${p.listingTypeName} in ${p.areaName}";
    final addressText =
        (p.title != null && p.title!.isNotEmpty) ? p.title! : p.areaName;
    final isUserAdminOrSuperAdmin =
        currentUser?.role == 'Admin' || currentUser?.role == 'Super Admin';
    final rawPriceFormatted = CRMCurrencyFormatter.formatShort(p.price);
    final priceText = rawPriceFormatted.startsWith('₹')
        ? rawPriceFormatted
        : "₹ $rawPriceFormatted";
    final hasImages = p.images.isNotEmpty;
    final formattedDateText = _formatPropertyDate(p.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: CRMSpacing.m),
      child: CRMCard(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 700;

            Widget imageSection = Container(
              width: isNarrow ? double.infinity : 280,
              height: isNarrow ? 220 : 210,
              decoration: BoxDecoration(
                color: CRMColors.backgroundOf(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: CRMColors.borderOf(context).withOpacity(0.5)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImages) ...[
                    _MobilePropertyImageCarousel(
                      images: p.images,
                      height: isNarrow ? 220 : 210,
                      onTap: () => _openPropertyDetails(context, p),
                    ),
                  ] else ...[
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 44,
                            color: CRMColors.primaryOf(context)
                                .withOpacity(0.4),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'NO PHOTOS',
                            style: TextStyle(
                              color: CRMColors.primaryOf(context)
                                  .withOpacity(0.6),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: CRMColors.primaryOf(context),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.add_a_photo_outlined,
                                size: 13),
                            label: const Text('+ Add Photos',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                            onPressed: () {
                              if (metadata != null) {
                                _showAddEditPropertyDialog(
                                    context, metadata, p);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Static Status Badge Pill inside image
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: _buildStaticStatusPill(p),
                  ),

                  // Selection Checkbox
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      height: 28,
                      width: 28,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Theme(
                        data: ThemeData(unselectedWidgetColor: Colors.white),
                        child: Checkbox(
                          value: _selectedPropertyIds.contains(p.id),
                          activeColor: CRMColors.primaryOf(context),
                          side: const BorderSide(
                              color: Colors.white, width: 1.5),
                          onChanged: (bool? checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedPropertyIds.add(p.id);
                              } else {
                                _selectedPropertyIds.remove(p.id);
                              }
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );

            final String locationFullText = [
              if (p.address.isNotEmpty) p.address,
              if (p.areaName.isNotEmpty && !p.address.contains(p.areaName)) p.areaName,
              if (p.cityName.isNotEmpty && !p.address.contains(p.cityName)) p.cityName,
            ].join(', ');

            final String areaSpecsText = [
              if (p.superBuiltupArea != null && p.superBuiltupArea! > 0)
                'Super Built-up: ${p.superBuiltupArea!.toStringAsFixed(0)} sq.ft.',
              if (p.carpetArea != null && p.carpetArea! > 0)
                'Carpet: ${p.carpetArea!.toStringAsFixed(0)} sq.ft.',
              if (p.plotArea != null && p.plotArea! > 0)
                'Plot: ${p.plotArea!.toStringAsFixed(0)} sq.ft.',
            ].join(' • ');

            Widget detailsSection = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                propertyTitle,
                                style: CRMTypography.sectionTitle.copyWith(
                                  color: CRMColors.textOf(context),
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (p.title.isNotEmpty && p.title != propertyTitle) ...[
                                const SizedBox(height: 2),
                                Text(
                                  p.title,
                                  style: TextStyle(
                                    color: CRMColors.primaryOf(context),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined, size: 14, color: CRMColors.primaryOf(context)),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      locationFullText.isNotEmpty ? locationFullText : addressText,
                                      style: CRMTypography.caption.copyWith(
                                        color: CRMColors.textMutedOf(context),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Interactive Status Dropdown Toggle Button
                            _buildCardStatusBadge(p, metadata),
                            const SizedBox(width: 8),
                            // Glassmorphism Box for Property Code ID
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color:
                                    CRMColors.primaryOf(context).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: CRMColors.primaryOf(context)
                                      .withOpacity(0.25),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: CRMColors.primaryOf(context)
                                        .withOpacity(0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                "ID : ${p.propertyCode}",
                                style: TextStyle(
                                  color: CRMColors.primaryOf(context),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          "$priceText / month",
                          style: TextStyle(
                            color: CRMColors.primaryOf(context),
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: CRMColors.sidebarBgOf(context),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: CRMColors.borderOf(context)
                                    .withOpacity(0.5)),
                          ),
                          child: Text(
                            _getPropertyBhkOrAreaValue(p),
                            style: TextStyle(
                              color: CRMColors.textSecondaryOf(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (areaSpecsText.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: CRMColors.primaryOf(context).withOpacity(0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              areaSpecsText,
                              style: TextStyle(
                                color: CRMColors.primaryOf(context),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        if (p.cityName.isNotEmpty)
                          _buildMetaChip(Icons.location_city_outlined, "City: ${p.cityName}"),
                        if (p.furnishingTypeName != null && p.furnishingTypeName!.isNotEmpty)
                          _buildMetaChip(Icons.chair_outlined, "Furnishing: ${p.furnishingTypeName}"),
                        if (p.facingTypeName != null && p.facingTypeName!.isNotEmpty)
                          _buildMetaChip(Icons.explore_outlined, "Facing: ${p.facingTypeName}"),
                        _buildMetaChip(
                          Icons.person_outline_rounded,
                          "Owner: ${p.ownerName} (${p.ownerMobile})",
                        ),
                        if (isUserAdminOrSuperAdmin)
                          _buildMetaChip(
                            Icons.badge_outlined,
                            "Added By: ${p.createdByName}",
                          ),
                        _buildMetaChip(
                          Icons.access_time_rounded,
                          "Date: $formattedDateText",
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        backgroundColor:
                            CRMColors.primaryOf(context).withOpacity(0.08),
                        foregroundColor: CRMColors.primaryOf(context),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () => _openPropertyDetails(context, p),
                      icon: const Icon(Icons.visibility_outlined, size: 15),
                      label: const Text('View Details',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    Row(
                      children: [
                        _buildPropertyActionsMenu(
                            context, p, metadata, isMine),
                      ],
                    ),
                  ],
                ),
              ],
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  imageSection,
                  const SizedBox(height: 14),
                  detailsSection,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                imageSection,
                const SizedBox(width: 20),
                Expanded(child: detailsSection),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: CRMColors.textMutedOf(context)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: CRMColors.textSecondaryOf(context),
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMobilePropertyCard(PropertyModel p, UserModel? currentUser,
      Set<String> bookmarkedIds, PropertyMetadataModel? metadata) {
    final isMine = _hasEditAccess(p, currentUser);
    final isHighlighted = p.id == _highlightedPropertyId;

    return AnimatedContainer(
      duration: CRMMotion.medium,
      curve: CRMMotion.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CRMBorderRadius.card + 2),
        border: Border.all(
          color: isHighlighted ? CRMColors.primaryOf(context) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: isHighlighted ? CRMShadows.primaryGlow : null,
      ),
      padding: const EdgeInsets.all(2),
      child: CRMCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(CRMBorderRadius.card),
          onTap: () => _openPropertyDetails(context, p),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(CRMBorderRadius.card),
                    ),
                    child: p.images.isNotEmpty
                        ? _MobilePropertyImageCarousel(
                            images: p.images,
                            onTap: () => _openPropertyDetails(context, p),
                          )
                        : GestureDetector(
                            onTap: () => _openPropertyDetails(context, p),
                            child: Container(
                              height: 300,
                              width: double.infinity,
                              color: CRMColors.skeletonBase,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      p.videos.isNotEmpty
                                          ? Icons.play_circle_outline_rounded
                                          : Icons.image_not_supported_outlined,
                                      size: 40,
                                      color: CRMColors.textMutedOf(context),
                                    ),
                                    const SizedBox(height: CRMSpacing.xs),
                                    Text(
                                      p.videos.isNotEmpty
                                          ? 'Video Available'
                                          : 'No Image Available',
                                      style: CRMTypography.caption.copyWith(
                                        color: CRMColors.textMutedOf(context),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ),
                  if (p.videos.isNotEmpty)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white24, width: 0.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.play_circle_fill_rounded, color: Colors.redAccent, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Video',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 28,
                          width: 28,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Theme(
                            data: ThemeData(unselectedWidgetColor: Colors.white),
                            child: Checkbox(
                              value: _selectedPropertyIds.contains(p.id),
                              activeColor: CRMColors.primaryOf(context),
                              side: const BorderSide(color: Colors.white, width: 1.5),
                              onChanged: (bool? checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selectedPropertyIds.add(p.id);
                                  } else {
                                    _selectedPropertyIds.remove(p.id);
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(CRMBorderRadius.xs),
                          ),
                          child: Text(
                            p.propertyCode,
                            style: CRMTypography.captionBold.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: CRMColors.primary,
                            borderRadius: BorderRadius.circular(CRMBorderRadius.xs),
                          ),
                          child: Text(
                            p.listingTypeName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (p.statusDisplayName.isNotEmpty)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: p.isStatusAvailable ? CRMColors.success : CRMColors.warning,
                          borderRadius: BorderRadius.circular(CRMBorderRadius.xs),
                        ),
                        child: Text(
                          p.statusDisplayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(CRMSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            p.title,
                            style: CRMTypography.cardTitle.copyWith(
                              color: CRMColors.textOf(context),
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          CRMCurrencyFormatter.formatShort(p.price),
                          style: CRMTypography.cardTitle.copyWith(
                            color: CRMColors.primaryOf(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: CRMSpacing.xs),
                    Row(
                      children: [
                        Icon(_getPropertyBhkOrAreaIcon(p),
                            size: 14, color: CRMColors.textSecondaryOf(context)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${_getPropertyBhkOrAreaValue(p)} in ${p.areaName}, ${p.cityName}',
                            style: CRMTypography.caption.copyWith(
                              color: CRMColors.textSecondaryOf(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    const SizedBox(height: CRMSpacing.s),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded,
                            size: 14, color: CRMColors.textSecondaryOf(context)),
                        const SizedBox(width: 4),
                        Text(
                          'Owner: ',
                          style: CRMTypography.caption
                              .copyWith(color: CRMColors.textSecondaryOf(context)),
                        ),
                        Expanded(
                          child: Text(
                            '${p.ownerName} (${p.ownerMobile})',
                            style: CRMTypography.captionBold.copyWith(
                              color: CRMColors.textOf(context),
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: CRMSpacing.xs),
                    Row(
                      children: [
                        Icon(Icons.badge_outlined,
                            size: 14, color: CRMColors.textSecondaryOf(context)),
                        const SizedBox(width: 4),
                        Text(
                          'Added by: ',
                          style: CRMTypography.caption
                              .copyWith(color: CRMColors.textSecondaryOf(context)),
                        ),
                        Expanded(
                          child: Text(
                            p.createdByName.isNotEmpty ? p.createdByName : 'N/A',
                            style: CRMTypography.captionBold.copyWith(
                              color: CRMColors.textOf(context),
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: CRMSpacing.xs),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 14, color: CRMColors.textSecondaryOf(context)),
                        const SizedBox(width: 4),
                        Text(
                          'Created: ${DateFormat('dd-MM-yyyy').format(p.createdAt)}',
                          style: CRMTypography.caption
                              .copyWith(color: CRMColors.textSecondaryOf(context)),
                        ),
                      ],
                    ),
                    const SizedBox(height: CRMSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          p.availableFromFormatted != null 
                              ? Icons.check_box_outlined 
                              : Icons.event_busy_rounded,
                          size: 14,
                          color: p.availableFromFormatted != null 
                              ? CRMColors.success 
                              : CRMColors.textSecondaryOf(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          p.availableFromFormatted != null 
                              ? 'Available: ${p.availableFromFormatted}' 
                              : 'Not Available',
                          style: CRMTypography.caption.copyWith(
                            color: p.availableFromFormatted != null 
                                ? CRMColors.success 
                                : CRMColors.textSecondaryOf(context),
                            fontWeight: p.availableFromFormatted != null 
                                ? FontWeight.bold 
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildPropertyActionsMenu(context, p, metadata, isMine),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.select<AuthBloc, UserModel?>((bloc) {
      final state = bloc.state;
      return state is Authenticated ? state.user : null;
    });
    final currentUserId = currentUser?.id;
    final bool isUserAdminOrSuperAdmin = currentUser != null &&
        (currentUser.role?.toLowerCase() == 'admin' || currentUser.role?.toLowerCase() == 'super admin' || currentUser.role?.toLowerCase() == 'telecaller');
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocConsumer<PropertiesBloc, PropertiesState>(
        buildWhen: (previous, current) =>
            current is PropertiesLoaded ||
            current is PropertiesLoading ||
            current is PropertiesInitial ||
            current is PropertiesError ||
            current is PropertyCreatedState,
        listenWhen: (previous, current) =>
            current is PropertiesError || current is PropertyCreatedState,
        listener: (context, state) {
          if (state is PropertiesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message),
                  backgroundColor: CRMColors.danger),
            );
          } else if (state is PropertyCreatedState) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _openPropertyDetails(context, state.property);
              if (_scrollController.hasClients) {
                _scrollController.animateTo(0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut);
              }
              setState(() {
                _highlightedPropertyId = state.property.id;
              });
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  setState(() {
                    _highlightedPropertyId = null;
                  });
                }
              });
            });
          }
        },
        builder: (context, state) {
          final isLoading =
              state is PropertiesLoading || state is PropertiesInitial;
          List<PropertyModel> properties = [];
          PropertyMetadataModel? metadata;
          Set<String> bookmarkedIds = {};

          if (state is PropertiesLoaded) {
            properties = state.properties.where((p) {
              final ltName = p.listingTypeName.toLowerCase();
              final matchesListing = _activeListingTab == 'Rent'
                  ? ltName.contains('rent')
                  : (ltName.contains('sale') ||
                      ltName.contains('resale') ||
                      !ltName.contains('rent'));

              final matchesCategory = _selectedCategory == null ||
                  p.categoryId == _selectedCategory;

              final matchesCategoryTab = _matchesActiveCategory(p);

              final matchesConfig = _selectedConfigurations.isEmpty ||
                  _selectedConfigurations.contains(p.configurationId);

              final matchesArea = _selectedAreas.isEmpty ||
                  _selectedAreas.contains(p.areaId);

              bool matchesPrice = true;
              if (_selectedPriceSortOrRange == 'custom') {
                if (_minPrice != null && p.price < _minPrice!) {
                  matchesPrice = false;
                }
                if (_maxPrice != null && p.price > _maxPrice!) {
                  matchesPrice = false;
                }
              }

              bool matchesSearch = true;
              if (_searchController.text.trim().isNotEmpty) {
                final query = _searchController.text.trim().toLowerCase();
                final words = query.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
                matchesSearch = words.every((word) =>
                    p.propertyCode.toLowerCase().contains(word) ||
                    p.title.toLowerCase().contains(word) ||
                    (p.description?.toLowerCase().contains(word) ?? false) ||
                    p.ownerName.toLowerCase().contains(word) ||
                    p.ownerMobile.toLowerCase().contains(word) ||
                    p.areaName.toLowerCase().contains(word) ||
                    p.cityName.toLowerCase().contains(word) ||
                    p.categoryName.toLowerCase().contains(word) ||
                    (p.configurationName?.toLowerCase().contains(word) ?? false) ||
                    p.propertyTypeName.toLowerCase().contains(word) ||
                    (isUserAdminOrSuperAdmin &&
                     (currentUser?.role == 'Super Admin' ||
                      (currentUser?.role == 'Admin' && (p.createdBy == currentUser?.id || p.adminId == currentUser?.id)) ||
                      (currentUser?.role == 'Telecaller' && (p.createdBy == currentUser?.id || p.adminId == currentUser?.adminId))) &&
                     p.createdByName.toLowerCase().contains(word)));
              }

              final matchesMyAdded = !_myAddedOnly || (p.createdBy == currentUserId);
              final matchesArchive = _archiveTabOnly
                  ? _archivedPropertyIds.contains(p.id)
                  : !_archivedPropertyIds.contains(p.id);
              final matchesStatus = _selectedStatusFilter == null ||
                  (p.propertyStatusName ?? '').toLowerCase() == _selectedStatusFilter!.toLowerCase();

              final cat = p.categoryName.toLowerCase();
              bool matchesTabCategory = false;
              if (_activeCategoryTab == 'All') {
                matchesTabCategory = true;
              } else if (_activeCategoryTab == 'Residential') {
                matchesTabCategory = cat.contains('resident') ||
                    cat.contains('apartment') ||
                    cat.contains('flat') ||
                    cat.contains('villa') ||
                    cat.contains('house') ||
                    cat.contains('bhk') ||
                    (!cat.contains('commercial') &&
                        !cat.contains('industrial') &&
                        !cat.contains('land') &&
                        !cat.contains('plot'));
              } else if (_activeCategoryTab == 'Commercial') {
                matchesTabCategory = cat.contains('commercial') ||
                    cat.contains('office') ||
                    cat.contains('shop') ||
                    cat.contains('showroom') ||
                    cat.contains('retail');
              } else if (_activeCategoryTab == 'Industrial') {
                matchesTabCategory = cat.contains('industrial') ||
                    cat.contains('factory') ||
                    cat.contains('warehouse') ||
                    cat.contains('shed');
              } else if (_activeCategoryTab == 'Land & Plot') {
                matchesTabCategory = cat.contains('land') || cat.contains('plot');
              }

              bool matchesBhk = true;
              if (_activeBhkFilter != null && _activeBhkFilter != 'All BHK') {
                if (_activeBhkFilter == '1 BHK') {
                  matchesBhk = p.bedrooms == 1 || (p.configurationName?.contains('1') ?? false);
                } else if (_activeBhkFilter == '2 BHK') {
                  matchesBhk = p.bedrooms == 2 || (p.configurationName?.contains('2') ?? false);
                } else if (_activeBhkFilter == '3 BHK') {
                  matchesBhk = p.bedrooms == 3 || (p.configurationName?.contains('3') ?? false);
                } else if (_activeBhkFilter == '4 BHK') {
                  matchesBhk = p.bedrooms == 4 || (p.configurationName?.contains('4') ?? false);
                } else if (_activeBhkFilter == '5+ BHK') {
                  matchesBhk = p.bedrooms >= 5 || (p.configurationName?.contains('5') ?? false);
                }
              }

              final matchesNoImages = !_noImagesOnly || p.images.isEmpty;

              return matchesListing &&
                  matchesCategory &&
                  matchesTabCategory &&
                  matchesConfig &&
                  matchesArea &&
                  matchesSearch &&
                  matchesPrice &&
                  matchesMyAdded &&
                  matchesArchive &&
                  matchesStatus &&
                  matchesCategoryTab &&
                  matchesBhk &&
                  matchesNoImages;
            }).toList();

            // Default sorting: Newest first (latest property appears first)
            properties.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            // Price Sorting (Low to High / High to Low)
            if (_selectedPriceSortOrRange == 'l2h') {
              properties.sort((a, b) => a.price.compareTo(b.price));
            } else if (_selectedPriceSortOrRange == 'h2l') {
              properties.sort((a, b) => b.price.compareTo(a.price));
            }

            metadata = state.metadata;
            _cachedMetadata = state.metadata;
            bookmarkedIds = state.bookmarkedIds;

            final bhkParam = GoRouterState.of(context).uri.queryParameters['bhk'];
            if (bhkParam != null && bhkParam.isNotEmpty) {
              if (bhkParam == '1' || bhkParam == '2' || bhkParam == '3' || bhkParam == '4') {
                _activeBhkFilter = '$bhkParam BHK';
              } else if (bhkParam == '5') {
                _activeBhkFilter = '5+ BHK';
              }
            }

            final searchQuery = GoRouterState.of(context).uri.queryParameters['search'] ??
                GoRouterState.of(context).uri.queryParameters['q'];
            if (searchQuery != null && searchQuery.isNotEmpty && _searchController.text != searchQuery) {
              _searchController.text = searchQuery;
              final sqLower = searchQuery.toLowerCase();
              if (sqLower.contains('commercial') || sqLower.contains('office') || sqLower.contains('shop') || sqLower.contains('showroom')) {
                _activeCategoryTab = 'Commercial';
              } else if (sqLower.contains('industrial') || sqLower.contains('factory') || sqLower.contains('warehouse')) {
                _activeCategoryTab = 'Industrial';
              } else if (sqLower.contains('land') || sqLower.contains('plot')) {
                _activeCategoryTab = 'Land & Plot';
              }
            }

            final listingParam = GoRouterState.of(context).uri.queryParameters['listingType'];
            if (listingParam != null && listingParam.isNotEmpty) {
              if (listingParam.toLowerCase() == 'rent' && _activeListingTab != 'Rent') {
                _activeListingTab = 'Rent';
              } else if ((listingParam.toLowerCase().contains('sale') || listingParam.toLowerCase().contains('re-sale')) && _activeListingTab != 'Re-Sale') {
                _activeListingTab = 'Re-Sale';
              }
            }

            final action =
                GoRouterState.of(context).uri.queryParameters['action'];
            if (action == 'add' &&
                !_hasAutoOpenedAdd &&
                state.metadata != null) {
              _hasAutoOpenedAdd = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showAddEditPropertyDialog(context, state.metadata!);
              });
            }

            final openId = widget.openPropertyId ??
                GoRouterState.of(context).uri.queryParameters['openId'];
            final t = GoRouterState.of(context).uri.queryParameters['t'];
            final uniqueKey = openId != null ? '${openId}_$t' : null;
            if (openId != null && _lastOpenedKey != uniqueKey) {
              _lastOpenedKey = uniqueKey;
              PropertyModel? matched;
              for (final item in properties) {
                if (item.id == openId) {
                  matched = item;
                  break;
                }
              }
              if (matched != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _openPropertyDetails(context, matched!);
                });
              } else {
                PropertiesRepository().getPropertyById(openId).then((p) {
                  if (p != null && mounted) {
                    _openPropertyDetails(context, p);
                  }
                });
              }
            }
          }

          final totalPages =
              properties.isEmpty ? 1 : (properties.length / _pageSize).ceil();
          final safePage = _currentPage.clamp(0, totalPages - 1);
          final pageStart = safePage * _pageSize;
          final pageEnd = (pageStart + _pageSize).clamp(0, properties.length);
          final pagedProperties = properties.isEmpty
              ? properties
              : properties.sublist(pageStart, pageEnd);

          return SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: CRMSpacing.m,
              vertical: CRMSpacing.l,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Responsive Page Header
                _buildPageHeader(_cachedMetadata),
                const SizedBox(height: CRMSpacing.m),

                // Rent vs Re-Sale Toggle Tabs
                Wrap(
                  spacing: CRMSpacing.s,
                  runSpacing: CRMSpacing.s,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      height: 36,
                      width: screenWidth < 600 ? 170 : 210,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: CRMColors.backgroundOf(context),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.6), width: 1.0),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                              child: _buildPropertyListingTabButton('Rent')),
                          const SizedBox(width: 4),
                          Expanded(
                              child: _buildPropertyListingTabButton('Re-Sale')),
                        ],
                      ),
                    ),
                    _buildMyAddedToggle(),
                    _buildArchiveToggle(),
                  ],
                ),
                const SizedBox(height: CRMSpacing.l),

                // 2. Statistics Row (Overflow Fixed Layout)
                _buildStatisticsRow(state is PropertiesLoaded ? state.properties : const []),
                const SizedBox(height: CRMSpacing.l),

                // 3. Search & 4. Advanced Filters
                _buildSearchAndFilters(_cachedMetadata),
                const SizedBox(height: CRMSpacing.l),

                // 5. Action Toolbar (Responsive choice chips)
                _buildActionToolbar(properties, pagedProperties),
                const SizedBox(height: CRMSpacing.m),

                // Bulk Actions Toolbar (When properties are selected)
                _buildBulkActionsToolbar(properties),

                // 6. Property Cards View / Table View & 7. Pagination
                if (!_isTableView) ...[
                  if (isLoading)
                    const Center(
                        child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator()))
                  else ...[
                    _buildHousingStyleResultsHeader(context, properties.length, pageStart, pageEnd),
                    if (pagedProperties.isEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: CRMCard(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(CRMSpacing.xl),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'No Properties Found',
                                  style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context)),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: CRMSpacing.s),
                                Text(
                                  _noImagesOnly
                                      ? 'No properties without images found.'
                                      : 'No records match your active search terms.',
                                  style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context)),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: pagedProperties.map((p) {
                          return _buildRichPropertyCard(
                              p, currentUser, bookmarkedIds, metadata);
                        }).toList(),
                      ),
                  ],
                ] else ...[
                  CRMDataTable(
                    isLoading: isLoading,
                    emptyTitle: 'No Properties Found',
                    emptyDescription:
                        'No records match your active search terms.',
                    showCheckboxColumn: false,
                    dataRowMinHeight: 72.0,
                    dataRowMaxHeight: 80.0,
                    columns: [
                      DataColumn(
                        label: Checkbox(
                          value: pagedProperties.isNotEmpty &&
                              pagedProperties.every((p) => _selectedPropertyIds.contains(p.id)),
                          tristate: pagedProperties.any((p) => _selectedPropertyIds.contains(p.id)) &&
                              !pagedProperties.every((p) => _selectedPropertyIds.contains(p.id)),
                          onChanged: (bool? checked) {
                            setState(() {
                              if (checked == true) {
                                for (final p in pagedProperties) {
                                  _selectedPropertyIds.add(p.id);
                                }
                              } else {
                                for (final p in pagedProperties) {
                                  _selectedPropertyIds.remove(p.id);
                                }
                              }
                            });
                          },
                        ),
                      ),
                      const DataColumn(label: Text('Code')),
                      if (isUserAdminOrSuperAdmin)
                        const DataColumn(label: Text('Added By')),
                      const DataColumn(label: Text('Property Name')),
                      const DataColumn(label: Text('Owner')),
                      const DataColumn(label: Text('Area')),
                      DataColumn(label: Text(_getBhkColumnHeader(metadata))),
                      const DataColumn(label: Text('Price')),
                      const DataColumn(label: Text('Date')),
                      const DataColumn(label: Text('Status')),
                      const DataColumn(label: Text('Photos')),
                      const DataColumn(label: Text('Actions')),
                    ],
                    rows: pagedProperties.map((p) {
                      final isMine = _hasEditAccess(p, currentUser);
                      final isBookmarked = bookmarkedIds.contains(p.id);
                      return DataRow(
                        color:
                            WidgetStateProperty.resolveWith<Color?>((states) {
                          if (p.id == _highlightedPropertyId) {
                            return CRMColors.primaryOf(context).withOpacity(0.08);
                          }
                          return null;
                        }),
                        onSelectChanged: (_) =>
                            _openPropertyDetails(context, p),
                        cells: [
                          DataCell(
                            Checkbox(
                              value: _selectedPropertyIds.contains(p.id),
                              onChanged: (bool? checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selectedPropertyIds.add(p.id);
                                  } else {
                                    _selectedPropertyIds.remove(p.id);
                                  }
                                });
                              },
                            ),
                          ),
                          DataCell(Text(p.propertyCode,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold))),
                          if (isUserAdminOrSuperAdmin)
                            DataCell(Text(
                              (currentUser?.role == 'Super Admin' ||
                                      (currentUser?.role == 'Admin' && (p.createdBy == currentUser?.id || p.adminId == currentUser?.id)) ||
                                      (currentUser?.role == 'Telecaller' && (p.createdBy == currentUser?.id || p.adminId == currentUser?.adminId)))
                                  ? p.createdByName
                                  : '-',
                            )),
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(p.title ?? 'No Title', maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      p.availableFromFormatted != null 
                                          ? Icons.event_available_rounded 
                                          : Icons.event_busy_rounded,
                                      size: 12,
                                      color: p.availableFromFormatted != null 
                                          ? CRMColors.success 
                                          : CRMColors.textSecondaryOf(context),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      p.availableFromFormatted != null 
                                          ? 'Available: ${p.availableFromFormatted}' 
                                          : 'Not Available',
                                      style: TextStyle(
                                        color: p.availableFromFormatted != null 
                                            ? CRMColors.success 
                                            : CRMColors.textSecondaryOf(context),
                                        fontSize: 10.5,
                                        fontWeight: p.availableFromFormatted != null 
                                            ? FontWeight.bold 
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(p.ownerName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  Text(p.ownerMobile,
                                      style: TextStyle(
                                          color: CRMColors.textMutedOf(context),
                                          fontSize: 11)),
                                ],
                              ),
                            ),
                          ),
                          DataCell(Text(p.areaName)),
                          DataCell(Text(_getPropertyBhkOrAreaValue(p))),
                          DataCell(Text(CRMCurrencyFormatter.formatShort(p.price),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600))),
                          DataCell(Text(
                              DateFormat('dd-MM-yyyy').format(p.createdAt))),
                          DataCell(
                            PopupMenuButton<String>(
                              tooltip: 'Change Status',
                              onSelected: (String statusName) async {
                                if (statusName == 'Available') {
                                  final currentStatus = (p.propertyStatusName ?? '').toLowerCase();
                                  final isCurrentlyRentedOrSold = currentStatus.contains('rented') || currentStatus.contains('sold');

                                  if (isCurrentlyRentedOrSold) {
                                    final clientName = await PropertyDealClientStore.getClientName(p.id, property: p);
                                    final bool hasClient = clientName != null && clientName.trim().isNotEmpty;

                                    final bool? confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (dialogContext) => AlertDialog(
                                        backgroundColor: CRMColors.cardBgOf(context),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(CRMBorderRadius.m),
                                        ),
                                        title: Text(
                                          "Confirm Status Change",
                                          style: CRMTypography.sectionTitle.copyWith(
                                            color: CRMColors.textOf(context),
                                          ),
                                        ),
                                         content: Text.rich(
                                           TextSpan(
                                             style: CRMTypography.body.copyWith(
                                               color: CRMColors.textSecondaryOf(context),
                                               height: 1.5,
                                             ),
                                             children: hasClient
                                                 ? [
                                                     const TextSpan(text: "This property is currently assigned to client "),
                                                     TextSpan(
                                                       text: "'$clientName'",
                                                       style: TextStyle(
                                                         color: CRMColors.primaryOf(context),
                                                         fontWeight: FontWeight.bold,
                                                       ),
                                                     ),
                                                     TextSpan(
                                                       text: " (${p.propertyStatusName}).\n\n",
                                                       style: TextStyle(
                                                         color: CRMColors.textOf(context),
                                                         fontWeight: FontWeight.w600,
                                                       ),
                                                     ),
                                                     const TextSpan(
                                                       text: "Are you sure you want to change its status to ",
                                                     ),
                                                     TextSpan(
                                                       text: "Available",
                                                       style: const TextStyle(
                                                         color: CRMColors.success,
                                                         fontWeight: FontWeight.bold,
                                                       ),
                                                     ),
                                                     const TextSpan(text: "?"),
                                                   ]
                                                 : [
                                                     const TextSpan(
                                                       text: "Are you sure you want to change the status of this property from ",
                                                     ),
                                                     TextSpan(
                                                       text: p.propertyStatusName ?? 'Rented Out',
                                                       style: TextStyle(
                                                         color: CRMColors.textOf(context),
                                                         fontWeight: FontWeight.bold,
                                                       ),
                                                     ),
                                                     const TextSpan(text: " to "),
                                                     TextSpan(
                                                       text: "Available",
                                                       style: const TextStyle(
                                                         color: CRMColors.success,
                                                         fontWeight: FontWeight.bold,
                                                       ),
                                                     ),
                                                     const TextSpan(text: "?"),
                                                   ],
                                           ),
                                         ),
                                        actions: [
                                          CRMButton(
                                            label: "Cancel",
                                            variant: CRMButtonVariant.outline,
                                            onPressed: () => Navigator.pop(dialogContext, false),
                                          ),
                                          const SizedBox(width: CRMSpacing.xs),
                                          CRMButton(
                                            label: "Yes",
                                            variant: CRMButtonVariant.primary,
                                            onPressed: () => Navigator.pop(dialogContext, true),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm != true) return;

                                    await PropertyDealClientStore.removeClientName(p.id);
                                  }
                                }

                                if (statusName == 'To Be Available') {
                                  final DateTime? pickedDate =
                                      await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now()
                                        .add(const Duration(days: 1)),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now()
                                        .add(const Duration(days: 365 * 5)),
                                    helpText: 'Select Available Date',
                                  );
                                  if (pickedDate == null) return;

                                  LookupItem? targetLookup;
                                  if (metadata != null) {
                                    for (final s in metadata.statuses) {
                                      if (s.name
                                          .toLowerCase()
                                          .contains('to be available')) {
                                        targetLookup = s;
                                        break;
                                      }
                                    }
                                  }
                                  final statusId = targetLookup?.id ??
                                      '05a73434-e99b-425b-99b2-1825d529ac35';
                                  if (context.mounted) {
                                    context.read<PropertiesBloc>().add(
                                          UpdatePropertyEvent(
                                            p.id,
                                            {
                                              'property_status_id': statusId,
                                              'possession_date': pickedDate
                                                  .toIso8601String()
                                                  .substring(0, 10),
                                            },
                                            activeTab: _activeTab,
                                          ),
                                        );
                                  }
                                  return;
                                }

                                LookupItem? targetLookup;
                                if (metadata != null) {
                                  for (final s in metadata.statuses) {
                                    if (s.name
                                            .toLowerCase()
                                            .replaceAll(' ', '') ==
                                        statusName
                                            .toLowerCase()
                                            .replaceAll(' ', '')) {
                                      targetLookup = s;
                                      break;
                                    }
                                  }
                                }
                                final statusId = targetLookup?.id ?? statusName;
                                context.read<PropertiesBloc>().add(
                                      UpdatePropertyEvent(
                                        p.id,
                                        {'property_status_id': statusId},
                                        activeTab: _activeTab,
                                      ),
                                    );
                              },
                              itemBuilder: (BuildContext context) {
                                final isRent = p.listingTypeName
                                    .toLowerCase()
                                    .contains('rent');
                                return <PopupMenuEntry<String>>[
                                  const PopupMenuItem<String>(
                                    value: 'Available',
                                    child: Text('Available'),
                                  ),
                                  if (isRent) ...[
                                    const PopupMenuItem<String>(
                                      value: 'Rented Out',
                                      child: Text('Rented Out'),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'To Be Available',
                                      child: Text('To Be Available'),
                                    ),
                                  ] else ...[
                                    const PopupMenuItem<String>(
                                      value: 'Sold Out',
                                      child: Text('Sold Out'),
                                    ),
                                  ],
                                ];
                              },
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: p.isStatusAvailable
                                        ? CRMColors.success
                                            .withValues(alpha: 0.12)
                                        : CRMColors.warning
                                            .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(
                                        CRMBorderRadius.xs),
                                    border: Border.all(
                                      color: (p.isStatusAvailable
                                              ? CRMColors.success
                                              : CRMColors.warning)
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          p.statusDisplayName,
                                          style: TextStyle(
                                            color: p.isStatusAvailable
                                                ? CRMColors.success
                                                : CRMColors.warning,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Icon(
                                          Icons.arrow_drop_down_rounded,
                                          size: 16,
                                          color: p.isStatusAvailable
                                              ? CRMColors.success
                                              : CRMColors.warning,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Builder(
                              builder: (context) {
                                final hasImages = p.images.isNotEmpty;
                                return InkWell(
                                  onTap: hasImages
                                      ? () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => CRMImageZoomViewer(
                                              images: p.images,
                                              initialIndex: 0,
                                            ),
                                          );
                                        }
                                      : null,
                                  borderRadius:
                                      BorderRadius.circular(CRMBorderRadius.xs),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: CRMColors.backgroundOf(context),
                                      borderRadius: BorderRadius.circular(
                                          CRMBorderRadius.xs),
                                      border: Border.all(
                                        color: hasImages
                                            ? CRMColors.primaryOf(context).withOpacity(0.3)
                                            : CRMColors.borderOf(context).withOpacity(0.6),
                                        width: 0.5,
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: hasImages
                                        ? Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              _buildPropertyThumbnail(
                                                  p.images.first),
                                              if (p.images.length > 1)
                                                Positioned(
                                                  right: 0,
                                                  bottom: 0,
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 3,
                                                        vertical: 1),
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Color(0xB3000000),
                                                      borderRadius:
                                                          BorderRadius.only(
                                                              topLeft: Radius
                                                                  .circular(4)),
                                                    ),
                                                    child: Text(
                                                      '+${p.images.length - 1}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          )
                                        : Icon(
                                            p.videos.isNotEmpty
                                                ? Icons.play_circle_outline_rounded
                                                : Icons.image_not_supported_outlined,
                                            size: 18,
                                            color: p.videos.isNotEmpty
                                                ? CRMColors.primaryOf(context)
                                                : CRMColors.textMutedOf(context),
                                          ),
                                  ),
                                );
                              },
                            ),
                          ),
                          DataCell(
                            _buildPropertyActionsMenu(context, p, metadata, isMine),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
                if (properties.isNotEmpty) ...[
                  const SizedBox(height: CRMSpacing.m),
                  _buildPagination(properties.length, totalPages, safePage),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageHeader(PropertyMetadataModel? metadata) {
    return CRMPageHeader(
      title: 'Properties',
      trailing: CRMButton(
        label: 'Add Property',
        prefixIcon: Icons.add_rounded,
        height: 40,
        onPressed: () {
          if (metadata == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('Loading details, please wait...')),
            );
            return;
          }
          _showAddEditPropertyDialog(context, metadata!);
        },
      ),
    );
  }

  Widget _buildStatisticsRow(List<PropertyModel> properties) {
    final filteredByMyAdded = properties.where((p) {
      if (!_myAddedOnly) return true;
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        return p.createdBy == authState.user.id;
      }
      return false;
    }).toList();

    final filteredByStatus = filteredByMyAdded.where((p) {
      return _selectedStatusFilter == null ||
          (p.propertyStatusName ?? '').toLowerCase() == _selectedStatusFilter!.toLowerCase();
    }).toList();

    final filteredByListingTab = filteredByStatus.where((p) {
      final ltName = p.listingTypeName.toLowerCase();
      if (_activeListingTab == 'Rent') {
        return ltName.contains('rent');
      } else {
        return ltName.contains('sale') ||
            ltName.contains('resale') ||
            !ltName.contains('rent');
      }
    }).toList();

    final filteredByListingAndCategory = filteredByListingTab.where(_matchesActiveCategory).toList();
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    final double cardWidth = isMobile
        ? (screenWidth - (CRMSpacing.m * 2) - CRMSpacing.m).clamp(0.0, double.infinity) / 2
        : 180.0;
    final double chartCardWidth = isMobile
        ? (screenWidth - (CRMSpacing.m * 2))
        : 260.0;
    final double cardHeight = isMobile ? 132.0 : 148.0;

    final List<Widget> widgets = [];
    Widget? mobileKpiCard;
    String mobileChartTitle = '';
    List<ChartSector> mobileSectors = [];

    if (_activeCategoryTab == 'Residential') {
      final statusCount = filteredByListingAndCategory.length;
      final kpi = CRMKPICard(
        title: '${_selectedStatusFilter ?? "Inventory"} listings',
        value: '$statusCount',
        icon: Icons.bolt_rounded,
        iconColor: CRMColors.terracotta,
        backgroundColor: CRMColors.kpiSage,
      );
      widgets.add(SizedBox(
        width: cardWidth,
        height: cardHeight,
        child: kpi,
      ));
      mobileKpiCard = kpi;
      mobileChartTitle = 'BHK Distribution';

      final List<ChartSector> bhkSectors = [];
      final colors = [
        CRMColors.info,
        CRMColors.success,
        CRMColors.warning,
        CRMColors.danger,
        CRMColors.primaryOf(context),
      ];
      for (int bhk = 1; bhk <= 5; bhk++) {
        final count = filteredByListingAndCategory
            .where((p) =>
                ((p.configurationName != null &&
                        p.configurationName!.toLowerCase().startsWith('$bhk bhk')) ||
                    (p.configurationName == null && p.bedrooms == bhk)))
            .length;
        if (count > 0) {
          bhkSectors.add(ChartSector(
            label: '$bhk BHK',
            value: count.toDouble(),
            color: colors[(bhk - 1) % colors.length],
          ));
        }
      }
      widgets.add(SizedBox(
        width: chartCardWidth,
        height: cardHeight,
        child: CRMChartCard(
          title: 'BHK Distribution',
          sectors: bhkSectors,
        ),
      ));
      mobileSectors = bhkSectors;
    } else if (_activeCategoryTab == 'Commercial') {
      final statusCount = filteredByListingAndCategory.length;
      final kpi = CRMKPICard(
        title: 'Commercial (${_selectedStatusFilter ?? "Inventory"})',
        value: '$statusCount',
        icon: Icons.business_center_outlined,
        iconColor: CRMColors.terracotta,
        backgroundColor: CRMColors.kpiTerracotta,
      );
      widgets.add(SizedBox(
        width: cardWidth,
        height: cardHeight,
        child: kpi,
      ));
      mobileKpiCard = kpi;
      mobileChartTitle = 'Property Types';

      final Map<String, int> typeCounts = {};
      for (final p in filteredByListingAndCategory) {
        final typeName = p.propertyTypeName;
        if (typeName.isNotEmpty && typeName != 'N/A') {
          typeCounts[typeName] = (typeCounts[typeName] ?? 0) + 1;
        }
      }
      final List<ChartSector> typeSectors = [];
      final typeColors = [
        CRMColors.primaryOf(context),
        CRMColors.info,
        CRMColors.success,
        CRMColors.warning,
        CRMColors.danger,
      ];
      int index = 0;
      typeCounts.forEach((name, count) {
        if (count > 0) {
          typeSectors.add(ChartSector(
            label: name,
            value: count.toDouble(),
            color: typeColors[index % typeColors.length],
          ));
          index++;
        }
      });
      widgets.add(SizedBox(
        width: chartCardWidth,
        height: cardHeight,
        child: CRMChartCard(
          title: 'Property Types',
          sectors: typeSectors,
        ),
      ));
      mobileSectors = typeSectors;
    } else if (_activeCategoryTab == 'Industrial') {
      final statusCount = filteredByListingAndCategory.length;
      final kpi = CRMKPICard(
        title: 'Industrial (${_selectedStatusFilter ?? "Inventory"})',
        value: '$statusCount',
        icon: Icons.factory_outlined,
        iconColor: CRMColors.text,
        backgroundColor: CRMColors.kpiSand,
      );
      widgets.add(SizedBox(
        width: cardWidth,
        height: cardHeight,
        child: kpi,
      ));
      mobileKpiCard = kpi;
      mobileChartTitle = 'Industrial Subcategories';

      final warehouses = filteredByListingAndCategory.where((p) => p.categoryName.toLowerCase().contains('warehouse') || p.title.toLowerCase().contains('warehouse') || (p.description != null && p.description!.toLowerCase().contains('warehouse'))).toList();
      final factories = filteredByListingAndCategory.where((p) => p.categoryName.toLowerCase().contains('factory') || p.categoryName.toLowerCase().contains('industrial') || p.title.toLowerCase().contains('factory') || (p.description != null && p.description!.toLowerCase().contains('factory'))).toList();
      final otherCount = statusCount - (warehouses.length + factories.length);

      final indSectors = <ChartSector>[];
      if (warehouses.isNotEmpty) {
        indSectors.add(ChartSector(label: 'Warehouses', value: warehouses.length.toDouble(), color: CRMColors.warning));
      }
      if (factories.isNotEmpty) {
        indSectors.add(ChartSector(label: 'Factories', value: factories.length.toDouble(), color: CRMColors.danger));
      }
      if (otherCount > 0) {
        indSectors.add(ChartSector(label: 'Sheds & Yards', value: otherCount.toDouble(), color: CRMColors.info));
      }

      widgets.add(SizedBox(
        width: chartCardWidth,
        height: cardHeight,
        child: CRMChartCard(
          title: 'Industrial Subcategories',
          sectors: indSectors,
        ),
      ));
      mobileSectors = indSectors;
    } else if (_activeCategoryTab == 'Land & Plot') {
      final statusCount = filteredByListingAndCategory.length;
      final kpi = CRMKPICard(
        title: 'Land & Plots (${_selectedStatusFilter ?? "Inventory"})',
        value: '$statusCount',
        icon: Icons.landscape_outlined,
        iconColor: CRMColors.terracotta,
        backgroundColor: CRMColors.kpiPlum,
      );
      widgets.add(SizedBox(
        width: cardWidth,
        height: cardHeight,
        child: kpi,
      ));
      mobileKpiCard = kpi;
      mobileChartTitle = 'Zoning & Land Usage';

      final resPlots = filteredByListingAndCategory.where((p) => p.title.toLowerCase().contains('resident') || (p.description != null && p.description!.toLowerCase().contains('resident'))).toList();
      final comLand = filteredByListingAndCategory.where((p) => p.title.toLowerCase().contains('commercial') || (p.description != null && p.description!.toLowerCase().contains('commercial'))).toList();
      final otherLand = statusCount - (resPlots.length + comLand.length);

      final landSectors = <ChartSector>[];
      if (resPlots.isNotEmpty) {
        landSectors.add(ChartSector(label: 'Residential Plots', value: resPlots.length.toDouble(), color: CRMColors.success));
      }
      if (comLand.isNotEmpty) {
        landSectors.add(ChartSector(label: 'Commercial Land', value: comLand.length.toDouble(), color: CRMColors.info));
      }
      if (otherLand > 0) {
        landSectors.add(ChartSector(label: 'Other Land', value: otherLand.toDouble(), color: CRMColors.warning));
      }

      widgets.add(SizedBox(
        width: chartCardWidth,
        height: cardHeight,
        child: CRMChartCard(
          title: 'Zoning & Land Usage',
          sectors: landSectors,
        ),
      ));
      mobileSectors = landSectors;
    }

    final categories = ['Residential', 'Commercial', 'Industrial', 'Land & Plot'];
    final categorySelector = Container(
      margin: const EdgeInsets.only(bottom: CRMSpacing.m),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: categories.map((cat) {
            final isSelected = _activeCategoryTab == cat;
            return Padding(
              padding: const EdgeInsets.only(right: CRMSpacing.s),
              child: ChoiceChip(
                label: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : CRMColors.textSecondaryOf(context),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                selected: isSelected,
                selectedColor: CRMColors.primary,
                backgroundColor: CRMColors.backgroundOf(context).withOpacity(0.5),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _activeCategoryTab = cat;
                      _currentPage = 0;
                    });
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );

    if (isMobile && mobileKpiCard != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: CRMSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            categorySelector,
            _MobileStatisticsSection(
              kpiCard: mobileKpiCard,
              chartTitle: mobileChartTitle,
              sectors: mobileSectors,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CRMSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          categorySelector,
          Wrap(
            spacing: CRMSpacing.m,
            runSpacing: CRMSpacing.m,
            children: widgets,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFiltersCard(PropertyMetadataModel? metadata) {
    final categories = metadata != null ? metadata.categories : <LookupItem>[];
    final areas = metadata != null ? metadata.areas.cast<LookupItem>().toList() : <LookupItem>[];
    final listingTypes =
        metadata != null ? metadata.listingTypes : <LookupItem>[];

    return CRMCard(
      title: 'Search Filter',
      child: Padding(
        padding: const EdgeInsets.only(top: CRMSpacing.s),
        child: Column(
          children: [
            // Search Input Row
            LayoutBuilder(
              builder: (context, searchConstraints) {
                final isCompactSearch = searchConstraints.maxWidth < 500;

                final searchField = TextField(
                  controller: _searchController,
                  style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
                  decoration: InputDecoration(
                    hintText: 'Search property code, title, owner mobile...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: CRMColors.backgroundOf(context),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                        borderSide: BorderSide.none),
                  ),
                  onChanged: (_) => _loadProperties(),
                );

                final searchButton = CRMButton(
                  label: 'Search',
                  onPressed: _loadProperties,
                );

                if (isCompactSearch) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      searchField,
                      const SizedBox(height: CRMSpacing.s),
                      searchButton,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: searchField),
                    const SizedBox(width: CRMSpacing.s),
                    searchButton,
                  ],
                );
              },
            ),
            const SizedBox(height: CRMSpacing.m),

            LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                double targetWidth;

                if (width >= 900) {
                  targetWidth = (width - (CRMSpacing.m * 4)) / 5;
                } else if (width >= 600) {
                  targetWidth = (width - CRMSpacing.m) / 2;
                } else {
                  targetWidth = width;
                }

                final List<LookupItem> configurations = [];
                if (metadata != null) {
                  if (_selectedCategory == null) {
                    configurations.addAll(metadata.configurations);
                  } else {
                    final cat = categories.firstWhere(
                      (cat) => cat.id == _selectedCategory,
                      orElse: () => LookupItem(id: '', name: ''),
                    );
                    final catName = cat.name.toLowerCase();

                    if (catName.contains('commercial')) {
                      final matches = <LookupItem>[];
                      matches.addAll(metadata.configurations.where((c) {
                        final name = c.name.toLowerCase();
                        return name.contains('office') || name.contains('shop') || name.contains('showroom');
                      }));
                      matches.addAll(metadata.types.where((t) {
                        final name = t.name.toLowerCase();
                        return name.contains('office') || name.contains('shop') || name.contains('showroom');
                      }));
                      for (final m in matches) {
                        if (!configurations.any((c) => c.name.toLowerCase() == m.name.toLowerCase())) {
                          configurations.add(m);
                        }
                      }
                    } else if (catName.contains('land') || catName.contains('plot')) {
                      final matches = <LookupItem>[];
                      matches.addAll(metadata.configurations.where((c) {
                        return c.name.toLowerCase().contains('plot');
                      }));
                      matches.addAll(metadata.types.where((t) {
                        return t.name.toLowerCase().contains('plot');
                      }));
                      for (final m in matches) {
                        if (!configurations.any((c) => c.name.toLowerCase() == m.name.toLowerCase())) {
                          configurations.add(m);
                        }
                      }
                    } else if (catName.contains('industrial')) {
                      final matches = <LookupItem>[];
                      matches.addAll(metadata.configurations.where((c) {
                        final name = c.name.toLowerCase();
                        return name.contains('warehouse') || name.contains('shed') || name.contains('industrial');
                      }));
                      matches.addAll(metadata.types.where((t) {
                        final name = t.name.toLowerCase();
                        return name.contains('warehouse') || name.contains('shed') || name.contains('industrial');
                      }));
                      for (final m in matches) {
                        if (!configurations.any((c) => c.name.toLowerCase() == m.name.toLowerCase())) {
                          configurations.add(m);
                        }
                      }
                    } else if (catName.contains('residential')) {
                      final matches = metadata.configurations.where((c) {
                        final name = c.name.toLowerCase();
                        return !name.contains('office') &&
                            !name.contains('shop') &&
                            !name.contains('showroom') &&
                            !name.contains('plot') &&
                            !name.contains('warehouse') &&
                            !name.contains('shed') &&
                            !name.contains('industrial');
                      }).toList();
                      for (final m in matches) {
                        if (!configurations.any((c) => c.name.toLowerCase() == m.name.toLowerCase())) {
                          configurations.add(m);
                        }
                      }
                    } else {
                      configurations.addAll(metadata.configurations.where((c) => c.categoryId == _selectedCategory));
                    }
                  }
                }

                final bool isWide = width >= 800;
                final isRent = _activeListingTab == 'Rent';
                final statusItems = isRent
                    ? ['Available', 'Rented Out', 'To Be Available']
                    : ['Available', 'Sold Out'];

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          label: 'Status',
                          value: _selectedStatusFilter,
                          items: statusItems
                              .map((val) => DropdownMenuItem<String>(
                                  value: val, child: Text(val)))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedStatusFilter = val;
                              _currentPage = 0;
                            });
                            _loadProperties();
                          },
                          width: double.infinity,
                        ),
                      ),
                      const SizedBox(width: CRMSpacing.m),
                      Expanded(
                        child: CRMMultiSelectDropdown(
                          label: (() {
                            if (_selectedCategory != null) {
                              final cat = categories.firstWhere(
                                (c) => c.id == _selectedCategory,
                                orElse: () => LookupItem(id: '', name: ''),
                              );
                              final catName = cat.name.toLowerCase();
                              if (catName.contains('commercial') ||
                                  catName.contains('industrial') ||
                                  catName.contains('land') ||
                                  catName.contains('plot')) {
                                return 'Property Type';
                              }
                            }
                            return 'BHK';
                          })(),
                          selectedIds: _selectedConfigurations,
                          items: configurations,
                          onChanged: (vals) {
                            setState(() {
                              _currentPage = 0;
                            });
                            _loadProperties();
                          },
                        ),
                      ),
                      const SizedBox(width: CRMSpacing.m),
                      Expanded(
                        child: CRMMultiSelectDropdown(
                          label: 'Area',
                          selectedIds: _selectedAreas,
                          items: areas,
                          onChanged: (vals) {
                            setState(() {
                              _currentPage = 0;
                            });
                            _loadProperties();
                          },
                        ),
                      ),
                      const SizedBox(width: CRMSpacing.m),
                      Expanded(
                        child: _buildDropdown(
                          label: 'Price Range',
                          value: _selectedPriceSortOrRange,
                          items: [
                            const DropdownMenuItem<String>(
                              value: 'l2h',
                              child: Text('Low to High'),
                            ),
                            const DropdownMenuItem<String>(
                              value: 'h2l',
                              child: Text('High to Low'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'custom',
                              child: Text(
                                _minPrice != null || _maxPrice != null
                                    ? 'Custom: ₹${_minPrice != null ? BudgetFormatter.format(_minPrice!) : '0'} - ₹${_maxPrice != null ? BudgetFormatter.format(_maxPrice!) : 'Max'}'
                                    : 'Custom Range...',
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val == 'custom') {
                              _showCustomPriceRangeDialog();
                            } else {
                              setState(() {
                                _selectedPriceSortOrRange = val;
                                _minPrice = null;
                                _maxPrice = null;
                                _currentPage = 0;
                              });
                              _loadProperties();
                            }
                          },
                          width: double.infinity,
                        ),
                      ),
                      const SizedBox(width: CRMSpacing.m),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: CRMButton(
                            label: 'Clear Filters',
                            variant: CRMButtonVariant.outline,
                            onPressed: _clearFilters,
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  final double columnWidth = width < 500 ? width : (width - CRMSpacing.m) / 2;
                  return Wrap(
                    spacing: CRMSpacing.m,
                    runSpacing: CRMSpacing.m,
                    children: [
                      _buildDropdown(
                        label: 'Status',
                        value: _selectedStatusFilter,
                        items: statusItems
                            .map((val) => DropdownMenuItem<String>(
                                value: val, child: Text(val)))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedStatusFilter = val;
                            _currentPage = 0;
                          });
                          _loadProperties();
                        },
                        width: columnWidth,
                      ),
                      SizedBox(
                        width: columnWidth,
                        child: CRMMultiSelectDropdown(
                          label: (() {
                            if (_selectedCategory != null) {
                              final cat = categories.firstWhere(
                                (c) => c.id == _selectedCategory,
                                orElse: () => LookupItem(id: '', name: ''),
                              );
                              final catName = cat.name.toLowerCase();
                              if (catName.contains('commercial') ||
                                  catName.contains('industrial') ||
                                  catName.contains('land') ||
                                  catName.contains('plot')) {
                                return 'Property Type';
                              }
                            }
                            return 'BHK';
                          })(),
                          selectedIds: _selectedConfigurations,
                          items: configurations,
                          onChanged: (vals) {
                            setState(() {
                              _currentPage = 0;
                            });
                            _loadProperties();
                          },
                        ),
                      ),
                      SizedBox(
                        width: columnWidth,
                        child: CRMMultiSelectDropdown(
                          label: 'Area',
                          selectedIds: _selectedAreas,
                          items: areas,
                          onChanged: (vals) {
                            setState(() {
                              _currentPage = 0;
                            });
                            _loadProperties();
                          },
                        ),
                      ),
                      _buildDropdown(
                        label: 'Price Range',
                        value: _selectedPriceSortOrRange,
                        items: [
                          const DropdownMenuItem<String>(
                            value: 'l2h',
                            child: Text('Low to High'),
                          ),
                          const DropdownMenuItem<String>(
                            value: 'h2l',
                            child: Text('High to Low'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'custom',
                            child: Text(
                              _minPrice != null || _maxPrice != null
                                  ? 'Custom: ₹${_minPrice != null ? BudgetFormatter.format(_minPrice!) : '0'} - ₹${_maxPrice != null ? BudgetFormatter.format(_maxPrice!) : 'Max'}'
                                  : 'Custom Range...',
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val == 'custom') {
                            _showCustomPriceRangeDialog();
                          } else {
                            setState(() {
                              _selectedPriceSortOrRange = val;
                              _minPrice = null;
                              _maxPrice = null;
                              _currentPage = 0;
                            });
                            _loadProperties();
                          }
                        },
                        width: columnWidth,
                      ),
                      SizedBox(
                        width: columnWidth,
                        height: 48,
                        child: CRMButton(
                          label: 'Clear Filters',
                          variant: CRMButtonVariant.outline,
                          onPressed: _clearFilters,
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileFilterButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isMobileFiltersExpanded = !_isMobileFiltersExpanded;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: 12),
        decoration: BoxDecoration(
          color: _isMobileFiltersExpanded ? CRMColors.primary : CRMColors.cardBgOf(context),
          borderRadius: BorderRadius.circular(CRMBorderRadius.card),
          border: Border.all(
            color: _isMobileFiltersExpanded ? CRMColors.primary : CRMColors.borderOf(context).withOpacity(0.6),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.3)
                  : const Color(0xFF64748B).withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_rounded,
              size: 18,
              color: _isMobileFiltersExpanded ? Colors.white : CRMColors.primaryOf(context),
            ),
            const SizedBox(width: CRMSpacing.s),
            Text(
              _isMobileFiltersExpanded ? "Hide Filters" : "Show Search Filters",
              style: CRMTypography.bodyMedium.copyWith(
                color: _isMobileFiltersExpanded ? Colors.white : CRMColors.textOf(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(PropertyMetadataModel? metadata) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMobileFilterButton(),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isMobileFiltersExpanded
                ? Padding(
                    padding: const EdgeInsets.only(top: CRMSpacing.m),
                    child: _buildSearchFiltersCard(metadata),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      );
    }

    return _buildSearchFiltersCard(metadata);
  }

  Widget _buildPropertyListingTabButton(String label) {
    final isSelected = _activeListingTab == label;
    final accent =
        label == 'Rent' ? CRMColors.rentAccent : CRMColors.resaleAccent;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeListingTab = label;
          _currentPage = 0;
          _selectedStatusFilter = null;
        });
      },
      child: AnimatedContainer(
        duration: CRMMotion.fast,
        curve: CRMMotion.easeOut,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected
                ? CRMColors.onAtmosphereAccent(label == 'Rent')
                : CRMColors.textSecondaryOf(context),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMyAddedToggle() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _myAddedOnly = !_myAddedOnly;
          if (_myAddedOnly) {
            _archiveTabOnly = false;
          }
        });
      },
      child: AnimatedContainer(
        duration: CRMMotion.fast,
        curve: CRMMotion.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _myAddedOnly ? CRMColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _myAddedOnly ? CRMColors.primary : CRMColors.borderOf(context).withOpacity(0.6),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _myAddedOnly ? Icons.check_circle_rounded : Icons.person_outline_rounded,
              size: 14,
              color: _myAddedOnly ? Colors.white : CRMColors.textSecondaryOf(context),
            ),
            const SizedBox(width: CRMSpacing.xs),
            Text(
              "My Added",
              style: TextStyle(
                fontSize: 12,
                color: _myAddedOnly ? Colors.white : CRMColors.textSecondaryOf(context),
                fontWeight: _myAddedOnly ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchiveToggle() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _archiveTabOnly = !_archiveTabOnly;
          if (_archiveTabOnly) {
            _myAddedOnly = false;
          }
        });
      },
      child: AnimatedContainer(
        duration: CRMMotion.fast,
        curve: CRMMotion.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _archiveTabOnly ? CRMColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _archiveTabOnly ? CRMColors.primary : CRMColors.borderOf(context).withOpacity(0.6),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _archiveTabOnly ? Icons.archive : Icons.archive_outlined,
              size: 14,
              color: _archiveTabOnly ? Colors.white : CRMColors.textSecondaryOf(context),
            ),
            const SizedBox(width: CRMSpacing.xs),
            Text(
              "Archive",
              style: TextStyle(
                fontSize: 12,
                color: _archiveTabOnly ? Colors.white : CRMColors.textSecondaryOf(context),
                fontWeight: _archiveTabOnly ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(List<LookupItem> categories) {
    return Container(
      width: 180,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m),
      decoration: BoxDecoration(
        color: CRMColors.backgroundOf(context),
        borderRadius: BorderRadius.circular(CRMBorderRadius.s),
        border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.6), width: 1.0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedCategory,
          hint: Text(
            'All Category',
            style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondaryOf(context)),
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(
                'All Category',
                style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textOf(context)),
              ),
            ),
            ...categories.map((c) {
              return DropdownMenuItem<String?>(
                value: c.id,
                child: Text(
                  c.name,
                  style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textOf(context)),
                ),
              );
            }),
          ],
          onChanged: (String? val) {
            setState(() {
              _selectedCategory = val;
              _selectedConfigurations.clear();
              _currentPage = 0;
            });
            _loadProperties();
          },
          icon: Icon(Icons.arrow_drop_down, color: CRMColors.textSecondaryOf(context)),
          dropdownColor: CRMColors.cardBgOf(context),
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = null;
      _selectedConfigurations.clear();
      _selectedAreas.clear();
      _selectedListingType = null;
      _selectedVerification = null;
      _activeListingTab = 'Rent';
      _selectedPriceSortOrRange = null;
      _minPrice = null;
      _maxPrice = null;
      _currentPage = 0;
      _myAddedOnly = false;
      _selectedStatusFilter = null;
    });
    _loadProperties();
  }

  Future<void> _showCustomPriceRangeDialog() async {
    final previousSelection = _selectedPriceSortOrRange;
    double currentMin = _minPrice ?? 0;
    double maxSliderLimit = ThemeManager().isRentMode ? 200000 : 10000000;
    double currentMax = _maxPrice ?? maxSliderLimit;
    if (currentMax > maxSliderLimit) maxSliderLimit = currentMax;

    final minController = TextEditingController(
      text: _minPrice != null ? BudgetFormatter.format(_minPrice!) : '0',
    );
    final maxController = TextEditingController(
      text: _maxPrice != null ? BudgetFormatter.format(_maxPrice!) : BudgetFormatter.format(maxSliderLimit),
    );

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double sliderMin = currentMin.clamp(0.0, maxSliderLimit);
            double sliderMax = currentMax.clamp(sliderMin, maxSliderLimit);

            return AlertDialog(
              backgroundColor: CRMColors.cardBgOf(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              content: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: CRMColors.textOf(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: CRMColors.cardBgOf(context),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.6)),
                            ),
                            child: Row(
                              children: [
                                Text('Min: ', style: TextStyle(color: CRMColors.textSecondaryOf(context), fontSize: 13)),
                                Expanded(
                                  child: TextField(
                                    controller: minController,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(color: CRMColors.textOf(context), fontSize: 13, fontWeight: FontWeight.bold),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onChanged: (val) {
                                      final parsed = BudgetFormatter.parse(val);
                                      setDialogState(() {
                                        currentMin = parsed;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'To',
                            style: TextStyle(
                              color: CRMColors.textOf(context),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: CRMColors.cardBgOf(context),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.6)),
                            ),
                            child: Row(
                              children: [
                                Text('Max: ', style: TextStyle(color: CRMColors.textSecondaryOf(context), fontSize: 13)),
                                Expanded(
                                  child: TextField(
                                    controller: maxController,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(color: CRMColors.textOf(context), fontSize: 13, fontWeight: FontWeight.bold),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onChanged: (val) {
                                      final parsed = BudgetFormatter.parse(val);
                                      setDialogState(() {
                                        currentMax = parsed;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: const Color(0xFF6C5CE7),
                        inactiveTrackColor: const Color(0xFF6C5CE7).withOpacity(0.2),
                        thumbColor: Colors.white,
                        overlayColor: const Color(0xFF6C5CE7).withOpacity(0.12),
                        rangeThumbShape: const RoundRangeSliderThumbShape(
                          enabledThumbRadius: 10,
                          elevation: 3,
                        ),
                        rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
                        trackHeight: 3,
                      ),
                      child: RangeSlider(
                        values: RangeValues(sliderMin, sliderMax),
                        min: 0,
                        max: maxSliderLimit,
                        onChanged: (RangeValues newValues) {
                          setDialogState(() {
                            currentMin = newValues.start;
                            currentMax = newValues.end;
                            minController.text = BudgetFormatter.format(currentMin);
                            maxController.text = BudgetFormatter.format(currentMax);
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('₹ 0', style: TextStyle(color: CRMColors.textSecondaryOf(context), fontSize: 12)),
                          Text('Any', style: TextStyle(color: CRMColors.textSecondaryOf(context), fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _selectedPriceSortOrRange = (previousSelection == 'custom' && (_minPrice != null || _maxPrice != null))
                          ? 'custom'
                          : (previousSelection == 'custom' ? null : previousSelection);
                    });
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CRMColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final minVal = currentMin;
                    final maxVal = currentMax;
                    setState(() {
                      _minPrice = minVal > 0 ? minVal : null;
                      _maxPrice = (maxVal < maxSliderLimit && maxVal > 0) ? maxVal : null;
                      _selectedPriceSortOrRange = (_minPrice != null || _maxPrice != null) ? 'custom' : null;
                      _currentPage = 0;
                    });
                    _loadProperties();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildVerificationDropdown(double width) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<bool?>(
        value: _selectedVerification,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Verification',
          filled: true,
          fillColor: CRMColors.backgroundOf(context),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: CRMSpacing.m, vertical: CRMSpacing.s),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              borderSide: BorderSide.none),
        ),
        items: const [
          DropdownMenuItem<bool?>(
              value: null,
              child: Text('All Verification', overflow: TextOverflow.ellipsis)),
          DropdownMenuItem<bool?>(
              value: true,
              child: Text('Verified', overflow: TextOverflow.ellipsis)),
          DropdownMenuItem<bool?>(
              value: false,
              child: Text('Unverified', overflow: TextOverflow.ellipsis)),
        ],
        onChanged: (val) {
          setState(() {
            _selectedVerification = val;
            _currentPage = 0;
          });
          _loadProperties();
        },
      ),
    );
  }

  Widget _buildPagination(int totalItems, int totalPages, int currentPage) {
    final from = currentPage * _pageSize + 1;
    final to = ((currentPage + 1) * _pageSize).clamp(0, totalItems);
    final double screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 500;

    final infoText = Text(
      'Showing $from–$to of $totalItems',
      style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
    );

    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Rows:',
            style:
                CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context))),
        const SizedBox(width: CRMSpacing.xs),
        DropdownButton<int>(
          value: _pageSize,
          underline: const SizedBox.shrink(),
          items: _pageSizeOptions
              .map(
                  (size) => DropdownMenuItem(value: size, child: Text('$size')))
              .toList(),
          onChanged: (val) {
            if (val == null) return;
            setState(() {
              _pageSize = val;
              _currentPage = 0;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed:
              currentPage > 0 ? () => setState(() => _currentPage--) : null,
        ),
        Text(
          '${currentPage + 1} / $totalPages',
          style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context)),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: currentPage < totalPages - 1
              ? () => setState(() => _currentPage++)
              : null,
        ),
      ],
    );

    if (isMobile) {
      return Column(
        children: [
          infoText,
          const SizedBox(height: CRMSpacing.s),
          controls,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        infoText,
        controls,
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required double width,
  }) {
    final bool hasValue =
        value == null || items.any((item) => item.value == value);
    final String? safeValue = hasValue ? value : null;

    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        value: safeValue,
        isExpanded: true,
        dropdownColor: CRMColors.cardBgOf(context),
        style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
          filled: true,
          fillColor: CRMColors.backgroundOf(context),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: CRMSpacing.m, vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              borderSide: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.6))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              borderSide: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.6))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              borderSide: BorderSide(color: CRMColors.primaryOf(context), width: 1.5)),
        ),
        items: [
          DropdownMenuItem<String>(
              value: null,
              child: Text('All $label', overflow: TextOverflow.ellipsis)),
          ...items,
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionToolbar(List<PropertyModel> allProperties, List<PropertyModel> pagedProperties) {
    final int noImagesCount =
        allProperties.where((p) => p.images.isEmpty).length;
    final authState = context.read<AuthBloc>().state;
    final currentUser = authState is Authenticated ? authState.user : null;
    final role = currentUser?.role.toLowerCase() ?? '';
    final bool canExport = role == 'admin' || role == 'super admin' || role == 'telecaller';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isTableView && pagedProperties.isNotEmpty) ...[
                Theme(
                  data: ThemeData(unselectedWidgetColor: CRMColors.textSecondaryOf(context)),
                  child: Checkbox(
                    value: pagedProperties.every((p) => _selectedPropertyIds.contains(p.id)),
                    tristate: pagedProperties.any((p) => _selectedPropertyIds.contains(p.id)) &&
                        !pagedProperties.every((p) => _selectedPropertyIds.contains(p.id)),
                    activeColor: CRMColors.primaryOf(context),
                    onChanged: (bool? checked) {
                      setState(() {
                        if (checked == true) {
                          for (final p in pagedProperties) {
                            _selectedPropertyIds.add(p.id);
                          }
                        } else {
                          for (final p in pagedProperties) {
                            _selectedPropertyIds.remove(p.id);
                          }
                        }
                      });
                    },
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      final allSel = pagedProperties.every((p) => _selectedPropertyIds.contains(p.id));
                      if (!allSel) {
                        for (final p in pagedProperties) {
                          _selectedPropertyIds.add(p.id);
                        }
                      } else {
                        for (final p in pagedProperties) {
                          _selectedPropertyIds.remove(p.id);
                        }
                      }
                    });
                  },
                  child: Text(
                    'Select All (${pagedProperties.length})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: CRMColors.textOf(context),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              FilterChip(
                avatar: Icon(
                  _noImagesOnly
                      ? Icons.no_photography_rounded
                      : Icons.image_not_supported_outlined,
                  size: 16,
                  color: _noImagesOnly
                      ? Colors.white
                      : CRMColors.primaryOf(context),
                ),
                label: Text(
                  'No Photos ($noImagesCount)',
                  style: TextStyle(
                    color: _noImagesOnly
                        ? Colors.white
                        : CRMColors.textOf(context),
                    fontWeight:
                        _noImagesOnly ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
                selected: _noImagesOnly,
                selectedColor: CRMColors.primaryOf(context),
                backgroundColor:
                    CRMColors.primaryOf(context).withOpacity(0.08),
                side: BorderSide(
                  color: _noImagesOnly
                      ? CRMColors.primaryOf(context)
                      : CRMColors.borderOf(context).withOpacity(0.6),
                ),
                onSelected: (bool selected) {
                  setState(() {
                    _noImagesOnly = selected;
                  });
                },
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canExport) ...[
                ElevatedButton.icon(
                  onPressed: () => _exportPropertiesToExcel(allProperties, currentUser),
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text(
                    'Export Properties',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF217346),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 1,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: CRMColors.sidebarBgOf(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: CRMColors.borderOf(context).withOpacity(0.6),
                      width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        if (_isTableView) {
                          setState(() => _isTableView = false);
                        }
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: !_isTableView
                              ? CRMColors.cardBgOf(context)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: !_isTableView ? CRMShadows.small : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.view_stream_rounded,
                              size: 16,
                              color: !_isTableView
                                  ? CRMColors.primaryOf(context)
                                  : CRMColors.textMutedOf(context),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Cards',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: !_isTableView
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: !_isTableView
                                    ? CRMColors.primaryOf(context)
                                    : CRMColors.textMutedOf(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        if (!_isTableView) {
                          setState(() => _isTableView = true);
                        }
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isTableView
                              ? CRMColors.cardBgOf(context)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: _isTableView ? CRMShadows.small : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.table_chart_outlined,
                              size: 16,
                              color: _isTableView
                                  ? CRMColors.primaryOf(context)
                                  : CRMColors.textMutedOf(context),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Table',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _isTableView
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _isTableView
                                    ? CRMColors.primaryOf(context)
                                    : CRMColors.textMutedOf(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _exportPropertiesToExcel(List<PropertyModel> properties, UserModel? currentUser) {
    if (properties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No properties available to export.'),
          backgroundColor: CRMColors.warning,
        ),
      );
      return;
    }

    final List<String> headers = [
      'Property Code',
      'Title',
      'Category',
      'Property Type',
      'Listing Type',
      'Configuration',
      'Price / Rent (₹)',
      'Area (sq.ft)',
      'Furnishing',
      'Facing',
      'City',
      'Locality / Area',
      'Address',
      'Owner Name',
      'Owner Mobile',
      'Status',
      'Added By',
      'Created Date',
    ];

    final StringBuffer csvBuffer = StringBuffer();
    // UTF-8 BOM so Excel opens with UTF-8 encoding and auto column split
    csvBuffer.write('\uFEFF');
    csvBuffer.writeln(headers.map((h) => '"${h.replaceAll('"', '""')}"').join(','));

    for (final p in properties) {
      final areaVal = p.superBuiltupArea ?? p.carpetArea ?? p.plotArea;
      final row = [
        p.propertyCode.isNotEmpty ? p.propertyCode : p.id,
        p.title,
        p.categoryName,
        p.propertyTypeName,
        p.listingTypeName,
        p.configurationName ?? '',
        BudgetFormatter.format(p.price),
        areaVal != null && areaVal > 0 ? areaVal.toString() : '',
        p.furnishingTypeName ?? '',
        p.facingTypeName ?? '',
        p.cityName,
        p.areaName,
        p.address,
        p.ownerName,
        p.ownerMobile,
        p.propertyStatusName,
        p.createdByName.isNotEmpty ? p.createdByName : 'System',
        DateFormat('dd/MM/yyyy hh:mm a').format(p.createdAt.toLocal()),
      ];

      csvBuffer.writeln(row.map((val) => '"${val.toString().replaceAll('"', '""')}"').join(','));
    }

    final bytes = utf8.encode(csvBuffer.toString());
    final filename = 'Properties_Export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
    FileDownloader.download(bytes, filename);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${properties.length} properties exported to Excel format successfully!'),
        backgroundColor: CRMColors.success,
      ),
    );
  }

  void _showAddEditPropertyDialog(
      BuildContext context, PropertyMetadataModel metadata,
      [PropertyModel? property]) {
    final propertiesBloc = context.read<PropertiesBloc>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12.0 : 40.0,
          vertical: isMobile ? 16.0 : 24.0,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: CRMColors.cardBgOf(dialogContext),
            borderRadius: BorderRadius.circular(CRMBorderRadius.dialog),
            boxShadow: CRMShadows.modal,
          ),
          width: isMobile ? screenWidth - 24 : screenWidth * 0.95,
          height: MediaQuery.of(context).size.height * 0.95,
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 750),
          clipBehavior: Clip.antiAlias,
          child: BlocProvider.value(
            value: propertiesBloc,
            child: AddEditPropertyScreen(
              metadata: metadata,
              property: property,
              activeTab: _activeTab,
              activeListingTab: _activeListingTab,
            ),
          ),
        ),
      ),
    );
  }

  void _openPropertyDetails(BuildContext context, PropertyModel p,
      {bool forceInAppDrawer = false}) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    if (kIsWeb && !isMobile && !forceInAppDrawer) {
      final String url = '${Uri.base.origin}/properties/${p.id}';
      launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
    } else {
      showCRMPropertyDrawer(context, p);
    }
  }

  String _getBhkColumnHeader(PropertyMetadataModel? metadata) {
    if (_selectedCategory == null || metadata == null) {
      return 'BHK';
    }
    final selectedCat = metadata.categories.firstWhere(
      (c) => c.id == _selectedCategory,
      orElse: () => LookupItem(id: '', name: ''),
    );
    final name = selectedCat.name.toLowerCase();
    if (name.contains('commercial') || name.contains('industrial')) {
      return 'Super Built-up Area';
    } else if (name.contains('land') || name.contains('plot')) {
      return 'Plot Area';
    }
    return 'BHK';
  }

  bool _matchesActiveCategory(PropertyModel p) {
    final cat = p.categoryName.toLowerCase();
    if (_activeCategoryTab == 'Residential') {
      return cat.contains('resident') ||
          cat.contains('apartment') ||
          cat.contains('flat') ||
          cat.contains('villa') ||
          cat.contains('house') ||
          cat.contains('bhk') ||
          (!cat.contains('commercial') &&
              !cat.contains('industrial') &&
              !cat.contains('land') &&
              !cat.contains('plot'));
    } else if (_activeCategoryTab == 'Commercial') {
      return cat.contains('commercial') ||
          cat.contains('office') ||
          cat.contains('shop') ||
          cat.contains('showroom') ||
          cat.contains('retail');
    } else if (_activeCategoryTab == 'Industrial') {
      return cat.contains('industrial') ||
          cat.contains('factory') ||
          cat.contains('warehouse') ||
          cat.contains('shed');
    } else if (_activeCategoryTab == 'Land & Plot') {
      return cat.contains('land') || cat.contains('plot');
    }
    return false;
  }

  String _getPropertyBhkOrAreaValue(PropertyModel p) {
    final catName = p.categoryName.toLowerCase();
    if (catName.contains('commercial') || catName.contains('industrial')) {
      return p.superBuiltupArea != null && p.superBuiltupArea! > 0
          ? '${p.superBuiltupArea!.toStringAsFixed(0)} Sq.Ft'
          : 'N/A';
    } else if (catName.contains('land') || catName.contains('plot')) {
      return p.plotArea != null && p.plotArea! > 0
          ? '${p.plotArea!.toStringAsFixed(0)} Sq.Ft'
          : 'N/A';
    }
    if (p.configurationName != null && p.configurationName!.trim().isNotEmpty) {
      return p.configurationName!;
    }
    return '${p.bedrooms} BHK';
  }

  IconData _getPropertyBhkOrAreaIcon(PropertyModel p) {
    final catName = p.categoryName.toLowerCase();
    if (catName.contains('commercial') || catName.contains('industrial')) {
      return Icons.business_center_outlined;
    } else if (catName.contains('land') || catName.contains('plot')) {
      return Icons.landscape_outlined;
    }
    return Icons.king_bed_outlined;
  }

  Widget _buildPropertyThumbnail(String url) {
    return CrmNetworkImage(
      url: url,
      fit: BoxFit.cover,
      cacheLogicalWidth: 72,
      cacheLogicalHeight: 72,
    );
  }
}

class CRMChartCard extends StatefulWidget {
  final String title;
  final List<ChartSector> sectors;

  const CRMChartCard({
    Key? key,
    required this.title,
    required this.sectors,
  }) : super(key: key);

  @override
  State<CRMChartCard> createState() => _CRMChartCardState();
}

class _CRMChartCardState extends State<CRMChartCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sweepAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _sweepAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant CRMChartCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only re-animate when title changes or sector data actually changes
    bool sectorsChanged = oldWidget.title != widget.title ||
        oldWidget.sectors.length != widget.sectors.length;
    if (!sectorsChanged) {
      for (int i = 0; i < oldWidget.sectors.length; i++) {
        if (oldWidget.sectors[i].label != widget.sectors[i].label ||
            oldWidget.sectors[i].value != widget.sectors[i].value) {
          sectorsChanged = true;
          break;
        }
      }
    }
    if (sectorsChanged) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = CRMColors.cardBgOf(context);
    final titleColor = CRMColors.textOf(context);
    final subtitleColor = CRMColors.textSecondaryOf(context);

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    final sectorsToShow = widget.sectors.isNotEmpty
        ? widget.sectors
        : [ChartSector(label: 'No Listings', value: 1.0, color: CRMColors.textMutedOf(context))];

    final total = sectorsToShow.fold<double>(0, (s, e) => s + e.value);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(CRMBorderRadius.card),
        border: Border.all(
          color: CRMColors.borderOf(context),
          width: 1,
        ),
      ),
      padding: EdgeInsets.all(isMobile ? CRMSpacing.s : CRMSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 3,
                height: 12,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      CRMColors.primaryOf(context),
                      CRMColors.primaryOf(context).withOpacity(0.4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Row(
                  children: [
                    // 3D Donut Chart
                    SizedBox(
                      width: isMobile ? 56 : 72,
                      height: isMobile ? 56 : 72,
                      child: CustomPaint(
                        painter: DonutChart3DPainter(
                          sectors: sectorsToShow,
                          backgroundColor: bgColor,
                          animationValue: _sweepAnimation.value,
                          isDark: isDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Animated legend
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(sectorsToShow.length, (i) {
                            final s = sectorsToShow[i];
                            final pct = total > 0 ? s.value / total : 0.0;
                            // Stagger each legend item
                            final itemDelay = 0.4 + (i * 0.08);
                            final itemEnd = (itemDelay + 0.3).clamp(0.0, 1.0);
                            final itemProgress = Curves.easeOut.transform(
                              (((_controller.value - itemDelay) / (itemEnd - itemDelay))
                                  .clamp(0.0, 1.0)),
                            );

                            return Opacity(
                              opacity: itemProgress,
                              child: Transform.translate(
                                offset: Offset(8 * (1 - itemProgress), 0),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 1.5),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: s.color,
                                          borderRadius: BorderRadius.circular(2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: s.color.withOpacity(0.4),
                                              blurRadius: 3,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              s.label == 'No Listings'
                                                  ? 'No Listings'
                                                  : '${s.label}: ${s.value.toInt()}',
                                              style: TextStyle(
                                                fontSize: isMobile ? 9 : 10,
                                                color: titleColor.withOpacity(0.85),
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            // Animated progress bar
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(2),
                                              child: SizedBox(
                                                height: 3,
                                                child: Stack(
                                                  children: [
                                                    Container(
                                                      color: subtitleColor.withOpacity(0.1),
                                                    ),
                                                    FractionallySizedBox(
                                                      widthFactor: pct * _sweepAnimation.value,
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          gradient: LinearGradient(
                                                            colors: [
                                                              s.color,
                                                              s.color.withOpacity(0.6),
                                                            ],
                                                          ),
                                                          borderRadius: BorderRadius.circular(2),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class KPICardData {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String chartTitle;
  final List<ChartSector> sectors;

  KPICardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.chartTitle,
    required this.sectors,
  });
}

class ChartSector {
  final String label;
  final double value;
  final Color color;

  ChartSector({
    required this.label,
    required this.value,
    required this.color,
  });
}

class DonutChart3DPainter extends CustomPainter {
  final List<ChartSector> sectors;
  final Color backgroundColor;
  final double animationValue;
  final bool isDark;

  DonutChart3DPainter({
    required this.sectors,
    required this.backgroundColor,
    required this.animationValue,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double total = sectors.fold(0, (sum, s) => sum + s.value);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width < size.height ? size.width / 2 : size.height / 2) - 2;
    final strokeWidth = radius * 0.38;
    final outerRadius = radius;
    final innerRadius = radius - strokeWidth;

    // --- 3D Shadow / Depth layers ---
    for (int i = 3; i >= 1; i--) {
      final shadowPaint = Paint()
        ..color = (isDark ? Colors.black : CRMColors.sand).withValues(alpha: 0.18)
            .withOpacity(0.06 * i)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + (i * 1.5)
        ..isAntiAlias = true;
      final shadowOffset = Offset(0, i * 0.8);
      canvas.drawCircle(center + shadowOffset, outerRadius - strokeWidth / 2, shadowPaint);
    }

    // --- Draw animated sectors as thick arcs with gradient ---
    final animatedSweepTotal = 2 * math.pi * animationValue;
    double startAngle = -math.pi / 2;

    for (final sector in sectors) {
      final sweepAngle = (sector.value / total) * animatedSweepTotal;
      final midAngle = startAngle + sweepAngle / 2;

      // Gradient arc paint
      final arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt
        ..isAntiAlias = true;

      // Create a sweep gradient for the sector for a richer look
      final darkerColor = Color.lerp(sector.color, Colors.black, 0.25)!;
      final lighterColor = Color.lerp(sector.color, Colors.white, 0.2)!;
      arcPaint.shader = ui.Gradient.sweep(
        center,
        [lighterColor, sector.color, darkerColor, sector.color],
        [0.0, 0.3, 0.7, 1.0],
        TileMode.clamp,
        startAngle,
        startAngle + sweepAngle,
      );

      final arcRect = Rect.fromCircle(center: center, radius: outerRadius - strokeWidth / 2);
      canvas.drawArc(arcRect, startAngle, sweepAngle, false, arcPaint);

      // Draw percentage text for large sectors
      if (sweepAngle > 0.4 && animationValue > 0.5) {
        final textOpacity = ((animationValue - 0.5) * 2).clamp(0.0, 1.0);
        final textRadius = outerRadius - strokeWidth / 2;
        final textX = center.dx + textRadius * math.cos(midAngle);
        final textY = center.dy + textRadius * math.sin(midAngle);
        final percentage = (sector.value / total * 100).toStringAsFixed(0);

        final textPainter = TextPainter(
          text: TextSpan(
            text: '$percentage%',
            style: TextStyle(
              color: Colors.white.withOpacity(textOpacity),
              fontSize: (strokeWidth * 0.38).clamp(7.0, 11.0),
              fontWeight: FontWeight.w800,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(textX - textPainter.width / 2, textY - textPainter.height / 2),
        );
      }

      startAngle += sweepAngle;
    }

    // --- Inner circle (center hole) with subtle gradient for depth ---
    final innerGradient = ui.Gradient.radial(
      Offset(center.dx - innerRadius * 0.2, center.dy - innerRadius * 0.2),
      innerRadius,
      isDark
          ? [CRMColors.surfaceElevated, CRMColors.background]
          : [CRMColors.cardBg, CRMColors.groupedBackground],
      [0.0, 1.0],
    );
    final innerPaint = Paint()
      ..shader = innerGradient
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(center, innerRadius - 1, innerPaint);

    // Subtle inner ring border
    final innerRingPaint = Paint()
      ..color = (isDark ? Colors.white : CRMColors.sand).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..isAntiAlias = true;
    canvas.drawCircle(center, innerRadius - 1, innerRingPaint);

    // --- Glossy highlight overlay on top half ---
    final highlightRect = Rect.fromCircle(center: center, radius: outerRadius - strokeWidth / 2);
    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.4
      ..isAntiAlias = true
      ..shader = ui.Gradient.linear(
        Offset(center.dx, center.dy - outerRadius),
        center,
        [
          Colors.white.withOpacity(isDark ? 0.08 : 0.18),
          Colors.white.withOpacity(0.0),
        ],
      );
    canvas.drawArc(highlightRect, -math.pi, math.pi, false, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant DonutChart3DPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.sectors != sectors ||
        oldDelegate.isDark != isDark;
  }
}

class HoverChartTooltip extends StatefulWidget {
  final Widget child;
  final String title;
  final List<ChartSector> sectors;

  const HoverChartTooltip({
    Key? key,
    required this.child,
    required this.title,
    required this.sectors,
  }) : super(key: key);

  @override
  State<HoverChartTooltip> createState() => _HoverChartTooltipState();
}

class _HoverChartTooltipState extends State<HoverChartTooltip> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isHovered = false;

  void _showOverlay() {
    if (widget.sectors.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isHovered || _overlayEntry != null) return;
      _overlayEntry = OverlayEntry(
        builder: (context) {
          final bgColor = CRMColors.surfaceElevatedOf(context);
          final borderColor = CRMColors.borderOf(context);
          final titleColor = CRMColors.textOf(context);

          return Positioned(
            width: 320,
            height: 180,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, -190), // Show above the card
              child: MouseRegion(
                onEnter: (_) {
                  _isHovered = true;
                },
                onExit: (_) {
                  _isHovered = false;
                  _hideOverlay();
                },
                child: Material(
                  elevation: 12,
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  shadowColor: Colors.black.withOpacity(0.15),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Row(
                            children: [
                              SizedBox(
                                width: 110,
                                height: 110,
                                child: CustomPaint(
                                  painter: DonutChart3DPainter(
                                    sectors: widget.sectors,
                                    backgroundColor: bgColor,
                                    animationValue: 1.0,
                                    isDark: Theme.of(context).brightness == Brightness.dark,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: widget.sectors.map((s) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: s.color,
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '${s.label}: ${s.value.toInt()}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: titleColor.withOpacity(0.8),
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
      Overlay.of(context).insert(_overlayEntry!);
    });
  }

  void _hideOverlay() {
    // Wait briefly to make sure user didn't enter the overlay region
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      if (!_isHovered) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _overlayEntry?.remove();
          _overlayEntry = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) {
          _isHovered = true;
          _showOverlay();
        },
        onExit: (_) {
          _isHovered = false;
          _hideOverlay();
        },
        child: widget.child,
      ),
    );
  }
}

class _MobilePropertyImageCarousel extends StatefulWidget {
  final List<String> images;
  final VoidCallback onTap;
  final double? height;

  const _MobilePropertyImageCarousel({
    Key? key,
    required this.images,
    required this.onTap,
    this.height,
  }) : super(key: key);

  @override
  State<_MobilePropertyImageCarousel> createState() => _MobilePropertyImageCarouselState();
}

class _MobilePropertyImageCarouselState extends State<_MobilePropertyImageCarousel> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  void _startTimer() {
    // Auto-sliding disabled per user request
    _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildPropertyThumbnail(String url) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: CrmNetworkImage(
          url: url,
          fit: BoxFit.contain,
          cacheLogicalWidth: 600,
          cacheLogicalHeight: 450,
          error: (context) => Container(
            color: CRMColors.backgroundOf(context),
            child: const Icon(Icons.broken_image_outlined, size: 24, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return const SizedBox.shrink();

    return Stack(
      alignment: Alignment.center,
      children: [
        // PageView
        GestureDetector(
          onTap: widget.onTap,
          child: Container(
            height: widget.height ?? 300,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(CRMBorderRadius.card),
            ),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemCount: widget.images.length,
              itemBuilder: (context, index) {
                return _buildPropertyThumbnail(widget.images[index]);
              },
            ),
          ),
        ),
        // Navigation Buttons (only if there are multiple images)
        if (widget.images.length > 1) ...[
          // Left Arrow
          Positioned(
            left: 8,
            child: Material(
              color: Colors.black.withOpacity(0.4),
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () {
                  // Reset timer on manual action
                  _startTimer();
                  if (_pageController.hasClients) {
                    final prevPage = (_currentPage - 1 + widget.images.length) % widget.images.length;
                    _pageController.animateToPage(
                      prevPage,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
            ),
          ),
          // Right Arrow
          Positioned(
            right: 8,
            child: Material(
              color: Colors.black.withOpacity(0.4),
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () {
                  // Reset timer on manual action
                  _startTimer();
                  if (_pageController.hasClients) {
                    final nextPage = (_currentPage + 1) % widget.images.length;
                    _pageController.animateToPage(
                      nextPage,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
            ),
          ),
        ],
        // Indicator text (always shown)
        Positioned(
          bottom: 8,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_currentPage + 1}/${widget.images.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileStatisticsSection extends StatefulWidget {
  final Widget kpiCard;
  final String chartTitle;
  final List<ChartSector> sectors;

  const _MobileStatisticsSection({
    Key? key,
    required this.kpiCard,
    required this.chartTitle,
    required this.sectors,
  }) : super(key: key);

  @override
  State<_MobileStatisticsSection> createState() => _MobileStatisticsSectionState();
}

class _MobileStatisticsSectionState extends State<_MobileStatisticsSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double cardWidth = (screenWidth - (CRMSpacing.m * 2) - CRMSpacing.m).clamp(0.0, double.infinity) / 2;
    final double cardHeight = 105.0;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = CRMColors.cardBgOf(context);

    final sectorsToShow = widget.sectors.isNotEmpty
        ? widget.sectors
        : [ChartSector(label: 'No Listings', value: 1.0, color: Colors.grey.shade400)];

    final total = sectorsToShow.fold<double>(0, (s, e) => s + e.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: widget.kpiCard,
            ),
            const SizedBox(width: CRMSpacing.m),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Container(
                width: cardWidth,
                height: cardHeight,
                decoration: BoxDecoration(
                  color: CRMColors.cardBgOf(context),
                  borderRadius: BorderRadius.circular(CRMBorderRadius.card),
                  border: Border.all(
                    color: CRMColors.borderOf(context),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.s, vertical: CRMSpacing.xs),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: CustomPaint(
                        painter: DonutChart3DPainter(
                          sectors: sectorsToShow,
                          backgroundColor: bgColor,
                          animationValue: 1.0,
                          isDark: isDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.chartTitle,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: CRMColors.textOf(context),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          size: 14,
                          color: CRMColors.primaryOf(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isExpanded
              ? Container(
                  margin: const EdgeInsets.only(top: CRMSpacing.m),
                  padding: const EdgeInsets.all(CRMSpacing.m),
                  decoration: BoxDecoration(
                    color: CRMColors.cardBgOf(context),
                    borderRadius: BorderRadius.circular(CRMBorderRadius.card),
                    border: Border.all(
                      color: CRMColors.borderOf(context),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.chartTitle} Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: CRMSpacing.s),
                      Column(
                        children: List.generate(sectorsToShow.length, (i) {
                          final s = sectorsToShow[i];
                          final pct = total > 0 ? s.value / total : 0.0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: CRMSpacing.xs),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: s.color,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            s.label,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            '${s.value.toInt()}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(2),
                                        child: SizedBox(
                                          height: 3,
                                          child: LinearProgressIndicator(
                                            value: pct,
                                            backgroundColor: (isDark ? Colors.white10 : Colors.black12),
                                            valueColor: AlwaysStoppedAnimation<Color>(s.color),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class PropertyDealClientStore {
  static const String _prefix = 'deal_client_name_';
  static const String _reqPrefix = 'won_req_properties_';
  static final Map<String, String> _memoryCache = {};
  static final Map<String, List<String>> _reqMemoryCache = {};

  static Future<void> setClientName(String propertyId, String clientName) async {
    _memoryCache[propertyId] = clientName;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefix$propertyId', clientName);
    } catch (_) {}
  }

  static Future<void> setWonRequirementProperties(String requirementId, List<String> propertyIds) async {
    _reqMemoryCache[requirementId] = propertyIds;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('$_reqPrefix$requirementId', propertyIds);
    } catch (_) {}
  }

  static Future<List<String>> getWonPropertyIds(String requirementId) async {
    if (_reqMemoryCache.containsKey(requirementId)) {
      return _reqMemoryCache[requirementId]!;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('$_reqPrefix$requirementId');
      if (list != null) {
        _reqMemoryCache[requirementId] = list;
        return list;
      }
    } catch (_) {}
    return [];
  }

  static String? getMemoryClientName(String propertyId) {
    return _memoryCache[propertyId];
  }

  static Future<String?> getClientName(String propertyId, {PropertyModel? property}) async {
    if (_memoryCache.containsKey(propertyId)) {
      return _memoryCache[propertyId];
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('$_prefix$propertyId');
      if (savedName != null && savedName.isNotEmpty) {
        _memoryCache[propertyId] = savedName;
        return savedName;
      }
    } catch (_) {}
    return null;
  }

  static Future<void> removeClientName(String propertyId) async {
    _memoryCache.remove(propertyId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefix$propertyId');
    } catch (_) {}
  }

  static Future<void> removeWonRequirementProperties(String requirementId) async {
    _reqMemoryCache.remove(requirementId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_reqPrefix$requirementId');
    } catch (_) {}
  }
}
