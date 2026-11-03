import 'package:flutter_test/flutter_test.dart';
import 'package:sameva/core/auth/secure_session_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _CoffreMemoire implements CoffreCles {
  final Map<String, String> valeurs = {};
  @override
  Future<String?> lire(String cle) async => valeurs[cle];
  @override
  Future<void> ecrire(String cle, String valeur) async => valeurs[cle] = valeur;
  @override
  Future<void> effacer(String cle) async => valeurs.remove(cle);
}

class _AncienStockage extends LocalStorage {
  _AncienStockage([this.session]);
  String? session;
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> hasAccessToken() async => session != null;
  @override
  Future<String?> accessToken() async => session;
  @override
  Future<void> persistSession(String s) async => session = s;
  @override
  Future<void> removePersistedSession() async => session = null;
}

void main() {
  const cle = 'sb-abc-auth-token';

  test('clé identique à celle de supabase_flutter', () {
    expect(SecureSessionStorage.cleParDefaut('https://abc.supabase.co'), cle);
  });

  test('reprend la session en clair puis l\'efface (personne n\'est déconnecté)', () async {
    final coffre = _CoffreMemoire();
    final ancien = _AncienStockage('{"access_token":"x"}');
    final s = SecureSessionStorage(persistSessionKey: cle, coffre: coffre, ancien: ancien);
    await s.initialize();
    expect(await s.accessToken(), '{"access_token":"x"}');
    expect(ancien.session, isNull, reason: 'plus rien en clair');
  });

  test('une session déjà chiffrée n\'est pas écrasée par une ancienne', () async {
    final coffre = _CoffreMemoire()..valeurs[cle] = 'recente';
    final ancien = _AncienStockage('ancienne');
    final s = SecureSessionStorage(persistSessionKey: cle, coffre: coffre, ancien: ancien);
    await s.initialize();
    expect(await s.accessToken(), 'recente');
    expect(ancien.session, isNull);
  });

  test('écrire, lire, effacer', () async {
    final s = SecureSessionStorage(persistSessionKey: cle, coffre: _CoffreMemoire(), ancien: _AncienStockage());
    await s.initialize();
    expect(await s.hasAccessToken(), isFalse);
    await s.persistSession('jeton');
    expect(await s.hasAccessToken(), isTrue);
    await s.removePersistedSession();
    expect(await s.accessToken(), isNull);
  });
}
