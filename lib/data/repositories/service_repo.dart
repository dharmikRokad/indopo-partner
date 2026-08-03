import '../../core/network/api_client.dart';
import '../models/service_model.dart';

class ServiceRepository {
  final ApiClient _apiClient;

  ServiceRepository(this._apiClient);

  /// Retrieves all services belonging to the authenticated partner
  Future<List<ServiceModel>> fetchServices() async {
    try {
      final response = await _apiClient.get('/partner-auth/services');
      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data['data'] as List? ?? [];
        return resData
            .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('[ServiceRepository] fetchServices API error: $e');
      rethrow;
    }
    return [];
  }

  /// Creates a new service for the authenticated partner
  Future<ServiceModel> addService(ServiceModel service) async {
    try {
      final Map<String, dynamic> body = {
        'name': service.name,
        'category': service.category,
        if (service.description.isNotEmpty) 'description': service.description,
        'price': double.tryParse(service.price) ?? 0.0,
        'isAvailable': service.isAvailable,
      };

      final response = await _apiClient.post(
        '/partner-auth/services',
        data: body,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null && response.data['data'] != null) {
          return ServiceModel.fromJson(
            response.data['data'] as Map<String, dynamic>,
          );
        }
      }
      throw Exception('Failed to create service');
    } catch (e) {
      print('[ServiceRepository] addService API error: $e');
      rethrow;
    }
  }

  /// Partially updates an existing service on the server
  Future<ServiceModel> editService(ServiceModel service) async {
    try {
      final Map<String, dynamic> body = {
        'name': service.name,
        'category': service.category,
        'description': service.description,
        'price': double.tryParse(service.price) ?? 0.0,
        'isAvailable': service.isAvailable,
      };

      final response = await _apiClient.patch(
        '/partner-auth/services/${service.id}',
        data: body,
      );
      if (response.statusCode == 200 && response.data != null) {
        if (response.data['data'] != null) {
          return ServiceModel.fromJson(
            response.data['data'] as Map<String, dynamic>,
          );
        }
      }
      throw Exception('Failed to update service');
    } catch (e) {
      print('[ServiceRepository] editService API error: $e');
      rethrow;
    }
  }

  /// Permanently deletes a service
  Future<void> deleteService(String id) async {
    try {
      final response = await _apiClient.delete('/partner-auth/services/$id');
      if (response.statusCode == 200) {
        return;
      }
      throw Exception('Failed to delete service');
    } catch (e) {
      print('[ServiceRepository] deleteService API error: $e');
      rethrow;
    }
  }

  /// Toggles service availability using the partial update PATCH endpoint
  Future<ServiceModel> toggleAvailability(String id, bool isAvailable) async {
    try {
      final Map<String, dynamic> body = {'isAvailable': isAvailable};

      final response = await _apiClient.patch(
        '/partner-auth/services/$id',
        data: body,
      );
      if (response.statusCode == 200 && response.data != null) {
        if (response.data['data'] != null) {
          return ServiceModel.fromJson(
            response.data['data'] as Map<String, dynamic>,
          );
        }
      }
      throw Exception('Failed to toggle availability');
    } catch (e) {
      print('[ServiceRepository] toggleAvailability API error: $e');
      rethrow;
    }
  }
}
