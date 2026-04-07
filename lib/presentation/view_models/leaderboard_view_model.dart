import 'package:flutter/material.dart';
import '../../data/models/leaderboard_entry_model.dart';
import '../../data/repositories/leaderboard_repository.dart';

/// ViewModel pour la page de classement.
class LeaderboardViewModel extends ChangeNotifier {
  final LeaderboardRepository _repository;

  List<LeaderboardEntry> _entries = [];
  bool _loading = false;
  String? _error;
  String? currentUserId;

  LeaderboardViewModel(this._repository);

  List<LeaderboardEntry> get entries => _entries;
  bool get loading => _loading;
  String? get error => _error;

  /// Charge le classement depuis Supabase.
  Future<void> load(String userId) async {
    currentUserId = userId;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _entries = await _repository.fetchLeaderboard();
    } catch (e) {
      _error = 'Impossible de charger le classement.';
      debugPrint('LeaderboardViewModel: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Rafraîchit le classement (pull-to-refresh).
  Future<void> refresh(String userId) => load(userId);
}
