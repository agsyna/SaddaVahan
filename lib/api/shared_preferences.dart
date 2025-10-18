import 'package:shared_preferences/shared_preferences.dart';

class MySharedPrefs {
  static SharedPreferences? _prefs;

  static Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<dynamic> getValue(String key) async {
    await _initPrefs();
    return _prefs!.get(key);
  }

  static Future<String?> getString(String key) async {
    await _initPrefs();
    return _prefs!.getString(key);
  }

  static Future<int?> getInt(String key) async {
    await _initPrefs();
    return _prefs!.getInt(key);
  }

  static Future<double?> getDouble(String key) async {
    await _initPrefs();
    return _prefs!.getDouble(key);
  }

  static Future<bool?> getBool(String key) async {
    await _initPrefs();
    return _prefs!.getBool(key);
  }

  static Future<List<String>?> getStringList(String key) async {
    await _initPrefs();
    return _prefs!.getStringList(key);
  }

  static Future<bool> setValue(String key, dynamic value) async {
    await _initPrefs();
    if (value is String) {
      return _prefs!.setString(key, value);
    } else if (value is int) {
      return _prefs!.setInt(key, value);
    } else if (value is double) {
      return _prefs!.setDouble(key, value);
    } else if (value is bool) {
      return _prefs!.setBool(key, value);
    } else if (value is List<String>) {
      return _prefs!.setStringList(key, value);
    }
    return false;
  }

  static Future<bool> remove(String key) async {
    await _initPrefs();
    return _prefs!.remove(key);
  }
  static Future<bool> clear() async {
    await _initPrefs();
    return _prefs!.clear();
  }
}