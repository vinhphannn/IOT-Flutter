import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/api_client.dart'; 
import '../models/room_model.dart'; // <--- Nhớ import Model Room

class RoomService {
  
  // 1. LẤY DANH SÁCH PHÒNG (Trả về List<Room> thay vì List<String>)
  Future<List<Room>> fetchRoomsByHouse(int houseId) async {
    final String endpoint = '/rooms/house/$houseId'; 
    debugPrint("🚀 [RoomService] Gọi API: $endpoint");

    try {
      final response = await ApiClient.get(endpoint);

      if (response.statusCode == 200) {
        // Parse JSON thành List các đối tượng Room
        List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        return body.map((item) => Room.fromJson(item)).toList();
      } else {
        debugPrint("❌ [RoomService] Lỗi: ${response.body}");
        return [];
      }
    } catch (e) {
      debugPrint("❌ [RoomService] Lỗi kết nối: $e");
      return [];
    }
  }

  // 2. THÊM PHÒNG
  Future<bool> addRoom(int houseId, String name) async {
    final response = await ApiClient.post(
      '/rooms/house/$houseId', 
      {'name': name},
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  // 3. XÓA PHÒNG (Dùng ID lấy từ object Room ở trên)
  Future<bool> deleteRoom(int roomId) async {
    final response = await ApiClient.delete('/rooms/$roomId');
    return response.statusCode == 200;
  }
}