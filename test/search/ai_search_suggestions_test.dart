import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/api/api_client.dart';
import 'package:propkart/features/search/ai_search_routes.dart';
import 'package:propkart/features/search/ai_search_suggestions.dart';
import 'package:propkart/features/search/services/ai_search_service.dart';
import 'package:propkart/features/search/widgets/ai_search_history_sheet.dart';
import 'package:propkart/features/search/widgets/ai_search_panel.dart';

class _FakeApi extends ApiClient {
  final List<String> calls = [];
  final List<Map<String, dynamic>> posts = [];
  List<Map<String, dynamic>> history = [
    {'id': '11111111-1111-1111-1111-111111111111', 'query': '2 bhk rent satellite', 'search_count': 3, 'last_searched_at': '2026-10-30T10:00:00Z', 'chips': [{'key': 'bedrooms', 'label': '2 BHK'}]},
    {'id': '22222222-2222-2222-2222-222222222222', 'query': 'gota', 'search_count': 1, 'last_searched_at': '2026-10-31T09:00:00Z', 'chips': []},
  ];

  Response _ok(String path, Object data) =>
      Response(requestOptions: RequestOptions(path: path), statusCode: 200, data: {'success': true, 'data': data});

  @override
  Future<Response> get(String url, {Map<String, dynamic>? queryParameters, Options? options}) async {
    calls.add('GET $url');
    if (url == '/search/history') {
      return _ok(url, {'items': history, 'page': 1, 'page_size': 20, 'total': history.length, 'total_pages': 1});
    }
    if (url == '/search/suggest') {
      return _ok(url, {
        'query': queryParameters?['q'],
        'recent': [history.first],
        'popular': [
          {'query': 'available property in gota', 'search_count': 4, 'user_count': 2},
        ],
        'pages': [
          {'id': 'properties', 'label': 'Properties', 'route': '/properties', 'icon': 'apartment'},
        ],
        'completions': [
          {'text': 'property in Satellite', 'kind': 'area'},
        ],
        'records': {
          'properties': [
            {'id': 'p1', 'title': 'Sunrise'},
          ],
          'totals': {'properties': 1},
        },
        'intent': {'entity': 'properties', 'filters': {}, 'chips': [], 'residual': 'sun'},
      });
    }
    throw DioException(requestOptions: RequestOptions(path: url));
  }

  @override
  Future<Response> post(String url, Map<String, dynamic> body, {Options? options}) async {
    calls.add('POST $url');
    posts.add(body);
    return _ok(url, {});
  }

