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

Future<List<DeviceLog>> getDeviceLogs(int deviceId, {int page = 0, int size = 20}) async {
    // 1. In ra URL để xem đúng chưa
    final String endpoint = '/devices/$deviceId/logs?page=$page&size=$size'; 
    print("🔍 [DEBUG] Đang gọi API: $endpoint");

    try {
      final response = await ApiClient.get(endpoint);
      
      // 2. In ra Status Code và Dữ liệu thô nhận được
      print("🔍 [DEBUG] Status Code: ${response.statusCode}");
      print("🔍 [DEBUG] Body nhận được: ${response.body}");

      if (response.statusCode == 200) {
        // Giải mã UTF-8 để không lỗi font tiếng Việt
        final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));
        
        List<dynamic> logsList = [];

        // 3. Kiểm tra cấu trúc dữ liệu trả về
        if (body is List) {
          print("✅ [DEBUG] Backend trả về dạng LIST (Đúng rồi!)");
          logsList = body;
        } else if (body is Map && body.containsKey('content')) {
          print("✅ [DEBUG] Backend trả về dạng PAGE (Spring Boot)");
          logsList = body['content'];
        } else {
          print("⚠️ [DEBUG] Cấu trúc lạ, không phải List cũng không phải Page: $body");
          return [];
        }

        // 4. Thử map từng phần tử xem có lỗi Parse không
        return logsList.map((item) {
          try {
            return DeviceLog.fromJson(item);
          } catch (e) {
            print("❌ [DEBUG] Lỗi Parse Item này: $item");
            print("❌ [DEBUG] Chi tiết lỗi: $e");
            // Trả về một object rỗng hoặc throw tiếp tùy ý (ở đây mình bỏ qua item lỗi)
            throw Exception("Parse Error"); 
          }
        }).toList();

      } else {
        print("❌ [DEBUG] API lỗi: ${response.statusCode} - ${response.reasonPhrase}");
        return [];
      }
    } catch (e) {
      print("❌ [DEBUG] Lỗi kết nối hoặc Code: $e");
      return [];
    }
  }
  
}