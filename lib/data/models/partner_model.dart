import 'day_schedule_model.dart';
import 'partner_type.dart';
import 'service_model.dart';

class PartnerModel {
  final String id;
  final String email;
  final PartnerType role;
  final bool isProfileConfigured;
  final Map<String, dynamic> details;
  final List<ServiceModel> services;
  final Map<String, DaySchedule>? weeklySchedule;
  final double? lat;
  final double? long;
  final String? orgAddress;
  final String? profilePicture;
  final bool isAvailable;
  final bool isActive;

  String get name =>
      details['full_name'] as String? ??
      details['org_name'] as String? ??
      details['lab_name'] as String? ??
      details['center_name'] as String? ??
      email;

  bool get hasSchedule =>
      (weeklySchedule != null && weeklySchedule!.isNotEmpty);

  PartnerModel({
    required this.id,
    required this.email,
    required this.role,
    required this.isProfileConfigured,
    this.details = const {},
    this.services = const [],
    this.weeklySchedule,
    this.lat,
    this.long,
    this.orgAddress,
    this.profilePicture,
    this.isAvailable = true,
    this.isActive = true,
  });

  factory PartnerModel.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('partner')) {
      return PartnerModel.fromApiJson(json['partner'] as Map<String, dynamic>);
    }

    final details = json['details'] as Map<String, dynamic>? ?? const {};
    final orgAddressStr =
        json['orgAddress'] as String? ?? details['address'] as String? ?? '';
    final profilePic =
        json['profilePicture'] as String? ??
        json['profile_picture'] as String? ??
        json['avatar'] as String? ??
        details['profile_picture'] as String? ??
        details['profilePicture'] as String?;

    final rawWeeklySchedule =
        json['weeklySchedule'] ??
        json['weekly_schedule'] ??
        details['weeklySchedule'] ??
        details['weekly_schedule'];

    final parsedWeeklySchedule = _parseWeeklySchedule(rawWeeklySchedule);

    return PartnerModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: PartnerTypeExtension.fromKey(json['role'] as String? ?? 'doctor'),
      isProfileConfigured: json['is_profile_configured'] as bool? ?? false,
      details: details,
      services: (json['services'] as List? ?? [])
          .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      weeklySchedule: parsedWeeklySchedule,
      lat: (json['lat'] as num?)?.toDouble(),
      long: (json['long'] as num?)?.toDouble(),
      orgAddress: orgAddressStr,
      profilePicture: profilePic,
      isAvailable:
          json['isAvailable'] as bool? ?? json['is_available'] as bool? ?? true,
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
    );
  }

  factory PartnerModel.fromApiJson(Map<String, dynamic> json) {
    final role = PartnerTypeExtension.fromKey(
      json['partnerType'] as String? ?? json['role'] as String? ?? 'doctor',
    );

    final orgAddressStr = json['orgAddress'] as String? ?? '';

    final name = json['name'] as String? ?? '';
    final orgName = json['orgName'] as String? ?? '';

    final details = <String, dynamic>{
      'phone': json['phone'] ?? '',
      'address': orgAddressStr,
      'org_name': orgName,
    };

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
            ? double.parse(docProfile['consultationFee'])
            : (docProfile['consultationFee'] as num?)?.toDouble() ?? 0.0;
      }
    } else if (role == PartnerType.pharmacy) {
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

    final profilePic =
        json['profilePicture'] as String? ??
        json['profile_picture'] as String? ??
        json['avatar'] as String? ??
        json['doctorProfile']?['profilePicture'] as String?;

    final rawWeeklySchedule =
        json['weeklySchedule'] ??
        json['weekly_schedule'] ??
        (json['doctorProfile'] is Map
            ? (json['doctorProfile']['weeklySchedule'] ??
                json['doctorProfile']['weekly_schedule'])
            : null) ??
        (json['details'] is Map
            ? (json['details']['weeklySchedule'] ??
                json['details']['weekly_schedule'])
            : null);

    final parsedWeeklySchedule = _parseWeeklySchedule(rawWeeklySchedule);

    return PartnerModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: role,
      isProfileConfigured: isConfigured,
      details: details,
      services: services,
      weeklySchedule: parsedWeeklySchedule,
      lat: json['lat'] is String
          ? double.parse(json['lat'])
          : (json['lat'] as num?)?.toDouble(),
      long: json['long'] is String
          ? double.parse(json['long'])
          : (json['long'] as num?)?.toDouble(),
      orgAddress: orgAddressStr,
      profilePicture: profilePic,
      isAvailable:
          json['isAvailable'] as bool? ?? json['is_active'] as bool? ?? true,
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
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
      'weeklySchedule': weeklySchedule?.map((k, v) => MapEntry(k, v.toJson())),
      'lat': lat,
      'long': long,
      'orgAddress': orgAddress,
      'profilePicture': profilePicture,
      'isAvailable': isAvailable,
      'isActive': isActive,
    };
  }

  PartnerModel copyWith({
    String? id,
    String? email,
    PartnerType? role,
    bool? isProfileConfigured,
    Map<String, dynamic>? details,
    List<ServiceModel>? services,
    Map<String, DaySchedule>? weeklySchedule,
    double? lat,
    double? long,
    String? orgAddress,
    String? profilePicture,
    bool? isAvailable,
    bool? isActive,
  }) {
    return PartnerModel(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      isProfileConfigured: isProfileConfigured ?? this.isProfileConfigured,
      details: details ?? this.details,
      services: services ?? this.services,
      weeklySchedule: weeklySchedule ?? this.weeklySchedule,
      lat: lat ?? this.lat,
      long: long ?? this.long,
      orgAddress: orgAddress ?? this.orgAddress,
      profilePicture: profilePicture ?? this.profilePicture,
      isAvailable: isAvailable ?? this.isAvailable,
      isActive: isActive ?? this.isActive,
    );
  }

  static Map<String, DaySchedule>? _parseWeeklySchedule(dynamic rawSchedule) {
    if (rawSchedule is Map && rawSchedule.isNotEmpty) {
      final schedule = <String, DaySchedule>{};
      rawSchedule.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          final normalizedKey = normalizeDayName(key.toString());
          schedule[normalizedKey] = DaySchedule.fromJson(value);
        } else if (value is Map) {
          final normalizedKey = normalizeDayName(key.toString());
          schedule[normalizedKey] = DaySchedule.fromJson(
            Map<String, dynamic>.from(value),
          );
        }
      });
      if (schedule.isNotEmpty) return schedule;
    }
    return null;
  }
}
