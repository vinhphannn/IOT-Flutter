import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../utils/navigation_service.dart';
import '../routes.dart';

class ApiClient {
  // 1. Hàm bổ trợ _sendRequest (Đã thêm tham số withToken)
  static Future<http.Response> _sendRequest(String method, String endpoint, {dynamic body, bool withToken = true}) async {
    final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
    
    // Truyền withToken vào để quyết định có lấy Header Authorization không
    final headers = await _getHeaders(withToken); 
    late http.Response response;

    try {
      switch (method.toUpperCase()) {
        case 'GET': 
          response = await http.get(url, headers: headers); 
          break;
        case 'POST': 
          response = await http.post(url, headers: headers, body: jsonEncode(body)); 
          break;
        case 'PUT': 
          response = await http.put(url, headers: headers, body: jsonEncode(body)); 
          break;
        case 'DELETE': 
          response = await http.delete(url, headers: headers); 
          break;
        default: 
          throw Exception("Method not supported");
      }
      return _handleResponse(response);
    } on SocketException {
      throw Exception("No Internet Connection");
    } catch (e) {
      rethrow;
    }
  }

  // 2. Các hàm Public (Đã cập nhật để nhận tham số withToken)
  static Future<http.Response> get(String endpoint, {bool withToken = true}) => 
      _sendRequest('GET', endpoint, withToken: withToken);

  static Future<http.Response> post(String endpoint, dynamic body, {bool withToken = true}) => 
      _sendRequest('POST', endpoint, body: body, withToken: withToken);

  static Future<http.Response> put(String endpoint, dynamic body, {bool withToken = true}) => 
      _sendRequest('PUT', endpoint, body: body, withToken: withToken);

  static Future<http.Response> delete(String endpoint, {bool withToken = true}) => 
      _sendRequest('DELETE', endpoint, withToken: withToken);

  // 3. Header: Chỉ gắn Token nếu withToken == true
  static Future<Map<String, String>> _getHeaders(bool withToken) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (withToken) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // 4. Xử lý lỗi TẬP TRUNG (Auto Logout khi 401)
  static Future<http.Response> _handleResponse(http.Response response) async {
    if (response.statusCode == 401) {
      print("🚨 401 UNAUTHORIZED -> Auto Logout");
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token'); 
      
      // Đá về màn hình Login/Option
      NavigationService.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.loginOptions, (route) => false,
      );
      throw Exception('UNAUTHORIZED');
    }
    return response;
  }

  // 5. Kiểm tra kết nối (Ping server)
  static Future<bool> checkConnection() async {
    try {
      // Ping không cần token, nên gọi get với withToken: false cho an toàn
      final response = await http.get(Uri.parse('${AppConfig.baseUrl}/auth/ping'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200; 
    } catch (_) { return false; }
  }
}