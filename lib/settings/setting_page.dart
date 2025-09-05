import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tickit/services/auth_service.dart'; // Import AuthService and authServiceProvider
import 'package:tickit/routes/app_router.dart'; // Import AppRoutes
import 'package:tickit/services/settings_manager.dart'; // Import SettingsManager

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authServiceProvider); // Watch the auth state

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          authState.when(
            data: (user) {
              final String? displayName =
                  user?.userMetadata?['full_name'] as String?;
              final String? photoUrl =
                  user?.userMetadata?['avatar_url'] as String?;

              return UserAccountsDrawerHeader(
                accountName: Text(
                  displayName ?? 'Anonymous',
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                ),
                accountEmail: Text(
                  user?.email ?? '',
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: photoUrl != null
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl == null ? const Icon(Icons.person) : null,
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => UserAccountsDrawerHeader(
              accountName: const Text('Error'),
              accountEmail: Text('Failed to load user: $error'),
              currentAccountPicture: const CircleAvatar(
                child: Icon(Icons.error),
              ),
            ),
          ),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: SettingsManager().themeModeNotifier,
            builder: (context, themeMode, child) {
              return RadioGroup<ThemeMode>(
                groupValue: themeMode,
                onChanged: (ThemeMode? newValue) {
                  if (newValue != null) {
                    SettingsManager().setThemeMode(newValue);
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Theme Mode',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text('System Default', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                      value: ThemeMode.system,
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text('Light', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                      value: ThemeMode.light,
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text('Dark', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                      value: ThemeMode.dark,
                    ),
                  ],
                ),
              );
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: SettingsManager().notificationsEnabledNotifier,
            builder: (context, notificationsEnabled, child) {
              return SwitchListTile(
                title: const Text('Enable Notifications'),
                secondary: const Icon(Icons.notifications_active),
                value: notificationsEnabled,
                onChanged: (value) {
                  SettingsManager().setNotificationsEnabled(value);
                },
              );
            },
          ),
          ListTile(
            title: const Text('Logout'),
            leading: const Icon(Icons.logout),
            onTap: () async {
              await ref
                  .read(authServiceProvider.notifier)
                  .signOut(); // Use notifier to call signOut
              if (context.mounted) {
                context.goNamed(AppRoutes.login); // Use named route
              }
            },
          ),
        ],
      ),
    );
  }
}
