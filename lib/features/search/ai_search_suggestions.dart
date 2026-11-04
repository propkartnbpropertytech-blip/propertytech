/// Parsed `/search/suggest` and `/search/history` payloads.
library;

String _text(dynamic value) => value?.toString() ?? '';

int _int(dynamic value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;

DateTime? _date(dynamic value) => value == null ? null : DateTime.tryParse('$value')?.toLocal();

List<String> _labels(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .map((chip) => chip is Map ? _text(chip['label']) : _text(chip))
      .where((label) => label.isNotEmpty)
      .toList(growable: false);
}

class AiRecentSearch {
  final String id;
  final String query;
  final int searchCount;
  final int? lastResultCount;
  final DateTime? lastSearchedAt;
  final List<String> chips;

  const AiRecentSearch({
    required this.id,
    required this.query,
    this.searchCount = 1,
    this.lastResultCount,
    this.lastSearchedAt,
    this.chips = const [],
  });

  factory AiRecentSearch.fromJson(Map<String, dynamic> json) => AiRecentSearch(
        id: _text(json['id']),
        query: _text(json['query']),
        searchCount: _int(json['search_count']),
        lastResultCount: json['last_result_count'] == null ? null : _int(json['last_result_count']),
        lastSearchedAt: _date(json['last_searched_at']),
        chips: _labels(json['chips']),
      );
}

class AiPopularSearch {
  final String query;
  final int searchCount;
  final int userCount;
  final List<String> chips;

  const AiPopularSearch({required this.query, this.searchCount = 0, this.userCount = 0, this.chips = const []});

  factory AiPopularSearch.fromJson(Map<String, dynamic> json) => AiPopularSearch(
        query: _text(json['query']),
        searchCount: _int(json['search_count']),
        userCount: _int(json['user_count']),
        chips: _labels(json['chips']),
      );
}

class AiPageSuggestion {
  final String id;
  final String label;
  final String route;
  final String icon;

  const AiPageSuggestion({required this.id, required this.label, required this.route, this.icon = ''});

  factory AiPageSuggestion.fromJson(Map<String, dynamic> json) => AiPageSuggestion(
        id: _text(json['id']),
        label: _text(json['label']),
        route: _text(json['route']),
        icon: _text(json['icon']),
      );
}

class AiCompletion {
  final String text;
  final String kind;

  const AiCompletion({required this.text, this.kind = ''});

  factory AiCompletion.fromJson(Map<String, dynamic> json) =>
      AiCompletion(text: _text(json['text']), kind: _text(json['kind']));
}

List<T> _list<T>(dynamic raw, T Function(Map<String, dynamic>) parse) {
  if (raw is! List) return const [];
  return raw.whereType<Map>().map((row) => parse(Map<String, dynamic>.from(row))).toList(growable: false);
}

class AiSuggestions {
  final String query;
  final List<AiRecentSearch> recent;
  final List<AiPopularSearch> popular;
  final List<AiPageSuggestion> pages;
  final List<AiCompletion> completions;

  /// Grouped records in the `/search/ai` shape, or null when nothing was searched.
  final Map<String, dynamic>? records;

  /// Public intent (entity, filters, chips, residual), or null for an empty query.
  final Map<String, dynamic>? intent;

  const AiSuggestions({
    this.query = '',
    this.recent = const [],
    this.popular = const [],
    this.pages = const [],
    this.completions = const [],
    this.records,
    this.intent,
  });

  static const empty = AiSuggestions();

  factory AiSuggestions.fromJson(Map<String, dynamic> json) => AiSuggestions(
        query: _text(json['query']),
        recent: _list(json['recent'], AiRecentSearch.fromJson),
        popular: _list(json['popular'], AiPopularSearch.fromJson),
        pages: _list(json['pages'], AiPageSuggestion.fromJson),
        completions: _list(json['completions'], AiCompletion.fromJson),
        records: json['records'] is Map ? Map<String, dynamic>.from(json['records'] as Map) : null,
        intent: json['intent'] is Map ? Map<String, dynamic>.from(json['intent'] as Map) : null,
      );

  bool get hasTextSuggestions => recent.isNotEmpty || popular.isNotEmpty || completions.isNotEmpty;
}

class AiSearchHistoryPage {
  final List<AiRecentSearch> items;
  final int page;
  final int totalPages;
  final int total;

  const AiSearchHistoryPage({this.items = const [], this.page = 1, this.totalPages = 0, this.total = 0});

  factory AiSearchHistoryPage.fromJson(Map<String, dynamic> json) => AiSearchHistoryPage(
        items: _list(json['items'], AiRecentSearch.fromJson),
        page: _int(json['page']),
        totalPages: _int(json['total_pages']),
        total: _int(json['total']),
      );
}
