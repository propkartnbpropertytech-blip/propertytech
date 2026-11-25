import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/design_system/mobile/mobile_screen.dart';
import '../../../core/design_system/tokens/app_breakpoints.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../models/document_model.dart';
import '../widgets/library_hub/library_hub_tokens.dart';
import '../widgets/library_hub/library_hub_widgets.dart';

/// New_UI Library hub (library.html). Vault navigation + Upload / Request
/// wire into existing vault screens and WhatsApp — no dead buttons.
class LibraryMainScreen extends StatefulWidget {
  const LibraryMainScreen({super.key});

  @override
  State<LibraryMainScreen> createState() => _LibraryMainScreenState();
}

class _LibraryMainScreenState extends State<LibraryMainScreen> {
  late final List<RentalDocument> _rentalDocs;
  late final List<ResaleDocument> _resaleDocs;
  late final List<ServiceAgentDocument> _serviceDocs;

  @override
  void initState() {
    super.initState();
    _rentalDocs = RentalDocument.getMockData();
    _resaleDocs = ResaleDocument.getMockData();
    _serviceDocs = ServiceAgentDocument.getMockData();
  }

  int _countRental(List<String> types) =>
      _rentalDocs.where((d) => types.any((t) => d.documentType.toLowerCase().contains(t.toLowerCase()))).length;

  int _countResale(List<String> types) =>
      _resaleDocs.where((d) => types.any((t) => d.documentType.toLowerCase().contains(t.toLowerCase()))).length;

  int _countService(List<String> types) =>
      _serviceDocs.where((d) => types.any((t) => d.documentType.toLowerCase().contains(t.toLowerCase()))).length;

  void _openVault(String path, {bool upload = false, String? clientName}) {
    if (upload && path != '/service-agent-library') {
      context.go(
        path,
        extra: <String, dynamic>{
          'autoOpenUpload': true,
          if (clientName != null && clientName.trim().isNotEmpty) 'clientName': clientName.trim(),
        },
      );
      return;
    }
    context.go(path);
  }

