/// Expression émotionnelle du chat compagnon.
enum CatMood { happy, neutral, sad, excited, sleepy }

/// Service déterminant l'état émotionnel du chat selon les stats du joueur.
/// Classe statique sans état — toutes les méthodes sont pures.
class CatMoodService {
  CatMoodService._();

  // ──────────────────────────────────────────────────────────────────────────
  // Humeur
  // ──────────────────────────────────────────────────────────────────────────

  /// Détermine l'humeur du chat selon [moral] (0.0–1.0) et [streak] (jours).
  static CatMood getMoodExpression(double moral, int streak) {
    if (streak >= 7 && moral >= 0.80) return CatMood.excited;
    if (moral >= 0.70) return CatMood.happy;
    if (moral >= 0.40) return CatMood.neutral;
    if (moral >= 0.20) return CatMood.sad;
    return CatMood.sleepy;
  }

  /// Retourne le nom d'animation Lottie (ou fallback string) pour une humeur.
  static String getIdleAnimation(CatMood mood) => switch (mood) {
        CatMood.excited => 'cat_excited',
        CatMood.happy   => 'cat_happy',
        CatMood.neutral => 'cat_idle',
        CatMood.sad     => 'cat_sad',
        CatMood.sleepy  => 'cat_sleepy',
      };

  // ──────────────────────────────────────────────────────────────────────────
  // Messages de bulle (SanctuaryPage)
  // ──────────────────────────────────────────────────────────────────────────

  /// Message affiché dans la bulle du chat sur la SanctuaryPage.
  static String getBubbleMessage(CatMood mood, int streak) {
    switch (mood) {
      case CatMood.excited:
        if (streak >= 30) return '$streak jours de suite ! Je suis immensément fier de toi ! 🌟';
        if (streak >= 14) return 'Deux semaines d\'affilée ! Tu es inarrêtable ! ⚡';
        return 'Une semaine parfaite ! Continue comme ça, champion ! 🎉';

      case CatMood.happy:
        const messages = [
          'Prêt pour de nouvelles aventures ? 🐾',
          'Aujourd\'hui sera une bonne journée, je le sens !',
          'Quelles quêtes allons-nous accomplir ensemble ? ✨',
          'Tu rayonnes d\'énergie positive ! 💫',
        ];
        return messages[streak % messages.length];

      case CatMood.neutral:
        return 'Allez, une petite quête pour se remettre en selle ? 🐱';

      case CatMood.sad:
        return 'Je suis là... On y va doucement, pas à pas. 🌙';

      case CatMood.sleepy:
        return 'Zzz... Réveille-moi quand tu es prêt... 😴';
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Messages de réaction (après validation de quête)
  // ──────────────────────────────────────────────────────────────────────────

  /// Message personnalisé du chat après la validation d'une quête.
  /// [questResult] : 'success' | 'late' | 'perfect'
  static String getCatReactionMessage(CatMood mood, String questResult) {
    if (questResult == 'perfect') {
      return switch (mood) {
        CatMood.excited => 'PARFAIT ! Tu es mon héros absolu ! 🌟⚡',
        CatMood.happy   => 'Impeccable ! Tu es fantastique ! ✨',
        CatMood.neutral => 'Très bien ! Tu m\'impressionnes. 😊',
        CatMood.sad     => 'Bravo... tu t\'en sors toujours. 💙',
        CatMood.sleepy  => '...Miaou. Bien joué. 😴',
      };
    }

    if (questResult == 'late') {
      return switch (mood) {
        CatMood.excited => 'Un peu en retard, mais l\'essentiel c\'est de finir ! 💪',
        CatMood.happy   => 'Mieux vaut tard que jamais ! 🐾',
        CatMood.neutral => 'La prochaine fois, on essaie plus tôt ? 🕐',
        CatMood.sad     => 'Merci d\'avoir quand même essayé... 🌙',
        CatMood.sleepy  => '...Tant mieux. 😴',
      };
    }

    // 'success' (cas général)
    return switch (mood) {
      CatMood.excited => 'Ouiii ! On est inarrêtables ! 🎉🐾',
      CatMood.happy   => 'Bravo ! Je suis tellement fier de toi ! ✨',
      CatMood.neutral => 'Bien joué ! Quête accomplie. 👍',
      CatMood.sad     => 'Tu l\'as fait... c\'est courageux. 💙',
      CatMood.sleepy  => 'Miaou... Bien. 😴',
    };
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────────────

  /// Emoji représentatif d'une humeur.
  static String moodEmoji(CatMood mood) => switch (mood) {
        CatMood.excited => '⚡',
        CatMood.happy   => '😺',
        CatMood.neutral => '😐',
        CatMood.sad     => '😿',
        CatMood.sleepy  => '😴',
      };

  /// Label lisible d'une humeur.
  static String moodLabel(CatMood mood) => switch (mood) {
        CatMood.excited => 'Surexcité',
        CatMood.happy   => 'Heureux',
        CatMood.neutral => 'Neutre',
        CatMood.sad     => 'Triste',
        CatMood.sleepy  => 'Endormi',
      };
}
