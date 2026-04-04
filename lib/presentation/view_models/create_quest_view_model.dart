import 'package:flutter/material.dart';
import '../../data/models/quest_model.dart';
import './auth_view_model.dart';
import '../providers/quest_provider.dart';

/// MVVM — ViewModel pour la création de quête.
class CreateQuestViewModel extends ChangeNotifier {
  CreateQuestViewModel(this._questProvider, this._authProvider);

  final QuestProvider _questProvider;
  final AuthViewModel _authProvider;

  bool _isLoading = false;
  String? _errorMessage;

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
      final desc = description?.trim();
      final quest = Quest(
        userId: userId,
        title: title.trim(),
        description: (desc != null && desc.isNotEmpty) ? desc : null,
        estimatedDurationMinutes: durationMinutes,
        frequency: frequency,
        difficulty: difficulty,
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
