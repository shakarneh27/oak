/// Supabase project configuration.
///
/// The defaults below point at the live Digital Oak project and are
/// safe to commit: the publishable key is designed to ship inside client
/// apps — Row Level Security is what protects the data.
///
/// Override at build/run time with `--dart-define` if you ever point the
/// app at a different Supabase project:
///
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://rezepuaruqhqviqvgrxg.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_V1jcYECRkrYZf42XUKQDsQ_Yw2ogeRR',
  );
}
