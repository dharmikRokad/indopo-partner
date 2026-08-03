import '../../core/network/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/appointment_model.dart';
import '../models/notification_model.dart';
import '../models/request_model.dart';

class RequestRepository {
  final ApiClient _apiClient;

  RequestRepository(this._apiClient);

  Future<List<RequestModel>> fetchRequests(
    RequestStatus status, {
    bool isMedical = false,
  }) async {
    if (isMedical) {
      return fetchPrescriptionInquiries(status: status);
    }

    try {
      final response = await _apiClient.get(
        ApiEndpoints.appointmentsList,
        queryParameters: {'status': status.apiKey},
      );

      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data['data'] as Map<String, dynamic>;
        final list = resData['appointments'] as List? ?? [];
        return list
            .map((json) => RequestModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('[RequestRepository] fetchRequests error: $e');
      rethrow;
    }
    return [];
  }

  Future<List<RequestModel>> fetchPrescriptionInquiries({
    RequestStatus status = RequestStatus.newRequest,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'type': 'PRESCRIPTION_INQUIRY',
        'page': page,
        'limit': limit,
        'sortBy': 'createdAt',
        'sortOrder': 'desc',
      };

      if (status == RequestStatus.newRequest) {
        queryParams['isRead'] = false;
      } else if (status == RequestStatus.inProgress ||
          status == RequestStatus.completed) {
        queryParams['isRead'] = true;
      }

      final response = await _apiClient.get(
        ApiEndpoints.notificationsList,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data['data'] as Map<String, dynamic>;
        final notificationResp = NotificationResponse.fromJson(resData);
        return notificationResp.notifications
            .map((notif) => notif.toRequestModel())
            .toList();
      }
    } catch (e) {
      print('[RequestRepository] fetchPrescriptionInquiries error: $e');
      rethrow;
    }
    return [];
  }

  Future<NotificationModel?> markNotificationAsRead(
    String notificationId,
  ) async {
    try {
      final response = await _apiClient.patch(
        ApiEndpoints.notificationRead(notificationId),
      );

      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data['data'] as Map<String, dynamic>;
        return NotificationModel.fromJson(resData);
      }
    } catch (e) {
      print('[RequestRepository] markNotificationAsRead error: $e');
    }
    return null;
  }

  Future<RequestModel> fetchRequestById(String id) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.appointmentDetail(id));
      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data['data'] as Map<String, dynamic>;
        return RequestModel.fromJson(resData);
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
    try {
      final response = await _apiClient.patch(
        ApiEndpoints.appointmentStatus(id),
        data: {'status': status.apiKey},
      );

      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data['data'] as Map<String, dynamic>;
        return RequestModel.fromJson(resData);
      }
    } catch (e) {
      print('[RequestRepository] updateRequestStatus error: $e');
      rethrow;
    }
    throw Exception('Failed to update status');
  }

  Future<AppointmentModel> assignAppointment(
    AppointmentModel appointment,
  ) async {
    final dateStr =
        "${appointment.date.year}-${appointment.date.month.toString().padLeft(2, '0')}-${appointment.date.day.toString().padLeft(2, '0')}";
    final body = {
      'appointmentDate': dateStr,
      'appointmentTime': appointment.time,
    };

    try {
      final response = await _apiClient.post(
        ApiEndpoints.appointmentConfirm(appointment.requestId),
        data: body,
      );

      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data['data'] as Map<String, dynamic>;
        return AppointmentModel(
          id: resData['id']?.toString() ?? appointment.id,
          requestId: appointment.requestId,
          appointmentNumber:
              resData['tokenNumber']?.toString() ??
              appointment.appointmentNumber,
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
