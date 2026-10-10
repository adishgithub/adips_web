import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/constants/sizes.dart';
import '../dashboard/web_dashboard_page.dart'
    show DashboardErrorView, DashboardLoadingView;
import '../layout/web_shell.dart';
import 'transactions_controller.dart';
import 'transactions_filters.dart';
import 'transactions_results.dart';

/// /transactions: every transaction, with server-side search, filters, sort
/// and paging. (Add / edit / delete come in Patch 08.)
class WebTransactionsPage extends StatelessWidget {
  const WebTransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TransactionsController>();
    return WebShell(
      title: 'Transactions',
      route: '/transactions',
      child: Obx(() {
        // Only replace the page when there is nothing to show yet; after
        // that a failure keeps the filters on screen.
        if (c.loadError.value != null && !c.hasLoaded) {
          return DashboardErrorView(
            title: 'Could not load your transactions',
            message: c.loadError.value!,
            onRetry: c.fetch,
          );
        }
        if (!c.hasLoaded) return const DashboardLoadingView();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AdipsSizes.lg),
          child: TransactionsBody(controller: c),
        );
      }),
    );
  }
}

class TransactionsBody extends StatelessWidget {
  const TransactionsBody({super.key, required this.controller});

  final TransactionsController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TransactionsFilters(
              search: c.search.value,
              onSearchChanged: c.setSearch,
              accounts: c.accounts.toList(),
              accountId: c.accountId.value,
              onAccountChanged: c.setAccount,
              type: c.type.value,
              onTypeChanged: c.setType,
              status: c.status.value,
              onStatusChanged: c.setStatus,
              dateRange: c.dateRange.value,
              onDateRangeChanged: c.setDateRange,
              sort: c.sort.value,
              onSortChanged: c.setSort,
            ),
            if (c.loadError.value != null) ...[
              const SizedBox(height: AdipsSizes.sm),
              _ErrorLine(message: c.loadError.value!, onRetry: c.fetch),
            ],
            const SizedBox(height: AdipsSizes.md),
            TransactionsResults(
              items: c.items.toList(),
              pageInfo: c.pageInfo.value,
              sort: c.sort.value,
              hasFilters: c.hasFilters,
              isLoading: c.isLoading.value,
              onToggleDateSort: c.toggleDateSort,
              onToggleAmountSort: c.toggleAmountSort,
              onPage: c.goToPage,
              onPageSize: c.setPageSize,
              onClearFilters: c.clearFilters,
              pageSizes: TransactionsController.pageSizes,
            ),
          ],
        ));
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine({required this.message, required this.onRetry});

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
