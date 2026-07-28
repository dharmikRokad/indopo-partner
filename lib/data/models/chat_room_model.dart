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
    final rawPatientName = json['patient_name'] ??
        json['patientName'] ??
        json['patient']?['name'] ??
        json['patient']?['fullName'] ??
        'Patient';

    final rawPatientPhoto = json['patient_photo_url'] ??
        json['patientPhotoUrl'] ??
        json['patient']?['photoUrl'] ??
        json['patient']?['profilePic'];

    final rawPartnerName = json['partner_name'] ??
        json['partnerName'] ??
        json['partner']?['name'] ??
        'Pharmacy Partner';

    final rawPartnerPhoto = json['partner_photo_url'] ??
        json['partnerPhotoUrl'] ??
        json['partner']?['photoUrl'];

    final rawLastMessage = json['last_message'] ?? json['lastMessage'];

    DateTime? parsedTime;
    final timeVal = json['last_message_time'] ?? json['lastMessageTime'];
    if (timeVal != null) {
      parsedTime = DateTime.tryParse(timeVal.toString())?.toLocal();
    }

    int parseCount(dynamic val) {
      if (val is int) return val;
      if (val != null) return int.tryParse(val.toString()) ?? 0;
      return 0;
    }

    DateTime parsedCreatedAt = DateTime.now();
    final createdVal = json['created_at'] ?? json['createdAt'];
    if (createdVal != null) {
      parsedCreatedAt = DateTime.tryParse(createdVal.toString())?.toLocal() ?? DateTime.now();
    }

    return ChatRoomModel(
      id: json['id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? json['patientId']?.toString() ?? '',
      partnerId: json['partner_id']?.toString() ?? json['partnerId']?.toString() ?? '',
      patientName: rawPatientName.toString(),
      patientPhotoUrl: rawPatientPhoto?.toString(),
      partnerName: rawPartnerName.toString(),
      partnerPhotoUrl: rawPartnerPhoto?.toString(),
      lastMessage: rawLastMessage?.toString(),
      lastMessageTime: parsedTime,
      partnerUnreadCount: parseCount(json['partner_unread_count'] ?? json['partnerUnreadCount']),
      patientUnreadCount: parseCount(json['patient_unread_count'] ?? json['patientUnreadCount']),
      createdAt: parsedCreatedAt,
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
