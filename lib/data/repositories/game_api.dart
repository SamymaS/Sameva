import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/player_stats_model.dart';
import '../models/quest_model.dart';

/// API d'intentions du jeu (Sprint 1).
///
/// Le client ne calcule plus aucune récompense et n'écrit plus jamais
/// `player_stats` ni `ai_validation_credits` : il envoie des intentions
/// (« valider cette quête », « invoquer ») et affiche ce que le serveur
/// renvoie. Toutes les règles vivent dans les fonctions SQL
/// (supabase/migrations/20261102000*) et dans l'Edge Function Oracle.
///
/// Les erreurs métier remontent sous forme de [GameApiException] portant un
/// code stable (ex. `solde_insuffisant`), traduit pour l'UI par
/// [GameApiException.userMessage].
class GameApi {
  final Future<dynamic> Function(String fn, Map<String, dynamic> params) _rpc;
  final Future<dynamic> Function(String name, Map<String, dynamic> body) _function;

  GameApi(SupabaseClient client)
      : _rpc = ((fn, params) => client.rpc(fn, params: params)),
        _function = ((name, body) async =>
            (await client.functions.invoke(name, body: body)).data);

  /// Constructeur de test : transport injecté, aucune dépendance réseau.
  @visibleForTesting
  GameApi.withTransport({
    required Future<dynamic> Function(String fn, Map<String, dynamic> params) rpc,
    required Future<dynamic> Function(String name, Map<String, dynamic> body) function,
  })  : _rpc = rpc,
        _function = function;

  // ── Appels ────────────────────────────────────────────────────────────────

  Future<PlayerServerState> getPlayerState() async =>
      PlayerServerState.fromJson(await _call('get_player_state', const {}));

  /// [timezone] doit être un nom IANA (ex. `Europe/Paris`).
  Future<void> setTimezone(String timezone) async {
    await _call('set_timezone', {'p_timezone': timezone});
  }

  /// Validation déclarative (quêtes sans preuve obligatoire).
  Future<QuestRewardResult> completeQuest(String questId) async =>
      QuestRewardResult.fromJson(await _call('complete_quest', {'p_quest_id': questId}));

  /// Règles quotidiennes (idempotent : à appeler à chaque ouverture).
  Future<DailyResult> claimDaily() async =>
      DailyResult.fromJson(await _call('claim_daily', const {}));

  /// Invocation gacha, payée en Sceaux (ou tirage gratuit quotidien).
  Future<InvokeResult> invoke(String banner, {int count = 1, bool useFree = false}) async =>
      InvokeResult.fromJson(await _call('invoke', {
        'p_banner': banner,
        'p_count': count,
        'p_use_free': useFree,
      }));

  /// TRANSITOIRE (Sprint 3) : débit seul, pour le marché, le craft et la
  /// boutique tant que le catalogue n'est pas en base.
  Future<void> spend({
    required String resource,
    required int amount,
    required String reason,
    String? ref,
  }) async {
    await _call('spend', {
      'p_resource': resource,
      'p_amount': amount,
      'p_reason': reason,
      'p_ref': ref,
    });
  }

  /// TRANSITOIRE (Sprint 3) : gains issus de l'inventaire local, plafonnés
  /// par jour. Le montant accordé peut être inférieur au montant demandé.
  Future<TransitionalReward> claimTransitionalReward(String source, num amount, {String? ref}) async =>
      TransitionalReward.fromJson(await _call('claim_transitional_reward', {
        'p_source': source,
        'p_amount': amount,
        'p_ref': ref,
      }));

  /// Demande le défi de capture (geste + nombre à écrire, tirés au hasard
  /// par le serveur) à afficher AVANT d'ouvrir la caméra. Idempotent tant que
  /// le défi est valide ; [reroll] en tire un autre (une fois par quête).
  Future<CaptureChallenge> requestChallenge(String questId, {bool reroll = false}) async =>
      CaptureChallenge.fromJson(await _call('oracle_challenge', {
        'p_quest_id': questId,
        'p_reroll': reroll,
      }));

  /// Option d'accessibilité « défis sans les mains » (nombre à 3 chiffres
  /// seulement). Enregistrée côté serveur, appliquée aux prochains défis.
  Future<void> setChallengeHandsFree(bool handsFree) async {
    await _call('set_challenge_hands_free', {'p_hands_free': handsFree});
  }

