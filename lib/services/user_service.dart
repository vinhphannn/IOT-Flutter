import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart'; // Import ApiClient của vợ

class UserService {
  
  // --- LẤY THÔNG TIN PROFILE TỪ API ---
  Future<Map<String, dynamic>?> fetchUserProfile() async {
    try {
      // Gọi API GET /user/profile
      final response = await ApiClient.get('/user/profile');
      
      // 👇 LOG RA ĐỂ VỢ KIỂM TRA XEM BE TRẢ VỀ CÁI GÌ
      debugPrint("🔍 Status Code: ${response.statusCode}");
      debugPrint("🔍 Body Server trả về: ${utf8.decode(response.bodyBytes)}");

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        
        // --- QUAN TRỌNG: LƯU LẠI VÀO MÁY LUÔN ---
        // Để các trang khác dùng lại mà không cần gọi API nhiều lần
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', data['id'].toString());
        await prefs.setString('email', data['email'] ?? "");
        await prefs.setString('fullName', data['fullName'] ?? "Unknown User");
        
        // Lưu Avatar (Quan trọng nhất chỗ này)
        if (data['avatarUrl'] != null) {
          await prefs.setString('avatarUrl', data['avatarUrl']);
        } else {
          await prefs.remove('avatarUrl'); // Xóa nếu null
        }

        return data;
      } else {
        debugPrint("❌ Lỗi Backend: ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Lỗi kết nối UserService: $e");
      return null;
    }
  }
}