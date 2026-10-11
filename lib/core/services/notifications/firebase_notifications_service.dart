import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:paypadi/core/services/notifications/notifications_service.dart';
import 'package:paypadi/core/services/notifications/push_notifications_message.dart';

class FirebaseNotificationsService implements INotificationsService {
  FirebaseNotificationsService(this._messaging);
  final FirebaseMessaging _messaging;

  @override
  Future<void> initialize() async {
    // Note: To handle background messages in Firebase, you must define a
    // top-level or static function using FirebaseMessaging.onBackgroundMessage()
    // inside your main.dart file, outside of this class.

    // Optional: Configure foreground presentation options for iOS
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> getToken() async {
    return _messaging.getToken();
  }

  @override
  Stream<String> get onTokenRefresh {
    return _messaging.onTokenRefresh;
  }

  @override
  Stream<PushNotificationMessage> get onForegroundMessage {
    return FirebaseMessaging.onMessage.map(_mapToGenericMessage);
  }

  @override
  Stream<PushNotificationMessage> get onMessageOpenedApp {
    return FirebaseMessaging.onMessageOpenedApp.map(_mapToGenericMessage);
  }

  @override
  Future<PushNotificationMessage?> getInitialMessage() async {
    final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      return _mapToGenericMessage(initialMessage);
    }
    return null;
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  // --- Helper Methods ---

  PushNotificationMessage _mapToGenericMessage(RemoteMessage message) {
    return PushNotificationMessage(
      messageId: message.messageId,
      title: message.notification?.title,
      body: message.notification?.body,
      data: message.data,
    );
  }
}
