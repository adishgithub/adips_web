import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../utils/constants/adips_category_colors.dart';
import '../../utils/constants/adips_icons.dart';
import '../../utils/constants/adips_palette.dart';
import '../../utils/constants/sizes.dart';
import '../../utils/helpers/category_style.dart';
import '../../utils/helpers/helper_functions.dart';
import '../../utils/models/app_transaction.dart';
import '../dashboard/recent_transactions.dart' show TransactionTile;
import '../dashboard/transaction_view.dart' show SortOption;
import 'transactions_query.dart';

/// Width of the results area from which the table replaces the card list.
const double kTableMinWidth = 760;

/// The results card: a sortable table on wide screens, a list of rows on
/// narrow ones, an empty state, and the paging bar underneath.
class TransactionsResults extends StatelessWidget {
  const TransactionsResults({
    super.key,
    required this.items,
    required this.pageInfo,
    required this.sort,
    required this.hasFilters,
    required this.onToggleDateSort,
    required this.onToggleAmountSort,
    required this.onPage,
    required this.onPageSize,
    this.onClearFilters,
    this.pageSizes = const [10, 25, 50],
    this.isLoading = false,
  });

  final List<AppTransaction> items;
  final TransactionPage pageInfo;
  final SortOption sort;
  final bool hasFilters;
  final bool isLoading;
  final VoidCallback onToggleDateSort;
  final VoidCallback onToggleAmountSort;
  final ValueChanged<int> onPage;
  final ValueChanged<int> onPageSize;
  final VoidCallback? onClearFilters;
  final List<int> pageSizes;

  @override
  Widget build(BuildContext context) {
    final isDark = AdipsHelperFunctions.isDarkMode(context);
    final surface =
        isDark ? AdipsPalette.darkTextField : AdipsPalette.lightTextField;
    final line = isDark ? AdipsPalette.darkLine : AdipsPalette.lightLine;
    final muted =
        isDark ? AdipsPalette.darkTextMuted : AdipsPalette.lightTextMuted;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AdipsSizes.borderRadiusSm),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 2,
            child: isLoading ? const LinearProgressIndicator() : null,
          ),
          if (items.isEmpty)
            _Empty(
                hasFilters: hasFilters,
                onClear: onClearFilters,
                muted: muted)
          else
            LayoutBuilder(builder: (context, c) {
              if (c.maxWidth >= kTableMinWidth) {
                return _Table(
                  items: items,
                  sort: sort,
                  onToggleDateSort: onToggleDateSort,
                  onToggleAmountSort: onToggleAmountSort,
                  line: line,
                );
              }
              return Column(children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: line),
                  TransactionTile(item: items[i]),
                ],
              ]);
            }),
          Divider(height: 1, color: line),
          PaginationBar(
            info: pageInfo,
            pageSizes: pageSizes,
            onPage: onPage,
            onPageSize: onPageSize,
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(
      {required this.hasFilters, required this.onClear, required this.muted});

  final bool hasFilters;
  final VoidCallback? onClear;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(children: [
        Icon(Icons.receipt_long_outlined, size: 32, color: muted),
        const SizedBox(height: 8),
        Text(
          hasFilters
              ? 'No transactions match your filters'
              : 'No transactions yet',
          textAlign: TextAlign.center,
          style: TextStyle(color: muted, fontSize: 14),
        ),
        if (hasFilters && onClear != null)
          TextButton(onPressed: onClear, child: const Text('Clear filters')),
      ]),
    );
  }
}

// Column widths: fixed for the narrow ones, flex for the text ones.
const _dateW = 110.0;
const _statusW = 110.0;
const _amountW = 140.0;

class _Table extends StatelessWidget {
  const _Table({
    required this.items,
    required this.sort,
    required this.onToggleDateSort,
    required this.onToggleAmountSort,
    required this.line,
  });

  final List<AppTransaction> items;
  final SortOption sort;
  final VoidCallback onToggleDateSort;
  final VoidCallback onToggleAmountSort;
  final Color line;

