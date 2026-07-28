enum RequestStatus {
  newRequest(key: 'new', apiKey: 'PENDING', displayName: 'New'),
  inProgress(key: 'in_progress', apiKey: 'CONFIRMED', displayName: 'Confirmed'),
  completed(key: 'completed', apiKey: 'COMPLETED', displayName: 'Completed'),
  cancelled(key: 'cancelled', apiKey: 'CANCELLED', displayName: 'Cancelled');

  final String key;
  final String apiKey;
  final String displayName;

  const RequestStatus({
    required this.key,
    required this.apiKey,
    required this.displayName,
  });

  static RequestStatus fromKey(String key) {
    switch (key.toLowerCase()) {
      case 'pending':
        return RequestStatus.newRequest;
      case 'confirmed':
        return RequestStatus.inProgress;
      case 'completed':
        return RequestStatus.completed;
      case 'cancelled':
        return RequestStatus.cancelled;
      default:
        return RequestStatus.newRequest;
    }
  }
}

class RequestModel {
  final String id;
  final String? patientId;
  final String? notificationId;
  final String? chatId;
  final String? tokenNumber;
  final String patientName;
  final int patientAge;
  final String patientGender;
  final String patientContact;
  final String description;
  final List<String> attachments;
  final DateTime timestamp;
  final RequestStatus status;
  final String? rejectionReason;

  RequestModel({
    required this.id,
    this.patientId,
    this.notificationId,
    this.chatId,
    this.tokenNumber,
    required this.patientName,
    required this.patientAge,
    required this.patientGender,
    required this.patientContact,
    required this.description,
    required this.attachments,
    required this.timestamp,
    required this.status,
    this.rejectionReason,
  });

  String get patientInitials {
    if (patientName.isEmpty) return 'P';
    final parts = patientName.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    final statusStr = (json['status'] as String? ?? 'PENDING').toUpperCase();
    RequestStatus mappedStatus;
    if (statusStr == 'PENDING') {
      mappedStatus = RequestStatus.newRequest;
    } else if (statusStr == 'CONFIRMED') {
      mappedStatus = RequestStatus.inProgress;
    } else if (statusStr == 'COMPLETED') {
      mappedStatus = RequestStatus.completed;
    } else {
      mappedStatus = RequestStatus.cancelled;
    }

    final tokenNo = json['tokenNumber']?.toString() ??
        json['token_number']?.toString() ??
        json['token']?.toString() ??
        json['tokenNo']?.toString() ??
        json['token_no']?.toString() ??
        json['appointmentNumber']?.toString() ??
        json['appointment_number']?.toString();

    return RequestModel(
      id: json['id'] as String? ?? '',
      patientId: json['patientId'] as String? ?? json['patient_id'] as String?,
      notificationId: json['notificationId'] as String? ?? json['notification_id'] as String?,
      chatId: json['chatId'] as String? ?? json['chat_id'] as String?,
      tokenNumber: tokenNo,
      patientName: json['patientName'] as String? ?? 'Unknown Patient',
      patientAge: json['patientAge'] as int? ?? 30,
      patientGender: json['patientGender'] as String? ?? 'Other',
      patientContact: json['patientPhone'] as String? ?? '',
      description: json['notes'] as String? ?? '',
      attachments: const [],
      timestamp: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      status: mappedStatus,
      rejectionReason: null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (notificationId != null) 'notification_id': notificationId,
      if (chatId != null) 'chat_id': chatId,
      if (tokenNumber != null) 'token_number': tokenNumber,
      'patient_name': patientName,
      'patient_age': patientAge,
      'patient_gender': patientGender,
      'patient_contact': patientContact,
      'description': description,
      'attachments': attachments,
      'created_at': timestamp.toIso8601String(),
      'status': status.key,
      'rejection_reason': rejectionReason,
    };
  }

  RequestModel copyWith({
    String? id,
    String? patientId,
    String? notificationId,
    String? chatId,
    String? tokenNumber,
    String? patientName,
    int? patientAge,
    String? patientGender,
    String? patientContact,
    String? requestType,
    String? description,
    List<String>? attachments,
    DateTime? timestamp,
    RequestStatus? status,
    String? rejectionReason,
  }) {
    return RequestModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      notificationId: notificationId ?? this.notificationId,
      chatId: chatId ?? this.chatId,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      patientName: patientName ?? this.patientName,
      patientAge: patientAge ?? this.patientAge,
      patientGender: patientGender ?? this.patientGender,
      patientContact: patientContact ?? this.patientContact,
      description: description ?? this.description,
      attachments: attachments ?? this.attachments,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
