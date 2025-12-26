import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../routes.dart';
import '../../config/app_config.dart';       // Import Config
import '../../services/api_client.dart';     // Import ApiClient
import '../../widgets/server_config_dialog.dart'; // Import Dialog cấu hình IP

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startAppFlow(); // Bắt đầu luồng kiểm tra thông minh
  }

  // --- 1. LOGIC KIỂM TRA KẾT NỐI (GIỮ NGUYÊN LOGIC XỊN) ---
  void _startAppFlow() async {
    // A. Load IP Server đã lưu trong máy (nếu có)
    await AppConfig.loadBaseUrl();

    // B. Thử "Ping" Server xem sống hay chết
    bool isConnected = await ApiClient.checkConnection();

    if (!isConnected) {
      // C. Nếu không kết nối được -> Hiện Popup cho nhập IP
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => ServerConfigDialog(
            onSaved: () {
              Navigator.pop(context); 
              _startAppFlow(); 
            },
          ),
        );
      }
    } else {
      // D. Nếu kết nối ngon lành -> Chạy tiếp logic kiểm tra đăng nhập
      _checkLoginStatus();
    }
  }

  // --- 2. LOGIC ĐIỀU HƯỚNG ---
  void _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2)); // Chờ tí cho hiện logo đẹp

    final prefs = await SharedPreferences.getInstance();
    
    final bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
    final String? token = prefs.getString('jwt_token');
    final bool isLoggedIn = token != null && token.isNotEmpty;
    final bool isSetupCompleted = prefs.getBool('is_setup_completed') ?? false;

    if (!mounted) return;

    if (isLoggedIn) {
      if (isSetupCompleted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.signUpSetup);
      }
    } else {
      if (seenOnboarding) {
        Navigator.pushReplacementNamed(context, AppRoutes.loginOptions);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size; // Lấy kích thước màn hình

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            // Phần Logo
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- KHÔI PHỤC LOGO ẢNH CŨ CỦA VỢ ---
                  Image.asset(
                    'assets/images/logo.png',
                    width: size.width * 0.25, 
                    height: size.width * 0.25,
                    fit: BoxFit.contain,
                    // Giữ cái này để lỡ ảnh lỗi thì nó hiện icon thay thế (dự phòng thôi)
                    errorBuilder: (context, error, stackTrace) => Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.smart_toy, size: 60, color: Theme.of(context).primaryColor),
                    ),
                  ),
                  // -------------------------------------
                  
                  const SizedBox(height: 20),
                  const Text(
                    'Smartify',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  
                  // Hiển thị IP nhỏ xíu bên dưới (Giữ lại để vợ biết đang kết nối đâu)
                  const SizedBox(height: 10),
                  Text(
                    "Server: ${AppConfig.baseUrl}",
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                  ),
                ],
              ),
            ),
            // Phần Loading
            const Expanded(
              flex: 1,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}