import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Socle Riverpod (ADR 0007). Les fonctionnalités migrées dépendent de ces
/// providers plutôt que de `Supabase.instance` : ils se remplacent en test.

/// Client Supabase.
final supabaseClientProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

/// Identifiant de l'utilisateur connecté, ou null. Tout provider propre à un
/// utilisateur le surveille (`ref.watch`) : à la déconnexion ou au changement
/// de compte, il est reconstruit automatiquement, sans `reset()` manuel.
final currentUserIdProvider = StreamProvider<String?>((ref) async* {
  final auth = ref.watch(supabaseClientProvider).auth;
  yield auth.currentUser?.id;
  yield* auth.onAuthStateChange.map((e) => e.session?.user.id).distinct();
});
