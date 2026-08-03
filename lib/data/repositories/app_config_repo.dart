import 'package:supabase_flutter/supabase_flutter.dart';

class AppConfigRepository {
  final SupabaseClient? _client;

  AppConfigRepository({SupabaseClient? client}) : _client = client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  /// Fetch configuration value by key from 'AppConfig' table
  Future<dynamic> getConfigValue(String key) async {
    try {
      final response = await _supabase
          .from('AppConfig')
          .select('value')
          .eq('key', key)
          .maybeSingle();

      if (response != null && response['value'] != null) {
        return response['value'];
      }
    } catch (e) {
      print('[AppConfigRepository] Error fetching config for key $key: $e');
    }
    return null;
  }

  /// Patient appointment message limit (null means unlimited for now)
  Future<int?> getPatientMessageLimit() async {
    final val = await getConfigValue('patient_appointment_message_limit');
    if (val is int) return val;
    if (val is String) return int.tryParse(val);
    return null;
  }

  /// Partner appointment message limit (null means unlimited)
  Future<int?> getPartnerMessageLimit() async {
    final val = await getConfigValue('partner_appointment_message_limit');
    if (val is int) return val;
    if (val is String) return int.tryParse(val);
    return null;
  }
}
