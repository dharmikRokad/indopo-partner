import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/lab_order_model.dart';
import 'package:dio/dio.dart';

class LabOrderRepository {
  final ApiClient _apiClient;

  LabOrderRepository(this._apiClient);

  /// Fetch all lab order dispatches assigned to this partner.
  Future<List<LabDispatchModel>> fetchLabOrders() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.labOrdersList);

      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data['data'];
        if (resData is List) {
          return resData
              .map((json) =>
                  LabDispatchModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('[LabOrderRepository] fetchLabOrders error: $e');
      rethrow;
    }
  }

  /// Accept a dispatched lab order by orderId.
  Future<String> acceptLabOrder(String orderId) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.acceptLabOrder(orderId),
      );

      if (response.statusCode == 200 && response.data != null) {
        final message = response.data['message']?.toString() ??
            'Order accepted successfully!';
        return message;
      }
      throw Exception('Failed to accept order.');
    } on DioException catch (e) {
      String errorMsg = 'Failed to accept order.';
      if (e.response?.data != null && e.response?.data is Map) {
        final resMap = e.response!.data as Map<String, dynamic>;
        if (resMap['message'] != null) {
          errorMsg = resMap['message'].toString();
        }
      } else if (e.message != null) {
        errorMsg = e.message!;
      }
      print('[LabOrderRepository] acceptLabOrder Dio error: $errorMsg');
      throw Exception(errorMsg);
    } catch (e) {
      print('[LabOrderRepository] acceptLabOrder error: $e');
      rethrow;
    }
  }
}
