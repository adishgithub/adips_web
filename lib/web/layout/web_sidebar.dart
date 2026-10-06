import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'web_nav_items.dart';

/// Navigation list used by the persistent sidebar (desktop), the icon
/// rail (tablet, [collapsed] = true) and the drawer (mobile).
class WebSidebar extends StatelessWidget {
  const WebSidebar({
    super.key,
    required this.currentRoute,
    this.collapsed = false,
    this.onNavigate,
  });

  final String currentRoute;
  final bool collapsed;

  /// Called after a destination is chosen (lets the drawer close itself).
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: collapsed ? 72 : 248,
      color: scheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: collapsed ? 0 : 20, vertical: 20),
              child: collapsed
                  ? Icon(Icons.account_balance, color: scheme.primary)
                  : Row(children: [
                      Icon(Icons.account_balance, color: scheme.primary),
                      const SizedBox(width: 10),
                      Text('ADIPS',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  for (final item in webNavItems)
                    _NavTile(
                      item: item,
                      selected: currentRoute == item.route ||
                          (item.route == '/transactions' &&
                              currentRoute.startsWith('/transactions/')),
                      collapsed: collapsed,
                      onTap: () {
                        onNavigate?.call();
                        if (currentRoute != item.route) {
                          Get.offAllNamed(item.route);
                        }
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });

  final WebNavItem item;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurface;
    final tile = Material(
      color: selected ? scheme.primary.withValues(alpha: 0.12) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: collapsed ? 0 : 14, vertical: 12),
          child: Row(
            mainAxisAlignment:
                collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(item.icon, color: color, size: 22),
              if (!collapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(item.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: color,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: collapsed ? Tooltip(message: item.label, child: tile) : tile,
    );
  }
}
