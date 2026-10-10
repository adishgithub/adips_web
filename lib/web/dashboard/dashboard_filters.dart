import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../utils/constants/adips_palette.dart';
import '../../utils/constants/sizes.dart';
import '../../utils/helpers/helper_functions.dart';
import '../../utils/models/date_range_option.dart';
import 'transaction_view.dart';

BoxDecoration _fieldDecoration(BuildContext context) {
  final isDark = AdipsHelperFunctions.isDarkMode(context);
  return BoxDecoration(
    color: isDark ? AdipsPalette.darkTextField : AdipsPalette.lightTextField,
    borderRadius: BorderRadius.circular(AdipsSizes.borderRadiusSm),
    border: Border.all(
        color: isDark ? AdipsPalette.darkLine : AdipsPalette.lightLine),
  );
}

/// Search box + date range + sort, in one responsive row (stacked on narrow
/// screens). All state lives in the controller; this only reports changes.
class DashboardFilters extends StatelessWidget {
  const DashboardFilters({
    super.key,
    required this.query,
    required this.onQueryChanged,
    required this.dateRange,
    required this.onDateRangeChanged,
    required this.sort,
    required this.onSortChanged,
  });

  final String query;
  final ValueChanged<String> onQueryChanged;

  /// null = all time.
  final DateRangeSelection? dateRange;
  final ValueChanged<DateRangeSelection?> onDateRangeChanged;
  final SortOption sort;
  final ValueChanged<SortOption> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 720;
      final search = TransactionSearchField(
        initialText: query,
        onChanged: onQueryChanged,
      );
      final date = DateRangeDropdown(
        selected: dateRange,
        onChanged: onDateRangeChanged,
      );
      final sortBox = SortDropdown(selected: sort, onChanged: onSortChanged);

      if (wide) {
        return Row(
          children: [
            Expanded(child: search),
            const SizedBox(width: AdipsSizes.sm),
            date,
            const SizedBox(width: AdipsSizes.sm),
            sortBox,
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          search,
          const SizedBox(height: AdipsSizes.sm),
          Row(children: [
            Expanded(child: date),
            const SizedBox(width: AdipsSizes.sm),
            Expanded(child: sortBox),
          ]),
        ],
      );
    });
  }
}

class TransactionSearchField extends StatefulWidget {
  const TransactionSearchField({
    super.key,
    required this.onChanged,
    this.initialText = '',
  });

  final String initialText;
  final ValueChanged<String> onChanged;

  @override
  State<TransactionSearchField> createState() => _TransactionSearchFieldState();
}

class _TransactionSearchFieldState extends State<TransactionSearchField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TransactionSearchField old) {
    super.didUpdateWidget(old);
    // "Clear filters" empties the query from outside: keep the box in sync.
    if (widget.initialText != _controller.text &&
        widget.initialText.isEmpty) {
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AdipsHelperFunctions.isDarkMode(context);
    final text =
        isDark ? AdipsPalette.darkTextPrimary : AdipsPalette.lightTextPrimary;
    final hint = isDark
        ? AdipsPalette.darkTextFieldPlaceHolderText
        : AdipsPalette.lightTextFieldPlaceHolderText;

    return Container(
      decoration: _fieldDecoration(context),
      child: TextField(
        controller: _controller,
        onChanged: (v) {
          setState(() {}); // refresh the clear button
          widget.onChanged(v);
        },
        style: TextStyle(fontSize: 14, color: text),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          hintText: 'Search transactions...',
          hintStyle: TextStyle(fontSize: 14, color: hint),
          prefixIcon: Icon(Icons.search_rounded, size: 20, color: hint),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: Icon(Icons.close_rounded, size: 18, color: hint),
                  onPressed: () {
                    _controller.clear();
                    setState(() {});
                    widget.onChanged('');
                  },
                ),
        ),
      ),
    );
  }
}

