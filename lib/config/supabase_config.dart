/// Configuration de l'application, injectée à la compilation (Sprint 2, ADR 0007).
///
/// Les valeurs viennent de `--dart-define-from-file=config/<env>.json`
/// (voir `config/exemple.json`). Il n'y a plus de fichier `.env` embarqué comme
/// asset dans l'APK : seules ces constantes compilées existent, et ce ne sont
/// que des valeurs publiques par conception (URL, clé anon protégée par la RLS,
/// ID client Web Google). Aucun secret serveur ne doit jamais arriver ici.
///
///   flutter run --dart-define-from-file=config/dev.json
///   flutter build apk --release --dart-define-from-file=config/prod.json
class SupabaseConfig {
  static const String _url = String.fromEnvironment('SUPABASE_URL');
  static const String _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String _googleWebClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  /// Nom de l'environnement (dev, banc, staging, prod), pour les journaux.
  static const String environment =
      String.fromEnvironment('SAMEVA_ENV', defaultValue: 'dev');

  /// Clés requises absentes de la configuration compilée.
  static List<String> get missingKeys => [
        if (_url.isEmpty) 'SUPABASE_URL',
        if (_anonKey.isEmpty) 'SUPABASE_ANON_KEY',
        if (_googleWebClientId.isEmpty) 'GOOGLE_WEB_CLIENT_ID',
      ];

  static String _require(String value, String key) {
    if (value.isEmpty) {
      throw StateError(
        '$key absent de la configuration. Lancer avec '
        '--dart-define-from-file=config/<env>.json (voir config/exemple.json).',
      );
    }
    return value;
  }

  /// URL du projet Supabase.
  static String get supabaseUrl => _require(_url, 'SUPABASE_URL');

  /// Clé API anonyme Supabase (publique, protégée par la RLS).
  static String get supabaseAnonKey => _require(_anonKey, 'SUPABASE_ANON_KEY');

  /// ID client Web Google, transmis au SDK Google Sign-In.
  static String get googleWebClientId =>
      _require(_googleWebClientId, 'GOOGLE_WEB_CLIENT_ID');
}
