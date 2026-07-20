import 'partner_type.dart';
import 'service_model.dart';

class PartnerModel {
  final String id;
  final String email;
  final PartnerType role;
  final bool isProfileConfigured;
  final Map<String, dynamic> details;
  final List<ServiceModel> services;
  final String? openTime;
  final String? closeTime;
  final List<String>? workingDays;
  final double? lat;
  final double? long;
  final String? orgAddress;

  PartnerModel({
    required this.id,
    required this.email,
    required this.role,
    required this.isProfileConfigured,
    this.details = const {},
    this.services = const [],
    this.openTime,
    this.closeTime,
    this.workingDays,
    this.lat,
    this.long,
    this.orgAddress,
  });

  factory PartnerModel.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('partner')) {
      return PartnerModel.fromApiJson(json['partner'] as Map<String, dynamic>);
    }

    final details = json['details'] as Map<String, dynamic>? ?? const {};
    final orgAddressStr =
        json['orgAddress'] as String? ?? details['address'] as String? ?? '';

    return PartnerModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: PartnerTypeExtension.fromKey(json['role'] as String? ?? 'doctor'),
      isProfileConfigured: json['is_profile_configured'] as bool? ?? false,
      details: details,
      services: (json['services'] as List? ?? [])
          .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      openTime: json['openTime'] as String?,
      closeTime: json['closeTime'] as String?,
      workingDays: _normalizeWorkingDays(
        (json['workingDays'] as List?)?.map((e) => e.toString()).toList(),
      ),
      lat: (json['lat'] as num?)?.toDouble(),
      long: (json['long'] as num?)?.toDouble(),
      orgAddress: orgAddressStr,
    );
  }

  factory PartnerModel.fromApiJson(Map<String, dynamic> json) {
    final role = PartnerTypeExtension.fromKey(
      json['partnerType'] as String? ?? json['role'] as String? ?? 'doctor',
    );

    final orgAddressStr = json['orgAddress'] as String? ?? '';

    final details = <String, dynamic>{
      'phone': json['phone'] ?? '',
      'address': orgAddressStr,
    };

    final name = json['name'] as String? ?? '';
    final orgName = json['orgName'] as String? ?? '';

    if (role == PartnerType.doctor) {
      details['full_name'] = name;
      details['clinic_name'] = orgName;
      final docProfile = json['doctorProfile'] as Map<String, dynamic>?;
      if (docProfile != null) {
        details['specialization'] =
            docProfile['specialization'] ??
            docProfile['speciality']?['name'] ??
            '';
        details['reg_number'] = docProfile['licenseNumber'] ?? '';
        details['consultation_fee'] = docProfile['consultationFee'] is String
            ? double.parse(docProfile['consultationFee'] ?? '0')
            : (docProfile['consultationFee'] as num?)?.toDouble() ?? 0.0;
      }
    } else if (role == PartnerType.medical) {
      details['full_name'] = name;
      details['clinic_hospital_name'] = orgName;
    } else if (role == PartnerType.laboratory) {
      details['lab_name'] = name;
      details['contact_person'] = json['contactPerson'] ?? '';
      final docProfile = json['doctorProfile'] as Map<String, dynamic>?;
      if (docProfile != null) {
        details['accreditation_number'] = docProfile['licenseNumber'] ?? '';
      }
    } else if (role == PartnerType.imagingCenter) {
      details['center_name'] = name;
      final docProfile = json['doctorProfile'] as Map<String, dynamic>?;
      if (docProfile != null) {
        details['accreditation_number'] = docProfile['licenseNumber'] ?? '';
      }
    }

    final isConfigured =
        name.isNotEmpty && (json['phone'] as String? ?? '').isNotEmpty;

    final servicesRaw =
        json['services'] as List? ??
        json['doctorProfile']?['services'] as List? ??
        [];
    final services = servicesRaw
        .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return PartnerModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: role,
      isProfileConfigured: isConfigured,
      details: details,
      services: services,
      openTime: json['openTime'] as String?,
      closeTime: json['closeTime'] as String?,
      workingDays: _normalizeWorkingDays(
        (json['workingDays'] as List?)?.map((e) => e.toString()).toList(),
      ),
      lat: json['lat'] is String
          ? double.parse(json['lat'] ?? '0')
          : (json['lat'] as num?)?.toDouble(),
      long: json['long'] is String
          ? double.parse(json['long'] ?? '0')
          : (json['long'] as num?)?.toDouble(),
      orgAddress: orgAddressStr,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role.key,
      'is_profile_configured': isProfileConfigured,
      'details': details,
      'services': services.map((e) => e.toJson()).toList(),
      'openTime': openTime,
      'closeTime': closeTime,
      'workingDays': workingDays,
      'lat': lat,
      'long': long,
      'orgAddress': orgAddress,
    };
  }

  PartnerModel copyWith({
    String? id,
    String? email,
    PartnerType? role,
    bool? isProfileConfigured,
    Map<String, dynamic>? details,
    List<ServiceModel>? services,
    String? openTime,
    String? closeTime,
    List<String>? workingDays,
    double? lat,
    double? long,
    String? orgAddress,
  }) {
    return PartnerModel(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      isProfileConfigured: isProfileConfigured ?? this.isProfileConfigured,
      details: details ?? this.details,
      services: services ?? this.services,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      workingDays: workingDays ?? this.workingDays,
      lat: lat ?? this.lat,
      long: long ?? this.long,
      orgAddress: orgAddress ?? this.orgAddress,
    );
  }

  static List<String>? _normalizeWorkingDays(List<String>? days) {
    if (days == null) return null;
    return days
        .map((day) {
          final clean = day.trim().toUpperCase();
          switch (clean) {
            case 'MONDAY':
              return 'MON';
            case 'TUESDAY':
              return 'TUE';
            case 'WEDNESDAY':
              return 'WED';
            case 'THURSDAY':
              return 'THU';
            case 'FRIDAY':
              return 'FRI';
            case 'SATURDAY':
              return 'SAT';
            case 'SUNDAY':
              return 'SUN';
            default:
              return clean;
          }
        })
        .toSet()
        .toList();
  }
}
