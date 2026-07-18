import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';

/// Wraps Supabase Auth + the `profiles` table.
///
/// Corresponds to the "شاشة البداية" (token check) and "تسجيل الدخول"
/// (`auth_session_init`) screens from the original spec: Supabase's
/// persisted session replaces the manual token check, and `signIn`
/// replaces the `auth_session_init` socket event.
class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  Session? get currentSession => _client.auth.currentSession;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<AppUser?> loadCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final row = await _client.from('profiles').select().eq('id', user.id).maybeSingle();
    if (row == null) return null;
    return AppUser.fromMap(row);
  }

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? classroom,
  }) async {
    final result = await _client.auth.signUp(email: email, password: password);
    final userId = result.user?.id;
    if (userId == null) {
      throw StateError('لم يتم إنشاء المستخدم، الرجاء المحاولة مجدداً');
    }
    final appUser = AppUser(id: userId, name: name, role: role, classroom: classroom);
    await _client.from('profiles').insert(appUser.toInsertMap());
    if (role == UserRole.student) {
      await _client.from('student_progress').insert({'student_id': userId});
    }
    return appUser;
  }

  Future<void> signOut() => _client.auth.signOut();
}
