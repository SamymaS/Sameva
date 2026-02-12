import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../data/models/quest_model.dart';
import '../../domain/services/validation_ai_service.dart';
import '../providers/auth_provider.dart';
import '../providers/quest_provider.dart';
import '../providers/player_provider.dart';

/// MVVM — ViewModel pour la validation de quête.
/// Gère validation simple (checkbox) ou preuve visuelle + IA.
class QuestValidationViewModel extends ChangeNotifier {
  QuestValidationViewModel(
    this._authProvider,
    this._questProvider,
    this._playerProvider, {
    ValidationAIService? validationService,
  }) : _validationService = validationService ?? MockValidationAIService();

  final AuthProvider _authProvider;
  final QuestProvider _questProvider;
  final PlayerProvider _playerProvider;
  final ValidationAIService _validationService;

  Uint8List? proofImage;
  bool isAnalyzing = false;
  ValidationResult? result;

  bool get isPhotoValidation => false; // sera overridé par la vue avec quest.validationType

  Future<void> analyzeProof(Quest quest, Uint8List imageBytes) async {
    isAnalyzing = true;
    notifyListeners();
    try {
      result = await _validationService.analyzeProof(quest: quest, imageBytes: imageBytes);
    } finally {
      isAnalyzing = false;
      notifyListeners();
    }
  }

  void setProof(Uint8List? bytes) {
    proofImage = bytes;
    result = null;
    notifyListeners();
  }

  Future<bool> completeQuest(Quest quest) async {
    final questId = quest.id;
    final userId = _authProvider.userId;
    if (questId == null || userId == null || userId.isEmpty) return false;

    await _questProvider.completeQuest(questId);
    final xp = quest.xpReward ?? 10;
    await _playerProvider.addExperience(userId, xp);
    await _playerProvider.updateStreak(userId);
    notifyListeners();
    return true;
  }
}
