# Constats QA (banc d'essai)

Relevés en pilotant l'app réelle sur le banc (`tools/banc`). Un constat corrigé
reste listé avec sa date, pour l'historique.

| # | Constat | Gravité | Statut |
| --- | --- | --- | --- |
| Q1 | Premier lancement : le résumé hebdomadaire (à zéro) s'empile sur la récompense du jour | Moyenne | Corrigé le 2026-10-21 (pas de résumé vide) |
| Q2 | Récompense du jour : « Jour 0 de série » pour un nouveau joueur | Faible | Corrigé le 2026-10-21 |
| Q3 | Bouton « + » (nouvelle quête) et étoiles de difficulté sans libellé accessible | Moyenne (accessibilité) | Corrigé le 2026-10-21 |
| Q4 | Validation : 5 points de difficulté affichés pour une échelle de 4 | Faible | Corrigé le 2026-10-21 |
| Q5 | Compteur « 5 Jeton MougiBot » (accord du pluriel), sans libellé accessible | Faible | Corrigé le 2026-10-21 |
| Q6 | Refus pour défi absent affiché « Presque ! Reprends une photo plus nette » alors que le score est de 90 | Haute (incompréhensible) | Corrigé le 2026-10-21 (« Défi non visible sur la photo ») |
| Q7 | « Reprendre une photo » effaçait la photo sans ouvrir la caméra (deux gestes au lieu d'un) | Faible | Corrigé le 2026-10-21 |
| Q8 | Écran des récompenses : les Sceaux gagnés n'apparaissaient pas | Moyenne | Corrigé le 2026-10-21 |
| Q9 | Échéance par défaut « aujourd'hui 23:59 » : bonus d'échéance presque automatique (+10 %) | Moyenne (économie) | Corrigé le 2026-10-21 (échéance à 6 h minimum de la création) |
| Q10 | Sanctuaire : niveau, or, PV et cartes non exposés aux lecteurs d'écran | Moyenne (accessibilité) | Ouvert (Sprint 2, socle client) |
| Q11 | Accueil vide : « Crée ta première quête ! » n'est pas cliquable | Faible (UX) | Corrigé le 2026-10-21 (bouton « Créer ma première quête ») |
| Q12 | Vocabulaire incohérent : « Jetons MougiBot » dans l'app, « Énergie de l'Oracle » dans la conception | Faible | Corrigé le 2026-10-30 (« points d'énergie » de l'Oracle, icône éclair) |
| Q13 | Champ « Titre » sans libellé propre (seul l'exemple « Ex. Ranger ma chambre » est lu) | Faible (accessibilité) | Corrigé le 2026-10-21 (libellé « Titre de la quête », e2e sans coordonnées) |
| Q14 | Validation d'une quête sans durée : « 0 min » affiché | Faible | Corrigé le 2026-10-30 (durée masquée si inconnue) |
| Q15 | Le balayage horizontal entre onglets a disparu avec go_router (une pile par onglet) | Faible (UX) | Ouvert : à rétablir si les testeurs le regrettent |
| Q16 | Accueil : toucher une quête ouvre une fiche sans aucune action (impossible de la valider depuis le Sanctuaire) | Moyenne (UX) | Corrigé le 2026-10-30 (bouton « Valider la quête » sur les quêtes actives) |
| Q17 | Android : après « Valider la quête » depuis la fiche, l'arbre d'accessibilité reste celui de la fiche (TalkBack lirait un écran caché) | Moyenne (accessibilité) | Ouvert : à reproduire avec TalkBack sur le S918B |
| Q18 | Après « Nouveau défi », l'ancienne photo restait attachée et « Soumettre » actif | Moyenne (anti-triche, UX) | Corrigé le 2026-10-30 (photo retirée, message « reprends une photo ») |
| Q19 | Quête ouverte par lien profond : « Continuer » après les récompenses menait à un écran noir | Haute | Corrigé le 2026-10-30 (`quitterEcran` : retour aux Quêtes si rien en dessous) |
| Q20 | « Créer ma première quête » proposé à un joueur qui a déjà des quêtes | Faible | Corrigé le 2026-10-30 |
| Q21 | Lien profond vers une quête créée ailleurs : « introuvable » tant que la liste n'était pas relue | Moyenne | Corrigé le 2026-10-30 (une relecture serveur) |
| Q22 | Démarrage direct sur une quête (lien profond) : énergie affichée à 0, validation bloquée | Haute | Corrigé le 2026-10-30 (soldes lus au démarrage si une session existe) |
| Q23 | Erreur de connexion invité affichée en anglais brut (« Anonymous sign-ins are disabled ») | Faible | Ouvert (traduire les erreurs d'authentification) |
| Q24 | Sons absents sur le web : le greffon web d'audioplayers 6 n'initialise pas son canal global | Faible (banc seulement) | Contourné le 2026-11-03 (sons coupés sur le web) ; lecture vérifiée sur Android le jour même |
| Q25 | Android (debug) : écran rouge à l'arrivée au Sanctuaire, un sprite créait un second ticker en changeant d'animation | Haute | Corrigé le 2026-11-03 (TickerProviderStateMixin, animations comparées par valeur, test de non-régression) |
| Q26 | Supabase CLI 3 refuse la section `[inbucket]` de `supabase/config.toml` | Moyenne (outillage) | Corrigé le 2026-11-03 (`[local_smtp]`) |
