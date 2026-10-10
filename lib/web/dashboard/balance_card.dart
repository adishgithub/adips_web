import 'package:flutter/material.dart';

import '../../utils/constants/adips_palette.dart';
import '../../utils/constants/sizes.dart';
import '../../utils/helpers/helper_functions.dart';
import '../../utils/models/account_model.dart';

/// Total balance of the accounts counted in the total (from
/// /accounts/summary). Totals are per currency and never added together: the
/// first is the headline, others are smaller lines below it.
class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.totals,
    this.fallbackCurrency = 'INR',
  });

  final List<AccountSummaryTotal> totals;
  final String fallbackCurrency;

  @override
  Widget build(BuildContext context) {
    final primary = totals.isNotEmpty
        ? totals.first
        : AccountSummaryTotal(currency: fallbackCurrency, totalBalance: 0);
    final others = totals.length > 1 ? totals.sublist(1) : const <AccountSummaryTotal>[];

    return ClipRRect(
      borderRadius: BorderRadius.circular(AdipsSizes.borderRadiusSm),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AdipsSizes.lg),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AdipsPalette.darkPrimaryBrandText,
              AdipsPalette.lightPrimaryBrandText,
            ],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              right: -10,
              bottom: -24,
              child: Opacity(
                opacity: 0.15,
                child: const Icon(Icons.account_balance,
                    size: 140, color: Colors.white),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Balance',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: AdipsSizes.fontSizesSm,
                  ),
                ),
                const SizedBox(height: AdipsSizes.xs),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AdipsFormatters.money(primary.totalBalance, primary.currency),
                    key: const Key('total-balance'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                for (final other in others) ...[
                  const SizedBox(height: 4),
                  Text(
                    '+ ${AdipsFormatters.money(other.totalBalance, other.currency)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
