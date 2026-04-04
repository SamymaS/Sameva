import 'package:supabase_flutter/supabase_flutter.dart';

/// Accès à la table `users` de Supabase.
/// Responsable de la création du profil utilisateur à la première connexion.
class UserRepository {
  final SupabaseClient _supabase;

  UserRepository(this._supabase);

  /// Crée le profil utilisateur s'il n'existe pas encore dans la table `users`.
  /// Appelé lors de la création d'une quête si l'entrée est manquante.
  Future<void> ensureUserExists(String userId) async {
    final exists = await _supabase
        .from('users')
        .select('id')
        .eq('id', userId)
        .maybeSingle();

    if (exists != null) return;

    final authUser = _supabase.auth.currentUser;
    if (authUser == null) throw Exception('Utilisateur non authentifié');

    await _supabase.from('users').insert({
      'id': userId,
      'username': authUser.email?.split('@')[0] ?? 'user_${userId.substring(0, 8)}',
      'display_name': authUser.userMetadata?['display_name'] ??
          authUser.email?.split('@')[0] ??
          'User',
    });

    // Création de l'équipement de base (best-effort — peut déjà exister)
    try {
      await _supabase.from('user_equipment').insert({'user_id': userId});
    } catch (_) {}
  }
}
