import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../data/models/quest_model.dart';
import '../../data/repositories/quest_repository.dart';
import '../../domain/services/validation_ai_service.dart';
import './auth_view_model.dart';

/// ViewModel pour la validation de quête.
/// Gère la preuve photo + analyse IA, et délègue la complétion à QuestRepository.
/// Note : la logique de récompenses joueur (XP, streak) reste dans CompleteQuestUseCase
/// jusqu'à l'extraction de PlayerProvider en service de domaine.
class QuestValidationViewModel extends ChangeNotifier {
  final AuthViewModel _auth;
  final QuestRepository _questRepo;
  final ValidationAIService _validationService;

  Uint8List? proofImage;
  bool isAnalyzing = false;
  ValidationResult? result;

  QuestValidationViewModel(
    this._auth,
    this._questRepo, {
    ValidationAIService? validationService,
  }) : _validationService = validationService ?? MockValidationAIService();

  Future<void> analyzeProof(Quest quest, Uint8List imageBytes) async {
    isAnalyzing = true;
    notifyListeners();
    try {
      result = await _validationService.analyzeProof(
          quest: quest, imageBytes: imageBytes);
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

  /// Marque la quête comme complétée dans Supabase.
  /// Les récompenses joueur (XP, streak) doivent être gérées par la page
  /// via CompleteQuestUseCase jusqu'à migration complète de PlayerProvider.
  Future<bool> completeQuest(Quest quest) async {
    if (quest.id == null || _auth.userId == null) return false;
    try {
      await _questRepo.completeQuest(quest);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
