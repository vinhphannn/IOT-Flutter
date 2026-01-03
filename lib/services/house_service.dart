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
}