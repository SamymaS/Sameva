import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sameva/data/models/quest_model.dart';
import 'package:sameva/data/repositories/game_api.dart';
import 'package:sameva/data/repositories/player_repository.dart';
import 'package:sameva/data/repositories/quest_repository.dart';
import 'package:sameva/presentation/use_cases/complete_quest_use_case.dart';
import 'package:sameva/presentation/view_models/inventory_view_model.dart';
import 'package:sameva/presentation/view_models/player_view_model.dart';
import 'package:sameva/presentation/view_models/quest_view_model.dart';

class _MockPlayerRepository extends Mock implements PlayerRepository {}

class _MockQuestRepository extends Mock implements QuestRepository {}

class _MockGameApi extends Mock implements GameApi {}

class _MockBox extends Mock implements Box<dynamic> {}

Quest _quest({String id = 'q1', ValidationType type = ValidationType.manual}) => Quest(
      id: id,
      userId: 'u1',
      title: 'Ranger le salon',
      difficulty: 2,
      category: 'Maison',
      rarity: QuestRarity.common,
      frequency: QuestFrequency.oneOff,
      status: QuestStatus.active,
      validationType: type,
      estimatedDurationMinutes: 30,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    );

QuestRewardResult _rewards({String? drop, int levelAfter = 1, List<Map<String, dynamic>> milestones = const []}) =>
    QuestRewardResult.fromJson({
      'quest_id': 'q1',
      'mode': 'declaratif',
      'xp': 15,
      'gold': 20,
      'seals': 0,
      'crystals': 0,
      'level_before': 1,
      'level_after': levelAfter,
      'level_up_crystals': levelAfter > 1 ? 4 : 0,
      'streak': 1,
      'streak_milestones': milestones,
      'drop': drop == null ? null : {'rarity': drop},
    });

void main() {
  late Directory hiveDir;
  late _MockPlayerRepository playerRepo;
  late _MockQuestRepository questRepo;
  late _MockGameApi api;
  late PlayerViewModel playerVm;
  late QuestViewModel questVm;
  late InventoryViewModel inventoryVm;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(PlayerStats());
    hiveDir = await Directory.systemTemp.createTemp('sameva_complete_quest_test_');
    Hive.init(hiveDir.path);
    await Hive.openBox('settings');
  });

  tearDownAll(() async {
    await Hive.close();
    if (hiveDir.existsSync()) hiveDir.deleteSync(recursive: true);
  });

  setUp(() async {
    playerRepo = _MockPlayerRepository();
    questRepo = _MockQuestRepository();
    api = _MockGameApi();
    when(() => playerRepo.api).thenReturn(api);
    when(() => playerRepo.loadLocalStats()).thenReturn(PlayerStats());
    when(() => playerRepo.saveLocalStats(any())).thenAnswer((_) async {});
    when(() => playerRepo.fetchServerState()).thenAnswer((_) async => PlayerServerState(
        stats: PlayerStats(gold: 20, totalExperience: 15, totalQuestsCompleted: 1),
        xpForNextLevel: 150,
        energy: 3,
        premium: false,
        gacha: const {}));
    playerVm = PlayerViewModel(playerRepo);
    await playerVm.loadPlayerStats('u1');

    when(() => questRepo.loadQuests('u1')).thenAnswer((_) async => [_quest()]);
    questVm = QuestViewModel(questRepo);
    await questVm.loadQuests('u1');

    final box = _MockBox();
    when(() => box.get(any())).thenReturn(null);
    when(() => box.put(any(), any())).thenAnswer((_) async {});
    inventoryVm = InventoryViewModel(box);
  });

  CompleteQuestUseCase useCase() => CompleteQuestUseCase(
        questProvider: questVm,
        playerProvider: playerVm,
        inventoryProvider: inventoryVm,
      );

  test('validation déclarative : le serveur calcule, le client reflète', () async {
    when(() => api.completeQuest('q1')).thenAnswer((_) async => _rewards());

    final result = await useCase().execute(_quest());

    verify(() => api.completeQuest('q1')).called(1);
    expect(result.rewards.xp, 15);
    expect(result.rewards.gold, 20);
    expect(questVm.quests.single.status, QuestStatus.completed);
    expect(playerVm.stats?.gold, 20, reason: 'or relu depuis le serveur');
    expect(result.newAchievements, contains('first_quest'));
  });

  test('aucun calcul local : seule la rareté serveur crée un objet', () async {
    when(() => api.completeQuest('q1')).thenAnswer((_) async => _rewards(drop: 'rare'));

    final result = await useCase().execute(_quest());

    expect(result.droppedItem, isNotNull);
    expect(result.droppedItem!.rarity, QuestRarity.rare);
    expect(inventoryVm.items, hasLength(1));
  });

  test('palier de flamme : l\'objet de la rareté indiquée est ajouté', () async {
    when(() => api.completeQuest('q1')).thenAnswer((_) async => _rewards(milestones: [
          {'days': 7, 'crystals': 5, 'item_rarity': 'common'}
        ]));

    final result = await useCase().execute(_quest());

    expect(result.milestoneItems, hasLength(1));
    expect(result.milestoneItems.single.rarity, QuestRarity.common);
  });

  test('montée de niveau renvoyée par le serveur', () async {
    when(() => api.completeQuest('q1')).thenAnswer((_) async => _rewards(levelAfter: 2));

    final result = await useCase().execute(_quest());

    expect(result.didLevelUp, isTrue);
    expect(result.newLevel, 2);
    expect(result.crystalsFromLevelUp, 4);
  });

  test('refus serveur (preuve requise) : rien n\'est modifié localement', () async {
    when(() => api.completeQuest('q1')).thenThrow(const GameApiException('preuve_requise'));

    await expectLater(
      useCase().execute(_quest(type: ValidationType.photo)),
      throwsA(isA<GameApiException>().having((e) => e.code, 'code', 'preuve_requise')),
    );
    expect(questVm.quests.single.status, QuestStatus.active);
    expect(inventoryVm.items, isEmpty);
  });

  test('verdict Oracle accepté : pas de second appel de complétion', () async {
    final result = await useCase().applyOracleVerdict(_quest(type: ValidationType.photo), _rewards());

    verifyNever(() => api.completeQuest(any()));
    expect(result.rewards.xp, 15);
    expect(questVm.quests.single.status, QuestStatus.completed);
  });
}