  /// Soumet une preuve photo à l'Oracle avec le défi affiché au joueur. Le
  /// verdict renvoyé est DÉJÀ appliqué côté serveur : si accepté, la quête
  /// est close et récompensée.
  Future<OracleVerdict> submitProof({
    required String questId,
    required String challengeId,
    required String imageBase64,
  }) async {
    try {
      final data = await _function('analyze-quest-proof', {
        'quest_id': questId,
        'challenge_id': challengeId,
        'image_base64': imageBase64,
      });
      return OracleVerdict.fromJson(_asMap(data));
    } on FunctionException catch (e) {
      throw GameApiException.fromFunction(e);
    } on GameApiException {
      rethrow;
    } catch (e) {
      throw GameApiException('erreur_reseau', e.toString());
    }
  }

  // ── Interne ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _call(String fn, Map<String, dynamic> params) async {
    try {
      final data = await _rpc(fn, params);
      return data == null ? const {} : _asMap(data);
    } on PostgrestException catch (e) {
      throw GameApiException.fromPostgrest(e);
    } catch (e) {
      throw GameApiException('erreur_reseau', e.toString());
    }
  }
}

Map<String, dynamic> _asMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  throw const GameApiException('reponse_invalide', 'Réponse serveur inattendue');
}

int _int(dynamic v, [int fallback = 0]) => v is num ? v.toInt() : (int.tryParse('$v') ?? fallback);
double _double(dynamic v, [double fallback = 0]) => v is num ? v.toDouble() : (double.tryParse('$v') ?? fallback);

QuestRarity? rarityFromCode(String? code) => switch (code) {
      'common' => QuestRarity.common,
      'uncommon' => QuestRarity.uncommon,
      'rare' => QuestRarity.rare,
      'epic' => QuestRarity.epic,
      'legendary' => QuestRarity.legendary,
      'mythic' => QuestRarity.mythic,
      _ => null,
    };

// ── Erreurs ─────────────────────────────────────────────────────────────────

/// Erreur métier ou technique renvoyée par le serveur.
class GameApiException implements Exception {
  /// Code stable (ex. `solde_insuffisant`, `photo_deja_utilisee`).
  final String code;
  final String? detail;
  final int? httpStatus;

  const GameApiException(this.code, [this.detail, this.httpStatus]);

  /// Code métier = message de l'exception SQL (`RAISE ... MESSAGE = code`).
  /// Les refus de droits (42501) deviennent `acces_refuse`.
  factory GameApiException.fromPostgrest(PostgrestException e) {
    if (e.code == '42501') return GameApiException('acces_refuse', e.message);
    if (e.code == 'P0001') return GameApiException(e.message, e.details?.toString());
    return GameApiException('erreur_serveur', e.message);
  }

  /// Corps d'erreur de l'Edge Function : `{"error": "<code>"}`.
  factory GameApiException.fromFunction(FunctionException e) {
    final details = e.details;
    String? code;
    int? refunded;
    if (details is Map) {
      code = details['error']?.toString();
      refunded = details['refunded'] is num ? (details['refunded'] as num).toInt() : null;
    }
    return GameApiException(
      code ?? (e.status >= 500 ? 'oracle_indisponible' : 'erreur_serveur'),
      refunded != null && refunded > 0 ? 'energie_rendue' : e.reasonPhrase,
      e.status,
    );
  }

  bool get isBusiness => !const {'erreur_reseau', 'erreur_serveur', 'reponse_invalide'}.contains(code);

