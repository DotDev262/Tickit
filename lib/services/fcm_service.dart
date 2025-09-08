import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  Future<void> initialize() async {
    // Request permission for notifications (iOS only)
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // Get the initial token and update it in Supabase
      final token = await _firebaseMessaging.getToken();
      if (token != null && _supabaseClient.auth.currentUser != null) {
        await _updateFCMTokenForUser(token);
      }

      // Listen for token refreshes and update in Supabase
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        if (_supabaseClient.auth.currentUser != null) {
          await _updateFCMTokenForUser(newToken);
        }
      });
    }

    // Foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background message handler registration
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> _updateFCMTokenForUser(String token) async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabaseClient.from('profiles').upsert({
        'id': userId,
        'fcm_token': token,
      }, onConflict: 'id');
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (message.notification == null) return;

    // Show local notification
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: message.hashCode,
        channelKey: 'basic_channel',
        title: message.notification?.title,
        body: message.notification?.body,
        payload: message.data.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      ),
    );

    // Save notification to Supabase
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId != null) {
      try {
        await _supabaseClient.from('notifications').insert({
          'user_id': userId,
          'body': message.notification?.body ?? message.data.toString(),
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        // Handle error silently
      }
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    if (message.notification == null) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: message.hashCode,
        channelKey: 'basic_channel',
        title: message.notification?.title,
        body: message.notification?.body,
        payload: message.data.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      ),
    );

    try {
      final supabaseClient = Supabase.instance.client;
      final userId = supabaseClient.auth.currentUser?.id;
      if (userId != null) {
        await supabaseClient.from('notifications').insert({
          'user_id': userId,
          'body': message.notification?.body ?? message.data.toString(),
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      // Background handler should not throw exceptions
    }
  }
}
