import 'package:flutter/foundation.dart';
import '../../data/models/quest_model.dart';
import '../../data/repositories/quest_repository.dart';
import './auth_view_model.dart';

/// ViewModel pour la liste des quêtes.
/// Charge, filtre et expose les quêtes via QuestRepository.
class QuestsListViewModel extends ChangeNotifier {
  final QuestRepository _questRepo;
  final AuthViewModel _auth;

  List<Quest> _quests = [];
  bool _isLoading = false;
  String? _error;

  QuestsListViewModel(this._questRepo, this._auth);

  List<Quest> get quests => _quests;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Quest> get activeQuests =>
      _quests.where((q) => q.status == QuestStatus.active).toList();

  List<Quest> get completedQuests =>
      _quests.where((q) => q.status == QuestStatus.completed).toList();

  Future<void> loadQuests() async {
    final userId = _auth.userId;
    if (userId == null || userId.isEmpty) {
      debugPrint('QuestsListViewModel: userId vide, chargement annulé');
      _quests = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _quests = await _questRepo.loadQuests(userId);
    } catch (e) {
      debugPrint('QuestsListViewModel: erreur chargement: $e');
      _error = 'Impossible de charger les quêtes. Vérifiez votre connexion.';
      _quests = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteQuest(String questId) async {
    try {
      await _questRepo.deleteQuest(questId);
      _quests.removeWhere((q) => q.id == questId);
      notifyListeners();
    } catch (e) {
      debugPrint('QuestsListViewModel: erreur suppression: $e');
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