  /// Message lisible, en français, pour l'utilisateur.
  String get userMessage => switch (code) {
        'solde_insuffisant' => 'Solde insuffisant.',
        'preuve_requise' => 'Cette quête se valide uniquement avec une photo analysée par MougiBot.',
        'quete_trop_recente' => 'Patiente encore un peu : une quête se valide au moins 10 minutes après sa création.',
        'quete_introuvable' => 'Quête introuvable.',
        'quete_deja_cloturee' => 'Cette quête est déjà terminée.',
        'quete_cloturee' => 'Une quête terminée ne peut plus être modifiée.',
        'champ_protege' => 'Ce champ ne peut pas être modifié.',
        'champ_verrouille' => 'Ce champ est figé : titre, catégorie, difficulté et preuve ne se modifient plus 10 minutes après la création (ou dès qu\'une preuve est soumise), et une échéance ne peut qu\'être avancée.',
        'quete_echue' => 'L\'échéance est passée : cette quête ne peut plus être supprimée.',
        'fuseau_verrouille' => 'Le fuseau horaire ne peut être changé qu\'une fois tous les 30 jours.',
        'categorie_reservee' => 'Cette catégorie est réservée.',
        'energie_insuffisante' => 'Plus d\'énergie pour l\'Oracle aujourd\'hui. Elle se recharge chaque jour.',
        'photo_deja_utilisee' => 'Cette photo a déjà servi à valider une quête. Prends-en une nouvelle.',
        'analyse_en_cours' => 'Une analyse est déjà en cours pour cette quête.',
        'plafond_atteint' => 'Limite du jour atteinte. Reviens demain !',
        'gratuit_deja_utilise' => 'Ton invocation gratuite du jour est déjà utilisée.',
        'gratuit_indisponible' => 'Pas d\'invocation gratuite sur cette bannière.',
        'banniere_inconnue' => 'Bannière indisponible.',
        'nombre_invalide' => 'Nombre d\'invocations invalide.',
        'montant_invalide' => 'Montant invalide.',
        'motif_invalide' || 'source_invalide' || 'ressource_invalide' => 'Action non autorisée.',
        'format_non_supporte' => 'Format d\'image non supporté (JPEG ou PNG).',
        'defi_requis' || 'defi_invalide' => 'Le défi de capture n\'est plus valable. Un nouveau défi va s\'afficher.',
        'analyse_illisible' => 'MougiBot n\'a pas réussi à lire ta photo. Reprends-la, bien cadrée et sans texte autour.',
        'defi_expire' => 'Le défi a expiré : reprends la photo avec le nouveau défi.',
        'relance_epuisee' => 'Tu as déjà changé le défi de cette quête.',
        'image_trop_lourde' => 'Image trop lourde (5 Mo maximum).',
        'image_invalide' || 'image_requise' => 'Image illisible, reprends une photo.',
        'oracle_indisponible' => detail == 'energie_rendue'
            ? 'MougiBot est indisponible pour le moment. Ton énergie t\'a été rendue.'
            : 'MougiBot est indisponible pour le moment. Réessaie dans un instant.',
        'non_authentifie' => 'Session expirée, reconnecte-toi.',
        'acces_refuse' => 'Action non autorisée.',
        'erreur_reseau' => 'Connexion impossible. Vérifie ton réseau.',
        _ => 'Une erreur est survenue. Réessaie.',
      };

  @override
  String toString() => 'GameApiException($code${detail != null ? ', $detail' : ''})';
}

// ── Modèles de résultat ─────────────────────────────────────────────────────

/// Palier de flamme atteint (cristaux crédités côté serveur, objet généré
/// localement depuis [itemRarity] jusqu'au Sprint 3).
class StreakMilestone {
  final int days;
  final int crystals;
  final QuestRarity? itemRarity;

  const StreakMilestone({required this.days, required this.crystals, this.itemRarity});

  factory StreakMilestone.fromJson(Map<String, dynamic> j) => StreakMilestone(
        days: _int(j['days']),
        crystals: _int(j['crystals']),
        itemRarity: rarityFromCode(j['item_rarity'] as String?),
      );
}

/// Résultat de `complete_quest` (et `rewards` d'un verdict Oracle accepté).
class QuestRewardResult {
  final String questId;
  final String mode; // 'oracle' | 'declaratif'
  final int xp;
  final int gold;
  final int seals;
  final int crystals;
  final int hpHealed;
  final int levelBefore;
  final int levelAfter;
  final int levelUpCrystals;
  final int streak;
  final List<StreakMilestone> streakMilestones;
  final QuestRarity? dropRarity;
  final Map<String, dynamic> factors;

  const QuestRewardResult({
    required this.questId,
    required this.mode,
    required this.xp,
    required this.gold,
    required this.seals,
    required this.crystals,
    required this.hpHealed,
    required this.levelBefore,
    required this.levelAfter,
    required this.levelUpCrystals,
    required this.streak,
    required this.streakMilestones,
    required this.dropRarity,
    required this.factors,
  });

  bool get didLevelUp => levelAfter > levelBefore;

