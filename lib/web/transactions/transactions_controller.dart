import 'dart:async';

import 'package:get/get.dart';

import '../../data/services/account_service.dart';
import '../../utils/http/http_client.dart';
import '../../utils/models/account_model.dart';
import '../../utils/models/app_transaction.dart';
import '../../utils/models/date_range_option.dart';
import '../dashboard/transaction_view.dart' show SortOption;
import 'transactions_query.dart';

/// State for /transactions: filters, sort and paging are sent to the server;
/// this controller only keeps the current page and the filter values.
class TransactionsController extends GetxController {
  TransactionsController({this.searchDebounce = const Duration(milliseconds: 400)});

  /// Wait this long after the last keystroke before searching.
  final Duration searchDebounce;

  static const pageSizes = [10, 25, 50];

  final TransactionListService _service = TransactionListService();
  final AccountService _accountService = AccountService();

  // Results
  final RxList<AppTransaction> items = <AppTransaction>[].obs;
  final Rx<TransactionPage> pageInfo = TransactionPage.empty.obs;
  final RxBool isLoading = false.obs;
  final RxnString loadError = RxnString();

  /// True after the first successful load. Reactive on purpose: the page
  /// reads it inside an Obx, which must rebuild when it flips.
  final RxBool loaded = false.obs;
  bool get hasLoaded => loaded.value;

  // Filters
  final RxList<AccountModel> accounts = <AccountModel>[].obs;
  final RxString search = ''.obs;
  final RxnString type = RxnString();
  final RxnString status = RxnString();
  final RxnInt accountId = RxnInt();
  final Rx<DateRangeSelection?> dateRange = Rx<DateRangeSelection?>(null);
  final Rx<SortOption> sort = SortOption.newestFirst.obs;
  final RxInt page = 1.obs;
  final RxInt pageSize = 10.obs;

  Timer? _debounce;
  int _seq = 0; // ignores out-of-order responses

  @override
  void onInit() {
    super.onInit();
    _loadAccounts();
    fetch(timeout: AdipsHttpHelper.coldStartTimeout);
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  TransactionQuery get query => TransactionQuery(
        page: page.value,
        limit: pageSize.value,
        sort: sort.value,
        search: search.value,
        type: type.value,
        status: status.value,
        accountId: accountId.value,
        range: dateRange.value?.range,
      );

  bool get hasFilters =>
      search.value.trim().isNotEmpty ||
      type.value != null ||
      status.value != null ||
      accountId.value != null ||
      dateRange.value != null;

  Future<void> _loadAccounts() async {
    try {
      accounts.assignAll(await _accountService.list());
    } catch (_) {
      // The account filter just stays empty; the list itself still works.
    }
  }

  Future<void> fetch({Duration timeout = AdipsHttpHelper.defaultTimeout}) async {
    final seq = ++_seq;
    isLoading.value = true;
    loadError.value = null;
    var lastPage = 0;
    try {
      final result = await _service.fetch(query, timeout: timeout);
      if (seq != _seq) return;
      // Rows were removed elsewhere and this page no longer exists.
      if (result.items.isEmpty && page.value > 1 && result.totalPages < page.value) {
        lastPage = result.totalPages;
      } else {
        items.assignAll(result.items);
        pageInfo.value = result;
        loaded.value = true;
      }
    } catch (e) {
      if (seq != _seq) return;
      loadError.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (seq == _seq) isLoading.value = false;
    }
    if (lastPage > 0) {
      page.value = lastPage;
      await fetch();
    }
  }

  // ---- Filter changes: back to page 1 and ask the server again --------

  void _changed() {
    page.value = 1;
    fetch();
  }

  /// Typing: wait for a pause, then search.
  void setSearch(String value) {
    search.value = value;
    _debounce?.cancel();
    _debounce = Timer(searchDebounce, _changed);
  }

  void setType(String? value) {
    type.value = value;
    _changed();
  }

  void setStatus(String? value) {
    status.value = value;
    _changed();
  }

  void setAccount(int? value) {
    accountId.value = value;
    _changed();
  }

  void setDateRange(DateRangeSelection? value) {
    dateRange.value = value;
    _changed();
  }

  void setSort(SortOption value) {
    sort.value = value;
    _changed();
  }

  /// Column header clicks: date flips newest/oldest, amount flips high/low.
  void toggleDateSort() => setSort(sort.value == SortOption.newestFirst
      ? SortOption.oldestFirst
      : SortOption.newestFirst);

  void toggleAmountSort() => setSort(sort.value == SortOption.amountHighToLow
      ? SortOption.amountLowToHigh
      : SortOption.amountHighToLow);

  void clearFilters() {
    _debounce?.cancel();
    search.value = '';
    type.value = null;
    status.value = null;
    accountId.value = null;
    dateRange.value = null;
    _changed();
  }

  // ---- Paging ----------------------------------------------------------

  void goToPage(int value) {
    final last = pageInfo.value.totalPages;
    final target = value.clamp(1, last < 1 ? 1 : last);
    // After a failed load the same page is allowed again (acts as a retry).
    if (target == page.value && loadError.value == null) return;
    page.value = target;
    fetch();
  }

  void setPageSize(int value) {
    if (value == pageSize.value) return;
    pageSize.value = value;
    _changed();
  }
}
