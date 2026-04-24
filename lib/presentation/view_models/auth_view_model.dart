import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/auth_repository.dart';

/// ViewModel d'authentification.
/// Gère l'état de connexion et délègue les appels réseau à AuthRepository.
class AuthViewModel with ChangeNotifier {
  final AuthRepository _repo;
  late final StreamSubscription<AuthState> _authSub;

  User? _user;
  String? _errorMessage;
  bool _isLoading = false;

  AuthViewModel(this._repo) {
    _user = _repo.currentUser;
    _authSub = _repo.authStateChanges.listen((data) {
      final event = data.event;
      final session = data.session;
      if (event == AuthChangeEvent.signedIn && session != null) {
        _user = session.user;
        _errorMessage = null;
      } else if (event == AuthChangeEvent.signedOut) {
        _user = null;
        _errorMessage = null;
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  String? get userId => _user?.id;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  Future<void> signInAnonymously() async {
    _setLoading(true);
    try {
      _user = await _repo.signInAnonymously();
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
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
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
