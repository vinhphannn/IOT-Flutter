import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart'; // <--- Import cấu hình chung

class AuthService {
  // Cấu hình Google Sign In
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // --- 1. ĐĂNG NHẬP GOOGLE ---
  Future<bool> signInWithGoogle() async {
    try {
      // Mở form đăng nhập Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      // Lấy Token xác thực
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        print("Không lấy được ID Token từ Google");
        return false;
      }

      // Gửi Token về Backend (Dùng AppConfig.baseUrl)
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/social-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"provider": "GOOGLE", "token": idToken}),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        String jwtToken = responseBody['token'];

        // Lưu thông tin vào máy
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', jwtToken);

        if (responseBody['email'] != null) {
          await prefs.setString('user_email', responseBody['email']);
        }

        // Lưu trạng thái Setup để Splash Screen biết đường chuyển hướng
        bool isSetup = responseBody['isSetup'] ?? false;
        await prefs.setBool('is_setup_completed', isSetup);

        print("Google Login thành công! Setup: $isSetup");
        return true;
      } else {
        print("Lỗi Backend: ${response.body}");
        return false;
      }
    } catch (error) {
      print("Lỗi đăng nhập Google: $error");
      return false;
    }
  }

  // --- 2. ĐĂNG KÝ (SIGN UP) ---
  Future<bool> register(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/signup'), // Dùng AppConfig
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": email, "password": password}),
      );

      if (response.statusCode == 200) {
        print("Đăng ký thành công!");
        return true;
      } else {
        print("Đăng ký thất bại: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Lỗi kết nối: $e");
      return false;
    }
  }

  // --- 3. ĐĂNG NHẬP THƯỜNG (LOGIN) ---
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/login'), // Dùng AppConfig
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": email, "password": password}),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        String jwtToken = responseBody['token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', jwtToken);

        if (responseBody['email'] != null) {
          await prefs.setString('user_email', responseBody['email']);
        }

        if (responseBody['id'] != null) {
          await prefs.setInt('user_id', responseBody['id']);
        }

        bool isSetup = responseBody['isSetup'] ?? false;
        await prefs.setBool('is_setup_completed', isSetup);

        return responseBody;
      } else {
        print("Đăng nhập thất bại: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Lỗi kết nối: $e");
      return null;
    }
  }

  // --- 4. SETUP PROFILE (TẠO NHÀ) ---
  Future<bool> setupProfile({
    required String nationality,
    required String houseName,
    required String address,
    required List<String> roomNames,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');

      if (token == null) return false;

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/user/setup'), // Dùng AppConfig
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "nationality": nationality,
          "houseName": houseName,
          "address": address,
          "roomNames": roomNames,
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        // 1. Lưu ID Nhà (Đã có)
        if (responseBody['houseId'] != null) {
          await prefs.setInt('currentHouseId', responseBody['houseId']);
        }

        // 2. Lưu Tên Nhà (THÊM CÁI NÀY)
        if (responseBody['houseName'] != null) {
          await prefs.setString('currentHouseName', responseBody['houseName']);
        }

        await prefs.setBool('is_setup_completed', true);
        return true;
      } else {
        print("Setup thất bại: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Lỗi Setup: $e");
      return false;
    }
  }

  // --- 5. ĐĂNG XUẤT ---
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Xóa sạch token, email, houseId...

    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    print("Đăng xuất thành công!");
  }
}
