class ChatMessage {
  final String id;
  final String chatId;
  final String appointmentId;
  final String senderId;
  final String senderRole; // 'partner' or 'patient'
  final String content;
  final String? imageUrl;
  final String? parentMessageId;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.appointmentId,
    required this.senderId,
    required this.senderRole,
    required this.content,
    this.imageUrl,
    this.parentMessageId,
    required this.timestamp,
  });

  bool get isSentByMe => senderRole == 'partner';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      chatId: json['chat_id']?.toString() ?? json['chatId']?.toString() ?? '',
      appointmentId: json['appointment_id']?.toString() ?? json['appointmentId']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? json['senderId']?.toString() ?? '',
      senderRole: json['sender_role']?.toString() ?? json['senderRole']?.toString() ?? 'patient',
      content: json['content']?.toString() ?? '',
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String?,
      parentMessageId: json['parent_message_id'] as String? ?? json['parentMessageId'] as String?,
      timestamp: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'] as String) ?? DateTime.now())
          : (json['createdAt'] != null
              ? (DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now())
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'appointment_id': appointmentId,
      'sender_id': senderId,
      'sender_role': senderRole,
      'content': content,
      if (imageUrl != null) 'image_url': imageUrl,
      if (parentMessageId != null) 'parent_message_id': parentMessageId,
      if (parentMessageId != null) 'parentMessageId': parentMessageId,
      'created_at': timestamp.toIso8601String(),
    };
  }
}
