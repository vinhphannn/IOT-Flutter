import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/api_client.dart'; // Import đúng file ApiClient xịn xò

class RoomService {
  // Đường dẫn chuẩn theo file Java vợ gửi: /rooms/house/{houseId}
  Future<List<String>> fetchRoomNamesByHouse(int houseId) async {
    // 1. Dùng đường dẫn này mới đúng với Backend nhé!
    final String endpoint = '/rooms/house/$houseId'; 
    
    debugPrint("🚀 [RoomService] Gọi API: $endpoint");

    try {
      // ApiClient đã tự động gắn Token để qua mặt Spring Security
      final response = await ApiClient.get(endpoint);

      if (response.statusCode == 200) {
        // Parse UTF-8 để không lỗi font tiếng Việt
        List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        
        // 2. QUAN TRỌNG: Kiểm tra xem trong Java, class Room đặt tên biến là 'name' hay 'roomName'?
        // Ở đây chồng giả sử là 'name'. Nếu lỗi, vợ thử đổi thành item['roomName'] nhé.
        return body.map((item) => item['name'].toString()).toList();
      } else {
        debugPrint("❌ [RoomService] Lỗi từ Backend: ${response.statusCode} - ${response.body}");
        return [];
      }
    } catch (e) {
      debugPrint("❌ [RoomService] Lỗi kết nối: $e");
      return [];
    }
  }
}