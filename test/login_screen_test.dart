import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:digital_oak/screens/auth/login_screen.dart';

/// Guards against the release-mode grey-box regression: with an Arabic
/// locale, Material widgets (TextField, Dropdown) crash unless the global
/// localization delegates are registered exactly as app.dart does.
Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    ),
  );
}

void main() {
  testWidgets('login form renders its fields under the Arabic locale', (tester) async {
    await tester.pumpWidget(_wrap(const LoginScreen()));
    await tester.pumpAndSettle();

    expect(find.text('البريد الإلكتروني'), findsOneWidget);
    expect(find.text('كلمة المرور'), findsOneWidget);
    expect(find.text('دخول'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sign-up tab shows name, role, and classroom fields', (tester) async {
    await tester.pumpWidget(_wrap(const LoginScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('حساب جديد'));
    await tester.pumpAndSettle();

    expect(find.text('الاسم الكامل'), findsOneWidget);
    expect(find.text('الدور'), findsOneWidget);
    expect(find.text('الصف (اختياري)'), findsOneWidget);
    expect(find.text('إنشاء الحساب'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
