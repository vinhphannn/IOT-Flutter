import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/house_model.dart';
import '../config/app_config.dart'; // <--- Import file cấu hình

class HouseService {
  Future<List<House>> fetchMyHouses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    // Dùng AppConfig.baseUrl thay vì biến cục bộ
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/houses'), 
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => House.fromJson(item)).toList();
    } else {
      // In lỗi ra để dễ debug
      print("Lỗi HouseService: ${response.statusCode} - ${response.body}");
      throw Exception('Failed to load houses');
    }
  }
}