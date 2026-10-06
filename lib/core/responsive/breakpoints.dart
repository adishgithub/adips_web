import 'package:flutter/widgets.dart';

/// Layout breakpoints from the web plan (section 7).
///   >= 1200  desktop : full sidebar + multi-column content
///   768-1199 tablet  : icon-only sidebar rail
///   < 768    mobile  : drawer navigation, stacked content
class Breakpoints {
  Breakpoints._();

  static const double tablet = 768;
  static const double desktop = 1200;

  /// Max width of centred page content on very wide screens.
  static const double contentMaxWidth = 1280;
}

enum ScreenSize { mobile, tablet, desktop }

ScreenSize screenSizeFor(double width) {
  if (width >= Breakpoints.desktop) return ScreenSize.desktop;
  if (width >= Breakpoints.tablet) return ScreenSize.tablet;
  return ScreenSize.mobile;
}

extension ScreenSizeContext on BuildContext {
  ScreenSize get screenSize => screenSizeFor(MediaQuery.sizeOf(this).width);
}
