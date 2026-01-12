import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration Supabase
/// 
/// Les clés sont chargées depuis le fichier .env
/// Pour obtenir vos clés :
/// 1. Allez sur https://supabase.com
/// 2. Créez un projet
/// 3. Allez dans Settings > API
/// 4. Copiez l'URL du projet et la clé anon (anon key)
/// 5. Ajoutez-les dans le fichier .env
class SupabaseConfig {
  /// URL du projet Supabase
  static String get supabaseUrl {
    final url = dotenv.env['SUPABASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception(
        'SUPABASE_URL n\'est pas défini dans le fichier .env\n'
        'Veuillez créer un fichier .env à la racine du projet avec vos clés Supabase.\n'
        'Voir .env.example pour un exemple.',
      );
    }
    return url;
  }

  /// Clé API anonyme Supabase
  static String get supabaseAnonKey {
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception(
        'SUPABASE_ANON_KEY n\'est pas défini dans le fichier .env\n'
        'Veuillez créer un fichier .env à la racine du projet avec vos clés Supabase.\n'
        'Voir .env.example pour un exemple.',
      );
    }
    return key;
  }
}

