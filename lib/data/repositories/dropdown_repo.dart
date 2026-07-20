import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/partner_type.dart';

class DropdownRepository {
  final ApiClient _apiClient;
  
  List<Map<String, dynamic>> _specialities = [];
  List<Map<String, dynamic>> _serviceCategories = [];
  bool _isLoaded = false;

  DropdownRepository(this._apiClient);

  List<Map<String, dynamic>> get specialities => _specialities;
  List<Map<String, dynamic>> get serviceCategories => _serviceCategories;
  bool get isLoaded => _isLoaded;

  Future<void> fetchDropdownValues() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.dropDownValue);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data != null) {
          _specialities = List<Map<String, dynamic>>.from(
            (data['specialities'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
          );
          _serviceCategories = List<Map<String, dynamic>>.from(
            (data['serviceCategories'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
          );
          _isLoaded = true;
          print('[DropdownRepository] Successfully fetched dropdown values: ${_specialities.length} specialities, ${_serviceCategories.length} categories.');
        }
      }
    } catch (e) {
      print('[DropdownRepository] Failed to fetch dropdown values: $e');
    }
  }

  List<String> getServiceCategoriesForRole(PartnerType role) {
    if (!_isLoaded || _serviceCategories.isEmpty) {
      // Fallback/Mock list if API fails or hasn't loaded yet
      if (role == PartnerType.laboratory) {
        return ['Blood Test', 'Pathology', 'Urine Test', 'Biochemistry', 'Hematology', 'Immunology', 'Hormone Test', 'Microbiology'];
      } else if (role == PartnerType.imagingCenter) {
        return ['X-Ray', 'CT Scan', 'MRI', 'Ultrasound', 'PET Scan', 'Mammography', 'DEXA Scan', 'Echocardiography'];
      }
      return [];
    }

    final targetType = role == PartnerType.laboratory ? 'LABORATORY' : 'IMAGING_CENTER';
    final filtered = _serviceCategories
        .where((element) => element['partnerType']?.toString().toUpperCase() == targetType)
        .map((element) => element['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();

    return filtered;
  }
}
