import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Cấu hình Google Sign In
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // scopes: ['email'], // Mặc định đã có email và profile
  );

  // Địa chỉ Backend (Lưu ý: Android Emulator dùng 10.0.2.2 thay cho localhost)
  // Nếu chạy máy thật thì thay bằng IP LAN của máy tính (VD: 192.168.1.x)
  static const String baseUrl = "http://10.0.2.2:8080/api"; 
  // static const String baseUrl = "http://172.20.10.12:8080/api"; 

  // Hàm xử lý đăng nhập Google
  Future<bool> signInWithGoogle() async {
    try {
      // 1. Mở form đăng nhập Google trên điện thoại
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) return false; // Người dùng hủy đăng nhập

      // 2. Lấy thông tin xác thực (bao gồm idToken)
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        print("Không lấy được ID Token từ Google");
        return false;
      }

      print("Google ID Token: $idToken");

      // 3. Gửi Token này về Backend Spring Boot
      final response = await http.post(
        Uri.parse('$baseUrl/auth/social-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "provider": "GOOGLE",
          "token": idToken, // Gửi token xịn cho Backend check
        }),
      );

      // 4. Xử lý phản hồi từ Backend
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        String jwtToken = responseBody['token'];
        
        // 5. Lưu JWT vào máy để lần sau tự đăng nhập
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', jwtToken);
        await prefs.setString('user_email', responseBody['email']);
        
        print("Đăng nhập thành công! Token: $jwtToken");
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

  // ... (Code cũ của signInWithGoogle giữ nguyên)

  // --- THÊM HÀM NÀY VÀO ---
  Future<bool> register(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'), // Gọi vào /api/auth/signup
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      // Backend trả về 200 OK là thành công
      if (response.statusCode == 200) {
        print("Đăng ký thành công: ${response.body}");
        return true;
      } else {
        // Backend trả về lỗi (VD: Email đã tồn tại)
        print("Đăng ký thất bại: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Lỗi kết nối: $e");
      return false;
    }
  }

// Trong file lib/services/auth_service.dart

  // ... (Các hàm khác giữ nguyên)

  // --- HÀM ĐĂNG XUẤT ---
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Xóa sạch sành sanh mọi thứ liên quan đến User
    await prefs.remove('jwt_token');
    await prefs.remove('user_email');
    await prefs.remove('user_id');
    await prefs.remove('is_setup_completed');
    
    // Nếu có đăng nhập Google thì logout luôn cho sạch
    // try { await _googleSignIn.signOut(); } catch (_) {} 

    print("Đăng xuất thành công! Đã xóa Token.");
  }

  // ... (Các hàm cũ giữ nguyên)

  // --- THÊM HÀM LOGIN ---
// Thay đổi kiểu trả về từ Future<bool> thành Future<Map<String, dynamic>?>
  // Để nếu thành công thì trả về cục dữ liệu (có isSetup), thất bại thì trả về null
Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        String jwtToken = responseBody['token'];
        
        // --- 1. GIỮ NGUYÊN LOGIC LƯU TRỮ CŨ ---
        final prefs = await SharedPreferences.getInstance();
        
        // Lưu Token
        await prefs.setString('jwt_token', jwtToken);
        
        // Lưu Email
        if (responseBody['email'] != null) {
          await prefs.setString('user_email', responseBody['email']);
        }
        
        // Lưu ID User (nếu có)
        if (responseBody['id'] != null) {
             await prefs.setInt('user_id', responseBody['id']);
        }

        // --- 2. THÊM DÒNG NÀY ĐỂ SPLASH SCREEN ĐỌC ---
        // (Nếu không có dòng này, lần sau mở app nó không biết là đã setup chưa đâu)
        bool isSetup = responseBody['isSetup'] ?? false;
        await prefs.setBool('is_setup_completed', isSetup); 

        print("Đăng nhập thành công! Token: $jwtToken | Setup: $isSetup");

        // --- 3. TRẢ VỀ TOÀN BỘ DATA (Để UI check isSetup ngay lập tức) ---
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
  // ... (Các hàm login/register cũ)

  // --- THÊM HÀM SETUP PROFILE ---
  Future<bool> setupProfile({
    required String nationality,
    required String houseName,
    required String address,
    required List<String> roomNames,
  }) async {
    try {
      // 1. Lấy Token từ bộ nhớ
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');

      if (token == null) return false;

      // 2. Gọi API
      final response = await http.post(
        Uri.parse('$baseUrl/user/setup'), // API /api/user/setup
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // <--- QUAN TRỌNG: Gửi kèm Token
        },
        body: jsonEncode({
          "nationality": nationality,
          "houseName": houseName,
          "address": address,
          "roomNames": roomNames,
        }),
      );

      if (response.statusCode == 200) {
        print("Setup thành công!");
        // Đánh dấu là đã setup xong (để lần sau vào thẳng Home)
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
}