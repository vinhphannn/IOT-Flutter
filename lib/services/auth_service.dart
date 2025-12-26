import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart'; // <--- Dùng ApiClient mới

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // --- LOGIN GOOGLE ---
  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) return false;

      // GỌI QUA API CLIENT (Tự xử lý Url, Header, 401)
      final response = await ApiClient.post('/auth/social-login', {
        "provider": "GOOGLE",
        "token": idToken
      });

      if (response.statusCode == 200) {
        await _saveUserData(response.body);
        return true;
      }
      return false;
    } catch (e) {
      print("Lỗi Google Login: $e");
      return false;
    }
  }

  // --- LOGIN THƯỜNG ---
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await ApiClient.post('/auth/login', {
        "email": email,
        "password": password
      });

      if (response.statusCode == 200) {
        await _saveUserData(response.body);
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // --- REGISTER ---
  Future<bool> register(String email, String password) async {
    try {
      final response = await ApiClient.post('/auth/signup', {
        "email": email,
        "password": password
      });
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- SETUP PROFILE ---
  Future<bool> setupProfile({
    required String nationality,
    required String houseName,
    required String address,
    required List<String> roomNames,
  }) async {
    try {
      final response = await ApiClient.post('/user/setup', {
        "nationality": nationality,
        "houseName": houseName,
        "address": address,
        "roomNames": roomNames,
      });

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        
        if (body['houseId'] != null) await prefs.setInt('currentHouseId', body['houseId']);
        if (body['houseName'] != null) await prefs.setString('currentHouseName', body['houseName']);
        await prefs.setBool('is_setup_completed', true);
        
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Hàm phụ lưu data
  Future<void> _saveUserData(String responseBody) async {
    final body = jsonDecode(responseBody);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', body['token']);
    if (body['email'] != null) await prefs.setString('user_email', body['email']);
    if (body['id'] != null) await prefs.setInt('user_id', body['id']);
    bool isSetup = body['isSetup'] ?? false;
    await prefs.setBool('is_setup_completed', isSetup);
  }

  // --- LOGOUT ---
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    try { await _googleSignIn.signOut(); } catch (_) {}
  }
}