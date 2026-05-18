import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/auth_repository.dart';

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
