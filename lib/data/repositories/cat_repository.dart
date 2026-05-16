import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cat_model.dart';

/// Accès aux compagnons stockés dans Supabase (table `companions`).
/// Ne touche PAS Hive : la persistance locale reste dans CatViewModel.
/// Toutes les opérations sont best-effort : erreurs loguées, jamais propagées.
class CatRepository {
  final SupabaseClient _supabase;

  CatRepository(this._supabase);

  /// Récupère tous les compagnons d'un utilisateur depuis Supabase.
  /// Retourne une liste vide en cas d'erreur (offline-first : ne jamais bloquer).
  Future<List<CatStats>> fetchRemoteCompanions(String userId) async {
    try {
      final response = await _supabase
          .from('companions')
          .select()
          .eq('user_id', userId);

      return (response as List)
          .map((row) =>
              CatStats.fromSupabaseMap(Map<String, dynamic>.from(row as Map)))
          .toList();
    } catch (e) {
      debugPrint('CatRepository: erreur fetchRemoteCompanions: $e');
      return [];
    }
  }

  /// Upsert un compagnon dans Supabase (clé de conflit : id).
  /// Best-effort : l'erreur est loguée mais jamais propagée.
  /// Le caller peut continuer même si Supabase est indisponible.
  Future<void> upsertCompanion(String userId, CatStats cat) async {
    try {
      await _supabase.from('companions').upsert(
            cat.toSupabaseMap(userId),
            onConflict: 'id',
          );
    } catch (e) {
      debugPrint('CatRepository: erreur upsertCompanion ${cat.id}: $e');
    }
  }
}
