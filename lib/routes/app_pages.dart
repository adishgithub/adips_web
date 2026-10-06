import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/local_storage/storage_utility.dart';
import '../web/auth/web_login_page.dart';
import '../web/common/coming_soon_page.dart';

/// Redirects to /login when there is no saved token. (A token that the
/// server later rejects with 401 is handled by the data layer in Phase 2.)
class AuthGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) =>
      AdipsLocalStorage.token == null ? const RouteSettings(name: '/login') : null;
}

/// Route map from the web plan (section 10). Each module is replaced by
/// its real page in the matching phase.
class AppPages {
  AppPages._();

  static const initial = '/dashboard';

  static GetPage<dynamic> _page(
          String path, String title, String phase) =>
      GetPage(
        name: path,
        middlewares: [AuthGuard()],
        page: () => ComingSoonPage(title: title, route: path, phase: phase),
      );

  static final pages = <GetPage<dynamic>>[
    GetPage(name: '/login', page: () => const WebLoginPage()),
    _page('/dashboard', 'Dashboard', 'Phase 3'),
    _page('/transactions', 'Transactions', 'Phase 4'),
    _page('/accounts', 'Accounts', 'Phase 6'),
    _page('/categories', 'Categories', 'Phase 7'),
    _page('/transaction-types', 'Transaction Types', 'Phase 7'),
    _page('/settings', 'Settings', 'Phase 8'),
    _page('/profile', 'Profile', 'Phase 8'),
  ];
}
