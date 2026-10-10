import 'package:flutter/material.dart';

import '../../utils/http/http_client.dart';
import '../../utils/models/app_transaction.dart';
import '../dashboard/transaction_view.dart' show SortOption;

/// How [SortOption] maps onto the backend's `sort_by` / `order` (allowed
/// columns there: transaction_date, amount, created_at, category, status).
extension SortOptionQuery on SortOption {
  String get sortBy => switch (this) {
        SortOption.newestFirst || SortOption.oldestFirst => 'transaction_date',
        SortOption.amountHighToLow || SortOption.amountLowToHigh => 'amount',
      };

  String get order => switch (this) {
        SortOption.newestFirst || SortOption.amountHighToLow => 'desc',
        SortOption.oldestFirst || SortOption.amountLowToHigh => 'asc',
      };
}

/// One request to GET /transactions. Filtering, sorting and paging all happen
/// on the server (the list can be far longer than one page).
class TransactionQuery {
  const TransactionQuery({
    this.page = 1,
    this.limit = 20,
    this.sort = SortOption.newestFirst,
    this.search = '',
    this.type,
    this.status,
    this.accountId,
    this.range,
  });

  final int page;
  final int limit;
  final SortOption sort;
  final String search;

  /// "credit" | "debit"; null = both.
  final String? type;

  /// "completed" | "pending" | "failed"; null = any.
  final String? status;
  final int? accountId;

  /// null = all time.
  final DateTimeRange? range;

  Map<String, String> toParams() {
    final q = search.trim();
    final r = range;
    return {
      'page': '$page',
      'limit': '$limit',
      'sort_by': sort.sortBy,
      'order': sort.order,
      if (accountId != null) 'account_id': '$accountId',
      if (type != null) 'type': type!,
      if (status != null) 'status': status!,
      if (q.isNotEmpty) 'search': q,
      // Whole first and last day, in the user's time zone, sent as UTC.
      if (r != null)
        'start_date':
            DateTime(r.start.year, r.start.month, r.start.day).toUtc().toIso8601String(),
      if (r != null)
        'end_date': DateTime(r.end.year, r.end.month, r.end.day, 23, 59, 59)
            .toUtc()
            .toIso8601String(),
    };
  }
}

/// One page of results plus the server's paging info (`meta`).
class TransactionPage {
  const TransactionPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.totalRecords,
    required this.totalPages,
  });

  final List<AppTransaction> items;
  final int page;
  final int limit;
  final int totalRecords;
  final int totalPages;

  static const empty = TransactionPage(
      items: [], page: 1, limit: 10, totalRecords: 0, totalPages: 1);

  /// 1-based position of the first / last row on this page (0 when empty).
  int get firstRow => items.isEmpty ? 0 : (page - 1) * limit + 1;
  int get lastRow => items.isEmpty ? 0 : firstRow + items.length - 1;

  factory TransactionPage.fromResponse(
    Map<String, dynamic> response, {
    required int fallbackPage,
    required int fallbackLimit,
  }) {
    final items = AdipsHttpHelper.listData(response)
        .map((e) => AppTransaction.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = AdipsHttpHelper.meta(response);
    int num0(String key, int fallback) {
      final v = meta[key];
      return v is num ? v.toInt() : fallback;
    }

    final total = num0('total_records', items.length);
    final limit = num0('limit', fallbackLimit);
    return TransactionPage(
      items: items,
      page: num0('page', fallbackPage),
      limit: limit,
      totalRecords: total,
      totalPages: num0('total_pages', 1) < 1 ? 1 : num0('total_pages', 1),
    );
  }
}

class TransactionListService {
  Future<TransactionPage> fetch(
    TransactionQuery query, {
    Duration timeout = AdipsHttpHelper.defaultTimeout,
  }) async {
    final uri =
        Uri(path: '/api/v1/transactions', queryParameters: query.toParams());
    final response = await AdipsHttpHelper.get(
      uri.toString(),
      cookie: AdipsHttpHelper.authCookie,
      timeout: timeout,
    );
    return TransactionPage.fromResponse(
      response,
      fallbackPage: query.page,
      fallbackLimit: query.limit,
    );
  }
}
