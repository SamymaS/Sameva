part of 'auth_bloc.dart';

/// Classe de base pour tous les events d'authentification.
sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Connexion avec email et mot de passe.
final class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthSignInRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Inscription avec email et mot de passe.
final class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthSignUpRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Connexion anonyme.
final class AuthSignInAnonymouslyRequested extends AuthEvent {
  const AuthSignInAnonymouslyRequested();
}

/// Deconnexion.
final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// Changement d'etat d'authentification (depuis le stream Supabase).
final class AuthStateChanged extends AuthEvent {
  final User? user;

  const AuthStateChanged(this.user);

  @override
  List<Object?> get props => [user];
}

/// Reinitialisation du message d'erreur.
final class AuthErrorCleared extends AuthEvent {
  const AuthErrorCleared();
}
