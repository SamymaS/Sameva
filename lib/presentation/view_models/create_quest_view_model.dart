import 'package:flutter/material.dart';
import '../../data/models/quest_model.dart';
import '../providers/auth_provider.dart';
import '../providers/quest_provider.dart';

/// MVVM — ViewModel pour la création de quête.
/// Hick : champs essentiels uniquement (titre, catégorie, type de validation).
class CreateQuestViewModel extends ChangeNotifier {
  CreateQuestViewModel(this._questProvider, this._authProvider);

  final QuestProvider _questProvider;
  final AuthProvider _authProvider;

  bool _isLoading = false;
  String? _errorMessage;

  final List<String> categories = [
    'Maison',
    'Sport',
    'Loisir',
    'Études',
    'Travail',
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
  }) async {
    final userId = _authProvider.userId;
    if (userId == null || userId.isEmpty) {
      _errorMessage = 'Non connecté';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final quest = Quest(
        userId: userId,
        title: title.trim(),
        estimatedDurationMinutes: durationMinutes,
        frequency: QuestFrequency.oneOff,
        difficulty: 1,
        category: category,
        rarity: QuestRarity.common,
        status: QuestStatus.active,
        validationType: validationType,
        deadline: deadline,
      );
      await _questProvider.addQuest(quest);
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