  Future<void> _showUploadDialog() async {
    String vault = 'rental';
    final propertyCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text('Upload document'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Vault', style: CRMTypography.caption.copyWith(color: LibTokens.muted(ctx))),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: vault,
                      items: const [
                        DropdownMenuItem(value: 'rental', child: Text('Rental')),
                        DropdownMenuItem(value: 'resale', child: Text('Re-sale')),
                        DropdownMenuItem(value: 'service', child: Text('Service agents')),
                      ],
                      onChanged: (v) => setLocal(() => vault = v ?? 'rental'),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    Text('Property or person', style: CRMTypography.caption.copyWith(color: LibTokens.muted(ctx))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: propertyCtrl,
                      decoration: const InputDecoration(
                        hintText: 'e.g. PR-1261 or Harsh Singh',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Opens the selected vault upload dialog so the file is saved with the existing library flow.',
                      style: CRMTypography.caption.copyWith(color: LibTokens.muted(ctx)),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(backgroundColor: LibTokens.green),
                  child: const Text('Upload'),
                ),
              ],
            );
          },
        );
      },
    );

    final name = propertyCtrl.text;
    propertyCtrl.dispose();
    if (ok != true || !mounted) return;

    switch (vault) {
      case 'resale':
        _openVault('/resale-library', upload: true, clientName: name);
        break;
      case 'service':
        _openVault('/service-agent-library');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Service vault opened — use Add agent to upload.')),
          );
        }
        break;
      default:
        _openVault('/rental-library', upload: true, clientName: name);
    }
  }

  Future<void> _showRequestDocumentsDialog() async {
    final phoneCtrl = TextEditingController();
    String need = 'Tenant ID proof + rent agreement';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text('Request documents'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'We’ll open WhatsApp with a checklist for the client.',
                      style: CRMTypography.caption.copyWith(color: LibTokens.muted(ctx)),
                    ),
                    const SizedBox(height: 14),
                    Text('Client mobile', style: CRMTypography.caption.copyWith(color: LibTokens.muted(ctx))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: '+91 98250 12345',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('What do you need?', style: CRMTypography.caption.copyWith(color: LibTokens.muted(ctx))),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: need,
                      items: const [
                        DropdownMenuItem(
                          value: 'Tenant ID proof + rent agreement',
                          child: Text('Tenant ID proof + rent agreement'),
                        ),
                        DropdownMenuItem(
                          value: 'Owner ID proof + property papers',
                          child: Text('Owner ID proof + property papers'),
                        ),
                        DropdownMenuItem(
                          value: 'Vendor Aadhaar + GST',
                          child: Text('Vendor Aadhaar + GST'),
                        ),
                      ],
                      onChanged: (v) => setLocal(() => need = v ?? need),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(backgroundColor: LibTokens.green),
                  child: const Text('Send on WhatsApp'),
                ),
              ],
            );
          },
        );
      },
    );

    final rawPhone = phoneCtrl.text;
    phoneCtrl.dispose();
    if (ok != true || !mounted) return;

    final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid mobile number')),
      );
      return;
    }
    final phone = digits.length == 10 ? '91$digits' : digits;
    final text = Uri.encodeComponent(
      'Hi, PropKart here. Please share these documents: $need. Thank you!',
    );
    final uri = Uri.parse('https://wa.me/$phone?text=$text');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    }
  }

  Future<void> _openFolderDialog({
    required String vaultTitle,
    required String folderLabel,
    required String route,
    required List<String> previewNames,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(folderLabel),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '$vaultTitle vault · open to manage files',
                  style: CRMTypography.caption.copyWith(color: LibTokens.muted(ctx)),
                ),
                const SizedBox(height: 12),
                if (previewNames.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No files yet — upload the first one in the vault.',
                      textAlign: TextAlign.center,
                      style: CRMTypography.body.copyWith(color: LibTokens.muted(ctx)),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: previewNames.length.clamp(0, 8),
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.description_outlined, size: 20),
                          title: Text(previewNames[i], maxLines: 1, overflow: TextOverflow.ellipsis),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _openVault(route, upload: true);
              },
              style: FilledButton.styleFrom(backgroundColor: LibTokens.green),
              child: const Text('Upload to this folder'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _openVault(route);
              },
              child: Text(
                'Open vault →',
                style: TextStyle(color: LibTokens.green, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, {required bool isPhone}) {
    final rentalFolders = [
      LibVaultFolder(label: 'Rental & lease agreements', count: _countRental(['agreement', 'lease'])),
      LibVaultFolder(label: 'Tenant & owner ID proofs', count: _countRental(['id proof', 'aadhaar', 'aadhar'])),
      LibVaultFolder(label: 'Rent & deposit receipts', count: _countRental(['receipt', 'deposit'])),
      LibVaultFolder(label: 'Utility bills', count: _countRental(['bill', 'electricity', 'water', 'maintenance'])),
      LibVaultFolder(label: 'Inspection photos & videos', count: _countRental(['photo', 'video', 'walkthrough'])),
    ];
    final resaleFolders = [
      LibVaultFolder(label: 'Sale deeds & agreements', count: _countResale(['deed', 'agreement'])),
      LibVaultFolder(label: 'Property legal documents', count: _countResale(['legal', 'title', 'document'])),
      LibVaultFolder(label: 'Society NOCs & floor plans', count: _countResale(['noc', 'floor'])),
      LibVaultFolder(label: 'Tax & municipal receipts', count: _countResale(['tax', 'municipal', 'receipt'])),
      LibVaultFolder(label: 'Home loan sanctions', count: _countResale(['loan', 'sanction'])),
    ];
    final serviceFolders = [
      LibVaultFolder(label: 'Aadhaar / ID proofs', count: _countService(['aadhaar', 'aadhar', 'id'])),
      LibVaultFolder(label: 'GST registration certificates', count: _countService(['gst'])),
      LibVaultFolder(label: 'Service agreements (SLAs)', count: _countService(['agreement', 'sla'])),
      LibVaultFolder(label: 'Price catalogs & quotations', count: _countService(['catalog', 'quotation', 'quote'])),
      LibVaultFolder(label: 'Invoices & completed work', count: _countService(['invoice', 'work'])),
    ];

    List<String> rentalPreview(int folderIndex) {
      final types = [
        ['agreement', 'lease'],
        ['id proof', 'aadhaar', 'aadhar'],
        ['receipt', 'deposit'],
        ['bill', 'electricity', 'water', 'maintenance'],
        ['photo', 'video', 'walkthrough'],
      ][folderIndex];
      return _rentalDocs
          .where((d) => types.any((t) => d.documentType.toLowerCase().contains(t)))
          .map((d) => d.name)
          .toList();
    }

    List<String> resalePreview(int folderIndex) {
      final types = [
        ['deed', 'agreement'],
        ['legal', 'title', 'document'],
        ['noc', 'floor'],
        ['tax', 'municipal', 'receipt'],
        ['loan', 'sanction'],
      ][folderIndex];
      return _resaleDocs
          .where((d) => types.any((t) => d.documentType.toLowerCase().contains(t)))
          .map((d) => d.name)
          .toList();
    }

    List<String> servicePreview(int folderIndex) {
      final types = [
        ['aadhaar', 'aadhar', 'id'],
        ['gst'],
        ['agreement', 'sla'],
        ['catalog', 'quotation', 'quote'],
        ['invoice', 'work'],
      ][folderIndex];
      return _serviceDocs
          .where((d) => types.any((t) => d.documentType.toLowerCase().contains(t)))
          .map((d) => d.documentName.isNotEmpty ? d.documentName : d.agentName)
          .toList();
    }

    final header = isPhone
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Library',
                style: CRMTypography.pageTitle.copyWith(color: LibTokens.ink(context)),
              ),
              const SizedBox(height: 4),
              Text(
                'Agreements, ID proofs and receipts for every deal.',
                style: CRMTypography.body.copyWith(color: LibTokens.muted(context)),
              ),
              const SizedBox(height: 12),
              LibHeaderActions(
                onRequest: _showRequestDocumentsDialog,
                onUpload: _showUploadDialog,
              ),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Library',
                      style: CRMTypography.pageTitle.copyWith(color: LibTokens.ink(context)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Agreements, ID proofs and receipts for every deal.',
                      style: CRMTypography.body.copyWith(color: LibTokens.muted(context)),
                    ),
                  ],
                ),
              ),
              LibHeaderActions(
                onRequest: _showRequestDocumentsDialog,
                onUpload: _showUploadDialog,
              ),
            ],
          );

    final cards = [
      LibVaultCard(
        icon: Icons.home_rounded,
        title: 'Rental',
        subtitle: 'Leases, tenant IDs, rent receipts',
        footerLabel: '${_rentalDocs.length} rental documents',
        folders: rentalFolders,
        onOpenVault: () => _openVault('/rental-library'),
        onFolderTap: (i) => _openFolderDialog(
          vaultTitle: 'Rental',
          folderLabel: rentalFolders[i].label,
          route: '/rental-library',
          previewNames: rentalPreview(i),
        ),
      ),
      LibVaultCard(
        icon: Icons.vpn_key_rounded,
        title: 'Re-sale',
        subtitle: 'Sale deeds, NOCs, loan papers',
        footerLabel: '${_resaleDocs.length} re-sale documents',
        folders: resaleFolders,
        onOpenVault: () => _openVault('/resale-library'),
        onFolderTap: (i) => _openFolderDialog(
          vaultTitle: 'Re-sale',
          folderLabel: resaleFolders[i].label,
          route: '/resale-library',
          previewNames: resalePreview(i),
        ),
      ),
      LibVaultCard(
        icon: Icons.handyman_rounded,
        title: 'Service agents',
        subtitle: 'Vendor IDs, GST, invoices',
        footerLabel: '${_serviceDocs.length} service documents',
        folders: serviceFolders,
        onOpenVault: () => _openVault('/service-agent-library'),
        onFolderTap: (i) => _openFolderDialog(
          vaultTitle: 'Service agents',
          folderLabel: serviceFolders[i].label,
          route: '/service-agent-library',
          previewNames: servicePreview(i),
        ),
      ),
    ];

    final width = CRMBreakpoints.widthOf(context);
    final columns = width >= 1100 ? 3 : (width >= 720 ? 2 : 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final gap = 12.0;
            final cardW = columns == 1
                ? constraints.maxWidth
                : (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: cards
                  .map((c) => SizedBox(width: cardW, child: c))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = CRMBreakpoints.isPhone(context);

    if (isPhone) {
      return MobileScreenScaffold(
        title: 'Library',
        padding: EdgeInsets.all(CRMBreakpoints.pagePadding(context)),
        body: _buildBody(context, isPhone: true),
      );
    }

    return Scaffold(
      backgroundColor: LibTokens.pageBg(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(CRMBreakpoints.pagePadding(context)),
          child: _buildBody(context, isPhone: false),
        ),
      ),
    );
  }
}
