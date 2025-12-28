import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  // Mặc định cho máy ảo Android
  static String baseUrl = "http://10.0.2.2:8080/api"; 
  
  static const String _keyBaseUrl = 'saved_base_url';

  // --- HÀM MỚI: Tự động tạo URL WebSocket từ baseUrl ---
  static String get webSocketUrl {
    // Nếu baseUrl là http://192.168.1.15:8080/api
    // Nó sẽ đổi thành ws://192.168.1.15:8080/ws
    String host = baseUrl.replaceAll("/api", ""); // Bỏ cái đuôi /api đi
    if (host.startsWith("https")) {
      return host.replaceFirst("https", "wss") + "/ws";
    } else {
      return host.replaceFirst("http", "ws") + "/ws";
    }
  }

  // Load URL khi mở App
  static Future<void> loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedUrl = prefs.getString(_keyBaseUrl);
    if (savedUrl != null && savedUrl.isNotEmpty) {
      baseUrl = savedUrl;
    }
  }

  // Lưu URL mới
  static Future<void> setBaseUrl(String newUrl) async {
    if (newUrl.endsWith('/')) {
      newUrl = newUrl.substring(0, newUrl.length - 1);
    }
    
    baseUrl = newUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, baseUrl);
  }
}