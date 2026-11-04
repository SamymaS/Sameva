import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Stockage minimal clé/valeur, pour pouvoir tester sans plateforme.
abstract class CoffreCles {
  Future<String?> lire(String cle);
  Future<void> ecrire(String cle, String valeur);
  Future<void> effacer(String cle);
}

/// Keystore Android / Keychain iOS.
class CoffrePlateforme implements CoffreCles {
  const CoffrePlateforme();
  static const _storage = FlutterSecureStorage(
    // La session survit à la réinstallation sur iOS seulement si on le veut :
    // ici non, une session doit mourir avec l'app.
    iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device),
  );
  @override
  Future<String?> lire(String cle) => _storage.read(key: cle);
  @override
  Future<void> ecrire(String cle, String valeur) =>
      _storage.write(key: cle, value: valeur);
  @override
  Future<void> effacer(String cle) => _storage.delete(key: cle);
}

/// Session Supabase chiffrée par la plateforme (ADR 0007, point 5).
///
/// Avant le Sprint 2, la session (jeton de rafraîchissement compris) était en
/// clair dans les SharedPreferences. Au premier lancement, la session
/// existante y est reprise puis effacée : personne n'est déconnecté, ce qui
/// compte surtout pour les invités, dont le compte n'existe que par elle.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage({
    required this.persistSessionKey,
    CoffreCles? coffre,
    LocalStorage? ancien,
  })  : _coffre = coffre ?? const CoffrePlateforme(),
        _ancien = ancien ??
            SharedPreferencesLocalStorage(persistSessionKey: persistSessionKey);

  /// Même clé que celle de supabase_flutter : `sb-<ref>-auth-token`.
  final String persistSessionKey;
  final CoffreCles _coffre;
  final LocalStorage _ancien;

  /// Clé par défaut de supabase_flutter pour une URL de projet.
  static String cleParDefaut(String supabaseUrl) =>
      'sb-${Uri.parse(supabaseUrl).host.split('.').first}-auth-token';

  @override
  Future<void> initialize() async {
    await _ancien.initialize();
    if (await _ancien.hasAccessToken()) {
      final session = await _ancien.accessToken();
      if (session != null &&
          session.isNotEmpty &&
          await _coffre.lire(persistSessionKey) == null) {
        await _coffre.ecrire(persistSessionKey, session);
      }
      await _ancien.removePersistedSession();
    }
  }

  @override
  Future<bool> hasAccessToken() async =>
      (await _coffre.lire(persistSessionKey)) != null;

  @override
  Future<String?> accessToken() => _coffre.lire(persistSessionKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _coffre.ecrire(persistSessionKey, persistSessionString);

  @override
  Future<void> removePersistedSession() => _coffre.effacer(persistSessionKey);
}
