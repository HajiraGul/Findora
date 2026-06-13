class AppNotification {
  final String id;
  final String type; // match | claim | account | system
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final String timeAgo;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.timeAgo,
  });

  /// Convenience accessor for the item this notification deep-links to (the
  /// recipient's own post whose match list should open).
  String? get itemId => data['itemId']?.toString();

  String? get matchItemId => data['matchItemId']?.toString();

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return AppNotification(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'system',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      data: rawData is Map
          ? rawData.map((key, value) => MapEntry(key.toString(), value))
          : <String, dynamic>{},
      isRead: json['isRead'] as bool? ?? false,
      timeAgo: json['timeAgo']?.toString() ?? '',
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      data: data,
      isRead: isRead ?? this.isRead,
      timeAgo: timeAgo,
    );
  }
}
