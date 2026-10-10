import 'package:get/get.dart';

import '../../utils/http/http_client.dart';
import '../../utils/local_storage/storage_utility.dart';
import '../../web/common/adips_toast.dart';

/// Session lifecycle for the web app.
class AuthSession {
  AuthSession._();

  static bool _expiring = false;

  /// Server rejected the saved token: clear it and go to login.
  /// Safe to call many times at once (parallel requests failing together).
  static Future<void> expire({
    String message = 'Your session has expired. Please sign in again.',
  }) async {
    if (_expiring) return;
    _expiring = true;
    try {
      await AdipsLocalStorage.clearToken();
      Get.offAllNamed('/login');
      AdipsToast.info(message);
    } finally {
      _expiring = false;
    }
  }

  /// Runs right after startup without blocking the first frame. If the saved
  /// token is invalid the global 401 hook (AdipsHttpHelper.onUnauthorized)
  /// calls [expire]. Timeouts / network errors are ignored on purpose: the
  /// backend may just be waking up (Render free tier), which does not mean
  /// the token is bad.
  static Future<void> validateInBackground() async {
    if (AdipsLocalStorage.token == null) return;
    try {
      final res = await AdipsHttpHelper.get(
        '/api/v1/users/validate',
        cookie: AdipsHttpHelper.authCookie,
        timeout: const Duration(seconds: 45),
      );
      final user = AdipsHttpHelper.data(res);
      await AdipsLocalStorage.saveCachedUser(
        (user['name'] ?? '').toString(),
        (user['email'] ?? '').toString(),
      );
    } catch (_) {
      // 401 handled globally; everything else: keep the session.
    }
  }
}
