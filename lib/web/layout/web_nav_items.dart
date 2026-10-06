import 'package:flutter/material.dart';

class WebNavItem {
  const WebNavItem(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}

/// Sidebar modules. Routes follow the plan's route map (section 10).
const webNavItems = <WebNavItem>[
  WebNavItem('Dashboard', Icons.dashboard_outlined, '/dashboard'),
  WebNavItem('Transactions', Icons.receipt_long_outlined, '/transactions'),
  WebNavItem('Accounts', Icons.account_balance_wallet_outlined, '/accounts'),
  WebNavItem('Categories', Icons.category_outlined, '/categories'),
  WebNavItem('Transaction Types', Icons.swap_horiz, '/transaction-types'),
  WebNavItem('Settings', Icons.settings_outlined, '/settings'),
];
