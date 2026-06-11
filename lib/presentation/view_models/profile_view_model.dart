import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/models/quest_model.dart';
import '../../data/models/player_stats_model.dart';
import '../../data/repositories/player_repository.dart';
import './auth_view_model.dart';
import './quest_view_model.dart';

/// ViewModel pour la page Profil.
/// Stats joueur via PlayerRepository (offline-first). Les quêtes sont lues
/// depuis QuestViewModel (source de vérité unique) — pas de snapshot parallèle.
class ProfileViewModel extends ChangeNotifier {
  final AuthViewModel _auth;
  final PlayerRepository _playerRepo;
  final QuestViewModel _questVM;

  PlayerStats? _stats;
  bool _isLoading = true;

  ProfileViewModel(this._auth, this._playerRepo, this._questVM);

  bool get isLoading => _isLoading;
  PlayerStats? get stats => _stats;
  List<Quest> get quests => _questVM.quests;
  String? get userEmail => _auth.user?.email;

  List<Quest> get completedQuests =>
      quests.where((q) => q.status == QuestStatus.completed).toList();

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

    // Quêtes : source de vérité unique. On déclenche un chargement seulement
    // si la liste partagée est vide (évite d'écraser un état déjà à jour).
    if (_questVM.quests.isEmpty) {
      await _questVM.loadQuests(userId);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
}
