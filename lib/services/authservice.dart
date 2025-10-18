import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  Future<AuthResponse> signUp(String email, String password) {
    return supabase.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signIn(String email, String password) {
    return supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signInWithGoogle() async {
    // Initialize once (preferably in main.dart)
    await GoogleSignIn.instance.initialize(
      clientId: "10975649203-r7ovjim91uke2p9t6h6j63uvm36sshfe.apps.googleusercontent.com", // Android
      serverClientId: "10975649203-6hdjqmnp2bb7b1hprqpoheoq49r6rkc6.apps.googleusercontent.com", // Web
    );

    // Start sign-in
    final account = await GoogleSignIn.instance.authenticate(
      scopeHint: ['email', 'profile'],
    );
    if (account == null) throw "User cancelled sign-in";

    // Get ID token
    final googleAuth = account.authentication;

    // Get access token (new API)
    final authz = await account.authorizationClient.authorizeScopes(
      ["email", "profile"],
    );
    final accessToken = authz.accessToken;

    // Authenticate with Supabase
    final response = await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: googleAuth.idToken!,
      accessToken: accessToken, 
    );

    if (response.session == null) {
      throw "Supabase sign-in failed";
    }
  }

  Future<void> signOut() => supabase.auth.signOut();

  Session? getSession() => supabase.auth.currentSession;

  Stream<AuthState> get authChanges => supabase.auth.onAuthStateChange;

  User? get currentUser => supabase.auth.currentUser;
}
