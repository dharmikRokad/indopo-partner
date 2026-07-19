import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String _keySelectedRole = 'indopo_selected_role';

  final SharedPreferences _prefs;

  LocalStorage(this._prefs);

  Future<void> saveSelectedRole(String role) async {
    await _prefs.setString(_keySelectedRole, role);
  }

  String? getSelectedRole() {
    return _prefs.getString(_keySelectedRole);
  }

  Future<void> clearSelectedRole() async {
    await _prefs.remove(_keySelectedRole);
  }
}
