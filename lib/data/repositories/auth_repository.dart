import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';

/// Jetons Google prêts à être transmis à Supabase Auth
/// (`linkIdentityWithIdToken` / `signInWithIdToken`).
class GoogleAuthTokens {
  final String idToken;
  final String? accessToken;

  const GoogleAuthTokens({required this.idToken, this.accessToken});
}

/// Abstraction sur `google_sign_in` (API 7.x, singleton `GoogleSignIn.instance`).
/// Permet d'injecter un double de test dans [AuthRepository] — le SDK Google
/// natif n'est pas mockable directement (pas de constructeur, méthodes statiques).
abstract class GoogleAuthGateway {
  Future<GoogleAuthTokens> signIn();
}

/// Implémentation réelle basée sur `google_sign_in` ^7.x.
class GoogleSignInGateway implements GoogleAuthGateway {
  bool _initialized = false;

  @override
  Future<GoogleAuthTokens> signIn() async {
    // GoogleSignIn.instance.initialize() doit être appelé exactement une
    // fois avant tout autre appel (API 7.x, singleton, pas de constructeur).
    if (!_initialized) {
      await GoogleSignIn.instance.initialize(
        serverClientId: SupabaseConfig.googleWebClientId,
      );
      _initialized = true;
    }

    // Authentification et autorisation sont deux étapes séparées.
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AuthException(
        'Impossible de récupérer le jeton d\'identité Google. Veuillez réessayer.',
      );
    }

    const scopes = ['email', 'profile'];
    final authorizationClient = account.authorizationClient;
    final authz = await authorizationClient.authorizationForScopes(scopes) ??
        await authorizationClient.authorizeScopes(scopes);

    return GoogleAuthTokens(idToken: idToken, accessToken: authz.accessToken);
  }
}

/// Accès aux données d'authentification via Supabase Auth.
/// Pas d'état UI — retourne des valeurs ou lance des exceptions.
class AuthRepository {
  final SupabaseClient _supabase;
  final GoogleAuthGateway _googleAuth;

  AuthRepository(this._supabase, {GoogleAuthGateway? googleAuth})
      : _googleAuth = googleAuth ?? GoogleSignInGateway();

  User? get currentUser => _supabase.auth.currentUser;
  String? get userId => _supabase.auth.currentUser?.id;
  bool get isAuthenticated => _supabase.auth.currentUser != null;

  /// Flux des changements d'état d'authentification.
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    return response.user;
  }

  Future<User?> createUserWithEmailAndPassword(String email, String password) async {
    final response = await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
    );
    return response.user;
  }

  /// Connexion anonyme (mode invité). Le user_id est stable jusqu'à la mise à niveau.
  Future<User?> signInAnonymously() async {
    final response = await _supabase.auth.signInAnonymously();
    return response.user;
  }

  /// Met à niveau un compte invité vers un compte email/mot de passe.
  /// Doit être appelé sur la session anonyme active — préserve le user_id.
  Future<User?> upgradeAnonymousToEmail({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.updateUser(
      UserAttributes(email: email.trim(), password: password),
    );
    return response.user;
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Connexion via Google.
  ///
  /// Si une session invite (anonyme) est active, l'identité Google est
  /// LIÉE au compte existant via [GoTrueClient.linkIdentityWithIdToken] :
  /// le user_id est préservé, donc quêtes, stats et jetons de l'invité
  /// restent intacts. Sinon, connexion/création classique via
  /// [GoTrueClient.signInWithIdToken].
  ///
  /// Si l'identité Google est déjà liée à un autre compte, la liaison
  /// échoue (code `identity_already_exists`) et une [AuthException] au
  /// message clair est relancée — la session invite n'est jamais détruite
  /// (l'échec survient avant toute sauvegarde de session, donc rien n'est
  /// écrasé côté client).
  ///
  /// L'annulation par l'utilisateur lance une [GoogleSignInException]
  /// (code [GoogleSignInExceptionCode.canceled]) qui n'est pas avalée ici :
  /// c'est à l'appelant (ViewModel) de décider de ne pas l'afficher comme
  /// une erreur.
  Future<User?> signInWithGoogle() async {
    final tokens = await _googleAuth.signIn();

    final user = currentUser;
    final wasGuest = user != null && user.isAnonymous;

    if (wasGuest) {
      try {
        final response = await _supabase.auth.linkIdentityWithIdToken(
          provider: OAuthProvider.google,
          idToken: tokens.idToken,
          accessToken: tokens.accessToken,
        );
        return response.user;
      } on AuthException catch (e) {
        if (e.code == 'identity_already_exists') {
          throw const AuthException(
            'Ce compte Google est déjà associé à un autre profil Sameva. '
            'Votre progression invité reste intacte : connectez-vous avec '
            'un autre compte Google ou continuez en tant qu\'invité.',
            code: 'identity_already_exists',
          );
        }
        rethrow;
      }
    }

    final response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: tokens.idToken,
      accessToken: tokens.accessToken,
    );
    return response.user;
  }
}
