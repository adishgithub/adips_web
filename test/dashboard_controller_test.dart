import 'dart:io';

import 'package:adips_web/utils/http/http_client.dart';
import 'package:adips_web/web/dashboard/dashboard_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _accounts = '''
{"success":true,"data":[
 {"id":1,"name":"Main","type":"bank","currency":"INR","opening_balance":0,
  "current_balance":1500,"icon_id":1,"color_id":1,"sort_order":1,
  "is_default":true,"include_in_total":true,"is_archived":false},
 {"id":2,"name":"Cash","type":"cash","currency":"USD","opening_balance":0,
  "current_balance":20,"icon_id":2,"color_id":2,"sort_order":2,
  "is_default":false,"include_in_total":true,"is_archived":false}]}''';

const _accountSummary = '''
{"success":true,"data":{"totals":[{"currency":"INR","total_balance":1500},
 {"currency":"USD","total_balance":20}],"accounts":[]}}''';

String _tx(int id, String desc, {int account = 1}) =>
    '{"id":$id,"user_id":1,"account_id":$account,"account_name":"A$account",'
    '"amount":10,"type":"debit","category":"Food","description":"$desc",'
    '"status":"completed","payment_method":"cash",'
    '"transaction_date":"2026-10-05T10:00:00Z","note":"","currency":"INR",'
    '"created_at":"2026-10-05T10:00:00Z","updated_at":"2026-10-05T10:00:00Z"}';

String _stats(num credit, num debit, int count) =>
    '{"success":true,"data":{"total_credit":$credit,"total_debit":$debit,'
    '"balance":${credit - debit},"transaction_count":$count}}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The services read the saved token from GetStorage, which needs a folder:
  // point path_provider at a temp dir so it can start in a test.
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
  late bool failStats;

  setUp(() {
    original = AdipsHttpHelper.client;
    requests = [];
    failStats = false;
    AdipsHttpHelper.client = MockClient((req) async {
      requests.add(req.url);
      final path = req.url.path;
      if (path.endsWith('/accounts/summary')) {
        return http.Response(_accountSummary, 200);
      }
      if (path.endsWith('/accounts')) return http.Response(_accounts, 200);
      if (path.endsWith('/transactions/summary')) {
        if (failStats) return http.Response('{"message":"boom"}', 500);
        return req.url.queryParameters['account_id'] == '2'
            ? http.Response(_stats(5, 1, 2), 200)
            : http.Response(_stats(100, 40, 9), 200);
      }
      if (path.endsWith('/transactions')) {
        final body = req.url.queryParameters['account_id'] == '2'
            ? '[${_tx(3, 'Only cash', account: 2)}]'
            : '[${_tx(1, 'Coffee')},${_tx(2, 'Lunch')}]';
        return http.Response('{"success":true,"data":$body}', 200);
      }
      return http.Response('{}', 404);
    });
  });

  tearDown(() => AdipsHttpHelper.client = original);

  test('loadAll fills accounts, totals and stats', () async {
    final c = DashboardController();
    await c.loadAll();

    expect(c.loadError.value, isNull);
    expect(c.isLoading.value, isFalse);
    expect(c.accounts.length, 2);
    expect(c.accountSummary.value.totals.first.totalBalance, 1500);
    expect(c.stats.value.totalCredit, 100);
    expect(c.stats.value.count, 9);
    expect(c.statsCurrency, 'INR'); // first total
    expect(c.transactions.map((t) => t.description), ['Coffee', 'Lunch']);
  });

  test('selecting an account re-fetches stats for it; again clears it',
      () async {
    final c = DashboardController();
    await c.loadAll();

    await c.selectAccount(2);
    expect(c.selectedAccountId.value, 2);
    expect(c.stats.value.count, 2);
    expect(c.statsCurrency, 'USD'); // the selected account's
    expect(c.transactions.map((t) => t.description), ['Only cash']);
    expect(requests.any((u) =>
        u.path.endsWith('/transactions') &&
        u.queryParameters['account_id'] == '2'), isTrue);

    await c.selectAccount(2); // same card again = back to all
    expect(c.selectedAccountId.value, isNull);
    expect(c.stats.value.count, 9);
    expect(c.transactions.length, 2);
  });

  test('a failed filter keeps the previous selection and reports an error',
      () async {
    final c = DashboardController();
    await c.loadAll();

    failStats = true;
    await c.selectAccount(2);

    expect(c.selectedAccountId.value, isNull);
    expect(c.stats.value.count, 9);
    expect(c.refreshError.value, isNotNull);
    expect(c.isRefreshing.value, isFalse);
  });

  test('search and clearFilters change the visible rows locally', () async {
    final c = DashboardController();
    await c.loadAll();
    c.setDateRange(null); // all time: the fixture dates are fixed

    c.setSearchQuery('lunch');
    expect(c.visibleItems.length, 1);

    final before = requests.length;
    c.clearFilters();
    expect(c.searchQuery.value, '');
    expect(c.visibleItems.length, 2);
    expect(requests.length, before); // no extra HTTP for local filters
  });

  test('a failed first load sets loadError and clears the spinner', () async {
    failStats = true;
    final c = DashboardController();
    await c.loadAll();

    expect(c.loadError.value, isNotNull);
    expect(c.isLoading.value, isFalse);
    expect(c.hasLoaded, isFalse);
  });
}
