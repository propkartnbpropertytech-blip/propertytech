import 'package:flutter/material.dart';
import '../../../../core/design_system/tokens/app_typography.dart';
import 'library_hub_tokens.dart';

class LibVaultFolder {
  final String label;
  final int count;
  const LibVaultFolder({required this.label, required this.count});
}

class LibVaultCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String footerLabel;
  final List<LibVaultFolder> folders;
  final VoidCallback onOpenVault;
  final ValueChanged<int>? onFolderTap;

  const LibVaultCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.footerLabel,
    required this.folders,
    required this.onOpenVault,
    this.onFolderTap,
  });

  @override
  State<LibVaultCard> createState() => _LibVaultCardState();
}

class _LibVaultCardState extends State<LibVaultCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final line = LibTokens.line(context);
    final green = LibTokens.greenTextOf(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: LibTokens.panelBg(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hover ? LibTokens.green2 : line,
          ),
          boxShadow: _hover
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: widget.onOpenVault,
              borderRadius: BorderRadius.circular(10),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: LibTokens.greenBgOf(context),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(widget.icon, color: green, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: CRMTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: LibTokens.ink(context),
                          ),
                        ),
                        Text(
                          widget.subtitle,
                          style: CRMTypography.caption.copyWith(
                            fontSize: 12,
                            color: LibTokens.muted(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: _hover ? green : LibTokens.muted(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ...List.generate(widget.folders.length, (i) {
              final f = widget.folders[i];
              final empty = f.count <= 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: InkWell(
                  onTap: () {
                    if (widget.onFolderTap != null) {
                      widget.onFolderTap!(i);
                    } else {
                      widget.onOpenVault();
                    }
                  },
                  borderRadius: BorderRadius.circular(9),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.folder_outlined, size: 16, color: LibTokens.muted(context)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            f.label,
                            style: CRMTypography.body.copyWith(
                              fontSize: 13,
                              color: LibTokens.ink(context),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                          decoration: BoxDecoration(
                            color: empty ? LibTokens.amberBg : LibTokens.soft(context),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            empty ? 'Empty' : '${f.count}',
                            style: CRMTypography.caption.copyWith(
                              fontSize: 11.5,
                              color: empty ? LibTokens.amber : LibTokens.muted(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.chevron_right_rounded, size: 16, color: LibTokens.muted(context)),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.footerLabel,
                    style: CRMTypography.caption.copyWith(
                      fontSize: 12,
                      color: LibTokens.muted(context),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: widget.onOpenVault,
                  style: TextButton.styleFrom(
                    foregroundColor: green,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Open vault →',
                    style: CRMTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: green,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LibHeaderActions extends StatelessWidget {
  final VoidCallback onRequest;
  final VoidCallback onUpload;

  const LibHeaderActions({
    super.key,
    required this.onRequest,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        OutlinedButton(
          onPressed: onRequest,
          style: OutlinedButton.styleFrom(
            foregroundColor: LibTokens.ink(context),
            side: BorderSide(color: LibTokens.line(context)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Request documents'),
        ),
        FilledButton.icon(
          onPressed: onUpload,
          style: FilledButton.styleFrom(
            backgroundColor: LibTokens.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.upload_rounded, size: 18),
          label: const Text('Upload'),
        ),
      ],
    );
  }
}

/// Dashed dropzone matching library.html `.xd`.
class LibDropzoneHint extends StatefulWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const LibDropzoneHint({
    super.key,
    this.title = 'Drop a PDF, photo or video here',
    this.subtitle = 'or click to choose · max 25 MB',
    this.onTap,
  });

  @override
  State<LibDropzoneHint> createState() => _LibDropzoneHintState();
}

class _LibDropzoneHintState extends State<LibDropzoneHint> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final green = LibTokens.greenTextOf(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _hover ? LibTokens.green2 : LibTokens.line(context),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(10),
            child: Column(
              children: [
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: CRMTypography.body.copyWith(
                    fontSize: 12.5,
                    color: _hover ? green : LibTokens.muted(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: CRMTypography.caption.copyWith(
                    fontSize: 11.5,
                    color: LibTokens.muted(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Emerald-styled dialog shell for hub Upload / Request / Folder flows.
Future<bool?> showLibDialog({
  required BuildContext context,
  required String title,
  String? subtitle,
  required Widget body,
  required String okLabel,
  String cancelLabel = 'Cancel',
  IconData icon = Icons.upload_rounded,
  bool danger = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) {
      return Dialog(
        backgroundColor: LibTokens.panelBg(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: LibTokens.greenBgOf(ctx),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(icon, color: LibTokens.greenTextOf(ctx), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: CRMTypography.sectionTitle.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: LibTokens.ink(ctx),
                            ),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle,
                              style: CRMTypography.caption.copyWith(
                                fontSize: 12.5,
                                color: LibTokens.muted(ctx),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(child: SingleChildScrollView(child: body)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(cancelLabel),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: danger ? const Color(0xFFDC2626) : LibTokens.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(okLabel),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
