import 'package:flutter/material.dart';

import '../../utils/constants/adips_palette.dart';
import '../../utils/helpers/helper_functions.dart';
import '../../utils/models/account_model.dart';
import '../../utils/models/date_range_option.dart';
import '../dashboard/dashboard_filters.dart';
import '../dashboard/transaction_view.dart' show SortOption;

/// A closed dropdown that lists [options] (value -> label); `null` is the
/// "everything" choice labelled [allLabel].
class OptionDropdown<T> extends StatelessWidget {
  const OptionDropdown({
    super.key,
    required this.icon,
    required this.allLabel,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.tooltip,
  });

  final IconData icon;
  final String allLabel;
  final Map<T, String> options;
  final T? selected;
  final ValueChanged<T?> onChanged;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final isDark = AdipsHelperFunctions.isDarkMode(context);
    final brand = isDark
        ? AdipsPalette.darkPrimaryBrandText
        : AdipsPalette.lightPrimaryBrandText;
    final text =
        isDark ? AdipsPalette.darkTextPrimary : AdipsPalette.lightTextPrimary;

    PopupMenuItem<int> row(int index, String label, bool checked) =>
        PopupMenuItem<int>(
          value: index,
          child: Row(children: [
            if (checked)
              Icon(Icons.check, size: 18, color: brand)
            else
              const SizedBox(width: 18),
            const SizedBox(width: 8),
            Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: text))),
          ]),
        );

    final keys = options.keys.toList();
    return PopupMenuButton<int>(
      tooltip: tooltip ?? allLabel,
      offset: const Offset(0, 48),
      onSelected: (i) => onChanged(i < 0 ? null : keys[i]),
      itemBuilder: (_) => [
        row(-1, allLabel, selected == null),
        for (var i = 0; i < keys.length; i++)
          row(i, options[keys[i]]!, selected == keys[i]),
      ],
      child: DropdownBox(
          icon: icon, label: selected == null ? allLabel : options[selected]!),
    );
  }
}

/// Filter bar for the Transactions page: search on its own row, the
/// dropdowns wrapping underneath.
class TransactionsFilters extends StatelessWidget {
  const TransactionsFilters({
    super.key,
    required this.search,
    required this.onSearchChanged,
    required this.accounts,
    required this.accountId,
    required this.onAccountChanged,
    required this.type,
    required this.onTypeChanged,
    required this.status,
    required this.onStatusChanged,
    required this.dateRange,
    required this.onDateRangeChanged,
    required this.sort,
    required this.onSortChanged,
  });

  final String search;
  final ValueChanged<String> onSearchChanged;
  final List<AccountModel> accounts;
  final int? accountId;
  final ValueChanged<int?> onAccountChanged;
  final String? type;
  final ValueChanged<String?> onTypeChanged;
  final String? status;
  final ValueChanged<String?> onStatusChanged;
  final DateRangeSelection? dateRange;
  final ValueChanged<DateRangeSelection?> onDateRangeChanged;
  final SortOption sort;
  final ValueChanged<SortOption> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TransactionSearchField(initialText: search, onChanged: onSearchChanged),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OptionDropdown<int>(
              icon: Icons.account_balance_wallet_outlined,
              allLabel: 'All accounts',
              options: {for (final a in accounts) a.id: a.name},
              selected: accountId,
              onChanged: onAccountChanged,
            ),
            OptionDropdown<String>(
              icon: Icons.swap_horiz_rounded,
              allLabel: 'Income & expenses',
              options: const {'credit': 'Income', 'debit': 'Expenses'},
              selected: type,
              onChanged: onTypeChanged,
            ),
            OptionDropdown<String>(
              icon: Icons.flag_outlined,
              allLabel: 'Any status',
              options: const {
                'completed': 'Completed',
                'pending': 'Pending',
                'failed': 'Failed',
              },
              selected: status,
              onChanged: onStatusChanged,
            ),
            DateRangeDropdown(selected: dateRange, onChanged: onDateRangeChanged),
            SortDropdown(selected: sort, onChanged: onSortChanged),
          ],
        ),
      ],
    );
  }
}
