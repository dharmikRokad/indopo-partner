class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String senderRole; // 'partner' or 'patient'
  final String content;
  final String? imageUrl;
  final String? parentMessageId;
  final int replyCount;
  final int unreadReplyCount;
  final bool isPrescription;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderRole,
    required this.content,
    this.imageUrl,
    this.parentMessageId,
    this.replyCount = 0,
    this.unreadReplyCount = 0,
    this.isPrescription = false,
    required this.createdAt,
  });

  /// True when this message was sent by the pharmacy partner (us)
  bool get isSentByPartner => senderRole == 'PARTNER';

  /// True when this is a root (thread-starter) message
  bool get isRootMessage =>
      parentMessageId == null || parentMessageId!.trim().isEmpty;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    int parseCount(dynamic val) {
      if (val is int) return val;
      if (val != null) return int.tryParse(val.toString()) ?? 0;
      return 0;
    }

    return ChatMessage(
      id: json['id']?.toString() ?? '',
      chatId: json['chat_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      senderRole: (json['sender_role']?.toString() ?? 'PATIENT').toUpperCase(),
      content: json['content']?.toString() ?? '',
      imageUrl: json['image_url'] as String?,
      parentMessageId: json['parent_message_id'] as String?,
      replyCount: parseCount(json['reply_count']),
      unreadReplyCount: parseCount(json['unread_reply_count']),
      isPrescription: json['is_prescription'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'] as String)?.toLocal() ??
                DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'sender_role': senderRole,
      'content': content,
      if (imageUrl != null && imageUrl!.isNotEmpty) 'image_url': imageUrl,
      if (parentMessageId != null && parentMessageId!.isNotEmpty)
        'parent_message_id': parentMessageId,
      'is_prescription': isPrescription,
      'reply_count': replyCount,
      'unread_reply_count': unreadReplyCount,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}
