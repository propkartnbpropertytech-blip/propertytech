import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../services/global_search_service.dart';

class GlobalSearchResultsScreen extends StatefulWidget {
  final String query;
  final String initialCategory;

  const GlobalSearchResultsScreen({
    super.key,
    required this.query,
    this.initialCategory = 'properties',
  });

  @override
  State<GlobalSearchResultsScreen> createState() => _GlobalSearchResultsScreenState();
}

class _GlobalSearchResultsScreenState extends State<GlobalSearchResultsScreen> {
  static const _categories = ['properties', 'requirements', 'owners', 'clients', 'leads'];
  final GlobalSearchService _service = GlobalSearchService();
  late String _category = widget.initialCategory;
  int _page = 1;
  int _request = 0;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  int _total = 0;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.search(query: widget.query, category: _category, page: _page);
      if (!mounted || request != _request) return;
      final rows = data[_category];
      setState(() {
        _items = rows is List
            ? rows.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList()
            : [];
        _total = data['total'] is num ? (data['total'] as num).toInt() : _items.length;
        _totalPages = data['total_pages'] is num ? (data['total_pages'] as num).toInt() : 1;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        _error = 'Search results are unavailable.';
      });
    }
  }

  String _title(Map<String, dynamic> row) {
    return (row['title'] ?? row['name'] ?? row['customer_name'] ?? row['companyName'] ?? row['property_code'] ?? 'Result').toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Search results for "${widget.query}"')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(CRMSpacing.m),
            child: Row(
              children: [
                for (final category in _categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: _category == category,
                      onSelected: (_) {
                        setState(() {
                          _category = category;
                          _page = 1;
                        });
                        _load();
                      },
                    ),
                  ),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(CRMSpacing.m),
              child: Text(_error!, style: TextStyle(color: CRMColors.danger)),
            ),
          Expanded(
            child: ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final row = _items[index];
                return ListTile(
                  title: Text(_title(row)),
                  subtitle: Text((row['mobile'] ?? row['phone'] ?? row['property_code'] ?? '').toString()),
                  onTap: () {
                    final id = row['id'];
                    if (id == null) return;
                    if (_category == 'properties') context.go('/properties?openId=$id');
                    if (_category == 'requirements' || _category == 'leads') context.go('/requirements?openId=$id');
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(CRMSpacing.m),
            child: Row(
              children: [
                Text('$_total results'),
                const Spacer(),
                IconButton(
                  onPressed: _page > 1
                      ? () {
                          setState(() => _page -= 1);
                          _load();
                        }
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('$_page / ${_totalPages == 0 ? 1 : _totalPages}'),
                IconButton(
                  onPressed: _page < _totalPages
                      ? () {
                          setState(() => _page += 1);
                          _load();
                        }
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
