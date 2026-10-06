import 'package:flutter/widgets.dart';

import '../../core/responsive/breakpoints.dart';

/// Picks a builder by available width (not device type). [tablet] falls
/// back to [desktop]; [mobile] falls back to [tablet].
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.desktop,
    this.tablet,
    this.mobile,
  });

  final WidgetBuilder desktop;
  final WidgetBuilder? tablet;
  final WidgetBuilder? mobile;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      switch (screenSizeFor(c.maxWidth)) {
        case ScreenSize.desktop:
          return desktop(context);
        case ScreenSize.tablet:
          return (tablet ?? desktop)(context);
        case ScreenSize.mobile:
          return (mobile ?? tablet ?? desktop)(context);
      }
    });
  }
}
