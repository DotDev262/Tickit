import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tickit/routes/app_router.dart';
import 'package:tickit/services/todo_service.dart';
import 'package:tickit/theme/app_theme.dart';
import 'package:tickit/services/settings_manager.dart'; // Import SettingsManager
import 'package:tickit/services/auth_service.dart'; // Import authServiceProvider
import 'package:dynamic_color/dynamic_color.dart'; // Import dynamic_color

// Import this

final todoServiceProvider = Provider((ref) => TodoService());

final todoListProvider = FutureProvider((ref) async {
  final user = ref.watch(authServiceProvider);
  if (user.valueOrNull == null) {
    // User is not logged in, return an empty list or handle as appropriate
    return [];
  }
  final todoService = ref.watch(todoServiceProvider);
  return todoService.getTodos();
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  // Initialize SettingsManager
  await SettingsManager().init();

  await Supabase.initialize(
    url: "https://mxexwydyrlqittwylwbg.supabase.co",
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: SettingsManager().themeModeNotifier,
          builder: (context, themeMode, child) {
            return MaterialApp.router(
              title: 'Tickit',
              debugShowCheckedModeBanner: false,
              routerConfig: AppRouter.router,
              themeMode: themeMode,
              theme: AppTheme.lightTheme(lightDynamic),
              darkTheme: AppTheme.darkTheme(darkDynamic),
            );
          },
        );
      },
    );
  }
}
