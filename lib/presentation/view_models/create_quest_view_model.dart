import 'package:flutter/material.dart';
import '../../data/models/quest_model.dart';
import './auth_view_model.dart';
import './quest_view_model.dart';

/// ViewModel d'état UI pour la création de quête.
/// Délègue création/mise à jour à QuestViewModel (source de vérité unique),
/// qui persiste via le repo ET met à jour la liste partagée + notifie.
class CreateQuestViewModel extends ChangeNotifier {
  final QuestViewModel _questVM;
  final AuthViewModel _auth;

  bool _isLoading = false;
  String? _errorMessage;

  CreateQuestViewModel(this._questVM, this._auth);

  final List<String> categories = [
    'Maison',
    'Sport',
    'Loisir',
    'Études',
    'Travail',
    'Santé',
    'Autre',
  ];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> createQuest({
    required String title,
    required String category,
    required ValidationType validationType,
    int durationMinutes = 30,
    DateTime? deadline,
    String? description,
    int difficulty = 1,
    QuestFrequency frequency = QuestFrequency.oneOff,
  }) async {
    final userId = _auth.userId;
    if (userId == null || userId.isEmpty) {
      _errorMessage = 'Non connecté';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final desc = description?.trim();
      final quest = Quest(
        userId: userId,
        title: title.trim(),
        description: (desc != null && desc.isNotEmpty) ? desc : null,
        estimatedDurationMinutes: durationMinutes,
        frequency: frequency,
        difficulty: difficulty.clamp(1, 4),
        category: category,
        rarity: QuestRarity.common,
        status: QuestStatus.active,
        validationType: validationType,
        deadline: deadline,
      );
      await _questVM.addQuest(quest);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateQuest(Quest quest) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _questVM.updateQuest(quest);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
