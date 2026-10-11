class PushNotificationMessage {
  const PushNotificationMessage({
    this.messageId,
    this.title,
    this.body,
    this.data = const {},
  });

  final String? messageId;
  final String? title;
  final String? body;
  final Map<String, dynamic> data;

  @override
  String toString() {
    return 'PushNotificationMessage(messageId: $messageId, title: $title, body: $body, data: $data)';
  }
}
