class ChatMessage {
  final String id;
  final String chatId;
  final String appointmentId;
  final String senderId;
  final String senderRole; // 'partner' or 'patient'
  final String content;
  final String? imageUrl;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.appointmentId,
    required this.senderId,
    required this.senderRole,
    required this.content,
    this.imageUrl,
    required this.timestamp,
  });

  bool get isSentByMe => senderRole == 'partner';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      chatId: json['chat_id']?.toString() ?? '',
      appointmentId: json['appointment_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      senderRole: json['sender_role']?.toString() ?? 'patient',
      content: json['content']?.toString() ?? '',
      imageUrl: json['image_url'] as String?,
      timestamp: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
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
      'image_url': imageUrl,
      'created_at': timestamp.toIso8601String(),
    };
  }
}