  factory QuestRewardResult.fromJson(Map<String, dynamic> j) => QuestRewardResult(
        questId: j['quest_id']?.toString() ?? '',
        mode: j['mode'] as String? ?? 'declaratif',
        xp: _int(j['xp']),
        gold: _int(j['gold']),
        seals: _int(j['seals']),
        crystals: _int(j['crystals']),
        hpHealed: _int(j['hp_healed']),
        levelBefore: _int(j['level_before'], 1),
        levelAfter: _int(j['level_after'], 1),
        levelUpCrystals: _int(j['level_up_crystals']),
        streak: _int(j['streak']),
        streakMilestones: (j['streak_milestones'] as List? ?? const [])
            .map((m) => StreakMilestone.fromJson(_asMap(m)))
            .toList(),
        dropRarity: j['drop'] is Map ? rarityFromCode((j['drop'] as Map)['rarity'] as String?) : null,
        factors: j['factors'] is Map ? _asMap(j['factors']) : const {},
      );
}

/// Résultat de `claim_daily`.
class DailyResult {
  final bool firstToday;
  final int loginGold;
  final int loginSeals;
  final int energyGranted;
  final List<({String id, String title})> missedQuests;
  final int hpLost;
  final int hpRegenerated;
  final bool streakLost;

  const DailyResult({
    required this.firstToday,
    required this.loginGold,
    required this.loginSeals,
    required this.energyGranted,
    required this.missedQuests,
    required this.hpLost,
    required this.hpRegenerated,
    required this.streakLost,
  });

  factory DailyResult.fromJson(Map<String, dynamic> j) {
    final login = j['login_reward'] is Map ? _asMap(j['login_reward']) : const <String, dynamic>{};
    return DailyResult(
      firstToday: j['first_today'] == true,
      loginGold: _int(login['gold']),
      loginSeals: _int(login['seals']),
      energyGranted: _int(j['energy_granted']),
      missedQuests: (j['missed_quests'] as List? ?? const [])
          .map((m) => _asMap(m))
          .map((m) => (id: m['id'].toString(), title: m['title']?.toString() ?? ''))
          .toList(),
      hpLost: _int(j['hp_lost']),
      hpRegenerated: _int(j['hp_regenerated']),
      streakLost: j['streak_lost'] == true,
    );
  }
}

/// Un tirage de gacha.
class PullResult {
  final QuestRarity rarity;
  final bool byPity;
  const PullResult(this.rarity, this.byPity);
}

/// Résultat de `invoke`.
class InvokeResult {
  final String banner;
  final List<PullResult> results;
  final int sealsSpent;
  final bool freeUsed;
  final int epicGuaranteedIn;
  final int legendaryGuaranteedIn;

  const InvokeResult({
    required this.banner,
    required this.results,
    required this.sealsSpent,
    required this.freeUsed,
    required this.epicGuaranteedIn,
    required this.legendaryGuaranteedIn,
  });

  factory InvokeResult.fromJson(Map<String, dynamic> j) {
    final pity = j['pity'] is Map ? _asMap(j['pity']) : const <String, dynamic>{};
    return InvokeResult(
      banner: j['banner']?.toString() ?? '',
      results: (j['results'] as List? ?? const [])
          .map((r) => _asMap(r))
          .map((r) => PullResult(rarityFromCode(r['rarity'] as String?) ?? QuestRarity.common, r['by_pity'] == true))
          .toList(),
      sealsSpent: _int(j['seals_spent']),
      freeUsed: j['free_used'] == true,
      epicGuaranteedIn: _int(pity['epic_guaranteed_in']),
      legendaryGuaranteedIn: _int(pity['legendary_guaranteed_in']),
    );
  }
}

/// Résultat de `claim_transitional_reward`.
class TransitionalReward {
  final String resource;
  final double granted;
  final bool capped;

  const TransitionalReward({required this.resource, required this.granted, required this.capped});

  int get grantedInt => granted.floor();

  factory TransitionalReward.fromJson(Map<String, dynamic> j) => TransitionalReward(
        resource: j['resource']?.toString() ?? '',
        granted: _double(j['granted']),
        capped: j['capped'] == true,
      );
}

/// Verdict de l'Oracle, déjà appliqué côté serveur.
class OracleVerdict {
  final String proofId;
  final bool accepted;
  final int score;
  final int threshold;
  final String explanation;
  final QuestRewardResult? rewards;

  /// Défi de capture demandé (null si aucun) et sa présence sur la photo.
  final String? challenge;
  final bool challengeOk;

