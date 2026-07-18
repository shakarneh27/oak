/// Supabase project credentials.
///
/// Values are read from `--dart-define` at build/run time so no secret ever
/// lives in source control:
///
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
///
/// For `flutter build web` on Vercel, set the same two build-time
/// environment variables in the Vercel project settings and forward them
/// through the build command (see vercel.json).
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR-PROJECT-REF.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR-SUPABASE-ANON-KEY',
  );
}
