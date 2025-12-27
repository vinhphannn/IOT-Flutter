import 'dart:convert';
import '../models/house_model.dart';
import 'api_client.dart'; // <--- Import ApiClient
import 'package:flutter/material.dart';
import '../models/device_model.dart'; // <--- Import Device Model
import 'api_client.dart';
import 'dart:convert';
import '../models/room_model.dart'; // <--- Import Room Model
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

  // 2. GIẢI QUYẾT LỖI: Thêm hàm fetchAllDevices
  Future<List<Device>> fetchAllDevices() async {
    // Gọi đến endpoint lấy tất cả thiết bị của User
    final response = await ApiClient.get('/devices'); 

    if (response.statusCode == 200) {
      // Dùng utf8.decode để không bị lỗi tiếng Việt
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((dynamic item) => Device.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load devices');
    }
  }

  // 3. Thêm hàm fetchRooms (Dùng cho Popup chọn phòng hoặc Tab)
  Future<List<Room>> fetchRooms() async {
    final response = await ApiClient.get('/rooms');
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((dynamic item) => Room.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load rooms');
    }
  }

  // 4. Hàm điều khiển thiết bị (Bật/Tắt)
  Future<bool> toggleDevice(int deviceId, bool status) async {
    final response = await ApiClient.put(
      '/devices/$deviceId/status',
      {'status': status},
    );
    return response.statusCode == 200;
  }

  // Thêm vào trong class HouseService
}