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
