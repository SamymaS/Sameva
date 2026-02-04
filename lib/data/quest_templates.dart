import 'models/quest_model.dart';

/// Template de quête préconfigurée (mode par thème).
class QuestTemplate {
  final String title;
  final String category;
  final int defaultDurationMinutes;
  final ValidationType validationType;

  const QuestTemplate({
    required this.title,
    required this.category,
    required this.defaultDurationMinutes,
    required this.validationType,
  });
}

/// Thèmes disponibles pour le mode "Par thème".
const List<String> themeCategories = ['Sport', 'Loisir', 'Maison'];

/// Quêtes préconfigurées par thème.
Map<String, List<QuestTemplate>> get questTemplatesByTheme {
  return {
    'Sport': const [
      QuestTemplate(
        title: 'Faire du sport (durée libre)',
        category: 'Sport',
        defaultDurationMinutes: 30,
        validationType: ValidationType.photo,
      ),
      QuestTemplate(
        title: 'Course à pied',
        category: 'Sport',
        defaultDurationMinutes: 20,
        validationType: ValidationType.photo,
      ),
      QuestTemplate(
        title: 'Séance de musculation',
        category: 'Sport',
        defaultDurationMinutes: 45,
        validationType: ValidationType.photo,
      ),
      QuestTemplate(
        title: 'Étirements',
        category: 'Sport',
        defaultDurationMinutes: 15,
        validationType: ValidationType.manual,
      ),
      QuestTemplate(
        title: 'Marche active',
        category: 'Sport',
        defaultDurationMinutes: 30,
        validationType: ValidationType.photo,
      ),
    ],
    'Loisir': const [
      QuestTemplate(
        title: 'Lire (livre ou article)',
        category: 'Loisir',
        defaultDurationMinutes: 30,
        validationType: ValidationType.photo,
      ),
      QuestTemplate(
        title: 'Activité créative (dessin, musique…)',
        category: 'Loisir',
        defaultDurationMinutes: 45,
        validationType: ValidationType.photo,
      ),
      QuestTemplate(
        title: 'Pause déconnexion (sans écran)',
        category: 'Loisir',
        defaultDurationMinutes: 20,
        validationType: ValidationType.manual,
      ),
      QuestTemplate(
        title: 'Apprendre quelque chose de nouveau',
        category: 'Loisir',
        defaultDurationMinutes: 30,
        validationType: ValidationType.photo,
      ),
    ],
    'Maison': const [
      QuestTemplate(
        title: 'Ranger une pièce',
        category: 'Maison',
        defaultDurationMinutes: 30,
        validationType: ValidationType.photo,
      ),
      QuestTemplate(
        title: 'Faire le lit',
        category: 'Maison',
        defaultDurationMinutes: 5,
        validationType: ValidationType.photo,
      ),
      QuestTemplate(
        title: 'Vaisselle / cuisine propre',
        category: 'Maison',
        defaultDurationMinutes: 15,
        validationType: ValidationType.photo,
      ),
      QuestTemplate(
        title: 'Tri / rangement (placard, bureau)',
        category: 'Maison',
        defaultDurationMinutes: 25,
        validationType: ValidationType.photo,
      ),
      QuestTemplate(
        title: 'Passer l\'aspirateur',
        category: 'Maison',
        defaultDurationMinutes: 20,
        validationType: ValidationType.photo,
      ),
    ],
  };
}
