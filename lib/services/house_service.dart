import 'dart:convert';
import '../models/house_model.dart';
import 'api_client.dart'; // <--- Import ApiClient

class HouseService {
  Future<List<House>> fetchMyHouses() async {
    // Không cần try-catch 401 nữa vì ApiClient lo rồi
    final response = await ApiClient.get('/houses');

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => House.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load houses');
    }
  }
}