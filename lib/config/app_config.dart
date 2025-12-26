import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  // Mặc định là máy ảo (cho lần đầu cài app)
  static String baseUrl = "http://10.0.2.2:8080/api"; 

  // Key để lưu trong SharedPreferences
  static const String _keyBaseUrl = 'saved_base_url';

  // 1. Hàm load URL từ bộ nhớ khi mở App
  static Future<void> loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedUrl = prefs.getString(_keyBaseUrl);
    if (savedUrl != null && savedUrl.isNotEmpty) {
      baseUrl = savedUrl;
    }
  }

  // 2. Hàm lưu URL mới khi vợ nhập
  static Future<void> setBaseUrl(String newUrl) async {
    // Đảm bảo không có dấu / ở cuối
    if (newUrl.endsWith('/')) {
      newUrl = newUrl.substring(0, newUrl.length - 1);
    }
    
    baseUrl = newUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, baseUrl);
  }
}