  @override
  Future<Response> delete(String url, {Options? options}) async {
    calls.add('DELETE $url');
    if (url == '/search/history') {
      history = [];
    } else {
      final id = url.split('/').last;
      history = history.where((row) => row['id'] != id).toList();
    }
    return _ok(url, {'removed': true});
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('suggest, history and record use the search API shapes', () async {
    final api = _FakeApi();
    final service = AiSearchService(apiClient: api);

    final suggest = await service.suggest('sun');
    expect(suggest.failed, isFalse);
    expect(suggest.suggestions.recent.single.query, '2 bhk rent satellite');
    expect(suggest.suggestions.recent.single.chips, ['2 BHK']);
    expect(suggest.suggestions.recent.single.searchCount, 3);
    expect(suggest.suggestions.popular.single.userCount, 2);
    expect(suggest.suggestions.pages.single.route, '/properties');
    expect(suggest.suggestions.completions.single.text, 'property in Satellite');
    expect((suggest.suggestions.records?['properties'] as List).single['title'], 'Sunrise');
    expect(suggest.suggestions.intent?['residual'], 'sun');

    final page = await service.history(filter: '  gota ');
    expect(page?.items, hasLength(2));
    expect(page?.total, 2);

    await service.record(query: '  gota  ', source: 'history', resultCount: 4);
    await service.record(query: '   ');
    expect(api.posts, hasLength(1));
    expect(api.posts.single, {'query': 'gota', 'source': 'history', 'result_count': 4});

    await service.record(query: 'sun', source: 'record', selectionType: 'property', selectionId: 'p1', selectionRoute: '/properties?openId=p1');
    expect(api.posts.last['selection'], {'type': 'property', 'id': 'p1', 'route': '/properties?openId=p1'});
    expect(api.posts.last.containsKey('result_count'), isFalse);

    expect(await service.removeHistory('22222222-2222-2222-2222-222222222222'), isTrue);
    expect(api.history, hasLength(1));
    expect(await service.clearHistory(), isTrue);
    expect(api.history, isEmpty);
  });

  test('a failed suggest call reports failure instead of throwing', () async {
    final service = AiSearchService(apiClient: _ThrowingApi());
    final result = await service.suggest('x');
    expect(result.failed, isTrue);
    expect(result.suggestions.hasTextSuggestions, isFalse);
    expect(await service.history(), isNull);
    expect(await service.removeHistory('a'), isFalse);
  });

  test('keyboard order lists recent, then completions, then popular, without duplicates', () {
    final entries = AiSearchPanel.suggestionEntries(
      query: 'sat',
      recent: const [AiRecentSearch(id: '1', query: 'Satellite rent')],
      completions: const [AiCompletion(text: 'satellite rent'), AiCompletion(text: 'property in Satellite')],
      popular: const [AiPopularSearch(query: 'Satellite 2 BHK')],
    );
    expect(entries.map((entry) => entry.text), ['Satellite rent', 'property in Satellite', 'Satellite 2 BHK']);
    expect(entries.map((entry) => entry.kind), ['recent', 'completion', 'popular']);

    final idle = AiSearchPanel.suggestionEntries(query: '', completions: const [AiCompletion(text: 'ignored')]);
    expect(idle.map((entry) => entry.kind).toSet(), {'example'});
    expect(idle, hasLength(AiSearchPanel.examples.length));
  });

  group('AiSearchRoutes', () {
    test('records open their exact page', () {
      final deleted = Uri.parse(AiSearchRoutes.property({'id': 'p1', 'is_recycle_bin': true, 'property_code': 'PK-9', 'listing_type': 'Rent'}));
      expect(deleted.path, '/bin');
      expect(deleted.queryParameters['tab'], 'properties');
      expect(deleted.queryParameters['search'], 'PK-9');
      final property = Uri.parse(AiSearchRoutes.property({'id': 'p1'}));
      expect(property.path, '/properties');
      expect(property.queryParameters['openId'], 'p1');
      expect(property.queryParameters['t'], isNotEmpty);
      expect(Uri.parse(AiSearchRoutes.requirement({'id': 'r1'})).queryParameters['openId'], 'r1');
      expect(AiSearchRoutes.client({'name': 'A & B'}), '/clients?search=A+%26+B');
      expect(AiSearchRoutes.employee({'id': 'u1'}, canOpenDetails: true), '/users/u1');
      expect(AiSearchRoutes.employee({'id': 'u1'}, canOpenDetails: false), '/users');
    });

    test('lead routes follow the role and the lead source', () {
      final salesCampaign = AiSearchRoutes.leadCandidates(
        {'id': 'l1', 'requirement_id': 'r9', 'is_campaign': true, 'lead_type': 'Requirement', 'name': 'X'},
        'Sales',
      );
      expect(Uri.parse(salesCampaign.first).path, '/my-campaign-leads');
      expect(Uri.parse(salesCampaign.first).queryParameters['openId'], 'r9');

      final salesListing = AiSearchRoutes.leadCandidates(
        {'id': 'l1', 'is_campaign': true, 'lead_type': 'Property Listing', 'name': 'Asha'},
        'Sales',
      );
      expect(salesListing.first, '/my-campaign-leads?search=Asha');

      final salesDirect = AiSearchRoutes.leadCandidates({'id': 'l2', 'name': 'Y'}, 'Sales');
      expect(salesDirect, hasLength(1));
      expect(Uri.parse(salesDirect.single).path, '/requirements');

      expect(AiSearchRoutes.leadCandidates({'name': 'Z', 'queue': 'CNR'}, 'Telecaller'), ['/telecaller/cnr?q=Z']);
      expect(AiSearchRoutes.leadCandidates({'name': 'Z', 'queue': 'Callback'}, 'Telecaller'), ['/telecaller/callbacks?q=Z']);
      final housing = Uri.parse(AiSearchRoutes.leadCandidates({'name': 'Z', 'source': 'HOUSING'}, 'Admin').first);
      expect(housing.path, '/campaign/housing');
      expect(housing.queryParameters['search'], 'Z');
      final meta = Uri.parse(AiSearchRoutes.leadCandidates({'name': 'Z', 'source': 'META', 'lead_type': 'Property Listing'}, 'Admin').first);
      expect(meta.path, '/campaign/meta');
      expect(meta.queryParameters['section'], 'Property Listing');

      final admin = AiSearchRoutes.leadCandidates({'name': 'Z', 'source': 'META'}, 'Admin');
      final fallback = Uri.parse(AiSearchRoutes.firstAllowed(admin, (path) => path != '/campaign/meta')!);
      expect(fallback.path, '/campaign/leads');
      expect(fallback.queryParameters['search'], 'Z');
      expect(AiSearchRoutes.firstAllowed(admin, (_) => false), isNull);

      final unnamed = Uri.parse(AiSearchRoutes.leadCandidates({'name': 'Lead', 'phone': '+91 98765 43210'}, 'Admin').first);
      expect(unnamed.queryParameters['search'], '9876543210');
    });

    test('a lead opens on the tab, mode and search that show it', () {
      final active = Uri.parse(AiSearchRoutes.requirement(
        {'id': 'r1', 'customer_name': 'Kuntal Shah', 'mobile': '9876543210', 'status': 'Interested', 'listing_type': 'Rent'},
        role: 'Admin',
      ));
      expect(active.path, '/requirements');
      expect(active.queryParameters['openId'], 'r1');
      expect(active.queryParameters['search'], 'Kuntal Shah');
      expect(active.queryParameters['tab'], 'leads');
      expect(active.queryParameters['mode'], 'rent');
      expect(active.queryParameters['status'], 'All');
      expect(active.queryParameters.containsKey('group'), isFalse);
      expect(active.queryParameters['t'], isNotEmpty);

      final won = Uri.parse(AiSearchRoutes.requirement({'id': 'r2', 'customer_name': 'A', 'status': 'Closed', 'listing_type': 'Re-Sale'}, role: 'Sales'));
      expect(won.queryParameters['tab'], 'won');
      expect(won.queryParameters['mode'], 'resale');
      expect(won.queryParameters['group'], 'all');

      final rejected = Uri.parse(AiSearchRoutes.requirement({'id': 'r3', 'customer_name': 'B', 'status': 'Rejected by Sales'}));
      expect(rejected.queryParameters['tab'], 'rejected');
      expect(rejected.queryParameters.containsKey('mode'), isFalse);

      final noName = Uri.parse(AiSearchRoutes.requirement({'id': 'r4', 'customer_name': '', 'mobile': '+91 98250-11122'}));
      expect(noName.queryParameters['search'], '9825011122');

      final campaign = Uri.parse(AiSearchRoutes.requirement({'id': 'r5', 'customer_name': 'C', 'is_direct_sales_campaign': true}, role: 'Sales'));
      expect(campaign.path, '/my-campaign-leads');
      expect(campaign.queryParameters['openId'], 'r5');
      expect(campaign.queryParameters.containsKey('tab'), isFalse);

      final rejectedCampaign = Uri.parse(AiSearchRoutes.requirement(
        {'id': 'r6', 'customer_name': 'D', 'status': 'Rejected (Budget Mismatch)', 'is_direct_sales_campaign': true},
        role: 'Sales',
      ));
      expect(rejectedCampaign.path, '/my-campaign-leads');
      expect(rejectedCampaign.queryParameters['tab'], 'rejected');
      expect(rejectedCampaign.queryParameters['openId'], 'r6');
    });

    test('a rejected campaign lead opens Leads → Rejected on its own record', () {
      const record = {
        'id': 'r7',
        'customer_name': 'Kuntal Shah',
        'mobile': '9876543210',
        'status': 'Rejected (No Requirement)',
        'listing_type': 'Rent',
      };
      final lead = {
        'id': 'il7',
        'name': 'Kuntal',
        'queue': 'Rejected (No Requirement)',
        'status': 'Rejected (No Requirement)',
        'lead_type': 'Requirement',
        'source': 'HOUSING',
        'rejected_requirement': record,
      };

      final admin = AiSearchRoutes.leadCandidates(lead, 'Admin');
      final opened = Uri.parse(AiSearchRoutes.firstAllowed(admin, (_) => true)!);
      expect(opened.path, '/requirements');
      expect(opened.queryParameters['tab'], 'rejected');
      expect(opened.queryParameters['openId'], 'r7');
      expect(opened.queryParameters['search'], 'Kuntal Shah');
      expect(opened.queryParameters['mode'], 'rent');
      expect(opened.queryParameters['status'], 'All');
      final noLeadsPage = Uri.parse(AiSearchRoutes.firstAllowed(admin, (path) => path != '/requirements')!);
      expect(noLeadsPage.path, '/campaign/housing');

      final telecaller = Uri.parse(AiSearchRoutes.leadCandidates({...lead, 'queue': 'CNR'}, 'Telecaller').first);
      expect(telecaller.path, '/requirements');
      expect(telecaller.queryParameters['tab'], 'rejected');

      final sales = AiSearchRoutes.leadCandidates(
        {'id': 'l7', 'requirement_id': 'r7', 'is_campaign': true, 'lead_type': 'Requirement', 'name': 'Kuntal', 'rejected_requirement': record},
        'Sales',
      );
      expect(Uri.parse(sales[0]).path, '/my-campaign-leads');
      expect(Uri.parse(sales[0]).queryParameters['tab'], 'rejected');
      expect(Uri.parse(sales[1]).path, '/requirements');
      expect(Uri.parse(sales[1]).queryParameters['tab'], 'rejected');
      expect(Uri.parse(sales[1]).queryParameters['group'], 'all');

      final active = AiSearchRoutes.leadCandidates({...lead, 'rejected_requirement': null, 'status': 'New'}, 'Admin');
      expect(Uri.parse(active.first).path, '/campaign/housing');
    });

    test('a lead row reads as rejected when its Leads page record is rejected', () {
      expect(AiSearchRoutes.leadStatus({'status': 'Interested'}), 'Interested');
      expect(
        AiSearchRoutes.leadStatus({'status': 'Interested', 'rejected_requirement': {'status': 'Rejected (Already rented)'}}),
        'Rejected (Already rented)',
      );
      expect(
        AiSearchRoutes.leadStatus({'status': 'Rejected (Others)', 'rejected_requirement': {'status': 'Rejected (Budget Mismatch)'}}),
        'Rejected (Others)',
      );
    });

    test('a property opens with the filters of the question that found it', () {
      final intent = {
        'entity': 'properties',
        'filters': {'bedrooms': 3, 'area': ['Gota'], 'max_price': 30000, 'listing_type': 'rent'},
        'residual': '',
      };
      final route = Uri.parse(AiSearchRoutes.property({'id': 'p7', 'listing_type': 'Rent'}, intent: intent));
      expect(route.path, '/properties');
      expect(route.queryParameters['openId'], 'p7');
      expect(route.queryParameters['bhk'], '3');
      expect(route.queryParameters['area'], 'Gota');
      expect(route.queryParameters.containsKey('search'), isFalse);
      expect(route.queryParameters['maxPrice'], '30000');
      expect(route.queryParameters['listingType'], 'rent');

      final byName = Uri.parse(AiSearchRoutes.property({'id': 'p8', 'listing_type': 'Re-Sale'}, intent: {'entity': 'all', 'filters': {}, 'residual': 'sunrise'}));
      expect(byName.queryParameters['search'], 'sunrise');
      expect(byName.queryParameters['listingType'], 'resale');
    });

    test('deleted records open the Recycle Bin tab that holds them', () {
      final lead = Uri.parse(AiSearchRoutes.recycleBin({'kind': 'requirement', 'id': 'r1', 'customer_name': 'Kuntal', 'listing_type': 'Re-Sale'}));
      expect(lead.path, '/bin');
      expect(lead.queryParameters['tab'], 'requirements');
      expect(lead.queryParameters['listing'], 'resale');
      expect(lead.queryParameters['search'], 'Kuntal');
      final property = Uri.parse(AiSearchRoutes.recycleBin({'kind': 'property', 'id': 'p1', 'property_code': '', 'title': 'Sunrise', 'listing_type': 'Rent'}));
      expect(property.queryParameters['tab'], 'properties');
      expect(property.queryParameters['listing'], 'rent');
      expect(property.queryParameters['search'], 'Sunrise');
      expect(AiSearchRoutes.listingParam('Re-Sale'), 'resale');
      expect(AiSearchRoutes.listingParam('Rent'), 'rent');
      expect(AiSearchRoutes.listingParam(null), '');
    });

    test('filtered pages carry the understood filters', () {
      final properties = Uri.parse(AiSearchRoutes.filteredPage({
        'entity': 'properties',
        'filters': {'listing_type': 'rent', 'bedrooms': 7, 'area': ['Satellite'], 'max_price': 35000},
        'residual': '',
      })!);
      expect(properties.path, '/properties');
      expect(properties.queryParameters['listingType'], 'rent');
      expect(properties.queryParameters['bhk'], '5');
      expect(properties.queryParameters['area'], 'Satellite');
      expect(properties.queryParameters['maxPrice'], '35000');
      expect(properties.queryParameters.containsKey('minPrice'), isFalse);

      final followups = {'entity': 'requirements', 'filters': {'followup_window': 'overdue'}, 'residual': ''};
      expect(AiSearchRoutes.filteredPage(followups, role: 'Sales'), '/requirements?tab=follow-ups&subTab=due');
      expect(AiSearchRoutes.filteredPage(followups, role: 'Telecaller'), '/requirements');
      expect(AiSearchRoutes.filteredPage({'entity': 'leads', 'filters': {}, 'residual': 'ravi'}, role: 'Telecaller'),
          '/telecaller/leads?search=ravi');
      expect(AiSearchRoutes.filteredPage({'entity': 'all', 'filters': {}, 'residual': 'ravi'}), isNull);
      expect(AiSearchRoutes.filteredPage(null), isNull);
    });

    test('view more properties opens the Properties page with every criterion of the question', () {
      final route = Uri.parse(AiSearchRoutes.propertiesPage({
        'entity': 'properties',
        'filters': {'listing_type': 'rent', 'bedrooms': 2, 'area': ['Gota'], 'min_price': 20000, 'max_price': 35000, 'status': 'available'},
        'residual': '',
      }, query: '2 bhk office for rent in gota 20k-35k available'));
      expect(route.path, '/properties');
      expect(route.queryParameters['ai'], '1');
      expect(route.queryParameters['listingType'], 'rent');
      expect(route.queryParameters['bhk'], '2');
      expect(route.queryParameters['area'], 'Gota');
      expect(route.queryParameters.containsKey('search'), isFalse);
      expect(route.queryParameters['minPrice'], '20000');
      expect(route.queryParameters['maxPrice'], '35000');
      expect(route.queryParameters['status'], 'Available');
      expect(route.queryParameters['category'], 'Commercial');
      expect(route.queryParameters['t'], isNotEmpty);

      final budgetOnly = Uri.parse(AiSearchRoutes.propertiesPage({'entity': 'properties', 'filters': {'max_price': 35000}, 'residual': ''}, query: '35k'));
      expect(budgetOnly.queryParameters['maxPrice'], '35000');
      expect(budgetOnly.queryParameters.containsKey('search'), isFalse);
      expect(budgetOnly.queryParameters.containsKey('area'), isFalse);
      expect(budgetOnly.queryParameters.containsKey('bhk'), isFalse);
      expect(budgetOnly.queryParameters.containsKey('category'), isFalse);

      final nameOnly = Uri.parse(AiSearchRoutes.propertiesPage({'entity': 'all', 'filters': {}, 'residual': 'sunrise'}, query: 'sunrise'));
      expect(nameOnly.queryParameters['search'], 'sunrise');
      expect(Uri.parse(AiSearchRoutes.propertiesPage(null, query: 'gota')).queryParameters['search'], 'gota');
      expect(AiSearchRoutes.propertyCategory('warehouse in changodar'), 'Industrial');
      expect(AiSearchRoutes.propertyCategory('plot near sanand'), 'Land & Plot');
      expect(AiSearchRoutes.propertyCategory('2 bhk flat'), '');
    });

    test('rented out and sold out searches open the tab that has the status', () {
      Map<String, String> params(Map<String, dynamic> filters) =>
          Uri.parse(AiSearchRoutes.propertiesPage({'entity': 'properties', 'filters': filters, 'residual': ''})).queryParameters;
      expect(params({'status': 'rented', 'area': ['Vaishnodevi']})['status'], 'Rented Out');
      expect(params({'status': 'rented', 'area': ['Vaishnodevi']})['listingType'], 'rent');
      expect(params({'status': 'sold'})['status'], 'Sold Out');
      expect(params({'status': 'sold'})['listingType'], 'resale');
      expect(params({'status': 'available'}).containsKey('listingType'), isFalse);
      expect(params({'status': 'sold', 'listing_type': 'resale'})['listingType'], 'resale');

      final opened = Uri.parse(AiSearchRoutes.property(
        {'id': 'p1', 'listing_type': 'Rent', 'property_status': 'Rented Out'},
        intent: {'entity': 'properties', 'filters': {'status': 'rented', 'area': ['Vaishnodevi']}, 'residual': ''},
      )).queryParameters;
      expect(opened['openId'], 'p1');
      expect(opened['status'], 'Rented Out');
      expect(opened['listingType'], 'rent');
    });

    test('a property row names its rented out or sold out status', () {
      expect(AiSearchRoutes.propertyStatus({'property_status': 'Rented Out'}), 'Rented Out');
      expect(AiSearchRoutes.propertyStatus({'property_status': 'Sold Out'}), 'Sold Out');
      expect(AiSearchRoutes.propertyStatus({'property_status': 'Available'}), isNull);
      expect(AiSearchRoutes.propertyStatus({'property_status': 'To Be Available'}), isNull);
      expect(AiSearchRoutes.propertyStatus({}), isNull);
    });
  });

  testWidgets('a rented out property shows its status next to the row', (tester) async {
    var opened = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AiSearchPanel(
          query: 'vaishnodevi rented',
          resultsMode: false,
          groups: [
            AiSearchGroupData(
              title: 'Properties',
              category: 'properties',
              total: 1,
              rows: [
                AiSearchRowData(title: 'Shivam Flats', subtitle: 'Code: PK9', badge: 'Rented Out', onTap: () => opened = true),
              ],
            ),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Rented Out'), findsOneWidget);
    await tester.tap(find.text('Shivam Flats'));
    expect(opened, isTrue);
  });

  testWidgets('the open panel shows recent and popular searches with history actions', (tester) async {
    AiSuggestionEntry? picked;
    AiRecentSearch? removed;
    var viewAll = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AiSearchPanel(
          query: '',
          resultsMode: false,
          recent: const [AiRecentSearch(id: '1', query: 'gota rent')],
          popular: const [AiPopularSearch(query: 'available property in gota'), AiPopularSearch(query: 'GOTA RENT')],
          onSuggestion: (entry) => picked = entry,
          onRemoveRecent: (item) => removed = item,
          onViewAllHistory: () => viewAll = true,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Recent searches'), findsOneWidget);
    expect(find.text('Popular in your team'), findsOneWidget);
    expect(find.text('GOTA RENT'), findsNothing);
    expect(find.text('2 BHK rentals in Satellite under ₹35,000'), findsOneWidget);

    await tester.tap(find.text('available property in gota'));
    expect(picked?.kind, 'popular');
    await tester.tap(find.byTooltip('Remove from history'));
    expect(removed?.id, '1');
    await tester.tap(find.byKey(const ValueKey('ai-search-view-all')));
    expect(viewAll, isTrue);
  });

  testWidgets('typing shows suggestions, pages, record previews and see-all', (tester) async {
    var seeAll = false;
    AiPageSuggestion? page;
    var filtered = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AiSearchPanel(
          query: 'sat',
          resultsMode: false,
          highlight: 0,
          completions: const [AiCompletion(text: 'property in Satellite')],
          pages: const [AiPageSuggestion(id: 'settings', label: 'Satellite settings', route: '/settings', icon: 'settings')],
          groups: [
            AiSearchGroupData(
              title: 'Properties',
              category: 'properties',
              total: 1,
              icon: Icons.apartment_outlined,
              rows: [AiSearchRowData(title: 'Satya Villa', subtitle: 'Code: PK1', onTap: () {})],
            ),
          ],
          onSeeAll: () => seeAll = true,
          onPage: (value) => page = value,
          onOpenFiltered: () => filtered = true,
          openFilteredLabel: 'Open Properties with these filters',
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('property in Satellite'), findsOneWidget);
    expect(find.text('Go to'), findsOneWidget);
    expect(find.text('Satya Villa'), findsOneWidget);
    expect(find.text('No matches for this search.'), findsNothing);
    final highlighted = tester.widget<ListTile>(find.ancestor(of: find.text('property in Satellite'), matching: find.byType(ListTile)));
    expect(highlighted.selected, isTrue);

    await tester.tap(find.text('Satellite settings'));
    expect(page?.route, '/settings');
    await tester.tap(find.byKey(const ValueKey('ai-search-see-all')));
    expect(seeAll, isTrue);
    await tester.tap(find.text('Open Properties with these filters'));
    expect(filtered, isTrue);
  });

  testWidgets('deleted records are labelled and kept apart from active ones', (tester) async {
    var opened = '';
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AiSearchPanel(
          query: 'kuntal',
          resultsMode: false,
          groups: [
            AiSearchGroupData(
              title: 'Leads',
              category: 'requirements',
              total: 1,
              rows: [AiSearchRowData(title: 'Kuntal Shah', subtitle: 'Mobile: 98765', onTap: () => opened = 'active')],
            ),
            AiSearchGroupData(
              title: 'Recycle Bin',
              category: 'recycle_bin',
              total: 4,
              canLoadMore: false,
              rows: [
                AiSearchRowData(
                  title: 'Kuntal Patel',
                  subtitle: 'Deleted lead',
                  badge: 'Deleted · Recycle Bin',
                  onTap: () => opened = 'deleted',
                ),
              ],
            ),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('LEADS · 1'), findsOneWidget);
    expect(find.text('RECYCLE BIN · 4'), findsOneWidget);
    expect(find.text('Deleted · Recycle Bin'), findsOneWidget);
    expect(find.text('View more recycle bin'), findsNothing);
    await tester.tap(find.text('Kuntal Patel'));
    expect(opened, 'deleted');
    await tester.tap(find.text('Kuntal Shah'));
    expect(opened, 'active');
  });

  testWidgets('typing with nothing found says so', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: AiSearchPanel(query: 'zzzz', resultsMode: false)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('No matches for this search.'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: AiSearchPanel(query: 'zzzz', resultsMode: false, suggestLoading: true)),
    ));
    await tester.pump();
    expect(find.text('No matches for this search.'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('the history sheet lists, removes and clears only through the API', (tester) async {
    final api = _FakeApi();
    String? selected;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 600,
          child: AiSearchHistorySheet(service: AiSearchService(apiClient: api), onSelect: (query) => selected = query),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('2 bhk rent satellite'), findsOneWidget);
    expect(find.text('gota'), findsOneWidget);
    expect(find.textContaining('Searched 3 times'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove from history').last);
    await tester.pumpAndSettle();
    expect(find.text('gota'), findsNothing);
    expect(api.calls, contains('DELETE /search/history/22222222-2222-2222-2222-222222222222'));

    await tester.tap(find.byKey(const ValueKey('ai-history-clear')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Clear all'));
    await tester.pumpAndSettle();
    expect(api.calls, contains('DELETE /search/history'));
    expect(find.text('No searches yet.'), findsOneWidget);
    expect(selected, isNull);
  });
}

class _ThrowingApi extends ApiClient {
  @override
  Future<Response> get(String url, {Map<String, dynamic>? queryParameters, Options? options}) async =>
      throw DioException(requestOptions: RequestOptions(path: url), type: DioExceptionType.connectionError);

  @override
  Future<Response> delete(String url, {Options? options}) async =>
      throw DioException(requestOptions: RequestOptions(path: url), type: DioExceptionType.badResponse);
}
