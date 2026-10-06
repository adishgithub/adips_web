import 'package:adips_web/core/responsive/breakpoints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('breakpoints match the plan (>=1200 / 768-1199 / <768)', () {
    expect(screenSizeFor(1920), ScreenSize.desktop);
    expect(screenSizeFor(1200), ScreenSize.desktop);
    expect(screenSizeFor(1199), ScreenSize.tablet);
    expect(screenSizeFor(768), ScreenSize.tablet);
    expect(screenSizeFor(767), ScreenSize.mobile);
  });
}
