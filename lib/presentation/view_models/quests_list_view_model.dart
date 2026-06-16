import 'package:flutter/foundation.dart';
import '../../data/models/quest_model.dart';
import './auth_view_model.dart';
import './quest_view_model.dart';

enum QuestSortOrder { dateDesc, difficultyAsc, durationAsc }

/// ViewModel d'état UI pour la liste des quêtes (filtres, recherche, tri).
/// Ne détient PAS de snapshot : la liste canonique vit dans QuestViewModel
/// (source de vérité unique). Ce VM forwarde les notifications du VM source
/// pour que ses Consumers se reconstruisent quand la liste change ailleurs.
class QuestsListViewModel extends ChangeNotifier {
  final QuestViewModel _questVM;
  final AuthViewModel _auth;

  String? _categoryFilter;
  QuestFrequency? _frequencyFilter;
  QuestSortOrder _sortOrder = QuestSortOrder.dateDesc;
  String _searchQuery = '';

  QuestsListViewModel(this._questVM, this._auth) {
    _questVM.addListener(notifyListeners);
  }

  @override
  void dispose() {
    _questVM.removeListener(notifyListeners);
    super.dispose();
  }

  List<Quest> get quests => _questVM.quests;
  bool get isLoading => _questVM.isLoading;
  String? get error => _questVM.error;
  String? get categoryFilter => _categoryFilter;
  QuestFrequency? get frequencyFilter => _frequencyFilter;
  QuestSortOrder get sortOrder => _sortOrder;
  String get searchQuery => _searchQuery;

  /// Catégories distinctes parmi les quêtes actives.
  List<String> get availableCategories {
    final cats = activeQuests.map((q) => q.category).toSet().toList()..sort();
    return cats;
  }

  // Active/completed dérivent de la source de vérité (pas de re-filtrage local).
  List<Quest> get activeQuests => _questVM.activeQuests;
  List<Quest> get completedQuests => _questVM.completedQuests;

  /// Quêtes actives après application des filtres, de la recherche et du tri.
  List<Quest> get filteredActiveQuests {
    var list = activeQuests;

    if (_searchQuery.isNotEmpty) {
      list = list
          .where((q) => q.title.toLowerCase().contains(_searchQuery))
          .toList();
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
            QuestSortOrder.difficultyAsc =>
              a.difficulty.compareTo(b.difficulty),
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

  /// Délègue le chargement à la source de vérité (QuestViewModel).
  Future<void> loadQuests() async {
    final userId = _auth.userId;
    if (userId == null || userId.isEmpty) {
      debugPrint('QuestsListViewModel: userId vide, chargement annulé');
      return;
    }
    await _questVM.loadQuests(userId);
  }

  /// Délègue la suppression à la source de vérité (QuestViewModel),
  /// qui retire la quête de la liste partagée, annule le rappel et notifie.
  Future<void> deleteQuest(String questId) async {
    await _questVM.deleteQuest(questId);
  }

  void clearError() {
    _questVM.clearError();
  }
}
