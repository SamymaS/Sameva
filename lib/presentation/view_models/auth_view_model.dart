import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/services/activity_log_service.dart';

/// ViewModel d'authentification.
/// Gère l'état de connexion et délègue les appels réseau à AuthRepository.
class AuthViewModel with ChangeNotifier {
  final AuthRepository _repo;
  late final StreamSubscription<AuthState> _authSub;

  // Stream broadcast émis lors de tout signedOut (manuel, token expiré, etc.).
  // Les VMs métier (Player, Inventory, Equipment, Cat) s'y abonnent pour se reset.
  final StreamController<void> _signedOutController =
      StreamController<void>.broadcast();

  // Stream broadcast émis lors d'un signedIn (connexion ou création de compte).
  // CatViewModel s'y abonne pour recharger les chats après login.
  final StreamController<void> _signedInController =
      StreamController<void>.broadcast();

  /// A écouter dans les VMs pour déclencher reset() automatiquement.
  Stream<void> get onSignedOut => _signedOutController.stream;

  /// A écouter dans les VMs pour recharger les données après connexion.
  Stream<void> get onSignedIn => _signedInController.stream;

  User? _user;
  String? _errorMessage;
  bool _isLoading = false;

  AuthViewModel(this._repo) {
    _user = _repo.currentUser;
    _authSub = _repo.authStateChanges.listen((data) {
      final event = data.event;
      final session = data.session;
      final previousUserId = _user?.id;

      if (event == AuthChangeEvent.signedIn && session != null) {
        _user = session.user;
        _errorMessage = null;
        // Notifie les VMs métier qu'un user vient de se connecter.
        _signedInController.add(null);
      } else if (event == AuthChangeEvent.tokenRefreshed && session != null) {
        _user = session.user;
        return; // refresh silencieux, pas de notify
      } else if (event == AuthChangeEvent.signedOut) {
        _user = null;
        _errorMessage = null;
        // Émet sur le stream pour que les VMs métier se reset automatiquement.
        // Couvre logout manuel, token expiré, signOut programmatique.
        _signedOutController.add(null);
      } else {
        return; // autres events ignorés
      }

      if (_user?.id != previousUserId) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    _signedOutController.close();
    _signedInController.close();
    super.dispose();
  }

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  String? get userId => _user?.id;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    if (email.trim().isEmpty) throw Exception('Veuillez entrer votre email');
    if (password.isEmpty) throw Exception('Veuillez entrer votre mot de passe');

    _setLoading(true);
    try {
      _user = await _repo.signInWithEmailAndPassword(email, password);
      _user ??= _repo.currentUser;
      _errorMessage = null;
    } on AuthException catch (e) {
      _errorMessage = _traduireErreur(e);
      rethrow;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createUserWithEmailAndPassword(String email, String password) async {
    if (email.trim().isEmpty) throw Exception('Veuillez entrer votre email');
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim())) {
      throw Exception('Email invalide');
    }
    if (password.length < 6) throw Exception('Le mot de passe doit contenir au moins 6 caractères');

    _setLoading(true);
    try {
      _user = await _repo.createUserWithEmailAndPassword(email, password);
      _user ??= _repo.currentUser;
      _errorMessage = null;
    } on AuthException catch (e) {
      _errorMessage = _traduireErreur(e);
      rethrow;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _repo.signOut();
      _user = null;
      _errorMessage = null;
      // Purge des données personnelles Hive pour éviter la fuite vers le prochain user.
      // Les clés correspondent aux conventions utilisées par chaque ViewModel.
      await _purgeHiveData();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Supprime définitivement le compte de l'utilisateur courant (RGPD).
  ///
  /// Flux complet :
  /// 1. Appel Edge Function `delete-account` (JWT auto-injecté par Supabase).
  ///    Rien dans le body — l'userId est extrait du JWT côté serveur.
  /// 2. Analyse de la réponse par étapes (audit_deleted + auth_user_deleted).
  /// 3. Sur succès complet uniquement : purge des clés Hive per-user +
  ///    [signOut()] (propage [onSignedOut] → reset des ViewModels abonnés).
  /// 4. Sur échec (partiel ou réseau) : lance une [Exception].
  ///    NE déconnecte PAS, NE purge PAS — l'utilisateur peut réessayer.
  ///
  /// [invokeOverride] : injectable en test pour court-circuiter l'appel réseau.
  /// En production, laissé null → appel réel via Supabase.instance.client.
  Future<void> deleteAccount({
    Future<Map<String, dynamic>> Function()? invokeOverride,
  }) async {
    final uid = _user?.id;
    if (uid == null) throw Exception('Aucun utilisateur connecté');

    // ── Appel réseau ─────────────────────────────────────────────────────
    final Map<String, dynamic> data;
    try {
      if (invokeOverride != null) {
        data = await invokeOverride();
      } else {
        final response = await Supabase.instance.client.functions.invoke(
          'delete-account',
          body: <String, dynamic>{},
        );
        final raw = response.data;
        data = raw is Map
            ? Map<String, dynamic>.from(raw)
            : <String, dynamic>{};
      }
    } catch (e) {
      throw Exception(
        'Impossible de contacter le serveur. '
        'Vérifiez votre connexion et réessayez.',
      );
    }

    // ── Analyse de la réponse par étapes ─────────────────────────────────
    // Utilise == true au lieu de `as bool?` pour éviter un TypeError si le
    // serveur renvoie un entier (ex. 1) ou une chaîne ("true") à la place
    // d'un booléen. TypeError est un Error (pas une Exception) et échappe
    // aux gestionnaires `on Exception catch` de l'UI → _isLoading resterait
    // bloqué à true. Avec == true, toute valeur non-booléenne est évaluée
    // à false (fail-closed) et lève une Exception propre via le bloc ci-dessous.
    final success = data['success'] == true;
    final steps = data['steps'];
    final stepsMap = steps is Map
        ? Map<String, dynamic>.from(steps)
        : <String, dynamic>{};
    final auditDeleted = stepsMap['audit_deleted'] == true;
    final authUserDeleted = stepsMap['auth_user_deleted'] == true;

    if (!success || !auditDeleted || !authUserDeleted) {
      final serverError = data['error'] as String?;
      throw Exception(
        serverError ??
            'Échec de la suppression du compte. '
            'Veuillez réessayer ou contacter le support.',
      );
    }

    // ── Succès complet — purge Hive étendue puis signOut ─────────────────
    // Purge des clés per-user non couvertes par _purgeHiveData() au logout.
    await _purgeHivePerUserData(uid);
    // Fermeture de la fuite RGPD ActivityLogService :
    // clearLog() couvre les deux vecteurs — _cache = null (mémoire statique)
    // + _box.delete('activity_log') (clé Hive dans la box 'settings').
    // Placé ici, sous la même garde success && audit_deleted && auth_user_deleted,
    // donc jamais exécuté sur échec partiel ou erreur réseau.
    await ActivityLogService.clearLog();
    // signOut propage onSignedOut → reset des ViewModels abonnés.
    // Si l'appel échoue (compte déjà supprimé côté serveur), on force le
    // reset local pour que _AuthGate redirige vers LoginPage.
    try {
      await signOut();
    } catch (e) {
      debugPrint(
          'AuthViewModel.deleteAccount: signOut après suppression (ignoré): $e');
      _user = null;
      _errorMessage = null;
      _signedOutController.add(null);
      notifyListeners();
    }
  }

  /// Purge des clés Hive isolées par userId, absentes du logout standard.
  ///
  /// Ces clés persistent intentionnellement entre les sessions du même
  /// utilisateur (pour éviter leur perte sur logout). Lors d'un effacement
  /// RGPD, elles doivent être explicitement supprimées.
  ///
  /// Boîtes et clés concernées (cf. sameva-rgpd skill) :
  /// - `cats`          → `cats_list_$userId`
  /// - `aiValidation`  → `ai_validation_$userId`
  /// - `settings`      → `has_onboarded_$userId`
  /// - `settings`      → `lastFreePullAt`
  Future<void> _purgeHivePerUserData(String userId) async {
    try {
      if (Hive.isBoxOpen('cats')) {
        await Hive.box('cats').delete('cats_list_$userId');
      }
      if (Hive.isBoxOpen('aiValidation')) {
        await Hive.box('aiValidation').delete('ai_validation_$userId');
      }
      if (Hive.isBoxOpen('settings')) {
        await Hive.box('settings').delete('has_onboarded_$userId');
        await Hive.box('settings').delete('lastFreePullAt');
      }
    } catch (e) {
      debugPrint('AuthViewModel: erreur purge Hive per-user: $e');
    }
  }

  /// Note : _purgeHiveData() est défensif. Les VMs métier seront aussi
  /// reset via le stream onSignedOut. La purge Hive est donc redondante
  /// mais idempotente, et garantit qu'aucune donnée locale persiste
  /// même si un VM oublie de s'abonner ou de reset proprement.
  Future<void> _purgeHiveData() async {
    try {
      // Stats joueur (PlayerRepository utilise la clé 'stats' dans la box 'playerStats')
      if (Hive.isBoxOpen('playerStats')) {
        await Hive.box('playerStats').delete('stats');
      }
      // Inventaire (InventoryViewModel utilise la clé 'items' dans la box 'inventory')
      if (Hive.isBoxOpen('inventory')) {
        await Hive.box('inventory').delete('items');
      }
      // Équipement + cosmétiques (EquipmentViewModel dans la box 'equipment')
      if (Hive.isBoxOpen('equipment')) {
        await Hive.box('equipment').delete('equipment');
        await Hive.box('equipment').delete('cosmetics');
      }
      // Cats reset géré par CatViewModel via stream onSignedOut, pas ici,
      // pour éviter double effacement (régression 14/05/26).
      // Achievements (AchievementService utilise la clé 'achievements' dans la box 'settings')
      if (Hive.isBoxOpen('settings')) {
        await Hive.box('settings').delete('achievements');
      }
    } catch (e) {
      debugPrint('AuthViewModel: erreur purge Hive au logout: $e');
    }
  }

  /// Retourne le userId courant si déjà disponible, sinon attend
  /// l'event signedIn sur le stream Supabase authStateChanges,
  /// avec timeout.
  ///
  /// Utilisé par OnboardingPage pour gérer la latence possible
  /// entre signup et hydratation de _user.
  Future<String> waitForSignedInUserId({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (_user?.id != null && _user!.id.isNotEmpty) {
      return _user!.id;
    }

    final completer = Completer<String>();
    late final StreamSubscription<AuthState> sub;

    sub = Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.signedIn &&
          state.session?.user.id != null &&
          state.session!.user.id.isNotEmpty) {
        if (!completer.isCompleted) {
          completer.complete(state.session!.user.id);
        }
      }
    });

    try {
      return await completer.future.timeout(timeout);
    } finally {
      await sub.cancel();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _traduireErreur(AuthException e) {
    switch (e.message) {
      case 'Invalid login credentials':
        return 'Email ou mot de passe incorrect';
      case 'Email not confirmed':
        return 'Veuillez confirmer votre email avant de vous connecter';
      case 'User already registered':
        return 'Cet email est déjà utilisé';
      case 'Password should be at least 6 characters':
        return 'Le mot de passe doit contenir au moins 6 caractères';
      case 'Signup is disabled':
        return "L'inscription est désactivée";
      default:
        return e.message;
    }
  }
}
