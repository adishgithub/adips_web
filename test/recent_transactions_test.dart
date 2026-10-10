import 'package:adips_web/utils/models/home_list_item.dart';
import 'package:adips_web/utils/theme/adips_app_theme.dart';
import 'package:adips_web/web/dashboard/dashboard_filters.dart';
import 'package:adips_web/web/dashboard/recent_transactions.dart';
import 'package:adips_web/web/dashboard/transaction_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'transaction_view_test.dart' show tx;

Future<void> pump(WidgetTester tester, Widget child, {double width = 1000}) async {
  tester.view.physicalSize = Size(width, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AdipsAppTheme.darkTheme,
    home: Scaffold(
        body: SingleChildScrollView(
            child: Padding(padding: const EdgeInsets.all(16), child: child))),
  ));
}

void main() {
  testWidgets('shows rows with sign, and caps the list with "View all"',
      (tester) async {
    var viewAll = false;
    final items = <HomeListItem>[
      for (var i = 0; i < 5; i++)
        TransactionRow(tx(i, 'Item $i', type: i == 0 ? 'credit' : 'debit')),
    ];
    await pump(
      tester,
      RecentTransactions(items: items, limit: 3, onViewAll: () => viewAll = true),
    );

    expect(find.text('Item 0'), findsOneWidget);
    expect(find.text('Item 3'), findsNothing);
    expect(find.text('Showing 3 of 5'), findsOneWidget);
    expect(find.text('+ ₹10.00'), findsOneWidget); // the credit
    expect(find.text('- ₹10.00'), findsNWidgets(2)); // two debits shown

    await tester.tap(find.text('View all transactions'));
    expect(viewAll, isTrue);
  });

  testWidgets('empty: plain message vs filtered message with Clear filters',
      (tester) async {
    await pump(tester, const RecentTransactions(items: []));
    expect(find.text('No transactions yet'), findsOneWidget);

    var cleared = false;
    await pump(
      tester,
      RecentTransactions(
          items: const [], hasFilters: true, onClearFilters: () => cleared = true),
    );
    expect(find.textContaining('No transactions match'), findsOneWidget);
    await tester.tap(find.text('Clear filters'));
    expect(cleared, isTrue);
  });

  testWidgets('a transfer row shows "A → B" without a sign', (tester) async {
    final row = TransferRow(
      debit: tx(1, 'Transfer', account: 'Main', group: 'g'),
      credit: tx(2, 'Transfer', type: 'credit', account: 'Cash', group: 'g'),
    );
    await pump(tester, RecentTransactions(items: [row]));
    expect(find.text('Main \u2192 Cash'), findsOneWidget);
    expect(find.text('₹10.00'), findsOneWidget);
  });

  testWidgets('filters: typing reports the query, sort menu reports the choice',
      (tester) async {
    String? query;
    SortOption? sort;
    await pump(
      tester,
      DashboardFilters(
        query: '',
        onQueryChanged: (v) => query = v,
        dateRange: null,
        onDateRangeChanged: (_) {},
        sort: SortOption.newestFirst,
        onSortChanged: (v) => sort = v,
      ),
    );

    await tester.enterText(find.byType(TextField), 'lunch');
    expect(query, 'lunch');

    await tester.tap(find.text('Newest First'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Amount: High to Low'));
    await tester.pumpAndSettle();
    expect(sort, SortOption.amountHighToLow);
  });

  testWidgets('filters lay out on a phone width without overflow',
      (tester) async {
    await pump(
      tester,
      DashboardFilters(
        query: '',
        onQueryChanged: (_) {},
        dateRange: null,
        onDateRangeChanged: (_) {},
        sort: SortOption.amountLowToHigh,
        onSortChanged: (_) {},
      ),
      width: 360,
    );
    expect(tester.takeException(), isNull);
  });
}
