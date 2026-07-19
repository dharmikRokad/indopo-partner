enum RequestStatus {
  newRequest,
  inProgress,
  completed,
}

extension RequestStatusExtension on RequestStatus {
  String get key {
    switch (this) {
      case RequestStatus.newRequest:
        return 'new';
      case RequestStatus.inProgress:
        return 'in_progress';
      case RequestStatus.completed:
        return 'completed';
    }
  }

  static RequestStatus fromKey(String key) {
    switch (key.toLowerCase()) {
      case 'new':
      case 'unread':
        return RequestStatus.newRequest;
      case 'in_progress':
      case 'accepted':
        return RequestStatus.inProgress;
      case 'completed':
      case 'done':
        return RequestStatus.completed;
      default:
        return RequestStatus.newRequest;
    }
  }
}

class RequestModel {
  final String id;
  final String patientName;
  final int patientAge;
  final String patientGender;
  final String patientContact;
  final String requestType; // Consultation, Test, Scan
  final String description;
  final List<String> attachments;
  final DateTime timestamp;
  final RequestStatus status;
  final String? rejectionReason;

  RequestModel({
    required this.id,
    required this.patientName,
    required this.patientAge,
    required this.patientGender,
    required this.patientContact,
    required this.requestType,
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
    return RequestModel(
      id: json['id'] as String? ?? '',
      patientName: json['patient_name'] as String? ?? 'Unknown Patient',
      patientAge: json['patient_age'] as int? ?? 0,
      patientGender: json['patient_gender'] as String? ?? 'Other',
      patientContact: json['patient_contact'] as String? ?? '',
      requestType: json['request_type'] as String? ?? 'Consultation',
      description: json['description'] as String? ?? '',
      attachments: List<String>.from(json['attachments'] ?? []),
      timestamp: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
      status: RequestStatusExtension.fromKey(json['status'] as String? ?? 'new'),
      rejectionReason: json['rejection_reason'] as String?,
    );
  }

  factory RequestModel.fromAppointmentJson(Map<String, dynamic> json) {
    final statusStr = (json['status'] as String? ?? 'PENDING').toUpperCase();
    RequestStatus mappedStatus;
    if (statusStr == 'PENDING') {
      mappedStatus = RequestStatus.newRequest;
    } else if (statusStr == 'CONFIRMED') {
      mappedStatus = RequestStatus.inProgress;
    } else {
      mappedStatus = RequestStatus.completed;
    }

    final serviceName = json['service']?['name'] as String? ?? json['location'] as String? ?? 'Consultation';

    return RequestModel(
      id: json['id'] as String? ?? '',
      patientName: json['patientName'] as String? ?? 'Unknown Patient',
      patientAge: json['patientAge'] as int? ?? 30,
      patientGender: json['patientGender'] as String? ?? 'Other',
      patientContact: json['patientPhone'] as String? ?? '',
      requestType: serviceName,
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
      'patient_name': patientName,
      'patient_age': patientAge,
      'patient_gender': patientGender,
      'patient_contact': patientContact,
      'request_type': requestType,
      'description': description,
      'attachments': attachments,
      'created_at': timestamp.toIso8601String(),
      'status': status.key,
      'rejection_reason': rejectionReason,
    };
  }

  RequestModel copyWith({
    String? id,
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
      patientName: patientName ?? this.patientName,
      patientAge: patientAge ?? this.patientAge,
      patientGender: patientGender ?? this.patientGender,
      patientContact: patientContact ?? this.patientContact,
      requestType: requestType ?? this.requestType,
      description: description ?? this.description,
      attachments: attachments ?? this.attachments,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
