import 'dart:io';

import 'package:adips_web/utils/http/http_client.dart';
import 'package:adips_web/utils/models/date_range_option.dart';
import 'package:adips_web/web/dashboard/transaction_view.dart';
import 'package:adips_web/web/transactions/transactions_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String _tx(int id) =>
    '{"id":$id,"user_id":1,"account_id":1,"account_name":"Main","amount":10,'
    '"type":"debit","category":"Food","description":"T$id","status":"completed",'
    '"payment_method":"cash","transaction_date":"2026-10-05T10:00:00Z","note":"",'
    '"currency":"INR","created_at":"2026-10-05T10:00:00Z",'
    '"updated_at":"2026-10-05T10:00:00Z"}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('adips_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => dir.path,
    );
    await GetStorage.init();
  });

  late http.Client original;
  late List<Uri> requests;
  late bool fail;
  const total = 25;

  setUp(() {
    original = AdipsHttpHelper.client;
    requests = [];
    fail = false;
    AdipsHttpHelper.client = MockClient((req) async {
      requests.add(req.url);
      if (fail) return http.Response('{"message":"boom"}', 500);
      if (!req.url.path.endsWith('/transactions')) {
        return http.Response('{"success":true,"data":[]}', 200);
      }
      final page = int.parse(req.url.queryParameters['page']!);
      final limit = int.parse(req.url.queryParameters['limit']!);
      final first = (page - 1) * limit;
      final count = (total - first).clamp(0, limit);
      final pages = (total / limit).ceil();
      final rows = [for (var i = 0; i < count; i++) _tx(first + i + 1)];
      return http.Response(
          '{"success":true,"data":[${rows.join(',')}],"meta":{"page":$page,'
          '"limit":$limit,"total_records":$total,"total_pages":$pages}}',
          200);
    });
  });

  tearDown(() => AdipsHttpHelper.client = original);

  Map<String, String> last() => requests.last.queryParameters;

  test('first fetch loads page 1 with the paging info', () async {
    final c = TransactionsController();
    await c.fetch();
    expect(c.hasLoaded, isTrue);
    expect(c.items.length, 10);
    expect(c.pageInfo.value.totalRecords, 25);
    expect(c.pageInfo.value.totalPages, 3);
    expect(c.isLoading.value, isFalse);
  });

  test('goToPage asks the server for that page and clamps to the range',
      () async {
    final c = TransactionsController();
    await c.fetch();
    c.goToPage(3);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(last()['page'], '3');
    expect(c.items.length, 5); // 25 rows: 10 + 10 + 5
    expect(c.pageInfo.value.lastRow, 25);

    final before = requests.length;
    c.goToPage(99); // clamps to 3 = where we already are: no request
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(requests.length, before);
  });

  test('changing a filter goes back to page 1 and sends the filter', () async {
    final c = TransactionsController();
    await c.fetch();
    c.goToPage(2);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    c.setStatus('pending');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(c.page.value, 1);
    expect(last()['page'], '1');
    expect(last()['status'], 'pending');

    c.setType('credit');
    c.setAccount(4);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(last()['type'], 'credit');
    expect(last()['account_id'], '4');
    expect(c.hasFilters, isTrue);
  });

  test('sort: header toggles flip direction and ask the server', () async {
    final c = TransactionsController();
    await c.fetch();
    c.toggleDateSort();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(c.sort.value, SortOption.oldestFirst);
    expect(last()['order'], 'asc');

    c.toggleAmountSort();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(c.sort.value, SortOption.amountHighToLow);
    expect(last()['sort_by'], 'amount');
    expect(last()['order'], 'desc');
  });

  test('typing is debounced into a single search request', () async {
    final c = TransactionsController(
        searchDebounce: const Duration(milliseconds: 30));
    await c.fetch();
    final before = requests.length;

    c.setSearch('l');
    c.setSearch('lu');
    c.setSearch('lunch');
    expect(requests.length, before); // nothing sent while typing
    await Future<void>.delayed(const Duration(milliseconds: 120));

    expect(requests.length, before + 1);
    expect(last()['search'], 'lunch');
  });

  test('clearFilters resets everything and reloads page 1', () async {
    final c = TransactionsController();
    await c.fetch();
    c.setStatus('failed');
    c.setDateRange(DateRangeOptions.presets().first);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(last().containsKey('start_date'), isTrue);

    c.clearFilters();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(c.hasFilters, isFalse);
    expect(last().containsKey('status'), isFalse);
    expect(last().containsKey('start_date'), isFalse);
  });

  test('a page past the end falls back to the last page', () async {
    final c = TransactionsController();
    await c.fetch();
    c.page.value = 7; // e.g. rows were deleted since
    await c.fetch();
    expect(c.page.value, 3);
    expect(c.items.length, 5);
    expect(c.isLoading.value, isFalse);
  });

  test('a failed first load sets loadError; a later failure keeps the rows',
      () async {
    fail = true;
    final c = TransactionsController();
    await c.fetch();
    expect(c.loadError.value, isNotNull);
    expect(c.hasLoaded, isFalse);

    fail = false;
    await c.fetch();
    expect(c.loadError.value, isNull);
    expect(c.items.length, 10);

    fail = true;
    c.goToPage(2);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(c.loadError.value, isNotNull);
    expect(c.items.length, 10); // old rows stay on screen
    expect(c.isLoading.value, isFalse);

    fail = false; // clicking the same page again retries it
    c.goToPage(2);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(c.loadError.value, isNull);
    expect(c.pageInfo.value.page, 2);
  });

  testWidgets('an Obx reading hasLoaded rebuilds when the first load finishes',
      (tester) async {
    // Regression: hasLoaded was a plain bool, so the page stayed on its
    // loading spinner forever even though the data had arrived.
    final c = TransactionsController();
    await tester.pumpWidget(MaterialApp(
      home: Obx(() => Text(c.hasLoaded ? 'loaded' : 'loading')),
    ));
    expect(find.text('loading'), findsOneWidget);

    await tester.runAsync(() => c.fetch());
    await tester.pump();
    expect(find.text('loaded'), findsOneWidget);
  });
}
