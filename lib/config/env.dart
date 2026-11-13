/// Backend environment configuration — the ONLY place backend coordinates
/// live in the client.
///
/// Values are read from `--dart-define` at build time:
///   flutter run \
///     --dart-define=SUPABASE_URL=https://<project>.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=<anon-key> \
///     --dart-define=USE_MOCK_BACKEND=false
///
/// With no defines (the default), [useMockBackend] is true and the app runs
/// entirely on the local stub services — nothing breaks before hosting.
/// The anon key is a PUBLIC, RLS-constrained key by design; the
/// service-role key must NEVER appear here or anywhere in the client.
class Env {
  Env._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Explicit override; default is mock unless both values are present.
  static const bool _mockOverride = bool.fromEnvironment(
    'USE_MOCK_BACKEND',
    defaultValue: false,
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Mock mode = explicit override OR backend not configured yet.
  static bool get useMockBackend => _mockOverride || !isConfigured;
}
