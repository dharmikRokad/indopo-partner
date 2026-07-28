import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/partner_model.dart';
import '../models/partner_type.dart';

class ProfileRepository {
  final ApiClient _apiClient;
  final Dio _nominatimDio;

  ProfileRepository(this._apiClient) : _nominatimDio = Dio() {
    _nominatimDio.options.headers = {
      'User-Agent': 'IndopoPartnerApp/1.0.0 (contact@indopo.com)',
    };
    _nominatimDio.options.connectTimeout = const Duration(seconds: 10);
    _nominatimDio.options.receiveTimeout = const Duration(seconds: 10);
  }

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

  Future<PartnerModel> saveProfile(
    PartnerModel partner, {
    File? profilePictureFile,
  }) async {
    final details = partner.details;
    final role = partner.role;

    final Map<String, dynamic> body = {
      'name':
          details['full_name'] ??
          details['lab_name'] ??
          details['center_name'] ??
          '',
      'phone': details['phone'] ?? '',
      'orgName': details['org_name'] ?? details['clinic_name'] ?? details['clinic_hospital_name'] ?? '',
      'orgAddress': partner.orgAddress ?? details['address'] ?? '',
      'services': partner.services.map((e) => e.toJson()).toList(),
      'openTime': partner.openTime,
      'closeTime': partner.closeTime,
      'workingDays': partner.workingDays,
      'lat': partner.lat,
      'long': partner.long,
    };

    if (role == PartnerType.doctor) {
      body['doctorProfile'] = {
        'qualification': details['specialization'] ?? '',
        'licenseNumber': details['reg_number'] ?? '',
        'consultationFee': details['consultation_fee'] ?? 0.0,
      };
    }

    try {
      final Response response;
      if (profilePictureFile != null) {
        final fileName = profilePictureFile.path.split(RegExp(r'[/\\]')).last;
        final formDataMap = Map<String, dynamic>.from(body);
        formDataMap['profilePicture'] = await MultipartFile.fromFile(
          profilePictureFile.path,
          filename: fileName,
        );
        final formData = FormData.fromMap(formDataMap);
        response = await _apiClient.patch(ApiEndpoints.profile, data: formData);
      } else {
        response = await _apiClient.patch(ApiEndpoints.profile, data: body);
      }

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
          lat: apiPartner.lat ?? partner.lat,
          long: apiPartner.long ?? partner.long,
          orgAddress: apiPartner.orgAddress ?? partner.orgAddress,
          profilePicture: apiPartner.profilePicture ?? partner.profilePicture,
        );
      }
    } catch (e) {
      print('[ProfileRepository] saveProfile error: $e');
      rethrow;
    }
    return partner;
  }

  Future<List<Map<String, dynamic>>> getAddressSuggestions(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final response = await _nominatimDio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {'q': query, 'format': 'json', 'limit': 5},
      );
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list.map((item) {
          final map = item as Map<String, dynamic>;
          return {
            'display_name': map['display_name'] ?? '',
            'lat': double.tryParse(map['lat']?.toString() ?? '') ?? 0.0,
            'lon': double.tryParse(map['lon']?.toString() ?? '') ?? 0.0,
          };
        }).toList();
      }
    } catch (e) {
      print('[ProfileRepository] getAddressSuggestions error: $e');
    }
    return [];
  }

  Future<String?> getAddressFromCoordinates(double lat, double lon) async {
    try {
      final response = await _nominatimDio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {'lat': lat, 'lon': lon, 'format': 'json'},
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data['display_name'] as String?;
      }
    } catch (e) {
      print('[ProfileRepository] getAddressFromCoordinates error: $e');
    }
    return null;
  }
}
