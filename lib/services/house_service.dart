import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../models/house_model.dart';
import '../models/device_model.dart';
import '../models/house_member_model.dart';

class HouseService {
  // ... (Hàm fetchMyHouses giữ nguyên) ...
  Future<List<House>> fetchMyHouses() async {
    try {
      final response = await ApiClient.get('/houses');
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        return body.map((item) => House.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // --- HÀM MỚI: Lấy danh sách thành viên ---
  Future<List<HouseMember>> fetchHouseMembers(int houseId) async {
    final response = await ApiClient.get('/houses/$houseId/members');
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => HouseMember.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load members');
    }
  }

  // --- HÀM MỚI: Xóa nhà (Dành cho Admin) ---
  Future<bool> deleteHouse(int houseId) async {
    final response = await ApiClient.delete('/houses/$houseId');
    return response.statusCode == 200;
  }

  Future<bool> updateHouseName(int houseId, String newName) async {
    final response = await ApiClient.put(
      '/houses/$houseId', 
      {'name': newName}, // Body JSON
    );
    return response.statusCode == 200;
  }

  // Hàm lấy thiết bị (Đổi tên cho đúng ý backend)
  Future<List<Device>> fetchDevicesByHouseId(int houseId) async {
    final String endpoint = '/devices/house/$houseId';
    try {
      final response = await ApiClient.get(endpoint);
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        return body.map((item) => Device.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Lỗi lấy thiết bị: $e");
      return [];
    }
  }

  // Hàm bật tắt (Nhận String ID để tránh lỗi type)
  Future<bool> toggleDevice(String deviceId, bool status) async {
    try {
      final response = await ApiClient.put(
        '/devices/$deviceId/status',
        {'status': status},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  // --- HÀM MỚI: Gửi lời mời vào nhà ---
// --- HÀM GỬI LỜI MỜI (Đã sửa khớp với Backend mới của vợ) ---
  Future<bool> sendInvite({
    required int houseId,
    required String email,
    required String role,
  }) async {
    try {
      // 👇 Cập nhật đường dẫn khớp với @PostMapping("/{houseId}/add-member")
      // Lưu ý: ApiClient của mình đã có tiền tố BaseUrl, nên chỉ cần truyền từ đoạn /houses
      final response = await ApiClient.post(
        '/houses/$houseId/add-member', 
        {
          "email": email,
          "role": role.toUpperCase() // Chuyển sang HOA để khớp với HouseRole.valueOf() trong Java
        }
      );

      if (response.statusCode == 200) {
        debugPrint("✅ Backend: ${response.body}");
        return true;
      } else {
        // In lỗi ra để debug nếu Backend trả về 400 hoặc 403
        debugPrint("❌ Lỗi Backend (${response.statusCode}): ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Lỗi kết nối Service: $e");
      return false;
    }
  }

  // --- HÀM MỚI: Xóa thành viên khỏi nhà ---
  // API: DELETE /api/houses/{houseId}/members/{userId}
  Future<bool> removeMember(int houseId, int userId) async {
    try {
      final response = await ApiClient.delete('/houses/$houseId/members/$userId');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Lỗi xóa thành viên: $e");
      return false;
    }
  }

  // --- HÀM MỚI: Lấy quyền của tôi trong nhà này ---
  Future<String?> fetchMyRoleInHouse(int houseId) async {
    try {
      final response = await ApiClient.get('/houses/$houseId/my-role');
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['role']; // Trả về "OWNER", "ADMIN" hoặc "MEMBER"
      }
      return null;
    } catch (e) {
      debugPrint("Lỗi lấy role cá nhân: $e");
      return null;
    }
  }

  // --- HÀM MỚI: Lấy mã QR mời vào nhà ---
  // API giả định: GET /api/houses/{houseId}/invite-code?role=ADMIN
  Future<String?> getInviteCode(int houseId, String role) async {
    try {
      final response = await ApiClient.get('/houses/$houseId/invite-code?role=${role.toUpperCase()}');
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['code']; // Giả định trả về {"code": "F6Z9K4X7"}
      }
      return null;
    } catch (e) {
      debugPrint("Lỗi lấy mã mời: $e");
      return null;
    }
  }

  // --- HÀM MỚI: Tham gia vào nhà bằng mã mời ---
  Future<bool> joinHouseByCode(String code) async {
    try {
      final response = await ApiClient.post(
        '/houses/join', // Khớp với @PostMapping("/join") của BE
        {"code": code}
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Lỗi join house: $e");
      return false;
    }
  }
  // --- HÀM MỚI: Tạo nhà và thêm danh sách phòng cùng lúc ---
  Future<bool> createHouseWithRooms({
    required String name,
    required List<String> roomNames,
  }) async {
    try {
      final response = await ApiClient.post(
        '/user/setup', // Khớp với @PostMapping("/setup") trong UserController.java của vợ
        {
          "houseName": name,
          "roomNames": roomNames,
          "address": "Default Address", // Thêm mặc định vì BE yêu cầu SetupProfileRequest
          "nationality": "Vietnam"
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Lỗi tạo nhà: $e");
      return false;
    }
  }

  // --- HÀM MỚI: Cập nhật vai trò thành viên ---
  // API: PUT /api/houses/{houseId}/members/{userId}/role
  Future<bool> updateMemberRole(int houseId, int userId, String newRole) async {
    try {
      final response = await ApiClient.put(
        '/houses/$houseId/members/$userId/role',
        {"role": newRole.toUpperCase()} // Gửi lên là "ADMIN" hoặc "MEMBER"
      );
      
      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint("Lỗi update role: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Lỗi kết nối: $e");
      return false;
    }
  }

  
}