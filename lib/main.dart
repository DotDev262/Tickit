import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tickit/firebase_options.dart';
import 'package:tickit/routes/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tickit/services/settings_manager.dart';
import 'package:tickit/settings/settings_page.dart'; // Added
// Added

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Initialize Firebase (if not already done by flutterfire configure)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await AwesomeNotifications().initialize(
    'resource://drawable/tickit', // Use your app icon name here
    [
      NotificationChannel(
        channelGroupKey: 'basic_channel_group',
        channelKey: 'basic_channel',
        channelName: 'Basic notifications',
        channelDescription: 'Notification channel for basic tests',
        defaultColor: const Color(0xFF9D50DD),
        ledColor: Colors.white,
      ),
    ],
  );

  await SettingsManager().init();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    final themeMode = ref.watch(
      themeModeProvider,
    ); // Watch the themeModeProvider

    return MaterialApp.router(
      title: 'Tickit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor:
              Colors.blue, // Example: Use primary color for selected item
          unselectedItemColor:
              Colors.grey, // Example: Use grey for unselected items
          backgroundColor: Colors.white, // Example: White background
          type: BottomNavigationBarType
              .fixed, // Ensure fixed type for consistent behavior
          // You can add more Material 3 specific properties here if needed
          // For example, indicatorColor, elevation, etc.
        ),
      ),
      darkTheme: ThemeData(
        // Define a dark theme
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Colors
              .blueAccent, // Example: Use accent color for selected item in dark theme
          unselectedItemColor:
              Colors.grey, // Example: Use grey for unselected items
          backgroundColor: Colors.black, // Example: Black background
          type: BottomNavigationBarType
              .fixed, // Ensure fixed type for consistent behavior
        ),
      ),
      themeMode: themeMode, // Set the themeMode
      routerConfig: router,
    );
  }
}
