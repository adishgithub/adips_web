import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../utils/constants/adips_category_colors.dart';
import '../../utils/constants/adips_icons.dart';
import '../../utils/constants/adips_palette.dart';
import '../../utils/constants/sizes.dart';
import '../../utils/helpers/category_style.dart';
import '../../utils/helpers/helper_functions.dart';
import '../../utils/models/app_transaction.dart';
import '../../utils/models/home_list_item.dart';

/// Read-only list of the latest rows on the dashboard. At most [limit] are
/// shown; the full list with paging arrives with the Transactions page
/// (Patch 07), which [onViewAll] opens. Editing arrives in Patch 08.
class RecentTransactions extends StatelessWidget {
  const RecentTransactions({
    super.key,
    required this.items,
    this.limit = 20,
    this.hasFilters = false,
    this.onClearFilters,
    this.onViewAll,
  });

  final List<HomeListItem> items;
  final int limit;

  /// True when a search or date range is narrowing the list, so an empty
  /// result reads "nothing matches" instead of "no transactions yet".
  final bool hasFilters;
  final VoidCallback? onClearFilters;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final isDark = AdipsHelperFunctions.isDarkMode(context);
    final surface =
        isDark ? AdipsPalette.darkTextField : AdipsPalette.lightTextField;
    final line = isDark ? AdipsPalette.darkLine : AdipsPalette.lightLine;
    final muted =
        isDark ? AdipsPalette.darkTextMuted : AdipsPalette.lightTextMuted;

    final shown = items.take(limit).toList();

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AdipsSizes.borderRadiusSm),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AdipsSizes.md, AdipsSizes.md, AdipsSizes.md, AdipsSizes.sm),
            child: Row(children: [
              Expanded(
                child: Text('Recent transactions',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              if (items.isNotEmpty)
                Text(
                  items.length > shown.length
                      ? 'Showing ${shown.length} of ${items.length}'
                      : '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                  style: TextStyle(fontSize: 12, color: muted),
                ),
            ]),
          ),
          Divider(height: 1, color: line),
          if (items.isEmpty)
            _Empty(
                hasFilters: hasFilters,
                onClearFilters: onClearFilters,
                muted: muted)
          else
            for (var i = 0; i < shown.length; i++) ...[
              if (i > 0) Divider(height: 1, color: line),
              switch (shown[i]) {
                TransactionRow(:final transaction) =>
                  TransactionTile(item: transaction),
                final TransferRow row => TransferTile(row: row),
              },
            ],
          if (items.length > shown.length && onViewAll != null) ...[
            Divider(height: 1, color: line),
            TextButton(
              onPressed: onViewAll,
              child: const Text('View all transactions'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(
      {required this.hasFilters, required this.onClearFilters, required this.muted});

  final bool hasFilters;
  final VoidCallback? onClearFilters;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 32, color: muted),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? 'No transactions match your search or date range'
                : 'No transactions yet',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 14),
          ),
          if (hasFilters && onClearFilters != null)
            TextButton(
                onPressed: onClearFilters, child: const Text('Clear filters')),
        ],
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.item});

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

    final income = item.isCredit;
    // Use the icon/colour snapshot saved with the transaction; fall back to
    // guessing from the name for old rows that have none (id 0).
    final color = item.categoryColorId > 0
        ? AdipsCategoryColors.byId(item.categoryColorId)
        : CategoryStyle.colorFor(item.category);
    final icon = item.categoryIconId > 0
        ? AdipsIcons.byId(item.categoryIconId)
        : CategoryStyle.iconFor(item.category);

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AdipsSizes.md, vertical: 12),
      child: Row(
        children: [
          _Avatar(icon: icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: text)),
                const SizedBox(height: 2),
                Text(
                  [
                    DateFormat('d MMM yyyy').format(item.transactionDate),
                    item.category,
                    if (item.accountName.isNotEmpty) item.accountName,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${income ? '+' : '-'} ${AdipsFormatters.money(item.amount, item.currency)}',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: income ? gain : loss),
              ),
              if (item.status != 'completed')
                Text(item.status,
                    style: TextStyle(fontSize: 10, color: muted)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Both legs of one transfer as a single "A → B" row, neutral colour.
class TransferTile extends StatelessWidget {
  const TransferTile({super.key, required this.row});

  final TransferRow row;

  @override
  Widget build(BuildContext context) {
    final isDark = AdipsHelperFunctions.isDarkMode(context);
    final text =
        isDark ? AdipsPalette.darkTextPrimary : AdipsPalette.lightTextPrimary;
    final muted =
        isDark ? AdipsPalette.darkTextMuted : AdipsPalette.lightTextMuted;
    final neutral =
        isDark ? AdipsPalette.darkAction : AdipsPalette.lightAction;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AdipsSizes.md, vertical: 12),
      child: Row(
        children: [
          _Avatar(icon: Icons.swap_horiz_rounded, color: neutral),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${row.debit.accountName} \u2192 ${row.credit.accountName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: text)),
                const SizedBox(height: 2),
                Text('${DateFormat('d MMM yyyy').format(row.date)} · Transfer',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: muted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(AdipsFormatters.money(row.amount, row.currency),
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: text)),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}
