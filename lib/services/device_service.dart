import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../models/device_model.dart';
import '../models/device_log_model.dart';

class DeviceService {
  // 1. Lấy danh sách thiết bị theo ID nhà (Giống hàm cũ nhưng chuyển về đây)
  Future<List<Device>> fetchDevicesByHouseId(int houseId) async {
    try {
      final response = await ApiClient.get('/devices/house/$houseId');
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        return body.map((item) => Device.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("❌ Lỗi lấy thiết bị: $e");
      return [];
    }
  }

  // 2. Hàm bật/tắt thiết bị
  Future<bool> toggleDevice(String deviceId, bool status) async {
    try {
      final response = await ApiClient.put(
        '/devices/$deviceId/status',
        {'status': status},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("❌ Lỗi Toggle Device: $e");
      return false;
    }
  }

  // 3. Hàm lấy Lịch sử (Logs) - Có hỗ trợ phân trang
  Future<List<DeviceLog>> getDeviceLogs(int deviceId, {int page = 0, int size = 20}) async {
    // API theo format: /api/devices/1/logs?page=0&size=20
    final String endpoint = '/devices/$deviceId/logs?page=$page&size=$size';
    
    try {
      final response = await ApiClient.get(endpoint);
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        return body.map((item) => DeviceLog.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("❌ Lỗi lấy Logs: $e");
      return [];
    }
  }
}