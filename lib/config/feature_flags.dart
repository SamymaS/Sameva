/// Feature flags MVP (Bloc 1).
///
/// Centralise les bascules d'activation des fonctionnalités hors périmètre MVP.
/// Le code des fonctionnalités masquées est conservé : il suffit de passer le
/// flag à `true` pour réactiver (phase post-MVP, collab artistique Noyuss).
///
/// Voir la vision produit (skill `sameva-context`) pour le périmètre verrouillé.
class FeatureFlags {
  FeatureFlags._();

  /// Mini-jeux (page Jeux) — retirée de la DockBar pour le MVP.
  /// NOTE : `MinigamesPage` n'est actuellement instanciée nulle part
  /// (code orphelin sous lib/ui/pages/minigames/). Ce flag documente
  /// l'intention ; la réactivation nécessitera de re-brancher un point d'entrée.
  static const bool showMinigames = false;

  /// Classement social (leaderboard).
  static const bool showLeaderboard = false;

  /// Historique des quêtes manquées.
  static const bool showHistory = false;

  /// Boss hebdomadaire sur l'Accueil.
  static const bool showWeeklyBoss = false;

  /// Onglet Premium (boutique en cristaux) du Portail.
  static const bool showMarketPremium = false;

  /// Slots cosmétiques extra : Pantalon, Chaussures, Accessoire, Titre.
  static const bool showExtraCosmeticSlots = false;
}
