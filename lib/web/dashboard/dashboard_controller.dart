import 'package:get/get.dart';

import '../../data/services/account_service.dart';
import '../../utils/http/http_client.dart';
import '../../utils/models/account_model.dart';
import '../../utils/models/app_transaction.dart';
import '../../utils/models/date_range_option.dart';
import '../../utils/models/home_list_item.dart';
import '../../utils/services/transaction_api.dart';
import 'transaction_view.dart';

/// State for the dashboard: balances, stat cards, accounts (Patch 05) and the
/// recent-transactions list with search / sort / date range (Patch 06).
/// Widgets only read this; all HTTP goes through the existing services.
class DashboardController extends GetxController {
  final AccountService _accounts = AccountService();

  final RxList<AccountModel> accounts = <AccountModel>[].obs;
  final Rx<AccountSummaryModel> accountSummary =
      AccountSummaryModel.empty.obs;
  final Rx<TransactionSummary> stats = TransactionSummary.empty.obs;

  /// Fetched transactions (newest first from the API, for the selected
  /// account or all). Search / sort / date range are applied locally.
  final RxList<AppTransaction> transactions = <AppTransaction>[].obs;
  final RxString searchQuery = ''.obs;
  final Rx<SortOption> sortOption = SortOption.newestFirst.obs;

  /// null = all time. Starts on "This Month" so the label the filter shows
  /// is the filter that is actually applied.
  final Rx<DateRangeSelection?> dateRange =
      Rx<DateRangeSelection?>(DateRangeOptions.presets().first);

  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs; // quiet reload / filter change
  final RxnString loadError = RxnString();
  final RxnString refreshError = RxnString();
  final RxnInt selectedAccountId = RxnInt();

  bool _loadedOnce = false;
  bool get hasLoaded => _loadedOnce;
  int _seq = 0; // ignores out-of-order responses

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  AccountModel? byId(int id) {
    for (final a in accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  AccountModel? get selectedAccount {
    final id = selectedAccountId.value;
    return id == null ? null : byId(id);
  }

  AccountModel? get defaultAccount {
    if (accounts.isEmpty) return null;
    return accounts.firstWhere((a) => a.isDefault,
        orElse: () => accounts.first);
  }

  /// Currency of the income/expense figures: the selected account's, else the
  /// first total's (same rule as mobile; totals are never converted).
  String get statsCurrency {
    final selected = selectedAccount;
    if (selected != null) return selected.currency;
    final totals = accountSummary.value.totals;
    if (totals.isNotEmpty) return totals.first.currency;
    return defaultAccount?.currency ?? 'INR';
  }

  /// First load / "Try again": shows the full-page spinner. Uses the long
  /// cold-start timeout because the free Render server may be asleep.
  Future<void> loadAll() async {
    final seq = ++_seq;
    var dropped = false;
    isLoading.value = true;
    loadError.value = null;
    try {
      const timeout = AdipsHttpHelper.coldStartTimeout;
      final results = await Future.wait<Object>([
        _accounts.list(timeout: timeout),
        _accounts.summary(timeout: timeout),
        TransactionApi.summary(
            accountId: selectedAccountId.value, timeout: timeout),
        _fetchTransactions(selectedAccountId.value, timeout: timeout),
      ]);
      if (seq != _seq) return;
      accounts.assignAll(results[0] as List<AccountModel>);
      accountSummary.value = results[1] as AccountSummaryModel;
      stats.value = results[2] as TransactionSummary;
      transactions.assignAll(results[3] as List<AppTransaction>);
      _loadedOnce = true;
      dropped = _dropStaleSelection();
    } catch (e) {
      if (seq != _seq) return;
      loadError.value = _message(e);
    } finally {
      if (seq == _seq) isLoading.value = false;
    }
    if (dropped) await reload();
  }

  /// Quiet reload (no spinner): after changes made elsewhere. A failure keeps
  /// the old numbers and sets [refreshError] for an inline banner.
  Future<void> reload() async {
    final seq = ++_seq;
    var dropped = false;
    isRefreshing.value = true;
    refreshError.value = null;
    try {
      final results = await Future.wait<Object>([
        _accounts.list(),
        _accounts.summary(),
        TransactionApi.summary(accountId: selectedAccountId.value),
        _fetchTransactions(selectedAccountId.value),
      ]);
      if (seq != _seq) return;
      accounts.assignAll(results[0] as List<AccountModel>);
      accountSummary.value = results[1] as AccountSummaryModel;
      stats.value = results[2] as TransactionSummary;
      transactions.assignAll(results[3] as List<AppTransaction>);
      dropped = _dropStaleSelection();
    } catch (e) {
      if (seq != _seq) return;
      refreshError.value = _message(e);
    } finally {
      if (seq == _seq) isRefreshing.value = false;
    }
    if (dropped) await reload();
  }

  /// Tap an account to filter the stat cards to it; tap it again (or pass
  /// null) to go back to all accounts. Balances never depend on the filter.
  Future<void> selectAccount(int? id) async {
    final previous = selectedAccountId.value;
    final next = id == previous ? null : id;
    if (next == previous) return;

    selectedAccountId.value = next; // highlight immediately
    final seq = ++_seq;
    isRefreshing.value = true;
    refreshError.value = null;
    try {
      final results = await Future.wait<Object>([
        TransactionApi.summary(accountId: next),
        _fetchTransactions(next),
      ]);
      if (seq != _seq) return;
      stats.value = results[0] as TransactionSummary;
      transactions.assignAll(results[1] as List<AppTransaction>);
    } catch (e) {
      if (seq != _seq) return;
      selectedAccountId.value = previous; // highlight = data shown
      refreshError.value = _message(e);
    } finally {
      if (seq == _seq) isRefreshing.value = false;
    }
  }

  Future<List<AppTransaction>> _fetchTransactions(int? accountId,
          {Duration timeout = AdipsHttpHelper.defaultTimeout}) =>
      TransactionApi.list(
        sortBy: 'transaction_date',
        order: 'desc',
        accountId: accountId,
        timeout: timeout,
      );

  // ---- Local search / sort / date range over the fetched list ---------

  void setSearchQuery(String value) => searchQuery.value = value;
  void setSortOption(SortOption value) => sortOption.value = value;
  void setDateRange(DateRangeSelection? value) => dateRange.value = value;

  /// Search emptied and date range widened to all time.
  void clearFilters() {
    searchQuery.value = '';
    dateRange.value = null;
  }

  /// Rows for the list after collapse / search / date range / sort.
  List<HomeListItem> get visibleItems => buildVisibleItems(
        transactions: transactions,
        collapseTransfers: selectedAccountId.value == null,
        query: searchQuery.value,
        range: dateRange.value?.range,
        sort: sortOption.value,
      );

  /// If the filtered account is gone (archived/deleted elsewhere), go back to
  /// "All". Returns true when that happened, so the caller reloads the stats.
  bool _dropStaleSelection() {
    final id = selectedAccountId.value;
    if (id != null && byId(id) == null) {
      selectedAccountId.value = null;
      return true;
    }
    return false;
  }

  static String _message(Object e) =>
      e.toString().replaceFirst('Exception: ', '');
}
