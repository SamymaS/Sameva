# Sameva

**Sameva** pousse l'utilisateur à réaliser des **actions réelles** en rendant la validation des tâches **crédible, vérifiable et gratifiante**.

Tout le reste (avatar, loot, animations, IA, etc.) existe uniquement pour servir cette fonction.

---

## Vision MVP (reboot recentré)

- **Cœur** : la **Quête** — action réelle concrète, mesurable et vérifiable (ranger une pièce, faire du sport, étudier 30 min, etc.).
- **Priorité n°1** : la **validation** — simple (checkbox), preuve visuelle (photo/vidéo), puis analyse IA (score 0–100, seuil 70).
- **6 pages** : Authentification · Mes Quêtes · Création de Quête · Validation de Quête · Récompense / Progression · Profil / Historique.

Exclu du MVP : boutique, gacha, mini-jeux, classements, social, économie complexe.

→ Voir **[documentation/VISION_REBOOT_MVP.md](documentation/VISION_REBOOT_MVP.md)** pour le détail.

---

## Lancer le projet

```bash
git clone <repo>
cd Sameva
cp .env.example .env   # puis renseigner SUPABASE_URL et SUPABASE_ANON_KEY
flutter pub get
flutter run
```

- **Backend** : Supabase (auth + base de données). Voir **[documentation/SUPABASE_SETUP.md](documentation/SUPABASE_SETUP.md)**.
- **État** : Provider (auth, quêtes, joueur, thème). Données locales : Hive (quests, playerStats).

---

## Structure du code (MVP)

```
lib/
├── main.dart              # Point d'entrée, Supabase, Hive, Provider
├── app_new.dart           # SamevaApp — 2 onglets (Mes Quêtes, Profil), routes
├── config/                # Supabase (supabase_config.dart)
├── data/models/           # Quest (quest_model.dart)
├── domain/services/       # validation_ai_service, quest_rewards_calculator
├── presentation/providers # auth, quest, player, theme
└── ui/
    ├── pages/             # auth, quest (list, create, validation), profile, rewards, settings
    ├── theme/             # app_theme, app_colors
    └── widgets/           # magical (animated_background, glowing_card), minimalist (fade_in, button, card, hud_header)
```

---

## Documentation

| Fichier | Contenu |
|--------|---------|
| [documentation/VISION_REBOOT_MVP.md](documentation/VISION_REBOOT_MVP.md) | Principe fondateur, 6 pages, validation, exclu MVP |
| [documentation/SUPABASE_SETUP.md](documentation/SUPABASE_SETUP.md) | Configuration Supabase, schéma, clés API |
| [documentation/supabase_schema.sql](documentation/supabase_schema.sql) | Schéma SQL Supabase |
