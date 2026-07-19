import '../../core/network/api_client.dart';
import '../models/appointment_model.dart';
import '../models/request_model.dart';

class RequestRepository {
  final ApiClient _apiClient;

  RequestRepository(this._apiClient);

  Future<List<RequestModel>> fetchRequests(RequestStatus status) async {
    String apiStatus = 'PENDING';
    if (status == RequestStatus.inProgress) {
      apiStatus = 'CONFIRMED';
    } else if (status == RequestStatus.completed) {
      apiStatus = 'COMPLETED';
    }

    try {
      final response = await _apiClient.get(
        '/appointments/partner/list',
        queryParameters: {'status': apiStatus},
      );

      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data['data'] as Map<String, dynamic>;
        final list = resData['appointments'] as List? ?? [];
        return list.map((json) => RequestModel.fromAppointmentJson(json as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      print('[RequestRepository] fetchRequests error: $e');
      rethrow;
    }
    return [];
  }

  Future<RequestModel> fetchRequestById(String id) async {
    try {
      final response = await _apiClient.get('/appointments/partner/list');
      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data['data'] as Map<String, dynamic>;
        final list = resData['appointments'] as List? ?? [];
        final match = list.firstWhere(
          (json) => json['id'] == id,
          orElse: () => null,
        );
        if (match != null) {
          return RequestModel.fromAppointmentJson(match as Map<String, dynamic>);
        }
      }
    } catch (e) {
      print('[RequestRepository] fetchRequestById error: $e');
      rethrow;
    }
    throw Exception('Request not found');
  }

  Future<RequestModel> updateRequestStatus(
    String id, 
    RequestStatus status, {
    String? rejectionReason,
  }) async {
    String apiStatus = 'CONFIRMED';
    if (status == RequestStatus.completed) {
      apiStatus = rejectionReason != null ? 'CANCELLED' : 'COMPLETED';
    }

    try {
      final response = await _apiClient.patch(
        '/appointments/$id/status',
        data: {'status': apiStatus},
      );

      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data['data'] as Map<String, dynamic>;
        return RequestModel.fromAppointmentJson(resData);
      }
    } catch (e) {
      print('[RequestRepository] updateRequestStatus error: $e');
      rethrow;
    }
    throw Exception('Failed to update status');
  }

  Future<AppointmentModel> assignAppointment(AppointmentModel appointment) async {
    final dateStr = "${appointment.date.year}-${appointment.date.month.toString().padLeft(2, '0')}-${appointment.date.day.toString().padLeft(2, '0')}";
    final body = {
      'appointmentDate': dateStr,
      'appointmentTime': appointment.time,
    };

    try {
      final response = await _apiClient.post(
        '/appointments/partner/${appointment.requestId}/confirm',
        data: body,
      );

      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data['data'] as Map<String, dynamic>;
        return AppointmentModel(
          id: resData['id']?.toString() ?? appointment.id,
          requestId: appointment.requestId,
          appointmentNumber: resData['tokenNumber']?.toString() ?? appointment.appointmentNumber,
          date: appointment.date,
          time: appointment.time,
          notes: appointment.notes,
        );
      }
    } catch (e) {
      print('[RequestRepository] assignAppointment error: $e');
      rethrow;
    }
    throw Exception('Failed to confirm appointment');
  }
}
