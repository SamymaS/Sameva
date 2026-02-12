import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Bloc d'authentification gerant la connexion, l'inscription,
/// la connexion anonyme et la deconnexion via Supabase Auth.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final StreamSubscription<AuthState> _authStateSubscription;

  AuthBloc() : super(const AuthInitial()) {
    // Enregistrer les handlers d'events
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthSignInAnonymouslyRequested>(_onSignInAnonymouslyRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthStateChanged>(_onAuthStateChanged);
    on<AuthErrorCleared>(_onErrorCleared);

    // Ecouter les changements d'etat d'authentification Supabase
    _authStateSubscription = _supabase.auth.onAuthStateChange.map((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        return AuthAuthenticated(
          user: session.user,
          userId: session.user.id,
        );
      } else if (event == AuthChangeEvent.signedOut) {
        return const AuthUnauthenticated();
      }

      // Pour les autres events, on conserve l'etat actuel
      return state;
    }).listen((authState) {
      // On utilise AuthStateChanged pour propager via le Bloc
      if (authState is AuthAuthenticated) {
        add(AuthStateChanged(authState.user));
      } else if (authState is AuthUnauthenticated) {
        add(const AuthStateChanged(null));
      }
    });

    // Verifier l'utilisateur actuel au demarrage
    final currentUser = _supabase.auth.currentUser;
    if (currentUser != null) {
      add(AuthStateChanged(currentUser));
    }
  }

  /// Convertit une erreur Supabase en message lisible en francais.
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
          return "L'inscription est désactivée";
        default:
          return error.message ?? 'Une erreur est survenue';
      }
    }
    return error.toString();
  }

  /// Connexion avec email et mot de passe.
  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());

      // Validation basique
      if (event.email.trim().isEmpty) {
        emit(const AuthError('Veuillez entrer votre email'));
        return;
      }
      if (event.password.isEmpty) {
        emit(const AuthError('Veuillez entrer votre mot de passe'));
        return;
      }

      final response = await _supabase.auth.signInWithPassword(
        email: event.email.trim(),
        password: event.password,
      );

      if (response.user != null) {
        emit(AuthAuthenticated(
          user: response.user!,
          userId: response.user!.id,
        ));
      } else {
        emit(const AuthError('Une erreur est survenue lors de la connexion'));
      }
    } on AuthException catch (e) {
      emit(AuthError(_getErrorMessage(e)));
    } catch (e) {
      emit(AuthError(_getErrorMessage(e)));
    }
  }

  /// Inscription avec email et mot de passe.
  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());

      // Validation
      if (event.email.trim().isEmpty) {
        emit(const AuthError('Veuillez entrer votre email'));
        return;
      }
      if (!event.email.contains('@')) {
        emit(const AuthError('Email invalide'));
        return;
      }
      if (event.password.length < 6) {
        emit(const AuthError(
          'Le mot de passe doit contenir au moins 6 caractères',
        ));
        return;
      }

      // Note: Le trigger handle_new_user() creera automatiquement
      // l'utilisateur dans la table users
      final response = await _supabase.auth.signUp(
        email: event.email.trim(),
        password: event.password,
      );

      if (response.user != null) {
        emit(AuthAuthenticated(
          user: response.user!,
          userId: response.user!.id,
        ));
      } else {
        emit(const AuthError("Une erreur est survenue lors de l'inscription"));
      }
    } on AuthException catch (e) {
      emit(AuthError(_getErrorMessage(e)));
    } catch (e) {
      emit(AuthError(_getErrorMessage(e)));
    }
  }

  /// Connexion anonyme.
  Future<void> _onSignInAnonymouslyRequested(
    AuthSignInAnonymouslyRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());

      final response = await _supabase.auth.signInAnonymously();

      if (response.user != null) {
        emit(AuthAuthenticated(
          user: response.user!,
          userId: response.user!.id,
        ));
      } else {
        emit(const AuthError(
          'Une erreur est survenue lors de la connexion anonyme',
        ));
      }
    } on AuthException catch (e) {
      emit(AuthError(_getErrorMessage(e)));
    } catch (e) {
      emit(AuthError(_getErrorMessage(e)));
    }
  }

  /// Deconnexion.
  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());
      await _supabase.auth.signOut();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(_getErrorMessage(e)));
    }
  }

  /// Changement d'etat d'authentification (depuis le stream Supabase).
  void _onAuthStateChanged(
    AuthStateChanged event,
    Emitter<AuthState> emit,
  ) {
    if (event.user != null) {
      emit(AuthAuthenticated(
        user: event.user!,
        userId: event.user!.id,
      ));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  /// Reinitialisation du message d'erreur.
  void _onErrorCleared(
    AuthErrorCleared event,
    Emitter<AuthState> emit,
  ) {
    // Revenir a l'etat non-authentifie apres avoir efface l'erreur
    emit(const AuthUnauthenticated());
  }

  @override
  Future<void> close() {
    _authStateSubscription.cancel();
    return super.close();
  }
}
