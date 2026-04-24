import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/models/quest_model.dart';
import '../../data/models/player_stats_model.dart';
import '../../data/repositories/player_repository.dart';
import '../../data/repositories/quest_repository.dart';
import './auth_view_model.dart';

/// ViewModel pour la page Profil.
/// Charge et expose les stats joueur et les quêtes via les repositories.
class ProfileViewModel extends ChangeNotifier {
  final AuthViewModel _auth;
  final PlayerRepository _playerRepo;
  final QuestRepository _questRepo;

  PlayerStats? _stats;
  List<Quest> _quests = [];
  bool _isLoading = true;

  ProfileViewModel(this._auth, this._playerRepo, this._questRepo);

  bool get isLoading => _isLoading;
  PlayerStats? get stats => _stats;
  List<Quest> get quests => _quests;
  String? get userEmail => _auth.user?.email;

  List<Quest> get completedQuests =>
      _quests.where((q) => q.status == QuestStatus.completed).toList();

  int get streak => _stats?.streak ?? 0;
  int get completedCount => completedQuests.length;

  int experienceForLevel(int level) => (100 * (level * 1.5)).round();

  Future<void> load(String userId) async {
    _isLoading = true;
    notifyListeners();

    // Offline-first : stats locales d'abord
    _stats = _playerRepo.loadLocalStats();
    notifyListeners();

    try {
      // Sync distante (best-effort)
      final remote = await _playerRepo.fetchRemoteStats(userId);
      if (remote != null) {
        _stats = remote;
        await _playerRepo.saveLocalStats(remote);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('ProfileViewModel: erreur sync stats: $e');
    }

    try {
      _quests = await _questRepo.loadQuests(userId);
    } catch (e) {
      debugPrint('ProfileViewModel: erreur chargement quêtes: $e');
      _quests = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
}
