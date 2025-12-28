import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../models/house_model.dart';
import '../models/device_model.dart';

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