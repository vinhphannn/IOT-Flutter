import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../utils/navigation_service.dart';
import '../routes.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  // Hàm GET chung
  static Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}$endpoint'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  // Hàm POST chung
  static Future<http.Response> post(String endpoint, dynamic body) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  // 1. Tự động lấy Token nhét vào Header
  static Future<Map<String, String>> _getHeaders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // 2. Tự động kiểm tra lỗi 401 tập trung
  static Future<http.Response> _handleResponse(http.Response response) async {
    if (response.statusCode == 401) {
      print("🚨 LỖI 401: Token hết hạn hoặc User bị xóa -> Auto Logout");

      // Xóa sạch dữ liệu
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Dùng chìa khóa vạn năng để đá về trang Login Options
      NavigationService.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.loginOptions, // Hoặc AppRoutes.welcome tùy vợ đặt tên
        (route) => false,
      );
      
      throw Exception('UNAUTHORIZED');
    }
    return response;
  }

  static Future<bool> checkConnection() async {
    try {
      // Gọi thử vào trang chủ hoặc 1 API public nào đó không cần Token
      // Timeout 3 giây thôi, lâu quá user chờ mệt
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/auth/ping'), // Vợ có thể dùng /auth/login (GET) hoặc endpoint nào nhẹ
      ).timeout(const Duration(seconds: 3));

      // Nếu Server phản hồi (dù lỗi 401 hay 404) chứng tỏ là ĐÃ KẾT NỐI ĐƯỢC
      return true; 
    } catch (e) {
      print("Lỗi kết nối Server: $e");
      return false; // Không kết nối được
    }
  }
}