/// Mirrors frontend/src/mockData/mockNotifications.ts `NotificationItem`.
class NotificationItem {
  final String id;
  final String group;
  final String title;
  final String body;
  final String type;
  final bool unread;

  /// Where tapping this notification should go. Null for notifications
  /// that are just an FYI with nowhere useful to send the user.
  final String? route;

  const NotificationItem({
    required this.id,
    required this.group,
    required this.title,
    required this.body,
    required this.type,
    required this.unread,
    this.route,
  });
}
