import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sameva/data/models/quest_model.dart';
import 'package:sameva/data/repositories/quest_repository.dart';
import 'package:sameva/presentation/view_models/auth_view_model.dart';
import 'package:sameva/presentation/view_models/quests_list_view_model.dart';

class _MockQuestRepository extends Mock implements QuestRepository {}

class _MockAuthViewModel extends Mock implements AuthViewModel {}

void main() {
  late _MockQuestRepository questRepo;
  late _MockAuthViewModel auth;
  late QuestsListViewModel vm;

  setUp(() {
    questRepo = _MockQuestRepository();
    auth = _MockAuthViewModel();
    vm = QuestsListViewModel(questRepo, auth);
  });

  group('QuestsListViewModel', () {
    test('loadQuests ne charge rien si userId est null', () async {
      when(() => auth.userId).thenReturn(null);

      await vm.loadQuests();

      expect(vm.quests, isEmpty);
      expect(vm.isLoading, isFalse);
      verifyNever(() => questRepo.loadQuests(any()));
    });

    test('loadQuests remplit la liste en cas de succès', () async {
      when(() => auth.userId).thenReturn('u1');
      final q = Quest(
        id: 'q1',
        userId: 'u1',
        title: 'T',
        estimatedDurationMinutes: 15,
        frequency: QuestFrequency.oneOff,
        difficulty: 1,
        category: 'Autre',
        rarity: QuestRarity.common,
        status: QuestStatus.active,
      );
      when(() => questRepo.loadQuests('u1')).thenAnswer((_) async => [q]);

      await vm.loadQuests();

      expect(vm.quests, hasLength(1));
      expect(vm.error, isNull);
      expect(vm.isLoading, isFalse);
      expect(vm.activeQuests, hasLength(1));
      expect(vm.completedQuests, isEmpty);
    });

    test('loadQuests pose une erreur lisible si le repository échoue', () async {
      when(() => auth.userId).thenReturn('u1');
      when(() => questRepo.loadQuests('u1')).thenThrow(Exception('timeout'));

      await vm.loadQuests();

      expect(vm.quests, isEmpty);
      expect(vm.error, isNotNull);
      expect(vm.isLoading, isFalse);
    });

    test('deleteQuest retire la quête et notifie', () async {
      when(() => auth.userId).thenReturn('u1');
      final q = Quest(
        id: 'to-delete',
        userId: 'u1',
        title: 'T',
        estimatedDurationMinutes: 1,
        frequency: QuestFrequency.oneOff,
        difficulty: 1,
        category: 'Autre',
        rarity: QuestRarity.common,
        status: QuestStatus.active,
      );
      when(() => questRepo.loadQuests('u1')).thenAnswer((_) async => [q]);
      when(() => questRepo.deleteQuest('to-delete')).thenAnswer((_) async {});

      await vm.loadQuests();
      await vm.deleteQuest('to-delete');

      expect(vm.quests, isEmpty);
      verify(() => questRepo.deleteQuest('to-delete')).called(1);
    });

    test('clearError remet l\'erreur à null', () async {
      when(() => auth.userId).thenReturn('u1');
      when(() => questRepo.loadQuests('u1')).thenThrow(Exception('x'));
      await vm.loadQuests();
      expect(vm.error, isNotNull);

      vm.clearError();

      expect(vm.error, isNull);
    });
  });

  // ── Filtres et tri ────────────────────────────────────────────────────────

  Quest makeQuest({
    required String id,
    String category = 'Sport',
    QuestFrequency frequency = QuestFrequency.daily,
    int difficulty = 2,
    int durationMinutes = 30,
    QuestStatus status = QuestStatus.active,
  }) =>
      Quest(
        id: id,
        userId: 'u1',
        title: 'Q$id',
        estimatedDurationMinutes: durationMinutes,
        frequency: frequency,
        difficulty: difficulty,
        category: category,
        rarity: QuestRarity.common,
        status: status,
        createdAt: DateTime(2024, 1, 1),
      );

  group('filteredActiveQuests', () {
    setUp(() async {
      when(() => auth.userId).thenReturn('u1');
      when(() => questRepo.loadQuests('u1')).thenAnswer((_) async => [
            makeQuest(id: '1', category: 'Sport', frequency: QuestFrequency.daily, difficulty: 3),
            makeQuest(id: '2', category: 'Santé', frequency: QuestFrequency.weekly, difficulty: 1),
            makeQuest(id: '3', category: 'Sport', frequency: QuestFrequency.monthly, difficulty: 2),
            makeQuest(id: '4', category: 'Santé', frequency: QuestFrequency.daily, difficulty: 1,
                status: QuestStatus.completed),
          ]);
      await vm.loadQuests();
    });

    test('sans filtre retourne toutes les quêtes actives', () {
      expect(vm.filteredActiveQuests, hasLength(3));
    });

    test('filtre par catégorie', () {
      vm.setCategoryFilter('Sport');
      expect(vm.filteredActiveQuests.every((q) => q.category == 'Sport'), isTrue);
      expect(vm.filteredActiveQuests, hasLength(2));
    });

    test('filtre par fréquence', () {
      vm.setFrequencyFilter(QuestFrequency.daily);
      expect(vm.filteredActiveQuests.every((q) => q.frequency == QuestFrequency.daily), isTrue);
      expect(vm.filteredActiveQuests, hasLength(1));
    });

    test('tri par difficulté croissante', () {
      vm.setSortOrder(QuestSortOrder.difficultyAsc);
      final difficulties = vm.filteredActiveQuests.map((q) => q.difficulty).toList();
      expect(difficulties, equals([...difficulties]..sort()));
    });

    test('tri par durée croissante', () {
      vm.setSortOrder(QuestSortOrder.durationAsc);
      final durations = vm.filteredActiveQuests.map((q) => q.estimatedDurationMinutes).toList();
      expect(durations, equals([...durations]..sort()));
    });

    test('clearFilters réinitialise tout', () {
      vm.setCategoryFilter('Sport');
      vm.setFrequencyFilter(QuestFrequency.daily);
      vm.setSortOrder(QuestSortOrder.difficultyAsc);

      vm.clearFilters();

      expect(vm.categoryFilter, isNull);
      expect(vm.frequencyFilter, isNull);
      expect(vm.sortOrder, QuestSortOrder.dateDesc);
      expect(vm.filteredActiveQuests, hasLength(3));
    });

    test('availableCategories retourne les catégories distinctes triées', () {
      expect(vm.availableCategories, equals(['Santé', 'Sport']));
    });

    test('désélectionner un filtre catégorie en le réappliquant', () {
      vm.setCategoryFilter('Sport');
      vm.setCategoryFilter(null);
      expect(vm.filteredActiveQuests, hasLength(3));
    });
  });
}
