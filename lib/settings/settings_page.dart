import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tickit/services/auth_service.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

// Providers
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
final notificationsEnabledProvider = StateProvider<bool>((ref) => true);
final swipeToDeleteEnabledProvider = StateProvider<bool>((ref) => true);
final swipeToMarkDoneEnabledProvider = StateProvider<bool>((ref) => true);

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // User Profile Section with Async handling
          Consumer(
            builder: (context, ref, child) {
              final authState = ref.watch(authStateProvider);

              return authState.when(
                data: (user) {
                  if (user == null) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (user.userMetadata?['avatar_url'] != null)
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: NetworkImage(
                              user.userMetadata!['avatar_url'],
                            ),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          user.userMetadata?['full_name'] ??
                              user.email ??
                              'User',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.email ?? '',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => const SizedBox.shrink(),
              );
            },
          ),

          const Divider(),

          // Theme Selection Section with RadioGroup
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Theme',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),

          RadioGroup<ThemeMode>(
            groupValue: currentThemeMode,
            onChanged: (ThemeMode? mode) {
              if (mode != null) {
                ref.read(themeModeProvider.notifier).state = mode;
              }
            },
            child: Column(
              children: ThemeMode.values.map((mode) {
                final title =
                    mode.name[0].toUpperCase() + mode.name.substring(1);
                return Row(
                  children: [
                    Radio<ThemeMode>(value: mode),
                    Text(
                      title,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),

          const Divider(),

          // Notifications Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Notifications',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),

          SwitchListTile(
            title: const Text('Enable Notifications'),
            value: ref.watch(notificationsEnabledProvider),
            onChanged: (bool enabled) async {
              ref.read(notificationsEnabledProvider.notifier).state = enabled;

              if (enabled) {
                final isAllowed = await AwesomeNotifications()
                    .isNotificationAllowed();
                if (!isAllowed) {
                  await AwesomeNotifications()
                      .requestPermissionToSendNotifications();
                }
              } else {
                await AwesomeNotifications().cancelAllSchedules();
              }
            },
          ),

          const Divider(),

          // Swipe Actions Toggles
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Swipe Actions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),

          SwitchListTile(
            title: const Text('Enable Swipe to Delete'),
            value: ref.watch(swipeToDeleteEnabledProvider),
            onChanged: (value) {
              ref.read(swipeToDeleteEnabledProvider.notifier).state = value;
            },
          ),

          SwitchListTile(
            title: const Text('Enable Swipe to Mark as Done'),
            value: ref.watch(swipeToMarkDoneEnabledProvider),
            onChanged: (value) {
              ref.read(swipeToMarkDoneEnabledProvider.notifier).state = value;
            },
          ),

          const Divider(),

          // Logout Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () async {
                await ref.read(authServiceProvider).signOut();
              },
              child: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }
}
