import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';
import 'core_providers.dart';

/// Raw Supabase auth state — drives the splash screen's automatic
/// navigation once the persisted session token has been checked.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).onAuthStateChange;
});

/// The signed-in user's profile row (name, role, classroom). Re-fetches
/// whenever the underlying auth state changes.
final currentProfileProvider = FutureProvider<AppUser?>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(authServiceProvider).loadCurrentProfile();
});
