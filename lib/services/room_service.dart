import 'dart:convert';
import 'api_client.dart'; // <--- Import ApiClient

class RoomService {
  Future<List<String>> fetchRoomNamesByHouse(int houseId) async {
    // Gọi cực ngắn gọn
    final response = await ApiClient.get('/rooms/house/$houseId');

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => item['name'].toString()).toList();
    } else {
      return [];
    }
  }
}