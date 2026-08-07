import 'request_model.dart';

enum NotificationType {
  appointmentReminder('APPOINTMENT_REMINDER'),
  appointmentConfirmed('APPOINTMENT_CONFIRMED'),
  appointmentCancelled('APPOINTMENT_CANCELLED'),
  reviewRequest('REVIEW_REQUEST'),
  prescriptionInquiry('PRESCRIPTION_INQUIRY'),
  general('GENERAL');

  final String value;
  const NotificationType(this.value);

  static NotificationType fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'APPOINTMENT_REMINDER':
        return NotificationType.appointmentReminder;
      case 'APPOINTMENT_CONFIRMED':
        return NotificationType.appointmentConfirmed;
      case 'APPOINTMENT_CANCELLED':
        return NotificationType.appointmentCancelled;
      case 'REVIEW_REQUEST':
        return NotificationType.reviewRequest;
      case 'PRESCRIPTION_INQUIRY':
        return NotificationType.prescriptionInquiry;
      case 'GENERAL':
      default:
        return NotificationType.general;
    }
  }
}

class NotificationPartnerInfo {
  final String id;
  final String name;
  final String orgName;
  final String partnerType;
  final String orgAddress;

  NotificationPartnerInfo({
    required this.id,
    required this.name,
    required this.orgName,
    required this.partnerType,
    required this.orgAddress,
  });

  factory NotificationPartnerInfo.fromJson(Map<String, dynamic> json) {
    return NotificationPartnerInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      orgName: json['orgName'] as String? ?? '',
      partnerType: json['partnerType'] as String? ?? '',
      orgAddress: json['orgAddress'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'orgName': orgName,
      'partnerType': partnerType,
      'orgAddress': orgAddress,
    };
  }
}

class NotificationPatientInfo {
  final String id;
  final String firstName;
  final String lastName;
  final String email;

  NotificationPatientInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory NotificationPatientInfo.fromJson(Map<String, dynamic> json) {
    return NotificationPatientInfo(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
    };
  }
}

class NotificationModel {
  final String id;
  final String patientId;
  final String? partnerId;
  final NotificationType type;
  final String message;
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final DateTime createdAt;
  final NotificationPartnerInfo? partner;
  final NotificationPatientInfo? patient;

  NotificationModel({
    required this.id,
    required this.patientId,
    this.partnerId,
    required this.type,
    required this.message,
    this.metadata,
    required this.isRead,
    required this.createdAt,
    this.partner,
    this.patient,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      patientId: json['patientId'] as String? ?? '',
      partnerId: json['partnerId'] as String?,
      type: NotificationType.fromString(json['type'] as String?),
      message: json['message'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      partner: json['partner'] != null
          ? NotificationPartnerInfo.fromJson(
              json['partner'] as Map<String, dynamic>,
            )
          : null,
      patient: json['patient'] != null
          ? NotificationPatientInfo.fromJson(
              json['patient'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'partnerId': partnerId,
      'type': type.value,
      'message': message,
      'metadata': metadata,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'partner': partner?.toJson(),
      'patient': patient?.toJson(),
    };
  }

  RequestModel toRequestModel() {
    final inquiryId =
        metadata?['prescriptionInquiryId']?.toString() ??
        metadata?['appointmentId']?.toString() ??
        id;

    final pId = patientId.isNotEmpty
        ? patientId
        : (patient?.id.isNotEmpty == true
              ? patient!.id
              : (metadata?['patientId']?.toString() ?? ''));

    final pName = patient?.fullName.isNotEmpty == true
        ? patient!.fullName
        : (metadata?['patientName']?.toString() ?? 'Unknown Patient');

    final reqStatus = isRead
        ? RequestStatus.inProgress
        : RequestStatus.newRequest;

    List<String> attachmentList = [];
    if (metadata?['attachments'] is List) {
      attachmentList = (metadata!['attachments'] as List)
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (metadata?['prescriptionUrl'] != null &&
        metadata!['prescriptionUrl'].toString().isNotEmpty) {
      attachmentList = [metadata!['prescriptionUrl'].toString()];
    }

    final String? prescriptionNotes =
        metadata?['notes'] ?? metadata?['description'];

    final tokenNo =
        metadata?['tokenNumber']?.toString() ??
        metadata?['token_number']?.toString() ??
        metadata?['token']?.toString();

    return RequestModel(
      id: inquiryId,
      patientId: pId.isNotEmpty ? pId : null,
      notificationId: id,
      chatId: metadata?['chatId']?.toString(),
      tokenNumber: tokenNo,
      patientName: pName,
      patientAge: (metadata?['patientAge'] is int)
          ? metadata!['patientAge'] as int
          : 30,
      patientProfilePicture: metadata?['patientPhotoUrl']?.toString() ?? '',
      patientGender: metadata?['patientGender']?.toString() ?? 'Other',
      patientContact:
          patient?.email ?? metadata?['patientPhone']?.toString() ?? '',
      description: prescriptionNotes ?? message,
      attachments: attachmentList,
      timestamp: createdAt,
      status: reqStatus,
    );
  }
}

class NotificationResponse {
  final List<NotificationModel> notifications;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPrevPage;
  final int unreadCount;

  NotificationResponse({
    required this.notifications,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPrevPage,
    required this.unreadCount,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['notifications'] as List? ?? [];
    final notificationList = rawList
        .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
        .toList();
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};

    return NotificationResponse(
      notifications: notificationList,
      total: pagination['total'] as int? ?? 0,
      page: pagination['page'] as int? ?? 1,
      limit: pagination['limit'] as int? ?? 20,
      totalPages: pagination['totalPages'] as int? ?? 1,
      hasNextPage: pagination['hasNextPage'] as bool? ?? false,
      hasPrevPage: pagination['hasPrevPage'] as bool? ?? false,
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }
}
