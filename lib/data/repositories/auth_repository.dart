import 'package:supabase_flutter/supabase_flutter.dart';

/// Accès aux données d'authentification via Supabase Auth.
/// Pas d'état UI — retourne des valeurs ou lance des exceptions.
class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  User? get currentUser => _supabase.auth.currentUser;
  String? get userId => _supabase.auth.currentUser?.id;
  bool get isAuthenticated => _supabase.auth.currentUser != null;

  /// Flux des changements d'état d'authentification.
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    return response.user;
  }

  Future<User?> createUserWithEmailAndPassword(String email, String password) async {
    final response = await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
    );
    return response.user;
  }

  /// Connexion anonyme (mode invité). Le user_id est stable jusqu'à la mise à niveau.
  Future<User?> signInAnonymously() async {
    final response = await _supabase.auth.signInAnonymously();
    return response.user;
  }

  /// Met à niveau un compte invité vers un compte email/mot de passe.
  /// Doit être appelé sur la session anonyme active — préserve le user_id.
  Future<User?> upgradeAnonymousToEmail({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.updateUser(
      UserAttributes(email: email.trim(), password: password),
    );
    return response.user;
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
