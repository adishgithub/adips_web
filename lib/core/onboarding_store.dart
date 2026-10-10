import 'package:get_storage/get_storage.dart';

/// Remembers (in browser storage) that this browser already saw onboarding,
/// so returning visitors go straight to /login.
class OnboardingStore {
  OnboardingStore._();

  static const _key = 'onboarding_seen';
  static final _box = GetStorage();

  static bool get seen => _box.read<bool>(_key) ?? false;

  static Future<void> markSeen() => _box.write(_key, true);
}
