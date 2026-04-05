import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sameva/data/models/quest_model.dart';
import 'package:sameva/data/repositories/player_repository.dart';
import 'package:sameva/data/repositories/quest_repository.dart';
import 'package:sameva/presentation/view_models/auth_view_model.dart';
import 'package:sameva/presentation/view_models/profile_view_model.dart';
import 'package:sameva/presentation/view_models/player_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockAuth extends Mock implements AuthViewModel {}

class _MockPlayerRepo extends Mock implements PlayerRepository {}

class _MockQuestRepo extends Mock implements QuestRepository {}

class _MockUser extends Mock implements User {}

void main() {
  late _MockAuth auth;
  late _MockPlayerRepo playerRepo;
  late _MockQuestRepo questRepo;
  late ProfileViewModel vm;

  setUpAll(() {
    registerFallbackValue(PlayerStats());
  });

  setUp(() {
    auth = _MockAuth();
    playerRepo = _MockPlayerRepo();
    questRepo = _MockQuestRepo();
    vm = ProfileViewModel(auth, playerRepo, questRepo);
  });

  group('ProfileViewModel', () {
    test('experienceForLevel aligné sur la formule joueur', () {
      expect(vm.experienceForLevel(1), 150);
    });

    test('load charge stats locales puis quêtes', () async {
      final stats = PlayerStats(level: 2, streak: 3);
      final quests = [
        Quest(
          id: '1',
          userId: 'u',
          title: 'Q',
          estimatedDurationMinutes: 1,
          frequency: QuestFrequency.oneOff,
          difficulty: 1,
          category: 'Autre',
          rarity: QuestRarity.common,
          status: QuestStatus.completed,
        ),
      ];
      when(() => playerRepo.loadLocalStats()).thenReturn(stats);
      when(() => playerRepo.fetchRemoteStats('u')).thenAnswer((_) async => null);
      when(() => questRepo.loadQuests('u')).thenAnswer((_) async => quests);

      await vm.load('u');

      expect(vm.isLoading, isFalse);
      expect(vm.stats?.level, 2);
      expect(vm.streak, 3);
      expect(vm.completedCount, 1);
    });

    test('load avec erreur quêtes laisse une liste vide', () async {
      when(() => playerRepo.loadLocalStats()).thenReturn(PlayerStats());
      when(() => playerRepo.fetchRemoteStats('u')).thenAnswer((_) async => null);
      when(() => questRepo.loadQuests('u')).thenThrow(Exception('net'));

      await vm.load('u');

      expect(vm.quests, isEmpty);
      expect(vm.isLoading, isFalse);
    });

    test('userEmail expose l\'email Supabase', () async {
      final user = _MockUser();
      when(() => user.email).thenReturn('hero@sameva.app');
      when(() => auth.user).thenReturn(user);
      when(() => playerRepo.loadLocalStats()).thenReturn(PlayerStats());
      when(() => playerRepo.fetchRemoteStats('u')).thenAnswer((_) async => null);
      when(() => questRepo.loadQuests('u')).thenAnswer((_) async => []);

      await vm.load('u');

      expect(vm.userEmail, 'hero@sameva.app');
    });

    test('signOut délègue à AuthViewModel', () async {
      when(() => auth.signOut()).thenAnswer((_) async {});

      await vm.signOut();

      verify(() => auth.signOut()).called(1);
    });
  });
}
