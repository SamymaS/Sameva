import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  AuthProvider() {
    _auth.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isAuthenticated => _user != null;

  Future<void> signInAnonymously() async {
    try {
      await _auth.signInAnonymously();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    // MODE TEST : Bypass de l'authentification réelle
    // Pour les tests, on se connecte automatiquement en mode anonyme
    // Peu importe les identifiants fournis, on passe en mode anonyme
    await _auth.signInAnonymously();
  }

  Future<void> createUserWithEmailAndPassword(String email, String password) async {
    // MODE TEST : Bypass de l'authentification réelle
    // Pour les tests, on se connecte automatiquement en mode anonyme
    // Peu importe les identifiants fournis, on passe en mode anonyme
    await _auth.signInAnonymously();
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }
} 