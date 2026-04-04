import 'package:flutter/material.dart';
import 'player_view_model.dart';

/// ViewModel de la page Récompenses.
/// Délègue à [PlayerViewModel] et expose les stats de progression du joueur.
class RewardsViewModel extends ChangeNotifier {
  final PlayerViewModel _playerViewModel;

  RewardsViewModel(this._playerViewModel) {
    _playerViewModel.addListener(_onPlayerChanged);
  }

  void _onPlayerChanged() => notifyListeners();

  PlayerStats? get stats => _playerViewModel.stats;

  int get level => stats?.level ?? 1;
  int get experience => stats?.experience ?? 0;
  int get gold => stats?.gold ?? 0;
  int get streak => stats?.streak ?? 0;
  int get healthPoints => stats?.healthPoints ?? 0;

  int get experienceForNextLevel => _playerViewModel.experienceForLevel(level);

  double get xpProgress {
    final needed = experienceForNextLevel;
    if (needed <= 0) return 0.0;
    return (experience / needed).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _playerViewModel.removeListener(_onPlayerChanged);
    super.dispose();
  }
}
