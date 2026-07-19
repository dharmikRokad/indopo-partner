import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../models/service_model.dart';
import '../models/partner_type.dart';

class ServiceRepository {
  final ApiClient _apiClient;
  static const String _localServicesKey = 'indopo_mock_services';

  ServiceRepository(this._apiClient);

  // Helper to check if API works or should fall back to local storage
  Future<List<ServiceModel>> fetchServices({required String partnerId, required PartnerType role}) async {
    try {
      // 1. Attempt API call
      final response = await _apiClient.get('/partners/services', queryParameters: {'partnerId': partnerId});
      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data['data'] as List? ?? [];
        return resData.map((e) => ServiceModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      print('[ServiceRepository] fetchServices API error (falling back to mock): $e');
    }

    // 2. Fallback to Local SharedPreferences Mock Storage
    return await _getLocalServices(partnerId, role);
  }

  Future<ServiceModel> addService(ServiceModel service) async {
    try {
      // 1. Attempt API call
      final response = await _apiClient.post('/partners/services', data: service.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null && response.data['data'] != null) {
          return ServiceModel.fromJson(response.data['data'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      print('[ServiceRepository] addService API error (falling back to mock): $e');
    }

    // 2. Fallback to Local Storage
    final services = await _getLocalServicesRaw();
    services.add(service);
    await _saveLocalServicesRaw(services);
    return service;
  }

  Future<ServiceModel> editService(ServiceModel service) async {
    try {
      // 1. Attempt API call
      final response = await _apiClient.put('/partners/services/${service.id}', data: service.toJson());
      if (response.statusCode == 200 && response.data != null) {
        if (response.data['data'] != null) {
          return ServiceModel.fromJson(response.data['data'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      print('[ServiceRepository] editService API error (falling back to mock): $e');
    }

    // 2. Fallback to Local Storage
    final services = await _getLocalServicesRaw();
    final index = services.indexWhere((element) => element.id == service.id);
    if (index != -1) {
      services[index] = service;
      await _saveLocalServicesRaw(services);
    }
    return service;
  }

  Future<void> deleteService(String id) async {
    try {
      // 1. Attempt API call
      final response = await _apiClient.delete('/partners/services/$id');
      if (response.statusCode == 200) {
        return;
      }
    } catch (e) {
      print('[ServiceRepository] deleteService API error (falling back to mock): $e');
    }

    // 2. Fallback to Local Storage
    final services = await _getLocalServicesRaw();
    services.removeWhere((element) => element.id == id);
    await _saveLocalServicesRaw(services);
  }

  Future<ServiceModel> toggleAvailability(String id, bool isAvailable) async {
    try {
      // 1. Attempt API call
      final response = await _apiClient.patch('/partners/services/$id/availability', data: {'isAvailable': isAvailable});
      if (response.statusCode == 200 && response.data != null) {
        if (response.data['data'] != null) {
          return ServiceModel.fromJson(response.data['data'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      print('[ServiceRepository] toggleAvailability API error (falling back to mock): $e');
    }

    // 2. Fallback to Local Storage
    final services = await _getLocalServicesRaw();
    final index = services.indexWhere((element) => element.id == id);
    if (index != -1) {
      final updated = services[index].copyWith(isAvailable: isAvailable);
      services[index] = updated;
      await _saveLocalServicesRaw(services);
      return updated;
    }
    throw Exception('Service not found for availability toggle');
  }

  // --- Mock Storage Helpers ---

  Future<List<ServiceModel>> _getLocalServices(String partnerId, PartnerType role) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_localServicesKey);
    
    if (jsonStr == null || jsonStr.isEmpty) {
      // Prepopulate mock data
      final List<ServiceModel> initialData = _generateMockServices(partnerId, role);
      await _saveLocalServicesRaw(initialData);
      return initialData;
    }

    try {
      final List<dynamic> decoded = jsonDecode(jsonStr) as List;
      final allServices = decoded.map((e) => ServiceModel.fromJson(e as Map<String, dynamic>)).toList();
      // Filter by current partnerId
      final partnerServices = allServices.where((element) => element.partnerId == partnerId).toList();
      
      // If this partner doesn't have any services yet, prepopulate them
      if (partnerServices.isEmpty) {
        final List<ServiceModel> initialData = _generateMockServices(partnerId, role);
        allServices.addAll(initialData);
        await _saveLocalServicesRaw(allServices);
        return initialData;
      }
      
      return partnerServices;
    } catch (e) {
      print('[ServiceRepository] Error parsing local mock services: $e');
      return _generateMockServices(partnerId, role);
    }
  }

  Future<List<ServiceModel>> _getLocalServicesRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_localServicesKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr) as List;
      return decoded.map((e) => ServiceModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveLocalServicesRaw(List<ServiceModel> services) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(services.map((e) => e.toJson()).toList());
    await prefs.setString(_localServicesKey, jsonStr);
  }

  List<ServiceModel> _generateMockServices(String partnerId, PartnerType role) {
    final now = DateTime.now().toIso8601String();
    if (role == PartnerType.imagingCenter) {
      return [
        ServiceModel(
          id: '89b40cc6-19cd-4db9-aca8-9ea2a71dff75',
          partnerId: partnerId,
          name: 'Whole Body PET Scan',
          category: 'PET Scan',
          description: 'Positron Emission Tomography scan',
          price: '800',
          isAvailable: true,
          createdAt: now,
        ),
        ServiceModel(
          id: 'mock-img-2',
          partnerId: partnerId,
          name: 'Chest X-Ray PA View',
          category: 'X-Ray',
          description: 'Standard chest radiography examination',
          price: '150',
          isAvailable: true,
          createdAt: now,
        ),
        ServiceModel(
          id: 'mock-img-3',
          partnerId: partnerId,
          name: 'Brain MRI Contrast',
          category: 'MRI',
          description: 'Magnetic Resonance Imaging of the brain with contrast agent',
          price: '600',
          isAvailable: false,
          createdAt: now,
        ),
      ];
    } else if (role == PartnerType.laboratory) {
      return [
        ServiceModel(
          id: 'mock-lab-1',
          partnerId: partnerId,
          name: 'Complete Blood Count (CBC)',
          category: 'Blood Test',
          description: 'Analyzes red blood cells, white blood cells, and platelets',
          price: '45',
          isAvailable: true,
          createdAt: now,
        ),
        ServiceModel(
          id: 'mock-lab-2',
          partnerId: partnerId,
          name: 'HbA1c Glycated Hemoglobin',
          category: 'Pathology',
          description: 'Measures average blood sugar levels over the past 3 months',
          price: '35',
          isAvailable: true,
          createdAt: now,
        ),
        ServiceModel(
          id: 'mock-lab-3',
          partnerId: partnerId,
          name: 'Thyroid Profile (T3, T4, TSH)',
          category: 'Biochemistry',
          description: 'Thyroid function test profile panel',
          price: '70',
          isAvailable: false,
          createdAt: now,
        ),
      ];
    }
    return [];
  }
}
