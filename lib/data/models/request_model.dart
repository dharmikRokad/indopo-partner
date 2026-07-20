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

    return RequestModel(
      id: json['id'] as String? ?? '',
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
      description: description ?? this.description,
      attachments: attachments ?? this.attachments,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
