class ChatConversation {
  final String id; // same as the approved claim id
  final String claimId;
  final String itemId;
  final String itemTitle;
  final String posterId;
  final String posterName;
  final String claimantId;
  final String claimantName;
  final bool enabled;
  /// Why a disabled chat was closed: 'resolved' (owner marked the item claimed)
  /// or 'admin' (moderator action). Null while the chat is still open.
  final String? closedReason;
  final String? lastMessageText;
  final String? lastMessageSenderId;
  final DateTime? lastMessageAt;
  final DateTime updatedAt;

  const ChatConversation({
    required this.id,
    required this.claimId,
    required this.itemId,
    required this.itemTitle,
    required this.posterId,
    required this.posterName,
    required this.claimantId,
    required this.claimantName,
    required this.enabled,
    this.closedReason,
    this.lastMessageText,
    this.lastMessageSenderId,
    this.lastMessageAt,
    required this.updatedAt,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final lastMessage = json['lastMessage'] is Map<String, dynamic>
        ? json['lastMessage'] as Map<String, dynamic>
        : null;

    return ChatConversation(
      id: json['id']?.toString() ?? '',
      claimId: json['claimId']?.toString() ?? '',
      itemId: json['itemId']?.toString() ?? '',
      itemTitle: json['itemTitle']?.toString() ?? 'Item',
      posterId: json['posterId']?.toString() ?? '',
      posterName: json['posterName']?.toString() ?? 'Poster',
      claimantId: json['claimantId']?.toString() ?? '',
      claimantName: json['claimantName']?.toString() ?? 'Claimant',
      enabled: json['enabled'] == true,
      closedReason: json['closedReason']?.toString(),
      lastMessageText: lastMessage?['text']?.toString(),
      lastMessageSenderId: lastMessage?['senderId']?.toString(),
      lastMessageAt: _fromMillis(lastMessage?['sentAt']),
      updatedAt: _fromMillis(json['updatedAt']) ?? DateTime.now(),
    );
  }

  /// Name of the user on the other side of this conversation.
  String otherPartyName(String currentUserId) {
    return currentUserId == posterId ? claimantName : posterName;
  }

  String get timeAgo {
    final reference = lastMessageAt ?? updatedAt;
    final diff = DateTime.now().difference(reference);
    if (diff.inDays > 1) return '${diff.inDays}d';
    if (diff.inDays == 1) return '1d';
    if (diff.inHours >= 1) return '${diff.inHours}h';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m';
    return 'now';
  }

  static DateTime? _fromMillis(Object? value) {
    final ms = value is int ? value : int.tryParse(value?.toString() ?? '');
    if (ms == null || ms <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  /// Hosted URL of an image shared in this message, or null for text-only
  /// messages. A message may carry text, an image, or both.
  final String? imageUrl;
  final DateTime sentAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.imageUrl,
    required this.sentAt,
  });

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final image = json['imageUrl']?.toString();
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      imageUrl: (image != null && image.isNotEmpty) ? image : null,
      sentAt: ChatConversation._fromMillis(json['sentAt']) ?? DateTime.now(),
    );
  }

  String get formattedTime {
    final hour = sentAt.hour % 12 == 0 ? 12 : sentAt.hour % 12;
    final minute = sentAt.minute.toString().padLeft(2, '0');
    final period = sentAt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
