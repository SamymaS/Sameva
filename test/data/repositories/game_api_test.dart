import 'package:flutter_test/flutter_test.dart';
import 'package:sameva/data/models/quest_model.dart';
import 'package:sameva/data/repositories/game_api.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tests de l'API d'intentions (Sprint 1) : parsing des réponses SQL et
/// extraction des codes d'erreur métier.
void main() {
  late List<(String, Map<String, dynamic>)> calls;

  GameApi apiReturning(dynamic rpcData, {dynamic functionData}) {
    calls = [];
    return GameApi.withTransport(
      rpc: (fn, params) async {
        calls.add((fn, params));
        return rpcData;
      },
      function: (name, body) async {
        calls.add((name, body));
        return functionData;
      },
    );
  }

  GameApi apiThrowing(Object error) => GameApi.withTransport(
        rpc: (_, __) async => throw error,
        function: (_, __) async => throw error,
      );

  group('appels', () {
    test('completeQuest envoie p_quest_id et parse la récompense', () async {
      final api = apiReturning({
        'quest_id': 'q1',
        'mode': 'declaratif',
        'xp': 15,
        'gold': 20,
        'seals': 0,
        'crystals': 0,
        'hp_healed': 5,
        'level_before': 1,
        'level_after': 2,
        'level_up_crystals': 4,
        'streak': 7,
        'streak_milestones': [
          {'days': 7, 'crystals': 5, 'item_rarity': 'common'}
        ],
        'drop': {'rarity': 'rare'},
        'factors': {'validation': 0.5, 'daily_rank': 1},
      });

      final r = await api.completeQuest('q1');

      expect(calls.single.$1, 'complete_quest');
      expect(calls.single.$2, {'p_quest_id': 'q1'});
      expect(r.xp, 15);
      expect(r.didLevelUp, isTrue);
      expect(r.levelUpCrystals, 4);
      expect(r.streakMilestones.single.itemRarity, QuestRarity.common);
      expect(r.dropRarity, QuestRarity.rare);
      expect(r.factors['validation'], 0.5);
    });

    test('invoke transmet bannière, nombre et gratuit, et lit la pity', () async {
      final api = apiReturning({
        'banner': 'objets',
        'results': [
          {'rarity': 'epic', 'by_pity': true},
          {'rarity': 'common', 'by_pity': false},
        ],
        'seals_spent': 90,
        'free_used': false,
        'pity': {'epic_guaranteed_in': 20, 'legendary_guaranteed_in': 61},
      });

      final r = await api.invoke('objets', count: 10);

      expect(calls.single.$2, {'p_banner': 'objets', 'p_count': 10, 'p_use_free': false});
      expect(r.results.first.rarity, QuestRarity.epic);
      expect(r.results.first.byPity, isTrue);
      expect(r.sealsSpent, 90);
      expect(r.legendaryGuaranteedIn, 61);
    });

    test('claimDaily lit la connexion, les quêtes manquées et l\'énergie', () async {
      final api = apiReturning({
        'first_today': true,
        'login_reward': {'gold': 30, 'seals': 1},
        'energy_granted': 2,
        'missed_quests': [
          {'id': 'm1', 'title': 'Courir'}
        ],
        'hp_lost': 30,
        'hp_regenerated': 0,
        'streak_lost': false,
      });

      final r = await api.claimDaily();

      expect(r.firstToday, isTrue);
      expect(r.loginGold, 30);
      expect(r.loginSeals, 1);
      expect(r.energyGranted, 2);
      expect(r.missedQuests.single.title, 'Courir');
      expect(r.hpLost, 30);
    });

    test('claimTransitionalReward renvoie le montant réellement accordé', () async {
      final api = apiReturning({'resource': 'gold', 'granted': 100, 'capped': true});
      final r = await api.claimTransitionalReward('vente_objet', 500, ref: 'epee');
      expect(calls.single.$2, {'p_source': 'vente_objet', 'p_amount': 500, 'p_ref': 'epee'});
      expect(r.grantedInt, 100);
      expect(r.capped, isTrue);
    });

    test('getPlayerState lit les stats serveur et l\'état gacha', () async {
      final api = apiReturning({
        'stats': {'level': 3, 'gold': 70, 'seals': 4, 'total_experience': 500, 'is_exhausted': false},
        'xp_for_next_level': 450,
        'energy': 2,
        'premium': true,
        'gacha': {
          'objets': {'since_epic': 3, 'since_legendary': 3, 'free_available': false}
        },
      });

      final s = await api.getPlayerState();

      expect(s.stats.level, 3);
      expect(s.stats.seals, 4);
      expect(s.xpForNextLevel, 450);
      expect(s.premium, isTrue);
      expect(s.gacha['objets']!.freeAvailable, isFalse);
    });

    test('submitProof envoie quest_id et image, et lit un verdict accepté', () async {
      final api = apiReturning(null, functionData: {
        'proof_id': 'p1',
        'quest_id': 'q1',
        'accepted': true,
        'score': 88,
        'threshold': 70,
        'explanation': 'Bravo',
        'rewards': {'quest_id': 'q1', 'mode': 'oracle', 'xp': 30, 'gold': 40, 'seals': 1},
      });

      final v = await api.submitProof(questId: 'q1', challengeId: 'c1', imageBase64: 'AAAA');

      expect(calls.single.$1, 'analyze-quest-proof');
      expect(calls.single.$2, {'quest_id': 'q1', 'challenge_id': 'c1', 'image_base64': 'AAAA'});
      expect(v.accepted, isTrue);
      expect(v.threshold, 70);
      expect(v.rewards?.seals, 1);
    });

    test('submitProof : un refus n\'a pas de récompense', () async {
      final api = apiReturning(null, functionData: {
        'proof_id': 'p1',
        'accepted': false,
        'score': 40,
        'threshold': 70,
        'explanation': 'Photo floue',
        'rewards': null,
      });
      final v = await api.submitProof(questId: 'q1', challengeId: 'c1', imageBase64: 'AAAA');
      expect(v.accepted, isFalse);
      expect(v.rewards, isNull);
    });
  });

  group('défi de capture', () {
    test('requestChallenge envoie la quête et la relance, parse le défi', () async {
      final api = apiReturning({
        'challenge_id': 'c1',
        'label': 'un pouce levé, et le nombre 47 écrit sur un papier',
        'gesture': 'un pouce levé',
        'number': '47',
        'hands_free': false,
        'expires_in': 175,
        'rerolls_left': 1,
      });
      final c = await api.requestChallenge('q1', reroll: true);
      expect(calls.single.$1, 'oracle_challenge');
      expect(calls.single.$2, {'p_quest_id': 'q1', 'p_reroll': true});
      expect(c.gesture, 'un pouce levé');
      expect(c.number, '47');
      expect(c.rerollsLeft, 1);
      expect(c.remaining().inSeconds, inInclusiveRange(173, 175));
    });

    test('l\'échéance vient de la durée restante, pas de l\'horloge du téléphone', () {
      final received = DateTime(2030, 1, 1, 12);
      final c = CaptureChallenge.fromJson({
        'challenge_id': 'c1',
        'label': 'le nombre 305 écrit sur un papier posé bien en vue',
        'number': '305',
        'hands_free': true,
        // Horodatage serveur très différent : ignoré.
        'expires_at': '2020-01-01T00:00:00Z',
        'expires_in': 120,
      }, receivedAt: received);
      expect(c.expiresAt, received.add(const Duration(seconds: 120)));
      expect(c.gesture, isNull);
      expect(c.isExpired(received.add(const Duration(seconds: 121))), isTrue);
    });

    test('setChallengeHandsFree appelle la RPC dédiée', () async {
      final api = apiReturning(null);
      await api.setChallengeHandsFree(true);
      expect(calls.single.$1, 'set_challenge_hands_free');
      expect(calls.single.$2, {'p_hands_free': true});
    });

    test('verdict : bonne photo mais défi non vu → refus « défi »', () async {
      final api = apiReturning(null, functionData: {
        'proof_id': 'p1',
        'accepted': false,
        'score': 95,
        'threshold': 70,
        'explanation': 'Chambre impeccable',
        'challenge': 'un pouce levé, et le nombre 47 écrit sur un papier',
        'challenge_ok': false,
        'rewards': null,
      });
      final v = await api.submitProof(questId: 'q1', challengeId: 'c1', imageBase64: 'AAAA');
      expect(v.rejectedForChallenge, isTrue);
    });

    test('messages dédiés : défi expiré, analyse illisible', () {
      expect(const GameApiException('defi_expire').userMessage, contains('expiré'));
      expect(const GameApiException('analyse_illisible').userMessage, contains('MougiBot'));
    });
  });

  group('erreurs', () {
    test('une erreur métier SQL (P0001) expose son code stable', () async {
      final api = apiThrowing(const PostgrestException(
          message: 'solde_insuffisant', code: 'P0001', details: 'seals : solde 3, demandé 10'));
      await expectLater(
        api.invoke('objets'),
        throwsA(isA<GameApiException>()
            .having((e) => e.code, 'code', 'solde_insuffisant')
            .having((e) => e.isBusiness, 'isBusiness', isTrue)),
      );
    });

    test('un refus de droits (42501) devient acces_refuse', () async {
      final api = apiThrowing(const PostgrestException(message: 'permission denied', code: '42501'));
      await expectLater(api.claimDaily(),
          throwsA(isA<GameApiException>().having((e) => e.code, 'code', 'acces_refuse')));
    });

    test('une panne réseau devient erreur_reseau', () async {
      final api = apiThrowing(Exception('SocketException'));
      await expectLater(api.getPlayerState(),
          throwsA(isA<GameApiException>().having((e) => e.code, 'code', 'erreur_reseau')));
    });

    test('Edge Function : le code vient du corps {"error": ...}', () async {
      final api = apiThrowing(const FunctionException(status: 409, details: {'error': 'photo_deja_utilisee'}));
      await expectLater(
        api.submitProof(questId: 'q1', challengeId: 'c1', imageBase64: 'AAAA'),
        throwsA(isA<GameApiException>()
            .having((e) => e.code, 'code', 'photo_deja_utilisee')
            .having((e) => e.httpStatus, 'status', 409)),
      );
    });

    test('Edge Function 502 avec énergie rendue : message adapté', () async {
      final api = apiThrowing(
          const FunctionException(status: 502, details: {'error': 'oracle_indisponible', 'refunded': 1}));
      try {
        await api.submitProof(questId: 'q1', challengeId: 'c1', imageBase64: 'AAAA');
        fail('doit lever');
      } on GameApiException catch (e) {
        expect(e.code, 'oracle_indisponible');
        expect(e.userMessage, contains('rendue'));
      }
    });

    test('chaque code métier connu a un message français dédié', () {
      const codes = [
        'solde_insuffisant', 'preuve_requise', 'quete_trop_recente', 'energie_insuffisante',
        'photo_deja_utilisee', 'gratuit_deja_utilise', 'plafond_atteint', 'champ_verrouille',
        'quete_echue', 'fuseau_verrouille', 'quete_deja_cloturee', 'analyse_en_cours',
      ];
      const generic = 'Une erreur est survenue. Réessaie.';
      for (final c in codes) {
        expect(GameApiException(c).userMessage, isNot(generic), reason: c);
      }
    });
  });
}
