import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme_mode_store.dart';
import '../../utils/http/http_client.dart';
import '../../utils/local_storage/storage_utility.dart';

/// Top bar: page title, theme toggle and the profile menu (with logout).
class WebHeader extends StatelessWidget implements PreferredSizeWidget {
  const WebHeader({super.key, required this.title, this.showMenuButton = false});

  final String title;

  /// Mobile layout: show a hamburger that opens the drawer.
  final bool showMenuButton;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = AdipsLocalStorage.cachedFullName ?? '';
    final email = AdipsLocalStorage.cachedEmail ?? '';
    return Material(
      color: scheme.surface,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: scheme.outlineVariant))),
          child: Row(children: [
            if (showMenuButton)
              IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Menu',
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            Expanded(
              child: Text(title,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
            IconButton(
              tooltip: 'Toggle theme',
              icon: Icon(Get.isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: ThemeModeStore.toggle,
            ),
            PopupMenuButton<String>(
              tooltip: 'Profile',
              onSelected: (v) {
                if (v == 'profile') Get.offAllNamed('/profile');
                if (v == 'logout') _logout();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  enabled: false,
                  child: Text(name.isEmpty ? email : '$name\n$email'),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'profile', child: Text('Profile')),
                const PopupMenuItem(value: 'logout', child: Text('Log out')),
              ],
              child: CircleAvatar(
                radius: 18,
                backgroundColor: scheme.primary,
                child: Text(
                  (name.isNotEmpty ? name : email).characters.firstOrNull
                          ?.toUpperCase() ??
                      '?',
                  style: TextStyle(color: scheme.onPrimary),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  static Future<void> logout() => _logout();

  static Future<void> _logout() async {
    try {
      await AdipsHttpHelper.post('/api/v1/users/logout', {},
          cookie: AdipsHttpHelper.authCookie);
    } catch (_) {
      // Logging out locally must work even if the server is unreachable.
    }
    await AdipsLocalStorage.clearToken();
    Get.offAllNamed('/login');
  }
}
