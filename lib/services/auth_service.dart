import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Added
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Added

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).onAuthStateChange;
});

class AuthService {
  final _client = Supabase.instance.client;

  Stream<User?> get onAuthStateChange => _client.auth.onAuthStateChange.map((event) => event.session?.user);

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<AuthResponse> signInWithGoogle() async {
    // Create a GoogleSignIn instance
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: dotenv.env['GOOGLE_ANDROID_CLIENT_ID'], // Use GOOGLE_ANDROID_CLIENT_ID for clientId
      serverClientId: dotenv.env['GOOGLE_SERVER_CLIENT_ID'], // Use GOOGLE_SERVER_CLIENT_ID for serverClientId
    );

    // Sign in with Google
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in aborted by user.');
    }

    // Get Google ID token and Access Token
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final String? idToken = googleAuth.idToken;
    final String? accessToken = googleAuth.accessToken; // Get accessToken

    if (idToken == null) {
      throw Exception('No Google ID Token found.');
    }
    if (accessToken == null) { // Check accessToken
      throw Exception('No Google Access Token found.');
    }

    // Sign in to Supabase with the ID token and Access Token
    return _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken, // Pass accessToken
    );
  }
}