/// "This Month", "Last 30 Days", recent months, "All time" and a custom range.
class DateRangeDropdown extends StatelessWidget {
  const DateRangeDropdown(
      {super.key, required this.selected, required this.onChanged});

  final DateRangeSelection? selected;
  final ValueChanged<DateRangeSelection?> onChanged;

  static const _allTime = '__all__';
  static const _custom = '__custom__';

  Future<void> _pickCustom(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: selected?.range ??
          DateTimeRange(
              start: now.subtract(const Duration(days: 7)), end: now),
    );
    if (picked == null) return;
    final f = DateFormat.MMMd();
    onChanged(DateRangeSelection(
        label: '${f.format(picked.start)} - ${f.format(picked.end)}',
        range: picked));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AdipsHelperFunctions.isDarkMode(context);
    final brand = isDark
        ? AdipsPalette.darkPrimaryBrandText
        : AdipsPalette.lightPrimaryBrandText;
    final text =
        isDark ? AdipsPalette.darkTextPrimary : AdipsPalette.lightTextPrimary;
    final presets = DateRangeOptions.presets();

    Widget item(String value, String label, {bool checked = false}) =>
        Row(children: [
          if (checked)
            Icon(Icons.check, size: 18, color: brand)
          else
            const SizedBox(width: 18),
          const SizedBox(width: 8),
          Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: text))),
        ]);

    return PopupMenuButton<String>(
      tooltip: 'Date range',
      offset: const Offset(0, 48),
      onSelected: (value) {
        if (value == _custom) {
          _pickCustom(context);
        } else if (value == _allTime) {
          onChanged(null);
        } else {
          onChanged(presets.firstWhere((p) => p.label == value));
        }
      },
      itemBuilder: (_) => [
        for (final p in presets)
          PopupMenuItem(
              value: p.label,
              child: item(p.label, p.label, checked: selected?.label == p.label)),
        PopupMenuItem(
            value: _allTime,
            child: item(_allTime, 'All time', checked: selected == null)),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _custom,
          child: Row(children: [
            Icon(Icons.date_range, size: 18, color: brand),
            const SizedBox(width: 8),
            Text('Custom Range', style: TextStyle(color: text)),
          ]),
        ),
      ],
      child: _DropdownBox(
          icon: Icons.calendar_today_outlined,
          label: selected?.label ?? 'All time'),
    );
  }
}

class SortDropdown extends StatelessWidget {
  const SortDropdown({super.key, required this.selected, required this.onChanged});

  final SortOption selected;
  final ValueChanged<SortOption> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = AdipsHelperFunctions.isDarkMode(context);
    final brand = isDark
        ? AdipsPalette.darkPrimaryBrandText
        : AdipsPalette.lightPrimaryBrandText;
    final text =
        isDark ? AdipsPalette.darkTextPrimary : AdipsPalette.lightTextPrimary;

    return PopupMenuButton<SortOption>(
      tooltip: 'Sort',
      offset: const Offset(0, 48),
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final o in SortOption.values)
          PopupMenuItem(
            value: o,
            child: Row(children: [
              if (selected == o)
                Icon(Icons.check, size: 18, color: brand)
              else
                const SizedBox(width: 18),
              const SizedBox(width: 8),
              Flexible(
                  child: Text(o.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: text))),
            ]),
          ),
      ],
      child: _DropdownBox(icon: Icons.swap_vert_rounded, label: selected.label),
    );
  }
}

class _DropdownBox extends StatelessWidget {
  const _DropdownBox({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = AdipsHelperFunctions.isDarkMode(context);
    final brand = isDark
        ? AdipsPalette.darkPrimaryBrandText
        : AdipsPalette.lightPrimaryBrandText;
    final text =
        isDark ? AdipsPalette.darkTextPrimary : AdipsPalette.lightTextPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: _fieldDecoration(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: brand),
          const SizedBox(width: 8),
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14, color: text)),
          ),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: brand),
        ],
      ),
    );
  }
}
