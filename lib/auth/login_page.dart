import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tickit/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import AuthException
import 'package:tickit/routes/app_router.dart'; // Import AppRoutes

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              await AuthService().signInWithGoogle();
              if (context.mounted) {
                context.goNamed(AppRoutes.tasks); // Use named route
              }
            } catch (e) {
              if (context.mounted) {
                String errorMessage = 'Sign-in failed. Please try again.';
                if (e is AuthException) {
                  errorMessage = 'Authentication failed: ${e.message}';
                } else {
                  errorMessage = 'An unexpected error occurred: $e';
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
                  ),
                );
              }
            }
          },
          child: const Text('Sign in with Google'),
        ),
      ),
    );
  }
}