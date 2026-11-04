-- Migration documentation : tracer la décision sécurité sur 
-- leaderboard_view (faux positif Security Advisor).
-- Audit @sameva-monitor du 17/05/26 — réf migration 
-- 20260513120000_harden_rls_policies.sql

COMMENT ON VIEW public.leaderboard_view IS
$comment$
SECURITY DEFINER intentionnel — faux positif Supabase Security 
Advisor.

Justification du bypass RLS :
- Le leaderboard nécessite de voir TOUS les joueurs, pas juste 
  le current user
- Sans bypass RLS, chaque user ne verrait que sa propre ligne 
  (RLS player_stats_self_access + users_select_own)

Protections compensatoires :
- security_barrier = true (anti-injection via fonctions volatiles)
- GRANT SELECT limité au rôle authenticated (pas anon, pas public)
- Projection limitée aux 5 colonnes publiques : 
  user_id (UUID opaque), level, xp, streak, display_name
- Aucune donnée sensible exposée (gold, crystals, moral, 
  credibility_score, achievements, email restent privés via RLS)

Alternative INVOKER rejetée : passer en SECURITY INVOKER 
nécessiterait une policy SELECT USING (true) sur player_stats 
qui ouvrirait toutes les colonnes (y compris sensibles) aux 
requêtes directes authentifiées.

Vigilance future : toute nouvelle colonne ajoutée à 
player_stats ou users doit être vérifiée — si elle apparaît 
dans le SELECT de cette vue, elle devient publique.
$comment$;