  const OracleVerdict({
    required this.proofId,
    required this.accepted,
    required this.score,
    required this.threshold,
    required this.explanation,
    required this.rewards,
    this.challenge,
    this.challengeOk = false,
  });

  /// Refus dû uniquement au défi absent (photo correcte mais pas « fraîche »).
  bool get rejectedForChallenge => !accepted && challenge != null && !challengeOk && score >= threshold;

  factory OracleVerdict.fromJson(Map<String, dynamic> j) => OracleVerdict(
        proofId: j['proof_id']?.toString() ?? '',
        accepted: j['accepted'] == true,
        score: _int(j['score']).clamp(0, 100),
        threshold: _int(j['threshold'], 70),
        explanation: j['explanation']?.toString() ?? '',
        rewards: j['rewards'] is Map ? QuestRewardResult.fromJson(_asMap(j['rewards'])) : null,
        challenge: j['challenge']?.toString(),
        challengeOk: j['challenge_ok'] == true,
      );
}

/// Défi de capture : un geste et un nombre à écrire sur un papier (ou le
/// nombre seul en mode « sans les mains »), tirés au hasard par le serveur.
/// Une photo prise avant le défi ne peut pas les contenir : c'est ce qui
/// prouve qu'elle vient d'être prise.
class CaptureChallenge {
  final String id;
  final String label;

  /// Geste demandé (null en mode « sans les mains »).
  final String? gesture;

  /// Nombre à écrire sur un papier.
  final String number;
  final bool handsFree;
  final int rerollsLeft;

  /// Échéance calculée à partir de la durée restante renvoyée par le serveur
  /// et de l'heure de réception : insensible au décalage d'horloge du téléphone.
  final DateTime expiresAt;

  const CaptureChallenge({
    required this.id,
    required this.label,
    required this.gesture,
    required this.number,
    required this.handsFree,
    required this.rerollsLeft,
    required this.expiresAt,
  });

  bool isExpired([DateTime? now]) => !(now ?? DateTime.now()).isBefore(expiresAt);

  Duration remaining([DateTime? now]) {
    final d = expiresAt.difference(now ?? DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  factory CaptureChallenge.fromJson(Map<String, dynamic> j, {DateTime? receivedAt}) {
    final at = receivedAt ?? DateTime.now();
    final expiresIn = j['expires_in'] is num ? (j['expires_in'] as num).toInt() : 180;
    return CaptureChallenge(
      id: j['challenge_id']?.toString() ?? '',
      label: j['label']?.toString() ?? '',
      gesture: j['gesture']?.toString(),
      number: j['number']?.toString() ?? '',
      handsFree: j['hands_free'] == true,
      rerollsLeft: j['rerolls_left'] is num ? (j['rerolls_left'] as num).toInt() : 0,
      expiresAt: at.add(Duration(seconds: expiresIn)),
    );
  }
}

/// État gacha d'une bannière.
class GachaBannerState {
  final int sinceEpic;
  final int sinceLegendary;
  final bool freeAvailable;
  const GachaBannerState({required this.sinceEpic, required this.sinceLegendary, required this.freeAvailable});
}

/// Résultat de `get_player_state`.
class PlayerServerState {
  final PlayerStats stats;
  final int xpForNextLevel;
  final int energy;
  final bool premium;
  final Map<String, GachaBannerState> gacha;

  const PlayerServerState({
    required this.stats,
    required this.xpForNextLevel,
    required this.energy,
    required this.premium,
    required this.gacha,
  });

  factory PlayerServerState.fromJson(Map<String, dynamic> j) {
    final gacha = <String, GachaBannerState>{};
    if (j['gacha'] is Map) {
      _asMap(j['gacha']).forEach((banner, raw) {
        final g = _asMap(raw);
        gacha[banner] = GachaBannerState(
          sinceEpic: _int(g['since_epic']),
          sinceLegendary: _int(g['since_legendary']),
          freeAvailable: g['free_available'] != false,
        );
      });
    }
    return PlayerServerState(
      stats: PlayerStats.fromSupabaseMap(_asMap(j['stats'] ?? const <String, dynamic>{})),
      xpForNextLevel: _int(j['xp_for_next_level'], 150),
      energy: _int(j['energy']),
      premium: j['premium'] == true,
      gacha: gacha,
    );
  }
}
