import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // دالة تهيئة الخدمة
  Future<bool> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      return true;
    } catch (e) {
      print('خطأ في تهيئة SharedPreferences: $e');
      return false;
    }
  }

  // التحقق من حالة التهيئة
  bool get isInitialized => _isInitialized;

  // قراءة القيم
  String? getString(String key) {
    _checkInitialization();
    return _prefs.getString(key);
  }

  int getInt(String key, {int defaultValue = 0}) {
    _checkInitialization();
    return _prefs.getInt(key) ?? defaultValue;
  }

  double getDouble(String key, {double defaultValue = 0.0}) {
    _checkInitialization();
    return _prefs.getDouble(key) ?? defaultValue;
  }

  bool getBool(String key, {bool defaultValue = false}) {
    _checkInitialization();
    return _prefs.getBool(key) ?? defaultValue;
  }

  List<String> getStringList(String key,
      {List<String> defaultValue = const []}) {
    _checkInitialization();
    return _prefs.getStringList(key) ?? defaultValue;
  }

  // كتابة القيم
  Future<bool> setString(String key, String value) {
    _checkInitialization();
    return _prefs.setString(key, value);
  }

  Future<bool> setInt(String key, int value) {
    _checkInitialization();
    return _prefs.setInt(key, value);
  }

  Future<bool> setDouble(String key, double value) {
    _checkInitialization();
    return _prefs.setDouble(key, value);
  }

  Future<bool> setBool(String key, bool value) {
    _checkInitialization();
    return _prefs.setBool(key, value);
  }

  Future<bool> setStringList(String key, List<String> value) {
    _checkInitialization();
    return _prefs.setStringList(key, value);
  }

  // حذف القيم
  Future<bool> remove(String key) {
    _checkInitialization();
    return _prefs.remove(key);
  }

  Future<bool> clear() {
    _checkInitialization();
    return _prefs.clear();
  }

  // التحقق من وجود مفتاح
  bool containsKey(String key) {
    _checkInitialization();
    return _prefs.containsKey(key);
  }

  // وظيفة مساعدة للتحقق من التهيئة
  void _checkInitialization() {
    if (!_isInitialized) {
      throw Exception('يجب تهيئة SharedPrefsService قبل استخدامه');
    }
  }
}
