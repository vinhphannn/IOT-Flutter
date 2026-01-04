import 'dart:convert';
import 'package:flutter/material.dart';
import 'api_client.dart'; // Import ApiClient cũ của vợ
 // Import ApiClient của vợ
import '../models/scene_model.dart';
class SmartService {
  
  // API: TẠO SCENE (Automation / Tap-to-Run)
  // URL: POST /api/smart/scenes
  Future<bool> createScene({
    required String name,
    required int houseId,
    required String type, // "AUTOMATION" hoặc "TAP_TO_RUN"
    required String iconUrl,
    required String colorCode,
    required List<Map<String, dynamic>> conditions,
    required List<Map<String, dynamic>> actions,
  }) async {
    try {
      final body = {
        "name": name,
        "houseId": houseId,
        "type": type,
        "iconUrl": iconUrl,
        "colorCode": colorCode,
        "conditions": conditions, // Mảng điều kiện (IF)
        "actions": actions,       // Mảng hành động (THEN)
      };

      debugPrint("📤 Sending Scene Data: ${jsonEncode(body)}");

      final response = await ApiClient.post('/smart/scenes', body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("✅ Tạo Scene thành công!");
        return true;
      } else {
        debugPrint("❌ Lỗi Backend: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Lỗi kết nối SmartService: $e");
      return false;
    }
  }

  // 2. LẤY DANH SÁCH SCENE THEO NHÀ
  Future<List<Scene>> getScenes(int houseId) async {
    try {
      final response = await ApiClient.get('/smart/scenes/house/$houseId');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Scene.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("❌ Lỗi lấy danh sách scene: $e");
    }
    return [];
  }

  // 3. CHẠY TAP-TO-RUN (EXECUTE)
  Future<bool> executeScene(int sceneId) async {
    try {
      final response = await ApiClient.post('/smart/scenes/$sceneId/execute', {});
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("❌ Lỗi chạy scene: $e");
      return false;
    }
  }

  // 4. BẬT/TẮT AUTOMATION (TOGGLE)
  Future<bool> toggleScene(int sceneId) async {
    try {
      final response = await ApiClient.put('/smart/scenes/$sceneId/toggle', {});
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("❌ Lỗi toggle scene: $e");
      return false;
    }
  }

  // 5. XÓA SCENE
  Future<bool> deleteScene(int sceneId) async {
    try {
      final response = await ApiClient.delete('/smart/scenes/$sceneId');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("❌ Lỗi xóa scene: $e");
      return false;
    }
  }
}