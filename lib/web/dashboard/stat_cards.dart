import 'package:flutter/material.dart';

import '../../utils/constants/adips_palette.dart';
import '../../utils/constants/sizes.dart';
import '../../utils/helpers/helper_functions.dart';
import '../common/adaptive_grid.dart';

/// Income / expenses / transaction count (from /transactions/summary).
class StatCards extends StatelessWidget {
  const StatCards({
    super.key,
    required this.totalIncome,
    required this.totalExpenses,
    required this.totalTransactions,
    this.currency = 'INR',
  });

  final double totalIncome;
  final double totalExpenses;
  final int totalTransactions;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final isDark = AdipsHelperFunctions.isDarkMode(context);
    final gain = isDark ? AdipsPalette.darkGain : AdipsPalette.lightGain;
    final loss = isDark ? AdipsPalette.darkLoss : AdipsPalette.lightLoss;
    final action = isDark ? AdipsPalette.darkAction : AdipsPalette.lightAction;
    final text = isDark ? AdipsPalette.darkTextPrimary : AdipsPalette.lightTextPrimary;

    return AdaptiveGrid(
      minItemWidth: 220,
      maxColumns: 3,
      children: [
        _StatCard(
          icon: Icons.trending_up_rounded,
          color: gain,
          label: 'Total Income',
          value: AdipsFormatters.money(totalIncome, currency),
          valueColor: gain,
        ),
        _StatCard(
          icon: Icons.trending_down_rounded,
          color: loss,
          label: 'Total Expenses',
          value: AdipsFormatters.money(totalExpenses, currency),
          valueColor: loss,
        ),
        _StatCard(
          icon: Icons.description_outlined,
          color: action,
          label: 'Total Transactions',
          value: '$totalTransactions',
          valueColor: text,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final isDark = AdipsHelperFunctions.isDarkMode(context);
    final surface = isDark ? AdipsPalette.darkTextField : AdipsPalette.lightTextField;
    final line = isDark ? AdipsPalette.darkLine : AdipsPalette.lightLine;
    final muted = isDark ? AdipsPalette.darkTextMuted : AdipsPalette.lightTextMuted;

    return Container(
      padding: const EdgeInsets.all(AdipsSizes.md),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AdipsSizes.borderRadiusSm),
        border: Border.all(color: line),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: AdipsSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: muted)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value,
                      maxLines: 1,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: valueColor)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
