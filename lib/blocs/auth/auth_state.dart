part of 'auth_bloc.dart';

/// Classe de base pour tous les states d'authentification.
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Etat initial au lancement de l'application.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Chargement en cours (connexion, inscription, deconnexion).
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Utilisateur authentifie.
final class AuthAuthenticated extends AuthState {
  final User user;
  final String userId;

  const AuthAuthenticated({
    required this.user,
    required this.userId,
  });

  @override
  List<Object?> get props => [user, userId];
}

/// Utilisateur non authentifie.
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Erreur d'authentification avec message lisible.
final class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
