import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/settings_provider.dart';

class DigitalOakApp extends ConsumerWidget {
  const DigitalOakApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final darkMode = ref.watch(settingsProvider).valueOrNull?.darkMode ?? false;

    return MaterialApp.router(
      title: 'السنديانة الرقمية',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      // Without these delegates MaterialLocalizations has no Arabic
      // resources, and every TextField crashes at build time (a grey box
      // in release builds).
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
    );
  }
}
