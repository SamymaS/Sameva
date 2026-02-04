import 'package:flutter/material.dart';
import '../../data/models/quest_model.dart';
import '../providers/auth_provider.dart';
import '../providers/quest_provider.dart';

/// MVVM — ViewModel pour l'écran Mes Quêtes.
/// Hick : peu de choix (onglets À faire / Terminées).
/// Miller : listes courtes (activeQuests, completedQuests).
class QuestsListViewModel extends ChangeNotifier {
  QuestsListViewModel(this._questProvider, this._authProvider);

  final QuestProvider _questProvider;
  final AuthProvider _authProvider;

  int _selectedTabIndex = 0;
  static const int maxTabs = 2;

  int get selectedTabIndex => _selectedTabIndex;
  bool get isLoading => _questProvider.isLoading;
  List<Quest> get activeQuests => _questProvider.activeQuests;
  List<Quest> get completedQuests => _questProvider.completedQuests;

  void setTab(int index) {
    if (index >= 0 && index < maxTabs) {
      _selectedTabIndex = index;
      notifyListeners();
    }
  }

  Future<void> loadQuests() async {
    final userId = _authProvider.userId;
    if (userId != null && userId.isNotEmpty) {
      await _questProvider.loadQuests(userId);
    }
    notifyListeners();
  }
}
