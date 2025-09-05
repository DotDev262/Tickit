import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod

// Define the provider for AuthService
final authServiceProvider = StreamNotifierProvider<AuthService, User?>(AuthService.new);

class AuthService extends StreamNotifier<User?> {
  final GoTrueClient _auth = Supabase.instance.client.auth;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  Stream<User?> build() {
    // Listen to authentication state changes and emit the current user
    return _auth.onAuthStateChange.map((authState) => authState.session?.user);
  }

  Future<void> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn(
        serverClientId: dotenv.env['GOOGLE_SERVER_CLIENT_ID']!,
      );
      if (googleUser == null) {
        // User cancelled the sign-in
        return;
      }
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        throw 'No access token found.';
      }
      if (idToken == null) {
        throw 'No ID token found.';
      }

      await _auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      // Wait for the authentication state to update in Supabase
      await _auth.onAuthStateChange.firstWhere((authState) => authState.session?.user != null);

      // The build method will automatically update the state based on onAuthStateChange
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    // The build method will automatically update the state based on onAuthStateChange
  }

  // Removed currentUser getter as it's now provided by the StreamNotifier state
}
