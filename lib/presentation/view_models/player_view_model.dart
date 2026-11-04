import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/player_stats_model.dart';
import '../../data/repositories/game_api.dart';
import '../../data/repositories/player_repository.dart';

// Re-export pour la compatibilité des imports existants
export '../../data/models/player_stats_model.dart';

/// ViewModel des statistiques joueur.
///
/// Sprint 1 : le serveur est l'unique autorité. Ce ViewModel ne modifie plus
/// jamais l'or, l'XP, les cristaux, les PV ou la flamme lui-même : il envoie
/// des intentions via [GameApi] puis relit l'état serveur ([refresh]).
/// Hive ne sert plus que de cache d'affichage.
///
/// Abonné aux streams [onSignedOut] et [onSignedIn] pour le lifecycle auth :
/// - [onSignedOut] → [reset()] : vide les stats en mémoire.
/// - [onSignedIn] → [loadPlayerStats(uid)] (garde idempotente si déjà chargé).
class PlayerViewModel with ChangeNotifier {
  final PlayerRepository _repo;

  /// Injecté en test pour contourner l'accès à Supabase.instance.
  final String? _testUserId;

  StreamSubscription<void>? _signedOutSub;
  StreamSubscription<void>? _signedInSub;

  PlayerStats? _stats;
  int _xpForNextLevel = 150;
  int _energy = 0;
  bool _premium = false;
  Map<String, GachaBannerState> _gacha = const {};

  PlayerViewModel(
    this._repo, {
    Stream<void>? onSignedOut,
    Stream<void>? onSignedIn,
    String? testUserId,
  }) : _testUserId = testUserId {
    if (onSignedOut != null) {
      _signedOutSub = onSignedOut.listen((_) => reset());
    }
    if (onSignedIn != null) {
      _signedInSub = onSignedIn.listen((_) async {
        if (_stats != null) return;
        final uid = _testUserId ?? _supabaseUserId;
        if (uid == null) return;
        await loadPlayerStats(uid);
      });
    }
  }

  String? get _supabaseUserId {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _signedOutSub?.cancel();
    _signedInSub?.cancel();
    super.dispose();
  }

  GameApi get api => _repo.api;
  PlayerStats? get stats => _stats;
  bool get isInitialized => _stats != null;
  bool get hasStreakBonus => _stats != null && _stats!.streak >= 7;

  /// Énergie de l'Oracle connue lors du dernier rafraîchissement.
  int get energy => _energy;
  bool get isPremium => _premium;

  /// État gacha par bannière (`objets`, `compagnons`).
  Map<String, GachaBannerState> get gacha => _gacha;

  /// XP requise pour passer au niveau suivant (fournie par le serveur).
  int get xpForNextLevel => _xpForNextLevel;

  /// Même formule que le serveur (`level.xp_factor` × niveau), pour les
  /// affichages hors-ligne.
  int experienceForLevel(int level) => 150 * level;

  // ── Chargement ────────────────────────────────────────────────────────────

  Future<void> loadPlayerStats(String userId) async {
    // TODO(Sprint 2) : envoyer le fuseau IANA de l'appareil via
    // api.setTimezone (une seule fois, le serveur le verrouille 30 jours).
    // DateTime.timeZoneName ne fournit pas de nom IANA : le serveur garde
    // Europe/Paris par défaut d'ici là.
    _stats = _repo.loadLocalStats();
    notifyListeners();
    await refresh();
  }

  /// Relit l'état faisant autorité. En cas d'erreur réseau, le cache reste
  /// affiché (rien n'est jamais écrit côté serveur depuis le client).
  Future<void> refresh() async {
    try {
      final state = await _repo.fetchServerState();
      _applyServerState(state);
      await _repo.saveLocalStats(_stats!);
      notifyListeners();
    } catch (e) {
      debugPrint('PlayerViewModel: rafraîchissement impossible, cache conservé: $e');
    }
  }

