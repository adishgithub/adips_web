import 'package:adips_web/web/dashboard/transaction_view.dart';
import 'package:adips_web/web/transactions/transactions_query.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults: page 1, 10 rows, newest first, no filters', () {
    expect(const TransactionQuery().toParams(), {
      'page': '1',
      'limit': '10',
      'sort_by': 'transaction_date',
      'order': 'desc',
    });
  });

  test('every filter becomes the matching query parameter', () {
    final p = TransactionQuery(
      page: 3,
      limit: 25,
      sort: SortOption.amountLowToHigh,
      search: '  lunch ',
      type: 'debit',
      status: 'pending',
      accountId: 7,
    ).toParams();
    expect(p['page'], '3');
    expect(p['limit'], '25');
    expect(p['sort_by'], 'amount');
    expect(p['order'], 'asc');
    expect(p['search'], 'lunch'); // trimmed
    expect(p['type'], 'debit');
    expect(p['status'], 'pending');
    expect(p['account_id'], '7');
  });

  test('blank search is not sent', () {
    expect(const TransactionQuery(search: '   ').toParams().containsKey('search'),
        isFalse);
  });

  test('sort options map to the backend columns', () {
    expect(SortOption.newestFirst.sortBy, 'transaction_date');
    expect(SortOption.newestFirst.order, 'desc');
    expect(SortOption.oldestFirst.order, 'asc');
    expect(SortOption.amountHighToLow.sortBy, 'amount');
    expect(SortOption.amountHighToLow.order, 'desc');
  });

  test('date range covers the whole first and last day (local time as UTC)', () {
    final p = TransactionQuery(
      range: DateTimeRange(
          start: DateTime(2026, 10, 1, 15), end: DateTime(2026, 10, 9, 8)),
    ).toParams();
    expect(DateTime.parse(p['start_date']!).toLocal(), DateTime(2026, 10, 1));
    expect(DateTime.parse(p['end_date']!).toLocal(),
        DateTime(2026, 10, 9, 23, 59, 59));
    expect(p['start_date']!.endsWith('Z'), isTrue);
  });

  test('page info reads items and meta; row range is 1-based', () {
    final page = TransactionPage.fromResponse({
      'data': [
        for (var i = 1; i <= 10; i++)
          {'id': i, 'description': 'T$i', 'type': 'debit', 'amount': 1},
      ],
      'meta': {'page': 2, 'limit': 10, 'total_records': 25, 'total_pages': 3},
    }, fallbackPage: 1, fallbackLimit: 10);
    expect(page.items.length, 10);
    expect(page.page, 2);
    expect(page.totalRecords, 25);
    expect(page.totalPages, 3);
    expect(page.firstRow, 11);
    expect(page.lastRow, 20);
  });

  test('missing meta falls back instead of crashing', () {
    final page = TransactionPage.fromResponse({'data': []},
        fallbackPage: 4, fallbackLimit: 25);
    expect(page.items, isEmpty);
    expect(page.page, 4);
    expect(page.totalPages, 1);
    expect(page.firstRow, 0);
    expect(page.lastRow, 0);
  });
}
