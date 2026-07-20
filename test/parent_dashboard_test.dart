import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:digital_oak/models/app_user.dart';
import 'package:digital_oak/models/student_progress.dart';
import 'package:digital_oak/models/adaptive_level.dart';
import 'package:digital_oak/providers/core_providers.dart';
import 'package:digital_oak/providers/parent_providers.dart';
import 'package:digital_oak/screens/parent/parent_dashboard_screen.dart';
import 'package:digital_oak/services/message_service.dart';

final _child = ParentChild(
  profile: const AppUser(
    id: 'student-1',
    name: 'سارة أحمد',
    role: UserRole.student,
    classroom: '4أ',
  ),
  progress: const StudentProgress(
    studentId: 'student-1',
    currentLevel: AdaptiveLevel.medium,
    oakLeaves: 42,
    treeGrowthStage: 9, // 45% growth
    badgesUnlocked: ['شارة المحاولة الشجاعة'],
  ),
);

const _teacher = AppUser(
  id: 'teacher-1',
  name: 'أ. محمود خليل',
  role: UserRole.teacher,
  managedClassrooms: ['4أ'],
);

final _message = OakMessage(
  id: 'msg-1',
  senderId: 'teacher-1',
  recipientId: 'parent-1',
  body: 'أداء ممتاز هذا الأسبوع! استمر في تشجيعه.',
  read: false,
  createdAt: DateTime.now(),
);

Widget _app() {
  // no autoRefreshToken: a background refresh timer would outlive the test
  final client = SupabaseClient(
    'http://localhost:54321',
    'test-key',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  return ProviderScope(
    overrides: [
      supabaseClientProvider.overrideWithValue(client),
      parentChildProvider.overrideWith((ref) async => _child),
      childTeacherProvider.overrideWith((ref) async => _teacher),
      myMessagesProvider.overrideWith((ref) => Stream.value([_message])),
      childWeeklyMinutesProvider.overrideWith(
        (ref) async => [12, 25, 18, 30, 22, 0, 8],
      ),
      childSessionStatsProvider.overrideWith(
        (ref) async => (completed: 14, streakDays: 3),
      ),
      childTopicsProvider.overrideWith(
        (ref) async =>
            (strong: ['د2: المجموعة الشمسية'], weak: ['د3: الخسوف والكسوف']),
      ),
    ],
    child: const MaterialApp(
      locale: Locale('ar'),
      supportedLocales: [Locale('ar'), Locale('en')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: ParentDashboardScreen(),
    ),
  );
}

void main() {
  testWidgets('overview tab shows child, tree growth, stats, and topics', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // app bar + the new "بيانات ابني" card both show the child's name
    expect(find.text('سارة أحمد'), findsNWidgets(2));
    expect(find.text('بيانات ابني'), findsOneWidget);
    expect(find.text('شجرة سارة'), findsOneWidget);
    expect(find.text('45%'), findsOneWidget);
    expect(find.text('نجوم'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('وقت التعلم هذا الأسبوع'), findsOneWidget);
    expect(find.text('يتفوق فيها'), findsOneWidget);
    expect(find.text('نصيحة نوري لكم'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'messages tab lists teacher message with unread badge and composer',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      await tester.tap(find.text('الرسائل'));
      await tester.pumpAndSettle();

      expect(find.text('رسائل المعلم'), findsOneWidget);
      expect(find.textContaining('أداء ممتاز هذا الأسبوع'), findsOneWidget);
      expect(find.text('جديد'), findsOneWidget);
      expect(find.text('رسالة جديدة للمعلم'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('contact and achievements tabs render reference sections', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('تواصل'));
    await tester.pumpAndSettle();
    expect(find.text('تواصل معنا'), findsOneWidget);
    expect(find.text('أ. محمود خليل'), findsOneWidget);
    expect(find.text('⏰ أوقات التواصل'), findsOneWidget);

    await tester.tap(find.text('الإنجازات'));
    await tester.pumpAndSettle();
    expect(find.text('إنجازات سارة'), findsOneWidget);
    expect(find.text('✅ مكتملة'), findsOneWidget);
    expect(find.text('🔒 قادمة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
