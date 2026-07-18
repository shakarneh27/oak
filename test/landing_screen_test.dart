import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:digital_oak/screens/landing/landing_content.dart';
import 'package:digital_oak/screens/landing/landing_screen.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: child,
  );
}

void main() {
  testWidgets('landing page renders brand, hero, and corner auth buttons', (tester) async {
    tester.view.physicalSize = const Size(1280, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(const LandingScreen()));
    await tester.pumpAndSettle();

    expect(find.text('تسجيل الدخول'), findsWidgets);
    expect(find.text('حساب جديد'), findsOneWidget);
    expect(find.text(LandingContent.heroTitle), findsWidgets);
    expect(find.text('ابدأ رحلة التعلم'), findsOneWidget);
    expect(find.text('لماذا السنديانة الرقمية؟'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('landing page lays out on a narrow phone screen', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(const LandingScreen()));
    await tester.pumpAndSettle();

    expect(find.text('دخول'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
