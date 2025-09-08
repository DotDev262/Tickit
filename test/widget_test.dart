import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tickit/main.dart';
import 'package:tickit/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthService implements AuthService {
  @override
  Stream<User?> get onAuthStateChange => Stream.value(null);

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthResponse> signInWithGoogle() async {
    return AuthResponse(session: null, user: null);
  }
}

void main() {
  testWidgets('shows LoginPage when not authenticated', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(MockAuthService())],
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sign in with Google'), findsOneWidget);
  });
}
