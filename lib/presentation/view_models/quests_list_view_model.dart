import 'package:flutter/foundation.dart';
import '../../data/models/quest_model.dart';
import '../../data/repositories/quest_repository.dart';
import '../../domain/services/notification_service.dart';
import './auth_view_model.dart';

enum QuestSortOrder { dateDesc, difficultyAsc, durationAsc }

/// ViewModel pour la liste des quêtes.
/// Charge, filtre et expose les quêtes via QuestRepository.
class QuestsListViewModel extends ChangeNotifier {
  final QuestRepository _questRepo;
  final AuthViewModel _auth;

  List<Quest> _quests = [];
  bool _isLoading = false;
  String? _error;

  String? _categoryFilter;
  QuestFrequency? _frequencyFilter;
  QuestSortOrder _sortOrder = QuestSortOrder.dateDesc;
  String _searchQuery = '';

  QuestsListViewModel(this._questRepo, this._auth);

  List<Quest> get quests => _quests;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get categoryFilter => _categoryFilter;
  QuestFrequency? get frequencyFilter => _frequencyFilter;
  QuestSortOrder get sortOrder => _sortOrder;
  String get searchQuery => _searchQuery;

  /// Catégories distinctes parmi les quêtes actives.
  List<String> get availableCategories {
    final cats = _quests
        .where((q) => q.status == QuestStatus.active)
        .map((q) => q.category)
        .toSet()
        .toList()
      ..sort();
    return cats;
  }

  List<Quest> get activeQuests =>
      _quests.where((q) => q.status == QuestStatus.active).toList();

  List<Quest> get completedQuests =>
      _quests.where((q) => q.status == QuestStatus.completed).toList();

  /// Quêtes actives après application des filtres, de la recherche et du tri.
  List<Quest> get filteredActiveQuests {
    var list = activeQuests;

    if (_searchQuery.isNotEmpty) {
      list = list.where((q) => q.title.toLowerCase().contains(_searchQuery)).toList();
    }
    if (_categoryFilter != null) {
      list = list.where((q) => q.category == _categoryFilter).toList();
    }
    if (_frequencyFilter != null) {
      list = list.where((q) => q.frequency == _frequencyFilter).toList();
    }

    list = List.of(list)
      ..sort((a, b) => switch (_sortOrder) {
            QuestSortOrder.dateDesc => b.createdAt.compareTo(a.createdAt),
            QuestSortOrder.difficultyAsc => a.difficulty.compareTo(b.difficulty),
            QuestSortOrder.durationAsc =>
              a.estimatedDurationMinutes.compareTo(b.estimatedDurationMinutes),
          });

    return list;
  }

  /// Quêtes terminées filtrées par recherche textuelle.
  List<Quest> get filteredCompletedQuests {
    if (_searchQuery.isEmpty) return completedQuests;
    return completedQuests
        .where((q) => q.title.toLowerCase().contains(_searchQuery))
        .toList();
  }

  void setCategoryFilter(String? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void setFrequencyFilter(QuestFrequency? frequency) {
    _frequencyFilter = frequency;
    notifyListeners();
  }

  void setSortOrder(QuestSortOrder order) {
    _sortOrder = order;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  void clearFilters() {
    _categoryFilter = null;
    _frequencyFilter = null;
    _sortOrder = QuestSortOrder.dateDesc;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

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
      await NotificationService.cancelQuestDeadlineReminder(questId);
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
