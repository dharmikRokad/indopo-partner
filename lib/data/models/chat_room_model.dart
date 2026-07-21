class ChatRoomModel {
  final String id;
  final String patientId;
  final String partnerId;
  final String patientName;
  final String? patientPhotoUrl;
  final String partnerName;
  final String? partnerPhotoUrl;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int partnerUnreadCount;
  final int patientUnreadCount;
  final DateTime createdAt;

  ChatRoomModel({
    required this.id,
    required this.patientId,
    required this.partnerId,
    required this.patientName,
    this.patientPhotoUrl,
    required this.partnerName,
    this.partnerPhotoUrl,
    this.lastMessage,
    this.lastMessageTime,
    this.partnerUnreadCount = 0,
    this.patientUnreadCount = 0,
    required this.createdAt,
  });

  String get patientInitials {
    if (patientName.trim().isEmpty) return 'P';
    final parts = patientName.trim().split(' ');
    if (parts.length > 1 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  String get partnerInitials {
    if (partnerName.trim().isEmpty) return 'M';
    final parts = partnerName.trim().split(' ');
    if (parts.length > 1 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      id: json['id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      partnerId: json['partner_id']?.toString() ?? '',
      patientName: json['patient_name']?.toString() ?? 'Patient',
      patientPhotoUrl: json['patient_photo_url'] as String?,
      partnerName: json['partner_name']?.toString() ?? 'Pharmacy Partner',
      partnerPhotoUrl: json['partner_photo_url'] as String?,
      lastMessage: json['last_message'] as String?,
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time'] as String)
          : null,
      partnerUnreadCount: json['partner_unread_count'] as int? ?? 0,
      patientUnreadCount: json['patient_unread_count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'partner_id': partnerId,
      'patient_name': patientName,
      'patient_photo_url': patientPhotoUrl,
      'partner_name': partnerName,
      'partner_photo_url': partnerPhotoUrl,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime?.toIso8601String(),
      'partner_unread_count': partnerUnreadCount,
      'patient_unread_count': patientUnreadCount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
