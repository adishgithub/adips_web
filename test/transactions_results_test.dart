import 'package:adips_web/utils/theme/adips_app_theme.dart';
import 'package:adips_web/web/dashboard/transaction_view.dart';
import 'package:adips_web/web/transactions/transactions_query.dart';
import 'package:adips_web/web/transactions/transactions_results.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'transaction_view_test.dart' show tx;

Future<void> pump(WidgetTester tester, Widget child, {double width = 1100}) async {
  tester.view.physicalSize = Size(width, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AdipsAppTheme.darkTheme,
    home: Scaffold(
        body: SingleChildScrollView(
            child: Padding(padding: const EdgeInsets.all(16), child: child))),
  ));
}

TransactionsResults results({
  int page = 2,
  int total = 25,
  int count = 3,
  SortOption sort = SortOption.newestFirst,
  bool hasFilters = false,
  VoidCallback? onDate,
  VoidCallback? onAmount,
  ValueChanged<int>? onPage,
  ValueChanged<int>? onSize,
  VoidCallback? onClear,
}) {
  final rows = [
    for (var i = 0; i < count; i++)
      tx(i, 'Item $i',
          type: i == 0 ? 'credit' : 'debit', account: 'Main', category: 'Food'),
  ];
  return TransactionsResults(
    items: rows,
    pageInfo: TransactionPage(
        items: rows, page: page, limit: 10, totalRecords: total, totalPages: 3),
    sort: sort,
    hasFilters: hasFilters,
    onToggleDateSort: onDate ?? () {},
    onToggleAmountSort: onAmount ?? () {},
    onPage: onPage ?? (_) {},
    onPageSize: onSize ?? (_) {},
    onClearFilters: onClear,
  );
}

void main() {
  testWidgets('wide: table with headers, signed amounts and status chips',
      (tester) async {
    await pump(tester, results());
    for (final h in ['Date', 'Description', 'Category', 'Account', 'Status', 'Amount']) {
      expect(find.text(h), findsOneWidget);
    }
    expect(find.text('Item 1'), findsOneWidget);
    expect(find.text('+ ₹10.00'), findsOneWidget);
    expect(find.text('- ₹10.00'), findsNWidgets(2));
    expect(find.text('Completed'), findsNWidgets(3));
  });

  testWidgets('narrow: list of rows instead of the table', (tester) async {
    await pump(tester, results(), width: 500);
    expect(find.text('Description'), findsNothing);
    expect(find.text('Item 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('clicking the Date / Amount headers reports the toggle',
      (tester) async {
    var date = 0, amount = 0;
    await pump(tester, results(onDate: () => date++, onAmount: () => amount++));
    await tester.tap(find.text('Date'));
    await tester.tap(find.text('Amount'));
    expect([date, amount], [1, 1]);
  });

  testWidgets('paging bar: summary text, next / previous', (tester) async {
    int? went;
    await pump(tester, results(onPage: (p) => went = p));
    expect(find.text('Showing 11-13 of 25'), findsOneWidget);
    expect(find.text('Page 2 of 3'), findsOneWidget);

    await tester.tap(find.byTooltip('Next page'));
    expect(went, 3);
    await tester.tap(find.byTooltip('Previous page'));
    expect(went, 1);
  });

  testWidgets('first page cannot go back, last page cannot go forward',
      (tester) async {
    await pump(tester, results(page: 1));
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_left)).onPressed,
        isNull);
    await pump(tester, results(page: 3));
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_right)).onPressed,
        isNull);
  });

  testWidgets('rows per page reports the new size', (tester) async {
    int? size;
    await pump(tester, results(onSize: (s) => size = s));
    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('25').last);
    await tester.pumpAndSettle();
    expect(size, 25);
  });

  testWidgets('empty: plain vs filtered with Clear filters', (tester) async {
    await pump(tester, results(count: 0, total: 0, page: 1));
    expect(find.text('No transactions yet'), findsOneWidget);
    expect(find.text('No results'), findsOneWidget);

    var cleared = false;
    await pump(tester,
        results(count: 0, total: 0, page: 1, hasFilters: true, onClear: () => cleared = true));
    expect(find.text('No transactions match your filters'), findsOneWidget);
    await tester.tap(find.text('Clear filters'));
    expect(cleared, isTrue);
  });
}
