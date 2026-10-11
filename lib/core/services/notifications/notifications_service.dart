import 'package:paypadi/core/services/notifications/push_notifications_message.dart';

abstract class INotificationsService {
  /// Initializes the notification service (e.g., configuring settings).
  Future<void> initialize();

  /// Requests permission from the user to display notifications.
  /// Returns [true] if granted, [false] otherwise.
  Future<bool> requestPermission();

  /// Retrieves the unique device token used for sending targeted pushes.
  Future<String?> getToken();

  /// A stream that emits a new token whenever the device token is refreshed.
  Stream<String> get onTokenRefresh;

  /// A stream that emits messages received while the app is in the foreground.
  Stream<PushNotificationMessage> get onForegroundMessage;

  /// A stream that emits messages when the user taps on a notification
  /// while the app is in the background.
  Stream<PushNotificationMessage> get onMessageOpenedApp;

  /// Gets the notification that caused the app to open from a terminated state.
  Future<PushNotificationMessage?> getInitialMessage();

  /// Subscribes the device to a specific topic.
  Future<void> subscribeToTopic(String topic);

  /// Unsubscribes the device from a specific topic.
  Future<void> unsubscribeFromTopic(String topic);
}
