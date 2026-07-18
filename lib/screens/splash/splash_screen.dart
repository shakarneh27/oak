import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// شاشة البداية: تهيئة محلية فقط، لا أحداث Socket.io — GoRouter's redirect
/// (see app_router.dart) performs the actual token check against the
/// persisted Supabase session and routes onward automatically.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.park_rounded, size: 96, color: OakColors.leafDark),
            const SizedBox(height: 16),
            Text('السنديانة الرقمية', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
