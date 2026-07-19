class ChatMessage {
  final String id;
  final String senderId;
  final String senderRole; // 'partner' or 'patient'
  final String content;
  final String? imageUrl;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.content,
    this.imageUrl,
    required this.timestamp,
  });

  bool get isSentByMe => senderRole == 'partner';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      senderRole: json['sender_role'] as String? ?? 'patient',
      content: json['content'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      timestamp: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_role': senderRole,
      'content': content,
      'image_url': imageUrl,
      'created_at': timestamp.toIso8601String(),
    };
  }
}
