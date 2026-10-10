import 'package:flutter/material.dart';

import '../../utils/constants/adips_category_colors.dart';
import '../../utils/constants/adips_icons.dart';
import '../../utils/constants/adips_palette.dart';
import '../../utils/constants/sizes.dart';
import '../../utils/helpers/helper_functions.dart';
import '../../utils/models/account_model.dart';
import '../common/adaptive_grid.dart';

/// Account cards in a responsive grid (up to 4 columns). Tapping a card calls
/// [onTap]; the card for [selectedId] is highlighted. With no accounts and an
/// [onAddAccount], an "Add account" prompt is shown instead.
class AccountCardGrid extends StatelessWidget {
  const AccountCardGrid({
    super.key,
    required this.accounts,
    this.selectedId,
    this.onTap,
    this.onAddAccount,
  });

  final List<AccountModel> accounts;
  final int? selectedId;
  final ValueChanged<AccountModel>? onTap;
  final VoidCallback? onAddAccount;

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return onAddAccount == null
          ? const SizedBox.shrink()
          : _NoAccounts(onAdd: onAddAccount!);
    }
    return AdaptiveGrid(
      minItemWidth: 230,
      maxColumns: 4,
      children: [
        for (final a in accounts)
          AccountCard(
            account: a,
            isSelected: a.id == selectedId,
            onTap: onTap == null ? null : () => onTap!(a),
          ),
      ],
    );
  }
}

class AccountCard extends StatelessWidget {
  const AccountCard({
    super.key,
    required this.account,
    required this.isSelected,
    this.onTap,
  });

  final AccountModel account;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AdipsHelperFunctions.isDarkMode(context);
    final surface = isDark ? AdipsPalette.darkTextField : AdipsPalette.lightTextField;
    final line = isDark ? AdipsPalette.darkLine : AdipsPalette.lightLine;
    final text = isDark ? AdipsPalette.darkTextPrimary : AdipsPalette.lightTextPrimary;
    final muted = isDark ? AdipsPalette.darkTextMuted : AdipsPalette.lightTextMuted;
    final loss = isDark ? AdipsPalette.darkLoss : AdipsPalette.lightLoss;
    final brand = isDark ? AdipsPalette.darkPrimaryBrandText : AdipsPalette.lightPrimaryBrandText;
    final accent = AdipsCategoryColors.byId(account.colorId);
    final negative = account.currentBalance < 0;
    final radius = BorderRadius.circular(AdipsSizes.borderRadiusSm);

    return Opacity(
      opacity: account.includeInTotal ? 1 : 0.65,
      child: Material(
        color: surface,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            padding: const EdgeInsets.all(AdipsSizes.md),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: isSelected ? brand : line,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: accent.withValues(alpha: 0.15),
                      child: Icon(AdipsIcons.byId(account.iconId),
                          color: accent, size: 17),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(account.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: text)),
                    ),
                    if (account.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: brand.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Default',
                            style: TextStyle(fontSize: 10, color: brand)),
                      ),
                  ],
                ),
                const SizedBox(height: AdipsSizes.md),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AdipsFormatters.money(account.currentBalance, account.currency),
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: negative ? loss : text),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  account.includeInTotal
                      ? AccountTypeInfo.of(account.type).label
                      : '${AccountTypeInfo.of(account.type).label} · not included in total',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoAccounts extends StatelessWidget {
  const _NoAccounts({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final isDark = AdipsHelperFunctions.isDarkMode(context);
    final surface = isDark ? AdipsPalette.darkTextField : AdipsPalette.lightTextField;
    final line = isDark ? AdipsPalette.darkLine : AdipsPalette.lightLine;
    final muted = isDark ? AdipsPalette.darkTextMuted : AdipsPalette.lightTextMuted;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AdipsSizes.md),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AdipsSizes.borderRadiusSm),
        border: Border.all(color: line),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AdipsSizes.sm,
        children: [
          Icon(Icons.account_balance_wallet_outlined, color: muted),
          Text('No accounts yet. Add one to start tracking balances.',
              style: TextStyle(color: muted)),
          TextButton(onPressed: onAdd, child: const Text('Add account')),
        ],
      ),
    );
  }
}
