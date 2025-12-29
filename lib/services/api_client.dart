import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../utils/navigation_service.dart';
import '../routes.dart';

class ApiClient {
  // 1. Hàm bổ trợ để tránh lặp code
  static Future<http.Response> _sendRequest(String method, String endpoint, {dynamic body}) async {
    final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
    final headers = await _getHeaders();
    late http.Response response;

    try {
      switch (method.toUpperCase()) {
        case 'GET': response = await http.get(url, headers: headers); break;
        case 'POST': response = await http.post(url, headers: headers, body: jsonEncode(body)); break;
        case 'PUT': response = await http.put(url, headers: headers, body: jsonEncode(body)); break;
        case 'DELETE': response = await http.delete(url, headers: headers); break;
        default: throw Exception("Method not supported");
      }
      return _handleResponse(response);
    } on SocketException {
      throw Exception("No Internet Connection");
    } catch (e) {
      rethrow;
    }
  }

  // 2. Các hàm Public (Vợ gọi từ Service)
  static Future<http.Response> get(String endpoint) => _sendRequest('GET', endpoint);
  static Future<http.Response> post(String endpoint, dynamic body) => _sendRequest('POST', endpoint, body: body);
  static Future<http.Response> put(String endpoint, dynamic body) => _sendRequest('PUT', endpoint, body: body);

  // 3. Header tự động lấy Token
  static Future<Map<String, String>> _getHeaders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // 4. Xử lý lỗi TẬP TRUNG (QUAN TRỌNG NHẤT)
  static Future<http.Response> _handleResponse(http.Response response) async {
    if (response.statusCode == 401) {
      print("🚨 401 UNAUTHORIZED -> Auto Logout");
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token'); // Xóa token thôi, giữ lại seenOnboarding
      
      NavigationService.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.loginOptions, (route) => false,
      );
      throw Exception('UNAUTHORIZED');
    }
    return response;
  }

  static Future<bool> checkConnection() async {
    try {
      final response = await http.get(Uri.parse('${AppConfig.baseUrl}/auth/ping'))
          .timeout(const Duration(seconds: 3));
      return true; 
    } catch (_) { return false; }
  }
}