import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../ai_search_suggestions.dart';
import '../services/ai_search_service.dart';
import 'ai_search_panel.dart';

/// The signed-in user's complete search history. The server only ever returns the caller's own rows.
class AiSearchHistorySheet extends StatefulWidget {
  final AiSearchService service;
  final ValueChanged<String> onSelect;

  const AiSearchHistorySheet({super.key, required this.service, required this.onSelect});

  static Future<void> show(BuildContext context, {required AiSearchService service, required ValueChanged<String> onSelect}) {
    final width = MediaQuery.of(context).size.width;
    final sheet = AiSearchHistorySheet(service: service, onSelect: onSelect);
    if (width < 600) {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: CRMColors.cardBgOf(context),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (_) => FractionallySizedBox(heightFactor: 0.85, child: sheet),
      );
    }
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: CRMColors.cardBgOf(context),
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.m)),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640), child: sheet),
      ),
    );
  }

  @override
  State<AiSearchHistorySheet> createState() => _AiSearchHistorySheetState();
}

class _AiSearchHistorySheetState extends State<AiSearchHistorySheet> {
  final TextEditingController _filter = TextEditingController();
  final List<AiRecentSearch> _items = [];
  Timer? _debounce;
  int _page = 0;
  int _totalPages = 1;
  int _total = 0;
  bool _loading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _filter.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    if (!reset && _page >= _totalPages) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    final next = reset ? 1 : _page + 1;
    final result = await widget.service.history(page: next, limit: 20, filter: _filter.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result == null) {
        _failed = true;
        return;
      }
      if (reset) _items.clear();
      _items.addAll(result.items);
      _page = result.page;
      _totalPages = result.totalPages;
      _total = result.total;
    });
  }

  Future<void> _remove(AiRecentSearch item) async {
    final index = _items.indexOf(item);
    setState(() {
      _items.remove(item);
      _total = (_total - 1).clamp(0, 1 << 30);
    });
    final ok = await widget.service.removeHistory(item.id);
    if (!ok && mounted) {
      setState(() {
        _items.insert(index.clamp(0, _items.length), item);
        _total += 1;
      });
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(content: Text('Could not remove this search. Try again.')));
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear search history?'),
        content: const Text('This removes every search you made. Other people are not affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear all')),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await widget.service.clearHistory();
    if (!mounted) return;
    if (ok) {
      setState(() {
        _items.clear();
        _total = 0;
        _page = 1;
        _totalPages = 1;
      });
    } else {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(content: Text('Could not clear your history. Try again.')));
    }
  }

  String _when(DateTime? at) {
    if (at == null) return '';
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) return '${diff.inHours} h ago';
    if (diff.inDays < 7) return '${diff.inDays} d ago';
    return '${at.day.toString().padLeft(2, '0')}/${at.month.toString().padLeft(2, '0')}/${at.year}';
  }

  @override
  Widget build(BuildContext context) {
    final secondary = CRMColors.textSecondaryOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(CRMSpacing.m, CRMSpacing.m, CRMSpacing.m, CRMSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ShaderMask(
                shaderCallback: (rect) => AiSearchTheme.gradient(context).createShader(rect),
                child: const Icon(Icons.manage_history_rounded, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your search history',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: CRMColors.textOf(context)),
                ),
              ),
              if (_items.isNotEmpty)
                TextButton.icon(
                  key: const ValueKey('ai-history-clear'),
                  onPressed: _clearAll,
                  icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                  label: const Text('Clear all'),
                ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          Text('Only you can see these. $_total saved.', style: TextStyle(fontSize: 12, color: secondary)),
          const SizedBox(height: 10),
          TextField(
            controller: _filter,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Filter your searches',
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.input)),
            ),
            onChanged: (_) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 300), () => _load(reset: true));
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 80) _load();
                return false;
              },
              child: _items.isEmpty
                  ? Center(
                      child: _loading
                          ? const CircularProgressIndicator()
                          : Text(
                              _failed ? 'Could not load your history. Try again.' : 'No searches yet.',
                              style: TextStyle(color: secondary),
                            ),
                    )
                  : ListView.separated(
                      itemCount: _items.length + (_loading ? 1 : 0),
                      separatorBuilder: (_, _) => Divider(height: 1, color: CRMColors.borderOf(context)),
                      itemBuilder: (context, index) {
                        if (index >= _items.length) {
                          return const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator()));
                        }
                        final item = _items[index];
                        final meta = [
                          _when(item.lastSearchedAt),
                          if (item.searchCount > 1) 'Searched ${item.searchCount} times',
                          if (item.chips.isNotEmpty) item.chips.join(' · '),
                        ].where((part) => part.isNotEmpty).join('  •  ');
                        return ListTile(
                          dense: true,
                          leading: Icon(Icons.history_rounded, size: 18, color: secondary),
                          title: Text(item.query, maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: meta.isEmpty ? null : Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: IconButton(
                            tooltip: 'Remove from history',
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () => _remove(item),
                          ),
                          onTap: () {
                            Navigator.of(context).maybePop();
                            widget.onSelect(item.query);
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
