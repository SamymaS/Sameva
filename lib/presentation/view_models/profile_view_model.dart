import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../providers/player_provider.dart';
import '../providers/quest_provider.dart';

/// MVVM — ViewModel pour Profil / Historique.
/// Goal Gradient : afficher progression (XP, streak, quêtes complétées).
class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel(this._authProvider, this._playerProvider, this._questProvider);

  final AuthProvider _authProvider;
  final PlayerProvider _playerProvider;
  final QuestProvider _questProvider;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  int? get level => _playerProvider.stats?.level;
  int? get experience => _playerProvider.stats?.experience;
  int? get gold => _playerProvider.stats?.gold;
  int get streak => _playerProvider.stats?.streak ?? 0;
  int get completedCount => _questProvider.completedQuests.length;
  String? get userEmail => _authProvider.user?.email;

  Future<void> load(String userId) async {
    _isLoading = true;
    notifyListeners();
    await _playerProvider.loadPlayerStats(userId);
    await _questProvider.loadQuests(userId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authProvider.signOut();
    notifyListeners();
  }
}