  void _applyServerState(PlayerServerState state) {
    // Les succès restent locaux jusqu'au Sprint 3 : on fusionne ceux du cache.
    final achievements = <String, int>{
      ...state.stats.achievements,
      ...?_stats?.achievements,
    };
    _stats = state.stats.copyWith(achievements: achievements);
    _xpForNextLevel = state.xpForNextLevel;
    _energy = state.energy;
    _premium = state.premium;
    _gacha = state.gacha;
  }

  // ── Intentions (le serveur décide) ────────────────────────────────────────

  /// Validation déclarative d'une quête.
  Future<QuestRewardResult> completeQuest(String questId) async {
    final result = await api.completeQuest(questId);
    await refresh();
    return result;
  }

  /// Règles quotidiennes (connexion, énergie, quêtes manquées, PV).
  Future<DailyResult> claimDaily() async {
    final result = await api.claimDaily();
    await refresh();
    return result;
  }

  /// Invocation gacha (payée en Sceaux).
  Future<InvokeResult> invoke(String banner, {int count = 1, bool useFree = false}) async {
    final result = await api.invoke(banner, count: count, useFree: useFree);
    await refresh();
    return result;
  }

  /// TRANSITOIRE (Sprint 3) : débit d'or ou de cristaux.
  Future<void> spend({
    required String resource,
    required int amount,
    required String reason,
    String? ref,
  }) async {
    await api.spend(resource: resource, amount: amount, reason: reason, ref: ref);
    await refresh();
  }

  /// TRANSITOIRE (Sprint 3) : gain plafonné issu de l'inventaire local.
  Future<TransitionalReward> claimTransitionalReward(String source, num amount, {String? ref}) async {
    final result = await api.claimTransitionalReward(source, amount, ref: ref);
    await refresh();
    return result;
  }

  /// Remet le ViewModel à son état initial (changement de compte).
  void reset() {
    _stats = null;
    _energy = 0;
    _premium = false;
    _gacha = const {};
    _xpForNextLevel = 150;
    notifyListeners();
  }

  // ── Succès (locaux jusqu'au Sprint 3) ─────────────────────────────────────

  /// Débloque les succès atteints. Purement cosmétiques et stockés dans le
  /// cache local : ils ne donnent aucune ressource (Sprint 3 : succès serveur).
  Future<List<String>> checkAndUnlockAchievements(String userId,
      {int inventoryCount = 0}) async {
    if (_stats == null) return [];

    final now = DateTime.now().millisecondsSinceEpoch;
    final achievements = Map<String, int>.from(_stats!.achievements);
    final newlyUnlocked = <String>[];

    void check(String id, bool condition) {
      if (condition && !achievements.containsKey(id)) {
        achievements[id] = now;
        newlyUnlocked.add(id);
      }
    }

    check('first_quest', _stats!.totalQuestsCompleted >= 1);
    check('quest_10',    _stats!.totalQuestsCompleted >= 10);
    check('quest_50',    _stats!.totalQuestsCompleted >= 50);
    check('quest_100',   _stats!.totalQuestsCompleted >= 100);
    check('streak_3',    _stats!.maxStreak >= 3);
    check('streak_7',    _stats!.maxStreak >= 7);
    check('streak_30',   _stats!.maxStreak >= 30);
    check('level_5',     _stats!.level >= 5);
    check('level_10',    _stats!.level >= 10);
    check('level_25',    _stats!.level >= 25);
    check('rich_1000',   _stats!.gold >= 1000);
    check('rich_5000',   _stats!.gold >= 5000);
    check('collector_10', inventoryCount >= 10);
    check('collector_25', inventoryCount >= 25);
    check('zen_master',  _stats!.moral >= 0.95);

    if (newlyUnlocked.isNotEmpty) {
      _stats = _stats!.copyWith(achievements: achievements);
      notifyListeners();
      await _repo.saveLocalStats(_stats!);
    }

    return newlyUnlocked;
  }
}
