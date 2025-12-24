import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RoomService {
  // IP máy ảo Android là 10.0.2.2, máy thật thì thay bằng IP LAN
  static const String baseUrl = "http://10.0.2.2:8080/api/rooms";

  Future<List<String>> fetchRooms() async {
    try {
      // 1. Lấy Token
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');

      if (token == null) return [];

      // 2. Gọi API
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // 3. Parse dữ liệu: List<Object> -> List<String> (Tên phòng)
        List<dynamic> data = jsonDecode(response.body);
        
        // Chuyển đổi từ JSON Object sang List tên phòng
        List<String> roomNames = data.map((item) => item['name'].toString()).toList();
        return roomNames;
      } else {
        print("Lỗi tải phòng: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Lỗi kết nối: $e");
      return [];
    }
  }
}