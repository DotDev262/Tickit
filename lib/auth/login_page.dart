import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tickit/services/auth_service.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Grab scaffoldMessenger before any async gaps
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SupaEmailAuth(
            onSignInComplete: (response) {
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('Sign in complete!')),
              );
            },
            onSignUpComplete: (response) {
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text(
                    'Sign up complete! Check your email for verification.',
                  ),
                ),
              );
            },
          ),
          const Divider(),
          // Custom Social Login Buttons
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await ref.read(authServiceProvider).signInWithGoogle();
              } catch (e) {
                // Use scaffoldMessenger here, no BuildContext used after await
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Google sign-in failed: $e')),
                );
              }
            },
            icon: const Icon(Icons.g_mobiledata), // Google icon
            label: const Text('Sign in with Google'),
          ),
        ],
      ),
    );
  }
}
