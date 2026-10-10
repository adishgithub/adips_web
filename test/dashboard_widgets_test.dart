import 'package:adips_web/utils/models/account_model.dart';
import 'package:adips_web/utils/theme/adips_app_theme.dart';
import 'package:adips_web/web/common/adaptive_grid.dart';
import 'package:adips_web/web/dashboard/account_card_grid.dart';
import 'package:adips_web/web/dashboard/balance_card.dart';
import 'package:adips_web/web/dashboard/stat_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AccountModel account({
  int id = 1,
  String name = 'Main',
  double balance = 1000,
  bool isDefault = false,
  bool includeInTotal = true,
}) =>
    AccountModel(
      id: id,
      name: name,
      type: 'bank',
      currency: 'INR',
      openingBalance: 0,
      currentBalance: balance,
      iconId: 1,
      colorId: 1,
      sortOrder: id,
      isDefault: isDefault,
      includeInTotal: includeInTotal,
      isArchived: false,
    );

Future<void> pump(WidgetTester tester, Widget child, {double width = 1200}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AdipsAppTheme.darkTheme,
    home: Scaffold(body: SingleChildScrollView(child: Padding(
      padding: const EdgeInsets.all(16),
      child: child,
    ))),
  ));
}

void main() {
  test('adaptiveColumns follows the width and respects min/max', () {
    int cols(double w) =>
        adaptiveColumns(w, minItemWidth: 230, maxColumns: 4, spacing: 16);
    expect(cols(1200), 4);
    expect(cols(900), 3);
    expect(cols(600), 2);
    expect(cols(300), 1);
    expect(cols(0), 1);
    expect(cols(5000), 4);
  });

  testWidgets('BalanceCard shows the headline total and other currencies',
      (tester) async {
    await pump(
      tester,
      const BalanceCard(totals: [
        AccountSummaryTotal(currency: 'INR', totalBalance: 1234.5),
        AccountSummaryTotal(currency: 'USD', totalBalance: 10),
      ]),
    );
    expect(find.text('₹1,234.50'), findsOneWidget);
    expect(find.text('+ \$10.00'), findsOneWidget);
  });

  testWidgets('BalanceCard with no totals shows zero in the fallback currency',
      (tester) async {
    await pump(tester, const BalanceCard(totals: [], fallbackCurrency: 'USD'));
    expect(find.text('\$0.00'), findsOneWidget);
  });

  testWidgets('StatCards show income, expenses and count', (tester) async {
    await pump(
      tester,
      const StatCards(
        totalIncome: 5000,
        totalExpenses: 1250.75,
        totalTransactions: 42,
      ),
    );
    expect(find.text('₹5,000.00'), findsOneWidget);
    expect(find.text('₹1,250.75'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('AccountCardGrid: default badge, not-in-total note, tap',
      (tester) async {
    AccountModel? tapped;
    await pump(
      tester,
      AccountCardGrid(
        accounts: [
          account(id: 1, name: 'Main', isDefault: true),
          account(id: 2, name: 'Old', balance: -50, includeInTotal: false),
        ],
        selectedId: 1,
        onTap: (a) => tapped = a,
      ),
    );
    expect(find.text('Default'), findsOneWidget);
    expect(find.textContaining('not included in total'), findsOneWidget);

    await tester.tap(find.text('Old'));
    expect(tapped?.id, 2);
  });

  testWidgets('AccountCardGrid empty state offers Add account', (tester) async {
    var added = false;
    await pump(
      tester,
      AccountCardGrid(accounts: const [], onAddAccount: () => added = true),
    );
    await tester.tap(find.text('Add account'));
    expect(added, isTrue);
  });

  testWidgets('dashboard widgets do not overflow on a phone-width screen',
      (tester) async {
    await pump(
      tester,
      Column(children: [
        const BalanceCard(totals: [
          AccountSummaryTotal(currency: 'INR', totalBalance: 98765432.1),
        ]),
        const SizedBox(height: 16),
        const StatCards(
            totalIncome: 123456789, totalExpenses: 98765, totalTransactions: 7),
        const SizedBox(height: 16),
        AccountCardGrid(accounts: [
          account(id: 1, name: 'A very long account name indeed', isDefault: true),
          account(id: 2, name: 'Cash'),
        ]),
      ]),
      width: 360,
    );
    expect(tester.takeException(), isNull);
  });
}
