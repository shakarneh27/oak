import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:digital_oak/screens/auth/login_screen.dart';

/// Guards the two-step auth flow: sign-in card, role-select cards, and
/// the role-specific sign-up form with its stronger requirements.
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
  testWidgets('sign-in card renders email, password, and signup link', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(const LoginScreen()));
    await tester.pumpAndSettle();

    expect(find.text('البريد الإلكتروني'), findsOneWidget);
    expect(find.text('كلمة المرور'), findsOneWidget);
    expect(find.text('دخول'), findsOneWidget);
    expect(find.text('ليس لديك حساب؟ أنشئ واحداً الآن'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('role select shows the three role cards with features', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(const LoginScreen(startInSignUp: true)));
    await tester.pumpAndSettle();

    expect(find.text('طالب'), findsOneWidget);
    expect(find.text('معلم'), findsOneWidget);
    expect(find.text('ولي الأمر'), findsOneWidget);
    expect(find.text('شجرة تنمو معك'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'student sign-up form has avatar picker, requirements, and classroom',
    (tester) async {
      tester.view.physicalSize = const Size(430, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap(const LoginScreen(startInSignUp: true)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('طالب'));
      await tester.pumpAndSettle();

      expect(find.text('حساب طالب جديد'), findsOneWidget);
      expect(find.text('اختر شخصيتك'), findsOneWidget);
      expect(find.text('الاسم الكامل'), findsOneWidget);
      expect(find.text('تأكيد كلمة المرور'), findsOneWidget);
      expect(find.text('اسم صفك'), findsOneWidget);
      expect(find.text('8 أحرف على الأقل'), findsOneWidget);

      // submitting empty form surfaces validation errors
      await tester.tap(find.text('إنشاء الحساب 🌱'));
      await tester.pumpAndSettle();
      expect(find.text('الاسم مطلوب'), findsOneWidget);
      expect(find.text('البريد الإلكتروني مطلوب'), findsOneWidget);
      expect(find.text('اسم الصف مطلوب'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('weak password and mismatched confirm are rejected', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(const LoginScreen(startInSignUp: true)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ولي الأمر'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'كلمة المرور'),
      'abc',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'تأكيد كلمة المرور'),
      'xyz',
    );
    await tester.tap(find.text('إنشاء الحساب 🌱'));
    await tester.pumpAndSettle();

    expect(find.text('8 أحرف على الأقل'), findsWidgets);
    expect(find.text('كلمتا المرور غير متطابقتين'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
