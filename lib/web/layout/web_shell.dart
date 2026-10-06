import 'package:flutter/material.dart';

import '../../core/responsive/breakpoints.dart';
import 'web_header.dart';
import 'web_sidebar.dart';

/// App frame for every signed-in page:
///   desktop  : persistent sidebar + header + centred content
///   tablet   : icon rail + header + content
///   mobile   : drawer + header + content
/// Pages pass their [title], [route] (for highlighting) and [child].
class WebShell extends StatelessWidget {
  const WebShell({
    super.key,
    required this.title,
    required this.route,
    required this.child,
  });

  final String title;
  final String route;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = screenSizeFor(constraints.maxWidth);
      final isMobile = size == ScreenSize.mobile;

      final content = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
          child: SizedBox(width: double.infinity, child: child),
        ),
      );

      return Scaffold(
        drawer: isMobile
            ? Drawer(
                child: Builder(
                  builder: (ctx) => WebSidebar(
                    currentRoute: route,
                    onNavigate: () => Navigator.of(ctx).pop(),
                  ),
                ),
              )
            : null,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isMobile)
              WebSidebar(
                  currentRoute: route, collapsed: size == ScreenSize.tablet),
            Expanded(
              child: Column(
                children: [
                  Builder(
                    builder: (ctx) => WebHeader(
                        title: title, showMenuButton: isMobile),
                  ),
                  Expanded(child: content),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
