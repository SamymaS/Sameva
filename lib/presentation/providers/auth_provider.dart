import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  User? _user;
  String? _errorMessage;
  bool _isLoading = false;

  AuthProvider() {
    // Écouter les changements d'état d'authentification
    _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      if (event == AuthChangeEvent.signedIn && session != null) {
        _user = session.user;
        _errorMessage = null;
      } else if (event == AuthChangeEvent.signedOut) {
        _user = null;
        _errorMessage = null;
      }
      notifyListeners();
    });

    // Vérifier l'utilisateur actuel au démarrage
    _user = _supabase.auth.currentUser;
  }

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  String? get userId => _user?.id;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  /// Convertit une erreur Supabase en message lisible
  String _getErrorMessage(dynamic error) {
    if (error is AuthException) {
      switch (error.message) {
        case 'Invalid login credentials':
          return 'Email ou mot de passe incorrect';
        case 'Email not confirmed':
          return 'Veuillez confirmer votre email avant de vous connecter';
        case 'User already registered':
          return 'Cet email est déjà utilisé';
        case 'Password should be at least 6 characters':
          return 'Le mot de passe doit contenir au moins 6 caractères';
        case 'Signup is disabled':
          return 'L\'inscription est désactivée';
        default:
          return error.message ?? 'Une erreur est survenue';
      }
    }
    return error.toString();
  }

  Future<void> signInAnonymously() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _supabase.auth.signInAnonymously();
      _user = response.user;
      _errorMessage = null;
    } on AuthException catch (e) {
      _errorMessage = _getErrorMessage(e);
      rethrow;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Validation basique
      if (email.trim().isEmpty) {
        throw Exception('Veuillez entrer votre email');
      }
      if (password.isEmpty) {
        throw Exception('Veuillez entrer votre mot de passe');
      }

      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      _user = response.user;
      _errorMessage = null;
    } on AuthException catch (e) {
      _errorMessage = _getErrorMessage(e);
      rethrow;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createUserWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Validation
      if (email.trim().isEmpty) {
        throw Exception('Veuillez entrer votre email');
      }
      if (!email.contains('@')) {
        throw Exception('Email invalide');
      }
      if (password.length < 6) {
        throw Exception('Le mot de passe doit contenir au moins 6 caractères');
      }

      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
      );
      
      // Note: Le trigger handle_new_user() créera automatiquement l'utilisateur dans la table users
      _user = response.user;
      _errorMessage = null;
    } on AuthException catch (e) {
      _errorMessage = _getErrorMessage(e);
      rethrow;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _supabase.auth.signOut();
      _user = null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Réinitialise le message d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
} 