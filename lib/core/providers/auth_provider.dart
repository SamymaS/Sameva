import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Modèle utilisateur simple pour remplacer Firebase User
class LocalUser {
  final String uid;
  final String? email;
  final String? displayName;

  LocalUser({
    required this.uid,
    this.email,
    this.displayName,
  });
}

class AuthProvider with ChangeNotifier {
  LocalUser? _user;
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userDisplayNameKey = 'user_display_name';
  static const String _isAuthenticatedKey = 'is_authenticated';

  AuthProvider() {
    _loadUser();
  }

  LocalUser? get user => _user;
  bool get isAuthenticated => _user != null;

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isAuthenticated = prefs.getBool(_isAuthenticatedKey) ?? false;
      
      if (isAuthenticated) {
        final uid = prefs.getString(_userIdKey);
        final email = prefs.getString(_userEmailKey);
        final displayName = prefs.getString(_userDisplayNameKey);
        
        if (uid != null) {
          _user = LocalUser(
            uid: uid,
            email: email,
            displayName: displayName,
          );
          notifyListeners();
        }
      }
    } catch (e) {
      print('Erreur lors du chargement de l\'utilisateur: $e');
    }
  }

  Future<void> _saveUser(LocalUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isAuthenticatedKey, true);
      await prefs.setString(_userIdKey, user.uid);
      if (user.email != null) {
        await prefs.setString(_userEmailKey, user.email!);
      }
      if (user.displayName != null) {
        await prefs.setString(_userDisplayNameKey, user.displayName!);
      }
    } catch (e) {
      print('Erreur lors de la sauvegarde de l\'utilisateur: $e');
      rethrow;
    }
  }

  Future<void> signInAnonymously() async {
    try {
      final uid = const Uuid().v4();
      _user = LocalUser(uid: uid);
      await _saveUser(_user!);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      // Pour l'instant, on crée un utilisateur simple
      // Dans une vraie app, on vérifierait le mot de passe
      final prefs = await SharedPreferences.getInstance();
      String? uid = prefs.getString('user_${email}_uid');
      
      if (uid == null) {
        // Créer un nouvel utilisateur
        uid = const Uuid().v4();
        await prefs.setString('user_${email}_uid', uid);
        // En production, on hasherait le mot de passe
        await prefs.setString('user_${email}_password', password);
      } else {
        // Vérifier le mot de passe (en production, on comparerait avec un hash)
        final savedPassword = prefs.getString('user_${email}_password');
        if (savedPassword != password) {
          throw Exception('Mot de passe incorrect');
        }
      }
      
      _user = LocalUser(
        uid: uid,
        email: email,
        displayName: email.split('@').first,
      );
      await _saveUser(_user!);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingUid = prefs.getString('user_${email}_uid');
      
      if (existingUid != null) {
        throw Exception('Un compte existe déjà avec cet email');
      }
      
      final uid = const Uuid().v4();
      await prefs.setString('user_${email}_uid', uid);
      // En production, on hasherait le mot de passe
      await prefs.setString('user_${email}_password', password);
      
      _user = LocalUser(
        uid: uid,
        email: email,
        displayName: email.split('@').first,
      );
      await _saveUser(_user!);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isAuthenticatedKey, false);
      _user = null;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
} 