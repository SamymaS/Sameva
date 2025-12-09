import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  User? _user;

  AuthProvider() {
    // Écouter les changements d'état d'authentification
    _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      if (event == AuthChangeEvent.signedIn && session != null) {
        _user = session.user;
      } else if (event == AuthChangeEvent.signedOut) {
        _user = null;
      }
      notifyListeners();
    });

    // Vérifier l'utilisateur actuel au démarrage
    _user = _supabase.auth.currentUser;
  }

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  String? get userId => _user?.id;

  Future<void> signInAnonymously() async {
    try {
      final response = await _supabase.auth.signInAnonymously();
      _user = response.user;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _user = response.user;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      _user = response.user;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
} 