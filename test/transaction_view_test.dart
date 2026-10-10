import 'package:adips_web/utils/models/app_transaction.dart';
import 'package:adips_web/utils/models/home_list_item.dart';
import 'package:adips_web/web/dashboard/transaction_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AppTransaction tx(
  int id,
  String description, {
  double amount = 10,
  String type = 'debit',
  String category = 'Food',
  String account = 'Main',
  int accountId = 1,
  DateTime? date,
  String? group,
}) {
  final d = date ?? DateTime(2026, 10, 5, 10);
  return AppTransaction(
    id: id,
    userId: 1,
    accountId: accountId,
    accountName: account,
    amount: amount,
    type: type,
    category: category,
    categoryIconId: 0,
    categoryColorId: 0,
    description: description,
    status: 'completed',
    paymentMethod: 'cash',
    transactionDate: d,
    note: '',
    currency: 'INR',
    createdAt: d,
    updatedAt: d,
    transferGroupId: group,
  );
}

List<String> names(List<HomeListItem> items) => [
      for (final i in items)
        switch (i) {
          TransactionRow(:final transaction) => transaction.description,
          TransferRow(:final debit, :final credit) =>
            '${debit.accountName}>${credit.accountName}',
        }
    ];

void main() {
  final list = [
    tx(1, 'Coffee', amount: 5, date: DateTime(2026, 10, 9)),
    tx(2, 'Salary', amount: 5000, type: 'credit', category: 'Salary', date: DateTime(2026, 10, 1)),
    tx(3, 'Rent', amount: 800, category: 'Housing', date: DateTime(2026, 9, 28)),
  ];

  test('default sort is newest first; the other sorts work', () {
    List<String> sorted(SortOption s) => names(buildVisibleItems(
        transactions: list, collapseTransfers: true, sort: s));
    expect(sorted(SortOption.newestFirst), ['Coffee', 'Salary', 'Rent']);
    expect(sorted(SortOption.oldestFirst), ['Rent', 'Salary', 'Coffee']);
    expect(sorted(SortOption.amountHighToLow), ['Salary', 'Rent', 'Coffee']);
    expect(sorted(SortOption.amountLowToHigh), ['Coffee', 'Rent', 'Salary']);
  });

  test('search matches description, category and account name, any case', () {
    List<String> find(String q) => names(buildVisibleItems(
        transactions: list, collapseTransfers: true, query: q));
    expect(find('COFF'), ['Coffee']);
    expect(find('housing'), ['Rent']);
    expect(find('  main '), ['Coffee', 'Salary', 'Rent']); // account name, trimmed
    expect(find('nothing'), isEmpty);
  });

  test('date range includes both end days and excludes outside', () {
    final r = DateTimeRange(
        start: DateTime(2026, 10, 1), end: DateTime(2026, 10, 9));
    expect(
      names(buildVisibleItems(
          transactions: list, collapseTransfers: true, range: r)),
      ['Coffee', 'Salary'],
    );
  });

  test('last day of the range includes late-evening transactions', () {
    final late = [tx(9, 'Late', date: DateTime(2026, 10, 9, 23, 30))];
    final r = DateTimeRange(
        start: DateTime(2026, 10, 9), end: DateTime(2026, 10, 9));
    expect(
      names(buildVisibleItems(
          transactions: late, collapseTransfers: true, range: r)),
      ['Late'],
    );
  });

  group('transfers', () {
    final legs = [
      tx(10, 'Transfer', type: 'debit', account: 'Main', accountId: 1, group: 'g1'),
      tx(11, 'Transfer', type: 'credit', account: 'Cash', accountId: 2, group: 'g1'),
      tx(12, 'Orphan', type: 'credit', account: 'Cash', accountId: 2, group: 'g2'),
    ];

    test('both legs collapse into one row when no account is selected', () {
      expect(
        names(buildVisibleItems(transactions: legs, collapseTransfers: true)),
        unorderedEquals(['Main>Cash', 'Orphan']), // orphan leg stays a row
      );
    });

    test('with an account selected, legs stay as plain rows', () {
      expect(
        buildVisibleItems(transactions: legs, collapseTransfers: false)
            .whereType<TransferRow>(),
        isEmpty,
      );
    });

    test('a transfer is found by "transfer" and by either account name', () {
      List<String> find(String q) => names(buildVisibleItems(
          transactions: legs, collapseTransfers: true, query: q));
      expect(find('transfer'), ['Main>Cash']);
      expect(find('cash'), unorderedEquals(['Main>Cash', 'Orphan']));
    });
  });
}
