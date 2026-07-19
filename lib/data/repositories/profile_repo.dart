import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/partner_model.dart';
import '../models/partner_type.dart';

class ProfileRepository {
  final ApiClient _apiClient;
  
  ProfileRepository(this._apiClient);

  Future<PartnerModel?> fetchProfile(String id) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.profile);
      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data['data'] as Map<String, dynamic>;
        return PartnerModel.fromApiJson(resData);
      }
    } catch (e) {
      print('[ProfileRepository] fetchProfile error: $e');
      rethrow;
    }
    return null;
  }

  Future<PartnerModel> saveProfile(PartnerModel partner) async {
    final details = partner.details;
    final role = partner.role;

    final Map<String, dynamic> body = {
      'name': details['full_name'] ?? details['lab_name'] ?? details['center_name'] ?? '',
      'phone': details['phone'] ?? '',
      'orgName': details['clinic_name'] ?? details['clinic_hospital_name'] ?? '',
      'orgAddress': details['address'] ?? '',
      'services': partner.services.map((e) => e.toJson()).toList(),
      'openTime': partner.openTime,
      'closeTime': partner.closeTime,
      'workingDays': partner.workingDays,
    };

    if (role == PartnerType.doctor) {
      body['doctorProfile'] = {
        'qualification': details['specialization'] ?? '',
        'licenseNumber': details['reg_number'] ?? '',
      };
    }

    try {
      final response = await _apiClient.patch(
        ApiEndpoints.profile,
        data: body,
      );

      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data['data'] as Map<String, dynamic>;
        final apiPartner = PartnerModel.fromApiJson(resData);

        // Merge local details with API partner details to prevent losing fields not supported by backend
        final mergedDetails = Map<String, dynamic>.from(partner.details)
          ..addAll(apiPartner.details);

        // Keep local services if the api response does not contain them
        final servicesToKeep = apiPartner.services.isNotEmpty 
            ? apiPartner.services 
            : partner.services;

        return apiPartner.copyWith(
          details: mergedDetails, 
          services: servicesToKeep,
          isProfileConfigured: true,
        );
      }
    } catch (e) {
      print('[ProfileRepository] saveProfile error: $e');
      rethrow;
    }
    return partner;
  }
}
