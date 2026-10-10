import 'package:adips_web/utils/theme/adips_app_theme.dart';
import 'package:adips_web/web/auth/web_onboarding_page.dart';
import 'package:adips_web/web/auth/web_register_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('register: mismatching passwords are rejected before any API call',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: AdipsAppTheme.darkTheme,
      home: const WebRegisterPage(),
    ));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Jo Doe');
    await tester.enterText(fields.at(1), 'jo@example.com');
    await tester.enterText(fields.at(2), 'secret1');
    await tester.enterText(fields.at(3), 'secret2');
    await tester.tap(find.text('Create account'));
    await tester.pump();

    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('onboarding: Next walks to the last slide, then Get started',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: AdipsAppTheme.darkTheme,
      home: const WebOnboardingPage(),
    ));

    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
  });
}