  @override
  Widget build(BuildContext context) {
    final isDark = AdipsHelperFunctions.isDarkMode(context);
    final muted =
        isDark ? AdipsPalette.darkTextMuted : AdipsPalette.lightTextMuted;

    TextStyle head = TextStyle(
        fontSize: 12, fontWeight: FontWeight.w600, color: muted);

    Widget sortable(String label, bool active, bool descending,
            VoidCallback onTap, {Alignment align = Alignment.centerLeft}) =>
        InkWell(
          onTap: onTap,
          child: Align(
            alignment: align,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(label, style: head),
                const SizedBox(width: 2),
                Icon(
                  active
                      ? (descending
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded)
                      : Icons.unfold_more_rounded,
                  size: 14,
                  color: muted,
                ),
              ]),
            ),
          ),
        );

    final dateActive =
        sort == SortOption.newestFirst || sort == SortOption.oldestFirst;
    final amountActive = !dateActive;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AdipsSizes.md),
        child: Row(children: [
          SizedBox(
              width: _dateW,
              child: sortable('Date', dateActive,
                  sort == SortOption.newestFirst, onToggleDateSort)),
          Expanded(
              flex: 3,
              child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('Description', style: head))),
          Expanded(
              flex: 2,
              child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('Category', style: head))),
          Expanded(
              flex: 2,
              child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('Account', style: head))),
          SizedBox(
              width: _statusW,
              child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('Status', style: head))),
          SizedBox(
              width: _amountW,
              child: sortable('Amount', amountActive,
                  sort == SortOption.amountHighToLow, onToggleAmountSort,
                  align: Alignment.centerRight)),
        ]),
      ),
      for (final t in items) ...[
        Divider(height: 1, color: line),
        _TableRow(item: t),
      ],
    ]);
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({required this.item});

  final AppTransaction item;

  @override
  Widget build(BuildContext context) {
    final isDark = AdipsHelperFunctions.isDarkMode(context);
    final text =
        isDark ? AdipsPalette.darkTextPrimary : AdipsPalette.lightTextPrimary;
    final muted =
        isDark ? AdipsPalette.darkTextMuted : AdipsPalette.lightTextMuted;
    final gain = isDark ? AdipsPalette.darkGain : AdipsPalette.lightGain;
    final loss = isDark ? AdipsPalette.darkLoss : AdipsPalette.lightLoss;

    final color = item.categoryColorId > 0
        ? AdipsCategoryColors.byId(item.categoryColorId)
        : CategoryStyle.colorFor(item.category);
    final icon = item.categoryIconId > 0
        ? AdipsIcons.byId(item.categoryIconId)
        : CategoryStyle.iconFor(item.category);
    final income = item.isCredit;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AdipsSizes.md, vertical: 10),
      child: Row(children: [
        SizedBox(
          width: _dateW,
          child: Text(DateFormat('d MMM yyyy').format(item.transactionDate),
              style: TextStyle(fontSize: 13, color: muted)),
        ),
        Expanded(
          flex: 3,
          child: Row(children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(item.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: text)),
            ),
          ]),
        ),
        Expanded(
          flex: 2,
          child: Text(item.category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: text)),
        ),
        Expanded(
          flex: 2,
          child: Text(item.accountName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: muted)),
        ),
        SizedBox(width: _statusW, child: StatusChip(status: item.status)),
        SizedBox(
          width: _amountW,
          child: Text(
            '${income ? '+' : '-'} ${AdipsFormatters.money(item.amount, item.currency)}',
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: income ? gain : loss),
          ),
        ),
      ]),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isDark = AdipsHelperFunctions.isDarkMode(context);
    final color = switch (status) {
      'completed' => isDark ? AdipsPalette.darkGain : AdipsPalette.lightGain,
      'failed' => isDark ? AdipsPalette.darkLoss : AdipsPalette.lightLoss,
      _ => isDark ? AdipsPalette.darkCaution : AdipsPalette.lightCaution,
    };
    final label =
        status.isEmpty ? '' : status[0].toUpperCase() + status.substring(1);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, color: color)),
      ),
    );
  }
}

/// "Showing 1-10 of 123", rows per page, previous / next.
class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.info,
    required this.onPage,
    required this.onPageSize,
    this.pageSizes = const [10, 25, 50],
  });

  final TransactionPage info;
  final ValueChanged<int> onPage;
  final ValueChanged<int> onPageSize;
  final List<int> pageSizes;

  @override
  Widget build(BuildContext context) {
    final isDark = AdipsHelperFunctions.isDarkMode(context);
    final muted =
        isDark ? AdipsPalette.darkTextMuted : AdipsPalette.lightTextMuted;
    final style = TextStyle(fontSize: 12, color: muted);

    final summary = info.totalRecords == 0
        ? 'No results'
        : 'Showing ${info.firstRow}-${info.lastRow} of ${info.totalRecords}';

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AdipsSizes.md, vertical: AdipsSizes.xs),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 4,
        spacing: AdipsSizes.md,
        children: [
          Text(summary, style: style),
          Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
            Text('Rows per page', style: style),
            DropdownButton<int>(
              value: pageSizes.contains(info.limit) ? info.limit : null,
              isDense: true,
              underline: const SizedBox.shrink(),
              items: [
                for (final s in pageSizes)
                  DropdownMenuItem(value: s, child: Text('$s')),
              ],
              onChanged: (v) {
                if (v != null) onPageSize(v);
              },
            ),
            IconButton(
              tooltip: 'Previous page',
              icon: const Icon(Icons.chevron_left),
              onPressed: info.page > 1 ? () => onPage(info.page - 1) : null,
            ),
            Text('Page ${info.page} of ${info.totalPages}', style: style),
            IconButton(
              tooltip: 'Next page',
              icon: const Icon(Icons.chevron_right),
              onPressed:
                  info.page < info.totalPages ? () => onPage(info.page + 1) : null,
            ),
          ]),
        ],
      ),
    );
  }
}
