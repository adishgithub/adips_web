import 'package:flutter/material.dart';

import '../layout/web_shell.dart';

/// Placeholder for modules scheduled in later phases. Replace per phase.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({
    super.key,
    required this.title,
    required this.route,
    required this.phase,
  });

  final String title;
  final String route;
  final String phase;

  @override
  Widget build(BuildContext context) {
    return WebShell(
      title: title,
      route: route,
      child: Center(
        child: Text('$title is planned for $phase.',
            style: Theme.of(context).textTheme.bodyLarge),
      ),
    );
  }
}
