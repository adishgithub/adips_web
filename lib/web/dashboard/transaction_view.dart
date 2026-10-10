import 'package:flutter/material.dart';

import '../../utils/models/app_transaction.dart';
import '../../utils/models/home_list_item.dart';

enum SortOption { newestFirst, oldestFirst, amountHighToLow, amountLowToHigh }

extension SortOptionLabel on SortOption {
  String get label => switch (this) {
        SortOption.newestFirst => 'Newest First',
        SortOption.oldestFirst => 'Oldest First',
        SortOption.amountHighToLow => 'Amount: High to Low',
        SortOption.amountLowToHigh => 'Amount: Low to High',
      };
}

/// Turns the fetched transactions into the rows the list shows: collapse
/// transfer pairs, search, date range, sort. Pure (no state, no HTTP) so it
/// is unit-tested; same rules as the mobile HomeController.visibleItems.
///
/// The API returns a transfer as two legs. With NO account filter
/// ([collapseTransfers] true) both legs become one [TransferRow]; with an
/// account filter only that account's leg is present and stays a normal
/// signed row so the account's statement adds up. A leg whose partner is not
/// in the list also stays a plain row instead of vanishing.
List<HomeListItem> buildVisibleItems({
  required List<AppTransaction> transactions,
  required bool collapseTransfers,
  String query = '',
  DateTimeRange? range,
  SortOption sort = SortOption.newestFirst,
}) {
  final q = query.trim().toLowerCase();

  final debits = <String, AppTransaction>{};
  final credits = <String, AppTransaction>{};
  if (collapseTransfers) {
    for (final t in transactions) {
      final id = t.transferGroupId;
      if (id == null) continue;
      (t.isCredit ? credits : debits)[id] = t;
    }
  }

  final items = <HomeListItem>[];
  for (final t in transactions) {
    final id = t.transferGroupId;
    if (collapseTransfers &&
        id != null &&
        debits.containsKey(id) &&
        credits.containsKey(id)) {
      // Emit the pair once, when we meet its debit leg.
      if (!t.isCredit) {
        items.add(TransferRow(debit: debits[id]!, credit: credits[id]!));
      }
      continue;
    }
    items.add(TransactionRow(t));
  }

  bool matches(HomeListItem item) {
    if (q.isEmpty) return true;
    return switch (item) {
      TransactionRow(:final transaction) => transaction.matchesQuery(q) ||
          transaction.accountName.toLowerCase().contains(q),
      TransferRow(:final debit, :final credit) =>
        'transfer ${debit.accountName} ${credit.accountName} ${debit.note}'
            .toLowerCase()
            .contains(q),
    };
  }

  var filtered = items.where(matches);

  if (range != null) {
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end =
        DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
    filtered = filtered
        .where((i) => !i.date.isBefore(start) && !i.date.isAfter(end));
  }

  final list = filtered.toList();
  list.sort((a, b) => switch (sort) {
        SortOption.newestFirst => b.date.compareTo(a.date),
        SortOption.oldestFirst => a.date.compareTo(b.date),
        SortOption.amountHighToLow => b.amount.compareTo(a.amount),
        SortOption.amountLowToHigh => a.amount.compareTo(b.amount),
      });
  return list;
}
