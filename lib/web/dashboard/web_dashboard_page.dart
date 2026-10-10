import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/constants/sizes.dart';
import '../layout/web_shell.dart';
import 'account_card_grid.dart';
import 'balance_card.dart';
import 'dashboard_controller.dart';
import 'dashboard_filters.dart';
import 'recent_transactions.dart';
import 'stat_cards.dart';

/// /dashboard: total balance, income/expense/count cards, the account grid
/// (Patch 05) and search / date range / sort over the recent transactions
/// (Patch 06).
class WebDashboardPage extends StatelessWidget {
  const WebDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<DashboardController>();
    return WebShell(
      title: 'Dashboard',
      route: '/dashboard',
      child: Obx(() {
        if (c.loadError.value != null) {
          return DashboardErrorView(
              message: c.loadError.value!, onRetry: c.loadAll);
        }
        if (c.isLoading.value && !c.hasLoaded) {
          return const DashboardLoadingView();
        }
        return RefreshIndicator(
          onRefresh: c.reload,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AdipsSizes.lg),
            child: DashboardBody(controller: c),
          ),
        );
      }),
    );
  }
}

class DashboardLoadingView extends StatelessWidget {
  const DashboardLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AdipsSizes.md),
          Text(
            'Loading… the server may take up to 30 seconds to wake up.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class DashboardErrorView extends StatelessWidget {
  const DashboardErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.title = 'Could not load your dashboard',
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AdipsSizes.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 48),
              const SizedBox(height: AdipsSizes.md),
              Text(title,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AdipsSizes.sm),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: AdipsSizes.lg),
              ElevatedButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      ),
    );
  }
}

/// The dashboard content. Public so Patch 06 can extend it and tests can
/// pump it with a controller.
class DashboardBody extends StatelessWidget {
  const DashboardBody({super.key, required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Obx(() {
      final selected = c.selectedAccount;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (c.isRefreshing.value) ...[
            const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: AdipsSizes.sm),
          ],
          if (c.refreshError.value != null) ...[
            _ErrorBanner(message: c.refreshError.value!, onRetry: c.reload),
            const SizedBox(height: AdipsSizes.md),
          ],
          BalanceCard(
            totals: c.accountSummary.value.totals,
            fallbackCurrency: c.statsCurrency,
          ),
          const SizedBox(height: AdipsSizes.lg),
          if (selected != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AdipsSizes.sm),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AdipsSizes.sm,
                children: [
                  Text('Showing figures for ${selected.name}'),
                  TextButton(
                    onPressed: () => c.selectAccount(null),
                    child: const Text('Show all'),
                  ),
                ],
              ),
            ),
          StatCards(
            totalIncome: c.stats.value.totalCredit,
            totalExpenses: c.stats.value.totalDebit,
            totalTransactions: c.stats.value.count,
            currency: c.statsCurrency,
          ),
          const SizedBox(height: AdipsSizes.lg),
          Text('Accounts', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AdipsSizes.sm),
          AccountCardGrid(
            accounts: c.accounts.toList(),
            selectedId: c.selectedAccountId.value,
            onTap: (a) => c.selectAccount(a.id),
            onAddAccount: () => Get.toNamed('/accounts'),
          ),
          const SizedBox(height: AdipsSizes.lg),
          DashboardFilters(
            query: c.searchQuery.value,
            onQueryChanged: c.setSearchQuery,
            dateRange: c.dateRange.value,
            onDateRangeChanged: c.setDateRange,
            sort: c.sortOption.value,
            onSortChanged: c.setSortOption,
          ),
          const SizedBox(height: AdipsSizes.md),
          RecentTransactions(
            items: c.visibleItems,
            // Only "filtered" when there is something to filter out.
            hasFilters: c.transactions.isNotEmpty &&
                (c.searchQuery.value.trim().isNotEmpty ||
                    c.dateRange.value != null),
            onClearFilters: c.clearFilters,
            onViewAll: () => Get.toNamed('/transactions'),
          ),
        ],
      );
    });
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AdipsSizes.sm),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(AdipsSizes.borderRadiusSm),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AdipsSizes.sm,
        children: [
          Icon(Icons.error_outline, color: scheme.onErrorContainer, size: 18),
          Text(message, style: TextStyle(color: scheme.onErrorContainer)),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
